#!/usr/bin/env python3
"""Criaturas das Planícies de Kronasta e da Gruta do Moinho: arte provisória de batalha.

Recorta os concepts do plano de povoamento (mesmo recorte de tools/package-evolucoes.py) para
godot/assets/campaign/planicies-v1/ e insere uma entrada "combat" por forma no content.json.
A tabela de encontros fica em tools/criaturas/gerar-encontros.py (regiões "planicie" e "caverna").

    python3 tools/package-planicies.py
"""
import csv
import importlib.util
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("evo", ROOT / "tools/package-evolucoes.py")
evo = importlib.util.module_from_spec(spec)
spec.loader.exec_module(evo)
OUT = ROOT / "godot/assets/campaign/planicies-v1"

# modelId → chave da identidade (família:forma)
FORMS = {
    # Planícies (Nv.10–14)
    "cristim": "galofuso-family-v1:cristim",
    "papisco": "alvacordo-family-v1:papisco",
    "javali-child": "javali-guerreiro:javali-child",
    "galhim": "cervarco-family-v1:galhim",
    # Gruta do Moinho (Nv.12–16)
    "vertim": "estratonte-family-v1:vertim",
    "ossito": "rexestrato-family-v1:ossito",
    "viuva-child": "viuva-anjo:viuva-child",
    # Guardião do Lago Subterrâneo (Nv.18)
    "estratonte": "estratonte-family-v1:estratonte",
}


def main():
    rows = {r["Chave da identidade"]: r for r in csv.DictReader(open(evo.CSV, encoding="utf-8-sig"), delimiter=";")}
    text = evo.CONTENT.read_text(encoding="utf-8")
    existing = json.loads(text)["combat"]
    added = {}
    for form_id, key in FORMS.items():
        size = evo.cutout(ROOT / rows[key]["Arte no repositório"], OUT / f"{form_id}.png", 420 if form_id == "estratonte" else 360)
        frame = {"x": 0, "y": 0, "w": size[0], "h": size[1]}
        entry = {"image": f"planicies-v1/{form_id}.png", "provisional": True,
                 "animations": {k: [frame] for k in ("idle", "flight", "attack", "hurt", "victory", "defeat")}}
        if form_id not in existing:
            added[form_id] = entry
    if added:
        anchor = '"combat": {\n'
        at = text.index(anchor) + len(anchor)
        block = "".join("    " + json.dumps(k, ensure_ascii=False) + ": " + json.dumps(v, ensure_ascii=False, separators=(",", ":")) + ",\n"
                        for k, v in added.items())
        text = text[:at] + block + text[at:]
        evo.CONTENT.write_text(text, encoding="utf-8")
        json.loads(text)
    print(len(FORMS), "formas;", len(added), "novas no content.json")


if __name__ == "__main__":
    main()
