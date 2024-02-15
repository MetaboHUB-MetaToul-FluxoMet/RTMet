import os
import os.path as path
from datetime import datetime

# Catch when a ThermoFisher raw file has been created

# Sort all the .raw files in the mass spectrometer output dir by date of last modification.
# If there are more than 2 files: take the oldest one, move it out of the dir and process it.

def catch_raw(*args, **kwargs):
    #print("Current working dir: " + os.getcwd())
    input_dir = path.join(os.getcwd(), "input_dir")
    files_datetimes = get_files_datetimes(input_dir)
    for key, value in files_datetimes.items():
        print(f'{key}: {value}')
    return False, {}

def get_files_datetimes(input_dir):
    file_mod_times = {}
    for file_name in os.listdir(input_dir):
        file_path = os.path.join(input_dir, file_name)
        if os.path.isfile(file_path):
            modification_time = os.path.getmtime(file_path)
            formatted_time = datetime.fromtimestamp(modification_time).strftime('%Y-%m-%d %H:%M:%S')
            file_mod_times[file_name] = formatted_time
    return file_mod_times