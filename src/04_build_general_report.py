from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
EDA_REPORT = ROOT / "reports" / "eda" / "eda_summary.md"
SEGMENTATION_REPORT = ROOT / "reports" / "segmentation" / "pca_segmentation.md"
OUTPUT_REPORT = ROOT / "reports" / "rapport_general.md"


def shift_headings(text):
    return re.sub(
        r"^(#{1,5}) (?=\S)",
        lambda match: f"{match.group(1)}# ",
        text,
        flags=re.MULTILINE,
    )


def read_markdown(path):
    if not path.is_file():
        raise FileNotFoundError(
            f"Rapport source introuvable : {path}. "
            "Exécutez d'abord les étapes précédentes du pipeline."
        )

    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()

    if lines and lines[0].strip() == "---":
        try:
            front_matter_end = lines.index("---", 1)
        except ValueError as error:
            raise ValueError(
                f"En-tête YAML non terminé dans le rapport : {path}"
            ) from error
        lines = lines[front_matter_end + 1 :]

    return "\n".join(lines).strip()


def build_eda_section():
    eda_text = read_markdown(EDA_REPORT)
    figure_heading = "## Figures sélectionnées pour la suite du projet"
    heading_index = eda_text.find(figure_heading)

    if heading_index == -1:
        raise ValueError(
            f"Section des figures introuvable dans {EDA_REPORT}"
        )

    eda_body = eda_text[:heading_index].strip()
    if eda_body.startswith("# "):
        eda_body = eda_body.split("\n", 1)[1].strip()
    eda_body = shift_headings(eda_body)
    figure_list = eda_text[heading_index + len(figure_heading) :]
    figure_names = re.findall(r"^- `([^`]+\.png)`\s*$", figure_list, re.MULTILINE)

    if not figure_names:
        raise ValueError(
            f"Aucune figure EDA référencée dans {EDA_REPORT}"
        )

    figure_sections = ["### Figures de l'analyse exploratoire"]
    for name in figure_names:
        figure_path = ROOT / "figures" / "eda" / name
        if not figure_path.is_file():
            raise FileNotFoundError(
                f"Figure EDA introuvable : {figure_path}"
            )

        caption = Path(name).stem.replace("_", " ").capitalize()
        figure_sections.extend(
            [
                f"![{caption}](../figures/eda/{name})",
                "",
            ]
        )

    return "\n\n".join([eda_body, "\n".join(figure_sections)]).strip()


def main():
    eda_section = build_eda_section()
    segmentation_section = shift_headings(read_markdown(SEGMENTATION_REPORT))

    report = "\n\n".join(
        [
            "# Rapport général — Customer Personality Analysis",
            (
                "Ce document rassemble l'analyse exploratoire réalisée en "
                "Python et l'analyse en composantes principales et la "
                "segmentation réalisées en R."
            ),
            "## 1. Analyse exploratoire des données",
            eda_section,
            "## 2. ACP et segmentation",
            segmentation_section,
        ]
    )

    OUTPUT_REPORT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_REPORT.write_text(report.rstrip() + "\n", encoding="utf-8")
    print(f"Rapport général enregistré : {OUTPUT_REPORT}")


if __name__ == "__main__":
    main()
