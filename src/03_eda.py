from pathlib import Path
import warnings

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

from scipy.stats import (
    spearmanr,
    mannwhitneyu,
    chi2_contingency,
    fisher_exact
)

warnings.filterwarnings("ignore", category=FutureWarning)

# ============================================================
# 1. CONFIGURATION DU PROJET
# ============================================================

ROOT = Path(__file__).resolve().parents[1]

DATA_PATH = ROOT / "data" / "processed" / "marketing_campaign_clean.csv"

FIGURES_DIR = ROOT / "figures" / "eda"
REPORTS_DIR = ROOT / "reports" / "eda"
TABLES_DIR = REPORTS_DIR / "tables"

for directory in [FIGURES_DIR, REPORTS_DIR, TABLES_DIR]:
    directory.mkdir(parents=True, exist_ok=True)

sns.set_theme(style="whitegrid", palette="deep")

plt.rcParams["figure.figsize"] = (10, 6)
plt.rcParams["figure.dpi"] = 120

# ============================================================
# 2. CHARGEMENT DES DONNEES
# ============================================================

def load_data():

    if not DATA_PATH.exists():
        raise FileNotFoundError(
            f"Fichier introuvable : {DATA_PATH}"
        )

    df = pd.read_csv(DATA_PATH)

    print("=" * 65)
    print("ANALYSE EXPLORATOIRE DES DONNEES")
    print("=" * 65)

    print(f"\nDimensions : {df.shape[0]} lignes x {df.shape[1]} colonnes")

    print("\nTypes de variables :")
    print(df.dtypes)

    return df


df = load_data()

# ============================================================
# 3. VERIFICATION DES VARIABLES
# ============================================================

required_columns = [
    "ID",
    "Year_Birth",
    "Education",
    "Marital_Status",
    "Income",
    "Kidhome",
    "Teenhome",
    "Dt_Customer",
    "Recency",
    "MntWines",
    "MntFruits",
    "MntMeatProducts",
    "MntFishProducts",
    "MntSweetProducts",
    "MntGoldProds",
    "NumDealsPurchases",
    "NumWebPurchases",
    "NumCatalogPurchases",
    "NumStorePurchases",
    "NumWebVisitsMonth",
    "Age_Client",
    "Nb_Enfants_Foyer",
    "Total_Spend",
    "Total_Purchases",
    "Response"
]

missing_columns = [
    col for col in required_columns
    if col not in df.columns
]

if missing_columns:
    raise ValueError(
        "Certaines colonnes nécessaires sont absentes : "
        + ", ".join(missing_columns)
    )

# Conversion de la date si nécessaire
df["Dt_Customer"] = pd.to_datetime(
    df["Dt_Customer"],
    errors="coerce"
)

# ============================================================
# 4. PRESENTATION GENERALE DES DONNEES
# ============================================================

print("\n" + "=" * 65)
print("4. PRESENTATION GENERALE")
print("=" * 65)

print("\nAperçu des données :")
print(df.head())

print("\nInformations générales :")
print(df.info())

print("\nNombre de doublons :")
print(df.duplicated().sum())

print("\nNombre de valeurs manquantes :")
print(df.isnull().sum().sum())

# Export des dimensions
dimensions = pd.DataFrame({
    "Indicateur": [
        "Nombre de clients",
        "Nombre de variables",
        "Nombre de doublons"
    ],
    "Valeur": [
        len(df),
        df.shape[1],
        df.duplicated().sum()
    ]
})

dimensions.to_csv(
    TABLES_DIR / "dimensions_donnees.csv",
    index=False
)

# ============================================================
# 5. STATISTIQUES DESCRIPTIVES
# ============================================================

print("\n" + "=" * 65)
print("5. STATISTIQUES DESCRIPTIVES")
print("=" * 65)

quantitative_vars = [
    "Age_Client",
    "Income",
    "Recency",
    "Nb_Enfants_Foyer",
    "Total_Spend",
    "Total_Purchases",
    "NumDealsPurchases",
    "NumWebPurchases",
    "NumCatalogPurchases",
    "NumStorePurchases",
    "NumWebVisitsMonth"
]

