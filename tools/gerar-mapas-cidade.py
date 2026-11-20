#!/usr/bin/env python3
"""Plantas próprias do Centro e do Condomínio (Lajes), partes A–C.

Até aqui as seis partes eram cópias da planta da Feira do Largo (A, B e C) com
fachadas trocadas. Este gerador escreve um .tmj original por parte em
art/overworld/mapas/, preservando eventos (rivais, saídas, chegadas) do mapa
compilado atual e mantendo as âncoras da história alcançáveis. Depois compile:

    python3 tools/gerar-mapas-cidade.py && node tools/compilar-mapas.mjs kronasta-centro-a ...

Peças usadas (todas já existentes): bambuzal-casa 4×4 (vira prédio no estilo do
bairro; no Centro, a casa em 6,5 recebe o campanário), feira-banca 3×2 (vira
quiosque cívico no Centro e no Condomínio), arvore, banco, poste, vaso, lixeira,
flores, pedra, biruta e pipa-presa.
"""
import json
import os
import subprocess

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
MAPS = os.path.join(ROOT, "art/overworld/mapas")
COMPILED = os.path.join(ROOT, "godot/assets/overworld/maps")
W, H = 48, 40
BASE_REVISION = "01e7fa0c"  # última versão com as plantas copiadas da Feira (eventos originais)
MATERIAL_GID = {"grama": 1, "terra": 2, "mato": 3, "agua": 4, "rocha": 5, "ponte": 6, "piso": 7,
                "calcada": 8, "asfalto": 9, "bosque": 10, "construcao": 11, "canteiro": 12}
LEVEL_GID = {0: 0, 1: 17, 2: 18, 3: 19}
RAMP_FIRSTGID = 201  # embedded tileset: id L = nível L com rampa v- (sobe para o fundo da tela)


def _hash(u, v, salt=0):
    h = (u * 374761393 + v * 668265263 + salt * 982451653) & 0x7FFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0x7FFFFFFF
    return (h % 10000) / 10000.0


