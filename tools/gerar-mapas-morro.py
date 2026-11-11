#!/usr/bin/env python3
"""Morro do Sol (bairro 1, ato 1) no modelo isométrico de Kronasta, áreas A–E.

Versão 3 (11/11/2026): mapas grandes (64×56), com mais andares, lados desiguais, um córrego
com poços rebaixados, grotas e cachoeiras (forest.waterFalls) e mais pontos sem saída. Cada área sobe o morro em
4 a 6 níveis de terraços, com rota principal, rotas alternativas, becos sem saída com
recompensa, moradores e mirantes. A chegada fica embaixo (v alto) e a saída para a próxima
área no alto (v baixo). A cena de jogo continua a mesma ("morro", "morro-area-2"…): saves,
desafios, estrelas e defesa de título não mudam.

    python3 tools/gerar-mapas-morro.py [a b c d e]
    node tools/compilar-mapas.mjs kronasta-morro-a ... kronasta-morro-e

Rivais (evento npc, acao morroDuel):
  A Zeca (morro-1) · B Bia (morro-2) · C Juninho e Lia (morro-3) · D Tião (morro-4) · E Mikka (morro-5)

Escadas sobem sempre para v− (o fundo da tela): rampas em v e v+1 no nível de baixo,
patamar em v−1 no nível de cima, pé em v+2.
"""
import importlib.util
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("cidade", os.path.join(HERE, "gerar-mapas-cidade.py"))
cidade = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cidade)
W, H = 64, 56
cidade.W, cidade.H = W, H                # o Plan da cidade usa as dimensões do módulo
Plan = cidade.Plan
cidade.LEVEL_GID = {L: 0 for L in range(10)}   # o write() daqui regrava a camada de altura
CX = 32                                  # eixo central (chegada e saída)
MAX_LEVEL = 9
ALTURAS_GID = 301                        # tileset embutido: id L = nível L; id 10+L = nível L com rampa v−

SCENES = ["morro", "morro-area-2", "morro-area-3", "morro-area-4", "morro-area-5"]
NAMES = ["Praça da Chegada", "Escadaria da Sombra", "Laje dos Ventos", "Mirante da Caixa-d’água", "Praça da Campeã"]
CASAS = ["rosa", "creme", "amarela", "azul", "verde"]


