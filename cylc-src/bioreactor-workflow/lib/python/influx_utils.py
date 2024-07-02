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


class InfluxBatchingCallback:
    """
    Register custom callbacks to handle batch events. It is needed because the
    write API in batch mode runs in the background, in a separate thread, and it
    isn’t possible to directly return underlying exceptions.

    Copied from:
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


def load_json_file(json_path: str) -> dict:
    """
    Load a JSON file and return its content as a dictionary
    """
    with open(json_path, "r", encoding="utf-8") as file:
        return json.load(file)


@dataclass
class MeasurementDataFrame:
    """
    Dataclass to hold DataFrame and metadata for InfluxDB.

    Attributes:
        `data_frame` : pd.DataFrame
            DataFrame to be uploaded to InfluxDB.
        `measurement_name` : str
            Name of the corresponding InfluxDB measurement.
        `tag_cols` : list[str]
            List of column in the DataFrame to be used as tags. See InfluxDB
            documentation on tags for more info.
        `time_col` : str
            Name of the column in the DataFrame that contains the timestamp.
    """

    data_frame: pd.DataFrame
    measurement_name: str
    tag_cols: list[str] = None
    time_col: str = "datetime"

    @classmethod
    def from_csv(
        cls, table_path: str | Path, schemas_path: str | Path, schema_name: str
    ) -> "MeasurementDataFrame":
        """
        Load a CSV file and its schema to create a MeasurementDataFrame object.

        Args:
            `table_path` : str | Path
                Path to the CSV file.
            `schemas_path` : str | Path
                Path to the JSON file containing the schema of the CSV file.
            `schema_name` : str
                Name of the schema in the JSON file.

        Returns:
            `MeasurementDataFrame`
                A MeasurementDataFrame object.

        Raises:
            `KeyError` If the datetime column is not found in the CSV file.

        """
        dataframe = pd.read_csv(table_path, sep=";")
        table_schema: dict = load_json_file(schemas_path)["tables"][schema_name]

        datetime_col: str = table_schema["datetime_column"]
        tags: list | None = table_schema.get("tags")

        if datetime_col not in dataframe.columns:
            raise KeyError(f"Column {datetime_col} not found in {table_path.name}")
        ## Should be added back when tables formats stabilizes.
        # if tags and not all(tag in dataframe.columns for tag in tags):
        #     raise KeyError(f"Tags {tags} not found in {table_path.name}")
        return cls(dataframe, schema_name, tags, datetime_col)

    def upload(self, client: InfluxDBClient, bucket: str) -> None:
        """
        Upload the DataFrame to InfluxDB.

        Args:
            `client` : InfluxDBClient
                InfluxDBClient object.
            `bucket` : str
                Name of the bucket in InfluxDB to upload to.

        Raises:
            `InfluxDBError` If the upload fails.
        """
        start_time = datetime.now()
        callback = InfluxBatchingCallback()
        with client.write_api(
            success_callback=callback.success,
            error_callback=callback.error,
            retry_callback=callback.retry,
        ) as write_api:
            write_api.write(
                bucket=bucket,
                record=self.data_frame,
                data_frame_measurement_name=self.measurement_name,
                data_frame_tag_columns=self.tag_cols,
                data_frame_timestamp_column=self.time_col,
            )
        if callback.error_event.is_set():
            raise InfluxDBError(callback.response, callback.message)
        print(f"Successfully finished upload in: {datetime.now() - start_time}")