class Plan:
    def __init__(self, scene, name, region, part, title):
        self.scene, self.name, self.region, self.part, self.title = scene, name, region, part, title
        self.mat = [["bosque"] * W for _ in range(H)]
        self.lvl = [[0] * W for _ in range(H)]
        self.ramp = [[False] * W for _ in range(H)]
        self.pieces = []
        self.events = []
        self.stairs_info = []
        # harbor: água desenhada nas células de água e muros de arrimo de concreto.
        self.forest = {"market": True, "harbor": True, "nativeProps": True, "closedStairs": True}
        self._next = 5000

    # ---- chão ----
    def rect(self, u0, v0, u1, v1, material, level=0):
        for v in range(v0, v1 + 1):
            for u in range(u0, u1 + 1):
                self.mat[v][u] = material
                self.lvl[v][u] = level
                self.ramp[v][u] = False

    def stairs(self, u, v, width, level):
        """Escada de duas células que sobe para v−: rampas em v e v+1 (nível `level`),
        patamar em v−1 (nível level+1), pé em v+2 (nível `level`)."""
        for du in range(width):
            for dv in (0, 1):
                self.mat[v + dv][u + du] = "terra"
                self.lvl[v + dv][u + du] = level
            self.ramp[v][u + du] = True
        self.stairs_list_add(u, v, width)

    def stairs_list_add(self, u, v, width):
        self.stairs_info.append({"u": u, "v": v, "width": width, "length": 2})

    # ---- peças ----
    def piece(self, asset, u, v, fu=1, fv=1, blocks=True, variant=None, name=None, extra=None):
        props = [{"name": "asset", "type": "string", "value": asset},
                 {"name": "pegada", "type": "string", "value": f"{fu}x{fv}"},
                 {"name": "bloqueia", "type": "bool", "value": blocks}]
        if variant:
            props.append({"name": "variante", "type": "string", "value": variant})
        for k, val in (extra or {}).items():
            props.append({"name": k, "type": "string", "value": val})
        self._next += 1
        self.pieces.append({"id": self._next, "name": name or asset, "type": "peca",
                            "x": u * 32 + 16, "y": v * 32 + 16, "point": True, "properties": props})

    def house(self, u, v, variant="creme", name="Prédio"):
        self.piece("bambuzal-casa", u, v, 4, 4, True, variant, name)

    def kiosk(self, u, v, variant="teal", name="Quiosque"):
        self.piece("feira-banca", u, v, 3, 2, True, variant, name)

    def tree(self, u, v, variant="a", blocks=True):
        """Árvore da moldura (sem colisão). A comum some na frente do caminho, então
        dentro das áreas andáveis usamos a árvore grande do kit (2×2, sempre visível)."""
        if blocks:
            self.piece("arvore-grande", u, v, 2, 2, True, "default", "Árvore")
        else:
            self.piece("arvore", u, v, 1, 1, False, variant, "Árvore")

    def bench(self, u, v, variant="concreto"):
        self.piece("banco", u, v, 2, 1, False, variant, "Banco")

    def post(self, u, v):
        self.piece("poste", u, v, 1, 1, True, "rua", "Poste")

    def item(self, ident, u, v, item, visibility="brilho", name="Material da cidade"):
        self.events.append({"id": ident, "name": name, "type": "item", "x": u * 32 + 16, "y": v * 32 + 16,
                            "point": True, "properties": [
                                {"name": "item", "type": "string", "value": item},
                                {"name": "quantidade", "type": "int", "value": 1},
                                {"name": "visibilidade", "type": "string", "value": visibility}]})

    # ---- eventos preservados do mapa atual ----
    def keep_events(self):
        # Sempre a versão original versionada (antes destas plantas): rodar o gerador
        # de novo não pode reler o mapa que ele mesmo escreveu.
        source = subprocess.run(["git", "show", f"{BASE_REVISION}:godot/assets/overworld/maps/{self.scene}.json"],
                                cwd=ROOT, capture_output=True, text=True, check=True).stdout
        old = json.loads(source)
        for e in old["events"]:
            props = []
            for k, val in e["props"].items():
                kind = "bool" if isinstance(val, bool) else "int" if isinstance(val, int) else "float" if isinstance(val, float) else "string"
                props.append({"name": k, "type": kind, "value": val})
            name = e["name"].replace("Feira ", "")
            self.events.append({"id": e["id"], "name": name, "type": e["type"], "x": e["u"] * 32 + 16,
                                "y": e["v"] * 32 + 16, "point": True, "properties": props})
        return old

    def frame_trees(self):
        """Mata da moldura: árvores sem colisão sobre a mata fechada perto do que se anda."""
        walk = {(u, v) for v in range(H) for u in range(W) if self.mat[v][u] != "bosque"}
        for v in range(H):
            for u in range(W):
                if self.mat[v][u] != "bosque":
                    continue
                near = any((u + du, v + dv) in walk for du in range(-2, 3) for dv in range(-2, 3))
                if _hash(u, v, 31) < (.62 if near else .48):
                    self.tree(u, v, "a" if _hash(u, v, 5) < .5 else "b", blocks=False)

    def write(self):
        chao, altura = [], []
        for v in range(H):
            for u in range(W):
                chao.append(MATERIAL_GID[self.mat[v][u]])
                level = self.lvl[v][u]
                altura.append(RAMP_FIRSTGID + level if self.ramp[v][u] else LEVEL_GID[level])
        forest = dict(self.forest)
        forest["stairs"] = self.stairs_info
        forest["guards"] = []
        ramp_tiles = [{"id": level, "properties": [{"name": "nivel", "type": "int", "value": level},
                                                   {"name": "rampa", "type": "string", "value": "v-"}]} for level in range(4)]
        tmj = {
            "type": "map", "version": "1.10", "orientation": "isometric", "width": W, "height": H,
            "tilewidth": 64, "tileheight": 32, "infinite": False,
            "properties": [
                {"name": "nome", "type": "string", "value": self.title},
                {"name": "regras", "type": "string", "value": "overworld-1"},
                {"name": "bioma", "type": "string", "value": "floresta"},
                {"name": "cena_jogo", "type": "string", "value": self.scene},
                {"name": "regiao", "type": "string", "value": self.region},
                {"name": "parte", "type": "string", "value": self.part},
                {"name": "trajetoria", "type": "string", "value": "1"},
                {"name": "rampa_comprimento", "type": "int", "value": 2},
                {"name": "forest", "type": "string", "value": json.dumps(forest, ensure_ascii=False, separators=(",", ":"))},
            ],
            "tilesets": [
                {"firstgid": 1, "source": "../tiles/rascunho.tsj"},
                {"firstgid": RAMP_FIRSTGID, "name": "rampas-v-menos", "tilewidth": 64, "tileheight": 32, "tilecount": 24,
                 "columns": 8, "image": "../tiles/rascunho.png", "imagewidth": 512, "imageheight": 96, "tiles": ramp_tiles},
            ],
            "layers": [
                {"name": "chao", "type": "tilelayer", "width": W, "height": H, "x": 0, "y": 0, "opacity": 1, "visible": True, "data": chao},
                {"name": "altura", "type": "tilelayer", "width": W, "height": H, "x": 0, "y": 0, "opacity": 1, "visible": True, "data": altura},
                {"name": "pecas", "type": "objectgroup", "objects": self.pieces},
                {"name": "eventos", "type": "objectgroup", "objects": self.events},
            ],
        }
        with open(os.path.join(MAPS, self.scene + ".tmj"), "w") as f:
            json.dump(tmj, f, ensure_ascii=False, indent=1)


