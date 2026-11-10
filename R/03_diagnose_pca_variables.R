project_root <- Sys.getenv("CUSTOMER_PERSONALITY_PROJECT_ROOT", unset = "")
if (nzchar(project_root)) {
  project_root <- normalizePath(project_root, mustWork = TRUE)
} else {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) == 0) {
    stop("Impossible de déterminer le chemin du projet. Lancez le script avec Rscript.")
  }
  script_path <- normalizePath(sub("^--file=", "", file_arg[[1]]))
  project_root <- dirname(dirname(script_path))
}
data_path <- file.path(
  project_root,
  "data",
  "processed",
  "marketing_campaign_clean.csv"
)
reports_dir <- file.path(project_root, "reports", "segmentation")

if (!file.exists(data_path)) {
  stop(
    "Fichier préparé introuvable : ",
    data_path,
    ". Exécutez d'abord python src/02_clean_data.py."
  )
}

dir.create(reports_dir, recursive = TRUE, showWarnings = FALSE)

segmentation_variables <- c(
  "Age_Client",
  "Income",
  "Kidhome",
  "Teenhome",
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
  "NumWebVisitsMonth"
)

data <- read.csv(
  data_path,
  check.names = FALSE,
  fileEncoding = "UTF-8-BOM",
  stringsAsFactors = FALSE
)

missing_columns <- setdiff(
  c("ID", "Year_Birth", segmentation_variables),
  names(data)
)
if (length(missing_columns) > 0) {
  stop(
    "Colonnes requises absentes : ",
    paste(missing_columns, collapse = ", ")
  )
}

non_numeric <- segmentation_variables[
  !vapply(data[segmentation_variables], is.numeric, logical(1))
]
if (length(non_numeric) > 0) {
  stop(
    "Les variables suivantes ne sont pas numériques : ",
    paste(non_numeric, collapse = ", ")
  )
}

variables <- data[segmentation_variables]
quantiles <- do.call(
  rbind,
  lapply(segmentation_variables, function(variable) {
    values <- variables[[variable]]
    finite_values <- values[is.finite(values)]
    if (length(finite_values) == 0) {
      stop("Aucune valeur numérique exploitable dans ", variable, ".")
    }

    q <- quantile(
      finite_values,
      probs = c(0, 0.25, 0.50, 0.75, 0.95, 0.99, 1),
      names = FALSE
    )
    data.frame(
      Variable = variable,
      Minimum = q[[1]],
      Q1 = q[[2]],
      Mediane = q[[3]],
      Q3 = q[[4]],
      P95 = q[[5]],
      P99 = q[[6]],
      Maximum = q[[7]],
      Valeurs_manquantes = sum(is.na(values)),
      stringsAsFactors = FALSE
    )
  })
)

outlier_diagnostics <- do.call(
  rbind,
  lapply(segmentation_variables, function(variable) {
    values <- variables[[variable]]
    finite_values <- values[is.finite(values)]
    quartiles <- quantile(
      finite_values,
      probs = c(0.25, 0.75),
      names = FALSE
    )
    iqr_value <- IQR(finite_values)
    lower_bound <- quartiles[[1]] - 1.5 * iqr_value
    upper_bound <- quartiles[[2]] + 1.5 * iqr_value
    outlier_indices <- which(
      is.finite(values) & (values < lower_bound | values > upper_bound)
    )

    data.frame(
      Variable = variable,
      Borne_inferieure_IQR = lower_bound,
      Borne_superieure_IQR = upper_bound,
      Nombre_valeurs_atypiques = length(outlier_indices),
      Pourcentage_valeurs_atypiques = length(outlier_indices) /
        length(finite_values) * 100,
      stringsAsFactors = FALSE
    )
  })
)

write.csv(
  quantiles,
  file.path(reports_dir, "diagnostic_quantiles_variables.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
write.csv(
  outlier_diagnostics,
  file.path(reports_dir, "diagnostic_valeurs_atypiques_iqr.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

extreme_income <- data[
  !is.na(data$Income) & data$Income > 150000,
  c("ID", "Year_Birth", "Income"),
  drop = FALSE
]
extreme_age <- data[
  !is.na(data$Age_Client) & data$Age_Client > 90,
  c("ID", "Year_Birth", "Age_Client"),
  drop = FALSE
]
write.csv(
  extreme_income,
  file.path(reports_dir, "diagnostic_revenus_superieurs_150000.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
write.csv(
  extreme_age,
  file.path(reports_dir, "diagnostic_ages_superieurs_90.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

cat("Diagnostic des variables pour l'ACP terminé.\n")
cat("Clients analysés :", nrow(data), "\n")
cat("Variables candidates :", length(segmentation_variables), "\n")
cat("Valeurs manquantes parmi les variables candidates :\n")
print(colSums(is.na(variables))[colSums(is.na(variables)) > 0])
cat("\nDiagnostic IQR :\n")
print(outlier_diagnostics, row.names = FALSE)
cat("\nAucune valeur n'a été supprimée ni modifiée.\n")
cat("Résultats enregistrés dans :", reports_dir, "\n")
