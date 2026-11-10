# Customer Personality Analysis

## Description

Customer Personality Analysis est un projet de Data Science visant à analyser
le comportement des clients et à identifier des segments homogènes à partir
de leurs caractéristiques sociodémographiques, de leurs revenus, de leurs
dépenses et de leurs habitudes d'achat.

À partir d'un jeu de données marketing de 2 240 clients, le projet suit une
démarche complète d'analyse de données : inspection, nettoyage, analyse
exploratoire, réduction de dimension par Analyse en Composantes Principales
(ACP) et segmentation par l'algorithme K-means.

L'objectif est de mieux comprendre les différents profils de consommateurs,
d'identifier leurs comportements d'achat et de fournir des éléments d'aide à
la décision pour améliorer le ciblage des campagnes marketing.

## Objectifs

- Explorer et comprendre les données clients.
- Assurer la qualité et la cohérence des données.
- Analyser les caractéristiques et comportements des consommateurs.
- Réduire la dimension des données à l'aide de l'ACP.
- Segmenter les clients avec K-means.
- Interpréter les groupes obtenus et formuler des recommandations marketing.

## Technologies

- Python : Pandas, NumPy, Matplotlib, Seaborn, SciPy.
- R : `prcomp` (ACP), `ggplot2` et `cluster` (K-means et silhouettes),
  `rmarkdown` et `knitr` (rapport).
- Git et GitHub : versionnement et documentation.

## Démarche

Le projet adopte une approche reproductible, combinant analyse statistique,
visualisation des données et apprentissage non supervisé. Les résultats sont
documentés progressivement, sans supposer ni inventer de conclusions. Les
recommandations issues de la segmentation sont des pistes à valider par des
tests marketing, et non des conclusions causales.

## Structure
- `data/raw/` : fichiers originaux, non modifiés (non suivis par Git).
- `data/processed/` : données préparées (non suivies par Git).
- `src/` : scripts Python d'inspection, de nettoyage et d'analyse.
- `figures/eda/` : graphiques de l'analyse exploratoire.
- `figures/segmentation/` : diagnostics de l'ACP et des segments.
- `reports/eda/` : synthèses et rapports de l'analyse exploratoire.
- `reports/segmentation/` : profils et résultats de l'ACP/segmentation.
- `notebooks/` : analyses exploratoires complémentaires.
- `R/` : scripts R.
- `docs/` : dictionnaire de données et décisions méthodologiques.

## Démarrage
Voir `docs/INSTALLATION.md`.

## Lancer l'analyse exploratoire

Après avoir placé `marketing_campaign.csv` dans `data/raw/` et activé
l'environnement virtuel :

```bash
python src/02_clean_data.py
python src/03_eda.py
```

Le script EDA lit `data/processed/marketing_campaign_clean.csv`, enregistre
une sélection de dix figures utiles à la segmentation et à la modélisation
dans `figures/eda/`, puis génère la synthèse statistique
`reports/eda/eda_summary.md`. Il exporte également les statistiques
descriptives, valeurs manquantes, corrélations, campagnes et distributions
catégorielles au format CSV dans `reports/eda/`. Les fichiers de données
restent exclus de Git.

## Lancer l'ACP et la segmentation (R)

Après avoir exécuté le nettoyage Python et installé les packages R indiqués
dans `docs/INSTALLATION.md` :

```bash
Rscript -e 'rmarkdown::render("R/04_pca_clustering.Rmd", output_file = "pca_segmentation.html", output_dir = "reports/segmentation")'
```

Le rapport HTML exécute le diagnostic des variables puis l'ACP et la
segmentation. Il présente la variance expliquée, les variables les plus
associées à chaque composante, le choix du nombre de segments, leurs profils,
une évaluation de la stabilité de K-means selon plusieurs initialisations et
un sous-échantillonnage répété des clients, ainsi que des recommandations
marketing fondées sur les données observées. Il
intègre les tableaux et les figures au rapport et exporte également les
résultats CSV sous `reports/segmentation/`. Le diagnostic signale les valeurs
atypiques, sans les supprimer ni les modifier.

Les principales sorties dédiées à l'interprétation sont
`reports/segmentation/interpretation_composantes_acp.csv` et
`reports/segmentation/recommandations_marketing.csv`. La stabilité est
résumée dans `reports/segmentation/resume_stabilite_kmeans.csv` et détaillée
dans `reports/segmentation/stabilite_kmeans_initialisations.csv`. La
sensibilité à la composition de l'échantillon est résumée dans
`reports/segmentation/resume_stabilite_sous_echantillonnage.csv` et détaillée
dans `reports/segmentation/stabilite_sous_echantillonnage.csv`. Ce dernier
diagnostic conserve fixes le prétraitement et l'ACP calculés sur l'ensemble
des clients ; il évalue la stabilité de K-means dans cet espace, pas celle de
toute la chaîne de traitement sur une nouvelle population.

Le script exclut `ID` et `Response` de la segmentation, sélectionne le nombre
de groupes avec la silhouette moyenne et enregistre le rapport dans
`reports/segmentation/pca_segmentation.html` (ainsi qu'une synthèse Markdown
dans `reports/segmentation/pca_segmentation.md`) et les figures dans
`figures/segmentation/`. Les recommandations sont des hypothèses descriptives
basées sur les dépenses, le canal d'achat le plus utilisé et les taux de
réponse observés ; elles ne démontrent pas l'efficacité causale d'une action.

## Reproductibilité
Les fichiers de données ne sont pas inclus dans Git. Ajouter la source, la date de téléchargement, le nom du fichier et son empreinte SHA-256 dans `docs/data_sources.md`.
