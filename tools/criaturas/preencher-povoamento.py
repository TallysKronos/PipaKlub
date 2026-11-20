#!/usr/bin/env python3
"""Gera documentation/creatures/familias/Plano-de-povoamento-aprovado.csv: a planilha do Codex
(Plano-de-povoamento.csv, regerada em branco por gerar_grupos.py) com as colunas de planejamento
(Área, Momento narrativo, Função do encontro, Disponibilidade) preenchidas pela distribuição
aprovada pelo dono em 08/11/2026. A fonte das regiões é godot/assets/campaign/encounters.json ("planejado"); campeões,
parque, chefes de história e pós-jogo vêm das listas abaixo. Linhas sem papel ficam em branco.

    python3 tools/criaturas/gerar-encontros.py && python3 tools/criaturas/preencher-povoamento.py
"""
import csv, io, json, os
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
CSV = os.path.join(ROOT, "documentation/creatures/familias/Plano-de-povoamento.csv")
OUT = os.path.join(ROOT, "documentation/creatures/familias/Plano-de-povoamento-aprovado.csv")
enc = json.load(open(os.path.join(ROOT, "godot/assets/campaign/encounters.json")))

REGIONS = {
    "kronasta-bosque": ("Bosque dos Ventos", "Ato 1 · Nv.1–5"), "kronasta-bambuzal": ("Vila do Bambuzal", "Ato 1 · Nv.9–12"),
    "kronasta-beira-canal": ("Beira-Canal", "Ato 2 · Nv.12–15"), "kronasta-feira": ("Feira do Largo", "Ato 2 · Nv.15–18"),
    "kronasta-caverna": ("Caverna do Mural", "Ato 2 · Nv.15–18"), "kronasta-cais": ("Cais Velho", "Ato 3 · Nv.18–21"),
    "kronasta-industrial": ("Distrito Industrial", "Ato 3 · Nv.20–24"), "kronasta-pantano": ("Pântano do Mormaço", "Ato 3 · Nv.23–25"),
    "kronasta-palafitas": ("Palafitas", "Ato 3 · Nv.24–27"), "kronasta-montanha": ("Serra de Kronasta", "Ato 4 · Nv.26–32"),
    "kronasta-alto-da-serra": ("Alto da Serra", "Ato 4 · Nv.27–30"), "kronasta-aracati": ("Ilha do Aracati", "Ato 4 · Nv.30–34"),
    "kronasta-centro": ("Centro", "Ato 5 · Nv.30–33"), "kronasta-lajes": ("Condomínio", "Ato 5 · Nv.33–36"),
    "kronasta-porto": ("Porto Novo", "Ato 6 · Nv.36–40"), "kronasta-coracao": ("Coração das Ruínas", "Ato 6 · Nv.40–45"),
    "kronasta-mirante": ("Alto do Mirante", "Ato 6 · Nv.40–44"),
}
ROLE = {"comuns": "Selvagem comum", "incomum": "Selvagem incomum", "rara": "Selvagem rara (mato denso)",
        "visitante": "Visitante (antecipa a região seguinte)", "guardiao": "Guardião de área (parte C/D, rabiola na 1ª vitória)",
        "noite": "Selvagem noturna"}
roles = {}  # chave → [(área, momento, função, disponibilidade)]
def add(k, area, moment, role, avail):
    if k.startswith("entrelacos:"): k = "shared:" + k.split(":")[1]  # chave do CSV para os Entrelaços
    roles.setdefault(k, []).append((area, moment, role, avail))

for rid, region in enc["regioes"].items():
    area, moment = REGIONS[rid]
    for role, value in region["planejado"].items():
        for k in (value if isinstance(value, list) else [value]):
            avail = "Guardião único" if role == "guardiao" else "Selvagem · enroscada e drop de rabiola"
            if k.startswith(("entrelacos:", "shared:")): avail = "Selvagem rara depois do ato 6"
            add(k, area, moment, ROLE[role], avail)

