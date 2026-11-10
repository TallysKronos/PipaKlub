#!/usr/bin/env python3
"""Morro do Sol (bairro 1, ato 1) no modelo isométrico de Kronasta, áreas A–E.

Versão 2 (10/11/2026): mapas maiores (64×56) e com mais andares. Cada área sobe o morro em
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
cidade.LEVEL_GID = {L: 0 for L in range(8)}   # o write() daqui regrava a camada de altura
CX = 32                                  # eixo central (chegada e saída)
MAX_LEVEL = 7
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
        self.forest = {"market": True, "nativeProps": True, "closedStairs": True, "shots": []}
        self.casa_n = 0
        self._event_id = 21000 + index * 40
        self._item_id = 21030 + index * 40

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
            if 0 <= fu < W and 0 <= fv < H and self.mat[fv][fu] != "bosque" and not self.ramp[fv][fu]:
                level = self.lvl[fv][fu]
                break
        for dv in range(4):
            for du in range(4):
                assert not self.ramp[v + dv][u + du], f"casa sobre escada em {u},{v}"
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
    """Praça da Chegada (5 níveis). A praça embaixo com a oficina e o Zeca; o patamar das
    casas; dois terraços laterais (oeste e leste) que sobem por escadas separadas e se
    reencontram na laje do meio; o largo da caixa-d'água no alto. Mirantes sem saída nas
    duas pontas guardam achados."""
    p = Morro(0)
    p.arrival("quintal", "Voltar à Rua dos Ventos")
    # Nível 0 — praça e becos da entrada
    p.rect(8, 38, 56, 47, "piso", 0)
    p.rect(18, 48, 27, 53, "piso", 0)                 # beco oeste da entrada
    p.rect(37, 48, 46, 53, "piso", 0)                 # beco leste
    p.rect(20, 41, 25, 44, "canteiro", 0)
    p.rect(39, 41, 44, 44, "canteiro", 0)
    # Nível 1 — patamar das casas
    p.rect(6, 28, 58, 35, "piso", 1)
    p.stairs(30, 36, 5, 0)                            # escadaria da praça
    p.stairs(12, 36, 3, 0)                            # escada do canto oeste
    # Nível 2 — terraços oeste e leste (separados por um quintal fechado)
    p.rect(4, 18, 26, 25, "piso", 2)
    p.rect(38, 18, 60, 25, "piso", 2)
    p.stairs(10, 26, 4, 1)
    p.stairs(48, 26, 4, 1)
    p.rect(27, 19, 37, 25, "grama", 1)                # quintal do meio (nível do patamar)
    p.rect(30, 26, 34, 27, "grama", 1)                # passagem do patamar ao quintal
    # Nível 3 — laje do meio e os dois mirantes
    p.rect(14, 8, 46, 15, "piso", 3)
    p.stairs(20, 16, 4, 2)
    p.stairs(40, 16, 4, 2)
    p.rect(3, 10, 10, 15, "piso", 3)                  # mirante oeste (sem saída)
    p.stairs(5, 16, 3, 2)
    p.rect(52, 10, 61, 15, "piso", 3)                 # mirante leste (sem saída)
    p.stairs(55, 16, 3, 2)
    # Nível 4 — largo da caixa-d'água e a passagem
    p.rect(22, 2, 42, 5, "piso", 4)
    p.stairs(30, 6, 5, 3)
    p.onward("morro-area-2", 4, "Seguir para a Escadaria da Sombra")
    # Gente e histórias
    p.rival("Zeca", 32, 41, "morro-1", identity="zeca")
    p.kiosk(10, 40, "teal", "Oficina de pipas")
    p.placa("Oficina de pipas", 12, 43, "Na oficina da praça, cada pipa começa com bambu, papel e um pouco de paciência. Os moradores usam a caixa-d’água para indicar o caminho: ela fica no alto, depois da laje do meio.")
    p.morador("Dora", "dora", 46, 31, "Tem dois jeitos de subir daqui: pela escada do lado da padaria ou pela do outro lado. As duas dão na laje do meio.")
    p.morador("Cauê", "caue", 32, 22, "Este quintal é o esconderijo da molecada. Ninguém vê a gente daqui, mas dá pra ouvir a praça inteira.")
    p.morador("Celina", "celina", 57, 12, "Do mirante dá pra ver o mar. Quem solta pipa aqui em cima pega o vento antes de todo mundo.")
    p.placa("Recado na parede", 6, 12, "\"Linha boa não se empresta, se ensina a fazer.\" Alguém pintou isso no muro do mirante faz muito tempo.")
    p.descanso(44, 33)
    # Casas
    p.casas([(19, 49), (38, 49)])                                         # entrada
    p.casa(50, 39, "Mercadinho do Morro")
    p.casas([(7, 29), (18, 29), (24, 29), (37, 29), (53, 29)])           # patamar
    p.casas([(5, 19), (15, 19), (39, 19), (56, 19)])                     # terraços
    p.casas([(15, 9), (26, 9), (35, 9)])                                 # laje
    p.casa(23, 2, "Casa da caixa-d’água"); p.casa(38, 2)
    p.tree(22, 42); p.tree(41, 42)
    p.tree(28, 21); p.tree(35, 22)
    for u, v in [(16, 46), (46, 46), (27, 39), (36, 39), (12, 33), (30, 13), (4, 14), (58, 14)]:
        p.bench(u, v, "madeira")
    p.posts([(27, 47), (37, 47), (9, 46), (55, 39), (29, 34), (35, 34), (8, 24), (58, 24), (28, 14), (36, 14), (29, 4), (35, 4)])
    p.flowers([(8, 47), (56, 47), (6, 35), (58, 28), (27, 25), (37, 19), (14, 15), (46, 8), (3, 10), (61, 15)])
    p.kites([(48, 44), (15, 39), (44, 11), (8, 21)])
    p.piece("biruta", 9, 11, 1, 1, True, "default", "Biruta do mirante")
    p.piece("biruta", 53, 11, 1, 1, True, "default", "Biruta do mirante")
    p.piece("lixeira", 26, 46, variant="rua", name="Lixeira")
    # Achados: os dois mirantes, o quintal e o fundo do beco
    p.tesouro(4, 11, "linha-encerada")
    p.tesouro(60, 11, "papel-seda")
    p.tesouro(36, 24, "cola-reparo")
    p.tesouro(45, 52, "papel-seda", escondido=False)
    for name, u, v in [("praca", 32, 42), ("patamar", 32, 31), ("laje", 30, 12), ("mirante", 57, 13), ("alto", 32, 3)]:
        p.shot(name, u, v)
    p.frame_trees()
    return p


def area_b():
    """Escadaria da Sombra (6 níveis). Uma escadaria central longa, com um patamar por nível.
    Do patamar da sombra (onde a Bia espera sob a árvore) saem três subidas: a central, a
    oeste (que termina num mirante sem saída) e a leste (um caminho alternativo que
    reencontra a central dois níveis acima)."""
    p = Morro(1)
    p.arrival("morro", "Voltar para a Praça da Chegada")
    p.rect(22, 44, 42, 47, "piso", 0)                 # pé da escadaria
    p.rect(8, 45, 21, 47, "piso", 0)                  # beco oeste
    p.rect(43, 45, 56, 47, "piso", 0)                 # beco leste
    p.rect(18, 36, 46, 41, "piso", 1)                 # primeiro patamar
    p.rect(6, 36, 17, 41, "piso", 1)                  # viela das lavadeiras
    p.stairs(30, 42, 5, 0)
    p.rect(10, 26, 54, 33, "piso", 2)                 # patamar da sombra
    p.stairs(30, 34, 5, 1)
    p.rect(24, 18, 40, 23, "piso", 3)                 # patamar do meio
    p.rect(6, 18, 20, 23, "piso", 3)                  # terraço oeste
    p.rect(44, 18, 58, 23, "piso", 3)                 # terraço leste
    p.stairs(30, 24, 5, 2)
    p.stairs(12, 24, 3, 2)
    p.stairs(50, 24, 3, 2)
    p.rect(22, 10, 60, 15, "piso", 4)                 # patamar alto (junta meio e leste)
    p.rect(4, 10, 16, 15, "piso", 4)                  # mirante oeste (sem saída)
    p.stairs(30, 16, 5, 3)
    p.stairs(52, 16, 3, 3)
    p.stairs(8, 16, 3, 3)
    p.rect(24, 2, 40, 7, "piso", 5)                   # alto da escadaria
    p.stairs(30, 8, 5, 4)
    p.onward("morro-area-3", 5, "Seguir para a Laje dos Ventos")
    p.rival("Bia", 36, 30, "morro-2", identity="bia")
    p.tree(26, 29); p.tree(42, 30); p.tree(20, 30)   # as árvores da sombra
    p.morador("Nilo", "nilo", 12, 40, "As lavadeiras estendem roupa aqui desde antes de eu nascer. Se a roupa balança pro mar, o vento tá bom pra pipa.")
    p.morador("Iara", "iara", 50, 12, "Subiu pelo lado de cá? Pouca gente conhece. A escada do leste é mais comprida, mas tem menos degrau quebrado.")
    p.placa("Marca no degrau", 32, 27, "Alguém riscou no degrau: \"daqui pra cima, só quem ouve o vento\".")
    p.placa("Altar das pipas perdidas", 6, 12, "Rabiolas velhas amarradas num pau de bambu. Cada uma é de uma pipa que o morro perdeu para o céu.")
    p.descanso(46, 31)
    p.casas([(10, 48), (48, 48)])
    p.casas([(19, 36), (41, 36), (7, 36)])
    p.casas([(16, 26), (22, 26), (38, 26), (44, 26)])
    p.casas([(25, 18), (36, 18), (14, 18), (45, 18)])
    p.casas([(23, 10), (40, 10), (56, 10), (11, 10)])
    p.casas([(25, 3), (36, 3)])
    for u, v in [(24, 46), (39, 46), (22, 40), (12, 32), (26, 22), (46, 22), (5, 14)]:
        p.bench(u, v, "madeira")
    p.posts([(29, 47), (35, 47), (29, 41), (35, 41), (29, 33), (35, 33), (29, 23), (35, 23), (29, 15), (35, 15), (29, 7), (35, 7)])
    p.flowers([(8, 47), (56, 47), (6, 41), (10, 33), (54, 26), (20, 23), (58, 18), (60, 15), (4, 10), (24, 7), (40, 2)])
    p.kites([(52, 46), (14, 28), (56, 21), (38, 4)])
    p.piece("biruta", 15, 11, 1, 1, True, "default", "Biruta do mirante")
    p.tesouro(9, 46, "papel-seda")
    p.tesouro(16, 41, "linha-encerada")
    p.tesouro(5, 11, "cola-reparo")
    p.tesouro(57, 22, "papel-seda", escondido=False)
    for name, u, v in [("pe", 32, 45), ("sombra", 32, 29), ("meio", 32, 20), ("mirante-oeste", 10, 13), ("alto", 32, 5)]:
        p.shot(name, u, v)
    p.frame_trees()
    return p


def area_c():
    """Laje dos Ventos (6 níveis). O caminho ziguezagueia: cada laje sobe pela ponta oposta
    da anterior, e o jogador atravessa o morro de lado a lado. A laje grande (Juninho e Lia)
    fica no meio. No leste, duas lajes altas sem saída levam à Laje do Vento."""
    p = Morro(2)
    p.arrival("morro-area-2", "Voltar para a Escadaria da Sombra")
    p.rect(8, 46, 56, 49, "piso", 0)                  # rua de baixo
    p.rect(6, 38, 40, 43, "piso", 1)                  # laje oeste
    p.stairs(10, 44, 4, 0)
    p.rect(24, 30, 58, 35, "piso", 2)                 # laje leste
    p.stairs(34, 36, 4, 1)
    p.rect(8, 20, 58, 27, "piso", 3)                  # laje grande
    p.stairs(52, 28, 4, 2)
    p.stairs(26, 28, 3, 2)                            # atalho pelo meio
    p.rect(8, 12, 44, 17, "piso", 4)                  # laje alta
    p.stairs(12, 18, 4, 3)
    p.rect(22, 2, 42, 9, "piso", 5)                   # passagem alta
    p.stairs(30, 10, 5, 4)
    p.rect(48, 12, 60, 17, "piso", 4)                 # laje alta do leste (sem saída)
    p.stairs(50, 18, 3, 3)
    p.rect(50, 4, 60, 9, "piso", 5)                   # Laje do Vento (sem saída)
    p.stairs(54, 10, 3, 4)
    p.onward("morro-area-4", 5, "Seguir para o Mirante da Caixa-d’água")
    p.rival("Juninho", 30, 24, "morro-3", identity="juninho")
    p.rival("Lia", 33, 24, "morro-3", identity="lia")
    p.kiosk(16, 24, "coral", "Varal da laje")
    p.kiosk(42, 24, "teal", "Varal da laje")
    p.morador("Dora", "dora", 20, 42, "Aqui ninguém sobe em linha reta. Cada laje abre do lado contrário da outra: é andar e virar.")
    p.morador("Cauê", "caue", 54, 14, "A Laje do Vento fica logo ali em cima. É onde o Juninho treina escondido da Lia.")
    p.placa("Varal da laje", 18, 26, "Roupas, rabiolas e bandeirinhas secando juntas. No morro, varal também é biruta.")
    p.placa("Laje do Vento", 52, 8, "O ponto mais alto das lajes. Daqui o vento chega limpo, sem bater em telhado nenhum.")
    p.descanso(36, 33)
    p.casas([(14, 50), (46, 50)])
    p.casas([(16, 38), (22, 38), (28, 38)])
    p.casas([(40, 30), (46, 30)])
    p.casas([(18, 20), (36, 20), (44, 20)])
    p.casas([(18, 12), (24, 12), (38, 12), (57, 12)])
    p.casas([(23, 3), (37, 3)])
    for u, v in [(20, 48), (42, 48), (8, 42), (30, 34), (10, 26), (56, 26), (10, 16), (58, 8)]:
        p.bench(u, v, "concreto")
    p.posts([(27, 49), (37, 49), (9, 43), (39, 38), (25, 35), (57, 30), (9, 27), (57, 20), (9, 17), (43, 12), (29, 9), (35, 9)])
    p.flowers([(8, 49), (56, 46), (6, 38), (58, 35), (8, 20), (58, 27), (44, 17), (60, 17), (22, 9), (42, 2), (60, 4)])
    p.kites([(12, 22), (50, 22), (40, 14), (56, 6), (30, 40)])
    p.piece("biruta", 59, 5, 1, 1, True, "default", "Biruta da Laje do Vento")
    p.piece("biruta", 9, 13, 1, 1, True, "default", "Biruta da laje")
    p.tesouro(55, 48, "linha-encerada")
    p.tesouro(7, 39, "papel-seda")
    p.tesouro(59, 16, "cola-reparo")
    p.tesouro(51, 5, "papel-seda")
    p.tesouro(9, 21, "linha-encerada", escondido=False)
    for name, u, v in [("rua", 32, 47), ("laje-oeste", 22, 41), ("laje-grande", 32, 24), ("laje-do-vento", 55, 8), ("alto", 32, 6)]:
        p.shot(name, u, v)
    p.frame_trees()
    return p


def area_d():
    """Mirante da Caixa-d'água (7 níveis). Um zigurate: a cada nível as subidas trocam entre
    o centro e as pontas. O Tião espera no mirante do meio; no topo, uma última escada leva
    à plataforma da caixa-d'água. Dois mirantes laterais sem saída guardam achados."""
    p = Morro(3)
    p.arrival("morro-area-3", "Voltar para a Laje dos Ventos")
    p.rect(12, 46, 52, 49, "piso", 0)
    p.rect(10, 40, 54, 43, "piso", 1)
    p.stairs(30, 44, 5, 0)
    p.rect(3, 32, 56, 37, "piso", 2)
    p.stairs(14, 38, 3, 1)
    p.stairs(48, 38, 3, 1)
    p.rect(12, 24, 52, 29, "piso", 3)                 # mirante do Tião
    p.stairs(30, 30, 5, 2)
    p.rect(3, 24, 9, 29, "piso", 3)                   # mirante oeste (sem saída)
    p.stairs(4, 30, 3, 2)
    p.rect(10, 16, 60, 21, "piso", 4)
    p.stairs(16, 22, 3, 3)
    p.stairs(46, 22, 3, 3)
    p.rect(10, 6, 54, 13, "piso", 5)                  # largo alto
    p.stairs(30, 14, 5, 4)
    p.rect(56, 8, 61, 13, "piso", 5)                  # mirante leste (sem saída)
    p.stairs(57, 14, 3, 4)
    p.rect(30, 2, 34, 5, "piso", 5)                   # passagem para a praça da campeã
    p.rect(40, 2, 54, 5, "piso", 6)                   # plataforma da caixa-d'água
    p.stairs(45, 6, 3, 5)
    p.onward("morro-area-5", 5, "Seguir para a Praça da Campeã")
    p.rival("Tião", 40, 27, "morro-4", identity="tiao")
    p.kiosk(20, 40, "teal", "Barraca do mirante")
    p.kiosk(40, 40, "coral", "Barraca de linha")
    p.morador("Celina", "celina", 26, 34, "A caixa-d’água é o farol do morro. De qualquer beco você olha pra cima e sabe onde está.")
    p.morador("Nilo", "nilo", 22, 9, "O Tião treina no mirante do meio. Teimoso que só: perde dez vezes e volta onze.")
    p.placa("Caixa-d’água do Morro", 42, 3, "A caixa-d’água azul abastece o morro inteiro. Na tampa, gerações de pipeiros riscaram o nome da primeira pipa.")
    p.placa("Luneta enferrujada", 5, 26, "Uma luneta de moeda, sem moeda. Ainda assim dá para ver a Rua dos Ventos lá embaixo.")
    p.descanso(20, 28)
    p.casas([(22, 32), (38, 32), (52, 32), (8, 32)])
    p.casas([(24, 24), (34, 24)])
    p.casas([(20, 16), (38, 16), (50, 16)])
    p.casas([(12, 6), (18, 6), (24, 6), (36, 6)])
    for u, v in [(18, 48), (44, 48), (28, 42), (44, 36), (14, 28), (48, 28), (12, 20), (26, 12), (58, 12), (50, 4)]:
        p.bench(u, v, "madeira")
    p.posts([(29, 49), (35, 49), (11, 43), (53, 43), (29, 37), (35, 37), (13, 29), (51, 29), (29, 21), (35, 21), (11, 13), (53, 13)])
    p.flowers([(12, 49), (52, 46), (10, 40), (54, 43), (3, 37), (56, 32), (12, 24), (52, 29), (60, 21), (10, 6), (54, 6), (40, 5), (54, 2)])
    p.kites([(46, 26), (8, 34), (56, 18), (48, 10), (16, 42)])
    p.piece("biruta", 53, 3, 1, 1, True, "default", "Biruta da caixa-d’água")
    p.piece("biruta", 8, 25, 1, 1, True, "default", "Biruta do mirante")
    p.tesouro(4, 28, "linha-encerada")
    p.tesouro(60, 9, "cola-reparo")
    p.tesouro(52, 4, "papel-seda")
    p.tesouro(4, 36, "papel-seda", escondido=False)
    p.tesouro(59, 20, "linha-encerada")
    for name, u, v in [("base", 32, 44), ("meio", 34, 30), ("tiao", 38, 26), ("largo-alto", 32, 10), ("caixa-dagua", 46, 4)]:
        p.shot(name, u, v)
    p.frame_trees()
    return p


