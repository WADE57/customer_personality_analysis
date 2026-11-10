---
title: "ACP et segmentation des clients"
author: "Customer Personality Analysis"
lang: fr
output:
  html_document:
    toc: true
    toc_float: true
    number_sections: true
    theme: readable
    keep_md: true
---



Ce rapport décrit les variables candidates à l’ACP, justifie le traitement
appliqué aux données, puis présente les segments obtenus. Les variables
`ID` et `Response` ne servent pas à construire les composantes ni les
segments. `Response` est uniquement décrite après segmentation.

## Préparation et diagnostic

Le diagnostic repère les valeurs manquantes et atypiques avant leur
prétraitement. Une valeur signalée par la règle IQR n’est pas nécessairement
une erreur ; elle n’est pas supprimée par ce diagnostic.




Table: Valeurs atypiques détectées par la règle IQR

|Variable            | Borne_inferieure_IQR| Borne_superieure_IQR| Nombre_valeurs_atypiques| Pourcentage_valeurs_atypiques|
|:-------------------|--------------------:|--------------------:|------------------------:|-----------------------------:|
|Age_Client          |                 10.0|                 82.0|                        3|                          0.13|
|Income              |             -14525.5|             118350.5|                        8|                          0.36|
|Kidhome             |                 -1.5|                  2.5|                        0|                          0.00|
|Teenhome            |                 -1.5|                  2.5|                        0|                          0.00|
|Recency             |                -51.0|                149.0|                        0|                          0.00|
|MntWines            |               -697.0|               1225.0|                       35|                          1.56|
|MntFruits           |                -47.0|                 81.0|                      227|                         10.13|
|MntMeatProducts     |               -308.0|                556.0|                      175|                          7.81|
|MntFishProducts     |                -67.5|                120.5|                      223|                          9.96|
|MntSweetProducts    |                -47.0|                 81.0|                      248|                         11.07|
|MntGoldProds        |                -61.5|                126.5|                      207|                          9.24|
|NumDealsPurchases   |                 -2.0|                  6.0|                       86|                          3.84|
|NumWebPurchases     |                 -4.0|                 12.0|                        4|                          0.18|
|NumCatalogPurchases |                 -6.0|                 10.0|                       23|                          1.03|
|NumStorePurchases   |                 -4.5|                 15.5|                        0|                          0.00|
|NumWebVisitsMonth   |                 -3.0|                 13.0|                        8|                          0.36|

Les âges supérieurs à 90 ans et le revenu égal à 666666 sont traités comme
manquants dans les variables d’analyse. Les valeurs manquantes sont imputées
par la médiane. Seules les six variables de dépenses sont plafonnées aux
percentiles 1 et 99 ; le revenu et les dépenses sont ensuite transformés avec
`log1p`. Toutes les variables utilisées sont centrées-réduites. Ces
opérations s’appliquent aux analyses, sans modifier le CSV préparé.

## Analyse en composantes principales

Le nombre de composantes retenu permet d’expliquer au moins 80 % de la
variance, dans la limite de dix composantes.




Table: Variance expliquée par les premières composantes

|Composante | Valeur_propre| Variance_expliquee_pct| Variance_cumulee_pct|
|:----------|-------------:|----------------------:|--------------------:|
|PC1        |          6.91|                  43.18|                43.18|
|PC2        |          1.98|                  12.39|                55.58|
|PC3        |          1.37|                   8.54|                64.11|
|PC4        |          1.01|                   6.28|                70.40|
|PC5        |          0.75|                   4.66|                75.06|
|PC6        |          0.68|                   4.27|                79.33|
|PC7        |          0.56|                   3.49|                82.81|
|PC8        |          0.51|                   3.18|                86.00|
|PC9        |          0.47|                   2.93|                88.92|
|PC10       |          0.39|                   2.44|                91.36|

Les variables suivantes ont une corrélation absolue d'au moins 0,30 avec
chaque composante retenue (trois variables au maximum). Le signe indique le
sens de l'association, sans établir de causalité.


Table: Variables les plus associées à chaque composante

|Composante | Variance_expliquee_pct|Variable          | Correlation|
|:----------|----------------------:|:-----------------|-----------:|
|PC1        |                 43.184|MntMeatProducts   |      -0.928|
|PC1        |                 43.184|MntWines          |      -0.854|
|PC1        |                 43.184|NumStorePurchases |      -0.790|
|PC2        |                 12.395|Teenhome          |       0.800|
|PC2        |                 12.395|NumDealsPurchases |       0.688|
|PC2        |                 12.395|Age_Client        |       0.483|
|PC3        |                  8.537|Age_Client        |       0.553|
|PC3        |                  8.537|NumDealsPurchases |      -0.505|
|PC3        |                  8.537|NumWebVisitsMonth |      -0.478|
|PC4        |                  6.281|Recency           |       0.995|
|PC5        |                  4.660|Age_Client        |       0.481|
|PC5        |                  4.660|Income            |      -0.341|
|PC6        |                  4.269|NumWebPurchases   |      -0.394|
|PC6        |                  4.269|NumDealsPurchases |       0.360|
|PC6        |                  4.269|Kidhome           |       0.340|
|PC7        |                  3.486|Teenhome          |      -0.457|
|PC7        |                  3.486|Age_Client        |       0.325|