# --------------------------------------------------------------------------
# Centro
# --------------------------------------------------------------------------

def centro_a():
    p = Plan("kronasta-centro-a", "Centro", "centro", "A", "Praça da Matriz")
    p.rect(21, 0, 27, 39, "piso")                    # avenida e chegada
    p.rect(4, 4, 20, 22, "grama", 1)                 # terraço da Matriz (oeste)
    p.rect(28, 4, 44, 22, "grama", 1)                # terraço do casario (leste)
    p.rect(8, 9, 17, 20, "piso", 1)                  # adro da igreja
    p.rect(31, 9, 41, 20, "piso", 1)                 # calçadão do casario
    p.rect(10, 23, 38, 36, "piso")                   # Praça da Matriz
    p.rect(21, 25, 27, 29, "rocha", 1)               # mureta ajardinada do chafariz
    p.rect(22, 26, 26, 28, "agua")                   # espelho d'água rebaixado
    p.stairs(13, 23, 4, 0)                           # escadaria da Matriz
    p.stairs(31, 23, 4, 0)                           # escadaria do casario
    p.keep_events()
    p.house(6, 5, "creme", "Igreja Matriz")          # campanário em 6,5
    p.house(12, 5, "azul", "Casa paroquial")
    p.house(5, 13, "coral", "Sobrado")
    p.house(37, 5, "coral", "Sobrado")
    p.house(32, 5, "creme", "Correio")
    p.house(39, 13, "azul", "Banco")
    for v in (4, 14):                                 # alameda da avenida (espaçada)
        p.tree(21, v)
        p.tree(26, v)
    for u, v in [(12, 30), (34, 30)]:
        p.kiosk(u, v, "coral" if u < 24 else "teal", "Quiosque da praça")
    for u, v in [(21, 24), (27, 24), (21, 35), (27, 35), (11, 24), (37, 24)]:
        p.post(u, v)
    for u, v in [(17, 27), (29, 27), (16, 33), (31, 33)]:
        p.bench(u, v)
    for u, v in [(21, 25), (27, 25), (21, 29), (27, 29)]:
        p.piece("flores", u, v, 1, 1, False, ["coral", "amarela"][(u + v) % 2], "Flores do chafariz")
    for u, v in [(15, 11), (11, 18), (35, 11), (40, 19)]:
        p.piece("flores", u, v, 1, 1, False, ["coral", "amarela", "azul"][(u + v) % 3], "Flores")
    for u, v in [(17, 14), (18, 18), (31, 18), (30, 12)]:
        p.tree(u, v, "tronco-largo")
    p.piece("vaso", 20, 9, variant="ceramica", name="Vaso")
    p.piece("vaso", 28, 9, variant="ceramica", name="Vaso")
    p.piece("lixeira", 20, 30, variant="rua", name="Lixeira")
    p.piece("placa-mapa", 25, 36, 2, 1, False, "parque", "Mapa da praça")
    p.item(100, 9, 19, "papel-seda", "escondido")
    p.item(101, 42, 9, "cola-reparo")
    p.frame_trees()
    return p