quantitative_vars = [
    col for col in quantitative_vars
    if col in df.columns
]

descriptive_stats = df[quantitative_vars].describe().T

descriptive_stats["median"] = df[quantitative_vars].median()
descriptive_stats["missing"] = df[quantitative_vars].isnull().sum()

descriptive_stats.to_csv(
    TABLES_DIR / "statistiques_descriptives.csv"
)

print(descriptive_stats)

# ============================================================
# 6. ANALYSE DES VALEURS MANQUANTES
# ============================================================

print("\n" + "=" * 65)
print("6. VALEURS MANQUANTES")
print("=" * 65)

missing_data = pd.DataFrame({
    "Variable": df.columns,
    "Nombre_manquant": df.isnull().sum().values,
    "Pourcentage": (
        df.isnull().mean().values * 100
    )
})

missing_data = missing_data.sort_values(
    by="Pourcentage",
    ascending=False
)

missing_data.to_csv(
    TABLES_DIR / "valeurs_manquantes.csv",
    index=False
)

print(missing_data[missing_data["Nombre_manquant"] > 0])

# Graphique des valeurs manquantes
missing_plot = missing_data[
    missing_data["Nombre_manquant"] > 0
]

if not missing_plot.empty:

    plt.figure(figsize=(10, 5))

    sns.barplot(
        data=missing_plot,
        x="Variable",
        y="Pourcentage"
    )

    plt.title("Pourcentage de valeurs manquantes")
    plt.xticks(rotation=45, ha="right")
    plt.ylabel("Valeurs manquantes (%)")
    plt.xlabel("Variables")
    plt.tight_layout()

    plt.savefig(
        FIGURES_DIR / "01_valeurs_manquantes.png"
    )

    plt.close()

# ============================================================
# 7. ANALYSE DES VARIABLES QUALITATIVES
# ============================================================

print("\n" + "=" * 65)
print("7. VARIABLES QUALITATIVES")
print("=" * 65)

qualitative_vars = [
    "Education",
    "Marital_Status"
]

for variable in qualitative_vars:

    frequencies = df[variable].value_counts(
        dropna=False
    ).reset_index()

    frequencies.columns = [
        variable,
        "Effectif"
    ]

    frequencies.to_csv(
        TABLES_DIR / f"distribution_{variable}.csv",
        index=False
    )

    print(f"\nRépartition de {variable} :")
    print(frequencies)

    plt.figure(figsize=(10, 5))

    sns.countplot(
        data=df,
        x=variable,
        order=df[variable].value_counts().index
    )

    plt.title(f"Répartition des clients selon {variable}")
    plt.xlabel(variable)
    plt.ylabel("Nombre de clients")
    plt.xticks(rotation=30, ha="right")
    plt.tight_layout()

    plt.savefig(
        FIGURES_DIR / f"repartition_{variable}.png"
    )

    plt.close()

# ============================================================
# 8. ANALYSE UNIVARIEE : DISTRIBUTIONS
# ============================================================

print("\n" + "=" * 65)
print("8. DISTRIBUTIONS DES VARIABLES QUANTITATIVES")
print("=" * 65)

for variable in quantitative_vars:

    values = df[variable].dropna()

    if values.empty:
        continue

    plt.figure(figsize=(9, 5))

    sns.histplot(
        values,
        kde=True,
        bins=30
    )

    plt.title(f"Distribution de {variable}")
    plt.xlabel(variable)
    plt.ylabel("Effectif")
    plt.tight_layout()

    plt.savefig(
        FIGURES_DIR / f"distribution_{variable}.png"
    )

    plt.close()

    # Boxplot
    plt.figure(figsize=(9, 4))

    sns.boxplot(
        x=values
    )

    plt.title(f"Boîte à moustaches de {variable}")
    plt.xlabel(variable)
    plt.tight_layout()

    plt.savefig(
        FIGURES_DIR / f"boxplot_{variable}.png"
    )

    plt.close()

# Visualisation spécifique du revenu
income_values = df["Income"].dropna()