![Variance individuelle et cumulée des composantes principales.](../figures/segmentation/01_variance_acp.png)

## Segmentation

Le nombre de segments est choisi en comparant la silhouette moyenne pour
plusieurs valeurs de `K`. La silhouette aide à comparer les partitions,
mais ne garantit pas à elle seule que les segments soient utiles au métier.


Table: Silhouette moyenne selon le nombre de segments

|  K| Silhouette_moyenne|
|--:|------------------:|
|  2|              0.357|
|  3|              0.287|
|  4|              0.235|
|  5|              0.221|
|  6|              0.204|
|  7|              0.196|
|  8|              0.192|

![Comparaison de la silhouette moyenne pour choisir le nombre de segments.](../figures/segmentation/02_selection_clusters.png)

### Comparaison avec la classification ascendante hiérarchique

K-means et la CAH utilisent ici les mêmes clients, les mêmes composantes ACP
et la distance euclidienne. La CAH utilise le critère `Ward.D2`, puis son
arbre est coupé au même nombre de groupes que K-means. La silhouette compare
la cohésion et la séparation ; l'ARI compare la concordance des affectations
sans dépendre de la numérotation des groupes.


Table: Comparaison des méthodes sur les mêmes données et avec le même K

|Methode       | Nombre_de_groupes|Distance    | Silhouette_moyenne| Taille_minimale| Taille_maximale| ARI_vs_Kmeans|
|:-------------|-----------------:|:-----------|------------------:|---------------:|---------------:|-------------:|
|K-means       |                 2|Euclidienne |              0.357|            1119|            1121|         1.000|
|CAH - Ward.D2 |                 2|Euclidienne |              0.309|             766|            1474|         0.469|

![Comparaison des silhouettes moyennes de K-means et de Ward.D2.](../figures/segmentation/07_comparaison_silhouette_kmeans_cah.png)

![K-means projeté sur PC1-PC2 ; les croix noires indiquent les centroïdes projetés et le titre donne la silhouette moyenne calculée sur toutes les composantes retenues.](../figures/segmentation/09_kmeans_centroides_silhouette.png)

La silhouette moyenne est de
0.357
pour K-means et de
0.309
pour Ward.D2. L'ARI entre les partitions est de
0.469 ;
il décrit leur concordance, pas la qualité absolue d'une méthode.
Les numéros de groupes sont propres à chaque méthode ; les profils et les
affectations doivent être comparés, sans supposer que le groupe 1 correspond
au groupe 1 dans les deux partitions.


Table: Tailles et proportions des groupes selon la méthode

|Methode       | Segment| Nombre_clients| Pourcentage|
|:-------------|-------:|--------------:|-----------:|
|K-means       |       1|           1121|       50.04|
|K-means       |       2|           1119|       49.96|
|CAH - Ward.D2 |       1|            766|       34.20|
|CAH - Ward.D2 |       2|           1474|       65.80|


Table: Profils médians par groupe et par méthode

|Methode       | Segment| Nombre_clients| Age_Client| Income| Kidhome| Teenhome| Recency| MntWines| MntFruits| MntMeatProducts| MntFishProducts| MntSweetProducts| MntGoldProds| NumDealsPurchases| NumWebPurchases| NumCatalogPurchases| NumStorePurchases| NumWebVisitsMonth| Taux_reponse_pct|
|:-------------|-------:|--------------:|----------:|------:|-------:|--------:|-------:|--------:|---------:|---------------:|---------------:|----------------:|------------:|-----------------:|---------------:|-------------------:|-----------------:|-----------------:|----------------:|
|K-means       |       1|           1121|         42|  35765|       1|        0|      49|     24.0|         2|              16|               3|                2|           10|                 2|               2|                   0|                 3|                 7|            10.62|
|K-means       |       2|           1119|         47|  68211|       0|        0|      50|    491.0|        32|             231|              50|               33|           53|                 1|               5|                   4|                 8|                 4|            19.21|
|CAH - Ward.D2 |       1|            766|         45|  72661|       0|        0|      50|    531.5|        47|             348|              72|               48|           54|                 1|               5|                   5|                 9|                 3|            23.24|
|CAH - Ward.D2 |       2|           1474|         43|  39898|       1|        1|      49|     43.0|         3|              23|               4|                3|           14|                 2|               3|                   1|                 4|                 7|            10.58|

![Projections des affectations K-means et Ward.D2 dans le plan des deux premières composantes.](../figures/segmentation/06_comparaison_partitions_kmeans_cah.png)

Le graphique des affectations montre aussi les centroïdes de K-means par une
croix noire. Ils ne sont pas affichés pour la CAH, qui est une méthode
hiérarchique sans centroïdes.

![Dendrogramme de Ward.D2 coupé au nombre de groupes retenu ; les étiquettes des clients sont masquées pour préserver la lisibilité.](../figures/segmentation/08_dendrogramme_cah_ward.png)