class Morro(Plan):
    def __init__(self, index):
        self.index = index
        scene_id = "kronasta-morro-" + "abcde"[index]
        super().__init__(scene_id, "Morro do Sol", "morro", "ABCDE"[index], "Morro do Sol · " + NAMES[index])
        self.game_scene = SCENES[index]
        self.forest = {"market": True, "stream": True, "nativeProps": True, "closedStairs": True, "shots": []}
        self.casa_n = 0
        self._event_id = 21000 + index * 40
        self._item_id = 21030 + index * 40

    # ---- chão: os níveis das áreas são relativos; o morro inteiro fica um nível acima do
    # zero para que poços e grotas possam ser rebaixados (água na cota 0).
    BASE = 1

    def rect(self, u0, v0, u1, v1, material, level=0):
        Plan.rect(self, u0, v0, u1, v1, material, level + self.BASE)

    def stairs(self, u, v, width, level):
        Plan.stairs(self, u, v, width, level + self.BASE)

    def water(self, u0, v0, u1, v1, terrace):
        """Água rebaixada um nível em relação ao terraço `terrace` (relativo)."""
        Plan.rect(self, u0, v0, u1, v1, "agua", terrace + self.BASE - 1)

    def grota(self, u0, v0, u1, v1):
        """Fundo de grota: rocha na cota 0, sem passagem."""
        Plan.rect(self, u0, v0, u1, v1, "rocha", 0)

    def ponte(self, u0, v0, u1, v1, level):
        Plan.rect(self, u0, v0, u1, v1, "ponte", level + self.BASE)

    def fall(self, u, v, width):
        """Cachoeira na face da frente (+v) das células de água (u…u+width−1, v)."""
        drop = self.lvl[v][u] - self.lvl[v + 1][u]
        assert self.mat[v][u] == "agua" and self.mat[v + 1][u] == "agua" and drop >= 1, f"queda inválida em {u},{v}"
        self.forest.setdefault("waterFalls", []).append({"u": u, "v": v, "width": width, "drop": drop})

    # ---- eventos ----
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

    def rival(self, name, u, v, stage, identity=None, sprite=None):
        props = {"acao": "morroDuel", "district": "morro", "duel": stage, "bloqueia": False}
        if identity:
            props["npcIdentity"] = identity
        if sprite:
            props["storySpritePath"] = sprite
        self.event("npc", name, u, v, props)

    def morador(self, name, identity, u, v, fala):
        """Morador que conversa: dica do bairro ou do caminho."""
        self.event("npc", name, u, v, {"district": "morro", "npcIdentity": identity, "texto": name + ": " + fala, "bloqueia": False})

    def placa(self, name, u, v, texto):
        self.event("interacao", name, u, v, {"texto": texto})

    def descanso(self, u, v):
        self.bench(u, v, "madeira")
        self.event("interacao", "Banco da sombra", u, v + 1, {"acao": "wildRest"})

    def tesouro(self, u, v, item, escondido=True):
        self._item_id += 1
        self.item(self._item_id, u, v, item, "escondido" if escondido else "brilho", "Achado do morro")

    def arrival(self, back_scene, name):
        """Chegada embaixo e saída de volta (para a área anterior, no alto dela)."""
        self.rect(CX - 4, H - 8, CX + 4, H - 1, "piso", 0)
        self.event("entrada", "Chegada", CX, H - 3, {})
        props = {"destino": back_scene}
        if back_scene != "quintal":
            props.update({"chegada_u": CX, "chegada_v": 1})
        self.event("saida", name, CX, H - 1, props)

    def onward(self, next_scene, top_level, name):
        """Saída no alto: só abre depois de vencer o desafio da área (gate em park_checkpoint)."""
        self.rect(CX - 2, 0, CX + 2, 1, "piso", top_level)
        props = {"destino": next_scene, "morroGate": "morro-%d" % (self.index + 1)}
        if next_scene != "quintal":
            props.update({"chegada_u": CX, "chegada_v": H - 4})
        self.event("saida", name, CX, 0, props)

    # ---- peças ----
    def casa(self, u, v, name="Casa"):
        # Casa fora do caminho ganha um lote de quintal (grama) no nível da rua ao lado,
        # para não afundar no mato da moldura.
        level = None
        for fu, fv in [(u + 1, v + 4), (u + 2, v + 4), (u + 4, v + 1), (u - 1, v + 1), (u + 1, v - 1)]:
            if 0 <= fu < W and 0 <= fv < H and self.mat[fv][fu] not in ("bosque", "agua", "rocha") and not self.ramp[fv][fu]:
                level = self.lvl[fv][fu]
                break
        for dv in range(4):
            for du in range(4):
                assert not self.ramp[v + dv][u + du] and self.mat[v + dv][u + du] not in ("agua", "rocha", "ponte"), f"casa sobre escada ou água em {u},{v}"
                if self.mat[v + dv][u + du] == "bosque":
                    self.mat[v + dv][u + du] = "grama"
                    self.lvl[v + dv][u + du] = level if level is not None else self.lvl[v + dv][u + du]
        self.house(u, v, CASAS[(self.casa_n + self.index) % len(CASAS)], name)
        self.casa_n += 1

    def casas(self, cells):
        for u, v in cells:
            self.casa(u, v)

    def flowers(self, cells):
        for u, v in cells:
            self.piece("flores", u, v, 1, 1, False, ["coral", "amarela", "azul"][(u + v) % 3], "Flores")

    def posts(self, cells):
        for u, v in cells:
            self.post(u, v)

    def kites(self, cells):
        for u, v in cells:
            self.piece("pipa-presa", u, v, 1, 1, False, "default", "Pipa presa")

    def shot(self, name, u, v):
        self.forest["shots"].append({"name": name, "u": u, "v": v, "zoom": 1, "kind": "jogo"})

    def write(self):
        super().write()
        # Alturas: o tileset de rascunho só tem níveis 1–3; aqui um tileset embutido cobre 0–7.
        path = os.path.join(cidade.MAPS, self.scene + ".tmj")
        tmj = json.load(open(path))
        for prop in tmj["properties"]:
            if prop["name"] == "cena_jogo":
                prop["value"] = self.game_scene
            if prop["name"] == "bioma":
                prop["value"] = "morro"
        altura = []
        for v in range(H):
            for u in range(W):
                level = self.lvl[v][u]
                assert 0 <= level <= MAX_LEVEL
                altura.append(ALTURAS_GID + (10 + level if self.ramp[v][u] else level))
        tiles = [{"id": L, "properties": [{"name": "nivel", "type": "int", "value": L}]} for L in range(MAX_LEVEL + 1)]
        tiles += [{"id": 10 + L, "properties": [{"name": "nivel", "type": "int", "value": L},
                                               {"name": "rampa", "type": "string", "value": "v-"}]} for L in range(MAX_LEVEL + 1)]
        tmj["tilesets"] = [tmj["tilesets"][0],
                           {"firstgid": ALTURAS_GID, "name": "morro-alturas", "tilewidth": 64, "tileheight": 32, "tilecount": 24,
                            "columns": 8, "image": "../tiles/rascunho.png", "imagewidth": 512, "imageheight": 96, "tiles": tiles}]
        for layer in tmj["layers"]:
            if layer["name"] == "altura":
                layer["data"] = altura
        json.dump(tmj, open(path, "w"), ensure_ascii=False, indent=1)


