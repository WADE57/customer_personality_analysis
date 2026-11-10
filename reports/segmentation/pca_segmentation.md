# ACP et segmentation des clients

## 1. Présentation de la méthode

- Nombre de clients analysés : **2240**.
- Nombre de variables numériques utilisées : **16**.
- Âges supérieurs à 90 ans traités comme manquants : **3**.
- Revenus égaux à 666666 traités comme manquants : **1**.
- Revenus initialement manquants : **24**.
- Nombre total de valeurs imputées par médiane : **28**.
- Les variables de dépenses sont plafonnées aux percentiles 1 et 99. Le revenu et l'âge ne sont pas plafonnés.
- Une transformation `log1p` est appliquée au revenu et aux six variables de dépenses.
- Les variables sont ensuite centrées-réduites.
- L'ACP conserve **7** composantes principales.
- Variance cumulée expliquée : **82.81 %**.
- `ID`, `Response`, les variables catégorielles et les variables dérivées redondantes ne sont pas utilisées pour entraîner l'ACP ou K-means.

## 2. Résultats de la segmentation

- Nombre de segments retenu : **2**.
- Silhouette moyenne : **0.357**.

## Comparaison K-means et classification hiérarchique

Les deux méthodes utilisent les mêmes 2240 clients et les mêmes scores d'ACP retenus. La CAH utilise la distance euclidienne et le critère de Ward.D2 ; l'arbre est coupé en 2 groupes pour permettre une comparaison directe.

La silhouette moyenne est de 0.357 pour K-means et de 0.309 pour Ward.D2. L'ARI entre les deux partitions est de 0.469; il mesure leur concordance, et non la qualité absolue d'une méthode.

Les numéros de segments sont propres à chaque méthode ; il faut comparer
les profils et les affectations plutôt que supposer que le segment 1 d'une
méthode correspond au segment 1 de l'autre.

       Methode Nombre_de_groupes    Distance Silhouette_moyenne Taille_minimale Taille_maximale
       K-means                 2 Euclidienne          0.3573135            1119            1121
 CAH - Ward.D2                 2 Euclidienne          0.3092728             766            1474
 ARI_vs_Kmeans
     1.0000000
     0.4687668

### Tailles des groupes par méthode

       Methode Segment Nombre_clients Pourcentage
       K-means       1           1121    50.04464
       K-means       2           1119    49.95536
 CAH - Ward.D2       1            766    34.19643
 CAH - Ward.D2       2           1474    65.80357

### Profils des groupes par méthode

       Methode Segment Nombre_clients Age_Client  Income Kidhome Teenhome Recency MntWines
       K-means       1           1121       42.0 35776.5       1        0      49     24.0
       K-means       2           1119       47.0 68211.0       0        0      50    491.0
 CAH - Ward.D2       1            766       45.5 72661.0       0        0      50    531.5
 CAH - Ward.D2       2           1474       43.0 39910.0       1        1      49     43.0
 MntFruits MntMeatProducts MntFishProducts MntSweetProducts MntGoldProds NumDealsPurchases
         2              16               3                2           10                 2
        32             231              50               33           53                 1
        47             348              72               48           54                 1
         3              23               4                3           14                 2
 NumWebPurchases NumCatalogPurchases NumStorePurchases NumWebVisitsMonth Taux_reponse_pct
               2                   0                 3                 7         10.61552
               5                   4                 8                 4         19.21358
               5                   5                 9                 3         23.23760
               3                   1                 4                 7         10.58345

La matrice de distances utilisée occupe environ 19.1 Mio en mémoire. La CAH requiert O(n²) en mémoire et en calcul ; ce coût augmente rapidement avec le nombre de clients.

| Segment | Nombre de clients | Pourcentage |
|---|---:|---:|
| 1 | 1121 | 50.04 |
| 2 | 1119 | 49.96 |

### Diagnostic des silhouettes

 Segment Nombre_clients Silhouette_moyenne Silhouette_mediane Pourcentage_silhouettes_negatives
       1           1121          0.3676258          0.4186820                          0.000000
       2           1119          0.3469828          0.4023013                          0.893655

### Stabilité selon les initialisations de K-means