La CAH et la matrice des distances ont un coût mémoire et calcul de l'ordre
de `O(n²)`. Ce coût reste praticable pour les 2 240 clients étudiés, mais
augmente rapidement sur des jeux de données beaucoup plus grands.

![Distribution des largeurs de silhouette dans la partition retenue.](../figures/segmentation/03_diagnostic_silhouette.png)

Le tableau ci-dessous décrit les silhouettes individuelles par segment :
quantiles, médiane et proportions de valeurs négatives ou proches de zéro.
Une silhouette négative signale une affectation à examiner, sans constituer
à elle seule la preuve d'une erreur de segmentation.


Table: Distribution des silhouettes individuelles par segment

| Segment| Nombre_clients| Silhouette_moyenne| Silhouette_q05| Silhouette_q25| Silhouette_mediane| Silhouette_q75| Silhouette_q95| Pourcentage_silhouettes_negatives| Pourcentage_silhouettes_entre_0_et_0_10|
|-------:|--------------:|------------------:|--------------:|--------------:|------------------:|--------------:|--------------:|---------------------------------:|---------------------------------------:|
|       1|           1121|              0.368|          0.061|          0.284|              0.419|          0.479|          0.521|                             0.000|                                   8.475|
|       2|           1119|              0.347|          0.051|          0.258|              0.402|          0.455|          0.498|                             0.894|                                   7.954|

![Silhouettes de chaque client, triées dans chaque segment. La ligne rouge marque zéro et la ligne orange le seuil exploratoire de 0,10.](../figures/segmentation/10_silhouettes_individuelles.png)

Les valeurs individuelles avec l'identifiant du client, son segment et son
segment voisin sont disponibles dans
`reports/segmentation/silhouettes_individuelles.csv`. La liste des clients
dont la silhouette est inférieure ou égale à 0,10 est également exportée
avec leurs caractéristiques dans `clients_proches_frontiere.csv`.

### Stabilité selon les initialisations de K-means

La partition retenue est comparée à 100 exécutions de K-means avec une
initialisation chacune. L'indice de Rand ajusté (ARI) est invariant à la
permutation des étiquettes : 1 correspond à des partitions identiques.


Table: Stabilité de la partition selon les initialisations

| Nombre_initialisations| Graine| ARI_moyen| ARI_ecart_type| ARI_minimum| ARI_quantile_05| ARI_maximum| Partitions_identiques_pct|
|----------------------:|------:|---------:|--------------:|-----------:|---------------:|-----------:|-------------------------:|
|                    100|   2027|     0.992|          0.008|       0.984|           0.984|           1|                        51|

Cette analyse mesure la sensibilité à l'initialisation sur les données et les
variables actuelles ; elle ne mesure pas la stabilité sur de nouveaux
échantillons.

### Stabilité par sous-échantillonnage

K-means est réajusté sur 100 sous-échantillons sans remise contenant 80 % des
clients, avec 50 initialisations par ajustement. Chaque modèle est utilisé
pour affecter tous les clients au centroïde le plus proche ; ces affectations
sont comparées à la partition de référence par ARI.


Table: Stabilité de K-means après sous-échantillonnage des clients

| Nombre_repetitions| Fraction_clients_pct| Taille_sous_echantillon| Initialisations_kmeans_par_repetition| Graine| ARI_moyen| ARI_ecart_type| ARI_minimum| ARI_quantile_05| ARI_maximum|
|------------------:|--------------------:|-----------------------:|-------------------------------------:|------:|---------:|--------------:|-----------:|---------------:|-----------:|
|                100|                   80|                    1792|                                    50|   2028|     0.979|          0.018|       0.928|           0.935|           1|

Cette analyse conserve fixes le prétraitement et l'ACP calculés sur l'ensemble
des clients. Elle évalue donc la sensibilité de K-means à la composition de
l'échantillon dans cet espace ACP, et non la stabilité de toute la chaîne de
traitement ou sa généralisation à une nouvelle population.

### Validation sur un échantillon mis de côté

Une validation complémentaire réserve 20 % des clients avant le
prétraitement. Les médianes d'imputation, seuils de plafonnement,
paramètres de standardisation, ACP, nombre de groupes et centroïdes sont
estimés uniquement sur les 80 % d'entraînement. Le test est transformé avec
ces paramètres, puis affecté aux centroïdes appris sans réajuster le modèle.


Table: Silhouette sur l'entraînement et le test mis de côté

|Echantillon      | Nombre_clients| Pourcentage_clients| Nombre_composantes| Variance_cumulee_pct| K_retenu| Silhouette_moyenne| Graine_decoupage|
|:----------------|--------------:|-------------------:|------------------:|--------------------:|--------:|------------------:|----------------:|
|Entrainement     |           1792|                  80|                  6|               80.025|        2|              0.372|             2029|
|Test mis de cote |            448|                  20|                  6|               80.025|        2|              0.377|             2029|



Table: Profils observés dans le test, par centroïde appris sur l'entraînement

