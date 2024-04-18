"""
    This module provides classes to match MS peaks to a user-provided database
    of known molecules.
    The module can also be run as a shell script.
"""

from dataclasses import dataclass
from enum import StrEnum
from pathlib import Path
import pandas as pd


class DeltaType(StrEnum):
    """Delta types for tolerances. PPM: parts per million, DA: Dalton"""

    PPM = "ppm"
    ABS = "absolute"
    DA = "absolute"
    MIN = "absolute"

    @staticmethod
    def from_string(label: str):
        if not isinstance(label, str):
            raise TypeError("label must be a string")
        if label.lower() in ("ppm"):
            return DeltaType.PPM
        if label.lower() in ("dalton", "da", "absolute", "abs", "minute", "min"):
            return DeltaType.ABS
        raise ValueError(f"Invalid DeltaType: {label}")


@dataclass
class Tolerance:
    """A tolerance value with a deltatype (PPM or DA)."""

    value: float
    deltatype: DeltaType


class _Feature:
    def __init__(self, mz: float, rt: float = None, metadata: dict = None):
        self.mz = mz
        self.rt = rt
        self.metadata = {} if metadata is None else metadata

    def has_rt(self) -> bool:
        """Returns whether the feature has a retention time.

        Returns:
            bool: True if the feature has a retention time, False otherwise.
        """
        return self.rt is not None

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, _Feature):
            return False
        return self.mz == other.mz and self.rt == other.rt

    def _delta_attr(self, other, attr, deltatype) -> float:
        # compute the difference between the attribute (mz or rt) of this feature
        # and of another feature
        self_attr = getattr(self, attr)
        other_attr = getattr(other, attr)
        if deltatype == DeltaType.PPM:
            return (self_attr - other_attr) / other_attr * 1e6
        if deltatype == DeltaType.ABS:
            return self_attr - other_attr
        raise ValueError(f"Invalid DeltaType: {deltatype}")

    def delta_mz(self, other: "_Feature", deltatype=DeltaType.PPM) -> float:
        """Returns the difference in mass-to-charge ratio between this feature
        and another feature.

        Args:
            other (_Feature): The other feature to compare with.
            deltatype (DeltaType): The mass tolerance type.

        Returns:
            float: The difference in mass-to-charge ratio.
        """
        return self._delta_attr(other, "mz", deltatype)

    def delta_rt(self, other: "_Feature", deltatype=DeltaType.PPM) -> float:
        """Returns the difference in retention time between this feature and
        another feature.

        Args:
            other (_Feature): The other feature to compare with.
            delta_type (DeltaType): The retention time tolerance type.

        Returns:
            float: The difference in retention time.
        """
        return self._delta_attr(other, "rt", deltatype)

    def _match_attr(self, other, attr, tol) -> bool:
        return abs(self._delta_attr(other, attr, tol.deltatype)) <= tol.value

    def match_mz(self, other: "_Feature", tol: Tolerance) -> bool:
        """Returns whether the feature mz matches another feature mz within a
        given tolerance.

        Args:
            other (_Feature): The other feature to compare with.
            tol (Tolerance): The mass-to-charge ratio tolerance.
        Returns:
            bool: True if the mass-to-charge ratio matches, False otherwise.
        """
        return self._match_attr(other, "mz", tol)

    def match_rt(self, other: "_Feature", tol: Tolerance) -> bool:
        """Returns whether the feature rt matches another feature rt within a
        given tolerance.

        Args:
            other (_Feature): The other feature to compare with.
            tol (Tolerance): The retention time tolerance.
        Returns:
            bool: True if retention time matches, False otherwise.
        """
        return self._match_attr(other, "rt", tol)


class Peak(_Feature):
    """
    A peak in a mass spectrometry experiment. It must at least have an intensity
    and a mass-to-charge ratio (mz). Additional metadata can be provided as a
    dictionary.
    """

    def __init__(
        self, intensity: float, mz: float, rt: float = None, metadata: dict = None
    ):
        super().__init__(mz, rt, metadata)
        self.intensity = intensity


class Molecule(_Feature):
    """
    A molecule is a known compound that can be detected in a mass spectrometry
    experiment. It must at least have a name and a mass-to-charge ratio (mz).
    Optionally, it can have a retention time (rt), and tolerances given as
    absolute values.
    Additional metadata can be provided as a dictionary.
    """

    def __init__(
        self,
        name: str,
        mz: float,
        rt: float = None,
        mz_tol: Tolerance = None,
        rt_tol: Tolerance = None,
        metadata: dict = None,
    ):
        super().__init__(mz, rt, metadata)
        self.name = name
        self.mz_tol = mz_tol
        if rt_tol is not None and rt is None:
            raise ValueError(
                "Retention time tolerance cannot be set without a retention time."
            )
        self.rt_tol = rt_tol


