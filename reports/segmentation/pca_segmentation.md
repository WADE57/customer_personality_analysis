# ACP et segmentation des clients

## 1. Présentation de la méthode

- Nombre de clients analysés : **2240**.
- Nombre de variables numériques utilisées : **16**.
- Revenus manquants imputés par la médiane : **24** valeur(s).
- Les valeurs d'âge, de revenu et de dépenses sont limitées aux percentiles 1 et 99 pour l'analyse.
- Une transformation `log1p` est appliquée au revenu et aux six variables de dépenses.
- Les variables sont ensuite centrées-réduites.
- L'ACP conserve **7** composantes principales.
- Variance cumulée expliquée : **82.92 %**.
- `ID`, `Response`, les variables catégorielles et les variables dérivées redondantes ne sont pas utilisées pour entraîner l'ACP ou K-means.

## 2. Résultats de la segmentation

- Nombre de segments retenu : **2**.
- Silhouette moyenne : **0.358**.

| Segment | Nombre de clients | Pourcentage |
|---|---:|---:|
| 1 | 1120 | 50.00 |
| 2 | 1120 | 50.00 |

### Diagnostic des silhouettes

 Segment Nombre_clients Silhouette_moyenne Silhouette_mediane
       1           1120          0.3687509          0.4203402
       2           1120          0.3469782          0.4028158
 Pourcentage_silhouettes_negatives
                         0.0000000
                         0.9821429

## 3. Profils des segments

Les profils sont calculés à partir des médianes des variables originales. Le taux de réponse est un indicateur descriptif postérieur à la segmentation.

 Segment Nombre_clients Age_Client Income Kidhome Teenhome Recency MntWines
       1           1120         42  35765       1        0      49     24.0
       2           1120         47  68148       0        0      50    490.5
 MntFruits MntMeatProducts MntFishProducts MntSweetProducts MntGoldProds
         2            16.0               3                2           10
        32           230.5              50               33           53
 NumDealsPurchases NumWebPurchases NumCatalogPurchases NumStorePurchases
                 2               2                   0                 3
                 1               5                   4                 8
 NumWebVisitsMonth Taux_reponse_pct Education_majoritaire
                 7         10.62500            Graduation
                 4         19.19643            Graduation
 Statut_matrimonial_majoritaire
                        Married
                        Married

## 4. Contributions des variables à l'ACP

            Variable    PC1    PC2    PC3    PC4    PC5    PC6    PC7
          Age_Client  0.486 11.620 22.983  0.118 31.165  8.176 19.112
              Income  9.240  0.944  6.054  0.054 14.181  0.000  0.204
             Kidhome  6.400  0.022  8.270  0.390  8.695 17.469  5.848
            Teenhome  0.039 32.337  4.583  0.069  0.013  1.522 37.253
             Recency  0.007  0.000  0.038 98.404  0.083  1.259  0.001
            MntWines 10.535  5.404  0.188  0.045  5.136  3.058  1.872
           MntFruits  8.577  2.786  2.653  0.101  5.432  3.597  2.628
     MntMeatProducts 12.443  0.000  0.752  0.013  1.590  0.130  3.120
     MntFishProducts  8.499  3.404  2.723  0.056  5.266  5.898  0.465
    MntSweetProducts  8.378  2.861  3.177  0.091  3.448  3.891  4.258
        MntGoldProds  6.889  0.338  7.301  0.043  9.401  0.963  1.823
   NumDealsPurchases  0.011 23.754 18.838  0.130  1.875 19.401  0.173
     NumWebPurchases  5.478  8.946  5.520  0.307  0.541 22.872  3.742
 NumCatalogPurchases  8.722  0.230  0.251  0.035  3.061  2.585 13.320
   NumStorePurchases  9.000  1.012  0.000  0.122  4.158  0.600  2.625
   NumWebVisitsMonth  5.295  6.342 16.669  0.021  5.954  8.580  3.556

## 5. Limites d'interprétation

- Les segments sont des profils exploratoires, pas des catégories naturelles garanties.
- Une silhouette moyenne modérée indique que les groupes ne sont pas parfaitement séparés.
- Le choix du nombre de clusters dépend des variables et de la méthode retenues.
- Les valeurs extrêmes ont été plafonnées uniquement pour l'ACP et le clustering.
- Les profils sont descriptifs et ne permettent pas d'établir des relations causales.
- Les variables catégorielles n'ont pas participé à la construction des segments.

## 6. Figures

- `figures/segmentation/01_variance_acp.png`
- `figures/segmentation/02_selection_clusters.png`
- `figures/segmentation/03_diagnostic_silhouette.png`
- `figures/segmentation/04_segments_plan_acp.png`
- `figures/segmentation/05_profils_segments.png`

## 7. Fichiers de résultats

- `reports/segmentation/variance_acp.csv`
- `reports/segmentation/contributions_variables_acp.csv`
- `reports/segmentation/correlations_variables_composantes.csv`
- `reports/segmentation/selection_nombre_clusters.csv`
- `reports/segmentation/diagnostic_silhouette_segments.csv`
- `reports/segmentation/tailles_segments.csv`
- `reports/segmentation/profils_segments.csv`
- `reports/segmentation/affectation_clients_segments.csv`