| Segment_entraine| Nombre_clients| Age_Client| Income| Kidhome| Teenhome| Recency| MntWines| MntFruits| MntMeatProducts| MntFishProducts| MntSweetProducts| MntGoldProds| NumDealsPurchases| NumWebPurchases| NumCatalogPurchases| NumStorePurchases| NumWebVisitsMonth| Taux_reponse_pct|
|----------------:|--------------:|----------:|------:|-------:|--------:|-------:|--------:|---------:|---------------:|---------------:|----------------:|------------:|-----------------:|---------------:|-------------------:|-----------------:|-----------------:|----------------:|
|                1|            219|         48|  69424|       0|        0|      47|      492|        32|             239|              50|               36|           47|                 1|               5|                   4|                 8|                 4|            17.81|
|                2|            229|         42|  35544|       1|        1|      47|       27|         3|              16|               3|                2|           12|                 2|               2|                   1|                 3|                 7|            11.35|

Le test est une partie mise de côté du même jeu de données : il évalue la
reproductibilité sur des clients non utilisés pour ajuster ce modèle, mais
ne remplace pas une validation externe sur une autre période ou population.
Les affectations individuelles du test sont exportées dans
`affectations_test_independant.csv`.

La silhouette de validation est calculée à partir des distances entre les
clients du test uniquement, avec leurs affectations fixées par les centroïdes
appris sur l'entraînement. Elle ne représente donc pas une distance entre
chaque client du test et l'ensemble des clients d'entraînement.

### Clients proches de la frontière

Une silhouette inférieure ou égale à 0,10 sert ici de seuil exploratoire
pour repérer les affectations proches de la frontière ; ce seuil n'est pas
une règle universelle. Les silhouettes négatives indiquent que les clients
sont, selon cette mesure, plus proches d'un autre groupe. Les chiffres de
cette section et la figure des silhouettes individuelles concernent la
segmentation initiale de l'ensemble des clients, et non le sous-échantillon
de test de la validation 80/20.


Table: Résumé des silhouettes proches de zéro ou négatives

| Seuil_silhouette| Nombre_clients_proches_frontiere| Pourcentage_clients_proches_frontiere| Nombre_silhouettes_negatives| Pourcentage_silhouettes_negatives|
|----------------:|--------------------------------:|-------------------------------------:|----------------------------:|---------------------------------:|
|              0.1|                              194|                                  8.66|                           10|                              0.45|



Table: Jusqu'à 20 clients les plus proches de la frontière ; liste complète dans le CSV

|   ID| Segment| Segment_voisin| Silhouette| Income| MntWines| MntMeatProducts| NumWebPurchases| NumStorePurchases| Response|
|----:|-------:|--------------:|----------:|------:|--------:|---------------:|---------------:|-----------------:|--------:|
| 2853|       2|              1|     -0.019|  51766|       60|              87|               4|                 4|        0|
|  983|       2|              1|     -0.017|  40059|      110|              92|               6|                 3|        0|
| 7930|       2|              1|     -0.014|  26877|      101|              76|               3|                 6|        0|
| 9246|       2|              1|     -0.013|  40101|      171|             129|               6|                 6|        0|
| 8070|       2|              1|     -0.010|  54222|      199|              31|               3|                 5|        0|
| 4426|       2|              1|     -0.007|  55801|      367|              51|               7|                 6|        0|
| 2961|       2|              1|     -0.007|  42081|      175|             110|               6|                 4|        0|
| 8132|       2|              1|     -0.004|  60631|      565|              65|               9|                 8|        0|
| 4324|       2|              1|     -0.004|  42387|      235|             235|               8|                 7|        0|
| 3083|       2|              1|     -0.004|  45837|      215|              87|               6|                 5|        0|
| 2948|       2|              1|      0.004|  62637|      104|              48|               2|                 5|        0|
| 3427|       2|              1|      0.004|  59821|      629|              70|              11|                 7|        0|
| 5552|       2|              1|      0.005|  48721|       81|             113|               4|                 5|        0|
| 9360|       2|              1|      0.006|  37040|       86|              73|               4|                 5|        0|
| 7108|       2|              1|      0.006|  51390|      205|              47|               5|                 5|        0|
| 3117|       1|              2|      0.007|     NA|      264|              21|               6|                 5|        0|
| 4271|       2|              1|      0.008|  38683|       46|              69|               4|                 6|        0|
|  635|       1|              2|      0.010|  57183|      464|              64|               9|                 7|        0|
| 9970|       2|              1|      0.011|  55375|       42|              57|               1|                 6|        0|
|  246|       2|              1|      0.012|  66480|      199|              57|               4|                 7|        0|

Dans cette partition, **194
clients (8.66 %)
ont une silhouette inférieure ou égale à 0,10**, et
**10
(0.45 %)
ont une silhouette négative**. Ces derniers sont à examiner en priorité.
Le seuil de 0,10 est exploratoire : il aide à sélectionner des cas, mais ne
constitue pas une frontière statistique universelle.

![Clients représentés sur les deux premières composantes, colorés par segment.](../figures/segmentation/04_segments_plan_acp.png)


Table: Taille des segments

| Segment| Nombre_clients| Pourcentage|
|-------:|--------------:|-----------:|
|       1|           1121|          50|
|       2|           1119|          50|

![Profil relatif des variables dans chaque segment.](../figures/segmentation/05_profils_segments.png)