class MzQuery:
    def __init__(self, peaks: list[Peak]):
        self.peaks = peaks

    @staticmethod
    def from_dataframe(df: pd.DataFrame):
        """Creates a MzQuery from a pandas DataFrame.

        Args:
            df (pd.DataFrame): The DataFrame containing the peaks.

        Returns:
            MzQuery: The MzQuery object.
        """
        peaks = []
        for _, row in df.iterrows():
            intensity = row["intensity"]
            mz = row["mz"]
            rt = row.get("rt")

            metadata = row.drop(["intensity", "mz", "rt"], errors="ignore")

            peaks.append(Peak(intensity, mz, rt, metadata.to_dict()))
        return MzQuery(peaks)


class MzDatabase:
    def __init__(self, molecules: list[Molecule]):
        self.molecules = molecules

    @staticmethod
    def from_dataframe(df: pd.DataFrame):
        """Creates a MzDatabase from a pandas DataFrame.

        Args:
            df (pd.DataFrame): The DataFrame containing the molecules.

        Returns:
            MzDatabase: The MzDatabase object.
        """
        molecules = []
        for _, row in df.iterrows():
            name = row["name"]
            mz = row["mz"]
            rt = row.get("rt")

            if row.get("mz_tol") is not None:
                mz_tol = Tolerance(row["mz_tol"], DeltaType.PPM)
            else:
                mz_tol = None

            if row.get("rt_tol") is not None:
                rt_tol = Tolerance(row["rt_tol"], DeltaType.MIN)
            else:
                rt_tol = None

            metadata = row.drop(
                ["name", "mz", "rt", "mz_tol", "rt_tol"], errors="ignore"
            )

            molecules.append(Molecule(name, mz, rt, mz_tol, rt_tol, metadata.to_dict()))
        return MzDatabase(molecules)


# def match_v2(query: MzQuery, database_file: MzDatabase, delta_type: str = 'ppm', mass_delta: float = 10.0) -> pd.DataFrame:
#     """_summary_

#     Args:
#         query_file (Path): _description_
#         database_file (Path): _description_
#         mz_db (int): _description_
#         mz_q (int): _description_
#         delta_type (str, optional): _description_. Defaults to 'ppm'.
#         mass_delta (float, optional): _description_. Defaults to 10.0.

#     Returns:
#         pd.DataFrame: _description_
#     """
#     query_file = Path(query_file)
#     database_file = Path(database_file)
#     delta_type = DeltaType.from_string(delta_type)
#     mass_delta = float(mass_delta)


#     database = pd.read_csv(f'{CYLC_WORKFLOW_RUN_DIR}/db/{DATABASE_FILE}', sep='\t')
#     queries = pd.read_csv(f'{CYLC_WORKFLOW_SHARE_DIR}/{CYLC_TASK_CYCLE_POINT}/{RAWFILE_STEM}.features.csv', sep=';')
#     output_file = f'{CYLC_WORKFLOW_SHARE_DIR}/{CYLC_TASK_CYCLE_POINT}/{RAWFILE_STEM}.matches.csv'
#     # column INDEX (0-based) of the mass in the database and query files
#     mz_db: int = MZ_DB
#     #mz_q: int = 0 # based on binneR output
#     mz_q = queries.columns.get_loc("mz")
#     # transform the string into the corresponding enum value

#     mass_delta: int = DELTA

#     # Dans la base de données, à partir de la colonne MASS, on calcule les masses min et max en fonction du type de delta
#     # et de la valeur. Les résultats sont stockés dans les colonnes MASS_MIN et MASS_MAX
#     if delta_type == DeltaType.PPM:
#         database['MASS_MIN'] = database.iloc[:,mz_db] - database.iloc[:,mz_db] * mass_delta / 1e6
#         database['MASS_MAX'] = database.iloc[:,mz_db] + database.iloc[:,mz_db] * mass_delta / 1e6
#     elif delta_type == DeltaType.DA:
#         database['MASS_MIN'] = database.iloc[:,mz_db] - mass_delta
#         database['MASS_MAX'] = database.iloc[:,mz_db] + mass_delta

#     #print(database.head())

#     out = queries.merge(database, how='cross').query('(MASS_MIN <= mz) & (mz <= MASS_MAX)')
#     # Ajouter une colonne DELTA_MZ qui contient la différence entre la masse de la base de données et la masse de la requête.
#     # Le résultat est arrondi à 5 chiffres après la virgule. Ne pas utiliser l'écriture scientifique.
#     mz_db_out = len(queries.columns) + mz_db
#     out['DELTA_MZ'] = out.iloc[:,mz_db_out] - out.iloc[:,mz_q]

#     #enlever les colonnes MASS_MIN et MASS_MAX
#     out = out.drop(columns=['MASS_MIN', 'MASS_MAX'])

#     out.to_csv(output_file, sep=';', index=False, float_format='%.5f')


if __name__ == "__main__":
    print("Hello world. We're running in script mode.")