def centro_b():
    p = Plan("kronasta-centro-b", "Centro", "centro", "B", "Estúdio da Pipa TV")
    p.rect(21, 23, 27, 39, "piso")                   # rua de chegada
    p.rect(12, 25, 36, 36, "piso")                   # largo da emissora
    p.rect(4, 26, 11, 36, "grama")                   # jardim oeste
    p.rect(37, 26, 44, 36, "grama")                  # jardim leste
    p.rect(10, 4, 38, 22, "piso", 1)                 # pátio do estúdio (platô)
    p.rect(22, 0, 26, 3, "piso", 1)                  # saída norte no platô
    p.rect(6, 9, 9, 20, "grama", 1)                  # canteiro lateral
    p.rect(39, 9, 42, 20, "grama", 1)
    p.stairs(22, 23, 5, 0)                           # escadaria principal
    p.keep_events()
    p.house(12, 5, "azul", "Estúdio da Pipa TV")
    p.house(16, 5, "azul", "Estúdio da Pipa TV")
    p.house(32, 5, "coral", "Redação")
    p.house(28, 5, "creme", "Camarins")
    p.kiosk(13, 16, "ochre", "Caminhão de transmissão")
    p.kiosk(33, 16, "teal", "Cabine de luz")
    for u, v in [(21, 6), (27, 6), (20, 18), (28, 18)]:
        p.piece("biruta", u, v, 1, 1, False, "default", "Antena de vento")
    for u, v in [(23, 9), (25, 15)]:
        p.piece("pipa-presa", u, v, 1, 1, False, "default", "Pipa do cenário")
    for u, v in [(14, 28), (32, 28), (14, 34), (32, 34)]:
        p.bench(u, v)
    for u, v in [(12, 26), (36, 26), (12, 36), (36, 36), (21, 22), (27, 22)]:
        p.post(u, v)
    for u, v in [(6, 28), (9, 33), (5, 35), (40, 28), (43, 33), (39, 35), (7, 12), (40, 17)]:
        p.tree(u, v, "florida" if (u + v) % 2 else "a")
    for u, v in [(8, 30), (41, 31)]:
        p.piece("flores", u, v, 1, 1, False, "coral", "Flores")
    p.piece("lixeira", 20, 30, variant="rua", name="Lixeira")
    p.item(102, 5, 30, "linha-encerada", "escondido")
    p.item(103, 37, 20, "papel-seda")
    p.frame_trees()
    return p