Table: Profils médians sur les variables d'origine et taux de réponse observé

| Segment| Nombre_clients| Age_Client| Income| Kidhome| Teenhome| Recency| MntWines| MntFruits| MntMeatProducts| MntFishProducts| MntSweetProducts| MntGoldProds| NumDealsPurchases| NumWebPurchases| NumCatalogPurchases| NumStorePurchases| NumWebVisitsMonth| Taux_reponse_pct|Education_majoritaire |Statut_matrimonial_majoritaire |
|-------:|--------------:|----------:|------:|-------:|--------:|-------:|--------:|---------:|---------------:|---------------:|----------------:|------------:|-----------------:|---------------:|-------------------:|-----------------:|-----------------:|----------------:|:---------------------|:------------------------------|
|       1|           1121|         42|  35765|       1|        0|      49|       24|         2|              16|               3|                2|           10|                 2|               2|                   0|                 3|                 7|            10.62|Graduation            |Married                        |
|       2|           1119|         47|  68211|       0|        0|      50|      491|        32|             231|              50|               33|           53|                 1|               5|                   4|                 8|                 4|            19.21|Graduation            |Married                        |

## Distributions et comparaison descriptive des segments

Les descriptifs neutralisent, sans modifier les données originales, les âges
supérieurs à 90 ans et le revenu égal à 666666. Les variables numériques sont
résumées par segment avec moyenne, écart-type, médiane, quartiles et
pourcentage de zéros. Les boîtes à moustaches et les fonctions de répartition
empirique complètent les médianes afin de montrer la dispersion et
l'asymétrie.


Table: Statistiques descriptives des variables quantitatives par segment

|Variable            | Segment| Nombre_clients| Nombre_observe| Nombre_manquant|  Moyenne| Ecart_type| Mediane|       Q1|       Q3|     IQR| Pourcentage_zero|
|:-------------------|-------:|--------------:|--------------:|---------------:|--------:|----------:|-------:|--------:|--------:|-------:|----------------:|
|Age_Client          |       1|           1121|           1119|               2|    43.15|      10.95|      42|    36.00|    51.00|    15.0|             0.00|
|Age_Client          |       2|           1119|           1118|               1|    47.04|      12.10|      47|    38.00|    57.00|    19.0|             0.00|
|Income              |       1|           1121|           1105|              16| 36057.26|   14691.38|   35765| 26576.00| 44551.00| 17975.0|             0.00|
|Income              |       2|           1119|           1110|               9| 67810.78|   14379.54|   68211| 58737.75| 77594.25| 18856.5|             0.00|
|Kidhome             |       1|           1121|           1121|               0|     0.77|       0.51|       1|     0.00|     1.00|     1.0|            26.85|
|Kidhome             |       2|           1119|           1119|               0|     0.12|       0.33|       0|     0.00|     0.00|     0.0|            88.65|
|Teenhome            |       1|           1121|           1121|               0|     0.51|       0.54|       0|     0.00|     1.00|     1.0|            51.12|
|Teenhome            |       2|           1119|           1119|               0|     0.50|       0.55|       0|     0.00|     1.00|     1.0|            52.28|
|Recency             |       1|           1121|           1121|               0|    48.84|      29.06|      49|    24.00|    75.00|    51.0|             1.34|
|Recency             |       2|           1119|           1119|               0|    49.38|      28.87|      50|    25.00|    73.00|    48.0|             1.16|
|MntWines            |       1|           1121|           1121|               0|    72.03|     131.90|      24|     9.00|    73.00|    64.0|             1.16|
|MntWines            |       2|           1119|           1119|               0|   536.25|     318.64|     491|   284.00|   742.50|   458.5|             0.00|
|MntFruits           |       1|           1121|           1121|               0|     4.31|       6.52|       2|     0.00|     6.00|     6.0|            28.10|
|MntFruits           |       2|           1119|           1119|               0|    48.33|      46.42|      32|    14.00|    71.00|    57.0|             7.60|
|MntMeatProducts     |       1|           1121|           1121|               0|    27.80|      74.01|      16|     8.00|    30.00|    22.0|             0.09|
|MntMeatProducts     |       2|           1119|           1119|               0|   306.35|     240.17|     231|   119.00|   430.50|   311.5|             0.00|
|MntFishProducts     |       1|           1121|           1121|               0|     5.88|       7.63|       3|     0.00|     8.00|     8.0|            27.56|
|MntFishProducts     |       2|           1119|           1119|               0|    69.23|      62.51|      50|    20.00|   103.00|    83.0|             6.70|
|MntSweetProducts    |       1|           1121|           1121|               0|     4.27|       6.06|       2|     0.00|     6.00|     6.0|            29.08|
|MntSweetProducts    |       2|           1119|           1119|               0|    49.90|      48.30|      33|    13.00|    74.00|    61.0|             8.31|
|MntGoldProds        |       1|           1121|           1121|               0|    16.64|      22.53|      10|     4.00|    21.00|    17.0|             3.48|
|MntGoldProds        |       2|           1119|           1119|               0|    71.45|      58.63|      53|    28.00|   102.00|    74.0|             1.97|
|NumDealsPurchases   |       1|           1121|           1121|               0|     2.33|       1.75|       2|     1.00|     3.00|     2.0|             0.98|
|NumDealsPurchases   |       2|           1119|           1119|               0|     2.32|       2.10|       1|     1.00|     3.00|     2.0|             3.13|
|NumWebPurchases     |       1|           1121|           1121|               0|     2.46|       1.89|       2|     1.00|     3.00|     2.0|             4.10|
|NumWebPurchases     |       2|           1119|           1119|               0|     5.71|       2.57|       5|     4.00|     7.00|     3.0|             0.27|
|NumCatalogPurchases |       1|           1121|           1121|               0|     0.66|       1.17|       0|     0.00|     1.00|     1.0|            52.10|
|NumCatalogPurchases |       2|           1119|           1119|               0|     4.67|       2.78|       4|     3.00|     6.00|     3.0|             0.18|
|NumStorePurchases   |       1|           1121|           1121|               0|     3.40|       1.36|       3|     3.00|     4.00|     1.0|             0.98|
|NumStorePurchases   |       2|           1119|           1119|               0|     8.19|       2.80|       8|     6.00|    10.00|     4.0|             0.36|
|NumWebVisitsMonth   |       1|           1121|           1121|               0|     6.57|       1.91|       7|     6.00|     8.00|     2.0|             0.27|
|NumWebVisitsMonth   |       2|           1119|           1119|               0|     4.06|       2.24|       4|     2.00|     6.00|     4.0|             0.71|

