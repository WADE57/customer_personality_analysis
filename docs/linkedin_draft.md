# Brouillon de publication LinkedIn

À publier après avoir confirmé que la copie locale des données correspond à
la source candidate et vérifié les droits d'utilisation. Remplacer
`[lien du dépôt]` par l'URL GitHub du projet.

---

📊 **Projet Data Science : segmentation de clients avec ACP et K-means**

J'ai réalisé un projet d'analyse de données marketing pour explorer les
profils et les habitudes d'achat de 2 240 clients.

La démarche comprend le nettoyage et l'analyse exploratoire en Python, puis
une ACP et une segmentation K-means en R. J'ai également comparé K-means à
la classification hiérarchique de Ward et évalué la stabilité des résultats.

Quelques résultats :

- 7 composantes principales expliquent 82,81 % de la variance ;
- 2 segments ont été retenus, avec une silhouette moyenne de 0,357
  (séparation modérée) ;
- la partition K-means présente un ARI moyen de 0,992 sur 100 initialisations
  et de 0,979 sur 100 sous-échantillonnages ;
- une validation interne 80/20 a été réalisée en ajustant le prétraitement,
  l'ACP et K-means uniquement sur l'échantillon d'entraînement.

Les profils observés distinguent notamment des niveaux différents de revenu,
de dépenses et de fréquence d'achat. Ces résultats sont descriptifs : ils ne
démontrent ni causalité ni efficacité des campagnes. Les recommandations
marketing formulées restent des hypothèses à évaluer par des tests contrôlés.

J'ai documenté les étapes, les visualisations et les limites méthodologiques
dans le dépôt : **[lien du dépôt]**

Ce travail m'a permis de pratiquer la préparation des données, l'analyse
multivariée, le clustering, l'évaluation de modèles non supervisés et la
communication de résultats avec prudence.

#DataScience #Python #R #ACP #Clustering #MarketingAnalytics
