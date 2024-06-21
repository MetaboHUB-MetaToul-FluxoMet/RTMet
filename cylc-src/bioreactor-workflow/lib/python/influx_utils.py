"""
Based on "How to ingest large DataFrame by splitting into chunks."
https://github.com/influxdata/influxdb-client-python/blob/master/examples/ingest_large_dataframe.py
"""

import logging
from datetime import datetime
from pathlib import Path
from dataclasses import dataclass
from threading import Event
from typing import Optional
import json

import pandas as pd
from influxdb_client import InfluxDBClient
from influxdb_client.client.exceptions import InfluxDBError
from urllib3 import HTTPResponse


# Enable logging for DataFrame serializer
HANDLER = logging.StreamHandler()
HANDLER.setFormatter(logging.Formatter("%(asctime)s | %(message)s"))
LOGGERSERIALIZER = logging.getLogger(
    "influxdb_client.client.write.dataframe_serializer"
)
LOGGERSERIALIZER.setLevel(level=logging.DEBUG)
LOGGERSERIALIZER.addHandler(HANDLER)


class BatchingCallback:
    """
    copied from:
    https://influxdb-client.readthedocs.io/en/latest/usage.html#handling-errors
    """

    def __init__(self):
        self.error_event = Event()
        self.response: Optional[HTTPResponse] = None
        self.message: Optional[str] = None

    def success(self, conf: tuple[str, str, str], data: str):
        pass

    def error(self, conf: tuple[str, str, str], data: str, exception: InfluxDBError):
        self.error_event.set()
        self.response = exception.response
        self.message = exception.message

    def retry(self, conf: tuple[str, str, str], data: str, exception: InfluxDBError):
        self.error_event.set()
        self.response = exception.response
        self.message = exception.message


def client_from_ini(ini_path: str, config_name: str = "influx2"):
    """
    Create client from ini file.
    """
    return InfluxDBClient.from_config_file(ini_path, config_name=config_name)


@dataclass
class MeasurementDataFrame:
    """
    Dataclass to hold DataFrame and metadata for InfluxDB
    """

    data_frame: pd.DataFrame
    measurement_name: str
    tag_cols: list[str] = None
    time_col: str = "datetime"


def load_tables_schemas(json_path: str) -> dict:
    """
    Load tables schemas from JSON file
    """
    with open(json_path, "r", encoding="utf-8") as file:
        return json.load(file)


def measurement_df_from_csv(
    schemas: dict, table_name: str, dir: str
) -> MeasurementDataFrame:
    dir_path = Path(dir)
    sep = schemas["sep"]
    table_schema = schemas["tables"][table_name]
    file_suffix = table_schema["suffix"]
    datetime_col: str = table_schema["datetime_column"]
    tags: list | None = table_schema.get("tags")

    files = list(dir_path.glob(f"*{file_suffix}"))
    if len(files) == 0:
        raise FileNotFoundError(
            f"No file found with suffix {file_suffix} in {dir_path}"
        )
    if len(files) > 1:
        raise FileNotFoundError(
            f"Many files found with suffix {file_suffix} in {dir_path}"
        )
    file_path = files[0]

    dataframe = pd.read_csv(file_path, sep=sep)
    if datetime_col not in dataframe.columns:
        raise KeyError(f"Column {datetime_col} not found in {file_path.name}")
    return MeasurementDataFrame(dataframe, table_name, tags, datetime_col)


def ingest(
    measurement_df: MeasurementDataFrame, client: InfluxDBClient, bucket: str
) -> None:
    start_time = datetime.now()
    callback = BatchingCallback()
    with client.write_api(
        success_callback=callback.success,
        error_callback=callback.error,
        retry_callback=callback.retry,
    ) as write_api:
        write_api.write(
            bucket=bucket,
            record=measurement_df.data_frame,
            data_frame_tag_columns=measurement_df.tag_cols,
            data_frame_measurement_name=measurement_df.measurement_name,
            data_frame_timestamp_column=measurement_df.time_col,
        )
    if callback.error_event.is_set():
        raise InfluxDBError(callback.response, callback.message)
    print(f"Successfully finished upload in: {datetime.now() - start_time}")
