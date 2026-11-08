#!/usr/bin/env python3
"""Morro do Sol (bairro 1, ato 1) no modelo isométrico de Kronasta, áreas A–E.

Até 08/11 o Morro era o único bairro com mapa pintado: cinco imagens vistas de cima
(assets/campaign/morro/*.png) com colisão em retângulos, numa tela própria (morro_view.gd).
Este gerador escreve um .tmj por área em art/overworld/mapas/ no mesmo sistema dos outros
bairros. Cada área sobe o morro: chegada embaixo (v alto), saída para a próxima área no
alto (v baixo), por escadarias. A cena de jogo continua a mesma ("morro", "morro-area-2"…),
assim saves, desafios, estrelas e a defesa de título não mudam.

    python3 tools/gerar-mapas-morro.py && node tools/compilar-mapas.mjs kronasta-morro-a ... kronasta-morro-e

Rivais (evento npc, acao morroDuel):
  A Zeca (morro-1) · B Bia (morro-2) · C Juninho e Lia (morro-3) · D Tião (morro-4) · E Mikka (morro-5)
"""
import importlib.util
import os

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("cidade", os.path.join(HERE, "gerar-mapas-cidade.py"))
cidade = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cidade)
Plan, W, H = cidade.Plan, cidade.W, cidade.H

SCENES = ["morro", "morro-area-2", "morro-area-3", "morro-area-4", "morro-area-5"]
NAMES = ["Praça da Chegada", "Escadaria da Sombra", "Laje dos Ventos", "Mirante da Caixa-d’água", "Praça da Campeã"]
CASAS = ["rosa", "creme", "amarela", "azul", "verde"]


class Morro(Plan):
    def __init__(self, index):
        self.index = index
        scene_id = "kronasta-morro-" + "abcde"[index]
        super().__init__(scene_id, "Morro do Sol", "morro", "ABCDE"[index], "Morro do Sol · " + NAMES[index])
        self.game_scene = SCENES[index]
        self.forest = {"market": True, "nativeProps": True, "closedStairs": True}
        self.casa_n = 0
        self._event_id = 21000 + index * 20

    def eid(self):
        self._event_id += 1
        return self._event_id

    def event(self, kind, name, u, v, props, ident=None):
        out = []
        for k, val in props.items():
            t = "bool" if isinstance(val, bool) else "int" if isinstance(val, int) else "float" if isinstance(val, float) else "string"
            out.append({"name": k, "type": t, "value": val})
        self.events.append({"id": ident or self.eid(), "name": name, "type": kind, "x": u * 32 + 16, "y": v * 32 + 16,
                            "point": True, "properties": out})

    def casa(self, u, v, name="Casa"):
        # Casa fora do caminho ganha um lote de quintal (grama) no nível da rua ao lado,
        # para não afundar no mato da moldura.
        level = None
        for fu, fv in [(u + 1, v + 4), (u + 2, v + 4), (u + 4, v + 1), (u - 1, v + 1), (u + 1, v - 1)]:
            if 0 <= fu < W and 0 <= fv < H and self.mat[fv][fu] != "bosque" and not self.ramp[fv][fu]:
                level = self.lvl[fv][fu]
                break
        for dv in range(4):
            for du in range(4):
                if self.mat[v + dv][u + du] == "bosque":
                    self.mat[v + dv][u + du] = "grama"
                    self.lvl[v + dv][u + du] = level if level is not None else self.lvl[v + dv][u + du]
        self.house(u, v, CASAS[(self.casa_n + self.index) % len(CASAS)], name)
        self.casa_n += 1

    def rival(self, name, u, v, stage, identity=None, sprite=None):
        props = {"acao": "morroDuel", "district": "morro", "duel": stage, "bloqueia": False}
        if identity:
            props["npcIdentity"] = identity
        if sprite:
            props["storySpritePath"] = sprite
        self.event("npc", name, u, v, props)

    def arrival(self, back_scene, back_u=24, back_v=1, name="Voltar"):
        """Chegada embaixo (v 37) e saída de volta (v 39)."""
        self.rect(21, 33, 27, 39, "piso", 0)
        self.event("entrada", "Chegada", 24, 37, {})
        props = {"destino": back_scene}
        if back_scene != "quintal":
            props.update({"chegada_u": back_u, "chegada_v": back_v})
        self.event("saida", name, 24, 39, props)

    def onward(self, next_scene, top_level, name):
        """Saída no alto (v 0): só abre depois de vencer o desafio da área (gate em park_checkpoint)."""
        self.rect(22, 0, 26, 1, "piso", top_level)
        props = {"destino": next_scene, "morroGate": "morro-%d" % (self.index + 1)}
        if next_scene != "quintal":
            props.update({"chegada_u": 24, "chegada_v": 36})
        self.event("saida", name, 24, 0, props)

    def flowers(self, cells):
        for u, v in cells:
            self.piece("flores", u, v, 1, 1, False, ["coral", "amarela", "azul"][(u + v) % 3], "Flores")

    def posts(self, cells):
        for u, v in cells[::2]:                     # poste sim, mas sem floresta de postes
            self.post(u, v)

    def kites(self, cells):
        for u, v in cells:
            self.piece("pipa-presa", u, v, 1, 1, False, "default", "Pipa presa")

    def write(self):
        super().write()
        import json
        path = os.path.join(cidade.MAPS, self.scene + ".tmj")
        tmj = json.load(open(path))
        for prop in tmj["properties"]:
            if prop["name"] == "cena_jogo":
                prop["value"] = self.game_scene
            if prop["name"] == "bioma":
                prop["value"] = "morro"
        json.dump(tmj, open(path, "w"), ensure_ascii=False, indent=1)


