#!/usr/bin/env bash

set -Eeuo pipefail

if [[ $# -gt 0 ]]; then
  if [[ $# -eq 1 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then
    echo "Usage: ./run_all.sh"
    echo "Exécute le pipeline Python et R complet du projet."
    exit 0
  fi

  echo "Usage: ./run_all.sh" >&2
  exit 2
fi

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$project_root"

if [[ -x "$project_root/.venv/bin/python" ]]; then
  python="$project_root/.venv/bin/python"
elif command -v python >/dev/null 2>&1; then
  python="$(command -v python)"
elif command -v python3 >/dev/null 2>&1; then
  python="$(command -v python3)"
else
  echo "Erreur : Python est introuvable. Activez l'environnement virtuel ou installez Python 3." >&2
  exit 1
fi

if ! command -v Rscript >/dev/null 2>&1; then
  echo "Erreur : Rscript est introuvable. Installez R avant de lancer le pipeline." >&2
  exit 1
fi

if [[ ! -f "$project_root/data/raw/marketing_campaign.csv" ]]; then
  echo "Erreur : fichier source absent : data/raw/marketing_campaign.csv" >&2
  exit 1
fi

echo "Étape 1/4 — Inspection des données brutes"
"$python" src/01_inspect_data.py

echo "Étape 2/4 — Nettoyage des données"
"$python" src/02_clean_data.py

echo "Étape 3/4 — Analyse exploratoire"
"$python" src/03_eda.py

echo "Étape 4/4 — Diagnostic, ACP, segmentation et rapport HTML"
Rscript -e 'rmarkdown::render("R/04_pca_clustering.Rmd", output_file = "pca_segmentation.html", output_dir = "reports/segmentation")'

echo "Pipeline terminé."
echo "Rapport ACP/segmentation : reports/segmentation/pca_segmentation.html"
echo "Rapport d'analyse exploratoire : reports/eda/eda_summary.md"
