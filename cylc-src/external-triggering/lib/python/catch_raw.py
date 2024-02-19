"""Catch when a ThermoFisher raw file has been created"""

from pathlib import Path
from datetime import datetime
import logging
import yaml

logging.basicConfig(level=logging.DEBUG)

with open('../../config.yml', 'r', encoding='utf-8') as stream:
    try:
        wfconfig: dict = yaml.safe_load(stream)
        logging.debug("type of wfconfig: %s", type(wfconfig))
        input_dir: Path = Path(wfconfig["input-directory"])
    except yaml.YAMLError as exc:
        print("exception: ", exc)

def catch_raw(point: int) -> tuple[bool, dict]:
    """Return True if a raw file ending in _n.raw with n the cycle number
    is present in the input_dir. Return False otherwise.
    """
    # Files are named like "file_01.raw" from 01 to 09 and "file_10.raw" from 10 to 99
    if point <= 9:
        point: str = f'0{point}'
    for filepath in input_dir.iterdir():
        if (
                filepath.is_file() and
                filepath.suffix == '.raw' and
                filepath.stem.endswith(f'_{point}') and
                not (filepath / ".lock").is_dir()
                # lockdir are created by the scp daemon when the file is being
                # copied and are removed when the copy is finished
            ):
            logging.debug("RAW FILE FOUND: %s", filepath)
            return True, {'file': filepath, 'time': get_file_datetime(filepath)}
    # No raw file found
    logging.debug("No raw file found in %s", input_dir)
    return False, {}

def get_file_datetime(file: Path):
    """Return the last modification time of the file."""
    modification_time = file.stat().st_mtime
    formatted_time: datetime = datetime.fromtimestamp(modification_time)
    return formatted_time

catch_raw(1)

# def get_raws_datetimes():
#     """Return a dictionary of raw file names in the directory and
#     their last modification times.
#     """
#     file_mod_times: dict = {}
#     for filepath in input_dir.iterdir():
#         if filepath.is_file() and filepath.suffix == '.raw':
#             modification_time = filepath.stat().st_mtime
#             formatted_time: datetime = datetime.fromtimestamp(modification_time)#\
#                 #.strftime('%Y-%m-%d %H:%M:%S')
#             file_mod_times[filepath] = formatted_time
#     return file_mod_times