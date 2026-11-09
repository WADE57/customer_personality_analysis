# Inspection initiale des fichiers CSV/Excel
# Place les deux fichiers dans data/raw/ avant d'exécuter ce script.

packages <- c("readr", "readxl", "dplyr", "janitor", "skimr")
missing <- packages[!packages %in% rownames(installed.packages())]
if (length(missing)) install.packages(missing)

library(readr)
library(readxl)
library(dplyr)
library(janitor)
library(skimr)

raw_dir <- file.path("data", "raw")
files <- list.files(raw_dir, pattern = "\\.(csv|xlsx|xls)$", full.names = TRUE, ignore.case = TRUE)

if (length(files) == 0) {
  message("Aucun fichier CSV/Excel trouvé dans ", raw_dir)
} else {
  for (f in files) {
    message("\n==============================")
    message("Fichier : ", basename(f))
    ext <- tolower(tools::file_ext(f))
    dat <- if (ext == "csv") {
      first_line <- readLines(f, n = 1, warn = FALSE)
      delimiter <- if (grepl("\\t", first_line)) "\\t" else if (grepl(";", first_line)) ";" else ","
      readr::read_delim(f, delim = delimiter, show_col_types = FALSE, name_repair = "minimal")
    } else {
      readxl::read_excel(f)
    }
    print(dim(dat))
    print(names(dat))
    print(skimr::skim(dat))
    message("Doublons exacts : ", sum(duplicated(dat)))
  }
}