if not income_values.empty:

    income_limit = income_values.quantile(0.99)

    plt.figure(figsize=(9, 5))

    sns.histplot(
        income_values[income_values <= income_limit],
        bins=30,
        kde=True
    )

    plt.title(
        "Distribution des revenus "
        "(jusqu'au 99e percentile)"
    )

    plt.xlabel("Revenu")
    plt.ylabel("Effectif")
    plt.tight_layout()

    plt.savefig(
        FIGURES_DIR / "distribution_income_zoom.png"
    )

    plt.close()

# ============================================================
# 9. DEPENSES PAR CATEGORIE DE PRODUITS
# ============================================================

print("\n" + "=" * 65)
print("9. DEPENSES PAR PRODUIT")
print("=" * 65)

product_vars = [
    "MntWines",
    "MntFruits",
    "MntMeatProducts",
    "MntFishProducts",
    "MntSweetProducts",
    "MntGoldProds"
]

product_labels = {
    "MntWines": "Vins",
    "MntFruits": "Fruits",
    "MntMeatProducts": "Viandes",
    "MntFishProducts": "Poissons",
    "MntSweetProducts": "Produits sucrés",
    "MntGoldProds": "Produits premium (Gold)"
}

product_spend = df[product_vars].mean().rename(
    index=product_labels
).reset_index()

product_spend.columns = [
    "Produit",
    "Depense_moyenne"
]

product_spend.to_csv(
    TABLES_DIR / "depenses_moyennes_produits.csv",
    index=False
)

print(product_spend)

plt.figure(figsize=(10, 6))

sns.barplot(
    data=product_spend,
    x="Produit",
    y="Depense_moyenne"
)

plt.title("Dépenses moyennes par catégorie de produits")
plt.xlabel("Catégorie de produits")
plt.ylabel("Dépense moyenne")
plt.xticks(rotation=30, ha="right")
plt.tight_layout()

plt.savefig(
    FIGURES_DIR / "depenses_moyennes_produits.png"
)

plt.close()

# ============================================================
# 10. ANALYSE DES ACHATS PAR CANAL
# ============================================================

print("\n" + "=" * 65)
print("10. ACHATS PAR CANAL")
print("=" * 65)

channel_vars = {
    "Web": "NumWebPurchases",
    "Catalogue": "NumCatalogPurchases",
    "Magasin": "NumStorePurchases"
}

channel_data = pd.DataFrame({
    "Canal": list(channel_vars.keys()),
    "Achats_moyens": [
        df[col].mean()
        for col in channel_vars.values()
    ]
})

channel_data.to_csv(
    TABLES_DIR / "achats_moyens_par_canal.csv",
    index=False
)

print(channel_data)

plt.figure(figsize=(8, 5))

sns.barplot(
    data=channel_data,
    x="Canal",
    y="Achats_moyens"
)

plt.title("Nombre moyen d'achats par canal")
plt.xlabel("Canal")
plt.ylabel("Nombre moyen d'achats")
plt.tight_layout()

plt.savefig(
    FIGURES_DIR / "achats_par_canal.png"
)

plt.close()

# ============================================================
# 11. ANALYSE DE LA REPONSE A LA CAMPAGNE
# ============================================================

print("\n" + "=" * 65)
print("11. REPONSE A LA DERNIERE CAMPAGNE")
print("=" * 65)

response_distribution = (
    df["Response"]
    .value_counts()
    .sort_index()
    .reset_index()
)

response_distribution.columns = [
    "Response",
    "Effectif"
]

response_distribution["Pourcentage"] = (
    response_distribution["Effectif"]
    / len(df) * 100
)

response_distribution.to_csv(
    TABLES_DIR / "repartition_response.csv",
    index=False
)

print(response_distribution)

plt.figure(figsize=(7, 5))

sns.countplot(
    data=df,
    x="Response"
)

plt.title("Répartition des réponses à la dernière campagne")
plt.xlabel("Réponse (0 = Non, 1 = Oui)")
plt.ylabel("Nombre de clients")
plt.tight_layout()

plt.savefig(
    FIGURES_DIR / "repartition_response.png"
)

plt.close()

# ============================================================
# 12. CORRELATIONS DE SPEARMAN
# ============================================================

print("\n" + "=" * 65)
print("12. CORRELATIONS DE SPEARMAN")
print("=" * 65)

