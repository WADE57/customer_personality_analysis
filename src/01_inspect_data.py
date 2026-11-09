from pathlib import Path
import hashlib
import csv
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"

def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def load_table(path: Path) -> pd.DataFrame:
    suffix = path.suffix.lower()

    if suffix == ".csv":
        try:
            with path.open("r", encoding="utf-8-sig", newline="") as f:
                sample = f.read(8192)
        except UnicodeDecodeError:
            with path.open("r", encoding="latin-1", newline="") as f:
                sample = f.read(8192)

        # Détection automatique du séparateur
        try:
            delimiter = csv.Sniffer().sniff(
                sample,
                delimiters="\t,;|"
            ).delimiter
        except csv.Error:
            delimiter = (
                "\t" if sample.count("\t") > sample.count(",")
                else ","
            )

        try:
            df = pd.read_csv(
                path,
                sep=delimiter,
                encoding="utf-8-sig"
            )
        except UnicodeDecodeError:
            df = pd.read_csv(
                path,
                sep=delimiter,
                encoding="latin-1"
            )

        # Nettoyage des noms de colonnes
        df.columns = df.columns.str.strip()

        # Suppression des espaces superflus dans les chaînes
        for col in df.select_dtypes(include="object").columns:
            df[col] = df[col].str.strip()

        print("\n" + "="*60)
        print("VERIFICATIONS COMPLEMENTAIRES")
        print("="*60)

        # 1. Vérifier les valeurs particulières dans Income
        print("\n1. Valeurs de Income :")
        print(df["Income"].value_counts(dropna=False).head(20))

        # 2. Vérifier les variables constantes
        print("\n2. Nombre de valeurs uniques :")
        print(df[["Z_CostContact", "Z_Revenue"]].nunique())

        # 3. Vérifier les catégories
        print("\n3. Education :")
        print(df["Education"].value_counts())

        print("\n4. Marital_Status :")
        print(df["Marital_Status"].value_counts())

        # 4. Vérifier les dates
        print("\n5. Aperçu des dates :")
        print(df["Dt_Customer"].head())

        # 5. Statistiques descriptives
        print("\n6. Statistiques descriptives :")
        print(df.describe().T)

        return df

    if suffix in {".xlsx", ".xls"}:
        return pd.read_excel(path)

    raise ValueError(f"Format non pris en charge : {suffix}")


def summarize(path: Path) -> None:
    df = load_table(path)
    print("\n" + "=" * 80)
    print(f"Fichier : {path.name}")
    print(f"SHA-256 : {sha256(path)}")
    print(f"Dimensions : {df.shape[0]} lignes × {df.shape[1]} colonnes")
    print("\nColonnes et types :")
    print(df.dtypes.to_string())
    print("\nValeurs manquantes (top 20) :")
    print(df.isna().sum().sort_values(ascending=False).head(20).to_string())
    print(f"Doublons exacts : {df.duplicated().sum()}")
    print("\nAperçu :")
    print(df.head(5).to_string(index=False))

if __name__ == "__main__":
    candidates = [p for p in RAW.iterdir() if p.is_file() and p.suffix.lower() in {".csv", ".xlsx", ".xls"}]
    if not candidates:
        print(f"Aucun CSV/Excel trouvé dans {RAW}. Ajoute les deux fichiers de données dans ce dossier.")
    else:
        for file in sorted(candidates):
            summarize(file)