![Boîtes à moustaches par segment ; les échelles verticales sont propres à chaque variable.](../figures/segmentation/11_distributions_quantitatives_segments.png)

![Fonctions de répartition empirique des variables quantitatives par segment.](../figures/segmentation/12_distributions_cumulees_segments.png)

Pour les variables quantitatives, le test de Wilcoxon-Mann-Whitney compare
les rangs des deux groupes et le delta de rangs de Cliff donne une mesure
d'effet. Pour la réponse, le niveau d'éducation et le statut matrimonial,
les distributions sont comparées par chi-deux ; une p-value simulée est
utilisée si les effectifs théoriques sont faibles. Les p-values sont
corrigées par la méthode de Holm sur l'ensemble des comparaisons.
Les tailles d'effet numériques sont orientées « segment 1 versus segment 2 » :
un delta négatif indique des valeurs généralement plus élevées dans le
segment 2. Les p-values plus petites que la précision numérique disponible
sont enregistrées à la limite machine et ne doivent pas être interprétées
comme exactement nulles.

Ces tests restent exploratoires et descriptifs : les variables quantitatives
ont participé à la construction de K-means, de sorte que leurs écarts ne
constituent pas une validation indépendante des segments. Les p-values ne
démontrent ni causalité ni utilité marketing.


Table: Comparaisons exploratoires entre segments et tailles d'effet