def area_a():
    """Praça da Chegada (5 níveis). Lados desiguais: a oeste, dois terraços empilhados que
    acabam num mirante sem saída; a leste, o Poço do Sol, alimentado por uma cachoeira que
    desce a grota vinda da nascente do terraço alto. O caminho para cima passa pelo leste."""
    p = Morro(0)
    p.arrival("quintal", "Voltar à Rua dos Ventos")
    p.rect(6, 38, 44, 47, "piso", 0)                  # praça (pende para o oeste)
    p.rect(18, 48, 27, 53, "piso", 0)                 # beco oeste da entrada
    p.rect(14, 41, 19, 44, "canteiro", 0)
    p.rect(45, 37, 58, 47, "piso", 0)                 # margem do Poço do Sol
    p.water(47, 39, 56, 45, 0)
    p.rect(52, 48, 58, 52, "grama", 0)                # quintal do poço (sem saída)
    p.rect(6, 28, 44, 35, "piso", 1)                  # patamar das casas
    p.stairs(8, 36, 3, 0)
    p.stairs(30, 36, 5, 0)
    p.rect(24, 20, 34, 27, "grama", 1)                # quintal escondido (sem saída)
    p.rect(4, 18, 22, 25, "piso", 2)                  # terraço oeste
    p.stairs(10, 26, 3, 1)
    p.rect(3, 8, 16, 15, "piso", 3)                   # mirante oeste (sem saída, dois níveis acima)
    p.stairs(6, 16, 3, 2)
    p.rect(38, 18, 60, 25, "piso", 2)                 # terraço da nascente
    p.rect(46, 26, 60, 27, "piso", 2)
    p.stairs(40, 26, 3, 1)
    p.water(52, 19, 57, 22, 2)                        # nascente
    p.water(54, 23, 55, 27, 2)
    p.ponte(54, 25, 55, 25, 2)
    p.grota(50, 28, 59, 36)
    p.water(54, 28, 55, 38, 0)                        # o córrego desce a grota até o poço
    p.fall(54, 27, 2)
    p.rect(26, 8, 50, 15, "piso", 3)                  # largo alto
    p.stairs(44, 16, 3, 2)
    p.rect(26, 2, 40, 5, "piso", 4)                   # largo da caixa-d'água
    p.stairs(30, 6, 5, 3)
    p.onward("morro-area-2", 4, "Seguir para a Escadaria da Sombra")
    p.rival("Zeca", 24, 42, "morro-1", identity="zeca")
    p.kiosk(8, 40, "teal", "Oficina de pipas")
    p.placa("Oficina de pipas", 10, 43, "Na oficina da praça, cada pipa começa com bambu, papel e um pouco de paciência. Para subir, siga o barulho da água: o caminho passa pela nascente.")
    p.placa("Poço do Sol", 46, 42, "A água da nascente cai pela grota e descansa aqui antes de sumir morro abaixo. No verão, a molecada pula do muro.")
    p.morador("Dora", "dora", 36, 31, "O lado de lá, o do mirante, não tem saída: é bonito, mas volta pelo mesmo caminho. Pra subir de verdade é pela escada da nascente.")
    p.morador("Cauê", "caue", 29, 23, "Este quintal é o esconderijo da molecada. Ninguém vê a gente daqui, mas dá pra ouvir a praça inteira.")
    p.morador("Celina", "celina", 8, 12, "Daqui de cima dá pra ver o mar. Vale a subida, mesmo sem ter pra onde ir depois.")
    p.placa("Nascente", 50, 21, "A água brota fria da pedra. Dizem que o vento do morro nasce junto com ela.")
    p.descanso(40, 33)
    p.casas([(19, 49)])
    p.casa(38, 39, "Mercadinho do Morro")
    p.casas([(14, 29), (20, 29), (36, 29)])
    p.casas([(12, 19), (17, 19)])
    p.casa(11, 9)
    p.casas([(39, 19), (47, 19)])
    p.casas([(27, 9), (38, 9), (46, 9)])
    p.casa(36, 2, "Casa da caixa-d’água")
    p.tree(16, 42); p.tree(26, 22); p.tree(31, 24)
    for u, v in [(12, 46), (30, 39), (8, 33), (20, 24), (4, 14), (42, 24), (28, 14), (48, 46)]:
        p.bench(u, v, "madeira")
    p.posts([(27, 47), (37, 47), (7, 46), (29, 34), (35, 34), (6, 24), (39, 24), (29, 14), (35, 14), (29, 4)])
    p.flowers([(6, 47), (44, 38), (58, 47), (6, 35), (24, 27), (34, 20), (22, 18), (60, 18), (3, 8), (50, 8), (26, 2)])
    p.kites([(40, 44), (15, 39), (18, 22), (44, 11)])
    p.piece("biruta", 15, 9, 1, 1, True, "default", "Biruta do mirante")
    p.tesouro(4, 9, "linha-encerada")                 # mirante oeste
    p.tesouro(33, 21, "cola-reparo")                  # quintal escondido
    p.tesouro(57, 51, "papel-seda")                   # quintal do poço
    p.tesouro(59, 26, "papel-seda")                   # além da pinguela da nascente
    p.tesouro(26, 52, "linha-encerada", escondido=False)
    for name, u, v in [("praca", 26, 42), ("poco", 50, 42), ("nascente", 52, 24), ("mirante", 9, 12), ("alto", 34, 10)]:
        p.shot(name, u, v)
    p.frame_trees()
    return p


