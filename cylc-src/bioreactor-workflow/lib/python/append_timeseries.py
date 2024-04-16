#from pathlib import Path
import os
import pandas as pd

CYLC_WORKFLOW_SHARE_DIR: str = os.environ['CYLC_WORKFLOW_SHARE_DIR']
CYLC_TASK_CYCLE_POINT: str = os.environ['CYLC_TASK_CYCLE_POINT']
NAMES_DB: int = int(os.environ['NAMES_DB']) - 1 # 0-indexed
RAWFILE_STEM: str = os.environ['RAWFILE_STEM']

def append_mzmatch():
    matches = pd.read_csv(f'{CYLC_WORKFLOW_SHARE_DIR}/{CYLC_TASK_CYCLE_POINT}/{RAWFILE_STEM}_mzmatches.tsv', sep='\t')
    intensity_timeseries = pd.read_csv(f'{CYLC_WORKFLOW_SHARE_DIR}/intensity_timeseries_mzmatch.tsv', sep='\t')
    matches['compound'] = matches.iloc[:, 9]
    # /!\ sort might be resource intensive. May need to be optimized
    matches = matches.sort_values('intensity', ascending=False).drop_duplicates('compound').sort_index()
    # Dropping duplicates is necessary for the map method.
    intensity_timeseries[str(CYLC_TASK_CYCLE_POINT)] = intensity_timeseries.iloc[:,NAMES_DB].map(matches.set_index('compound')['intensity'])
    intensity_timeseries.to_csv(f'{CYLC_WORKFLOW_SHARE_DIR}/intensity_timeseries_mzmatch.tsv', sep='\t', na_rep='NA', index=False)
    