La partition de référence (K = 2) a été comparée à 100 exécutions indépendantes de K-means avec une seule initialisation chacune. L'indice ARI tient compte des permutations d'étiquettes ; 1 correspond à des partitions identiques.

 Nombre_initialisations Graine ARI_moyen ARI_ecart_type ARI_minimum ARI_quantile_05 ARI_maximum
                    100   2027 0.9921531    0.008045732    0.983986        0.983986           1
 Partitions_identiques_pct
                        51

### Stabilité par sous-échantillonnage

K-means a été réajusté sur 100 sous-échantillons sans remise contenant 80 % des clients (1792 clients par répétition), avec 50 initialisations par ajustement. Chaque partition a ensuite été appliquée à tous les clients par affectation au centroïde le plus proche, puis comparée à la partition de référence par ARI.

L'imputation, le plafonnement, la standardisation et l'ACP sont maintenus
fixes. Ce diagnostic mesure donc la sensibilité de K-means à la composition
de l'échantillon dans l'espace ACP existant ; il ne valide pas toute la
chaîne de traitement ni la généralisation à une nouvelle population.

 Nombre_repetitions Fraction_clients_pct Taille_sous_echantillon
                100                   80                    1792
 Initialisations_kmeans_par_repetition Graine ARI_moyen ARI_ecart_type ARI_minimum ARI_quantile_05
                                    50   2028 0.9789884     0.01790867   0.9280937       0.9349046
 ARI_maximum
           1

## 3. Profils des segments

Les profils sont calculés à partir des médianes des variables originales. Le taux de réponse est un indicateur descriptif postérieur à la segmentation.

 Segment Nombre_clients Age_Client  Income Kidhome Teenhome Recency MntWines MntFruits
       1           1121         42 35776.5       1        0      49       24         2
       2           1119         47 68211.0       0        0      50      491        32
 MntMeatProducts MntFishProducts MntSweetProducts MntGoldProds NumDealsPurchases NumWebPurchases
              16               3                2           10                 2               2
             231              50               33           53                 1               5
 NumCatalogPurchases NumStorePurchases NumWebVisitsMonth Taux_reponse_pct Education_majoritaire
                   0                 3                 7         10.61552            Graduation
                   4                 8                 4         19.21358            Graduation
 Statut_matrimonial_majoritaire
                        Married
                        Married

## 4. Contributions des variables à l'ACP

            Variable    PC1    PC2    PC3    PC4    PC5    PC6    PC7
          Age_Client  0.485 11.746 22.357  0.111 31.061  9.026 18.951
              Income  8.926  0.790  6.793  0.047 15.602  0.005  0.153
             Kidhome  6.419  0.020  7.962  0.400 10.086 16.880  5.914
            Teenhome  0.041 32.257  4.662  0.065  0.034  1.507 37.474
             Recency  0.007  0.000  0.041 98.418  0.057  1.267  0.001
            MntWines 10.545  5.441  0.205  0.045  4.756  3.254  1.953
           MntFruits  8.613  2.730  2.741  0.100  5.048  3.831  2.657
     MntMeatProducts 12.476  0.000  0.751  0.013  1.515  0.108  3.198
     MntFishProducts  8.540  3.340  2.815  0.055  4.821  6.174  0.485
    MntSweetProducts  8.417  2.803  3.254  0.089  3.128  4.080  4.194
        MntGoldProds  6.917  0.359  7.374  0.040  8.445  0.867  2.200
   NumDealsPurchases  0.012 23.842 18.658  0.129  2.274 18.975  0.179
     NumWebPurchases  5.485  9.054  5.434  0.311  0.570 22.730  3.772
 NumCatalogPurchases  8.750  0.220  0.239  0.035  2.752  2.428 13.221
   NumStorePurchases  9.024  1.042  0.000  0.122  3.748  0.660  2.181
   NumWebVisitsMonth  5.342  6.355 16.716  0.020  6.103  8.206  3.467

## 5. Interprétation des composantes

