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

|Methode       | Segment| Nombre_clients| Age_Client|  Income| Kidhome| Teenhome| Recency| MntWines| MntFruits| MntMeatProducts| MntFishProducts| MntSweetProducts| MntGoldProds| NumDealsPurchases| NumWebPurchases| NumCatalogPurchases| NumStorePurchases| NumWebVisitsMonth| Taux_reponse_pct|
|:-------------|-------:|--------------:|----------:|-------:|-------:|--------:|-------:|--------:|---------:|---------------:|---------------:|----------------:|------------:|-----------------:|---------------:|-------------------:|-----------------:|-----------------:|----------------:|
|K-means       |       1|           1121|       42.0| 35776.5|       1|        0|      49|     24.0|         2|              16|               3|                2|           10|                 2|               2|                   0|                 3|                 7|            10.62|
|K-means       |       2|           1119|       47.0| 68211.0|       0|        0|      50|    491.0|        32|             231|              50|               33|           53|                 1|               5|                   4|                 8|                 4|            19.21|
|CAH - Ward.D2 |       1|            766|       45.5| 72661.0|       0|        0|      50|    531.5|        47|             348|              72|               48|           54|                 1|               5|                   5|                 9|                 3|            23.24|
|CAH - Ward.D2 |       2|           1474|       43.0| 39910.0|       1|        1|      49|     43.0|         3|              23|               4|                3|           14|                 2|               3|                   1|                 4|                 7|            10.58|

![Projections des affectations K-means et Ward.D2 dans le plan des deux premières composantes.](../figures/segmentation/06_comparaison_partitions_kmeans_cah.png)

Le graphique des affectations montre aussi les centroïdes de K-means par une
croix noire. Ils ne sont pas affichés pour la CAH, qui est une méthode
hiérarchique sans centroïdes.

![Dendrogramme de Ward.D2 coupé au nombre de groupes retenu ; les étiquettes des clients sont masquées pour préserver la lisibilité.](../figures/segmentation/08_dendrogramme_cah_ward.png)

La CAH et la matrice des distances ont un coût mémoire et calcul de l'ordre
de `O(n²)`. Ce coût reste praticable pour les 2 240 clients étudiés, mais
augmente rapidement sur des jeux de données beaucoup plus grands.

![Distribution des largeurs de silhouette dans la partition retenue.](../figures/segmentation/03_diagnostic_silhouette.png)

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

![Clients représentés sur les deux premières composantes, colorés par segment.](../figures/segmentation/04_segments_plan_acp.png)


Table: Taille des segments

| Segment| Nombre_clients| Pourcentage|
|-------:|--------------:|-----------:|
|       1|           1121|          50|
|       2|           1119|          50|

![Profil relatif des variables dans chaque segment.](../figures/segmentation/05_profils_segments.png)


Table: Profils médians sur les variables d'origine et taux de réponse observé

| Segment| Nombre_clients| Age_Client|  Income| Kidhome| Teenhome| Recency| MntWines| MntFruits| MntMeatProducts| MntFishProducts| MntSweetProducts| MntGoldProds| NumDealsPurchases| NumWebPurchases| NumCatalogPurchases| NumStorePurchases| NumWebVisitsMonth| Taux_reponse_pct|Education_majoritaire |Statut_matrimonial_majoritaire |
|-------:|--------------:|----------:|-------:|-------:|--------:|-------:|--------:|---------:|---------------:|---------------:|----------------:|------------:|-----------------:|---------------:|-------------------:|-----------------:|-----------------:|----------------:|:---------------------|:------------------------------|
|       1|           1121|         42| 35776.5|       1|        0|      49|       24|         2|              16|               3|                2|           10|                 2|               2|                   0|                 3|                 7|            10.62|Graduation            |Married                        |
|       2|           1119|         47| 68211.0|       0|        0|      50|      491|        32|             231|              50|               33|           53|                 1|               5|                   4|                 8|                 4|            19.21|Graduation            |Married                        |

## Recommandations marketing à tester

Les pistes ci-dessous sont générées à partir des dépenses totales médianes,
du canal d'achat médian le plus utilisé et du taux de réponse observé dans
chaque segment, comparés aux valeurs globales. Elles servent à formuler des
hypothèses de ciblage ; elles ne démontrent ni causalité ni efficacité future.


Table: Pistes marketing fondées sur les profils observés

| Segment| Depenses_totales_medianes| Depenses_totales_medianes_population|Niveau_depenses |Canal_achat_median_le_plus_utilise | Taux_reponse_pct| Taux_reponse_population_pct|Recommandation                                                                                                                                                                                           |
|-------:|-------------------------:|------------------------------------:|:---------------|:----------------------------------|----------------:|---------------------------:|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|       1|                        69|                                  396|au-dessous      |Magasin                            |            10.62|                       14.91|Tester une offre de découverte ou de vente croisée. Adapter le test au canal d'achat médian le plus utilisé : Magasin. Tester plusieurs messages ou incitations avant d'augmenter la pression marketing. |
|       2|                      1034|                                  396|au-dessus       |Magasin                            |            19.21|                       14.91|Tester une action de fidélisation ou une offre premium. Adapter le test au canal d'achat médian le plus utilisé : Magasin. Prioriser un pilote de campagne sur ce segment.                               |

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
