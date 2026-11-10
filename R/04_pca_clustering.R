
# ============================================================
# PROJET : CUSTOMER PERSONALITY ANALYSIS
# ETAPE : ACP ET SEGMENTATION DES CLIENTS PAR K-MEANS
# ============================================================
#
# Objectifs :
# 1. Préparer les variables quantitatives.
# 2. Réaliser une ACP.
# 3. Déterminer le nombre de composantes à conserver.
# 4. Sélectionner le nombre de clusters par silhouette.
# 5. Réaliser une segmentation K-means.
# 6. Interpréter les profils des segments.
# 7. Exporter les résultats et les graphiques.
#
# Les données originales ne sont jamais modifiées.
#
# ============================================================


# ------------------------------------------------------------
# 1. CONFIGURATION DU PROJET
# ------------------------------------------------------------

project_root <- Sys.getenv(
  "CUSTOMER_PERSONALITY_PROJECT_ROOT",
  unset = ""
)

if (nzchar(project_root)) {

  project_root <- normalizePath(
    project_root,
    mustWork = TRUE
  )

} else {

  args <- commandArgs(trailingOnly = FALSE)

  file_arg <- grep(
    "^--file=",
    args,
    value = TRUE
  )

  if (length(file_arg) == 0) {
    stop(
      "Impossible de déterminer le chemin du projet. ",
      "Lancez le script avec Rscript."
    )
  }

  script_path <- normalizePath(
    sub("^--file=", "", file_arg[[1]])
  )

  project_root <- dirname(dirname(script_path))
}


# Chemins des fichiers

data_path <- file.path(
  project_root,
  "data",
  "processed",
  "marketing_campaign_clean.csv"
)

figures_dir <- file.path(
  project_root,
  "figures",
  "segmentation"
)

reports_dir <- file.path(
  project_root,
  "reports",
  "segmentation"
)


# ------------------------------------------------------------
# 2. VERIFICATION DES PACKAGES
# ------------------------------------------------------------

required_packages <- c(
  "ggplot2",
  "cluster"
)

missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]

if (length(missing_packages) > 0) {

  stop(
    "Packages R manquants : ",
    paste(missing_packages, collapse = ", "),
    ". Installez-les avec install.packages()."
  )
}


# ------------------------------------------------------------
# 3. VERIFICATION DU FICHIER DE DONNEES
# ------------------------------------------------------------

if (!file.exists(data_path)) {

  stop(
    "Fichier préparé introuvable : ",
    data_path,
    ". Exécutez d'abord python src/02_clean_data.py."
  )
}

dir.create(
  figures_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  reports_dir,
  recursive = TRUE,
  showWarnings = FALSE
)


# ------------------------------------------------------------
# 4. DEFINITION DES VARIABLES
# ------------------------------------------------------------

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


# Variables utilisées pour l'ACP et K-means

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


# Variables de dépenses

spending_features <- c(
  "MntWines",
  "MntFruits",
  "MntMeatProducts",
  "MntFishProducts",
  "MntSweetProducts",
  "MntGoldProds"
)


# Variables transformées par logarithme

log_features <- c(
  "Income",
  spending_features
)


# Variables plafonnées aux percentiles 1 et 99

# Seules les variables de dépenses sont plafonnées.
# Le revenu et l'âge ne sont pas plafonnés automatiquement.

cap_features <- spending_features


# ------------------------------------------------------------
# 5. IMPORTATION DES DONNEES
# ------------------------------------------------------------

data <- read.csv(
  data_path,
  check.names = FALSE,
  fileEncoding = "UTF-8-BOM",
  stringsAsFactors = FALSE
)

missing_columns <- setdiff(
  required_columns,
  names(data)
)

if (length(missing_columns) > 0) {

  stop(
    "Colonnes requises absentes : ",
    paste(missing_columns, collapse = ", ")
  )
}

if (nrow(data) < 3) {
  stop(
    "Il faut au moins trois clients pour réaliser l'ACP ",
    "et la segmentation."
  )
}

if (anyDuplicated(data$ID)) {
  stop("La colonne ID contient des doublons.")
}

if (anyNA(data$ID)) {
  stop("La colonne ID contient des valeurs manquantes.")
}

if (!is.numeric(data$Response) ||
    anyNA(data$Response) ||
    !all(data$Response %in% c(0, 1))) {

  stop(
    "La variable Response doit être numérique, ",
    "sans valeur manquante et codée 0/1."
  )
}


# ------------------------------------------------------------
# 6. SELECTION ET VERIFICATION DES VARIABLES
# ------------------------------------------------------------

predictors <- data[
  ,
  segmentation_features,
  drop = FALSE
]

for (column in segmentation_features) {

  if (!is.numeric(predictors[[column]])) {

    stop(
      "La variable de segmentation ",
      column,
      " n'est pas numérique."
    )
  }
}


# Vérification des valeurs infinies

for (column in segmentation_features) {

  if (any(is.infinite(predictors[[column]]))) {

    stop(
      "Valeurs infinies détectées dans ",
      column,
      "."
    )
  }
}

# ------------------------------------------------------------
# CONTROLE DES VALEURS SUSPECTES
# ------------------------------------------------------------

# Nombre de revenus déjà manquants dans les données
original_missing_income <- sum(
  is.na(predictors$Income)
)

# Identification des âges supérieurs à 90 ans
invalid_age <- !is.na(predictors$Age_Client) &
  predictors$Age_Client > 90

invalid_age_count <- sum(invalid_age)

# Identification du revenu extrême 666666
invalid_income <- !is.na(predictors$Income) &
  predictors$Income == 666666

invalid_income_count <- sum(invalid_income)

# Neutralisation dans les variables de travail uniquement
predictors$Age_Client[invalid_age] <- NA_real_

predictors$Income[invalid_income] <- NA_real_

cat("\nCONTROLE DES VALEURS SUSPECTES\n")
cat("Âges supérieurs à 90 ans :", invalid_age_count, "\n")
cat("Revenus égaux à 666666 :", invalid_income_count, "\n")
cat("Revenus initialement manquants :", original_missing_income, "\n")


# ------------------------------------------------------------
# 7. TRAITEMENT DES VALEURS MANQUANTES
# ------------------------------------------------------------

missing_counts <- colSums(
  is.na(predictors)
)

imputed_columns <- names(
  missing_counts[missing_counts > 0]
)

for (column in imputed_columns) {

  median_value <- median(
    predictors[[column]],
    na.rm = TRUE
  )

  if (!is.finite(median_value)) {

    stop(
      "Impossible d'imputer la variable ",
      column,
      "."
    )
  }

  predictors[[column]][
    is.na(predictors[[column]])
  ] <- median_value
}

cat("\nIMPUTATION DES VALEURS MANQUANTES\n")

for (column in names(missing_counts)) {

  if (missing_counts[[column]] > 0) {

    cat(
      column, ":",
      missing_counts[[column]],
      "valeur(s) imputée(s)\n"
    )

  }
}


# Vérification finale

if (
  any(
    !vapply(
      predictors,
      function(x) all(is.finite(x)),
      logical(1)
    )
  )
) {

  stop(
    "Les variables de segmentation contiennent ",
    "des valeurs non finies."
  )
}


# ------------------------------------------------------------
# 8. VERIFICATION DES VARIABLES DE DEPENSES ET REVENU
# ------------------------------------------------------------

if (
  any(
    as.matrix(
      predictors[
        ,
        log_features,
        drop = FALSE
      ]
    ) < 0
  )
) {

  stop(
    "Les variables de revenu et de dépenses ",
    "doivent être positives ou nulles."
  )
}


# ------------------------------------------------------------
# 9. LIMITATION DES VALEURS EXTREMES
# ------------------------------------------------------------

for (column in cap_features) {

  bounds <- quantile(
    predictors[[column]],
    probs = c(0.01, 0.99),
    names = FALSE,
    na.rm = TRUE
  )

  predictors[[column]] <- pmin(
    pmax(
      predictors[[column]],
      bounds[[1]]
    ),
    bounds[[2]]
  )
}


# ------------------------------------------------------------
# 10. TRANSFORMATION LOGARITHMIQUE
# ------------------------------------------------------------

