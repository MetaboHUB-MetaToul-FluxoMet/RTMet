from pathlib import Path
import pandas as pd

pd.set_option("display.max_columns", None)

# Again, Magic strings for columns names. Yikes!
ids_db: str = "Isobaric ID"
ref_mol_db: str = "Ref Isobaric ID"
coeff_a_db: str = "Coeff A"
coeff_b_db: str = "Coeff B"

ids_mtc: str = "isobaric_id"
intens_mtc: str = "intensity"

relative_c: str = "relative_intensity"
absolute_c: str = "concentration"


def quantify(db_path: Path, matches_path: Path) -> None:
    database: pd.DataFrame = pd.read_csv(db_path, sep=";")
    matches: pd.DataFrame = pd.read_csv(matches_path, sep=";")

    matches_dir = Path(matches_path).parent
    matches_stem = ".".join(
        Path(matches_path).stem.split(".")[:-1]
    )  # Removes .matches.csv

    # Define output files paths
    output_file_concentrations = Path(
        f"{matches_dir}/{matches_stem}.concentrations.csv"
    )
    output_file_quantified_matches = Path(
        f"{matches_dir}/{matches_stem}.features.quantified.csv"
    )

    # ❗️❗️❗️TEMPORAIRE❗️❗️❗️: drop les lignes avec ids_mtc dupliqués
    matches = matches.drop_duplicates(subset=ids_mtc)
    # Il faut faire autrement, notamment fusionner les pics scindés par binneR.

    for col_db in (ref_mol_db, coeff_a_db, coeff_b_db):
        matches[col_db] = matches[ids_mtc].map(database.set_index(ids_db)[col_db])

    # Compute the relative concentration of each feature.
    matches[relative_c] = matches[intens_mtc] / matches[ref_mol_db].map(
        matches.set_index(ids_mtc)[intens_mtc]
    )

    # relative_c = A * absolute_c + B   (y = ax + b)
    # absolute_c = (relative_c - B) / A
    matches[absolute_c] = (matches[relative_c] - matches[coeff_b_db]) / matches[
        coeff_a_db
    ]

    print(matches.head())


if __name__ == "__main__":
    db_path = Path("molecules_db.csv")
    matches_path = Path("run2.matches.csv")
    quantify(db_path, matches_path)
