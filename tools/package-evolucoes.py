#!/usr/bin/env python3
"""Evolução dos Soulmonsters: tabela de famílias e arte provisória das formas.

Lê o plano de povoamento (documentation/creatures/familias/Plano-de-povoamento-aprovado.csv)
e as cadeias abaixo, recorta as imagens brutas dos concepts (fundo liso → transparente)
e escreve:

  godot/assets/campaign/evolutions.json     regras e formas (lido por scripts/campaign/evolution.gd)
  godot/assets/campaign/evolucoes-v1/*.png  arte provisória (um quadro, como o Veskoro)
  godot/assets/campaign/content.json        uma entrada combat por forma (batalha, equipe, mapa)

A arte é provisória: quando a arte final de uma forma chegar, troque o PNG (ou a entrada
combat da forma) e mantenha o id.

    python3 tools/package-evolucoes.py
"""
import csv
import json
import pathlib

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[1]
CSV = ROOT / "documentation/creatures/familias/Plano-de-povoamento-aprovado.csv"
OUT = ROOT / "godot/assets/campaign/evolucoes-v1"
CONTENT = ROOT / "godot/assets/campaign/content.json"
TABLE = ROOT / "godot/assets/campaign/evolutions.json"

# Estágios: o parceiro da oficina nasce no estágio de criança (II). Jovem (III) e adulto (IV)
# chegam por nível. "bonus" soma ao bônus de criação nos atributos (em %).
STAGES = {
    "crianca": {"name": "Criança", "level": 1, "bonus": 0},
    "jovem": {"name": "Jovem", "level": 16, "bonus": 6},
    "adulto": {"name": "Adulto", "level": 32, "bonus": 12},
}

# Famílias que o jogador já pode ter na campanha. A chave é o modelId do parceiro; cada
# estágio lista as formas possíveis (mais de uma = o jogador escolhe na hora de evoluir).
# Ids são as chaves de identidade do plano de povoamento (família:forma).
CHAINS = {
    "basica": {"family": "carcara", "crianca": ["carcara:carcara"], "jovem": ["carcara:caravento"], "adulto": ["carcara:caramastro"]},
    "mata": {"family": "mata-verde", "crianca": ["mata-verde:mata-verde"], "jovem": ["mata-verde:folhante"], "adulto": ["mata-verde:verdestrama"]},
    "raio": {"family": "raio-de-sol", "crianca": ["raio-de-sol:raio-de-sol-crianca"], "jovem": [], "adulto": ["raio-de-sol:solguarda"]},
    "azulao": {"family": "azulao", "crianca": ["azulao:azulao"],
               "jovem": ["azulao:azulineo", "azulao:azulume", "azulao:azulfazo"],
               "adulto": ["azulao:azulaculo", "azulao:azuligero", "azulao:azultor"]},
    "rabbito": {"family": "rabbito", "crianca": ["rabbito:rabbito"], "jovem": ["rabbito:rastro-dos-ventos"],
                "adulto": ["rabbito:mestre-dos-fios", "rabbito:tecelao-da-aurora", "rabbito:arauto-da-tempestade",
                           "rabbito:rabbito-conde-da-ultima-hora", "rabbito:rabbito-velocista-relampago"]},
    "doberman-c": {"family": "doberman-c", "crianca": [], "jovem": ["doberman-c:doberman-c"], "adulto": ["doberman-c:dobracula"]},
    # Montaria aquática (mount_passives.gd): a Capiboia vem da Marisol, ao fim da aula de remo.
    "capivara-boia": {"family": "capivara-boia", "crianca": ["capivara-boia:capivara-boia"],
                      "jovem": ["capivara-boia:remansa", "capivara-boia:capiboia-contensor", "capivara-boia:capiboia-condutor"],
                      "adulto": ["capivara-boia:marevia", "capivara-boia:capiboia-porto", "capivara-boia:capiboia-tececorrente"]},
}
# A forma de base de cada família é o modelId que o jogo já usa (arte e regras atuais).
BASE_ID = {"carcara:carcara": "basica", "mata-verde:mata-verde": "mata", "raio-de-sol:raio-de-sol-crianca": "raio",
           "azulao:azulao": "azulao", "rabbito:rabbito": "rabbito", "doberman-c:doberman-c": "doberman-c"}


