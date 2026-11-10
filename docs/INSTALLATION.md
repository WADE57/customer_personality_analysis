# Installation

## Linux / Ubuntu

```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip git r-base
```

Depuis le dossier du projet :

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
```

Pour vérifier :

```bash
python --version
R --version
git --version
```

Dans R, installer les packages de départ :

```r
install.packages(c("tidyverse", "readr", "readxl", "janitor", "skimr", "FactoMineR", "factoextra", "cluster", "ggplot2"))
```

Le script `R/04_pca_clustering.R` utilise `ggplot2` et `cluster`.

## Environnement Python

À chaque nouvelle session :

```bash
cd chemin/vers/customer_personality_analysis
source .venv/bin/activate
```

Ne pas versionner `.venv/` ni les fichiers de données brutes.
