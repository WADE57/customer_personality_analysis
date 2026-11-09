
from pathlib import Path
import pandas as pd
import csv

# ============================================================
# 1. CONFIGURATION DES CHEMINS
# ============================================================

ROOT = Path(__file__).resolve().parents[1]

RAW = ROOT / "data" / "raw"
PROCESSED = ROOT / "data" / "processed"

PROCESSED.mkdir(parents=True, exist_ok=True)

INPUT_FILE = RAW / "marketing_campaign.csv"
OUTPUT_FILE = PROCESSED / "marketing_campaign_clean.csv"


# ============================================================
# 2. DETECTION DU SEPARATEUR
# ============================================================

def detect_separator(file_path):

    with open(file_path, "r", encoding="utf-8-sig") as f:
        sample = f.read(10000)

    try:
        dialect = csv.Sniffer().sniff(
            sample,
            delimiters=";,\t|"
        )
        return dialect.delimiter

    except csv.Error:
        return ","


# ============================================================
# 3. CHARGEMENT DES DONNEES
# ============================================================

print("=" * 65)
print("DEBUT DU NETTOYAGE DES DONNEES")
print("=" * 65)

if not INPUT_FILE.exists():
    raise FileNotFoundError(
        f"Fichier source introuvable : {INPUT_FILE}"
    )

separator = detect_separator(INPUT_FILE)

df = pd.read_csv(
    INPUT_FILE,
    sep=separator,
    encoding="utf-8-sig",
    skipinitialspace=True
)

print("\nSéparateur détecté :", repr(separator))
print("Dimensions initiales :", df.shape)


# ============================================================
# 4. NORMALISATION DES NOMS DE COLONNES
# ============================================================

# Suppression des espaces avant et après les noms
df.columns = df.columns.str.strip()

# Remplacement des espaces multiples par _
df.columns = df.columns.str.replace(
    r"\s+",
    "_",
    regex=True
)

print("\nColonnes après normalisation :")
print(df.columns.tolist())

# Vérification des colonnes indispensables
colonnes_requises = [
    "ID",
    "Income",
    "Dt_Customer",
    "Year_Birth",
    "Education",
    "Marital_Status",
    "Kidhome",
    "Teenhome"
]

for col in colonnes_requises:
    if col not in df.columns:
        raise ValueError(f"Colonne indispensable manquante : {col}")

# Vérification des noms de colonnes dupliqués
if df.columns.duplicated().any():
    raise ValueError("Des noms de colonnes sont dupliqués.")


# ============================================================
# 5. NETTOYAGE DES VARIABLES TEXTUELLES
# ============================================================

print("\nNettoyage des variables textuelles...")

for col in df.select_dtypes(
    include=["object", "str"]
).columns:

    df[col] = df[col].astype("string").str.strip()

# Remplacement des chaînes vides par des valeurs manquantes
df = df.replace(r"^\s*$", pd.NA, regex=True)


# ============================================================
# 6. NETTOYAGE DE LA VARIABLE INCOME
# ============================================================

print("\n" + "=" * 65)
print("6. NETTOYAGE DE INCOME")
print("=" * 65)

df["Income"] = pd.to_numeric(
    df["Income"],
    errors="coerce"
)

print("Type :", df["Income"].dtype)
print("Valeurs manquantes :", df["Income"].isna().sum())

print("\nStatistiques du revenu :")
print(df["Income"].describe())

# Vérification des revenus négatifs
revenus_negatifs = (df["Income"] < 0).sum()

print("Revenus négatifs :", revenus_negatifs)


# ============================================================
# 7. CONVERSION DE LA VARIABLE DATE
# ============================================================

print("\n" + "=" * 65)
print("7. CONVERSION DES DATES")
print("=" * 65)

print("Dates originales :")
print(df["Dt_Customer"].head())

df["Dt_Customer"] = pd.to_datetime(
    df["Dt_Customer"],
    dayfirst=True,
    errors="coerce"
)

print("\nDates converties :")
print(df["Dt_Customer"].head())

print(
    "Dates manquantes ou invalides :",
    df["Dt_Customer"].isna().sum()
)

print("Date minimale :", df["Dt_Customer"].min())
print("Date maximale :", df["Dt_Customer"].max())


# ============================================================
# 8. VERIFICATION DES IDENTIFIANTS
# ============================================================

print("\n" + "=" * 65)
print("8. VERIFICATION DES IDENTIFIANTS")
print("=" * 65)

df["ID"] = pd.to_numeric(
    df["ID"],
    errors="coerce"
)

print("Identifiants manquants :", df["ID"].isna().sum())
print("Identifiants uniques :", df["ID"].nunique())
print("Identifiants dupliqués :", df["ID"].duplicated().sum())

# Un identifiant doit être présent et unique
if df["ID"].isna().any():
    raise ValueError("Des identifiants clients sont manquants.")

if df["ID"].duplicated().any():
    raise ValueError("Des identifiants clients sont dupliqués.")


# ============================================================
# 9. DETECTION DES VARIABLES CONSTANTES
# ============================================================

print("\n" + "=" * 65)
print("9. VARIABLES CONSTANTES")
print("=" * 65)

colonnes_constantes = [
    col
    for col in df.columns
    if df[col].nunique(dropna=False) <= 1
]

print("Variables constantes :", colonnes_constantes)

df = df.drop(columns=colonnes_constantes)

print(
    "Nombre de variables supprimées :",
    len(colonnes_constantes)
)


# ============================================================
# 10. CREATION DE NOUVELLES VARIABLES
# ============================================================

print("\n" + "=" * 65)
print("10. CREATION DE VARIABLES")
print("=" * 65)