correlation_vars = [
    "Age_Client",
    "Income",
    "Nb_Enfants_Foyer",
    "Recency",
    "Total_Spend",
    "Total_Purchases",
    "NumDealsPurchases",
    "NumWebPurchases",
    "NumCatalogPurchases",
    "NumStorePurchases",
    "NumWebVisitsMonth"
]

correlation_vars = [
    col for col in correlation_vars
    if col in df.columns
]

spearman_matrix = df[correlation_vars].corr(
    method="spearman"
)

spearman_matrix.to_csv(
    TABLES_DIR / "matrice_correlation_spearman.csv"
)

plt.figure(figsize=(12, 9))

sns.heatmap(
    spearman_matrix,
    annot=True,
    fmt=".2f",
    cmap="coolwarm",
    center=0
)

plt.title("Matrice des corrélations de Spearman")
plt.tight_layout()

plt.savefig(
    FIGURES_DIR / "matrice_correlation_spearman.png"
)

plt.close()

# Corrélations ciblées
correlation_pairs = [
    ("Income", "Total_Spend"),
    ("Age_Client", "Total_Spend"),
    ("Nb_Enfants_Foyer", "Total_Spend"),
    ("NumWebVisitsMonth", "NumWebPurchases")
]

correlation_results = []

for var1, var2 in correlation_pairs:

    subset = df[[var1, var2]].dropna()

    rho, p_value = spearmanr(
        subset[var1],
        subset[var2]
    )

    correlation_results.append({
        "Variable_1": var1,
        "Variable_2": var2,
        "Spearman_rho": rho,
        "p_value": p_value,
        "Effectif": len(subset)
    })

correlation_results = pd.DataFrame(
    correlation_results
)

correlation_results.to_csv(
    TABLES_DIR / "correlations_ciblees.csv",
    index=False
)

print(correlation_results)

# Graphiques bivariés
for var1, var2 in correlation_pairs:

    plt.figure(figsize=(8, 5))

    sns.scatterplot(
        data=df,
        x=var1,
        y=var2,
        alpha=0.5
    )

    plt.title(f"{var1} en fonction de {var2}")
    plt.tight_layout()

    plt.savefig(
        FIGURES_DIR / f"{var1}_vs_{var2}.png"
    )

    plt.close()

# ============================================================
# 13. FONCTION DE CORRECTION DE HOLM
# ============================================================

def holm_correction(p_values):

    """
    Correction de Holm-Bonferroni.
    Contrôle le risque d'erreur familial.
    """

    p_values = np.asarray(p_values, dtype=float)

    n = len(p_values)

    order = np.argsort(p_values)

    adjusted = np.empty(n)

    sorted_p = p_values[order]

    adjusted_sorted = np.maximum.accumulate(
        (n - np.arange(n)) * sorted_p
    )

    adjusted_sorted = np.minimum(
        adjusted_sorted,
        1.0
    )

    adjusted[order] = adjusted_sorted

    return adjusted

# ============================================================
# 14. COMPARAISON REPONDANTS / NON-REPONDANTS
# ============================================================

print("\n" + "=" * 65)
print("14. COMPARAISON SELON LA REPONSE")
print("=" * 65)

comparison_vars = [
    "Income",
    "Total_Spend",
    "Total_Purchases",
    "Recency"
]

mann_whitney_results = []

for variable in comparison_vars:

    group_no = df.loc[
        df["Response"] == 0,
        variable
    ].dropna()

    group_yes = df.loc[
        df["Response"] == 1,
        variable
    ].dropna()

    if len(group_no) == 0 or len(group_yes) == 0:
        continue

    # Test de Mann-Whitney
    statistic, p_value = mannwhitneyu(
        group_yes,
        group_no,
        alternative="two-sided"
    )

    # Corrélation bisérielle de rang
    # Positive : valeurs généralement plus élevées
    # chez les répondants.
    effect_size = (
        2 * statistic
        / (len(group_yes) * len(group_no))
    ) - 1

    mann_whitney_results.append({
        "Variable": variable,
        "Mediane_non_repondants": group_no.median(),
        "Mediane_repondants": group_yes.median(),
        "Effectif_non": len(group_no),
        "Effectif_oui": len(group_yes),
        "U_statistic": statistic,
        "p_value": p_value,
        "Rank_biserial": effect_size
    })

