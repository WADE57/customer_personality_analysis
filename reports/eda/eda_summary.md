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

| Variable_1        | Variable_2      |   Spearman_rho |   p_value |   Effectif |
|:------------------|:----------------|---------------:|----------:|-----------:|
| Income            | Total_Spend     |         0.8509 |         0 |       2216 |
| Age_Client        | Total_Spend     |         0.1568 |         0 |       2240 |
| Nb_Enfants_Foyer  | Total_Spend     |        -0.4838 |         0 |       2240 |
| NumWebVisitsMonth | NumWebPurchases |        -0.0972 |         0 |       2240 |

## 5. Comparaison des répondants et non-répondants

| Variable        |   Mediane_non_repondants |   Mediane_repondants |   Effectif_non |   Effectif_oui |   U_statistic |   p_value |   Rank_biserial |   p_value_Holm | Significatif_5pct   |
|:----------------|-------------------------:|---------------------:|---------------:|---------------:|--------------:|----------:|----------------:|---------------:|:--------------------|
| Income          |                    50150 |              64090   |           1883 |            333 |        395126 |         0 |          0.2603 |              0 | True                |
| Total_Spend     |                      314 |               1057.5 |           1906 |            334 |        441422 |         0 |          0.3868 |              0 | True                |
| Total_Purchases |                       11 |                 16   |           1906 |            334 |        403790 |         0 |          0.2686 |              0 | True                |
| Recency         |                       52 |                 30   |           1906 |            334 |        216066 |         0 |         -0.3212 |              0 | True                |

## 6. Analyse des campagnes précédentes

| Campagne     |   Acceptations |   Taux_acceptation_pct | Test_utilise   |   Statistique_chi2 |   p_value |   Odds_ratio_Fisher |   V_Cramer |   Effectif_min_attendu |   p_value_Holm | Significatif_5pct   |
|:-------------|---------------:|-----------------------:|:---------------|-------------------:|----------:|--------------------:|-----------:|-----------------------:|---------------:|:--------------------|
| AcceptedCmp1 |            144 |                 6.4286 | Chi-deux       |           193.592  |         0 |            nan      |     0.294  |                21.4714 |              0 | True                |
| AcceptedCmp2 |             30 |                 1.3393 | Fisher exact   |            64.1984 |         0 |             12.0764 |     0.1693 |                 4.4732 |              0 | True                |
| AcceptedCmp3 |            163 |                 7.2768 | Chi-deux       |           144.81   |         0 |            nan      |     0.2543 |                24.3045 |              0 | True                |
| AcceptedCmp4 |            167 |                 7.4554 | Chi-deux       |            70.1917 |         0 |            nan      |     0.177  |                24.9009 |              0 | True                |
| AcceptedCmp5 |            163 |                 7.2768 | Chi-deux       |           238.985  |         0 |            nan      |     0.3266 |                24.3045 |              0 | True                |

## 7. Précautions d'interprétation

- Une corrélation ne démontre pas une relation de causalité.
- Les p-values ont été ajustées par la méthode de Holm dans chaque famille de tests.
- Les tailles d'effet complètent l'interprétation des tests statistiques.
- Le test exact de Fisher est utilisé lorsqu'au moins un effectif théorique du tableau est inférieur à 5.
- Les valeurs atypiques sont conservées à ce stade et doivent être interprétées avec prudence.
- Les analyses statistiques ne prouvent pas l'efficacité causale des campagnes.