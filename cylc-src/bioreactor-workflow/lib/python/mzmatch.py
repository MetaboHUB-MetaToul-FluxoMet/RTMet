import os
from enum import Enum
import pandas as pd

CYLC_WORKFLOW_RUN_DIR: str = os.environ['CYLC_WORKFLOW_RUN_DIR']
CYLC_WORKFLOW_SHARE_DIR: str = os.environ['CYLC_WORKFLOW_SHARE_DIR']
CYLC_TASK_CYCLE_POINT: str = os.environ['CYLC_TASK_CYCLE_POINT']
RAWFILE_STEM: str = os.environ['RAWFILE_STEM']
DATABASE_FILE: str = os.environ['DATABASE_FILE']
MZ_DB: int = int(os.environ['MZ_DB']) - 1 # 0-indexed
DELTA_TYPE: str = os.environ['DELTA_TYPE']
DELTA: int = int(os.environ['DELTA'])

class DeltaType(Enum):
    PPM = 1
    DA = 2

def match():
    # Précondition: les paramètres obtenus par l'environnement sont corrects. Non vérifié ici.
    database = pd.read_csv(f'{CYLC_WORKFLOW_RUN_DIR}/db/{DATABASE_FILE}', sep='\t')
    queries = pd.read_csv(f'{CYLC_WORKFLOW_SHARE_DIR}/{CYLC_TASK_CYCLE_POINT}/{RAWFILE_STEM}.features.csv', sep=';')
    output_file = f'{CYLC_WORKFLOW_SHARE_DIR}/{CYLC_TASK_CYCLE_POINT}/{RAWFILE_STEM}.matches.csv'
    # column INDEX (0-based) of the mass in the database and query files
    mz_db: int = MZ_DB
    # mz_q: int = 0 # based on binneR output
    mz_q = queries.columns.get_loc("mz")
    # transform the string into the corresponding enum value
    delta_type: DeltaType = DeltaType.PPM if DELTA_TYPE == 'ppm' else DeltaType.DA
    mass_delta: int = DELTA

    # Dans la base de données, à partir de la colonne MASS, on calcule les masses min et max en fonction du type de delta
    # et de la valeur. Les résultats sont stockés dans les colonnes MASS_MIN et MASS_MAX
    if delta_type == DeltaType.PPM:
        database['MASS_MIN'] = database.iloc[:,mz_db] - database.iloc[:,mz_db] * mass_delta / 1e6
        database['MASS_MAX'] = database.iloc[:,mz_db] + database.iloc[:,mz_db] * mass_delta / 1e6
    elif delta_type == DeltaType.DA:
        database['MASS_MIN'] = database.iloc[:,mz_db] - mass_delta
        database['MASS_MAX'] = database.iloc[:,mz_db] + mass_delta

    #print(database.head())

    out = queries.merge(database, how='cross').query('(MASS_MIN <= mz) & (mz <= MASS_MAX)')
    # Ajouter une colonne DELTA_MZ qui contient la différence entre la masse de la base de données et la masse de la requête.
    # Le résultat est arrondi à 5 chiffres après la virgule. Ne pas utiliser l'écriture scientifique.
    mz_db_out = len(queries.columns) + mz_db
    out['DELTA_MZ'] = out.iloc[:,mz_db_out] - out.iloc[:,mz_q]

    #enlever les colonnes MASS_MIN et MASS_MAX
    out = out.drop(columns=['MASS_MIN', 'MASS_MAX'])

    out.to_csv(output_file, sep=';', index=False, float_format='%.5f')