def cutout(src: pathlib.Path, dst: pathlib.Path, height=360) -> tuple:
    """Fundo liso (cor dos cantos) vira transparente por preenchimento a partir das bordas."""
    im = Image.open(src).convert("RGBA")
    if max(im.size) > 1600:
        im.thumbnail((1600, 1600), Image.LANCZOS)
    w, h = im.size
    mask = Image.new("L", (w + 2, h + 2), 0)
    rgb = im.convert("RGB")
    # Preenche a partir de pontos da borda com tolerância (fundos brancos e escuros com brilho).
    filled = rgb.copy()
    sentinel = (1, 254, 3)
    for x, y in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1), (w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2)]:
        if filled.getpixel((x, y)) != sentinel:
            ImageDraw.floodfill(filled, (x, y), sentinel, thresh=58)
    px = filled.load()
    alpha = Image.new("L", (w, h), 255)
    a = alpha.load()
    for y in range(h):
        for x in range(w):
            if px[x, y] == sentinel:
                a[x, y] = 0
    im.putalpha(alpha)
    box = im.getbbox() or (0, 0, w, h)
    im = im.crop(box)
    scale = height / im.height
    if im.width * scale > height * 1.6:
        scale = height * 1.6 / im.width
    im = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.LANCZOS)
    dst.parent.mkdir(parents=True, exist_ok=True)
    im.save(dst, optimize=True)
    return im.size


def main():
    rows = {r["Chave da identidade"]: r for r in csv.DictReader(open(CSV, encoding="utf-8-sig"), delimiter=";")}
    content = json.loads(CONTENT.read_text(encoding="utf-8"))
    forms, models = {}, {}
    for model, chain in CHAINS.items():
        previous = []
        for stage in ("crianca", "jovem", "adulto"):
            ids = chain[stage]
            if not ids:
                continue
            current = []
            for key in ids:
                row = rows[key]
                form_id = BASE_ID.get(key) or key.split(":")[1]
                entry = {"name": row["Nome"].replace(" (proposta)", ""), "family": chain["family"], "root": model,
                         "stage": stage, "level": STAGES[stage]["level"], "bonus": STAGES[stage]["bonus"],
                         "from": previous[:], "identity": key, "status": row["Estado visual"], "provisional": True}
                if form_id not in BASE_ID.values():
                    art = ROOT / row["Arte no repositório"]
                    size = cutout(art, OUT / f"{form_id}.png")
                    frame = {"x": 0, "y": 0, "w": size[0], "h": size[1]}
                    content["combat"][form_id] = {"image": f"evolucoes-v1/{form_id}.png", "provisional": True,
                                                  "animations": {k: [frame] for k in ("idle", "flight", "attack", "hurt", "victory", "defeat")}}
                    entry["source"] = row["Arte no repositório"]
                else:
                    # Forma de base (a da oficina): sem bônus, mesmo quando o estágio é jovem (Dóber).
                    entry["provisional"] = False
                    entry["bonus"] = 0
                forms[form_id] = entry
                current.append(form_id)
            previous = current
        models[model] = chain["family"]
    table = {
        "version": 1,
        "fonte": "tools/package-evolucoes.py · plano de povoamento aprovado",
        "regra": "A evolução fica disponível quando o parceiro alcança o nível do estágio seguinte; o jogador confirma (e escolhe entre ramos, quando há mais de um). Nível, XP, condição e nome dado pelo jogador são mantidos.",
        "stages": STAGES,
        "forms": forms,
    }
    TABLE.write_text(json.dumps(table, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    # Insere só as entradas novas no bloco "combat", sem reformatar o resto do content.json.
    text = CONTENT.read_text(encoding="utf-8")
    existing = json.loads(text)["combat"]
    added = {k: v for k, v in content["combat"].items() if k not in existing}
    if added:
        anchor = '"combat": {\n'
        at = text.index(anchor) + len(anchor)
        block = "".join("    " + json.dumps(k, ensure_ascii=False) + ": " + json.dumps(v, ensure_ascii=False, separators=(",", ":")) + ",\n"
                        for k, v in added.items())
        text = text[:at] + block + text[at:]
        CONTENT.write_text(text, encoding="utf-8")
        json.loads(text)
    print(len(forms), "formas;", sum(1 for f in forms.values() if f.get("source")), "com arte provisória")


if __name__ == "__main__":
    main()