for (column in log_features) {

  predictors[[column]] <- log1p(
    predictors[[column]]
  )
}


# ------------------------------------------------------------
# 11. VERIFICATION DE LA VARIANCE
# ------------------------------------------------------------

zero_variance <- vapply(
  predictors,
  function(x) sd(x) == 0,
  logical(1)
)

if (any(zero_variance)) {

  stop(
    "Variables constantes détectées après préparation : ",
    paste(
      names(predictors)[zero_variance],
      collapse = ", "
    )
  )
}


# ------------------------------------------------------------
# 12. STANDARDISATION DES VARIABLES
# ------------------------------------------------------------

standardized <- scale(predictors)

if (
  any(
    !is.finite(as.matrix(standardized))
  )
) {

  stop(
    "La standardisation a produit des valeurs non finies."
  )
}


# ------------------------------------------------------------
# 13. ANALYSE EN COMPOSANTES PRINCIPALES
# ------------------------------------------------------------

pca <- prcomp(
  standardized,
  center = FALSE,
  scale. = FALSE
)


# Variance expliquée

variance_explained <- (
  pca$sdev^2 /
    sum(pca$sdev^2)
)

cumulative_variance <- cumsum(
  variance_explained
)


# Nombre de composantes retenues :
# seuil de variance cumulée de 80 %
# avec un maximum de 10 composantes.

n_components <- min(
  which(cumulative_variance >= 0.80)[1],
  10L,
  ncol(pca$x)
)

if (
  !is.finite(n_components) ||
  n_components < 2
) {

  stop(
    "L'ACP n'a pas produit au moins ",
    "deux composantes utilisables."
  )
}


# Scores des composantes retenues

pca_scores <- as.data.frame(
  pca$x[
    ,
    seq_len(n_components),
    drop = FALSE
  ]
)


# ------------------------------------------------------------
# 14. EXPORT DES VALEURS PROPRES ET VARIANCES
# ------------------------------------------------------------

eigenvalues <- data.frame(
  Composante = paste0(
    "PC",
    seq_along(variance_explained)
  ),
  Valeur_propre = pca$sdev^2,
  Variance_expliquee_pct = variance_explained * 100,
  Variance_cumulee_pct = cumulative_variance * 100
)

