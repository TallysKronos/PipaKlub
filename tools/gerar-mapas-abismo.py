#!/usr/bin/env python3
"""Abismo de Kronasta (região submersa, exploração), áreas A–D.

Quatro mapas de recife no fundo do mar, ligados em sequência (o alto de cada um chega no pé
do seguinte). Só se entra montado numa montaria aquática (mount_passives.gd; a Capiboia).
Em D fica a arena do chefe (Coromar, kind "abismo-boss").

Cada mapa é um labirinto: uma grade de corredores (3 células de largura) escavada entre
paredões de recife, gerada de forma determinística a partir de uma semente. A grade é dividida
em faixas de altura (o mapa sobe para o fundo da tela); onde um corredor cruza de uma faixa
para a de cima há uma escada. Salões abertos interrompem o labirinto; becos sem saída guardam
baús (peça "bau" com item e quantidade, abertos em bosque_campaign.gd).

Matéria (forest.submerged, renderizador submerged_structures.gd):
  piso = areia · grama = leito com limo · bosque = abismo escuro entre os recifes

    python3 tools/gerar-mapas-abismo.py && node tools/compilar-mapas.mjs abismo-a abismo-b abismo-c abismo-d
"""
import importlib.util
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("morro", os.path.join(HERE, "gerar-mapas-morro.py"))
morro = importlib.util.module_from_spec(spec)
spec.loader.exec_module(morro)
W, H, cidade = morro.W, morro.H, morro.cidade

PITCH, CORR = 5, 3                # passo da grade e largura do corredor
COLS, ROWS = 12, 10               # células da grade
U0, V0 = 2, 1                     # canto do primeiro corredor


def cu(i):
    return U0 + i * PITCH


def cv(j):
    return V0 + j * PITCH