mann_whitney_results = pd.DataFrame(
    mann_whitney_results
)

# Correction de Holm sur les quatre tests
mann_whitney_results["p_value_Holm"] = holm_correction(
    mann_whitney_results["p_value"]
)

mann_whitney_results["Significatif_5pct"] = (
    mann_whitney_results["p_value_Holm"] < 0.05
)

mann_whitney_results.to_csv(
    TABLES_DIR / "comparaison_response_mann_whitney.csv",
    index=False
)

print(mann_whitney_results)

# Graphique des dépenses selon Response
plt.figure(figsize=(8, 5))

sns.boxplot(
    data=df,
    x="Response",
    y="Total_Spend"
)

plt.title("Dépenses selon la réponse à la campagne")
plt.xlabel("Réponse (0 = Non, 1 = Oui)")
plt.ylabel("Dépenses totales")
plt.tight_layout()

plt.savefig(
    FIGURES_DIR / "profil_selon_response.png"
)

plt.close()

# ============================================================
# 15. ANALYSE DES CINQ CAMPAGNES PRECEDENTES
# ============================================================

print("\n" + "=" * 65)
print("15. ANALYSE DES CAMPAGNES PRECEDENTES")
print("=" * 65)

campaign_vars = [
    "AcceptedCmp1",
    "AcceptedCmp2",
    "AcceptedCmp3",
    "AcceptedCmp4",
    "AcceptedCmp5"
]

campaign_results = []

for campaign in campaign_vars:

    # Nombre et taux d'acceptation
    accepted = df[campaign].sum()

    acceptance_rate = (
        accepted / len(df) * 100
    )

    # Tableau de contingence :
    # lignes = acceptation de la campagne
    # colonnes = réponse à la dernière campagne
    contingency = pd.crosstab(
        df[campaign],
        df["Response"]
    ).reindex(
        index=[0, 1],
        columns=[0, 1],
        fill_value=0
    )

    chi2, chi_p, dof, expected = chi2_contingency(
        contingency,
        correction=False
    )

    # Choix du test en fonction des effectifs attendus
    if (expected < 5).any():

        odds_ratio, p_value = fisher_exact(
            contingency.to_numpy()
        )

        test_name = "Fisher exact"

    else:

        p_value = chi_p
        odds_ratio = np.nan
        test_name = "Chi-deux"

    # V de Cramer
    n = contingency.to_numpy().sum()

    cramer_v = np.sqrt(
        chi2 / n
    ) if n > 0 else np.nan

    campaign_results.append({
        "Campagne": campaign,
        "Acceptations": int(accepted),
        "Taux_acceptation_pct": acceptance_rate,
        "Test_utilise": test_name,
        "Statistique_chi2": chi2,
        "p_value": p_value,
        "Odds_ratio_Fisher": odds_ratio,
        "V_Cramer": cramer_v,
        "Effectif_min_attendu": expected.min()
    })

campaign_results = pd.DataFrame(
    campaign_results
)

# Correction de Holm sur les cinq tests
campaign_results["p_value_Holm"] = holm_correction(
    campaign_results["p_value"]
)

campaign_results["Significatif_5pct"] = (
    campaign_results["p_value_Holm"] < 0.05
)

campaign_results.to_csv(
    TABLES_DIR / "analyse_campagnes.csv",
    index=False
)

print(campaign_results)

# Graphique des taux d'acceptation
plt.figure(figsize=(9, 5))

sns.barplot(
    data=campaign_results,
    x="Campagne",
    y="Taux_acceptation_pct"
)

plt.title("Taux d'acceptation des cinq campagnes précédentes")
plt.xlabel("Campagne")
plt.ylabel("Taux d'acceptation (%)")
plt.tight_layout()

plt.savefig(
    FIGURES_DIR / "taux_acceptation_campagnes.png"
)

plt.close()

# ============================================================
# 16. ANALYSE DES DATES D'INSCRIPTION
# ============================================================

print("\n" + "=" * 65)
print("16. ANALYSE DES DATES D'INSCRIPTION")
print("=" * 65)