def area_a():
    """Praça da Chegada: a praça embaixo, a oficina de pipas, o Zeca no meio e a escadaria
    que sobe em dois lances até a passagem para a Escadaria da Sombra."""
    p = Morro(0)
    p.arrival("quintal", name="Voltar à Rua dos Ventos")
    p.rect(13, 32, 20, 37, "piso", 0)               # beco das casas da entrada (oeste)
    p.rect(28, 32, 35, 37, "piso", 0)               # beco leste
    p.rect(6, 20, 42, 31, "piso", 0)                # praça
    p.rect(16, 25, 19, 28, "canteiro", 0)
    p.rect(29, 25, 32, 28, "canteiro", 0)
    p.rect(4, 8, 44, 17, "piso", 1)                 # patamar das casas
    p.rect(18, 2, 30, 5, "piso", 2)                 # largo da caixa-d'água
    p.stairs(22, 18, 5, 0)                          # primeiro lance
    p.stairs(22, 6, 5, 1)                           # segundo lance
    p.onward("morro-area-2", 2, "Seguir para a Escadaria da Sombra")
    p.rival("Zeca", 24, 23, "morro-1", identity="zeca")
    p.event("interacao", "Oficina de pipas", 9, 25, {"texto": "Na oficina da praça, cada pipa começa com bambu, papel e um pouco de paciência. Os moradores usam a caixa-d’água para indicar o caminho: suba a escadaria e encontre o patamar do bairro."})
    p.kiosk(7, 22, "teal", "Oficina de pipas")
    p.casa(14, 33); p.casa(30, 33)
    p.casa(37, 21, "Mercadinho do Morro")
    p.casa(5, 9); p.casa(10, 9); p.casa(33, 9); p.casa(38, 9)
    p.casa(14, 12, "Casa do patamar"); p.casa(29, 12)
    p.tree(17, 26); p.tree(30, 26)
    for u, v in [(12, 29), (34, 29), (20, 21), (27, 21)]:
        p.bench(u, v, "madeira")
    p.posts([(21, 31), (27, 31), (7, 30), (41, 30), (21, 16), (27, 16), (19, 3), (29, 3)])
    p.flowers([(6, 31), (42, 21), (20, 14), (28, 14), (9, 16), (39, 16)])
    p.kites([(36, 30), (11, 21)])
    p.piece("biruta", 41, 25, 1, 1, True, "default", "Biruta")
    p.piece("lixeira", 20, 30, variant="rua", name="Lixeira")
    p.item(21001 + 18, 43, 15, "papel-seda", "escondido")
    p.item(21001 + 19, 5, 22, "linha-encerada")
    p.frame_trees()
    return p


