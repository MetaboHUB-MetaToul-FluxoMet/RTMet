"""
Cylc xtrigger script. Monitor the presence of a completed raw file,
either locally or remotely.
Catch when a ThermoFisher raw file has been created.
"""

from pathlib import Path
from typing import Optional

from fabric import Connection
import filenamesutil as fnu

# Using the logging module won't work because Cylc handles everything
# behind the scenes.
# But if you use print() and set the --debug flag when launching
# `cylc play`, Cylc will show the print() output in the scheduler log.


def catch_raw(
    point: str,
    workflow_run_dir: str,
    runs_raw_dir: str = "",
    remote: bool = False,
    host: str = None,
) -> tuple[bool, dict]:
    """Return {True, ......\n
    Return (False, {}) otherwise.
    """
    print("Debug: 🟠 `catch_raw` debug statements.")

    point: int = int(point)
    workflow_run_dir: Path = Path(workflow_run_dir)

    workflow_name: str = workflow_run_dir.name

    self_contained = False
    if not runs_raw_dir:
        self_contained = True
        rawfiles_dir: Path = workflow_run_dir / "raws"
        rawfiles_dir.mkdir(exist_ok=True)
    else:
        rawfiles_dir: Path = Path(runs_raw_dir) / workflow_name

    if not remote:
        rawfiles_dir = Path(rawfiles_dir).expanduser().resolve()
        if not rawfiles_dir.exists() or not rawfiles_dir.is_dir():
            print(f"Error: 🔴 {rawfiles_dir} does not exist or is not a directory.")
            return False, {}
        filenames = fnu.get_local_filenames(rawfiles_dir)
    else:
        with Connection(host) as conn:
            filenames = fnu.get_remote_filenames(conn, rawfiles_dir)

    print(f"Debug: 🟠 Filenames in {rawfiles_dir}: {filenames}")

    fn_components = [fnu.FileNameComponents.from_filename(f) for f in filenames]
    print(f"Debug: 🟠 Filename components: {fn_components}")

    current_raw: Optional[str] = None
    next_raw: Optional[str] = None
    for fn in fn_components:
        if is_cyclepoint_raw(point, fn):
            current_raw = fn.to_string()
        elif is_cyclepoint_raw(point + 1, fn):
            next_raw = fn.to_string()
        if current_raw and next_raw:
            break

    if current_raw:
        raw_path = str(rawfiles_dir / Path(current_raw))
        if next_raw or self_contained:
            return True, {"file": raw_path}
    return False, {}

    # for filepath in rawfiles_dir.iterdir():
    #     if (
    #         filepath.is_file()
    #         and filename_rule(point, filepath)
    #         and not (filepath / ".lock").is_dir()
    #         # lockdir are created by the scp daemon when the file is being
    #         # copied and are removed when the copy is finished
    #     ):
    #         return True, {
    #             "file": str(filepath),
    #             "working_dir": str(Path.cwd()),
    #         }
    # return False, {}


def is_cyclepoint_raw(point: int, filename: fnu.FileNameComponents) -> bool:
    """Return True if the file name ends with _n where n is the cycle point
    number. Zero padding (01, 001, etc. for 1) is supported.
    """
    if filename.extension == ".raw" and filename.stem_suffix.isdigit():
        return int(filename.stem_suffix) == point
    return False


# class FilenameRules:
#     """A class to store all the filename rules."""

#     @staticmethod
#     def is_integer_named(point: int, filestem: str) -> bool:
#         """Return True if the file stem ends with _n where n is the cycle point
#         number. Zero padding (01, 001, etc. for 1) is supported.
#         """
#         stem_suffix = filestem.split("_")[-1]
#         return int(stem_suffix) == point if stem_suffix.isdigit() else False

#     @staticmethod
#     def t15_naming(point: int, filepath: Path) -> bool:
#         """Return True if the file name ends with _t[15*n-1].raw where n is the cycle point
#         number."""
#         return filepath.stem.endswith(f"_t{15*(point-1)}") and filepath.suffix == ".raw"

#     @staticmethod
#     def t15_naming_210(point: int, filepath: Path) -> bool:
#         """Return True if the file name ends with _t[15*n-1].raw where n is the cycle point
#         number."""
#         return (
#             filepath.stem.endswith(f"_t{15*(point-1)+210}")
#             and filepath.suffix == ".raw"
#         )