def area_b():
    """Escadaria da Sombra (6 níveis). A escadaria sobe pelo meio; a oeste, uma grota funda
    onde a nascente despenca três níveis até o poço da entrada; a leste, um caminho
    alternativo e uma laje sem saída sobre o beco."""
    p = Morro(1)
    p.arrival("morro", "Voltar para a Praça da Chegada")
    p.rect(23, 44, 44, 47, "piso", 0)                 # pé da escadaria
    p.rect(8, 43, 22, 50, "piso", 0)                  # margem do poço
    p.water(10, 45, 20, 48, 0)
    p.rect(45, 44, 58, 47, "piso", 0)                 # beco leste
    p.rect(52, 36, 60, 41, "piso", 1)                 # laje do beco (sem saída)
    p.stairs(54, 42, 3, 0)
    p.rect(22, 36, 48, 41, "piso", 1)                 # primeiro patamar
    p.stairs(30, 42, 5, 0)
    p.rect(18, 26, 54, 33, "piso", 2)                 # patamar da sombra
    p.stairs(30, 34, 5, 1)
    p.rect(26, 18, 40, 23, "piso", 3)                 # patamar do meio
    p.stairs(30, 24, 5, 2)
    p.rect(44, 18, 58, 23, "piso", 3)                 # terraço leste
    p.stairs(50, 24, 3, 2)
    p.rect(6, 18, 20, 23, "piso", 3)                  # terraço da nascente (sem saída)
    p.stairs(18, 24, 3, 2)
    p.water(8, 19, 13, 21, 3)
    p.water(10, 22, 11, 23, 3)
    p.grota(7, 24, 14, 42)
    p.water(10, 24, 11, 44, 0)                        # o córrego corre no fundo da grota
    p.fall(10, 23, 2)
    p.rect(24, 10, 60, 15, "piso", 4)                 # patamar alto
    p.stairs(30, 16, 5, 3)
    p.stairs(52, 16, 3, 3)
    p.rect(26, 2, 40, 7, "piso", 5)                   # alto da escadaria
    p.stairs(30, 8, 5, 4)
    p.onward("morro-area-3", 5, "Seguir para a Laje dos Ventos")
    p.rival("Bia", 36, 30, "morro-2", identity="bia")
    p.tree(26, 29); p.tree(42, 30); p.tree(21, 30)
    p.morador("Nilo", "nilo", 21, 44, "Tá ouvindo? É a queda da grota. A água vem lá da nascente, três andares acima, e descansa neste poço.")
    p.morador("Iara", "iara", 50, 12, "Subiu pelo lado de cá? Pouca gente conhece. A escada do leste é mais comprida, mas tem menos degrau quebrado.")
    p.placa("Marca no degrau", 32, 27, "Alguém riscou no degrau: \"daqui pra cima, só quem ouve o vento\".")
    p.placa("Altar das pipas perdidas", 15, 20, "Rabiolas velhas amarradas num pau de bambu, na beira da nascente. Cada uma é de uma pipa que o morro perdeu para o céu.")
    p.placa("Laje do beco", 58, 38, "Uma laje esquecida em cima do beco. Alguém deixou uma cadeira virada para o pôr do sol.")
    p.descanso(46, 31)
    p.casas([(48, 48)])
    p.casas([(23, 36), (41, 36)])
    p.casas([(22, 26), (38, 26), (44, 26)])
    p.casas([(26, 19), (36, 19), (45, 18)])
    p.casas([(25, 10), (40, 10), (56, 10)])
    p.casas([(27, 3), (36, 3)])
    for u, v in [(26, 46), (40, 46), (24, 40), (20, 32), (28, 22), (46, 22), (16, 22), (56, 40)]:
        p.bench(u, v, "madeira")
    p.posts([(29, 47), (35, 47), (29, 41), (35, 41), (29, 33), (35, 33), (29, 23), (35, 23), (29, 15), (35, 15), (29, 7)])
    p.flowers([(8, 43), (22, 50), (58, 44), (48, 41), (18, 33), (54, 26), (58, 18), (60, 15), (6, 18), (26, 7), (40, 2)])
    p.kites([(54, 46), (22, 28), (56, 21), (38, 4)])
    p.piece("biruta", 7, 22, 1, 1, True, "default", "Biruta da nascente")
    p.tesouro(9, 49, "papel-seda")                    # atrás do poço
    p.tesouro(59, 37, "linha-encerada")               # laje do beco
    p.tesouro(7, 19, "cola-reparo")                   # nascente
    p.tesouro(57, 22, "papel-seda", escondido=False)
    p.tesouro(59, 14, "linha-encerada")
    for name, u, v in [("poco", 16, 46), ("sombra", 34, 29), ("nascente", 12, 21), ("meio", 34, 20), ("alto", 32, 5)]:
        p.shot(name, u, v)
    p.frame_trees()
    return p