Les variables ci-dessous ont une corrélation absolue d'au moins 0,30
avec chaque composante (trois variables au maximum). Le signe indique
le sens de l'association ; il ne s'agit pas d'un effet causal.

 Composante Variance_expliquee_pct          Variable Correlation
        PC1              43.183503   MntMeatProducts  -0.9284341
        PC1              43.183503          MntWines  -0.8535891
        PC1              43.183503 NumStorePurchases  -0.7896192
        PC2              12.394680          Teenhome   0.7998198
        PC2              12.394680 NumDealsPurchases   0.6876270
        PC2              12.394680        Age_Client   0.4826487
        PC3               8.536628        Age_Client   0.5525944
        PC3               8.536628 NumDealsPurchases  -0.5048178
        PC3               8.536628 NumWebVisitsMonth  -0.4778291
        PC4               6.281343           Recency   0.9945418
        PC5               4.660264        Age_Client   0.4812536
        PC5               4.660264            Income  -0.3410809
        PC6               4.269476   NumWebPurchases  -0.3940463
        PC6               4.269476 NumDealsPurchases   0.3600322
        PC6               4.269476           Kidhome   0.3395745
        PC7               3.486443          Teenhome  -0.4572101
        PC7               3.486443        Age_Client   0.3251416

## 6. Recommandations marketing à tester

Les recommandations sont générées à partir des dépenses totales médianes, du canal d'achat médian le plus utilisé et du taux de réponse observé dans chaque segment. Elles sont comparées aux médianes ou taux globaux.

 Segment Depenses_totales_medianes Depenses_totales_medianes_population Niveau_depenses
       1                        69                                  396      au-dessous
       2                      1034                                  396       au-dessus
 Canal_achat_median_le_plus_utilise Taux_reponse_pct Taux_reponse_population_pct
                            Magasin         10.61552                    14.91071
                            Magasin         19.21358                    14.91071
                                                                                                                                                                                           Recommandation
 Tester une offre de découverte ou de vente croisée. Adapter le test au canal d'achat médian le plus utilisé : Magasin. Tester plusieurs messages ou incitations avant d'augmenter la pression marketing.
                               Tester une action de fidélisation ou une offre premium. Adapter le test au canal d'achat médian le plus utilisé : Magasin. Prioriser un pilote de campagne sur ce segment.

Ces recommandations sont des hypothèses descriptives à évaluer par des
tests marketing contrôlés. Les écarts observés ne démontrent ni causalité
ni efficacité future.

## 7. Limites d'interprétation

- Les segments sont des profils exploratoires, pas des catégories naturelles garanties.
- Une silhouette moyenne modérée indique que les groupes ne sont pas parfaitement séparés.
- Le choix du nombre de clusters dépend des variables et de la méthode retenues.
- Seules les variables de dépenses sont plafonnées aux percentiles 1 et 99 pour l'ACP et le clustering.
- Les profils sont descriptifs et ne permettent pas d'établir des relations causales.
- Les variables catégorielles n'ont pas participé à la construction des segments.

## 8. Figures

- `figures/segmentation/01_variance_acp.png`
- `figures/segmentation/02_selection_clusters.png`
- `figures/segmentation/03_diagnostic_silhouette.png`
- `figures/segmentation/04_segments_plan_acp.png`
- `figures/segmentation/05_profils_segments.png`
- `figures/segmentation/06_comparaison_partitions_kmeans_cah.png`
- `figures/segmentation/07_comparaison_silhouette_kmeans_cah.png`
- `figures/segmentation/08_dendrogramme_cah_ward.png`
- `figures/segmentation/09_kmeans_centroides_silhouette.png`

## 9. Fichiers de résultats

- `reports/segmentation/variance_acp.csv`
- `reports/segmentation/contributions_variables_acp.csv`
- `reports/segmentation/correlations_variables_composantes.csv`
- `reports/segmentation/interpretation_composantes_acp.csv`
- `reports/segmentation/recommandations_marketing.csv`
- `reports/segmentation/comparaison_kmeans_cah.csv`
- `reports/segmentation/tailles_segments_comparaison.csv`
- `reports/segmentation/profils_kmeans_cah.csv`
- `reports/segmentation/resume_stabilite_kmeans.csv`
- `reports/segmentation/stabilite_kmeans_initialisations.csv`
- `reports/segmentation/resume_stabilite_sous_echantillonnage.csv`
- `reports/segmentation/stabilite_sous_echantillonnage.csv`
- `reports/segmentation/selection_nombre_clusters.csv`
- `reports/segmentation/diagnostic_silhouette_segments.csv`
- `reports/segmentation/tailles_segments.csv`
- `reports/segmentation/profils_segments.csv`
- `reports/segmentation/affectation_clients_segments.csv`

