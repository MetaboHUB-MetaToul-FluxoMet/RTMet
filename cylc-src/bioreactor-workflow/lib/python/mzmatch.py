from pathlib import Path
import pandas as pd

pd.set_option("display.max_columns", None)

# Magic strings for columns names. Such good programming practice! :-)
mz_db: str = "Precursor m/z"
ids_db: str = "Precursor Name"
pol_db: str = "Precursor Charge"  # 1 / -1

intensity_q: str = "intensity"
mz_q: str = "mz"
pol_q: str = "polarity"  # p / n


def match(db_path: Path, query_path: Path, mz_tol: float) -> None:
    query_dir = Path(query_path).parent
    query_stem = ".".join(
        Path(query_path).stem.split(".")[:-1]
    )  # Removes .features.csv

    output_file_matches = Path(f"{query_dir}/{query_stem}.matches.csv")
    output_file_annotated_query = Path(
        f"{query_dir}/{query_stem}.features.annotated.csv"
    )

    original_database = pd.read_csv(db_path, sep="\t")
    original_query = pd.read_csv(query_path, sep=";")
    tol_ppm = float(mz_tol)

    query = original_query
    database = original_database

    database[pol_db] = database[pol_db].map({1: "p", -1: "n"})
    database[mz_db] = database[mz_db].apply(pd.to_numeric)
    query[[mz_q, intensity_q]] = query[[mz_q, intensity_q]].apply(pd.to_numeric)

    database["MASS_MIN"] = database[mz_db] - database[mz_db] * tol_ppm / 1e6
    database["MASS_MAX"] = database[mz_db] + database[mz_db] * tol_ppm / 1e6

    print("Database :", database.head())

    combinaisons = query.merge(database, how="cross")
    print("Combinaisons :", combinaisons.head())

    matches = combinaisons.query(f"(MASS_MIN <= {mz_q}) & ({mz_q} <= MASS_MAX)")
    matches["delta_ppm"] = (matches[mz_q] - matches[mz_db]) / matches[mz_db] * 1e6
    print("Matches :", matches.head())

    matches.to_csv(output_file_matches, sep=";", index=False, float_format="%.5f")

    # Ajouter une colonne 'annotated' à query qui contient True quand une ligne de matches contient les mêmes valeurs pour la colonne mz.
    query["annotated"] = query[mz_q].isin(matches[mz_q])

    print("Annotated query :", query.head(n=20))

    matches = matches[[ids_db, mz_q, "delta_ppm", intensity_q]].rename(
        columns={ids_db: "isobaric_id", mz_q: "feature_mz", intensity_q: "intensity"}
    )

    # Le résultat est arrondi à 5 chiffres après la virgule. Ne pas utiliser l'écriture scientifique.
    matches.to_csv(output_file_matches, sep=";", index=False, float_format="%.5f")
    query.to_csv(output_file_annotated_query, sep=";", index=False)
