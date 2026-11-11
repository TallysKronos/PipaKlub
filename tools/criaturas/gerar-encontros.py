#!/usr/bin/env python3
"""Gera godot/assets/campaign/encounters.json a partir da distribuição aprovada em 08/11/2026
(documentation/creatures/distribuicao/DISTRIBUICAO-DE-SOULMONSTERS.md).

"encontros" é o que aparece hoje: só espécies com arte de batalha no jogo. "planejado" liga
cada papel (comum, incomum, rara, visitante, guardião) à chave do catálogo
(documentation/creatures/familias/catalogo.json). Quando o Codex entregar a arte de uma
família, ela entra em "encontros" com o modelId dela.

    python3 tools/criaturas/gerar-encontros.py
"""
import json, os, sys
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
cat = json.load(open(os.path.join(ROOT, "documentation/creatures/familias/catalogo.json")))

def key(family, node=None):
    fam = next((f for f in cat["families"] if f["id"] == family), None)
    if not fam: sys.exit(f"família inexistente: {family}")
    if node is None: node = fam["nodes"][0]["id"]
    if not any(n["id"] == node for n in fam["nodes"]): sys.exit(f"forma inexistente: {family}:{node} ({[n['id'] for n in fam['nodes']]})")
    return f"{family}:{node}"

def stage(family, index):
    fam = next(f for f in cat["families"] if f["id"] == family)
    return key(family, fam["nodes"][index]["id"])

