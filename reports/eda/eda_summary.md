# Rapport d'analyse exploratoire des données

## 1. Présentation du jeu de données

- Nombre de clients : 2240
- Nombre de variables : 31
- Nombre de doublons : 0
- Nombre de revenus manquants : 24
- Taux de réponse à la dernière campagne : 14.91 %

## 2. Statistiques descriptives

|                     |   count |     mean |      std |   min |      25% |     50% |     75% |    max |   median |   missing |
|:--------------------|--------:|---------:|---------:|------:|---------:|--------:|--------:|-------:|---------:|----------:|
| Age_Client          |    2240 |    45.19 |    11.98 |    18 |    37    |    44   |    55   |    121 |     44   |         0 |
| Income              |    2216 | 52247.2  | 25173.1  |  1730 | 35303    | 51381.5 | 68522   | 666666 |  51381.5 |        24 |
| Recency             |    2240 |    49.11 |    28.96 |     0 |    24    |    49   |    74   |     99 |     49   |         0 |
| Nb_Enfants_Foyer    |    2240 |     0.95 |     0.75 |     0 |     0    |     1   |     1   |      3 |      1   |         0 |
| Total_Spend         |    2240 |   605.8  |   602.25 |     5 |    68.75 |   396   |  1045.5 |   2525 |    396   |         0 |
| Total_Purchases     |    2240 |    12.54 |     7.21 |     0 |     6    |    12   |    18   |     32 |     12   |         0 |
| NumDealsPurchases   |    2240 |     2.33 |     1.93 |     0 |     1    |     2   |     3   |     15 |      2   |         0 |
| NumWebPurchases     |    2240 |     4.08 |     2.78 |     0 |     2    |     4   |     6   |     27 |      4   |         0 |
| NumCatalogPurchases |    2240 |     2.66 |     2.92 |     0 |     0    |     2   |     4   |     28 |      2   |         0 |
| NumStorePurchases   |    2240 |     5.79 |     3.25 |     0 |     3    |     5   |     8   |     13 |      5   |         0 |
| NumWebVisitsMonth   |    2240 |     5.32 |     2.43 |     0 |     3    |     6   |     7   |     20 |      6   |         0 |

## 3. Valeurs manquantes

| Variable   |   Nombre_manquant |   Pourcentage |
|:-----------|------------------:|--------------:|
| Income     |                24 |          1.07 |

## 4. Corrélations de Spearman

| Variable_1        | Variable_2      |   Spearman_rho | p_value   |   Effectif |
|:------------------|:----------------|---------------:|:----------|-----------:|
| Income            | Total_Spend     |         0.8509 | < 1e-300  |       2216 |
| Age_Client        | Total_Spend     |         0.1568 | 8.53e-14  |       2240 |
| Nb_Enfants_Foyer  | Total_Spend     |        -0.4838 | 8.59e-132 |       2240 |
| NumWebVisitsMonth | NumWebPurchases |        -0.0972 | 4.03e-06  |       2240 |

## 5. Comparaison des répondants et non-répondants

| Variable        |   Mediane_non_repondants |   Mediane_repondants |   Effectif_non |   Effectif_oui |   U_statistic |   p_value |   Rank_biserial |   p_value_Holm | Significatif_5pct   |
|:----------------|-------------------------:|---------------------:|---------------:|---------------:|--------------:|----------:|----------------:|---------------:|:--------------------|
| Income          |                    50150 |              64090   |           1883 |            333 |        395126 |  3.4e-14  |          0.2603 |       3.4e-14  | True                |
| Total_Spend     |                      314 |               1057.5 |           1906 |            334 |        441422 |  1.44e-29 |          0.3868 |       5.76e-29 | True                |
| Total_Purchases |                       11 |                 16   |           1906 |            334 |        403790 |  4.09e-15 |          0.2686 |       8.17e-15 | True                |
| Recency         |                       52 |                 30   |           1906 |            334 |        216066 |  6.79e-21 |         -0.3212 |       2.04e-20 | True                |

## 6. Analyse des campagnes précédentes

| Campagne     |   Acceptations |   Taux_acceptation_pct | Test_utilise   |   Statistique_chi2 |   p_value |   Odds_ratio_Fisher |   V_Cramer |   Effectif_min_attendu |   p_value_Holm | Significatif_5pct   |
|:-------------|---------------:|-----------------------:|:---------------|-------------------:|----------:|--------------------:|-----------:|-----------------------:|---------------:|:--------------------|
| AcceptedCmp1 |            144 |                 6.4286 | Chi-deux       |           193.592  |  5.23e-44 |            nan      |     0.294  |                21.4714 |       2.09e-43 | True                |
| AcceptedCmp2 |             30 |                 1.3393 | Fisher exact   |            64.1984 |  1.27e-10 |             12.0764 |     0.1693 |                 4.4732 |       1.27e-10 | True                |
| AcceptedCmp3 |            163 |                 7.2768 | Chi-deux       |           144.81   |  2.36e-33 |            nan      |     0.2543 |                24.3045 |       7.09e-33 | True                |
| AcceptedCmp4 |            167 |                 7.4554 | Chi-deux       |            70.1917 |  5.38e-17 |            nan      |     0.177  |                24.9009 |       1.08e-16 | True                |
| AcceptedCmp5 |            163 |                 7.2768 | Chi-deux       |           238.985  |  6.55e-54 |            nan      |     0.3266 |                24.3045 |       3.27e-53 | True                |

## 7. Précautions d'interprétation

- Une corrélation ne démontre pas une relation de causalité.
- Les p-values ont été ajustées par la méthode de Holm dans chaque famille de tests.
- Les tailles d'effet complètent l'interprétation des tests statistiques.
- Le test exact de Fisher est utilisé lorsqu'au moins un effectif théorique du tableau est inférieur à 5.
- Les valeurs atypiques sont conservées à ce stade et doivent être interprétées avec prudence.
- Les analyses statistiques ne prouvent pas l'efficacité causale des campagnes.

## 8. Conclusion de l'analyse exploratoire

L'analyse exploratoire a porté sur 2240 clients et 31 variables.
Elle a permis d'étudier les distributions des variables, les relations entre les caractéristiques des clients, leurs dépenses et leurs comportements d'achat.
Une forte association positive a été observée entre le revenu et les dépenses totales, tandis qu'une association négative modérée apparaît entre le nombre d'enfants au foyer et les dépenses.
Les comparaisons entre répondants et non-répondants ont révélé des différences statistiquement significatives pour les quatre variables étudiées, après correction de Holm.
Les cinq campagnes précédentes présentent également des associations statistiquement significatives avec la réponse à la dernière campagne.
Ces résultats constituent une base exploratoire pour l'étude des profils de clients. Ils ne permettent toutefois pas d'établir des relations de causalité.

## Figures sélectionnées pour la suite du projet

Les figures retenues couvrent la qualité des données, les profils clients, les habitudes d'achat, les relations entre variables et la réponse aux campagnes.

- `01_valeurs_manquantes.png`
- `profils_categoriels.png`
- `distributions_variables_cles.png`
- `depenses_moyennes_produits.png`
- `achats_par_canal.png`
- `repartition_response.png`
- `matrice_correlation_spearman.png`
- `relations_variables_cles.png`
- `profil_selon_response.png`
- `taux_acceptation_campagnes.png`