def area_c():
    """Laje dos Ventos (6 níveis). O caminho ziguezagueia de laje em laje. Uma grota funda
    corta a laje grande ao meio: a água da laje alta despenca quatro níveis e some no fundo;
    uma pinguela alta liga os dois lados. No leste, duas lajes sem saída até a Laje do Vento."""
    p = Morro(2)
    p.arrival("morro-area-2", "Voltar para a Escadaria da Sombra")
    p.rect(8, 46, 56, 49, "piso", 0)                  # rua de baixo
    p.rect(2, 44, 7, 50, "grama", 0)                  # quintal das pipas (sem saída)
    p.rect(6, 38, 40, 43, "piso", 1)                  # laje oeste
    p.stairs(10, 44, 4, 0)
    p.rect(24, 30, 58, 35, "piso", 2)                 # laje leste
    p.stairs(34, 36, 4, 1)
    p.rect(8, 20, 28, 27, "piso", 3)                  # laje grande, metade oeste
    p.rect(36, 20, 58, 27, "piso", 3)                 # laje grande, metade leste
    p.stairs(52, 28, 4, 2)
    p.stairs(25, 28, 3, 2)                            # atalho pelo meio
    p.rect(8, 12, 44, 17, "piso", 4)                  # laje alta
    p.stairs(12, 18, 4, 3)
    p.water(30, 13, 34, 15, 4)                        # tanque da laje alta
    p.water(31, 16, 33, 17, 4)
    p.grota(29, 18, 35, 29)
    p.water(31, 18, 33, 25, 0)
    p.water(30, 26, 34, 29, 0)                        # sumidouro
    p.fall(31, 17, 3)
    p.ponte(29, 23, 35, 24, 3)                        # pinguela alta
    p.rect(22, 2, 42, 9, "piso", 5)                   # passagem alta
    p.stairs(30, 10, 5, 4)
    p.rect(48, 12, 60, 17, "piso", 4)                 # laje alta do leste (sem saída)
    p.stairs(50, 18, 3, 3)
    p.rect(50, 4, 60, 9, "piso", 5)                   # Laje do Vento (sem saída)
    p.stairs(54, 10, 3, 4)
    p.onward("morro-area-4", 5, "Seguir para o Mirante da Caixa-d’água")
    p.rival("Juninho", 18, 24, "morro-3", identity="juninho")
    p.rival("Lia", 21, 24, "morro-3", identity="lia")
    p.kiosk(11, 24, "coral", "Varal da laje")
    p.kiosk(44, 24, "teal", "Varal da laje")
    p.morador("Dora", "dora", 20, 42, "Aqui ninguém sobe em linha reta. Cada laje abre do lado contrário da outra: é andar e virar.")
    p.morador("Cauê", "caue", 54, 14, "A Laje do Vento fica logo ali em cima. É onde o Juninho treina escondido da Lia.")
    p.placa("Pinguela da grota", 27, 23, "Tábuas sobre a grota. Lá embaixo a água do tanque cai, faz um redemoinho e some pela pedra.")
    p.placa("Varal da laje", 13, 26, "Roupas, rabiolas e bandeirinhas secando juntas. No morro, varal também é biruta.")
    p.placa("Laje do Vento", 52, 8, "O ponto mais alto das lajes. Daqui o vento chega limpo, sem bater em telhado nenhum.")
    p.descanso(40, 33)
    p.casas([(14, 50), (46, 50)])
    p.casas([(16, 38), (22, 38), (28, 38)])
    p.casas([(40, 30), (46, 30)])
    p.casas([(16, 20), (38, 20), (46, 20)])
    p.casas([(18, 12), (24, 12), (38, 12), (57, 12)])
    p.casas([(23, 3), (37, 3)])
    for u, v in [(20, 48), (42, 48), (8, 42), (30, 34), (10, 26), (56, 26), (10, 16), (58, 8), (3, 46)]:
        p.bench(u, v, "concreto")
    p.posts([(27, 49), (37, 49), (9, 43), (39, 38), (25, 35), (57, 30), (9, 27), (57, 20), (9, 17), (43, 12), (29, 9)])
    p.flowers([(8, 49), (56, 46), (6, 38), (58, 35), (8, 20), (58, 27), (44, 17), (60, 17), (22, 9), (42, 2), (60, 4), (2, 44)])
    p.kites([(12, 22), (50, 22), (40, 14), (56, 6), (30, 40)])
    p.piece("biruta", 59, 5, 1, 1, True, "default", "Biruta da Laje do Vento")
    p.piece("biruta", 9, 13, 1, 1, True, "default", "Biruta da laje")
    p.tesouro(3, 49, "linha-encerada")                # quintal das pipas
    p.tesouro(7, 39, "papel-seda")
    p.tesouro(59, 16, "cola-reparo")                  # laje alta do leste
    p.tesouro(51, 5, "papel-seda")                    # Laje do Vento
    p.tesouro(37, 26, "linha-encerada", escondido=False)
    for name, u, v in [("rua", 32, 47), ("laje-oeste", 22, 41), ("grota", 32, 24), ("tanque", 32, 15), ("laje-do-vento", 55, 8)]:
        p.shot(name, u, v)
    p.frame_trees()
    return p


