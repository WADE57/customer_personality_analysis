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
figures_dir <- file.path(project_root, "figures", "segmentation")
reports_dir <- file.path(project_root, "reports", "segmentation")

required_packages <- c("ggplot2", "cluster")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "Packages R manquants : ",
    paste(missing_packages, collapse = ", "),
    ". Installez-les avec install.packages()."
  )
}

if (!file.exists(data_path)) {
  stop(
    "Fichier préparé introuvable : ",
    data_path,
    ". Exécutez d'abord python src/02_clean_data.py."
  )
}

dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(reports_dir, recursive = TRUE, showWarnings = FALSE)

required_columns <- c(
  "ID",
  "Response",
  "Education",
  "Marital_Status",
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

segmentation_features <- c(
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

spending_features <- c(
  "MntWines",
  "MntFruits",
  "MntMeatProducts",
  "MntFishProducts",
  "MntSweetProducts",
  "MntGoldProds"
)
log_features <- c("Income", spending_features)
cap_features <- c("Age_Client", log_features)

data <- read.csv(
  data_path,
  check.names = FALSE,
  fileEncoding = "UTF-8-BOM",
  stringsAsFactors = FALSE
)

missing_columns <- setdiff(required_columns, names(data))
if (length(missing_columns) > 0) {
  stop(
    "Colonnes requises absentes : ",
    paste(missing_columns, collapse = ", ")
  )
}
if (nrow(data) < 3) {
  stop("Il faut au moins trois clients pour réaliser l'ACP et la segmentation.")
}
if (anyDuplicated(data$ID)) {
  stop("La colonne ID contient des doublons.")
}

predictors <- data[segmentation_features]
for (column in segmentation_features) {
  if (!is.numeric(predictors[[column]])) {
    stop("La variable de segmentation ", column, " n'est pas numérique.")
  }
}

missing_counts <- colSums(is.na(predictors))
imputed_columns <- names(missing_counts[missing_counts > 0])
for (column in imputed_columns) {
  median_value <- median(predictors[[column]], na.rm = TRUE)
  if (!is.finite(median_value)) {
    stop("Impossible d'imputer la variable ", column, ".")
  }
  predictors[[column]][is.na(predictors[[column]])] <- median_value
}

if (any(!vapply(predictors, function(x) all(is.finite(x)), logical(1)))) {
  stop("Les variables de segmentation contiennent des valeurs non finies.")
}
if (any(as.matrix(predictors[, log_features, drop = FALSE]) < 0)) {
  stop("Les variables de revenu et de dépenses doivent être positives ou nulles.")
}

for (column in cap_features) {
  bounds <- quantile(
    predictors[[column]],
    probs = c(0.01, 0.99),
    names = FALSE,
    na.rm = TRUE
  )
  predictors[[column]] <- pmin(
    pmax(predictors[[column]], bounds[[1]]),
    bounds[[2]]
  )
}

for (column in log_features) {
  predictors[[column]] <- log1p(predictors[[column]])
}

zero_variance <- vapply(predictors, function(x) sd(x) == 0, logical(1))
if (any(zero_variance)) {
  stop(
    "Variables constantes détectées après préparation : ",
    paste(names(predictors)[zero_variance], collapse = ", ")
  )
}

standardized <- scale(predictors)
pca <- prcomp(standardized, center = FALSE, scale. = FALSE)
variance_explained <- pca$sdev^2 / sum(pca$sdev^2)
cumulative_variance <- cumsum(variance_explained)
n_components <- min(
  which(cumulative_variance >= 0.80)[1],
  10L,
  ncol(pca$x)
)
if (!is.finite(n_components) || n_components < 2) {
  stop("L'ACP n'a pas produit au moins deux composantes utilisables.")
}

pca_scores <- as.data.frame(pca$x[, seq_len(n_components), drop = FALSE])

eigenvalues <- data.frame(
  Composante = paste0("PC", seq_along(variance_explained)),
  Valeur_propre = pca$sdev^2,
  Variance_expliquee_pct = variance_explained * 100,
  Variance_cumulee_pct = cumulative_variance * 100
)
write.csv(
  eigenvalues,
  file.path(reports_dir, "variance_acp.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

loadings <- as.data.frame(pca$rotation)
loadings$Variable <- rownames(loadings)
loadings <- loadings[, c("Variable", names(pca_scores)[names(pca_scores) != "ID"])]
write.csv(
  loadings,
  file.path(reports_dir, "contributions_variables_acp.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

scree_data <- eigenvalues
scree_data$Composante <- factor(
  scree_data$Composante,
  levels = scree_data$Composante
)
p_scree <- ggplot2::ggplot(
  scree_data,
  ggplot2::aes(x = Composante, y = Variance_expliquee_pct)
) +
  ggplot2::geom_col(fill = "#2878B5") +
  ggplot2::geom_line(
    ggplot2::aes(y = Variance_cumulee_pct, group = 1),
    color = "#C44E52",
    linewidth = 1
  ) +
  ggplot2::geom_point(
    ggplot2::aes(y = Variance_cumulee_pct),
    color = "#C44E52",
    size = 2
  ) +
  ggplot2::labs(
    title = "Variance expliquée par les composantes principales",
    subtitle = "Barres : variance individuelle ; ligne : variance cumulée",
    x = "Composante principale",
    y = "Variance expliquée (%)"
  ) +
  ggplot2::theme_minimal() +
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
ggplot2::ggsave(
  file.path(figures_dir, "01_variance_acp.png"),
  p_scree,
  width = 10,
  height = 6,
  dpi = 160
)

candidate_k <- 2:min(8L, nrow(pca_scores) - 1L)
distance_matrix <- dist(pca_scores)
set.seed(2026)
cluster_candidates <- lapply(candidate_k, function(k) {
  fit <- kmeans(pca_scores, centers = k, nstart = 50, iter.max = 100)
  silhouette <- cluster::silhouette(fit$cluster, distance_matrix)
  list(
    k = k,
    fit = fit,
    silhouette = silhouette,
    average_silhouette = mean(silhouette[, "sil_width"])
  )
})

silhouette_scores <- data.frame(
  K = candidate_k,
  Silhouette_moyenne = vapply(
    cluster_candidates,
    function(x) x$average_silhouette,
    numeric(1)
  )
)
write.csv(
  silhouette_scores,
  file.path(reports_dir, "selection_nombre_clusters.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

best_index <- which.max(silhouette_scores$Silhouette_moyenne)
best_k <- silhouette_scores$K[[best_index]]
best_fit <- cluster_candidates[[best_index]]$fit
best_silhouette <- cluster_candidates[[best_index]]$silhouette
segment <- factor(best_fit$cluster)

p_silhouette <- ggplot2::ggplot(
  silhouette_scores,
  ggplot2::aes(x = K, y = Silhouette_moyenne)
) +
  ggplot2::geom_line(color = "#2878B5", linewidth = 1) +
  ggplot2::geom_point(size = 3, color = "#C44E52") +
  ggplot2::geom_vline(
    xintercept = best_k,
    linetype = "dashed",
    color = "#55A868"
  ) +
  ggplot2::scale_x_continuous(breaks = candidate_k) +
  ggplot2::labs(
    title = "Sélection du nombre de segments",
    subtitle = paste("K retenu :", best_k, "selon la silhouette moyenne"),
    x = "Nombre de clusters (K)",
    y = "Silhouette moyenne"
  ) +
  ggplot2::theme_minimal()
ggplot2::ggsave(
  file.path(figures_dir, "02_selection_clusters.png"),
  p_silhouette,
  width = 8,
  height = 5,
  dpi = 160
)

silhouette_plot_data <- data.frame(
  Largeur_silhouette = best_silhouette[, "sil_width"],
  Segment = factor(best_silhouette[, "cluster"])
)
p_silhouette_segments <- ggplot2::ggplot(
  silhouette_plot_data,
  ggplot2::aes(x = Largeur_silhouette, fill = Segment)
) +
  ggplot2::geom_histogram(bins = 30, alpha = 0.8, position = "identity") +
  ggplot2::labs(
    title = "Distribution des largeurs de silhouette",
    x = "Largeur de silhouette",
    y = "Nombre de clients",
    fill = "Segment"
  ) +
  ggplot2::theme_minimal()
ggplot2::ggsave(
  file.path(figures_dir, "03_diagnostic_silhouette.png"),
  p_silhouette_segments,
  width = 8,
  height = 5,
  dpi = 160
)

plot_data <- data.frame(
  PC1 = pca$x[, 1],
  PC2 = pca$x[, 2],
  Segment = segment
)
p_segments <- ggplot2::ggplot(
  plot_data,
  ggplot2::aes(x = PC1, y = PC2, color = Segment)
) +
  ggplot2::geom_point(alpha = 0.65, size = 1.8) +
  ggplot2::labs(
    title = paste("Segmentation des clients dans le plan ACP (K =", best_k, ")"),
    x = sprintf("PC1 (%.1f %% de variance)", variance_explained[[1]] * 100),
    y = sprintf("PC2 (%.1f %% de variance)", variance_explained[[2]] * 100),
    color = "Segment"
  ) +
  ggplot2::theme_minimal()
ggplot2::ggsave(
  file.path(figures_dir, "04_segments_plan_acp.png"),
  p_segments,
  width = 9,
  height = 6,
  dpi = 160
)

segment_sizes <- as.data.frame(table(Segment = segment))
names(segment_sizes)[[2]] <- "Nombre_clients"
segment_sizes$Pourcentage <- segment_sizes$Nombre_clients / nrow(data) * 100
write.csv(
  segment_sizes,
  file.path(reports_dir, "tailles_segments.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

profile_variables <- c(
  "Age_Client",
  "Income",
  "Kidhome",
  "Teenhome",
  "Recency",
  spending_features,
  "NumDealsPurchases",
  "NumWebPurchases",
  "NumCatalogPurchases",
  "NumStorePurchases",
  "NumWebVisitsMonth"
)
cluster_profiles <- do.call(
  rbind,
  lapply(levels(segment), function(level) {
    rows <- segment == level
    data.frame(
      Segment = level,
      Nombre_clients = sum(rows),
      lapply(data[rows, profile_variables, drop = FALSE], median, na.rm = TRUE),
      check.names = FALSE
    )
  })
)
cluster_profiles$Taux_reponse_pct <- vapply(
  levels(segment),
  function(level) {
    mean(data$Response[segment == level], na.rm = TRUE) * 100
  },
  numeric(1)
)
cluster_profiles$Education_majoritaire <- vapply(
  levels(segment),
  function(level) {
    values <- data$Education[segment == level]
    names(which.max(table(values)))
  },
  character(1)
)
cluster_profiles$Statut_matrimonial_majoritaire <- vapply(
  levels(segment),
  function(level) {
    values <- data$Marital_Status[segment == level]
    names(which.max(table(values)))
  },
  character(1)
)
write.csv(
  cluster_profiles,
  file.path(reports_dir, "profils_segments.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

cluster_assignments <- data.frame(
  ID = data$ID,
  Segment = segment
)
write.csv(
  cluster_assignments,
  file.path(reports_dir, "affectation_clients_segments.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

profile_long <- do.call(
  rbind,
  lapply(seq_len(nrow(cluster_profiles)), function(i) {
    values <- as.numeric(
      unlist(cluster_profiles[i, profile_variables], use.names = FALSE)
    )
    data.frame(
      Segment = cluster_profiles$Segment[[i]],
      Variable = profile_variables,
      Mediane = values
    )
  })
)
profile_long$Valeur_standardisee <- ave(
  profile_long$Mediane,
  profile_long$Variable,
  FUN = function(x) {
    variable_sd <- sd(x)
    if (is.na(variable_sd) || variable_sd == 0) {
      return(rep(0, length(x)))
    }
    (x - mean(x)) / variable_sd
  }
)
p_profiles <- ggplot2::ggplot(
  profile_long,
  ggplot2::aes(x = Variable, y = Segment, fill = Valeur_standardisee)
) +
  ggplot2::geom_tile(color = "white") +
  ggplot2::scale_fill_gradient2(
    low = "#2878B5",
    mid = "white",
    high = "#C44E52",
    midpoint = 0
  ) +
  ggplot2::labs(
    title = "Profil médian des segments",
    subtitle = "Couleur relative à la moyenne des médianes de chaque variable",
    x = NULL,
    y = "Segment",
    fill = "Écart standardisé"
  ) +
  ggplot2::theme_minimal() +
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
ggplot2::ggsave(
  file.path(figures_dir, "05_profils_segments.png"),
  p_profiles,
  width = 12,
  height = max(5, best_k * 0.7),
  dpi = 160
)

report_lines <- c(
  "# ACP et segmentation des clients",
  "",
  "## Méthode",
  "",
  paste0("- Clients analysés : **", nrow(data), "**."),
  paste0("- Variables numériques utilisées : **", length(segmentation_features), "**."),
  paste0(
    "- `ID`, `Response`, les variables catégorielles et les variables dérivées ",
    "redondantes ne sont pas utilisées pour entraîner l'ACP ou le clustering."
  ),
  paste0(
    "- Revenus manquants imputés par la médiane : **",
    sum(missing_counts),
    "** valeur(s)."
  ),
  paste0(
    "- Les valeurs d'âge, revenu et dépenses sont limitées aux percentiles ",
    "1 et 99 pour l'analyse uniquement ; le fichier préparé n'est pas modifié."
  ),
  paste0(
    "- Une transformation `log1p` est appliquée au revenu et aux dépenses, ",
    "puis les variables sont centrées-réduites."
  ),
  paste0(
    "- L'ACP conserve **",
    n_components,
    "** composante(s) (variance cumulée : **",
    sprintf("%.1f", cumulative_variance[[n_components]] * 100),
    " %**)."
  ),
  paste0(
    "- K-means est ajusté sur les composantes retenues ; `K` est choisi ",
    "parmi 2 à 8 en maximisant la silhouette moyenne."
  ),
  "",
  "## Résultat de la segmentation",
  "",
  paste0("- Nombre de segments retenu : **", best_k, "**."),
  paste0(
    "- Silhouette moyenne : **",
    sprintf("%.3f", silhouette_scores$Silhouette_moyenne[[best_index]]),
    "**."
  ),
  "",
  "| Segment | Clients | Part (%) |",
  "|---|---:|---:|"
)

report_lines <- c(
  report_lines,
  vapply(seq_len(nrow(segment_sizes)), function(i) {
    paste0(
      "| ",
      segment_sizes$Segment[[i]],
      " | ",
      segment_sizes$Nombre_clients[[i]],
      " | ",
      sprintf("%.1f", segment_sizes$Pourcentage[[i]]),
      " |"
    )
  }, character(1)),
  "",
  "### Profil médian et réponse observée",
  "",
  paste0(
    "Les médianes des variables d'origine et le taux de réponse par segment ",
    "sont décrits après la segmentation. `Response` n'a pas servi à créer ",
    "les segments ; son taux est un indicateur descriptif postérieur."
  ),
  "",
  paste(
    capture.output(print(cluster_profiles, row.names = FALSE)),
    collapse = "\n"
  ),
  "",
  "## Limites d'interprétation",
  "",
  paste0(
    "- Les segments sont des profils exploratoires, pas des catégories ",
    "naturelles garanties ni des groupes causaux."
  ),
  paste0(
    "- Le choix du nombre de clusters dépend de la méthode et des variables ",
    "retenues ; il doit être discuté avec leur interprétabilité métier."
  ),
  paste0(
    "- Les valeurs extrêmes ont été limitées uniquement pour le calcul de l'ACP ",
    "et du clustering ; les exports de profils utilisent les données d'origine."
  ),
  "",
  "## Figures",
  "",
  "- `figures/segmentation/01_variance_acp.png`",
  "- `figures/segmentation/02_selection_clusters.png`",
  "- `figures/segmentation/03_diagnostic_silhouette.png`",
  "- `figures/segmentation/04_segments_plan_acp.png`",
  "- `figures/segmentation/05_profils_segments.png`",
  "",
  "## Fichiers de résultats",
  "",
  "- `reports/segmentation/variance_acp.csv`",
  "- `reports/segmentation/contributions_variables_acp.csv`",
  "- `reports/segmentation/selection_nombre_clusters.csv`",
  "- `reports/segmentation/tailles_segments.csv`",
  "- `reports/segmentation/profils_segments.csv`",
  "- `reports/segmentation/affectation_clients_segments.csv`",
  ""
)

writeLines(
  report_lines,
  file.path(reports_dir, "pca_segmentation.md"),
  useBytes = TRUE
)

cat("ACP et segmentation terminées.\n")
cat("Clients analysés :", nrow(data), "\n")
cat("Composantes principales retenues :", n_components, "\n")
cat("Segments retenus :", best_k, "\n")
cat("Figures :", figures_dir, "\n")
cat("Rapport :", file.path(reports_dir, "pca_segmentation.md"), "\n")
