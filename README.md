# Customer Personality Analysis

Projet portfolio de Data Science : analyse du comportement client, segmentation et prédiction de réponse aux campagnes marketing.

## Objectifs
1. Comparer deux versions du jeu de données avant analyse.
2. Nettoyer et documenter les données.
3. Réaliser une EDA et une analyse statistique.
4. Étudier les relations entre variables et réaliser une ACP.
5. Segmenter les clients.
6. Construire et évaluer des modèles prédictifs sans fuite de données.
7. Présenter les résultats et recommandations.

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
Rscript R/04_pca_clustering.R
```

Le script exclut `ID` et `Response` de la segmentation, sélectionne le nombre
de groupes avec la silhouette moyenne et enregistre le rapport dans
`reports/segmentation/pca_segmentation.md`, ainsi que les figures dans
`figures/segmentation/`.

## Reproductibilité
Les fichiers de données ne sont pas inclus dans Git. Ajouter la source, la date de téléchargement, le nom du fichier et son empreinte SHA-256 dans `docs/data_sources.md`.
