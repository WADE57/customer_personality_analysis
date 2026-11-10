
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
# 7. Exporter les résultats, graphiques et rapports.
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

cap_features <- c(
  "Age_Client",
  log_features
)


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


# ------------------------------------------------------------
# 20. DIAGNOSTIC DETAILLE DES SILHOUETTES
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
        Silhouette_mediane = median(values),
        Pourcentage_silhouettes_negatives =
          mean(values < 0) * 100
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


# ------------------------------------------------------------
# 21. GRAPHIQUE DE SELECTION DES CLUSTERS
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
          data[
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

    values <- data$Education[
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

      values <- data$Marital_Status[
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
# 29. GENERATION DU RAPPORT MARKDOWN
# ------------------------------------------------------------

contributions_report <- contributions
contributions_report[-1] <- lapply(
  contributions_report[-1],
  round,
  digits = 3
)

report_lines <- c(

  "# ACP et segmentation des clients",

  "",

  "## 1. Présentation de la méthode",

  "",

  paste0(
    "- Nombre de clients analysés : **",
    nrow(data),
    "**."
  ),

  paste0(
    "- Nombre de variables numériques utilisées : **",
    length(segmentation_features),
    "**."
  ),

  paste0(
    "- Revenus manquants imputés par la médiane : **",
    sum(missing_counts),
    "** valeur(s)."
  ),

  paste0(
    "- Les valeurs d'âge, de revenu et de dépenses sont ",
    "limitées aux percentiles 1 et 99 pour l'analyse."
  ),

  paste0(
    "- Une transformation `log1p` est appliquée au revenu ",
    "et aux six variables de dépenses."
  ),

  paste0(
    "- Les variables sont ensuite centrées-réduites."
  ),

  paste0(
    "- L'ACP conserve **",
    n_components,
    "** composantes principales."
  ),

  paste0(
    "- Variance cumulée expliquée : **",
    sprintf(
      "%.2f",
      cumulative_variance[n_components] * 100
    ),
    " %**."
  ),

  paste0(
    "- `ID`, `Response`, les variables catégorielles et ",
    "les variables dérivées redondantes ne sont pas utilisées ",
    "pour entraîner l'ACP ou K-means."
  ),

  "",

  "## 2. Résultats de la segmentation",

  "",

  paste0(
    "- Nombre de segments retenu : **",
    best_k,
    "**."
  ),

  paste0(
    "- Silhouette moyenne : **",
    sprintf(
      "%.3f",
      silhouette_scores$Silhouette_moyenne[[best_index]]
    ),
    "**."
  ),

  "",

  "| Segment | Nombre de clients | Pourcentage |",

  "|---|---:|---:|"
)


# Tableau des tailles

report_lines <- c(
  report_lines,

  vapply(
    seq_len(nrow(segment_sizes)),
    function(i) {

      paste0(
        "| ",
        segment_sizes$Segment[[i]],
        " | ",
        segment_sizes$Nombre_clients[[i]],
        " | ",
        sprintf(
          "%.2f",
          segment_sizes$Pourcentage[[i]]
        ),
        " |"
      )
    },
    character(1)
  ),

  "",

  "### Diagnostic des silhouettes",

  "",

  paste(
    capture.output(
      print(
        silhouette_diagnostic,
        row.names = FALSE
      )
    ),
    collapse = "\n"
  ),

  "",

  "## 3. Profils des segments",

  "",

  paste0(
    "Les profils sont calculés à partir des médianes ",
    "des variables originales. Le taux de réponse est ",
    "un indicateur descriptif postérieur à la segmentation."
  ),

  "",

  paste(
    capture.output(
      print(
        cluster_profiles,
        row.names = FALSE
      )
    ),
    collapse = "\n"
  ),

  "",

  "## 4. Contributions des variables à l'ACP",

  "",

  paste(
    capture.output(
      print(
        contributions_report,
        row.names = FALSE
      )
    ),
    collapse = "\n"
  ),

  "",

  "## 5. Limites d'interprétation",

  "",

  "- Les segments sont des profils exploratoires, pas des catégories naturelles garanties.",

  "- Une silhouette moyenne modérée indique que les groupes ne sont pas parfaitement séparés.",

  "- Le choix du nombre de clusters dépend des variables et de la méthode retenues.",

  "- Les valeurs extrêmes ont été plafonnées uniquement pour l'ACP et le clustering.",

  "- Les profils sont descriptifs et ne permettent pas d'établir des relations causales.",

  "- Les variables catégorielles n'ont pas participé à la construction des segments.",

  "",

  "## 6. Figures",

  "",

  "- `figures/segmentation/01_variance_acp.png`",

  "- `figures/segmentation/02_selection_clusters.png`",

  "- `figures/segmentation/03_diagnostic_silhouette.png`",

  "- `figures/segmentation/04_segments_plan_acp.png`",

  "- `figures/segmentation/05_profils_segments.png`",

  "",

  "## 7. Fichiers de résultats",

  "",

  "- `reports/segmentation/variance_acp.csv`",

  "- `reports/segmentation/contributions_variables_acp.csv`",

  "- `reports/segmentation/correlations_variables_composantes.csv`",

  "- `reports/segmentation/selection_nombre_clusters.csv`",

  "- `reports/segmentation/diagnostic_silhouette_segments.csv`",

  "- `reports/segmentation/tailles_segments.csv`",

  "- `reports/segmentation/profils_segments.csv`",

  "- `reports/segmentation/affectation_clients_segments.csv`",

  ""
)


# ------------------------------------------------------------
# 30. EXPORT DU RAPPORT
# ------------------------------------------------------------

writeLines(
  report_lines,
  file.path(
    reports_dir,
    "pca_segmentation.md"
  ),
  useBytes = TRUE
)


# ------------------------------------------------------------
# 31. RESUME FINAL
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
  "Silhouette moyenne :",
  round(
    silhouette_scores$Silhouette_moyenne[[best_index]],
    3
  ),
  "\n"
)

cat("\n")
cat("Dossier des figures :", figures_dir, "\n")
cat("Dossier des rapports :", reports_dir, "\n")

cat("\n")
cat("============================================\n")