for k, role in [("mata-verde:brotim", "comuns"), ("azulao:azulim", "comuns"), ("carcara:carquim", "comuns"),
                ("galofuso-family-v1:pivico", "incomum"), ("raio-de-sol:solim", "rara"), ("cervarco-family-v1:brotim", "visitante")]:
    add(k, "Parque dos Ventos", "Prólogo e ato 1 · Nv.1–8", ROLE[role], "Selvagem · enroscada e drop de rabiola")

CHAMPIONS = [("raio-de-sol:solguarda", "Mikka", "Morro do Sol", "Prólogo"), ("flautrevo:vesperalia", "Lohan", "Vila do Bambuzal", "Ato 1"),
             ("makareu:makareu", "Kleie", "Beira-Canal", "Ato 2"), ("velaravan:velaravan", "Dona Zulmira", "Feira do Largo", "Ato 2"),
             ("alvorraia:alvorraia", "Marisol", "Cais Velho", "Ato 3"), ("pangolim-trovao:pangolim-adult-dragao", "Bruno Solda", "Vila Operária", "Ato 3"),
             ("urso-polar:borealvo", "Dona Neve", "Alto da Serra", "Ato 4"), ("melicodia:melicodia", "Leo Antena", "Centro", "Ato 5"),
             ("doberman-c:dobracula", "Tainá", "Condomínio", "Ato 5"), ("vortentaculo:vortentaculo", "Capitão Jurandir", "Porto Novo", "Ato 6"),
             ("grifarca:grifarca", "Ícaro", "Alto do Mirante", "Ato 6"), ("azulao:azuligero", "Jamile", "Estádio de Kronasta", "Final")]
for k, who, area, moment in CHAMPIONS:
    add(k, area, moment, "Ás do campeão " + who + " (família-assinatura do bairro)", "Só no time do campeão; tenentes usam as comuns da região")
STORY = {"rabbito": "Parceiro do Kael", "rai": "Parceiro do Tyler", "platyx": "Parceiro do Grampo (decidido 02/11)",
         "mormaco": "Quatro Ventos · Pântano", "tufanocorte": "Quatro Ventos · Serra", "rabiolava": "Quatro Ventos · Aracati",
         "trovareta": "Quatro Ventos · Bosque", "eremor": "Lendário · Coração D", "retalho": "Parceira da Heleana",
         "pipa-dragao": "Parceiro do Gollia", "veskoro": "Ás do campeão Caio Garça (Palafitas)"}
KNIGHTS = ["bradamara", "cidraco", "geordraco", "joanacendra", "lacustrel", "rolandor", "tomoeryu", "valdrisa"]

raw = open(CSV, encoding="utf-8-sig").read()
rows = list(csv.reader(io.StringIO(raw), delimiter=";"))
head = rows[0]
ia, im, ifn, idisp = (head.index(c) for c in ["Área a planejar", "Momento narrativo a planejar", "Função do encontro a planejar", "Disponibilidade a decidir"])
filled = 0
for r in rows[1:]:
    if not r: continue
    k = r[0]; family = k.split(":")[0]
    entries = roles.get(k, [])
    if family in STORY and not entries:
        entries = [("Conforme a história", "", STORY[family], "Nunca selvagem")]
    elif family in KNIGHTS and not entries:
        entries = [("Pós-jogo · Liga dos Campeões ou partes D", "Pós-jogo · Nv.55–65", "Lendário do pós-jogo (luta única)", "Enroscada garantida ao vencer")]
    if not entries: continue
    r[ia] = " · ".join(dict.fromkeys(e[0] for e in entries))
    r[im] = " · ".join(dict.fromkeys(e[1] for e in entries if e[1]))
    r[ifn] = " · ".join(dict.fromkeys(e[2] for e in entries))
    r[idisp] = " · ".join(dict.fromkeys(e[3] for e in entries))
    filled += 1
missing = [k for k in roles if k not in {r[0] for r in rows[1:] if r}]
out = io.StringIO(); csv.writer(out, delimiter=";", lineterminator="\n").writerows(rows)
open(OUT, "w", encoding="utf-8-sig").write(out.getvalue())
print(f"{filled} linhas preenchidas; chaves planejadas fora do CSV: {missing}")