write.csv(
  eigenvalues,
  file.path(
    reports_dir,
    "variance_acp.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)


# ------------------------------------------------------------
# 15. CONTRIBUTIONS DES VARIABLES A L'ACP
# ------------------------------------------------------------

# pca$rotation contient les vecteurs propres.
# Les contributions sont calculées avec :
# Contribution = 100 * vecteur_propre^2

rotation_retained <- pca$rotation[
  ,
  seq_len(n_components),
  drop = FALSE
]


# Contributions des variables

contributions <- as.data.frame(
  100 * rotation_retained^2
)

contributions$Variable <- rownames(
  contributions
)

contributions <- contributions[
  ,
  c(
    "Variable",
    paste0("PC", seq_len(n_components))
  )
]

write.csv(
  contributions,
  file.path(
    reports_dir,
    "contributions_variables_acp.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)


# ------------------------------------------------------------
# 16. CORRELATIONS VARIABLES-COMPOSANTES
# ------------------------------------------------------------

# Les variables ayant été standardisées,
# les corrélations sont calculées par :
# Corr(variable, PC) = rotation * écart-type de PC

correlations <- as.data.frame(
  sweep(
    rotation_retained,
    2,
    pca$sdev[seq_len(n_components)],
    FUN = "*"
  )
)

correlations$Variable <- rownames(
  correlations
)

correlations <- correlations[
  ,
  c(
    "Variable",
    paste0("PC", seq_len(n_components))
  )
]

write.csv(
  correlations,
  file.path(
    reports_dir,
    "correlations_variables_composantes.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

component_interpretation <- do.call(
  rbind,
  lapply(
    seq_len(n_components),
    function(component_index) {

      component_name <- paste0("PC", component_index)
      component_correlations <- correlations[[component_name]]
      ordered_indices <- order(
        abs(component_correlations),
        decreasing = TRUE
      )
      top_indices <- ordered_indices[
        abs(component_correlations[ordered_indices]) >= 0.30
      ]
      if (length(top_indices) == 0) {
        top_indices <- ordered_indices[[1]]
      }
      top_indices <- head(top_indices, 3L)

      data.frame(
        Composante = component_name,
        Variance_expliquee_pct =
          variance_explained[[component_index]] * 100,
        Variable = correlations$Variable[top_indices],
        Correlation = component_correlations[top_indices],
        stringsAsFactors = FALSE
      )
    }
  )
)

write.csv(
  component_interpretation,
  file.path(
    reports_dir,
    "interpretation_composantes_acp.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)


# ------------------------------------------------------------
# 17. GRAPHIQUE DE LA VARIANCE EXPLIQUEE
# ------------------------------------------------------------

scree_data <- eigenvalues

scree_data$Composante <- factor(
  scree_data$Composante,
  levels = scree_data$Composante
)

p_scree <- ggplot2::ggplot(
  scree_data,
  ggplot2::aes(
    x = Composante,
    y = Variance_expliquee_pct
  )
) +

  ggplot2::geom_col(
    fill = "#2878B5"
  ) +

  ggplot2::geom_line(
    ggplot2::aes(
      y = Variance_cumulee_pct,
      group = 1
    ),
    color = "#C44E52",
    linewidth = 1
  ) +

  ggplot2::geom_point(
    ggplot2::aes(
      y = Variance_cumulee_pct
    ),
    color = "#C44E52",
    size = 2
  ) +

  ggplot2::geom_hline(
    yintercept = 80,
    linetype = "dashed",
    color = "darkgreen"
  ) +

  ggplot2::labs(
    title = "Variance expliquée par les composantes principales",
    subtitle = paste(
      "Composantes retenues :",
      n_components,
      "| Variance cumulée :",
      round(
        cumulative_variance[n_components] * 100,
        2
      ),
      "%"
    ),
    x = "Composante principale",
    y = "Variance expliquée (%)"
  ) +

  ggplot2::theme_minimal() +

  ggplot2::theme(
    axis.text.x = ggplot2::element_text(
      angle = 45,
      hjust = 1
    )
  )

ggplot2::ggsave(
  file.path(
    figures_dir,
    "01_variance_acp.png"
  ),
  p_scree,
  width = 10,
  height = 6,
  dpi = 160
)


# ------------------------------------------------------------
# 18. SELECTION DU NOMBRE DE CLUSTERS
# ------------------------------------------------------------

candidate_k <- 2:min(
  8L,
  nrow(pca_scores) - 1L
)

distance_matrix <- dist(
  pca_scores
)

set.seed(2026)


# Calcul K-means et silhouette pour chaque K

cluster_candidates <- lapply(
  candidate_k,
  function(k) {

    fit <- kmeans(
      pca_scores,
      centers = k,
      nstart = 50,
      iter.max = 100
    )

    silhouette <- cluster::silhouette(
      fit$cluster,
      distance_matrix
    )

    list(
      k = k,
      fit = fit,
      silhouette = silhouette,
      average_silhouette = mean(
        silhouette[, "sil_width"]
      )
    )
  }
)


# Tableau de sélection

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
  file.path(
    reports_dir,
    "selection_nombre_clusters.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)


# ------------------------------------------------------------
# 19. CHOIX DU MEILLEUR MODELE K-MEANS
# ------------------------------------------------------------

best_index <- which.max(
  silhouette_scores$Silhouette_moyenne
)

best_k <- silhouette_scores$K[[best_index]]

best_fit <- cluster_candidates[[best_index]]$fit

best_silhouette <- cluster_candidates[[best_index]]$silhouette

segment <- factor(
  best_fit$cluster
)

adjusted_rand_index <- function(reference, candidate) {

  contingency <- table(reference, candidate)
  choose_two <- function(values) {
    values * (values - 1) / 2
  }

  pair_count <- choose_two(sum(contingency))
  if (pair_count == 0) {
    return(NA_real_)
  }

  index <- sum(choose_two(contingency))
  row_pairs <- sum(choose_two(rowSums(contingency)))
  column_pairs <- sum(choose_two(colSums(contingency)))
  expected_index <- row_pairs * column_pairs / pair_count
  maximum_index <- (row_pairs + column_pairs) / 2
  denominator <- maximum_index - expected_index

  if (denominator == 0) {
    return(if (index == maximum_index) 1 else NA_real_)
  }

  (index - expected_index) / denominator
}

cah_fit <- hclust(
  distance_matrix,
  method = "ward.D2"
)
cah_cluster <- cutree(
  cah_fit,
  k = best_k
)
names(cah_cluster) <- as.character(seq_along(cah_cluster))
cah_silhouette <- cluster::silhouette(
  cah_cluster,
  distance_matrix
)

kmeans_cluster_sizes <- table(best_fit$cluster)
cah_cluster_sizes <- table(cah_cluster)

method_comparison <- data.frame(
  Methode = c("K-means", "CAH - Ward.D2"),
  Nombre_de_groupes = c(best_k, best_k),
  Distance = c("Euclidienne", "Euclidienne"),
  Silhouette_moyenne = c(
    mean(best_silhouette[, "sil_width"]),
    mean(cah_silhouette[, "sil_width"])
  ),
  Taille_minimale = c(
    min(kmeans_cluster_sizes),
    min(cah_cluster_sizes)
  ),
  Taille_maximale = c(
    max(kmeans_cluster_sizes),
    max(cah_cluster_sizes)
  ),
  ARI_vs_Kmeans = c(
    1,
    adjusted_rand_index(best_fit$cluster, cah_cluster)
  )
)

write.csv(
  method_comparison,
  file.path(
    reports_dir,
    "comparaison_kmeans_cah.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

method_projection_data <- rbind(
  data.frame(
    PC1 = pca$x[, 1],
    PC2 = pca$x[, 2],
    Segment = factor(best_fit$cluster),
    Methode = "K-means"
  ),
  data.frame(
    PC1 = pca$x[, 1],
    PC2 = pca$x[, 2],
    Segment = factor(cah_cluster),
    Methode = "CAH - Ward.D2"
  )
)

method_centers <- data.frame(
  PC1 = best_fit$centers[, 1],
  PC2 = best_fit$centers[, 2],
  Methode = "K-means"
)

p_method_projection <- ggplot2::ggplot(
  method_projection_data,
  ggplot2::aes(
    x = PC1,
    y = PC2,
    color = Segment
  )
) +
  ggplot2::geom_point(
    alpha = 0.55,
    size = 1.4
  ) +
  ggplot2::geom_point(
    data = method_centers,
    ggplot2::aes(
      x = PC1,
      y = PC2
    ),
    inherit.aes = FALSE,
    shape = 4,
    color = "black",
    size = 5,
    stroke = 1.5
  ) +
  ggplot2::facet_wrap(
    ~Methode
  ) +
  ggplot2::labs(
    title = paste(
      "Comparaison des partitions dans le plan ACP (K =",
      best_k,
      ")"
    ),
    subtitle = "Les numéros de segments sont propres à chaque méthode",
    x = sprintf(
      "PC1 (%.1f %% de variance)",
      variance_explained[[1]] * 100
    ),
    y = sprintf(
      "PC2 (%.1f %% de variance)",
      variance_explained[[2]] * 100
    ),
    color = "Segment"
  ) +
  ggplot2::theme_minimal()

ggplot2::ggsave(
  file.path(
    figures_dir,
    "06_comparaison_partitions_kmeans_cah.png"
  ),
  p_method_projection,
  width = 12,
  height = 6,
  dpi = 160
)

p_kmeans_centroids <- data.frame(
  Segment = factor(seq_len(nrow(best_fit$centers))),
  PC1 = best_fit$centers[, 1],
  PC2 = best_fit$centers[, 2]
)

p_kmeans_projection <- ggplot2::ggplot(
  data.frame(
    PC1 = pca$x[, 1],
    PC2 = pca$x[, 2],
    Segment = segment
  ),
  ggplot2::aes(
    x = PC1,
    y = PC2,
    color = Segment
  )
) +
  ggplot2::geom_point(
    alpha = 0.65,
    size = 1.8
  ) +
  ggplot2::geom_point(
    data = p_kmeans_centroids,
    ggplot2::aes(
      x = PC1,
      y = PC2
    ),
    inherit.aes = FALSE,
    shape = 4,
    color = "black",
    size = 5,
    stroke = 1.5
  ) +
  ggplot2::labs(
    title = paste0(
      "K-means : K = ",
      best_k,
      " (silhouette : ",
      sprintf("%.3f", mean(best_silhouette[, "sil_width"])),
      ")"
    ),
    subtitle = paste(
      "Projection sur PC1-PC2 ; clustering calculé sur",
      n_components,
      "composantes"
    ),
    x = sprintf(
      "PC1 (%.1f %% de variance)",
      variance_explained[[1]] * 100
    ),
    y = sprintf(
      "PC2 (%.1f %% de variance)",
      variance_explained[[2]] * 100
    ),
    color = "Segment"
  ) +
  ggplot2::theme_minimal()

ggplot2::ggsave(
  file.path(
    figures_dir,
    "09_kmeans_centroides_silhouette.png"
  ),
  p_kmeans_projection,
  width = 9,
  height = 7,
  dpi = 160
)

p_method_silhouette <- ggplot2::ggplot(
  method_comparison,
  ggplot2::aes(
    x = Methode,
    y = Silhouette_moyenne,
    fill = Methode
  )
) +
  ggplot2::geom_col(
    width = 0.65,
    show.legend = FALSE
  ) +
  ggplot2::geom_text(
    ggplot2::aes(
      label = sprintf("%.3f", Silhouette_moyenne)
    ),
    vjust = -0.4
  ) +
  ggplot2::coord_cartesian(
    ylim = c(
      0,
      max(method_comparison$Silhouette_moyenne) * 1.15
    )
  ) +
  ggplot2::labs(
    title = "Silhouette moyenne par méthode",
    subtitle = paste(
      "Distance euclidienne,",
      best_k,
      "groupes"
    ),
    x = NULL,
    y = "Silhouette moyenne"
  ) +
  ggplot2::theme_minimal()

ggplot2::ggsave(
  file.path(
    figures_dir,
    "07_comparaison_silhouette_kmeans_cah.png"
  ),
  p_method_silhouette,
  width = 8,
  height = 5,
  dpi = 160
)

p_dendrogram_path <- file.path(
  figures_dir,
  "08_dendrogramme_cah_ward.png"
)

cluster_palette <- setNames(
  c("#E64B35", "#4DBBD5", "#00A087", "#3C5488", "#F39B7F",
    "#8491B4", "#91D1C2", "#DC0000")[seq_len(best_k)],
  as.character(seq_len(best_k))
)

color_dendrogram_branches <- function(node) {

  if (is.leaf(node)) {
    leaf_label <- attr(node, "label")
    cluster_id <- unname(cah_cluster[as.character(leaf_label)])
    attr(node, "edgePar") <- list(
      col = cluster_palette[[as.character(cluster_id)]],
      lwd = 1.2
    )
    return(node)
  }

  node_labels <- labels(node)
  node_clusters <- unique(
    unname(cah_cluster[as.character(node_labels)])
  )
  edge_color <- if (length(node_clusters) == 1L) {
    cluster_palette[[as.character(node_clusters[[1]])]]
  } else {
    "#555555"
  }

  attr(node, "edgePar") <- list(
    col = edge_color,
    lwd = 1.2
  )

  for (child_index in seq_along(node)) {
    node[[child_index]] <- color_dendrogram_branches(
      node[[child_index]]
    )
  }

  node
}

dendrogram <- color_dendrogram_branches(
  as.dendrogram(cah_fit)
)

grDevices::png(
  filename = p_dendrogram_path,
  width = 1800,
  height = 1000,
  res = 160
)
plot(
  dendrogram,
  leaflab = "none",
  main = paste(
    "Dendrogramme de la CAH (Ward.D2, K =",
    best_k,
    ")"
  ),
  xlab = "Clients (étiquettes masquées)",
  ylab = "Hauteur de fusion",
  sub = ""
)
rect.hclust(
  cah_fit,
  k = best_k,
  border = seq_len(best_k) + 1L
)
grDevices::dev.off()

stability_runs <- 100L
stability_seed <- 2027L
stability_ari <- numeric(stability_runs)

set.seed(stability_seed)
for (run in seq_len(stability_runs)) {

  stability_fit <- kmeans(
    pca_scores,
    centers = best_k,
    nstart = 1,
    iter.max = 100
  )

  stability_ari[[run]] <- adjusted_rand_index(
    best_fit$cluster,
    stability_fit$cluster
  )
}

stability_results <- data.frame(
  Initialisation = seq_len(stability_runs),
  ARI_vs_partition_reference = stability_ari
)

write.csv(
  stability_results,
  file.path(
    reports_dir,
    "stabilite_kmeans_initialisations.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

stability_summary <- data.frame(
  Nombre_initialisations = stability_runs,
  Graine = stability_seed,
  ARI_moyen = mean(stability_ari, na.rm = TRUE),
  ARI_ecart_type = sd(stability_ari, na.rm = TRUE),
  ARI_minimum = min(stability_ari, na.rm = TRUE),
  ARI_quantile_05 = unname(
    quantile(stability_ari, 0.05, na.rm = TRUE)
  ),
  ARI_maximum = max(stability_ari, na.rm = TRUE),
  Partitions_identiques_pct = mean(
    stability_ari >= 1 - 1e-12,
    na.rm = TRUE
  ) * 100
)

write.csv(
  stability_summary,
  file.path(
    reports_dir,
    "resume_stabilite_kmeans.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

subsample_runs <- 100L
subsample_fraction <- 0.80
subsample_size <- floor(
  nrow(pca_scores) * subsample_fraction
)
subsample_seed <- 2028L
subsample_ari <- numeric(subsample_runs)
pca_score_matrix <- as.matrix(pca_scores)

set.seed(subsample_seed)
subsample_indices <- lapply(
  seq_len(subsample_runs),
  function(run) {
    sample.int(
      nrow(pca_score_matrix),
      size = subsample_size,
      replace = FALSE
    )
  }
)
subsample_fit_seeds <- sample.int(
  .Machine$integer.max,
  size = subsample_runs
)

for (run in seq_len(subsample_runs)) {

  current_indices <- subsample_indices[[run]]

  set.seed(subsample_fit_seeds[[run]])
  subsample_fit <- kmeans(
    pca_score_matrix[current_indices, , drop = FALSE],
    centers = best_k,
    nstart = 50,
    iter.max = 100
  )

  distances_to_centers <- vapply(
    seq_len(nrow(subsample_fit$centers)),
    function(cluster_index) {

      differences <- sweep(
        pca_score_matrix,
        2,
        subsample_fit$centers[cluster_index, ],
        FUN = "-"
      )

      rowSums(differences^2)
    },
    numeric(nrow(pca_score_matrix))
  )

  predicted_clusters <- max.col(
    -distances_to_centers,
    ties.method = "first"
  )

  subsample_ari[[run]] <- adjusted_rand_index(
    best_fit$cluster,
    predicted_clusters
  )
}

subsample_results <- data.frame(
  Repetition = seq_len(subsample_runs),
  Taille_sous_echantillon = subsample_size,
  Fraction_clients_pct = subsample_size / nrow(pca_score_matrix) * 100,
  Graine_kmeans = subsample_fit_seeds,
  ARI_vs_partition_reference = subsample_ari
)

write.csv(
  subsample_results,
  file.path(
    reports_dir,
    "stabilite_sous_echantillonnage.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

subsample_stability_summary <- data.frame(
  Nombre_repetitions = subsample_runs,
  Fraction_clients_pct = subsample_size / nrow(pca_score_matrix) * 100,
  Taille_sous_echantillon = subsample_size,
  Initialisations_kmeans_par_repetition = 50L,
  Graine = subsample_seed,
  ARI_moyen = mean(subsample_ari, na.rm = TRUE),
  ARI_ecart_type = sd(subsample_ari, na.rm = TRUE),
  ARI_minimum = min(subsample_ari, na.rm = TRUE),
  ARI_quantile_05 = unname(
    quantile(subsample_ari, 0.05, na.rm = TRUE)
  ),
  ARI_maximum = max(subsample_ari, na.rm = TRUE)
)

write.csv(
  subsample_stability_summary,
  file.path(
    reports_dir,
    "resume_stabilite_sous_echantillonnage.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)


# ------------------------------------------------------------
# 20. VALIDATION SUR UN ECHANTILLON MIS DE COTE
# ------------------------------------------------------------

set.seed(2029)
validation_test_indices <- sample.int(
  nrow(data),
  size = floor(nrow(data) * 0.20),
  replace = FALSE
)
validation_train_indices <- setdiff(
  seq_len(nrow(data)),
  validation_test_indices
)
validation_train_data <- data[
  validation_train_indices,
  ,
  drop = FALSE
]
validation_test_data <- data[
  validation_test_indices,
  ,
  drop = FALSE
]

fit_validation_preprocessing <- function(training_data) {

  values <- training_data[
    ,
    segmentation_features,
    drop = FALSE
  ]
  values$Age_Client[
    !is.na(values$Age_Client) & values$Age_Client > 90
  ] <- NA_real_
  values$Income[
    !is.na(values$Income) & values$Income == 666666
  ] <- NA_real_

  medians <- vapply(
    values,
    median,
    numeric(1),
    na.rm = TRUE
  )
  if (any(!is.finite(medians))) {
    stop("Impossible d'estimer les médianes de prétraitement sur l'entraînement.")
  }
  for (column in segmentation_features) {
    values[[column]][is.na(values[[column]])] <- medians[[column]]
  }

  cap_bounds <- t(vapply(
    cap_features,
    function(column) {
      quantile(
        values[[column]],
        probs = c(0.01, 0.99),
        names = FALSE
      )
    },
    numeric(2)
  ))
  colnames(cap_bounds) <- c("minimum", "maximum")

  for (column in cap_features) {
    values[[column]] <- pmin(
      pmax(values[[column]], cap_bounds[column, "minimum"]),
      cap_bounds[column, "maximum"]
    )
  }
  for (column in log_features) {
    values[[column]] <- log1p(values[[column]])
  }

  centers <- vapply(values, mean, numeric(1))
  scales <- vapply(values, sd, numeric(1))
  if (any(!is.finite(scales) | scales == 0)) {
    stop("Prétraitement d'entraînement invalide : variable sans variance.")
  }

  list(
    medians = medians,
    cap_bounds = cap_bounds,
    centers = centers,
    scales = scales
  )
}

apply_validation_preprocessing <- function(input_data, preprocessing) {

  values <- input_data[
    ,
    segmentation_features,
    drop = FALSE
  ]
  values$Age_Client[
    !is.na(values$Age_Client) & values$Age_Client > 90
  ] <- NA_real_
  values$Income[
    !is.na(values$Income) & values$Income == 666666
  ] <- NA_real_

  for (column in segmentation_features) {
    values[[column]][
      is.na(values[[column]])
    ] <- preprocessing$medians[[column]]
  }
  for (column in cap_features) {
    values[[column]] <- pmin(
      pmax(
        values[[column]],
        preprocessing$cap_bounds[column, "minimum"]
      ),
      preprocessing$cap_bounds[column, "maximum"]
    )
  }
  for (column in log_features) {
    values[[column]] <- log1p(values[[column]])
  }

  values <- sweep(values, 2, preprocessing$centers, FUN = "-")
  values <- sweep(values, 2, preprocessing$scales, FUN = "/")

  if (any(!is.finite(as.matrix(values)))) {
    stop("Le prétraitement a produit des valeurs non finies.")
  }
  values
}

validation_preprocessing <- fit_validation_preprocessing(
  validation_train_data
)
validation_train_matrix <- apply_validation_preprocessing(
  validation_train_data,
  validation_preprocessing
)
validation_test_matrix <- apply_validation_preprocessing(
  validation_test_data,
  validation_preprocessing
)
validation_pca <- prcomp(
  validation_train_matrix,
  center = FALSE,
  scale. = FALSE
)
validation_variance <- validation_pca$sdev^2 /
  sum(validation_pca$sdev^2)
validation_cumulative_variance <- cumsum(validation_variance)
validation_n_components <- min(
  which(validation_cumulative_variance >= 0.80)[1],
  10L,
  ncol(validation_pca$x)
)
validation_train_scores <- validation_pca$x[
  ,
  seq_len(validation_n_components),
  drop = FALSE
]
validation_test_scores <- predict(
  validation_pca,
  newdata = validation_test_matrix
)[
  ,
  seq_len(validation_n_components),
  drop = FALSE
]

validation_candidate_k <- 2:min(
  8L,
  nrow(validation_train_scores) - 1L
)
validation_train_distances <- dist(validation_train_scores)
set.seed(2030)
validation_candidates <- lapply(
  validation_candidate_k,
  function(k) {
    fit <- kmeans(
      validation_train_scores,
      centers = k,
      nstart = 50,
      iter.max = 100
    )
    silhouette <- cluster::silhouette(
      fit$cluster,
      validation_train_distances
    )
    list(
      fit = fit,
      silhouette = silhouette,
      average_silhouette = mean(silhouette[, "sil_width"])
    )
  }
)
validation_best_index <- which.max(vapply(
  validation_candidates,
  function(candidate) candidate$average_silhouette,
  numeric(1)
))
validation_best_k <- validation_candidate_k[[validation_best_index]]
validation_train_fit <- validation_candidates[[validation_best_index]]$fit
validation_train_silhouette <-
  validation_candidates[[validation_best_index]]$silhouette

validation_squared_distances <- vapply(
  seq_len(nrow(validation_train_fit$centers)),
  function(cluster_index) {
    differences <- sweep(
      validation_test_scores,
      2,
      validation_train_fit$centers[cluster_index, ],
      FUN = "-"
    )
    rowSums(differences^2)
  },
  numeric(nrow(validation_test_scores))
)
validation_test_clusters <- max.col(
  -validation_squared_distances,
  ties.method = "first"
)
if (length(unique(validation_test_clusters)) < 2L) {
  stop(
    "La partition de test ne contient pas au moins deux segments. ",
    "La silhouette de validation ne peut pas être calculée."
  )
}
validation_test_silhouette <- cluster::silhouette(
  validation_test_clusters,
  dist(validation_test_scores)
)

validation_summary <- data.frame(
  Echantillon = c("Entrainement", "Test mis de cote"),
  Nombre_clients = c(
    nrow(validation_train_data),
    nrow(validation_test_data)
  ),
  Pourcentage_clients = c(
    nrow(validation_train_data),
    nrow(validation_test_data)
  ) / nrow(data) * 100,
  Nombre_composantes = validation_n_components,
  Variance_cumulee_pct =
    validation_cumulative_variance[validation_n_components] * 100,
  K_retenu = validation_best_k,
  Silhouette_moyenne = c(
    mean(validation_train_silhouette[, "sil_width"]),
    mean(validation_test_silhouette[, "sil_width"])
  ),
  Graine_decoupage = 2029L,
  stringsAsFactors = FALSE
)
write.csv(
  validation_summary,
  file.path(reports_dir, "validation_echantillon_mis_de_cote.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

validation_test_assignments <- data.frame(
  ID = validation_test_data$ID,
  Segment_entraine = validation_test_clusters,
  Silhouette_test = validation_test_silhouette[, "sil_width"]
)
write.csv(
  validation_test_assignments,
  file.path(reports_dir, "affectations_test_independant.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

validation_profile_data <- validation_test_data
validation_profile_data$Age_Client[
  !is.na(validation_profile_data$Age_Client) &
    validation_profile_data$Age_Client > 90
] <- NA_real_
validation_profile_data$Income[
  !is.na(validation_profile_data$Income) &
    validation_profile_data$Income == 666666
] <- NA_real_

validation_profile_variables <- c(
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
validation_profiles <- do.call(
  rbind,
  lapply(
    seq_len(validation_best_k),
    function(cluster_index) {
      rows <- validation_test_clusters == cluster_index
      data.frame(
        Segment_entraine = cluster_index,
        Nombre_clients = sum(rows),
        lapply(
          validation_profile_data[
            rows,
            validation_profile_variables,
            drop = FALSE
          ],
          median,
          na.rm = TRUE
        ),
        Taux_reponse_pct = mean(
          validation_test_data$Response[rows],
          na.rm = TRUE
        ) * 100,
        check.names = FALSE
      )
    }
  )
)
write.csv(
  validation_profiles,
  file.path(reports_dir, "profils_segments_test_independant.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)


# ------------------------------------------------------------
# 21. DIAGNOSTIC DETAILLE DES SILHOUETTES
# ------------------------------------------------------------

silhouette_data <- data.frame(
  Segment = factor(
    best_silhouette[, "cluster"]
  ),
  Largeur_silhouette = best_silhouette[
    ,
    "sil_width"
  ]
)


# Résumé par segment

silhouette_diagnostic <- do.call(
  rbind,
  lapply(
    levels(silhouette_data$Segment),
    function(level) {

      values <- silhouette_data$Largeur_silhouette[
        silhouette_data$Segment == level
      ]

      data.frame(
        Segment = level,
        Nombre_clients = length(values),
        Silhouette_moyenne = mean(values),
        Silhouette_q05 = unname(quantile(values, 0.05)),
        Silhouette_q25 = unname(quantile(values, 0.25)),
        Silhouette_mediane = median(values),
        Silhouette_q75 = unname(quantile(values, 0.75)),
        Silhouette_q95 = unname(quantile(values, 0.95)),
        Pourcentage_silhouettes_negatives =
          mean(values < 0) * 100,
        Pourcentage_silhouettes_entre_0_et_0_10 =
          mean(values >= 0 & values <= 0.10) * 100
      )
    }
  )
)

write.csv(
  silhouette_diagnostic,
  file.path(
    reports_dir,
    "diagnostic_silhouette_segments.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

boundary_threshold <- 0.10
boundary_indices <- which(
  best_silhouette[, "sil_width"] <= boundary_threshold
)
individual_silhouettes <- data.frame(
  ID = data$ID,
  Segment = best_silhouette[, "cluster"],
  Segment_voisin = best_silhouette[, "neighbor"],
  Largeur_silhouette = best_silhouette[, "sil_width"],
  check.names = FALSE
)
individual_silhouettes <- individual_silhouettes[
  order(
    individual_silhouettes$Segment,
    individual_silhouettes$Largeur_silhouette
  ),
  ,
  drop = FALSE
]
write.csv(
  individual_silhouettes,
  file.path(reports_dir, "silhouettes_individuelles.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

boundary_clients <- data.frame(
  ID = data$ID[boundary_indices],
  Segment = best_silhouette[boundary_indices, "cluster"],
  Segment_voisin = best_silhouette[boundary_indices, "neighbor"],
  Silhouette = best_silhouette[boundary_indices, "sil_width"],
  data[
    boundary_indices,
    c(segmentation_features, "Response"),
    drop = FALSE
  ],
  check.names = FALSE
)
boundary_clients <- boundary_clients[
  order(boundary_clients$Silhouette),
  ,
  drop = FALSE
]
write.csv(
  boundary_clients,
  file.path(reports_dir, "clients_proches_frontiere.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

boundary_summary <- data.frame(
  Seuil_silhouette = boundary_threshold,
  Nombre_clients_proches_frontiere = length(boundary_indices),
  Pourcentage_clients_proches_frontiere =
    length(boundary_indices) / nrow(data) * 100,
  Nombre_silhouettes_negatives =
    sum(best_silhouette[, "sil_width"] < 0),
  Pourcentage_silhouettes_negatives =
    mean(best_silhouette[, "sil_width"] < 0) * 100
)
write.csv(
  boundary_summary,
  file.path(reports_dir, "resume_clients_proches_frontiere.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

p_individual_silhouettes <- ggplot2::ggplot(
  individual_silhouettes,
  ggplot2::aes(
    x = seq_len(nrow(individual_silhouettes)),
    y = Largeur_silhouette,
    fill = factor(Segment)
  )
) +
  ggplot2::geom_col(
    width = 1
  ) +
  ggplot2::geom_hline(
    yintercept = 0,
    color = "#C44E52",
    linewidth = 0.7
  ) +
  ggplot2::geom_hline(
    yintercept = boundary_threshold,
    color = "#E69F00",
    linetype = "dashed",
    linewidth = 0.7
  ) +
  ggplot2::facet_grid(
    Segment ~ .,
    scales = "free_x",
    space = "free_x"
  ) +
  ggplot2::labs(
    title = "Silhouettes individuelles de la partition K-means",
    subtitle = paste(
      "Valeur négative : affectation à examiner | Seuil exploratoire :",
      boundary_threshold
    ),
    x = "Clients de chaque segment, triés par silhouette croissante",
    y = "Largeur de silhouette",
    fill = "Segment"
  ) +
  ggplot2::theme_minimal() +
  ggplot2::theme(
    legend.position = "none",
    axis.text.x = ggplot2::element_blank(),
    axis.ticks.x = ggplot2::element_blank()
  )

ggplot2::ggsave(
  file.path(figures_dir, "10_silhouettes_individuelles.png"),
  p_individual_silhouettes,
  width = 10,
  height = 7,
  dpi = 160
)


# ------------------------------------------------------------
# 22. GRAPHIQUE DE SELECTION DES CLUSTERS
# ------------------------------------------------------------

p_silhouette <- ggplot2::ggplot(
  silhouette_scores,
  ggplot2::aes(
    x = K,
    y = Silhouette_moyenne
  )
) +

  ggplot2::geom_line(
    color = "#2878B5",
    linewidth = 1
  ) +

  ggplot2::geom_point(
    size = 3,
    color = "#C44E52"
  ) +

  ggplot2::geom_vline(
    xintercept = best_k,
    linetype = "dashed",
    color = "#55A868"
  ) +

  ggplot2::scale_x_continuous(
    breaks = candidate_k
  ) +

  ggplot2::labs(
    title = "Sélection du nombre de segments",
    subtitle = paste(
      "K retenu :",
      best_k,
      "| Silhouette moyenne :",
      round(
        silhouette_scores$Silhouette_moyenne[
          best_index
        ],
        3
      )
    ),
    x = "Nombre de clusters (K)",
    y = "Silhouette moyenne"
  ) +

  ggplot2::theme_minimal()

ggplot2::ggsave(
  file.path(
    figures_dir,
    "02_selection_clusters.png"
  ),
  p_silhouette,
  width = 8,
  height = 5,
  dpi = 160
)


# ------------------------------------------------------------
# 22. DISTRIBUTION DES SILHOUETTES
# ------------------------------------------------------------

p_silhouette_segments <- ggplot2::ggplot(
  silhouette_data,
  ggplot2::aes(
    x = Largeur_silhouette,
    fill = Segment
  )
) +

  ggplot2::geom_histogram(
    bins = 30,
    alpha = 0.8,
    position = "identity"
  ) +

  ggplot2::geom_vline(
    xintercept = 0,
    linetype = "dashed"
  ) +

  ggplot2::labs(
    title = "Distribution des largeurs de silhouette",
    x = "Largeur de silhouette",
    y = "Nombre de clients",
    fill = "Segment"
  ) +

  ggplot2::theme_minimal()

ggplot2::ggsave(
  file.path(
    figures_dir,
    "03_diagnostic_silhouette.png"
  ),
  p_silhouette_segments,
  width = 8,
  height = 5,
  dpi = 160
)


# ------------------------------------------------------------
# 23. REPRESENTATION DES SEGMENTS DANS LE PLAN ACP
# ------------------------------------------------------------

plot_data <- data.frame(
  PC1 = pca$x[, 1],
  PC2 = pca$x[, 2],
  Segment = segment
)

p_segments <- ggplot2::ggplot(
  plot_data,
  ggplot2::aes(
    x = PC1,
    y = PC2,
    color = Segment
  )
) +

  ggplot2::geom_point(
    alpha = 0.65,
    size = 1.8
  ) +

  ggplot2::labs(
    title = paste(
      "Segmentation des clients dans le plan ACP (K =",
      best_k,
      ")"
    ),
    x = sprintf(
      "PC1 (%.1f %% de variance)",
      variance_explained[[1]] * 100
    ),
    y = sprintf(
      "PC2 (%.1f %% de variance)",
      variance_explained[[2]] * 100
    ),
    color = "Segment"
  ) +

  ggplot2::theme_minimal()

ggplot2::ggsave(
  file.path(
    figures_dir,
    "04_segments_plan_acp.png"
  ),
  p_segments,
  width = 9,
  height = 6,
  dpi = 160
)


# ------------------------------------------------------------
# 24. TAILLE DES SEGMENTS
# ------------------------------------------------------------

segment_sizes <- as.data.frame(
  table(
    Segment = segment
  )
)

names(segment_sizes)[[2]] <- "Nombre_clients"

segment_sizes$Pourcentage <-
  segment_sizes$Nombre_clients /
  nrow(data) * 100

write.csv(
  segment_sizes,
  file.path(
    reports_dir,
    "tailles_segments.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)


# ------------------------------------------------------------
# 25. PROFILS DES SEGMENTS
# ------------------------------------------------------------

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

segment_descriptive_data <- data
segment_descriptive_data$Age_Client[
  !is.na(segment_descriptive_data$Age_Client) &
    segment_descriptive_data$Age_Client > 90
] <- NA_real_
segment_descriptive_data$Income[
  !is.na(segment_descriptive_data$Income) &
    segment_descriptive_data$Income == 666666
] <- NA_real_

method_cluster_labels <- list(
  "K-means" = best_fit$cluster,
  "CAH - Ward.D2" = cah_cluster
)

method_cluster_sizes <- do.call(
  rbind,
  lapply(
    names(method_cluster_labels),
    function(method) {

      sizes <- table(method_cluster_labels[[method]])

      data.frame(
        Methode = method,
        Segment = names(sizes),
        Nombre_clients = as.integer(sizes),
        Pourcentage = as.integer(sizes) / nrow(data) * 100,
        row.names = NULL
      )
    }
  )
)

write.csv(
  method_cluster_sizes,
  file.path(
    reports_dir,
    "tailles_segments_comparaison.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

method_profile_comparison <- do.call(
  rbind,
  lapply(
    names(method_cluster_labels),
    function(method) {

      labels <- method_cluster_labels[[method]]
      do.call(
        rbind,
        lapply(
          sort(unique(labels)),
          function(level) {

            rows <- labels == level
            data.frame(
              Methode = method,
              Segment = as.character(level),
              Nombre_clients = sum(rows),
              lapply(
                segment_descriptive_data[
                  rows,
                  profile_variables,
                  drop = FALSE
                ],
                median,
                na.rm = TRUE
              ),
              Taux_reponse_pct = mean(
                segment_descriptive_data$Response[rows],
                na.rm = TRUE
              ) * 100,
              check.names = FALSE
            )
          }
        )
      )
    }
  )
)

write.csv(
  method_profile_comparison,
  file.path(
    reports_dir,
    "profils_kmeans_cah.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)


# Calcul des médianes par segment

cluster_profiles <- do.call(
  rbind,
  lapply(
    levels(segment),
    function(level) {

      rows <- segment == level

      data.frame(
        Segment = level,
        Nombre_clients = sum(rows),
        lapply(
          segment_descriptive_data[
            rows,
            profile_variables,
            drop = FALSE
          ],
          median,
          na.rm = TRUE
        ),
        check.names = FALSE
      )
    }
  )
)


# Taux de réponse après segmentation

cluster_profiles$Taux_reponse_pct <- vapply(
  levels(segment),
  function(level) {

    mean(
      data$Response[
        segment == level
      ],
      na.rm = TRUE
    ) * 100
  },
  numeric(1)
)


# Modalité d'éducation majoritaire

cluster_profiles$Education_majoritaire <- vapply(
  levels(segment),
  function(level) {

    values <- segment_descriptive_data$Education[
      segment == level
    ]

    names(
      which.max(
        table(values)
      )
    )
  },
  character(1)
)


# Statut matrimonial majoritaire

cluster_profiles$Statut_matrimonial_majoritaire <-
  vapply(
    levels(segment),
    function(level) {

      values <- segment_descriptive_data$Marital_Status[
        segment == level
      ]

      names(
        which.max(
          table(values)
        )
      )
    },
    character(1)
  )


# Export des profils

write.csv(
  cluster_profiles,
  file.path(
    reports_dir,
    "profils_segments.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

quantitative_distribution_summary <- do.call(
  rbind,
  lapply(
    profile_variables,
    function(variable) {
      do.call(
        rbind,
        lapply(
          levels(segment),
          function(level) {
            values <- segment_descriptive_data[[variable]][
              segment == level
            ]
            observed <- values[is.finite(values)]
            data.frame(
              Variable = variable,
              Segment = level,
              Nombre_clients = length(values),
              Nombre_observe = length(observed),
              Nombre_manquant = sum(!is.finite(values)),
              Moyenne = mean(observed),
              Ecart_type = sd(observed),
              Mediane = median(observed),
              Q1 = unname(quantile(observed, 0.25)),
              Q3 = unname(quantile(observed, 0.75)),
              IQR = IQR(observed),
              Pourcentage_zero = mean(observed == 0) * 100,
              check.names = FALSE
            )
          }
        )
      )
    }
  )
)
write.csv(
  quantitative_distribution_summary,
  file.path(reports_dir, "distributions_quantitatives_segments.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

quantitative_tests <- lapply(
  profile_variables,
  function(variable) {
    values <- segment_descriptive_data[[variable]]
    group_one <- values[segment == levels(segment)[[1]]]
    group_two <- values[segment == levels(segment)[[2]]]
    group_one <- group_one[is.finite(group_one)]
    group_two <- group_two[is.finite(group_two)]

    test <- stats::wilcox.test(
      group_one,
      group_two,
      exact = FALSE,
      correct = TRUE
    )
    u_statistic <- unname(test$statistic)
    rank_biserial <- 2 * u_statistic /
      (length(group_one) * length(group_two)) - 1

    data.frame(
      Variable = variable,
      Type = "Quantitative",
      Test = "Wilcoxon-Mann-Whitney",
      N_segment_1 = length(group_one),
      N_segment_2 = length(group_two),
      Mediane_segment_1 = median(group_one),
      Mediane_segment_2 = median(group_two),
      Difference_medianes = median(group_one) - median(group_two),
      Statistique = u_statistic,
      Taille_effet = rank_biserial,
      Mesure_taille_effet = "Delta de Cliff (segment 1 vs 2)",
      P_value = max(test$p.value, .Machine$double.xmin),
      stringsAsFactors = FALSE
    )
  }
)

categorical_variables <- c(
  "Response",
  "Education",
  "Marital_Status"
)
categorical_distribution_summary <- do.call(
  rbind,
  lapply(
    categorical_variables,
    function(variable) {
      values <- as.character(segment_descriptive_data[[variable]])
      values[is.na(values)] <- "Manquant"
      counts <- table(
        Modalite = values,
        Segment = segment,
        useNA = "no"
      )
      proportions <- prop.table(counts, margin = 2) * 100
      data.frame(
        Variable = variable,
        Modalite = rep(rownames(counts), times = ncol(counts)),
        Segment = rep(colnames(counts), each = nrow(counts)),
        Nombre_clients = as.vector(counts),
        Pourcentage_segment = as.vector(proportions),
        row.names = NULL,
        check.names = FALSE
      )
    }
  )
)
write.csv(
  categorical_distribution_summary,
  file.path(reports_dir, "distributions_categorielles_segments.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

categorical_tests <- lapply(
  categorical_variables,
  function(variable) {
    values <- as.character(segment_descriptive_data[[variable]])
    values[is.na(values)] <- "Manquant"
    contingency <- table(
      Modalite = values,
      Segment = segment,
      useNA = "no"
    )
    chi_square <- suppressWarnings(
      stats::chisq.test(contingency, correct = FALSE)
    )
    use_simulation <- any(chi_square$expected < 5)
    if (use_simulation) {
      set.seed(2031)
      test <- stats::chisq.test(
        contingency,
        correct = FALSE,
        simulate.p.value = TRUE,
        B = 10000
      )
      test_name <- "Chi-deux simule (10 000 repetitions)"
    } else {
      test <- chi_square
      test_name <- "Chi-deux de Pearson"
    }
    cramer_v <- sqrt(
      unname(test$statistic) /
        (sum(contingency) * min(dim(contingency) - 1))
    )

    data.frame(
      Variable = variable,
      Type = "Categorielle",
      Test = test_name,
      N_segment_1 = sum(contingency[, 1]),
      N_segment_2 = sum(contingency[, 2]),
      Mediane_segment_1 = NA_real_,
      Mediane_segment_2 = NA_real_,
      Difference_medianes = NA_real_,
      Statistique = unname(test$statistic),
      Taille_effet = cramer_v,
      Mesure_taille_effet = "V de Cramer",
      P_value = test$p.value,
      stringsAsFactors = FALSE
    )
  }
)

segment_difference_tests <- do.call(
  rbind,
  c(quantitative_tests, categorical_tests)
)
segment_difference_tests$P_value_Holm <- stats::p.adjust(
  segment_difference_tests$P_value,
  method = "holm"
)
segment_difference_tests <- segment_difference_tests[
  order(segment_difference_tests$P_value_Holm),
  ,
  drop = FALSE
]
write.csv(
  segment_difference_tests,
  file.path(reports_dir, "tests_differences_segments.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

quantitative_distribution_long <- do.call(
  rbind,
  lapply(
    profile_variables,
    function(variable) {
      data.frame(
        Variable = variable,
        Segment = segment,
        Valeur = segment_descriptive_data[[variable]]
      )
    }
  )
)
quantitative_distribution_long <- quantitative_distribution_long[
  is.finite(quantitative_distribution_long$Valeur),
  ,
  drop = FALSE
]

p_segment_boxplots <- ggplot2::ggplot(
  quantitative_distribution_long,
  ggplot2::aes(
    x = Segment,
    y = Valeur,
    fill = Segment
  )
) +
  ggplot2::geom_boxplot(
    outlier.alpha = 0.20,
    outlier.size = 0.5
  ) +
  ggplot2::facet_wrap(
    ~Variable,
    scales = "free_y",
    ncol = 4
  ) +
  ggplot2::labs(
    title = "Distributions quantitatives par segment",
    subtitle = "Valeurs originales ; âge > 90 et revenu = 666666 exclus des descriptifs",
    x = "Segment K-means",
    y = "Valeur",
    fill = "Segment"
  ) +
  ggplot2::theme_minimal() +
  ggplot2::theme(
    legend.position = "none",
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
  )
ggplot2::ggsave(
  file.path(figures_dir, "11_distributions_quantitatives_segments.png"),
  p_segment_boxplots,
  width = 13,
  height = 10,
  dpi = 160
)

p_segment_ecdf <- ggplot2::ggplot(
  quantitative_distribution_long,
  ggplot2::aes(
    x = Valeur,
    color = Segment
  )
) +
  ggplot2::stat_ecdf(
    linewidth = 0.7,
    alpha = 0.85
  ) +
  ggplot2::facet_wrap(
    ~Variable,
    scales = "free_x",
    ncol = 4
  ) +
  ggplot2::labs(
    title = "Distributions cumulées des variables par segment",
    x = "Valeur observée",
    y = "Proportion cumulée",
    color = "Segment"
  ) +
  ggplot2::theme_minimal()
ggplot2::ggsave(
  file.path(figures_dir, "12_distributions_cumulees_segments.png"),
  p_segment_ecdf,
  width = 13,
  height = 10,
  dpi = 160
)

p_categorical_distributions <- ggplot2::ggplot(
  categorical_distribution_summary,
  ggplot2::aes(
    x = Modalite,
    y = Pourcentage_segment,
    fill = Segment
  )
) +
  ggplot2::geom_col(
    position = "dodge"
  ) +
  ggplot2::facet_wrap(
    ~Variable,
    scales = "free_x"
  ) +
  ggplot2::labs(
    title = "Variables catégorielles et réponse par segment",
    x = "Modalité",
    y = "Pourcentage dans le segment",
    fill = "Segment"
  ) +
  ggplot2::theme_minimal() +
  ggplot2::theme(
    axis.text.x = ggplot2::element_text(angle = 35, hjust = 1)
  )
ggplot2::ggsave(
  file.path(figures_dir, "13_distributions_categorielles_segments.png"),
  p_categorical_distributions,
  width = 12,
  height = 6,
  dpi = 160
)

total_spending <- rowSums(
  data[
    ,
    spending_features,
    drop = FALSE
  ],
  na.rm = TRUE
)
overall_median_spending <- median(
  total_spending,
  na.rm = TRUE
)
overall_response_rate <- mean(
  data$Response,
  na.rm = TRUE
) * 100
purchase_channels <- c(
  "Web" = "NumWebPurchases",
  "Catalogue" = "NumCatalogPurchases",
  "Magasin" = "NumStorePurchases"
)

marketing_recommendations <- do.call(
  rbind,
  lapply(
    levels(segment),
    function(level) {

      rows <- segment == level
      segment_median_spending <- median(
        total_spending[rows],
        na.rm = TRUE
      )
      channel_medians <- vapply(
        purchase_channels,
        function(variable) {
          median(
            data[[variable]][rows],
            na.rm = TRUE
          )
        },
        numeric(1)
      )
      preferred_channel <- names(
        channel_medians[channel_medians == max(channel_medians)]
      )
      preferred_channel <- paste(
        preferred_channel,
        collapse = " / "
      )
      response_rate <- mean(
        data$Response[rows],
        na.rm = TRUE
      ) * 100

      spending_profile <- if (
        segment_median_spending > overall_median_spending
      ) {
        "au-dessus"
      } else if (
        segment_median_spending < overall_median_spending
      ) {
        "au-dessous"
      } else {
        "au niveau de"
      }

      spending_action <- if (
        segment_median_spending > overall_median_spending
      ) {
        "Tester une action de fidélisation ou une offre premium."
      } else if (
        segment_median_spending < overall_median_spending
      ) {
        "Tester une offre de découverte ou de vente croisée."
      } else {
        "Tester une campagne généraliste avant de différencier l'offre."
      }

      response_action <- if (
        response_rate > overall_response_rate
      ) {
        "Prioriser un pilote de campagne sur ce segment."
      } else if (
        response_rate < overall_response_rate
      ) {
        "Tester plusieurs messages ou incitations avant d'augmenter la pression marketing."
      } else {
        "Comparer une campagne de référence et une variante avant de différencier le traitement."
      }

      data.frame(
        Segment = level,
        Depenses_totales_medianes = segment_median_spending,
        Depenses_totales_medianes_population =
          overall_median_spending,
        Niveau_depenses = spending_profile,
        Canal_achat_median_le_plus_utilise = preferred_channel,
        Taux_reponse_pct = response_rate,
        Taux_reponse_population_pct = overall_response_rate,
        Recommandation = paste(
          spending_action,
          paste0(
            "Adapter le test au canal d'achat médian le plus utilisé : ",
            preferred_channel,
            "."
          ),
          response_action
        ),
        stringsAsFactors = FALSE
      )
    }
  )
)

write.csv(
  marketing_recommendations,
  file.path(
    reports_dir,
    "recommandations_marketing.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)


# ------------------------------------------------------------
# 26. AFFECTATION DES CLIENTS AUX SEGMENTS
# ------------------------------------------------------------

cluster_assignments <- data.frame(
  ID = data$ID,
  Segment = segment
)

write.csv(
  cluster_assignments,
  file.path(
    reports_dir,
    "affectation_clients_segments.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)


# ------------------------------------------------------------
# 27. PREPARATION DU GRAPHIQUE DES PROFILS
# ------------------------------------------------------------

profile_long <- do.call(
  rbind,
  lapply(
    seq_len(nrow(cluster_profiles)),
    function(i) {

      values <- as.numeric(
        unlist(
          cluster_profiles[
            i,
            profile_variables
          ],
          use.names = FALSE
        )
      )

      data.frame(
        Segment = cluster_profiles$Segment[[i]],
        Variable = profile_variables,
        Mediane = values
      )
    }
  )
)


# Standardisation des médianes par rapport
# à la moyenne et à l'écart-type de la population complète.

profile_long$Valeur_standardisee <- mapply(
  function(mediane, variable) {

    moyenne_globale <- mean(
      data[[variable]],
      na.rm = TRUE
    )

    ecart_type_global <- sd(
      data[[variable]],
      na.rm = TRUE
    )

    if (
      is.na(ecart_type_global) ||
      ecart_type_global == 0
    ) {

      return(0)
    }

    (
      mediane - moyenne_globale
    ) / ecart_type_global

  },
  profile_long$Mediane,
  profile_long$Variable
)


# ------------------------------------------------------------
# 28. GRAPHIQUE DES PROFILS DES SEGMENTS
# ------------------------------------------------------------

p_profiles <- ggplot2::ggplot(
  profile_long,
  ggplot2::aes(
    x = Variable,
    y = Segment,
    fill = Valeur_standardisee
  )
) +

  ggplot2::geom_tile(
    color = "white"
  ) +

  ggplot2::scale_fill_gradient2(
    low = "#2878B5",
    mid = "white",
    high = "#C44E52",
    midpoint = 0
  ) +

  ggplot2::labs(
    title = "Profil médian des segments",
    subtitle = paste(
      "Médianes exprimées en écarts-types",
      "par rapport à la population complète"
    ),
    x = NULL,
    y = "Segment",
    fill = "Écart standardisé"
  ) +

  ggplot2::theme_minimal() +

  ggplot2::theme(
    axis.text.x = ggplot2::element_text(
      angle = 45,
      hjust = 1
    )
  )

ggplot2::ggsave(
  file.path(
    figures_dir,
    "05_profils_segments.png"
  ),
  p_profiles,
  width = 12,
  height = max(
    5,
    best_k * 0.7
  ),
  dpi = 160
)


# ------------------------------------------------------------
# 29. RESUME FINAL
# ------------------------------------------------------------

cat("\n")
cat("============================================\n")
cat(" ACP ET SEGMENTATION TERMINEES\n")
cat("============================================\n")

cat(
  "Clients analysés :",
  nrow(data),
  "\n"
)

cat(
  "Variables utilisées :",
  length(segmentation_features),
  "\n"
)

cat(
  "Valeurs manquantes imputées :",
  sum(missing_counts),
  "\n"
)

cat(
  "Composantes principales retenues :",
  n_components,
  "\n"
)

cat(
  "Variance cumulée expliquée :",
  round(
    cumulative_variance[n_components] * 100,
    2
  ),
  "%\n"
)

cat(
  "Nombre de segments retenu :",
  best_k,
  "\n"
)

cat(
  "Silhouette CAH Ward.D2 :",
  round(method_comparison$Silhouette_moyenne[[2]], 3),
  "| ARI vs K-means :",
  round(method_comparison$ARI_vs_Kmeans[[2]], 3),
  "\n"
)

cat(
  "Silhouette moyenne :",
  round(
    silhouette_scores$Silhouette_moyenne[[best_index]],
    3
  ),
  "\n"
)

cat(
  "ARI moyen sur",
  stability_runs,
  "initialisations :",
  round(stability_summary$ARI_moyen[[1]], 3),
  "\n"
)

cat(
  "ARI minimum :",
  round(stability_summary$ARI_minimum[[1]], 3),
  "| Partitions identiques :",
  round(stability_summary$Partitions_identiques_pct[[1]], 1),
  "%\n"
)

cat(
  "ARI moyen sur les sous-échantillons :",
  round(subsample_stability_summary$ARI_moyen[[1]], 3),
  "| Minimum :",
  round(subsample_stability_summary$ARI_minimum[[1]], 3),
  "\n"
)

cat(
  "Validation holdout — K :",
  validation_best_k,
  "| Silhouette entraînement/test :",
  round(validation_summary$Silhouette_moyenne[[1]], 3),
  "/",
  round(validation_summary$Silhouette_moyenne[[2]], 3),
  "\n"
)

cat(
  "Clients proches de la frontière (silhouette <= 0,10) :",
  boundary_summary$Nombre_clients_proches_frontiere[[1]],
  "| Silhouettes négatives :",
  boundary_summary$Nombre_silhouettes_negatives[[1]],
  "\n"
)

cat("\n")
cat("Dossier des figures :", figures_dir, "\n")
cat("Dossier des rapports :", reports_dir, "\n")

cat("\n")
cat("============================================\n")