# ACP et segmentation des clients

## Méthode

- Clients analysés : **2240**.
- Variables numériques utilisées : **16**.
- `ID`, `Response`, les variables catégorielles et les variables dérivées redondantes ne sont pas utilisées pour entraîner l'ACP ou le clustering.
- Revenus manquants imputés par la médiane : **24** valeur(s).
- Les valeurs d'âge, revenu et dépenses sont limitées aux percentiles 1 et 99 pour l'analyse uniquement ; le fichier préparé n'est pas modifié.
- Une transformation `log1p` est appliquée au revenu et aux dépenses, puis les variables sont centrées-réduites.
- L'ACP conserve **7** composante(s) (variance cumulée : **82.9 %**).
- K-means est ajusté sur les composantes retenues ; `K` est choisi parmi 2 à 8 en maximisant la silhouette moyenne.

## Résultat de la segmentation

- Nombre de segments retenu : **2**.
- Silhouette moyenne : **0.358**.

| Segment | Clients | Part (%) |
|---|---:|---:|
| 1 | 1120 | 50.0 |
| 2 | 1120 | 50.0 |

### Profil médian et réponse observée

Les médianes des variables d'origine et le taux de réponse par segment sont décrits après la segmentation. `Response` n'a pas servi à créer les segments ; son taux est un indicateur descriptif postérieur.

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

## Limites d'interprétation

- Les segments sont des profils exploratoires, pas des catégories naturelles garanties ni des groupes causaux.
- Le choix du nombre de clusters dépend de la méthode et des variables retenues ; il doit être discuté avec leur interprétabilité métier.
- Les valeurs extrêmes ont été limitées uniquement pour le calcul de l'ACP et du clustering ; les exports de profils utilisent les données d'origine.

## Figures

- `figures/segmentation/01_variance_acp.png`
- `figures/segmentation/02_selection_clusters.png`
- `figures/segmentation/03_diagnostic_silhouette.png`
- `figures/segmentation/04_segments_plan_acp.png`
- `figures/segmentation/05_profils_segments.png`

## Fichiers de résultats

- `reports/segmentation/variance_acp.csv`
- `reports/segmentation/contributions_variables_acp.csv`
- `reports/segmentation/selection_nombre_clusters.csv`
- `reports/segmentation/tailles_segments.csv`
- `reports/segmentation/profils_segments.csv`
- `reports/segmentation/affectation_clients_segments.csv`