def area_d():
    """Mirante da Caixa-d'água (7 níveis). A oeste, o morro sobe em degraus até o mirante da
    luneta. A leste, um paredão: a água que transborda da caixa-d'água despenca seis níveis
    pela grota e enche o Poço da Bica, um recanto sem saída ao pé do morro."""
    p = Morro(3)
    p.arrival("morro-area-3", "Voltar para a Laje dos Ventos")
    p.rect(12, 46, 52, 49, "piso", 0)
    p.rect(48, 37, 61, 45, "piso", 0)                 # margem do Poço da Bica (sem saída)
    p.water(50, 39, 58, 42, 0)
    p.rect(10, 40, 46, 43, "piso", 1)
    p.stairs(30, 44, 5, 0)
    p.rect(3, 32, 46, 37, "piso", 2)
    p.stairs(14, 38, 3, 1)
    p.stairs(40, 38, 3, 1)
    p.rect(12, 24, 46, 29, "piso", 3)                 # mirante do Tião
    p.stairs(30, 30, 5, 2)
    p.rect(3, 24, 9, 29, "piso", 3)                   # mirante da luneta (sem saída)
    p.stairs(4, 30, 3, 2)
    p.rect(10, 16, 46, 21, "piso", 4)
    p.stairs(16, 22, 3, 3)
    p.stairs(42, 22, 3, 3)
    p.rect(10, 6, 48, 13, "piso", 5)                  # largo alto
    p.stairs(30, 14, 5, 4)
    p.rect(30, 2, 34, 5, "piso", 5)                   # passagem para a praça da campeã
    p.rect(40, 2, 54, 5, "piso", 6)                   # plataforma da caixa-d'água
    p.stairs(45, 6, 3, 5)
    p.water(51, 3, 53, 5, 6)                          # o transbordo da caixa-d'água
    p.grota(49, 6, 62, 36)
    p.water(51, 6, 53, 38, 0)
    p.fall(51, 5, 3)
    p.onward("morro-area-5", 5, "Seguir para a Praça da Campeã")
    p.rival("Tião", 38, 27, "morro-4", identity="tiao")
    p.kiosk(20, 40, "teal", "Barraca do mirante")
    p.kiosk(36, 40, "coral", "Barraca de linha")
    p.morador("Celina", "celina", 26, 34, "A caixa-d’água é o farol do morro. Quando ela transborda, a água cai o paredão inteiro e vira o Poço da Bica lá embaixo.")
    p.morador("Nilo", "nilo", 22, 9, "O Tião treina no mirante do meio. Teimoso que só: perde dez vezes e volta onze.")
    p.placa("Caixa-d’água do Morro", 42, 3, "A caixa-d’água azul abastece o morro inteiro. Na tampa, gerações de pipeiros riscaram o nome da primeira pipa.")
    p.placa("Luneta enferrujada", 5, 26, "Uma luneta de moeda, sem moeda. Ainda assim dá para ver a Rua dos Ventos lá embaixo.")
    p.placa("Poço da Bica", 49, 41, "A água cai de tão alto que chega em chuva fina. Quem acha este canto costuma guardar segredo.")
    p.descanso(20, 28)
    p.casas([(22, 32), (36, 32), (8, 32)])
    p.casas([(24, 24), (34, 24)])
    p.casas([(20, 16), (36, 16)])
    p.casas([(12, 6), (18, 6), (24, 6), (36, 6)])
    for u, v in [(18, 48), (44, 48), (28, 42), (44, 36), (14, 28), (44, 28), (12, 20), (26, 12), (44, 4), (60, 44)]:
        p.bench(u, v, "madeira")
    p.posts([(29, 49), (35, 49), (11, 43), (45, 43), (29, 37), (35, 37), (13, 29), (45, 24), (29, 21), (35, 21), (11, 13), (47, 13)])
    p.flowers([(12, 49), (52, 46), (10, 40), (46, 43), (3, 37), (46, 32), (12, 24), (46, 29), (46, 16), (10, 6), (48, 6), (40, 5), (61, 37)])
    p.kites([(44, 26), (8, 34), (44, 18), (46, 10), (16, 42)])
    p.piece("biruta", 41, 2, 1, 1, True, "default", "Biruta da caixa-d’água")
    p.piece("biruta", 8, 25, 1, 1, True, "default", "Biruta do mirante")
    p.tesouro(4, 28, "linha-encerada")                # mirante da luneta
    p.tesouro(60, 38, "cola-reparo")                  # Poço da Bica
    p.tesouro(49, 3, "papel-seda")                    # plataforma, na beira do transbordo
    p.tesouro(4, 36, "papel-seda", escondido=False)
    p.tesouro(45, 20, "linha-encerada")
    for name, u, v in [("base", 32, 44), ("poco-da-bica", 54, 41), ("tiao", 36, 26), ("largo-alto", 32, 10), ("caixa-dagua", 47, 4)]:
        p.shot(name, u, v)
    p.frame_trees()
    return p