|Variable            |Type         |Test                                 | N_segment_1| N_segment_2| Mediane_segment_1| Mediane_segment_2| Difference_medianes|  Statistique| Taille_effet|Mesure_taille_effet             |P_value |P_value_Holm |
|:-------------------|:------------|:------------------------------------|-----------:|-----------:|-----------------:|-----------------:|-------------------:|------------:|------------:|:-------------------------------|:-------|:------------|
|Kidhome             |Quantitative |Wilcoxon-Mann-Whitney                |        1121|        1119|                 1|                 0|                   1| 1016433.5000|       0.6206|Delta de Cliff (segment 1 vs 2) |< 1e-04 |<1e-04       |
|MntMeatProducts     |Quantitative |Wilcoxon-Mann-Whitney                |        1121|        1119|                16|               231|                -215|   28844.0000|      -0.9540|Delta de Cliff (segment 1 vs 2) |< 1e-04 |<1e-04       |
|NumCatalogPurchases |Quantitative |Wilcoxon-Mann-Whitney                |        1121|        1119|                 0|                 4|                  -4|   51155.5000|      -0.9184|Delta de Cliff (segment 1 vs 2) |< 1e-04 |<1e-04       |
|NumWebVisitsMonth   |Quantitative |Wilcoxon-Mann-Whitney                |        1121|        1119|                 7|                 4|                   3| 1001445.5000|       0.5967|Delta de Cliff (segment 1 vs 2) |< 1e-04 |<1e-04       |
|MntWines            |Quantitative |Wilcoxon-Mann-Whitney                |        1121|        1119|                24|               491|                -467|   60819.0000|      -0.9030|Delta de Cliff (segment 1 vs 2) |< 1e-04 |<1e-04       |
|NumStorePurchases   |Quantitative |Wilcoxon-Mann-Whitney                |        1121|        1119|                 3|                 8|                  -5|   65963.5000|      -0.8948|Delta de Cliff (segment 1 vs 2) |< 1e-04 |<1e-04       |
|Income              |Quantitative |Wilcoxon-Mann-Whitney                |        1105|        1110|             35765|             68211|              -32446|   61077.5000|      -0.9004|Delta de Cliff (segment 1 vs 2) |< 1e-04 |<1e-04       |
|MntFishProducts     |Quantitative |Wilcoxon-Mann-Whitney                |        1121|        1119|                 3|                50|                 -47|  120726.5000|      -0.8075|Delta de Cliff (segment 1 vs 2) |< 1e-04 |<1e-04       |
|MntFruits           |Quantitative |Wilcoxon-Mann-Whitney                |        1121|        1119|                 2|                32|                 -30|  133369.0000|      -0.7874|Delta de Cliff (segment 1 vs 2) |< 1e-04 |<1e-04       |
|MntSweetProducts    |Quantitative |Wilcoxon-Mann-Whitney                |        1121|        1119|                 2|                33|                 -31|  139801.5000|      -0.7771|Delta de Cliff (segment 1 vs 2) |< 1e-04 |<1e-04       |
|NumWebPurchases     |Quantitative |Wilcoxon-Mann-Whitney                |        1121|        1119|                 2|                 5|                  -3|  159808.5000|      -0.7452|Delta de Cliff (segment 1 vs 2) |< 1e-04 |<1e-04       |
|MntGoldProds        |Quantitative |Wilcoxon-Mann-Whitney                |        1121|        1119|                10|                53|                 -43|  173246.0000|      -0.7238|Delta de Cliff (segment 1 vs 2) |< 1e-04 |<1e-04       |
|Age_Client          |Quantitative |Wilcoxon-Mann-Whitney                |        1119|        1118|                42|                47|                  -5|  503874.5000|      -0.1945|Delta de Cliff (segment 1 vs 2) |< 1e-04 |<1e-04       |
|Education           |Categorielle |Chi-deux de Pearson                  |        1121|        1119|                NA|                NA|                  NA|      54.5271|       0.1560|V de Cramer                     |< 1e-04 |<1e-04       |
|Response            |Categorielle |Chi-deux de Pearson                  |        1121|        1119|                NA|                NA|                  NA|      32.6299|       0.1207|V de Cramer                     |< 1e-04 |<1e-04       |
|NumDealsPurchases   |Quantitative |Wilcoxon-Mann-Whitney                |        1121|        1119|                 2|                 1|                   1|  672302.5000|       0.0719|Delta de Cliff (segment 1 vs 2) |0.00195 |0.0078       |
|Marital_Status      |Categorielle |Chi-deux simule (10 000 repetitions) |        1121|        1119|                NA|                NA|                  NA|      13.5833|       0.0779|V de Cramer                     |0.03900 |0.1170       |
|Teenhome            |Quantitative |Wilcoxon-Mann-Whitney                |        1121|        1119|                 0|                 0|                   0|  631611.5000|       0.0070|Delta de Cliff (segment 1 vs 2) |0.74168 |1.0000       |
|Recency             |Quantitative |Wilcoxon-Mann-Whitney                |        1121|        1119|                49|                50|                  -1|  620199.5000|      -0.0112|Delta de Cliff (segment 1 vs 2) |0.64742 |1.0000       |



Table: Effectifs et pourcentages des modalités par segment

|Variable       |Modalite   | Segment| Nombre_clients| Pourcentage_segment|
|:--------------|:----------|-------:|--------------:|-------------------:|
|Response       |0          |       1|           1002|               89.38|
|Response       |1          |       1|            119|               10.62|
|Response       |0          |       2|            904|               80.79|
|Response       |1          |       2|            215|               19.21|
|Education      |2n Cycle   |       1|            112|                9.99|
|Education      |Basic      |       1|             52|                4.64|
|Education      |Graduation |       1|            530|               47.28|
|Education      |Master     |       1|            195|               17.40|
|Education      |PhD        |       1|            232|               20.70|
|Education      |2n Cycle   |       2|             91|                8.13|
|Education      |Basic      |       2|              2|                0.18|
|Education      |Graduation |       2|            597|               53.35|
|Education      |Master     |       2|            175|               15.64|
|Education      |PhD        |       2|            254|               22.70|
|Marital_Status |Absurd     |       1|              0|                0.00|
|Marital_Status |Alone      |       1|              3|                0.27|
|Marital_Status |Divorced   |       1|            113|               10.08|
|Marital_Status |Married    |       1|            441|               39.34|
|Marital_Status |Single     |       1|            246|               21.94|
|Marital_Status |Together   |       1|            288|               25.69|
|Marital_Status |Widow      |       1|             28|                2.50|
|Marital_Status |YOLO       |       1|              2|                0.18|
|Marital_Status |Absurd     |       2|              2|                0.18|
|Marital_Status |Alone      |       2|              0|                0.00|
|Marital_Status |Divorced   |       2|            119|               10.63|
|Marital_Status |Married    |       2|            423|               37.80|
|Marital_Status |Single     |       2|            234|               20.91|
|Marital_Status |Together   |       2|            292|               26.09|
|Marital_Status |Widow      |       2|             49|                4.38|
|Marital_Status |YOLO       |       2|              0|                0.00|