# Espécies com arte de batalha hoje (encounter_model): o que a região mostra até a família chegar.
GENERIC = [["basica", 50], ["mata", 35], ["raio", 15]]
LIVE = {
    "kronasta-bambuzal": [["rascunho-bicho-pau", 45], ["mata", 40], ["rascunho-joaninha", 15]],
    "kronasta-feira": [["rascunho-bicho-pau", 50], ["rascunho-joaninha", 50]],
    "kronasta-beira-canal": [["lacertubo", 100]],
    # Planícies de Kronasta e Gruta do Moinho (tools/package-planicies.py, arte provisória).
    "planicie": [["cristim", 40], ["papisco", 35], ["javali-child", 15], ["galhim", 10]],
    "caverna": [["vertim", 40], ["ossito", 35], ["viuva-child", 25]],
    # A Caverna do Mural também começa com "caverna-": a chave mais longa vence (wild_tables.gd).
    "caverna-mural": GENERIC,
    # Vulcão, Serra Gelada e Abismo (side_regions.gd).
    "vulcao": [["trincaguarda", 45], ["gevardente", 40], ["trinca-brasas", 15]],
    "serra-gelada": [["urso-polar-young", 40], ["nimbordo", 35], ["lupunhal", 20], ["lupregente", 5]],
    "abismo": [["vortespira", 35], ["hipomoranga", 30], ["reciforte", 20], ["alvorvela", 15]],
}
B, C, J, A = 0, 1, 2, 3  # Bebê, Criança, Jovem, Adulto (ordem dos nós nas famílias de chart)
PLAN = {
    "kronasta-bosque": dict(comuns=[stage("cervarco-family-v1", B), stage("mata-verde", B), stage("mico-samurai", B)], incomum=stage("caramund", B), rara=stage("yaguaru-memoria", B), visitante=stage("canticripta", B), guardiao=stage("yaguaru-memoria", A), noite=[stage("yaguaru-memoria", B)]),
    "kronasta-bambuzal": dict(comuns=[stage("canticripta", B), stage("flautrevo", B), stage("cacaurama", B)], incomum=stage("vesperalito", B), rara=key("tamandua-tear"), visitante=stage("selacrabio", B), guardiao=stage("flautrevo", A)),
    "kronasta-beira-canal": dict(comuns=[stage("makareu", B), stage("cascoronte", B), stage("ibiscrito", B)], incomum=stage("capivara-boia", B), rara=stage("ofirante", B), visitante=stage("trancoura", B), guardiao=stage("makareu", A)),
    "kronasta-feira": dict(comuns=[stage("selacrabio", B), stage("gevoraz", B), stage("gambalhote", B)], incomum=stage("velaravan", B), rara=key("javali-biscoito"), visitante=stage("reciferreo", B), guardiao=stage("velaravan", A)),
    "kronasta-caverna": dict(comuns=[stage("estratonte-family-v1", B), stage("rexestrato-family-v1", B), stage("viuva-anjo", B)], incomum=stage("vortentaculo", B), rara=stage("entrelacos", 0)),  # Paleórix, só depois do ato 6
    "kronasta-cais": dict(comuns=[stage("reciferreo", B), stage("alvorraia", B), stage("capivara-boia", B)], incomum=stage("coroabissal", B), rara=stage("hipolanterna-family-v1", B), visitante=stage("trinca-brasas", B), guardiao=stage("alvorraia", A), noite=[stage("hipolanterna-family-v1", B)]),
    "kronasta-industrial": dict(comuns=[stage("caracol-pneu", C), stage("trinca-brasas", B), stage("ressonhiena", B)], incomum=stage("pangolim-trovao", C), rara=stage("raptorio", J), visitante=stage("crocafago", B)),
    "kronasta-pantano": dict(comuns=[stage("crocafago", B), stage("capivara-boia", C), stage("ofirante", C)], incomum=stage("anaconda-retrato", C), rara=stage("hipolanterna-family-v1", J), visitante=stage("ibiscrito", C), guardiao=stage("crocafago", A)),
    "kronasta-palafitas": dict(comuns=[stage("ibiscrito", C), stage("reciferreo", C), stage("capivara-boia", C)], incomum=stage("hipolanterna-family-v1", C), rara=stage("coroabissal", J), visitante=stage("grifarca", C)),
    "kronasta-montanha": dict(comuns=[stage("grifarca", C), stage("gravurso", C), stage("avelince", C)], incomum=stage("lupunhal", C), rara=stage("lince-de-cerco", J), visitante=stage("nimbalio", C), guardiao=stage("grifarca", A)),
    "kronasta-alto-da-serra": dict(comuns=[stage("urso-polar", C), stage("nimbalio", C), stage("lupunhal", C)], incomum=key("ibex-astrolabio"), rara=key("alvaneve"), guardiao=stage("urso-polar", A)),
    "kronasta-aracati": dict(comuns=[stage("trinca-brasas", J), stage("javali-guerreiro", J), stage("gevoraz", C)], incomum=key("jarabrasa"), rara=key("auriflama")),
    "kronasta-centro": dict(comuns=[stage("riscaz", C), stage("miralis", C), stage("chaspiral", C)], incomum=stage("melicodia", J), rara=stage("coruja-balanca", J), visitante=stage("gata-lunar", J), guardiao=stage("dirubastiao", A)),
    "kronasta-lajes": dict(comuns=[stage("doberman-c", C), stage("trancoura", C), stage("gata-lunar", J)], incomum=stage("torvargo", J), rara=stage("chaspiral", J), visitante=stage("vortentaculo", C), guardiao=stage("doberman-c", A), noite=[stage("gata-lunar", A)]),
    "kronasta-porto": dict(comuns=[stage("vortentaculo", C), stage("coroabissal", J), stage("capivara-boia", J)], incomum=stage("makareu", J), rara=stage("vortentaculo", A), visitante=key("celofita"), guardiao=stage("capivara-boia", A), noite=[stage("vortentaculo", A)]),
    "kronasta-coracao": dict(comuns=[stage("rexestrato-family-v1", J), stage("estratonte-family-v1", J), stage("cervarco-family-v1", J)], incomum=stage("ibiscrito", J), rara=[key("araruna-memoria"), key("caimbira-memoria"), key("tamoata-memoria")]),
    "planicie": dict(comuns=[stage("galofuso-family-v1", C), stage("alvacordo-family-v1", C), stage("javali-guerreiro", C)], incomum=stage("cervarco-family-v1", C)),
    "caverna": dict(comuns=[stage("estratonte-family-v1", C), stage("rexestrato-family-v1", C), stage("viuva-anjo", C)], guardiao=stage("estratonte-family-v1", A)),
    "vulcao": dict(comuns=[stage("trinca-brasas", J), stage("gevoraz", J), stage("trinca-brasas", C)], guardiao=stage("trinca-brasas", A)),
    "serra-gelada": dict(comuns=[stage("urso-polar", J), stage("nimbalio", J), stage("lupunhal", J)], rara=key("lupunhal", "lupregente"), guardiao=stage("urso-polar", A)),
    "abismo": dict(comuns=[stage("vortentaculo", J), stage("hipolanterna-family-v1", J), stage("reciferreo", J)], incomum=stage("alvorraia", J), guardiao=key("coroabissal", "coromar")),
    "kronasta-mirante": dict(comuns=[stage("grifarca", J), stage("nimbalio", J), stage("etruslanca", J)], incomum=key("guaravento"), rara=key("pteralis"), guardiao=stage("etruslanca", A)),
}
NEVER = ["rabbito", "rai", "platyx", "mormaco", "tufanocorte", "rabiolava", "trovareta", "eremor", "retalho", "pipa-dragao", "veskoro"]  # o Lacertubo jovem é selvagem no Beira-Canal; o adulto é o chefe
regions = {}
for prefix in sorted(set(PLAN) | set(LIVE)):
    regions[prefix] = {"encontros": [{"modelo": m, "peso": w} for m, w in LIVE.get(prefix, GENERIC)], "planejado": PLAN.get(prefix, {})}
out = {"version": 1, "fonte": "documentation/creatures/distribuicao/DISTRIBUICAO-DE-SOULMONSTERS.md", "padrao": [{"modelo": m, "peso": w} for m, w in GENERIC], "nuncaSelvagem": NEVER, "regioes": regions}
path = os.path.join(ROOT, "godot/assets/campaign/encounters.json")
open(path, "w").write(json.dumps(out, ensure_ascii=False, indent=1) + "\n")
print(path, len(regions), "regiões")