# ------------------------------------------------------------
# 10.1 Nombre d'enfants et d'adolescents dans le foyer
# ------------------------------------------------------------

df["Nb_Enfants_Foyer"] = (
    df["Kidhome"] + df["Teenhome"]
)

# ------------------------------------------------------------
# 10.2 Dépenses totales par client
# ------------------------------------------------------------

colonnes_depenses = [
    "MntWines",
    "MntFruits",
    "MntMeatProducts",
    "MntFishProducts",
    "MntSweetProducts",
    "MntGoldProds"
]

for col in colonnes_depenses:
    if col not in df.columns:
        raise ValueError(f"Colonne de dépenses manquante : {col}")

df["Total_Spend"] = df[colonnes_depenses].sum(axis=1)

# ------------------------------------------------------------
# 10.3 Nombre total d'achats par canal
# ------------------------------------------------------------

colonnes_achats = [
    "NumWebPurchases",
    "NumCatalogPurchases",
    "NumStorePurchases"
]

for col in colonnes_achats:
    if col not in df.columns:
        raise ValueError(f"Colonne d'achats manquante : {col}")

df["Total_Purchases"] = df[colonnes_achats].sum(axis=1)

# NumDealsPurchases reste une variable indépendante.
# Elle ne doit pas être ajoutée une deuxième fois aux achats.

# ------------------------------------------------------------
# 10.4 Calcul approximatif de l'âge
# ------------------------------------------------------------

date_reference = pd.Timestamp("2014-06-29")

df["Age_Client"] = (
    date_reference.year - df["Year_Birth"]
)

print("Variables créées :")
print("- Nb_Enfants_Foyer")
print("- Total_Spend")
print("- Total_Purchases")
print("- Age_Client")


# ============================================================
# 11. DETECTION DES ANOMALIES DE NAISSANCE
# ============================================================

print("\n" + "=" * 65)
print("11. ANNEES DE NAISSANCE SUSPECTES")
print("=" * 65)

anomalies_naissance = df[
    (df["Year_Birth"] < 1900) |
    (df["Year_Birth"] > 2014)
]

print(
    "Nombre d'observations suspectes :",
    len(anomalies_naissance)
)

print(
    anomalies_naissance[
        ["ID", "Year_Birth", "Age_Client"]
    ]
)

# Les observations suspectes sont conservées.
# Elles seront examinées pendant l'analyse exploratoire.


# ============================================================
# 12. EXAMEN DES REVENUS EXTREMES
# ============================================================

print("\n" + "=" * 65)
print("12. REVENUS EXTREMES")
print("=" * 65)

seuil_revenu = df["Income"].quantile(0.99)

revenus_extremes = df[
    df["Income"] > seuil_revenu
].sort_values(
    "Income",
    ascending=False
)

print("Seuil du 99e percentile :", seuil_revenu)

print(
    revenus_extremes[
        ["ID", "Income", "Education", "Marital_Status"]
    ].head(20)
)

# Aucune suppression automatique des valeurs extrêmes.


# ============================================================
# 13. CONTROLES DE COHERENCE
# ============================================================

print("\n" + "=" * 65)
print("13. CONTROLES DE COHERENCE")
print("=" * 65)

# ------------------------------------------------------------
# 13.1 Vérification des dépenses négatives
# ------------------------------------------------------------

depenses_negatives = (
    df[colonnes_depenses] < 0
).sum().sum()

print("Dépenses négatives :", depenses_negatives)

# ------------------------------------------------------------
# 13.2 Vérification des achats négatifs
# ------------------------------------------------------------

achats_negatifs = (
    df[colonnes_achats] < 0
).sum().sum()

print("Achats négatifs :", achats_negatifs)

# ------------------------------------------------------------
# 13.3 Vérification des variables de campagne
# ------------------------------------------------------------

colonnes_campagnes = [
    "AcceptedCmp1",
    "AcceptedCmp2",
    "AcceptedCmp3",
    "AcceptedCmp4",
    "AcceptedCmp5",
    "Response"
]

print("\nDistribution des variables de campagne :")

for col in colonnes_campagnes:

    if col not in df.columns:
        raise ValueError(f"Colonne de campagne manquante : {col}")

    print(
        f"{col} :",
        df[col].value_counts(dropna=False).to_dict()
    )

    valeurs_valides = set(df[col].dropna().unique())

    if not valeurs_valides.issubset({0, 1}):
        print(
            f"ATTENTION : {col} contient des valeurs différentes de 0 et 1."
        )


# ============================================================
# 14. CONTROLE FINAL
# ============================================================

print("\n" + "=" * 65)
print("14. CONTROLE FINAL")
print("=" * 65)

print("Dimensions finales :", df.shape)

print("\nValeurs manquantes :")

print(
    df.isna()
    .sum()
    .sort_values(ascending=False)
    .head(20)
)

print("\nTypes des variables :")
print(df.dtypes)

print("\nDoublons exacts :", df.duplicated().sum())

print("\nAperçu du dataset :")
print(df.head())

print("\nStatistiques des nouvelles variables :")

print(
    df[
        [
            "Nb_Enfants_Foyer",
            "Age_Client",
            "Total_Spend",
            "Total_Purchases"
        ]
    ].describe()
)


# ============================================================
# 15. SAUVEGARDE DU DATASET NETTOYE
# ============================================================

df.to_csv(
    OUTPUT_FILE,
    index=False,
    encoding="utf-8-sig"
)

print("\n" + "=" * 65)
print("NETTOYAGE TERMINE")
print("=" * 65)

print("Fichier enregistré :", OUTPUT_FILE)
print("Dimensions finales :", df.shape)

print(
    f"Taille du fichier : "
    f"{OUTPUT_FILE.stat().st_size / 1024:.2f} Ko"
)