def area_e():
    """Praça da Campeã (5 níveis). Escadaria larga em três lances até a arena, onde a Mikka
    espera no gramado. A arquibancada só sobe pelo oeste; no canto nordeste, a bica da
    arquibancada cai num tanque. Um jardim sem saída a oeste e o coreto a leste."""
    p = Morro(4)
    p.arrival("morro-area-4", "Voltar para o Mirante da Caixa-d’água")
    p.rect(14, 46, 50, 49, "piso", 0)
    p.rect(4, 40, 54, 43, "piso", 1)                  # feira da torcida
    p.stairs(29, 44, 7, 0)
    p.rect(16, 34, 48, 37, "piso", 2)                 # patamar das bandeiras
    p.stairs(29, 38, 7, 1)
    p.rect(4, 32, 12, 37, "grama", 2)                 # jardim da primeira pipa (sem saída)
    p.stairs(6, 38, 3, 1)
    p.rect(8, 12, 56, 31, "piso", 3)                  # arena
    p.stairs(29, 32, 7, 2)
    for v in range(13, 31):                           # gramado redondo, deslocado para o oeste
        for u in range(13, 46):
            du, dv = (u + .5 - 29.5) / 14.5, (v + .5 - 21.5) / 7.6
            if du * du + dv * dv <= 1:
                p.mat[v][u] = "grama"
    p.rect(8, 2, 56, 9, "piso", 4)                    # arquibancada
    p.stairs(12, 10, 4, 3)
    p.water(49, 5, 54, 9, 4)                          # bica da arquibancada
    p.water(49, 10, 54, 15, 3)                        # tanque da arena
    p.fall(49, 9, 6)
    p.onward("quintal", 4, "Sair para a cidade")
    p.rival("Mikka", 29, 20, "morro-5", sprite="res://assets/campaign/morro/mikka-overworld.png")
    p.forest["landmark"] = {"kind": "arena", "u": 29.5, "v": 21.5}
    p.kiosk(14, 40, "coral", "Barraca da torcida")
    p.kiosk(46, 40, "teal", "Barraca de rabiolas")
    p.kiosk(47, 26, "coral", "Coreto")
    p.morador("Iara", "iara", 22, 42, "Dia de desafio a feira enche. Todo mundo quer ver quem tem coragem de subir até a Mikka.")
    p.morador("Dora", "dora", 46, 19, "A Mikka nunca perdeu aqui em cima. Mas ela mesma diz: título é vento, um dia muda de lado.")
    p.placa("Mural dos campeões", 32, 4, "Nomes pintados à mão, um por geração. O último ainda está fresco: MIKKA.")
    p.placa("Canteiro da primeira pipa", 6, 34, "Dizem que a primeira pipa do morro subiu deste canteiro. Ninguém corta as flores daqui.")
    p.placa("Tanque da arena", 48, 13, "A bica da arquibancada enche o tanque. Depois de cada desafio, vencedor e vencido lavam o rosto na mesma água.")
    p.descanso(52, 30)
    p.casas([(9, 13), (9, 26), (52, 20)])
    p.casas([(18, 3), (24, 3), (38, 3)])
    p.casas([(16, 50), (44, 50)])
    for u, v in [(20, 48), (42, 48), (24, 36), (40, 36), (46, 22), (16, 29), (28, 8), (36, 8), (44, 8)]:
        p.bench(u, v, "madeira")
    p.posts([(28, 49), (36, 49), (28, 43), (36, 43), (28, 37), (36, 37), (17, 12), (46, 30), (11, 9), (47, 2)])
    p.tree(9, 20); p.tree(54, 27)
    p.kites([(18, 14), (42, 14), (40, 29), (10, 36), (54, 22)])
    p.flowers([(14, 49), (50, 46), (4, 43), (54, 40), (5, 32), (11, 37), (8, 31), (56, 31), (8, 2), (56, 2), (55, 16)])
    p.piece("biruta", 9, 3, 1, 1, True, "default", "Biruta da arquibancada")
    p.tesouro(4, 36, "cola-reparo")                   # jardim da primeira pipa
    p.tesouro(55, 3, "linha-encerada")                # ponta leste da arquibancada, atrás da bica
    p.tesouro(55, 12, "papel-seda")                   # atrás do tanque
    p.tesouro(52, 42, "papel-seda", escondido=False)
    for name, u, v in [("feira", 32, 44), ("bandeiras", 32, 36), ("arena", 30, 22), ("tanque", 50, 13), ("arquibancada", 32, 6)]:
        p.shot(name, u, v)
    p.frame_trees()
    return p


AREAS = {"a": area_a, "b": area_b, "c": area_c, "d": area_d, "e": area_e}

if __name__ == "__main__":
    for key in (sys.argv[1:] or sorted(AREAS)):
        plan = AREAS[key]()
        plan.write()
        print("escrito", plan.scene, "→", plan.game_scene, len(plan.pieces), "peças", len(plan.events), "eventos")