def centro_c():
    p = Plan("kronasta-centro-c", "Centro", "centro", "C", "Arena do Centro")
    p.rect(21, 30, 27, 39, "piso")                   # chegada
    p.rect(14, 26, 34, 36, "piso")                   # largo da arena
    p.rect(12, 12, 36, 23, "piso", 1)                # arquibancada baixa
    p.rect(8, 14, 11, 22, "grama", 1)
    p.rect(37, 14, 40, 22, "grama", 1)
    p.rect(14, 1, 34, 9, "piso", 2)                  # ringue no alto
    p.stairs(22, 24, 5, 0)
    p.stairs(22, 10, 5, 1)
    p.forest["landmark"] = {"kind": "arena", "u": 24.5, "v": 5.5}
    p.keep_events()
    p.house(13, 13, "coral", "Bilheteria")
    p.house(31, 13, "azul", "Vestiário")
    for u, v in [(16, 19), (30, 19), (16, 22), (30, 22), (17, 3), (30, 3), (17, 7), (30, 7)]:
        p.bench(u, v)
    for u, v in [(14, 1), (34, 1), (14, 9), (34, 9), (12, 23), (36, 23), (14, 26), (34, 26)]:
        p.post(u, v)
    for u, v in [(9, 15), (10, 20), (38, 16), (39, 21)]:
        p.tree(u, v, "florida")
    for u, v in [(21, 13), (27, 13)]:
        p.piece("biruta", u, v, 1, 1, False, "default", "Bandeira da arena")
    p.piece("vaso", 20, 27, variant="ceramica", name="Vaso")
    p.piece("vaso", 28, 27, variant="ceramica", name="Vaso")
    p.item(104, 39, 18, "cola-reparo")
    p.frame_trees()
    return p


# --------------------------------------------------------------------------
# Condomínio (Lajes)
# --------------------------------------------------------------------------

def lajes_a():
    p = Plan("kronasta-lajes-a", "Condomínio", "lajes", "A", "Portaria e Praça")
    p.rect(21, 32, 27, 39, "piso")                   # calçada de chegada
    p.rect(5, 28, 43, 31, "piso")                    # avenida em frente ao condomínio
    p.rect(5, 27, 43, 27, "construcao")              # muro do condomínio
    p.rect(22, 27, 26, 27, "piso")                   # portão da portaria
    p.rect(8, 14, 40, 26, "piso")                    # praça interna
    p.rect(12, 18, 17, 22, "canteiro")               # canteiros
    p.rect(31, 18, 36, 22, "canteiro")
    p.rect(22, 0, 26, 13, "piso")                    # passagem para o clube
    p.rect(4, 4, 18, 13, "grama", 1)                 # torre oeste
    p.rect(30, 4, 44, 13, "grama", 1)                # torre leste
    p.stairs(8, 14, 4, 0)
    p.stairs(37, 14, 4, 0)
    p.keep_events()
    p.kiosk(28, 24, "teal", "Portaria")
    p.house(5, 5, "creme", "Torre Jacarandá")
    p.house(11, 5, "azul", "Torre Ipê")
    p.house(32, 5, "coral", "Torre Paineira")
    p.house(38, 5, "creme", "Torre Quaresmeira")
    for u, v in [(13, 17), (16, 17), (32, 17), (35, 17)]:
        p.tree(u, v, "florida")
    for u, v in [(19, 20), (28, 20), (19, 24), (10, 24)]:
        p.bench(u, v)
    for u, v in [(21, 26), (27, 26), (13, 16), (35, 16), (6, 29), (42, 29), (21, 31), (27, 31)]:
        p.post(u, v)
    for u, v in [(15, 9), (17, 12), (34, 10), (43, 12)]:
        p.piece("flores", u, v, 1, 1, False, ["azul", "coral", "amarela"][(u + v) % 3], "Flores")
    p.piece("pipa-presa", 24, 20, 1, 1, False, "default", "Pipa no canteiro")
    p.piece("lixeira", 20, 29, variant="rua", name="Lixeira")
    p.item(105, 43, 8, "linha-encerada")
    p.item(106, 6, 11, "papel-seda", "escondido")
    p.frame_trees()
    return p