Dans les données analysées, le segment 2 présente un revenu médian de
68 211 contre
35 765 pour le segment 1 ; les dépenses
médianes en vin sont respectivement de
491 et
24. Le segment 2 achète aussi plus
souvent en magasin (médianes :
8 contre
3), tandis que les visites
web mensuelles médianes sont
4 contre
7. La récence médiane est
proche (49 contre
50 jours). Le taux descriptif de
réponse à une campagne est de
10.62 % dans le segment 1 et
19.21 % dans le segment 2. Ces écarts
décrivent les groupes sur cet échantillon ; ils n'impliquent pas de causalité.

## Interprétation métier des segments

### Résultats statistiques observés

Le segment 1 comprend **1121
clients (50.04 %)**.
Sa dépense totale médiane est de **69**,
inférieure à la médiane globale de **396**.
Son revenu médian est de **35 765**.
Les médianes d'achats sont de **3** en magasin,
**2** sur le Web et
**0** par catalogue.
Le taux de réponse observé est de **10.62 %**.

Le segment 2 comprend **1119
clients (49.96 %)**.
Sa dépense totale médiane est de **1 034**,
au-dessus de la médiane globale de **396**.
Son revenu médian est de **68 211**.
Les médianes d'achats sont de **8** en magasin,
**5** sur le Web et
**4** par catalogue.
Le taux de réponse observé est de **19.21 %**.

### Lecture métier prudente

Dans les données étudiées, le segment 1 présente une intensité d'achat et
des dépenses plus faibles. Le segment 2 rassemble des clients aux dépenses,
revenus médians et fréquences d'achat observés plus élevés. Les différences
de taux de réponse sont descriptives et ne démontrent pas que l'appartenance
à un segment cause une réponse plus élevée. Il s'agit de profils observés,
pas d'une valeur vie client ni d'une prévision de comportement futur.

Le canal « Magasin » désigne le canal dont le **nombre médian d'achats**
est le plus élevé dans chaque segment. Cela ne signifie ni que ce canal
représente la majorité des dépenses, ni qu'il génère la majorité du chiffre
d'affaires.

### Recommandations à tester

- **Segment 1 :** expérimenter une offre de découverte, une promotion ciblée
  ou une action de vente croisée, avec plusieurs messages à comparer.
- **Segment 2 :** tester une action de fidélisation, une offre premium ou
  des produits complémentaires.
- Dans les deux cas, adapter le pilote au canal magasin, où la médiane du
  nombre d'achats est la plus élevée, sans en déduire une répartition des
  dépenses par canal.
- Mesurer les résultats à l'aide d'un groupe témoin et d'indicateurs définis
  à l'avance (conversion, chiffre d'affaires incrémental et rentabilité).

Ces actions sont des hypothèses opérationnelles. Leur efficacité doit être
mesurée par des campagnes contrôlées avant tout déploiement.

![Répartition de la réponse, de l'éducation et du statut matrimonial dans chaque segment.](../figures/segmentation/13_distributions_categorielles_segments.png)

## Recommandations marketing à tester

Les pistes ci-dessous sont générées à partir des dépenses totales médianes,
du canal d'achat médian le plus utilisé et du taux de réponse observé dans
chaque segment, comparés aux valeurs globales. Elles servent à formuler des
hypothèses de ciblage ; elles ne démontrent ni causalité ni efficacité future.


Table: Pistes marketing fondées sur les profils observés

| Segment| Depenses_totales_medianes| Depenses_totales_medianes_population|Niveau_depenses |Canal_achat_median_le_plus_utilise | Taux_reponse_pct| Taux_reponse_population_pct|Recommandation                                                                                                                                                                                                                                                                    |
|-------:|-------------------------:|------------------------------------:|:---------------|:----------------------------------|----------------:|---------------------------:|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|       1|                        69|                                  396|au-dessous      |Magasin                            |            10.62|                       14.91|Tester une offre de découverte ou de vente croisée. Adapter le test au canal où la médiane du nombre d'achats est la plus élevée : Magasin (cela ne mesure pas la part des dépenses par canal). Tester plusieurs messages ou incitations avant d'augmenter la pression marketing. |
|       2|                      1034|                                  396|au-dessus       |Magasin                            |            19.21|                       14.91|Tester une action de fidélisation ou une offre premium. Adapter le test au canal où la médiane du nombre d'achats est la plus élevée : Magasin (cela ne mesure pas la part des dépenses par canal). Prioriser un pilote de campagne sur ce segment.                               |

## Interprétation et limites

- Les segments sont des profils exploratoires, pas des catégories naturelles
  garanties ni des groupes causaux.
- Les données manquantes et valeurs extrêmes sont traitées uniquement pour
  l’ACP et le clustering ; les exports de profils utilisent les données
  d’origine.
- La réponse aux campagnes n’a pas influencé la création des segments. Son
  taux par groupe est descriptif et ne prouve pas une différence causale.
- Le choix final des segments doit aussi tenir compte de leur taille, de leur
  stabilité et de leur interprétabilité commerciale.
- Le diagnostic de stabilité compare les initialisations sur le même jeu de
  données ; il ne remplace pas une validation sur des échantillons distincts.
- Le sous-échantillonnage teste la sensibilité à la composition des clients,
  conditionnellement au prétraitement et à l'ACP déjà calculés sur l'ensemble.
