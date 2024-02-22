"""Catch when a ThermoFisher raw file has been created"""

from pathlib import Path
from datetime import datetime
import logging
import yaml
import os

# DO NOT PRINT ANYTHING TO STDOUT, IT'S RESERVED TO THE RESULT OF CATCH_RAW

logging.basicConfig(level=logging.DEBUG)

def catch_raw(point: str, workflow_run_dir: str) -> tuple[bool, dict]:
    """Return True if a raw file ending in _n.raw with n the cycle number
    is present in the input_dir. Return False otherwise.
    """
    point: int = int(point)
    workflow_run_dir: Path = Path(workflow_run_dir)
    
    config_file = workflow_run_dir / "config.yml"
    input_dir = load_input_config(config_file)
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
            logging.debug("🛑 RAW FILE FOUND: %s", filepath)
            return True, {
                'file': str(filepath),
                'time': get_file_datetime(filepath).strftime('%Y-%m-%d %H:%M:%S')
            }
            #return True, {}
    # No raw file found
    logging.debug("🛑 No raw file found in %s", input_dir)
    return False, {}

def load_input_config(config_file: Path) -> Path:
    """Should be replaced by a call to the Cylc suite's configuration
    """
    with open(config_file, 'r', encoding='utf-8') as stream:
        try:
            wfconfig: dict = yaml.safe_load(stream)
            logging.debug("🛑 type of wfconfig: %s", type(wfconfig))
            input_dir: Path = Path(wfconfig["input-directory"])
        except yaml.YAMLError as exc:
            raise exc
        return input_dir

def get_file_datetime(file: Path) -> datetime:
    """Return the last modification time of the file."""
    modification_time = file.stat().st_mtime
    formatted_time: str = datetime.fromtimestamp(modification_time)
    return formatted_time

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