def area_e():
    """Praça da Campeã (5 níveis). Uma escadaria larga sobe em três lances até a arena: um
    largo de vinte fileiras com o gramado redondo onde a Mikka espera. Atrás da arena, a
    arquibancada alta e a saída para a cidade. Dois jardins laterais sem saída ficam a meio
    caminho."""
    p = Morro(4)
    p.arrival("morro-area-4", "Voltar para o Mirante da Caixa-d’água")
    p.rect(14, 46, 50, 49, "piso", 0)
    p.rect(4, 40, 60, 43, "piso", 1)                  # feira da torcida
    p.stairs(29, 44, 7, 0)
    p.rect(16, 34, 48, 37, "piso", 2)                 # patamar das bandeiras
    p.stairs(29, 38, 7, 1)
    p.rect(4, 34, 12, 37, "grama", 2)                 # jardim oeste (sem saída)
    p.stairs(6, 38, 3, 1)
    p.rect(52, 34, 60, 37, "grama", 2)                # jardim leste (sem saída)
    p.stairs(55, 38, 3, 1)
    p.rect(8, 12, 56, 31, "piso", 3)                  # arena
    p.stairs(29, 32, 7, 2)
    for v in range(13, 31):                           # gramado redondo
        for u in range(16, 49):
            du, dv = (u + .5 - 32.5) / 14.5, (v + .5 - 21.5) / 7.6
            if du * du + dv * dv <= 1:
                p.mat[v][u] = "grama"
    p.rect(8, 2, 56, 9, "piso", 4)                    # arquibancada
    p.stairs(12, 10, 4, 3)
    p.stairs(48, 10, 4, 3)
    p.onward("quintal", 4, "Sair para a cidade")
    p.rival("Mikka", 32, 20, "morro-5", sprite="res://assets/campaign/morro/mikka-overworld.png")
    p.forest["landmark"] = {"kind": "arena", "u": 32.5, "v": 21.5}
    p.kiosk(14, 40, "coral", "Barraca da torcida")
    p.kiosk(46, 40, "teal", "Barraca de rabiolas")
    p.kiosk(46, 28, "coral", "Coreto")
    p.morador("Iara", "iara", 22, 42, "Dia de desafio a feira enche. Todo mundo quer ver quem tem coragem de subir até a Mikka.")
    p.morador("Dora", "dora", 14, 28, "A Mikka nunca perdeu aqui em cima. Mas ela mesma diz: título é vento, um dia muda de lado.")
    p.placa("Mural dos campeões", 32, 4, "Nomes pintados à mão, um por geração. O último ainda está fresco: MIKKA.")
    p.placa("Canteiro da primeira pipa", 6, 35, "Dizem que a primeira pipa do morro subiu deste canteiro. Ninguém corta as flores daqui.")
    p.descanso(55, 35)
    p.casas([(9, 13), (9, 26), (52, 13), (52, 26)])
    p.casas([(18, 3), (24, 3), (38, 3), (44, 3)])
    p.casas([(16, 50), (44, 50)])
    for u, v in [(20, 48), (42, 48), (24, 36), (40, 36), (14, 20), (50, 20), (20, 29), (28, 8), (36, 8)]:
        p.bench(u, v, "madeira")
    p.posts([(28, 49), (36, 49), (28, 43), (36, 43), (28, 37), (36, 37), (16, 13), (48, 13), (16, 30), (48, 30), (11, 9), (53, 9)])
    p.tree(10, 20); p.tree(53, 21)
    p.kites([(20, 14), (44, 14), (20, 29), (44, 30), (10, 36), (54, 4)])
    p.flowers([(14, 49), (50, 46), (10, 43), (54, 40), (5, 34), (11, 37), (60, 34), (8, 31), (56, 12), (8, 2), (56, 9)])
    p.piece("biruta", 55, 3, 1, 1, True, "default", "Biruta da arquibancada")
    p.tesouro(4, 36, "cola-reparo")
    p.tesouro(59, 36, "papel-seda")
    p.tesouro(9, 3, "linha-encerada")
    p.tesouro(55, 30, "papel-seda", escondido=False)
    for name, u, v in [("feira", 32, 44), ("bandeiras", 32, 36), ("arena", 32, 22), ("jardim", 8, 36), ("arquibancada", 32, 6)]:
        p.shot(name, u, v)
    p.frame_trees()
    return p


AREAS = {"a": area_a, "b": area_b, "c": area_c, "d": area_d, "e": area_e}

if __name__ == "__main__":
    for key in (sys.argv[1:] or sorted(AREAS)):
        plan = AREAS[key]()
        plan.write()
        print("escrito", plan.scene, "→", plan.game_scene, len(plan.pieces), "peças", len(plan.events), "eventos")
