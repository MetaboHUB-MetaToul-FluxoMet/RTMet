#from pathlib import Path
import os
import pandas as pd

CYLC_WORKFLOW_SHARE_DIR = os.environ['CYLC_WORKFLOW_SHARE_DIR']
CYLC_TASK_CYCLE_POINT = os.environ['CYLC_TASK_CYCLE_POINT']

def append():
    matches = pd.read_csv(f'{CYLC_WORKFLOW_SHARE_DIR}/{CYLC_TASK_CYCLE_POINT}/features_annotated_matches.tsv', sep='\t')
    intensity_timeseries = pd.read_csv(f'{CYLC_WORKFLOW_SHARE_DIR}/intensity_timeseries.tsv', sep='\t')
    matches['compound'] = matches.iloc[:, 9].apply(lambda x: x.split('#')[3])
    matches = matches.sort_values('intensity', ascending=False).drop_duplicates('compound').sort_index()
    intensity_timeseries[str(CYLC_TASK_CYCLE_POINT)] = intensity_timeseries['NAME'].map(matches.set_index('compound')['intensity'])
    intensity_timeseries.to_csv(f'{CYLC_WORKFLOW_SHARE_DIR}/intensity_timeseries.tsv', sep='\t', na_rep='NA', index=False)