class Abismo(morro.Morro):
    def __init__(self, part, title, seed, depth, bands, event_base):
        super().__init__(0)
        self.scene = self.game_scene = "abismo-" + part
        self.name, self.region, self.part, self.title = "Abismo de Kronasta", "abismo", part.upper(), "Abismo de Kronasta · " + title
        self.mat = [["bosque"] * W for _ in range(H)]         # abismo entre os recifes (escuro)
        self.forest = {"submerged": True, "baseLevel": 1, "softTone": True, "depth": depth, "nativeProps": True,
                       "closedStairs": True, "trails": [], "shots": []}
        self._event_id = event_base
        self._item_id = event_base + 50
        self._chest = 0
        self.rng = random.Random(seed)
        self.bands = bands          # nível relativo de cada linha da grade (len ROWS)
        self.open = set()           # células da grade usadas
        self.links = set()          # ligações entre células ((i, j), (i2, j2))
        self.rooms = []

    # ---- escrita do bioma ----
    def write(self):
        super().write()
        import json
        path = os.path.join(cidade.MAPS, self.scene + ".tmj")
        tmj = json.load(open(path))
        for prop in tmj["properties"]:
            if prop["name"] == "bioma":
                prop["value"] = "floresta"
        json.dump(tmj, open(path, "w"), ensure_ascii=False, indent=1)

    # ---- labirinto ----
    def maze(self, skip=(), start=(6, ROWS - 1), extra=10):
        """Labirinto perfeito (busca em profundidade com retrocesso) nas células fora de
        `skip`, mais `extra` ligações a mais para abrir laços (rotas alternativas)."""
        cells = {(i, j) for i in range(COLS) for j in range(ROWS)} - set(skip)
        stack, seen = [start], {start}
        while stack:
            i, j = stack[-1]
            options = [(i + di, j + dj) for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)) if (i + di, j + dj) in cells and (i + di, j + dj) not in seen]
            if not options:
                stack.pop()
                continue
            nxt = self.rng.choice(options)
            seen.add(nxt)
            self.links.add(tuple(sorted(((i, j), nxt))))
            stack.append(nxt)
        self.open |= seen
        candidates = [tuple(sorted(((i, j), (i + di, j + dj)))) for (i, j) in seen for di, dj in ((1, 0), (0, 1))
                      if (i + di, j + dj) in seen and tuple(sorted(((i, j), (i + di, j + dj)))) not in self.links]
        self.rng.shuffle(candidates)
        for a, b in candidates[:extra]:
            self.links.add((a, b))

    def carve(self):
        """Escava corredores e ligações; escadas onde a ligação sobe de faixa."""
        for (i, j) in self.open:
            mat = "piso" if (i + j) % 3 else "grama"
            self.rect(cu(i), cv(j), cu(i) + CORR - 1, cv(j) + CORR - 1, mat, self.bands[j])
        for link in sorted(self.links):
            (i, j), (i2, j2) = sorted(link, key=lambda c: (c[1], c[0]))
            if j == j2:     # horizontal: mesma faixa
                lo = min(i, i2)
                self.rect(cu(lo) + CORR, cv(j), cu(lo) + PITCH - 1, cv(j) + CORR - 1, "piso", self.bands[j])
            else:           # vertical: j2 = j + 1 (abaixo)
                upper, lower = self.bands[j], self.bands[j2]
                gap_v = cv(j2) - (PITCH - CORR)
                if upper == lower:
                    self.rect(cu(i), gap_v, cu(i) + CORR - 1, cv(j2) - 1, "piso", lower)
                else:
                    assert upper == lower + 1, f"ligação sobe dois níveis em {a}-{b}"
                    self.stairs(cu(i), gap_v, CORR, lower)

    def room(self, i0, j0, i1, j1, material="piso"):
        """Salão aberto cobrindo as células (i0…i1, j0…j1) de uma mesma faixa."""
        level = self.bands[j0]
        assert all(self.bands[j] == level for j in range(j0, j1 + 1)), "salão em faixas diferentes"
        self.rect(cu(i0), cv(j0), cu(i1) + CORR - 1, cv(j1) + CORR - 1, material, level)
        self.rooms.append((i0, j0, i1, j1))
        for i in range(i0, i1 + 1):
            for j in range(j0, j1 + 1):
                self.open.add((i, j))

    def degree(self, cell):
        return sum(1 for a, b in self.links if cell in (a, b))

    def dead_ends(self, avoid=()):
        inside_room = {(i, j) for (i0, j0, i1, j1) in self.rooms for i in range(i0, i1 + 1) for j in range(j0, j1 + 1)}
        return sorted(c for c in self.open if self.degree(c) == 1 and c not in inside_room and c not in avoid)

    def center(self, cell):
        i, j = cell
        return cu(i) + 1, cv(j) + 1

    # ---- peças e eventos ----
    def bau(self, cell, item, amount):
        u, v = self.center(cell)
        self._chest += 1
        self.piece("bau", u, v, 1, 1, True, "fechado", "Baú do recife", {"item": item, "quantidade": str(amount)})

    def prop(self, kind, u, v, fu, fv, name, blocks=True):
        for dv in range(fv):
            for du in range(fu):
                assert not self.ramp[v + dv][u + du], f"{kind} sobre escada em {u},{v}"
        self.piece("submerso-prop", u, v, fu, fv, blocks, kind, name)

    def baliza(self, cell):
        i, j = cell                                   # fileira do meio: longe do pé e do patamar das escadas
        self.piece("submerso-marker", cu(i) + 2, cv(j) + 1, 1, 1, True, "baliza", "Baliza de mergulho")

    def entry(self, i, back_scene, back_u, name):
        u = cu(i) + 1
        self.rect(cu(i), cv(ROWS - 1) + CORR, cu(i) + CORR - 1, H - 1, "piso", self.bands[ROWS - 1])
        self.event("entrada", "Chegada", u, H - 3, {})
        props = {"destino": back_scene}
        if back_scene != "kronasta":
            props.update({"chegada_u": back_u, "chegada_v": 1})
        self.event("saida", name, u, H - 1, props)
        return u

    def exit(self, i, next_scene, next_u, name):
        u = cu(i) + 1
        self.rect(cu(i), 0, cu(i) + CORR - 1, cv(0) - 1 if cv(0) > 0 else 0, "piso", self.bands[0])
        self.event("saida", name, u, 0, {"destino": next_scene, "chegada_u": next_u, "chegada_v": H - 4})

    def decorate(self, density=.16):
        """Algas sobre o paredão, junto dos corredores (sem colisão nova), e pedrinhas."""
        walk = {(u, v) for v in range(H) for u in range(W) if self.mat[v][u] in ("piso", "grama") or self.ramp[v][u]}
        taken = {(int(p["x"]) // 32, int(p["y"]) // 32) for p in self.pieces}
        for v in range(H):
            for u in range(W):
                if self.mat[v][u] != "bosque" or (u, v) in taken:
                    continue
                near = any((u + du, v + dv) in walk for du in (-1, 0, 1) for dv in (-1, 0, 1))
                if near and cidade._hash(u, v, 61) < density:
                    self.piece("submerso-prop", u, v, 1, 1, False, "alga", "Alga")


REWARDS = [("moedas", 30), ("papel-seda", 3), ("linha-encerada", 2), ("cola-reparo", 2), ("moedas", 50),
           ("kit-remendo", 1), ("vareta-bambu", 3), ("moedas", 80)]


def fill_chests(p, count, avoid=()):
    ends = p.dead_ends(avoid)
    p.rng.shuffle(ends)
    for k, cell in enumerate(ends[:count]):
        item, amount = REWARDS[(k + p._event_id // 100) % len(REWARDS)]
        p.bau(cell, item, amount)
    return ends[:count]


def area_a():
    """Recife da Entrada (3 faixas). O labirinto é mais aberto: dois salões de coral e uma
    fossa funda atravessada por um arco de pedra."""
    bands = [2, 2, 2, 1, 1, 1, 0, 0, 0, 0]
    p = Abismo("a", "Recife da Entrada", 1101, 0, bands, 24000)
    p.maze(skip=[(2, 7), (3, 7), (2, 8), (3, 8), (8, 4), (9, 4), (8, 5), (9, 5)], start=(6, 9), extra=12)
    p.carve()
    p.room(2, 7, 3, 8, "grama")                       # jardim de coral (sul-oeste)
    p.room(8, 4, 9, 5)                                # salão da arraia
    p.links |= {((1, 7), (2, 7)), ((3, 8), (4, 8)), ((7, 4), (8, 4)), ((9, 5), (10, 5))}
    p.carve()
    u_in = p.entry(6, "kronasta", 0, "Voltar à superfície")
    p.exit(5, "abismo-b", cu(5) + 1, "Descer pela fenda")
    p.prop("colonia", cu(2) + 1, cv(7) + 1, 3, 3, "Colônia de coral")
    p.prop("coral", cu(8) + 2, cv(4) + 1, 2, 2, "Coral")
    p.prop("espirao", cu(9) + 1, cv(5), 2, 2, "Espirão de coral")
    p.placa("Recife da Entrada", u_in + 1, H - 5, "A luz ainda chega aqui. A Boia nada devagar, e o Kael segura firme. Quanto mais fundo, mais escuro o recife fica.")
    p.placa("Jardim de coral", cu(3) + 2, cv(8) + 2, "Corais crescem em volta de uma pipa antiga presa na pedra. A rabiola balança como se ainda houvesse vento.")
    p.event("interacao", "Bolha de ar", cu(9) + 2, cv(4) + 2, {"acao": "wildRest"})
    fill_chests(p, 6, avoid=[(6, 9), (5, 0)])
    for cell in [(6, 8), (6, 6), (5, 3), (5, 1)]:
        if cell in p.open:
            p.baliza(cell)
    p.decorate()
    for name, u, v in [("entrada", u_in, H - 6), ("jardim", cu(2) + 3, cv(7) + 3), ("arraia", cu(8) + 3, cv(4) + 3), ("saida", cu(5) + 1, 3)]:
        p.shot(name, u, v)
    return p


def area_b():
    """Labirinto de Algas (4 faixas). Corredores estreitos e muitos becos, um salão alto de
    algas gigantes e a Gruta do Eco, sem saída."""
    bands = [3, 3, 2, 2, 2, 1, 1, 0, 0, 0]
    p = Abismo("b", "Labirinto de Algas", 2207, 1, bands, 24100)
    p.maze(skip=[(1, 2), (2, 2), (1, 3), (2, 3), (1, 4), (2, 4), (9, 7), (10, 7), (9, 8), (10, 8)], start=(5, 9), extra=8)
    p.carve()
    p.room(1, 2, 2, 4, "grama")                       # salão das algas gigantes
    p.room(9, 7, 10, 8)                               # gruta do eco
    p.links |= {((3, 3), (2, 3)), ((8, 8), (9, 8))}
    p.carve()
    u_in = p.entry(5, "abismo-a", cu(5) + 1, "Subir para o Recife da Entrada")
    p.exit(7, "abismo-c", cu(7) + 1, "Descer para a Cidade Afundada")
    for k, (u, v) in enumerate([(cu(1), cv(2)), (cu(2) + 1, cv(2) + 1), (cu(1) + 1, cv(3) + 2), (cu(2), cv(4))]):
        p.prop("alga", u, v, 1, 1, "Alga gigante")
    p.prop("colonia", cu(9) + 1, cv(7) + 1, 3, 3, "Colônia do eco")
    p.placa("Gruta do Eco", cu(10) + 1, cv(8) + 1, "Qualquer som volta três vezes. No fundo, alguém riscou setas apontando para baixo.")
    p.placa("Algas gigantes", cu(1) + 2, cv(4) + 2, "As algas sobem tão alto que somem no escuro. A Boia passa entre elas sem encostar em nenhuma.")
    p.event("interacao", "Bolha de ar", cu(2) + 2, cv(3), {"acao": "wildRest"})
    fill_chests(p, 7, avoid=[(5, 9), (7, 0)])
    for cell in [(5, 8), (6, 6), (7, 4), (7, 2)]:
        if cell in p.open:
            p.baliza(cell)
    p.decorate(.22)
    for name, u, v in [("entrada", u_in, H - 6), ("algas", cu(1) + 3, cv(3) + 1), ("eco", cu(9) + 3, cv(7) + 3), ("saida", cu(7) + 1, 3)]:
        p.shot(name, u, v)
    return p


def area_c():
    """Cidade Afundada (4 faixas). Ruínas de uma vila antiga: praças retangulares (o desenho
    construído é intencional), uma fossa cortando o meio e um arco de pedra."""
    bands = [3, 3, 3, 2, 2, 2, 1, 1, 0, 0]
    p = Abismo("c", "Cidade Afundada", 3313, 2, bands, 24200)
    skip = [(4, 3), (5, 3), (6, 3), (7, 3), (4, 4), (5, 4), (6, 4), (7, 4), (0, 6), (1, 6), (0, 7), (1, 7)]
    p.maze(skip=skip, start=(8, 9), extra=10)
    p.carve()
    p.room(4, 3, 7, 4)                                # praça da vila
    p.room(0, 6, 1, 7, "grama")                       # jardim da casa afundada (sem saída)
    p.links |= {((3, 3), (4, 3)), ((7, 4), (8, 4)), ((5, 2), (5, 3)), ((2, 7), (1, 7))}
    p.carve()
    u_in = p.entry(8, "abismo-b", cu(7) + 1, "Subir para o Labirinto de Algas")
    p.exit(3, "abismo-d", cu(6) + 1, "Descer para o Trono das Marés")
    p.prop("espirao", cu(4) + 1, cv(3) + 1, 2, 2, "Coluna da praça")
    p.prop("espirao", cu(7) + 1, cv(3) + 1, 2, 2, "Coluna da praça")
    p.prop("colonia", cu(5) + 2, cv(4), 3, 3, "Fonte de coral")
    p.placa("Praça da vila", cu(4) + 3, cv(4) + 2, "Uma praça inteira no fundo do mar. Nas pedras, desenhos de pipas iguais às de Kronasta.")
    p.placa("Casa afundada", cu(0) + 1, cv(7) + 1, "Uma porta sem casa. Do lado de dentro, um carretel de linha ainda enrolado.")
    p.event("interacao", "Bolha de ar", cu(6) + 2, cv(3) + 1, {"acao": "wildRest"})
    fill_chests(p, 7, avoid=[(8, 9), (3, 0)])
    for cell in [(8, 8), (8, 6), (7, 5), (3, 2), (3, 1)]:
        if cell in p.open:
            p.baliza(cell)
    p.decorate(.18)
    for name, u, v in [("entrada", u_in, H - 6), ("praca", cu(5) + 3, cv(3) + 3), ("casa", cu(0) + 3, cv(6) + 3), ("saida", cu(3) + 1, 3)]:
        p.shot(name, u, v)
    return p


def area_d():
    """Trono das Marés (4 faixas). O último labirinto, o mais escuro, sobe até a arena: um
    salão largo de areia cercado de corais onde o Coromar espera. Atrás dele, o santuário."""
    bands = [3, 3, 3, 2, 2, 2, 1, 1, 0, 0]
    p = Abismo("d", "Trono das Marés", 4421, 3, bands, 24300)
    arena = [(i, j) for i in range(3, 9) for j in range(0, 3)]
    p.maze(skip=arena, start=(6, 9), extra=9)
    p.carve()
    p.room(3, 0, 8, 2)                                # arena do Coromar
    p.links |= {((5, 3), (5, 2)), ((2, 1), (3, 1)), ((8, 1), (9, 1))}
    p.carve()
    u_in = p.entry(6, "abismo-c", cu(3) + 1, "Subir para a Cidade Afundada")
    # Santuário atrás da arena (só depois da vitória): faixa estreita no alto.
    p.rect(cu(5), 0, cu(6) + CORR - 1, 0, "grama", bands[0])
    for u, v in [(cu(3), cv(0)), (cu(8) + 1, cv(0)), (cu(3), cv(2) + 1), (cu(8) + 1, cv(2) + 1)]:
        p.prop("coral", u, v, 2, 2, "Coral da arena")
    p.prop("espirao", cu(3) + 3, cv(1), 2, 2, "Espirão da arena")
    p.prop("espirao", cu(7) + 2, cv(1), 2, 2, "Espirão da arena")
    boss_u, boss_v = cu(5) + 3, cv(1) + 1
    p.event("npc", "Coromar", boss_u, boss_v, {"acao": "abismoBoss", "storySpritePath": "res://assets/campaign/abismo-v1/coromar.png", "ocultar_apos": "abismoCoromarVencido", "bloqueia": True})
    p.placa("Trono das Marés", boss_u - 4, cv(2) + 2, "A areia forma ondas em volta de um trono de coral. Quatro marcas no chão, uma para cada maré.")
    p.event("interacao", "Santuário das Marés", cu(6) + 1, 0, {"texto": "Uma pipa de nácar presa no coral. Dizem que só o Coromar decide quem pode levá-la para a superfície.", "requer": "abismoCoromarVencido"})
    p.event("interacao", "Bolha de ar", cu(6) + 1, cv(5) + 1, {"acao": "wildRest"})
    fill_chests(p, 6, avoid=[(6, 9)])
    p.item(p._item_id + 10, cu(5) + 1, 0, "linha-encerada", "brilho", "Linha das marés")
    p.events[-1]["properties"].append({"name": "requer", "type": "string", "value": "abismoCoromarVencido"})
    for cell in [(6, 8), (6, 6), (5, 4)]:
        if cell in p.open:
            p.baliza(cell)
    p.decorate(.2)
    for name, u, v in [("entrada", u_in, H - 6), ("meio", cu(5) + 1, cv(5) + 1), ("arena", boss_u, boss_v + 2), ("santuario", cu(6), 2)]:
        p.shot(name, u, v)
    return p


AREAS = {"a": area_a, "b": area_b, "c": area_c, "d": area_d}

if __name__ == "__main__":
    for key in (sys.argv[1:] or sorted(AREAS)):
        plan = AREAS[key]()
        plan.write()
        print("escrito", plan.scene, len(plan.pieces), "peças", len(plan.events), "eventos", plan._chest, "baús")