def area_b():
    """Escadaria da Sombra: becos estreitos entre casas, uma escadaria longa e a Bia
    debaixo da árvore grande no patamar do meio."""
    p = Morro(1)
    p.arrival("morro", 24, 1, "Voltar para a Praça da Chegada")
    p.rect(18, 28, 30, 32, "piso", 0)               # pé da escadaria
    p.rect(8, 29, 17, 31, "piso", 0)                # beco oeste
    p.rect(31, 29, 40, 31, "piso", 0)               # beco leste
    p.rect(12, 16, 36, 25, "piso", 1)               # patamar da sombra
    p.rect(20, 3, 28, 13, "piso", 2)                # alto da escadaria
    p.rect(29, 6, 37, 10, "piso", 2)                # varanda do alto
    p.stairs(22, 26, 5, 0)
    p.stairs(22, 14, 5, 1)
    p.onward("morro-area-3", 2, "Seguir para a Laje dos Ventos")
    p.rect(22, 2, 26, 2, "piso", 2)
    p.rival("Bia", 26, 20, "morro-2", identity="bia")
    p.tree(28, 18)                                  # a árvore da sombra
    p.tree(15, 19)
    p.casa(9, 32); p.casa(35, 32)
    p.casa(8, 24); p.casa(37, 24)
    p.casa(12, 13); p.casa(31, 13)
    p.casa(15, 4); p.casa(33, 2)
    for u, v in [(18, 23), (31, 22)]:
        p.bench(u, v, "madeira")
    p.posts([(19, 28), (29, 28), (13, 17), (35, 17), (21, 12), (27, 12), (21, 4), (27, 4)])
    p.flowers([(12, 25), (36, 25), (9, 30), (39, 30), (30, 9), (36, 7)])
    p.kites([(34, 6), (13, 22)])
    p.item(21021 + 18, 36, 8, "cola-reparo", "escondido")
    p.frame_trees()
    return p


def area_c():
    """Laje dos Ventos: a laje grande dos meninos (Juninho e Lia), varais e pipas presas,
    com uma laje mais alta de onde se vê a próxima subida."""
    p = Morro(2)
    p.arrival("morro-area-2", 24, 1, "Voltar para a Escadaria da Sombra")
    p.rect(10, 25, 38, 32, "piso", 0)               # rua de baixo
    p.rect(8, 12, 40, 22, "piso", 1)                # laje grande
    p.rect(30, 4, 40, 9, "piso", 2)                 # laje alta (leste)
    p.rect(19, 3, 29, 9, "piso", 2)                 # passagem alta
    p.stairs(22, 23, 5, 0)
    p.stairs(22, 10, 5, 1)
    p.onward("morro-area-4", 2, "Seguir para o Mirante da Caixa-d’água")
    p.rect(22, 2, 26, 2, "piso", 2)
    p.rival("Juninho", 23, 16, "morro-3", identity="juninho")
    p.rival("Lia", 26, 16, "morro-3", identity="lia")
    p.casa(11, 27, "Casa da rua de baixo"); p.casa(33, 27)
    p.casa(4, 13); p.casa(41, 13)
    p.casa(9, 3); p.casa(14, 4)
    p.kiosk(10, 17, "coral", "Varal da laje")
    p.kiosk(35, 17, "teal", "Varal da laje")
    p.kites([(14, 14), (32, 13), (38, 6), (17, 20)])
    p.piece("biruta", 39, 5, 1, 1, True, "default", "Biruta da laje")
    for u, v in [(15, 30), (30, 30)]:
        p.bench(u, v, "concreto")
    p.posts([(21, 26), (27, 26), (9, 12), (39, 12), (21, 9), (27, 9)])
    p.flowers([(9, 21), (39, 21), (31, 8), (19, 8)])
    p.item(21041 + 18, 39, 4, "papel-seda")
    p.item(21041 + 19, 9, 31, "linha-encerada", "escondido")
    p.frame_trees()
    return p


