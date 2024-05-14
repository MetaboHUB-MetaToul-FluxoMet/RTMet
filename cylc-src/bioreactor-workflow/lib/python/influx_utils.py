"""
Based on "How to ingest large DataFrame by splitting into chunks."
https://github.com/influxdata/influxdb-client-python/blob/master/examples/ingest_large_dataframe.py
"""

import logging
from datetime import datetime
from pathlib import Path
from dataclasses import dataclass
import pandas as pd
import json

from influxdb_client import InfluxDBClient
from influxdb_client.extras import np


# Enable logging for DataFrame serializer
loggerSerializer = logging.getLogger(
    "influxdb_client.client.write.dataframe_serializer"
)
loggerSerializer.setLevel(level=logging.DEBUG)
handler = logging.StreamHandler()
handler.setFormatter(logging.Formatter("%(asctime)s | %(message)s"))
loggerSerializer.addHandler(handler)

# Configuration
URL = "http://localhost:8086"
TOKEN = "HlkyCQBW_F8Ri_UyOlyNDDVNZg93uEXDwpT6CQ1My4Hdx8cW2vx6wTM_duzcf3rn2y88H7a3ZZJ-N_q4_mV14g=="
ORG = "FluxoMet"
BUCKET = "testing-py-api"


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


# def data_frame_from_csv(csv_path: str, sep: str = ";", time: datetime = None):
#     """
#     Read CSV to DataFrame
#     """
#     print()
#     print("=== Reading CSV to DataFrame ===")
#     print()
#     data_frame = pd.read_csv(Path(csv_path), sep=sep)
#     if time:
#         data_frame["time"] = time
#     else:
#         data_frame["time"] = datetime.now()
#     print(data_frame)
#     return data_frame


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


def ingest(measurement_df: MeasurementDataFrame, client: InfluxDBClient, bucket: str):
    start_time = datetime.now()
    with client.write_api() as write_api:
        write_api.write(
            bucket=bucket,
            record=measurement_df.data_frame,
            data_frame_tag_columns=measurement_df.tag_cols,
            data_frame_measurement_name=measurement_df.measurement_name,
            data_frame_timestamp_column=measurement_df.time_col,
        )
    print(f"Import finished in: {datetime.now() - start_time}")