date_data = df.dropna(
    subset=["Dt_Customer"]
).copy()

date_data["Mois_Inscription"] = (
    date_data["Dt_Customer"].dt.to_period("M").astype(str)
)

monthly_customers = (
    date_data["Mois_Inscription"]
    .value_counts()
    .sort_index()
    .reset_index()
)

monthly_customers.columns = [
    "Mois",
    "Nombre_clients"
]

monthly_customers.to_csv(
    TABLES_DIR / "clients_par_mois.csv",
    index=False
)

plt.figure(figsize=(12, 5))

sns.lineplot(
    data=monthly_customers,
    x="Mois",
    y="Nombre_clients",
    marker="o"
)

plt.title("Nombre de clients par mois d'inscription")
plt.xlabel("Mois")
plt.ylabel("Nombre de clients")
plt.xticks(rotation=45)
plt.tight_layout()

plt.savefig(
    FIGURES_DIR / "clients_par_mois.png"
)

plt.close()

# ============================================================
# 17. GENERATION DU RAPPORT AUTOMATIQUE
# ============================================================

print("\n" + "=" * 65)
print("17. GENERATION DU RAPPORT EDA")
print("=" * 65)

response_rate = df["Response"].mean() * 100

report = []

report.append("# Rapport d'analyse exploratoire des données")
report.append("")
report.append("## 1. Présentation du jeu de données")
report.append("")
report.append(f"- Nombre de clients : {len(df)}")
report.append(f"- Nombre de variables : {df.shape[1]}")
report.append(f"- Nombre de doublons : {df.duplicated().sum()}")
report.append(
    f"- Nombre de revenus manquants : {df['Income'].isna().sum()}"
)
report.append(
    f"- Taux de réponse à la dernière campagne : {response_rate:.2f} %"
)

report.append("")
report.append("## 2. Statistiques descriptives")
report.append("")
report.append(
    descriptive_stats.round(2).to_markdown()
)

report.append("")
report.append("## 3. Valeurs manquantes")
report.append("")
report.append(
    missing_data[
        missing_data["Nombre_manquant"] > 0
    ].round(2).to_markdown(index=False)
)

report.append("")
report.append("## 4. Corrélations de Spearman")
report.append("")
report.append(
    correlation_results.round(4).to_markdown(index=False)
)

report.append("")
report.append("## 5. Comparaison des répondants et non-répondants")
report.append("")
report.append(
    mann_whitney_results.round(4).to_markdown(index=False)
)

report.append("")
report.append("## 6. Analyse des campagnes précédentes")
report.append("")
report.append(
    campaign_results.round(4).to_markdown(index=False)
)

report.append("")
report.append("## 7. Précautions d'interprétation")
report.append("")
report.append(
    "- Une corrélation ne démontre pas une relation de causalité."
)
report.append(
    "- Les p-values ont été ajustées par la méthode de Holm "
    "dans chaque famille de tests."
)
report.append(
    "- Les tailles d'effet complètent l'interprétation "
    "des tests statistiques."
)
report.append(
    "- Le test exact de Fisher est utilisé lorsqu'au moins "
    "un effectif théorique du tableau est inférieur à 5."
)
report.append(
    "- Les valeurs atypiques sont conservées à ce stade "
    "et doivent être interprétées avec prudence."
)
report.append(
    "- Les analyses statistiques ne prouvent pas "
    "l'efficacité causale des campagnes."
)

report_path = REPORTS_DIR / "eda_summary.md"

with open(
    report_path,
    "w",
    encoding="utf-8"
) as file:

    file.write("\n".join(report))

# ============================================================
# 18. BILAN FINAL
# ============================================================

print("\n" + "=" * 65)
print("ANALYSE EXPLORATOIRE TERMINEE")
print("=" * 65)

print(f"\nNombre de clients analysés : {len(df)}")
print(f"Nombre de variables : {df.shape[1]}")

print(f"\nGraphiques enregistrés dans : {FIGURES_DIR}")
print(f"Tableaux CSV enregistrés dans : {TABLES_DIR}")
print(f"Rapport Markdown : {report_path}")

print("\nLa partie 3 est exécutée.")