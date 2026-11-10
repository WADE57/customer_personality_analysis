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

Installer uniquement les packages R nécessaires au pipeline ACP/segmentation :

```r
install.packages(c("ggplot2", "cluster", "rmarkdown", "knitr"))
```

## Données

Placer le fichier source `marketing_campaign.csv` dans `data/raw/`. Le
nettoyage produit `data/processed/marketing_campaign_clean.csv`; ces
répertoires sont exclus de Git. La provenance et l'empreinte du fichier
présent localement sont décrites dans [`data_sources.md`](data_sources.md).
Vérifier la licence et les conditions de réutilisation auprès de la source
avant de republier ou redistribuer les données.

## Environnement Python

À chaque nouvelle session :

```bash
cd chemin/vers/customer_personality_analysis
source .venv/bin/activate
```

Puis lancer l'ensemble du pipeline :

```bash
./run_all.sh
```

Le script utilise `.venv/bin/python` lorsqu'il existe. Ne pas versionner
`.venv/` ni les fichiers de données.