def area_d():
    """Mirante da Caixa-d'água: a caixa-d'água no alto, o Tião no mirante e a última
    escadaria para a praça da campeã."""
    p = Morro(3)
    p.arrival("morro-area-3", 24, 1, "Voltar para a Laje dos Ventos")
    p.rect(14, 27, 34, 32, "piso", 0)               # largo de baixo
    p.rect(6, 14, 42, 24, "piso", 1)                # mirante
    p.rect(8, 16, 13, 20, "canteiro", 1)
    p.rect(17, 3, 31, 11, "piso", 2)                # base da caixa-d'água
    p.stairs(22, 25, 5, 0)
    p.stairs(22, 12, 5, 1)
    p.onward("morro-area-5", 2, "Seguir para a Praça da Campeã")
    p.rect(22, 2, 26, 2, "piso", 2)
    p.rival("Tião", 30, 19, "morro-4", identity="tiao")
    p.piece("cais-mastro", 18, 5, 2, 2, True, None, "Caixa-d’água do Morro")
    p.casa(15, 28); p.casa(29, 28)
    p.casa(7, 25); p.casa(37, 25)
    p.casa(36, 16, "Casa do mirante")
    p.casa(9, 6); p.casa(34, 6)
    p.tree(10, 17)
    for u, v in [(16, 22), (24, 21), (32, 23)]:
        p.bench(u, v, "madeira")
    p.posts([(15, 27), (33, 27), (7, 15), (41, 15), (21, 11), (27, 11), (17, 3), (31, 3)])
    p.flowers([(6, 24), (42, 24), (30, 10), (17, 10)])
    p.kites([(41, 20), (29, 4)])
    p.item(21061 + 18, 41, 23, "cola-reparo")
    p.frame_trees()
    return p


def area_e():
    """Praça da Campeã: o gramado redondo onde a Mikka espera, bandeirinhas, coreto e
    a saída para a cidade."""
    p = Morro(4)
    p.arrival("morro-area-4", 24, 1, "Voltar para o Mirante da Caixa-d’água")
    p.rect(19, 28, 29, 32, "piso", 0)
    p.rect(6, 6, 42, 27, "piso", 1)                 # praça da campeã
    p.rect(14, 10, 34, 22, "grama", 1)              # gramado
    for v in range(10, 23):                         # arredonda os cantos do gramado
        for u in range(14, 35):
            du, dv = (u - 24) / 10.5, (v - 16) / 6.6
            if du * du + dv * dv > 1.05:
                p.mat[v][u] = "piso"
    p.stairs(22, 28, 5, 0)
    p.rect(22, 27, 26, 27, "piso", 1)
    p.rect(22, 0, 26, 5, "piso", 1)
    p.onward("quintal", 1, "Sair para a cidade")
    p.rival("Mikka", 24, 15, "morro-5", sprite="res://assets/campaign/morro/mikka-overworld.png")
    p.forest["landmark"] = {"kind": "arena", "u": 24.5, "v": 16.5}
    p.kiosk(36, 8, "coral", "Coreto")
    p.casa(7, 7); p.casa(12, 2); p.casa(31, 2)
    p.casa(6, 21); p.casa(38, 21)
    for u, v in [(12, 9), (36, 13), (12, 23), (35, 24)]:
        p.bench(u, v, "madeira")
    p.posts([(13, 9), (35, 9), (13, 23), (35, 23), (21, 5), (27, 5), (21, 28), (27, 28)])
    p.tree(8, 13); p.tree(39, 16)
    p.kites([(16, 9), (32, 9), (16, 23), (32, 23)])
    p.flowers([(7, 26), (42, 26), (42, 7), (20, 6), (28, 6)])
    p.item(21081 + 18, 41, 12, "papel-seda", "escondido")
    p.frame_trees()
    return p


if __name__ == "__main__":
    for build in (area_a, area_b, area_c, area_d, area_e):
        plan = build()
        plan.write()
        print("escrito", plan.scene, "→", plan.game_scene, len(plan.pieces), "peças", len(plan.events), "eventos")