def lajes_b():
    p = Plan("kronasta-lajes-b", "Condomínio", "lajes", "B", "Clube e Piscina")
    p.rect(7, 4, 41, 32, "piso", 1)                  # deck do clube (elevado)
    p.rect(14, 16, 34, 26, "agua")                   # piscina rebaixada: muros de concreto até a água
    p.rect(22, 0, 26, 3, "piso", 1)                  # saída para o terraço
    p.rect(3, 12, 6, 30, "grama", 1)                 # jardim do clube
    p.rect(42, 12, 45, 30, "grama", 1)
    p.rect(21, 31, 27, 39, "piso")                   # alameda de chegada (térreo)
    p.stairs(22, 29, 5, 0)                           # escadaria da alameda ao deck
    p.keep_events()
    p.house(9, 5, "azul", "Sede do clube")
    p.house(35, 5, "creme", "Vestiários")
    p.kiosk(15, 7, "coral", "Lanchonete")
    p.kiosk(31, 7, "ochre", "Bar da piscina")
    for u in range(15, 34, 4):
        p.bench(u, 14)
        if not 20 < u < 27:
            p.bench(u, 29 if u in (15, 31) else 28)
    for u, v in [(4, 14), (5, 20), (4, 27), (43, 15), (44, 21), (43, 28)]:
        p.tree(u, v, "florida" if (u + v) % 2 else "b")
    for u, v in [(13, 15), (35, 15), (11, 29), (37, 29), (21, 32), (27, 32)]:
        p.post(u, v)
    for u, v in [(10, 18), (38, 22)]:
        p.piece("biruta", u, v, 1, 1, False, "default", "Guarda-sol")
    for u, v in [(9, 30), (39, 30), (9, 11), (39, 11)]:
        p.piece("vaso", u, v, variant="ceramica", name="Vaso")
    p.item(107, 4, 22, "cola-reparo", "escondido")
    p.item(108, 40, 13, "papel-seda")
    p.frame_trees()
    return p


def lajes_c():
    p = Plan("kronasta-lajes-c", "Condomínio", "lajes", "C", "Terraço do Condomínio")
    p.rect(21, 30, 27, 39, "piso")                   # hall de entrada
    p.rect(14, 26, 34, 36, "piso")                   # saguão térreo
    p.rect(10, 15, 38, 23, "piso", 1)                # jardim suspenso
    p.rect(14, 2, 34, 12, "piso", 2)                 # cobertura
    p.rect(17, 3, 20, 5, "canteiro", 2)              # floreiras da cobertura
    p.rect(28, 3, 31, 5, "canteiro", 2)
    p.stairs(22, 24, 5, 0)
    p.stairs(22, 13, 5, 1)
    p.forest["landmark"] = {"kind": "arena", "u": 24.5, "v": 7.5}
    p.keep_events()
    p.house(11, 16, "creme", "Casa de máquinas")
    p.house(34, 16, "azul", "Salão de festas")
    for u, v in [(16, 18), (30, 18), (16, 22), (30, 22)]:
        p.bench(u, v)
    for u, v in [(15, 20), (32, 20), (21, 16), (27, 16)]:
        p.piece("vaso", u, v, variant="ceramica", name="Vaso")
    for u, v in [(14, 2), (34, 2), (14, 12), (34, 12), (10, 23), (38, 23), (14, 26), (34, 26)]:
        p.post(u, v)
    for u, v in [(18, 4), (29, 4)]:
        p.piece("flores", u, v, 1, 1, False, "amarela", "Flores")
    p.piece("biruta", 33, 6, 1, 1, False, "default", "Biruta da cobertura")
    p.item(109, 37, 21, "linha-encerada")
    p.frame_trees()
    return p


if __name__ == "__main__":
    for build in (centro_a, centro_b, centro_c, lajes_a, lajes_b, lajes_c):
        plan = build()
        plan.write()
        print("escrito", plan.scene, len(plan.pieces), "peças", len(plan.events), "eventos")
