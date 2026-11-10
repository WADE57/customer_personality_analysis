# Provenance des données

## Source candidate identifiée

La page Kaggle [Customer Personality Analysis](https://www.kaggle.com/datasets/imakash3011/customer-personality-analysis),
téléversée par **Akash Patel** (`imakash3011`), correspond au nom de fichier
`marketing_campaign.csv` et au schéma général de 2 240 observations et 29
colonnes du fichier local.

Les métadonnées de la [page Kaggle](https://www.kaggle.com/api/v1/datasets/view/imakash3011/customer-personality-analysis)
indiquent :

- fichier publié : `marketing_campaign.csv` ;
- taille annoncée : **220 188 octets** ;
- dernière mise à jour indiquée par Kaggle : **2021-08-22** (ce n'est pas la
  date de téléchargement du fichier local) ;
- licence affichée : **CC0: Public Domain** ;
- la description du jeu attribue sa fourniture à **Dr. Omar Romero-Hernandez**.

La licence [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)
permet en principe la copie, la modification et la redistribution dans la
mesure où les droits concernés peuvent être abandonnés. La page Creative
Commons précise que CC0 ne règle pas nécessairement les droits à la vie
privée, à l'image, les marques ou les autres droits de tiers. La présence
d'une mention CC0 sur Kaggle n'est pas une vérification juridique indépendante
des droits de chaque enregistrement.

## Vérification de la copie locale

| Fichier local | Dimensions vérifiées | Séparateur | Taille | SHA-256 |
|---|---:|---|---:|---|
| `data/raw/marketing_campaign.csv` | 2 240 clients × 29 colonnes | Tabulation | 882 954 octets | `74efc07c95e86f918061b757228ed608570360bf63f7921cff1fc120476e3bf6` |
| `data/processed/marketing_campaign_clean.csv` | 2 240 clients × 31 colonnes | Virgule | 237 041 octets | `6eeac6cd31e8b609108918793db0c666456364f7a99c047c827627bc922621b9` |

Le nom du fichier et ses dimensions sont compatibles avec la source Kaggle,
mais la taille locale brute (**882 954 octets**) ne correspond pas à la
taille annoncée par Kaggle (**220 188 octets**). Son contenu exact n'a donc
pas été rapproché de la copie publiée et sa provenance n'est **pas
confirmée**. La date de téléchargement locale n'est pas enregistrée.

## Conditions de publication du projet

- Les fichiers bruts et préparés sont exclus de Git ; ne pas les ajouter au
  dépôt avant d'avoir établi leur provenance et leurs droits.
- Citer la page Kaggle, Akash Patel et le crédit fourni par la description
  (Dr. Omar Romero-Hernandez) comme provenance candidate, sans prétendre que
  le fichier local est identique à la copie publiée.
- Avant toute redistribution des enregistrements, confirmer que la copie
  locale provient bien de cette source et examiner les éventuels droits de
  tiers et les risques liés aux données clients.
- L'ancien jeu de travail mentionné dans les notes n'était pas disponible
  lors de cette vérification ; aucune comparaison avec lui n'est présentée.
