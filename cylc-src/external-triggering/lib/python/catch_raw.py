from pathlib import Path
from datetime import datetime

# Catch when a ThermoFisher raw file has been created

# Sort all the .raw files in the mass spectrometer output dir by date of
# last modification. If there are more than 2 files: take the oldest one,
# move it out of the dir and process it.

def catch_raw() -> tuple[bool, dict]:
    """Take the oldest .raw file in the input_dir and return its name
    and last modification time.
    """
    #print("Current working dir: " + Path.cwd())
    input_dir = Path.cwd() / "input_dir"
    files_datetimes = get_raws_datetimes(input_dir)
    for key, value in files_datetimes.items():
        print(f'{key}: {value}')
    return False, {}

def get_raws_datetimes(input_dir: Path):
    """Return a dictionary of raw file names in the directory and
    their last modification times.
    """
    file_mod_times: dict = {}
    for file_name in input_dir.iterdir():
        if file_name.is_file() and file_name.suffix == '.raw':
            modification_time = file_name.stat().st_mtime
            formatted_time: datetime = datetime.fromtimestamp(modification_time)#\
                #.strftime('%Y-%m-%d %H:%M:%S')
            file_mod_times[file_name] = formatted_time
    return file_mod_times
