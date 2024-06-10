"""
Cylc xtrigger script. Monitor the filesystem for the presence of a completed raw
file corresponding to the current workflow cycle point.
Xtriggers are referenced in the flow.cylc file, and called asynchronously in the
process pool. They must be defined in a module with the same name as the xtrigger
function. For more informations, see:
https://cylc.github.io/cylc-doc/8.2.4/html/user-guide/writing-workflows/external-triggers.html#custom-trigger-functions
"""

from pathlib import Path
from typing import Optional
import filenamesutil as fnu

# Using the logging module won't work because Cylc handles everything behind the
# scenes.
# But if you use print() and set the --debug flag when launching `cylc play`,
# Cylc will show the print() output in the scheduler log. That's why we use
# `print("Debug: 🟠 ...)` here.


def catch_raw_local(
    point: str, workflow_run_dir: str, runs_raw_dir: str
) -> tuple[bool, dict]:
    """Return `(True, {"file": raw_path})` if a completed raw file corresponding
    to the current cycle point is found in the subdirectory of `runs_raw_dir`
    matching the workflow run name.\n
    Return `(False, {})` otherwise.\n
    The "completed" state is guessed by the presence of the next raw file.
    """
    print("Debug: 🟠 `catch_raw` debug statements.")
    point = int(point)
    run_name: str = Path(workflow_run_dir).name
    rawfiles_dir = Path(runs_raw_dir, run_name).expanduser().resolve()

    if not rawfiles_dir.exists() or not rawfiles_dir.is_dir():
        print(f"Error: 🔴 {rawfiles_dir} does not exist or is not a directory.")
        return False, {}

    filenames = fnu.get_local_filenames(rawfiles_dir)
    print(f"Debug: 🟠 Filenames in {rawfiles_dir}: {filenames}")

    fn_components = [fnu.FileNameComponents.from_filename(f) for f in filenames]
    print(f"Debug: 🟠 Filename components: {fn_components}")

    current_raw: Optional[str] = None
    next_raw: Optional[str] = None
    for filename in fn_components:
        if filename.is_cyclepoint_raw(point):
            current_raw = str(filename)
        elif filename.is_cyclepoint_raw(point + 1):
            next_raw = str(filename)
        if current_raw and next_raw:
            raw_path = rawfiles_dir / Path(current_raw)
            print(f"Debug: 🟢 Found raw file: {raw_path}")
            return True, {"file": str(raw_path)}
    print("Error: 🔴 No corresponding raw file found.")
    return False, {}
