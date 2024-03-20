"""Catch when a ThermoFisher raw file has been created"""

from pathlib import Path
from datetime import datetime
from typing import Callable
import logging
#import yaml

# DO NOT PRINT ANYTHING TO STDOUT, IT'S RESERVED TO THE RESULT OF CATCH_RAW

logging.basicConfig(level=logging.DEBUG)

def catch_raw(point: str, workflow_run_dir: str, filename_rule_input: str, rawfiles_dir_input = None) -> tuple[bool, dict]:
    """Return {True, {'file': Path, 'time': str} if a raw file following the rule
    with n the cycle number is present in the rawfiles_dir.
    Return (False, {}) otherwise.
    """
    point: int = int(point)
    workflow_run_dir: Path = Path(workflow_run_dir)
    
    if rawfiles_dir_input is not None and Path(rawfiles_dir_input).exists() and Path(rawfiles_dir_input).is_dir():
        rawfiles_dir: Path = Path(rawfiles_dir_input)
    else:
        rawfiles_dir: Path = workflow_run_dir / "raws"
        rawfiles_dir.mkdir(exist_ok=True)

    try:
        filename_rule: Callable[[int, Path], bool] = getattr(FilenameRules, filename_rule_input)
    except AttributeError:
        # default rule
        filename_rule: Callable[[int, Path], bool] = FilenameRules.integer_naming


    #config_file: Path = workflow_run_dir / "config.yml"
    #rawfiles_dir: Path = load_input_config(config_file)
    

    for filepath in rawfiles_dir.iterdir():
        if (
                filepath.is_file() and
                filename_rule(point, filepath) and
                not (filepath / ".lock").is_dir()
                # lockdir are created by the scp daemon when the file is being
                # copied and are removed when the copy is finished
            ):
            logging.debug("🛑 RAW FILE FOUND: %s", filepath)
            return True, {
                'file': str(filepath),
                'time': get_file_datetime(filepath).strftime('%Y-%m-%d %H:%M:%S')
            }
    # No raw file found
    logging.debug("🛑 No raw file found in %s", rawfiles_dir)
    return False, {}

# def load_input_config(config_file: Path) -> Path:
#     """Should be replaced by a call to the Cylc suite's configuration
#     """
#     with open(config_file, 'r', encoding='utf-8') as stream:
#         try:
#             wfconfig: dict = yaml.safe_load(stream)
#             logging.debug("🛑 type of wfconfig: %s", type(wfconfig))
#             rawfiles_dir: Path = Path(wfconfig["input-directory"])
#         except yaml.YAMLError as exc:
#             raise exc
#         return rawfiles_dir

def get_file_datetime(file: Path) -> datetime:
    """Return the last modification time of the file."""
    modification_time = file.stat().st_mtime
    formatted_time: str = datetime.fromtimestamp(modification_time)
    return formatted_time

class FilenameRules:
    """A class to store all the filename rules."""

    @staticmethod
    def integer_naming(point: int, filepath: Path) -> bool:
        """Return True if the file name ends with _n.raw where n is the cycle point number.\n
        Files are named like "file_01.raw" from 01 to 09 and "file_10.raw" from 10 to 99.
        """
        f_point: int = f'0{point}' if point <= 9 else point
        return filepath.stem.endswith(f'_{f_point}') and filepath.suffix == '.raw'

    @staticmethod
    def t15_naming(point: int, filepath: Path) -> bool:
        """Return True if the file name ends with _t[15*n-1].raw where n is the cycle point number."""
        return filepath.stem.endswith(f'_t{15*(point-1)}') and filepath.suffix == '.raw'

    @staticmethod
    def t15_naming_210(point: int, filepath: Path) -> bool:
        """Return True if the file name ends with _t[15*n-1].raw where n is the cycle point number."""
        return filepath.stem.endswith(f'_t{15*(point-1)+210}') and filepath.suffix == '.raw'
