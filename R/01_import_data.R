
# ============================================================
# PROJET : CUSTOMER PERSONALITY ANALYSIS
# ETAPE 04 : IMPORTATION ET VERIFICATION DES DONNEES
# ============================================================

# 1. Définir le chemin du projet
projet <- normalizePath(".", winslash = "/", mustWork = TRUE)

# 2. Importer le fichier nettoyé par Python
fichier <- file.path(
  projet,
  "data",
  "processed",
  "marketing_campaign_clean.csv"
)

if (!file.exists(fichier)) {
  stop("Le fichier de données nettoyées est introuvable.")
}

data <- read.csv(
  fichier,
  header = TRUE,
  sep = ",",
  stringsAsFactors = FALSE,
  na.strings = c("", "NA")
)

# 3. Vérifier les dimensions
cat("\nDIMENSIONS DU DATASET\n")
cat("Nombre de lignes :", nrow(data), "\n")
cat("Nombre de colonnes :", ncol(data), "\n")

# 4. Vérifier les noms des variables
cat("\nNOMS DES VARIABLES\n")
print(names(data))

# 5. Vérifier les types des variables
cat("\nSTRUCTURE DU DATASET\n")
str(data)

# 6. Vérifier les valeurs manquantes
cat("\nVALEURS MANQUANTES\n")
manquants <- colSums(is.na(data))
print(manquants[manquants > 0])

# 7. Statistiques descriptives
cat("\nSTATISTIQUES DESCRIPTIVES\n")
summary(data)

# 8. Vérifier les premières observations
cat("\nPREMIERES OBSERVATIONS\n")
print(head(data))

# 9. Vérifier les doublons
cat("\nDOUBLONS\n")
cat("Nombre de doublons :", sum(duplicated(data)), "\n")

# 10. Confirmation
cat("\nImportation et vérification terminées.\n")
