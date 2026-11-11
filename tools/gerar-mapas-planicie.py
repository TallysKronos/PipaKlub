#!/usr/bin/env python3
"""Planícies de Kronasta (A–C) e a Gruta do Moinho (cavernas A–C).

Seis mapas de 64×56 ligados por saídas em lados diferentes, para que o caminho não seja
sempre "subir até o alto do mapa":

    Kronasta ─(oeste)→ Planície A ─(leste)→ Planície B ─(leste)→ Planície C (lado leste)
                         │(sul)                 │ boca da gruta (encosta norte)
                         └──────→ Planície C (norte)
                                                ↓
                       Caverna A ─(oeste)→ Caverna B ─(norte)→ Caverna C ─(leste)→
                       vale escondido no oeste da Planície C (só se chega pela gruta)

Formas naturais (manchas irregulares) para campos, colinas, lagos e salões; retângulos só
em coisas construídas. Lagos e poços ficam um nível abaixo do chão, com a cachoeira caindo
dentro deles (documentation/continuidade-terreno-isometrico.md).

    python3 tools/gerar-mapas-planicie.py && node tools/compilar-mapas.mjs planicie-a planicie-b planicie-c caverna-a caverna-b caverna-c

Escadas sobem para v− (o fundo da tela). Saídas laterais e para baixo são no mesmo nível.
"""
import importlib.util
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("morro", os.path.join(HERE, "gerar-mapas-morro.py"))
morro = importlib.util.module_from_spec(spec)
spec.loader.exec_module(morro)
W, H, cidade = morro.W, morro.H, morro.cidade
noise = cidade._hash


class Campo(morro.Morro):
    """Base comum: manchas naturais, trilhas largas e saídas em qualquer borda."""

    def __init__(self, scene, name, region, part, title, event_base, forest):
        super().__init__(0)
        self.scene = self.game_scene = scene
        self.name, self.region, self.part, self.title = name, region, part, title
        self.forest = dict(forest, shots=[], trails=[])
        self._event_id = event_base
        self._item_id = event_base + 50

    def write(self):
        super().write()
        import json
        path = os.path.join(cidade.MAPS, self.scene + ".tmj")
        tmj = json.load(open(path))
        for prop in tmj["properties"]:
            if prop["name"] == "bioma":
                prop["value"] = "floresta"
        json.dump(tmj, open(path, "w"), ensure_ascii=False, indent=1)

    # ---- formas ----
    def cell(self, u, v, material, level):
        if 0 <= u < W and 0 <= v < H and not self.ramp[v][u]:
            morro.Plan.rect(self, u, v, u, v, material, level + self.BASE)

    def blob(self, cu, cv, rx, ry, material, level, salt=1, rough=.22):
        """Mancha de contorno irregular (elipse com borda ruidosa)."""
        for v in range(int(cv - ry - 2), int(cv + ry + 3)):
            for u in range(int(cu - rx - 2), int(cu + rx + 3)):
                du, dv = (u + .5 - cu) / rx, (v + .5 - cv) / ry
                ang = math.atan2(dv, du)
                edge = 1 + rough * (math.sin(ang * 3 + salt) * .6 + math.sin(ang * 7 + salt * 2.3) * .4) + (noise(u, v, salt) - .5) * rough * .6
                if du * du + dv * dv <= edge * edge:
                    self.cell(u, v, material, level)

    def pool(self, cu, cv, rx, ry, terrace, salt=1):
        """Lago/poço natural um nível abaixo do terraço."""
        for v in range(int(cv - ry - 2), int(cv + ry + 3)):
            for u in range(int(cu - rx - 2), int(cu + rx + 3)):
                du, dv = (u + .5 - cu) / rx, (v + .5 - cv) / ry
                ang = math.atan2(dv, du)
                edge = 1 + .18 * math.sin(ang * 4 + salt)
                if du * du + dv * dv <= edge * edge and 0 <= u < W and 0 <= v < H and not self.ramp[v][u]:
                    morro.Plan.rect(self, u, v, u, v, "agua", terrace + self.BASE - 1)

    def path(self, points, width, material, level):
        """Trilha larga por uma polilinha (mesmo nível)."""
        for (u0, v0), (u1, v1) in zip(points, points[1:]):
            steps = int(max(abs(u1 - u0), abs(v1 - v0)) * 2) + 1
            for k in range(steps + 1):
                t = k / steps
                u, v = u0 + (u1 - u0) * t, v0 + (v1 - v0) * t
                for du in range(-(width // 2), width - width // 2):
                    for dv in range(-(width // 2), width - width // 2):
                        self.cell(int(round(u)) + du, int(round(v)) + dv, material, level)

    # ---- ligações ----
    def edge_exit(self, u, v, destination, arrive=None, name="Seguir"):
        props = {"destino": destination}
        if arrive:
            props.update({"chegada_u": arrive[0], "chegada_v": arrive[1]})
        self.event("saida", name, u, v, props)

    def arrival(self, u, v, name="Chegada"):
        self.event("entrada", name, u, v, {})

    # ---- missões (scripts/campaign/planicie_story.gd) ----
    def quest_npc(self, name, identity, u, v, acao, **extra):
        props = {"district": "morro", "npcIdentity": identity, "acao": acao, "bloqueia": False}
        props.update(extra)
        self.event("npc", name, u, v, props)

    def quest_item(self, u, v, item, name, requer):
        """Item de missão: só aparece depois do pedido (props requer = flag)."""
        self._item_id += 1
        self.events.append({"id": self._item_id, "name": name, "type": "item", "x": u * 32 + 16, "y": v * 32 + 16, "point": True,
                            "properties": [{"name": "item", "type": "string", "value": item}, {"name": "quantidade", "type": "int", "value": 1},
                                           {"name": "visibilidade", "type": "string", "value": "brilho"}, {"name": "requer", "type": "string", "value": requer}]})

    def tesouros(self, items):
        for u, v, item, hidden in items:
            self.tesouro(u, v, item, hidden)


# ---------------------------------------------------------------------------
# Planícies
# ---------------------------------------------------------------------------

def planicie(part, title, base):
    p = Campo("planicie-" + part, "Planícies de Kronasta", "planicie", part.upper(), "Planícies de Kronasta · " + title, base,
              {"stream": True, "nativeProps": True, "closedStairs": True})
    return p


def decorate_field(p, trees, groves=(), rocks=(), flowers=(), kites=()):
    for u, v in trees:
        p.tree(u, v)
    for u, v in groves:
        p.tree(u, v, "a" if (u + v) % 2 else "b", blocks=False)
    for i, (u, v) in enumerate(rocks):
        p.piece("pedra", u, v, 1, 1, True, str(i % 3), "Pedra")
    p.flowers(flowers)
    p.kites(kites)


def planicie_a():
    """Campos do Vento. Chega pelo oeste. A trilha corta o campo para o leste (Planície B) e
    desce um ramo para o sul (Planície C). Ao norte, uma colina de dois patamares com o moinho
    antigo; a leste, um lago fundo alimentado pela cachoeira da colina da nascente."""
    p = planicie("a", "Campos do Vento", 25000)
    p.blob(32, 30, 31, 26, "grama", 0, salt=3, rough=.12)
    p.blob(20, 40, 10, 6, "mato", 0, salt=5)
    p.blob(44, 14, 7, 4, "mato", 0, salt=7)
    p.path([(0, 33), (12, 33), (22, 29), (34, 27), (46, 23), (56, 20), (63, 20)], 3, "terra", 0)
    p.path([(34, 27), (36, 38), (38, 48), (38, 55)], 3, "terra", 0)
    p.arrival(2, 33)
    p.edge_exit(0, 33, "kronasta", name="Voltar a Kronasta")
    p.edge_exit(63, 20, "planicie-b", (2, 31), "Seguir para as Colinas do Moinho")
    p.edge_exit(38, 55, "planicie-c", (38, 3), "Descer para o Vale das Pedras")
    # Colina do moinho (norte-oeste): dois patamares
    p.blob(16, 13, 11, 6, "grama", 1, salt=11)
    p.stairs(17, 19, 3, 0)
    p.blob(11, 8, 6, 3.5, "grama", 2, salt=13)
    p.stairs(10, 11, 3, 1)
    # Colina da nascente e o lago (leste)
    p.blob(50, 33, 7, 4, "grama", 2, salt=17)
    p.rect(49, 32, 51, 35, "agua", 1)                 # nascente rebaixada na colina
    p.rect(49, 36, 51, 39, "agua", -1)                # o riacho desce até o lago
    p.pool(50, 44, 7, 5, 0, salt=4)
    p.fall(49, 35, 3)
    p.placa("Moinho antigo", 12, 7, "Do moinho sobrou o eixo e uma hélice de bambu. Quando o vento vira, ela ainda dá meia-volta, como se lembrasse.")
    p.placa("Lago da Nascente", 42, 45, "A água desce da colina e cai no lago com barulho de chuva. Peixes prateados fogem da sombra das pipas.")
    p.quest_npc("Seu Bento", "tiao", 14, 8, "planicieMoinho")
    p.morador("Nilo", "nilo", 30, 30, "Nas planícies o vento corre solto. Dizem que tem uma gruta nas Colinas do Moinho, a leste, que atravessa o morro por baixo.")
    p.event("interacao", "Sombra da paineira", 26, 24, {"acao": "wildRest"})
    p.bench(26, 23, "madeira")
    decorate_field(p, trees=[(5, 22), (9, 44), (24, 21), (40, 34), (56, 46), (58, 26), (28, 48), (44, 6)],
                   groves=[(3, 12), (4, 28), (8, 50), (22, 52), (30, 6), (52, 8), (60, 36), (61, 50)],
                   rocks=[(18, 37), (32, 44), (46, 28), (55, 15), (8, 16)],
                   flowers=[(14, 30), (25, 36), (34, 34), (45, 18), (20, 16), (13, 10), (55, 40), (28, 42)],
                   kites=[(12, 6), (36, 20)])
    p.piece("biruta", 14, 9, 1, 1, True, "default", "Biruta da colina")
    p.tesouros([(9, 7, "linha-encerada", True), (57, 38, "papel-seda", True), (8, 40, "cola-reparo", False), (52, 10, "moedas", True)])
    for name, u, v in [("chegada", 6, 33), ("colina", 14, 11), ("lago", 48, 42), ("cruzamento", 34, 28)]:
        p.shot(name, u, v)
    p.frame_trees()
    return p


def planicie_b():
    """Colinas do Moinho. Chega pelo oeste. Uma serra baixa ocupa o norte: no alto da
    encosta, a boca da Gruta do Moinho. A trilha segue pelo sul até a saída leste. Um riacho
    desce da serra em duas quedas até o lago do sul."""
    p = planicie("b", "Colinas do Moinho", 25100)
    p.blob(32, 32, 31, 23, "grama", 0, salt=21, rough=.12)
    p.blob(48, 44, 9, 5, "mato", 0, salt=23)
    p.path([(0, 31), (12, 34), (24, 38), (40, 40), (52, 42), (63, 42)], 3, "terra", 0)
    p.arrival(2, 31)
    p.edge_exit(0, 31, "planicie-a", (61, 20), "Voltar aos Campos do Vento")
    p.edge_exit(63, 42, "planicie-c", (61, 40), "Seguir para o Vale das Pedras")
    # Serra do norte: encosta (1) e crista (2)
    p.blob(34, 14, 24, 7, "grama", 1, salt=27)
    p.stairs(20, 21, 3, 0)
    p.path([(21, 24), (24, 30), (24, 37)], 3, "terra", 0)
    p.blob(36, 8, 12, 3.5, "grama", 2, salt=29)
    p.stairs(30, 11, 3, 1)
    # Boca da gruta na crista: a entrada fica no patamar, encostada na rocha
    p.rect(40, 2, 46, 5, "rocha", 3)
    p.piece("mina-cave", 43, 5, 1, 1, True, "entrada-gruta", "Boca da Gruta do Moinho")
    p.edge_exit(43, 7, "caverna-a", (32, 52), "Entrar na Gruta do Moinho")
    # Riacho da serra: tanque na crista, queda até a encosta, queda até o lago
    p.rect(25, 6, 27, 8, "agua", 1)                   # tanque da crista
    p.rect(25, 9, 27, 13, "agua", 0)
    p.fall(25, 8, 3)
    p.rect(25, 14, 27, 25, "agua", -1)
    p.fall(25, 13, 3)
    p.pool(26, 30, 5, 4, 0, salt=8)                   # lago ao pé da serra
    p.ponte(25, 17, 27, 18, 1)                        # pinguela da encosta
    p.placa("Boca da gruta", 41, 7, "Um vento frio sai da pedra. Lá dentro se ouve água correndo e, mais longe, um eco que parece um sino.")
    p.placa("Moinho de pedra", 48, 12, "Um moinho de pedra virado para o vale. As pás foram trocadas por pipas velhas, presas no eixo.")
    p.quest_npc("Iara", "iara", 36, 38, "grutaIara")
    p.event("npc", "Tito", 38, 38, {"district": "morro", "npcIdentity": "juninho", "bloqueia": False, "requer": "grutaTitoAchado",
                                     "texto": "Tito: Lá no fundo da gruta tem um lago, e no meio do lago dorme um bicho de pedra enorme. Eu vi!"})
    p.quest_item(52, 17, "pa-do-moinho", "Pá do moinho", "planicieMoinhoPedido")
    p.event("interacao", "Sombra do moinho", 50, 15, {"acao": "wildRest"})
    p.bench(50, 14, "madeira")
    decorate_field(p, trees=[(6, 26), (14, 50), (34, 46), (58, 30), (8, 38), (54, 20)],
                   groves=[(3, 20), (4, 52), (20, 54), (42, 54), (60, 50), (61, 22), (12, 16)],
                   rocks=[(30, 33), (46, 36), (56, 38), (18, 18), (44, 18)],
                   flowers=[(10, 30), (22, 44), (40, 34), (52, 32), (30, 16), (40, 12), (48, 26)],
                   kites=[(36, 6), (50, 40)])
    p.tesouros([(31, 6, "papel-seda", True), (59, 26, "linha-encerada", True), (10, 46, "cola-reparo", False), (49, 9, "moedas", True)])
    for name, u, v in [("chegada", 6, 31), ("serra", 34, 14), ("gruta", 43, 8), ("riacho", 24, 20), ("lago", 14, 44)]:
        p.shot(name, u, v)
    p.frame_trees()
    return p


def planicie_c():
    """Vale das Pedras. Duas chegadas: pelo norte (Planície A) e pelo leste (Planície B).
    No meio, o círculo de pedras e um rio rebaixado com ponte. A oeste, atrás da crista de
    rocha, o vale escondido: a entrada óbvia é a saída da Gruta do Moinho; por fora, só uma
    fenda estreita ao pé da colina do círculo."""
    p = planicie("c", "Vale das Pedras", 25200)
    p.blob(38, 28, 24, 25, "grama", 0, salt=31, rough=.12)
    p.path([(38, 0), (38, 10), (40, 24), (46, 34), (54, 40), (63, 40)], 3, "terra", 0)
    p.arrival(38, 3)
    p.edge_exit(38, 0, "planicie-a", (38, 52), "Subir para os Campos do Vento")
    p.edge_exit(63, 40, "planicie-b", (61, 42), "Voltar às Colinas do Moinho")
    # Rio rebaixado que corta o vale de norte a sul, com ponte
    p.path([(26, 2), (28, 14), (30, 26), (32, 40), (30, 54)], 3, "agua", -1)
    p.path([(33, 26), (40, 24)], 3, "terra", 0)
    p.path([(22, 26), (29, 26)], 3, "terra", 0)
    p.ponte(29, 25, 32, 27, 0)
    # Círculo de pedras (oeste do rio)
    p.blob(18, 34, 8, 6, "grama", 1, salt=33)
    p.stairs(15, 40, 3, 0)
    p.path([(16, 43), (22, 43), (24, 34), (22, 26)], 3, "terra", 0)
    for k in range(8):
        a = k * math.tau / 8
        p.piece("pedra", int(18 + math.cos(a) * 4.5), int(34 + math.sin(a) * 3.2), 1, 1, True, str(k % 3), "Pedra do círculo")
    # Crista de rocha que esconde o vale oeste (sem passagem)
    p.blob(10, 16, 4, 12, "rocha", 2, salt=35, rough=.1)
    # Vale escondido (oeste): só pela gruta
    p.blob(5, 30, 4.5, 10, "grama", 0, salt=37)
    p.rect(0, 28, 2, 30, "grama", 0)
    p.path([(7, 25), (12, 25)], 1, "terra", 0)        # fenda estreita na crista de rocha
    p.piece("mina-cave", 1, 26, 1, 1, True, "entrada-gruta", "Saída da Gruta do Moinho")
    p.arrival(3, 29, "Saída da gruta")
    p.edge_exit(0, 29, "caverna-c", (60, 30), "Voltar para a gruta")
    p.placa("Vale escondido", 6, 34, "Um vale pequeno, fechado pela crista de rocha. Alguém deixou pipas de pedra-pomes enfileiradas no chão, como num varal.")
    p.quest_item(19, 35, "pa-do-moinho", "Pá do moinho", "planicieMoinhoPedido")
    p.placa("Círculo de pedras", 18, 34, "Oito pedras em roda. No centro, o capim não cresce: o vento ali gira sozinho.")
    p.morador("Dora", "dora", 42, 30, "O rio divide o vale. Do outro lado da crista dizem que tem um canto escondido, mas ninguém acha a passagem por fora.")
    p.event("interacao", "Sombra da figueira", 50, 20, {"acao": "wildRest"})
    p.bench(50, 19, "madeira")
    decorate_field(p, trees=[(48, 12), (56, 28), (44, 48), (36, 36), (54, 52), (5, 22)],
                   groves=[(60, 12), (62, 30), (40, 54), (24, 52), (20, 6), (50, 4)],
                   rocks=[(46, 18), (52, 34), (40, 44), (7, 38), (3, 24)],
                   flowers=[(44, 26), (50, 46), (36, 16), (58, 20), (18, 30), (4, 33), (7, 27)],
                   kites=[(18, 38), (6, 31)])
    p.tesouros([(2, 36, "linha-encerada", True), (7, 23, "moedas", False), (15, 30, "papel-seda", True), (50, 46, "cola-reparo", True)])
    for name, u, v in [("chegada", 38, 6), ("ponte", 31, 26), ("circulo", 18, 34), ("vale", 5, 30), ("leste", 58, 40)]:
        p.shot(name, u, v)
    p.frame_trees()
    return p


# ---------------------------------------------------------------------------
# Cavernas
# ---------------------------------------------------------------------------

class Gruta(Campo):
    def __init__(self, part, title, event_base):
        super().__init__("caverna-" + part, "Gruta do Moinho", "caverna", part.upper(), "Gruta do Moinho · " + title, event_base,
                         {"mine": True, "mural": True, "cutFill": True, "baseLevel": 0, "stream": True, "nativeProps": True, "closedStairs": True, "rails": [], "frames": []})
        self.mat = [["rocha"] * W for _ in range(H)]
        self.lvl = [[4] * W for _ in range(H)]           # rocha acima do chão mais alto

    def cave(self, kind, u, v, name):
        self.piece("mina-cave", u, v, 1, 1, True, kind, name)

    def frame_trees(self):
        pass

    def bau(self, u, v, item, amount):
        assert self.mat[v][u] in ("terra", "grama") and not self.ramp[v][u], f"baú fora do chão em {u},{v}"
        self.piece("bau", u, v, 1, 1, True, "fechado", "Baú da gruta", {"item": item, "quantidade": str(amount)})


def caverna_a():
    """Entrada da Gruta. Chega pelo sul (boca da gruta). Galerias sinuosas sobem um patamar;
    um rio subterrâneo cai num poço; becos com baús. Sai pelo oeste."""
    p = Gruta("a", "Galeria do Rio", 25300)
    p.blob(32, 50, 6, 4, "terra", 0, salt=41)
    p.rect(30, 52, 34, 55, "terra", 0)
    p.arrival(32, 52, "Entrada da gruta")
    p.edge_exit(32, 55, "planicie-b", (43, 9), "Sair para as Colinas do Moinho")
    p.path([(32, 48), (26, 42), (16, 40), (8, 36)], 3, "terra", 0)
    p.path([(32, 48), (42, 44), (52, 40)], 3, "grama", 0)
    p.blob(54, 38, 6, 4, "grama", 0, salt=43)          # salão dos cogumelos (sem saída)
    p.blob(10, 34, 6, 4, "terra", 0, salt=45)
    p.stairs(10, 29, 3, 0)
    p.blob(14, 22, 10, 6, "terra", 1, salt=47)         # patamar do rio
    p.path([(14, 22), (8, 20), (1, 20)], 3, "terra", 1)
    p.edge_exit(0, 20, "caverna-b", (61, 22), "Seguir pela galeria oeste")
    p.path([(20, 20), (32, 16), (44, 14)], 3, "terra", 1)
    p.blob(46, 14, 6, 4, "terra", 1, salt=49)          # galeria dos cristais (sem saída)
    # Rio subterrâneo: nasce no alto (rocha), cai no poço do patamar
    p.pool(30, 30, 4, 3, 1, salt=3)
    p.rect(29, 24, 31, 27, "agua", 0)
    p.rect(29, 21, 31, 23, "agua", 1)                 # fenda da parede
    p.fall(29, 23, 3)
    p.path([(26, 28), (24, 34), (26, 38)], 3, "terra", 1)
    p.stairs(25, 39, 3, 0)
    for kind, u, v in [("cristal-azul", 48, 12), ("cristal-ambar", 44, 16), ("cogumelos-gruta", 56, 36), ("cogumelos-gruta", 52, 40),
                       ("estalagmite-alta", 18, 38), ("estalagmite-baixa", 36, 46), ("coluna-calcario", 12, 24), ("rocha-solta", 22, 18)]:
        p.cave(kind, u, v, "Formação da gruta")
    p.bau(57, 38, "moedas", 40)
    p.bau(49, 15, "kit-remendo", 1)
    p.quest_item(44, 13, "pa-do-moinho", "Pá do moinho", "planicieMoinhoPedido")
    p.bau(6, 34, "linha-encerada", 2)
    p.placa("Rio da gruta", 25, 31, "A água cai de uma fenda no teto e enche o poço. A Gruta do Moinho respira junto com o rio.")
    p.placa("Salão dos cogumelos", 52, 37, "Cogumelos que brilham azul. Quando o Rabbito passa, eles acendem um pouco mais.")
    p.event("interacao", "Fonte de água fresca", 16, 21, {"acao": "wildRest"})
    for name, u, v in [("entrada", 32, 50), ("rio", 30, 27), ("cogumelos", 54, 38), ("cristais", 46, 14)]:
        p.shot(name, u, v)
    return p


def caverna_b():
    """Galerias de Cristal. Chega pelo leste. Um labirinto de galerias em três patamares,
    com becos de cristal. Sai pelo norte."""
    p = Gruta("b", "Galerias de Cristal", 25400)
    p.rect(58, 20, 63, 24, "terra", 0)
    p.arrival(61, 22, "Galeria leste")
    p.edge_exit(63, 22, "caverna-a", (2, 20), "Voltar para a Galeria do Rio")
    p.path([(58, 22), (48, 26), (40, 34), (30, 40), (18, 44), (8, 46)], 3, "terra", 0)
    p.path([(48, 26), (52, 36), (54, 46)], 3, "grama", 0)
    p.blob(54, 48, 5, 4, "grama", 0, salt=51)          # beco do cristal âmbar (sem saída)
    p.blob(8, 46, 5, 4, "terra", 0, salt=53)           # beco oeste (sem saída)
    p.path([(30, 40), (29, 30)], 3, "terra", 0)
    p.stairs(28, 27, 3, 0)
    p.blob(28, 22, 9, 5, "terra", 1, salt=55)          # salão central
    p.path([(22, 22), (10, 20), (8, 14)], 3, "terra", 1)
    p.blob(9, 12, 5, 3.5, "terra", 1, salt=57)         # beco dos cristais azuis (sem saída)
    p.path([(34, 20), (42, 16), (42, 15)], 3, "terra", 1)
    p.stairs(41, 12, 3, 1)
    p.blob(42, 8, 8, 3.5, "terra", 2, salt=59)         # galeria alta
    p.path([(42, 6), (40, 1)], 3, "terra", 2)
    p.rect(39, 0, 41, 1, "terra", 2)
    p.edge_exit(40, 0, "caverna-c", (40, 52), "Subir para o Lago Subterrâneo")
    p.pool(18, 30, 4, 3, 1, salt=7)                    # poço do salão
    p.rect(17, 21, 23, 24, "rocha", 3)
    p.rect(19, 22, 21, 24, "agua", 2)                 # fenda que verte no poço
    p.rect(19, 25, 21, 27, "agua", 0)
    p.fall(19, 24, 3)
    for kind, u, v in [("cristal-azul", 8, 10), ("cristal-azul", 11, 13), ("cristal-ambar", 56, 49), ("cristal-ambar", 52, 47),
                       ("estalagmite-alta", 36, 36), ("coluna-calcario", 30, 20), ("estalagmite-baixa", 46, 8), ("cogumelos-gruta", 6, 47)]:
        p.cave(kind, u, v, "Formação da gruta")
    p.bau(55, 50, "moedas", 60)
    p.bau(7, 13, "cola-reparo", 2)
    p.bau(5, 46, "papel-seda", 3)
    p.bau(36, 9, "linha-encerada", 2)
    p.quest_npc("Tito", "juninho", 9, 11, "grutaTito", requer="grutaTitoPedido", ocultar_apos="grutaTitoAchado")
    p.placa("Galerias de Cristal", 27, 24, "Cristais crescem do teto ao chão. A luz das pipas se parte neles em mil pontos coloridos.")
    p.event("interacao", "Fonte de água fresca", 32, 22, {"acao": "wildRest"})
    for name, u, v in [("entrada", 58, 22), ("salao", 28, 22), ("cristais", 9, 12), ("alto", 42, 7)]:
        p.shot(name, u, v)
    return p


def caverna_c():
    """Lago Subterrâneo. Chega pelo sul. Um lago enorme rebaixado ocupa o salão; uma
    cachoeira desce da parede norte; uma ilha se alcança por uma ponte de pedra. Sai pelo
    leste, para o vale escondido da Planície C."""
    p = Gruta("c", "Lago Subterrâneo", 25500)
    p.rect(38, 50, 42, 55, "terra", 0)
    p.arrival(40, 52, "Galeria sul")
    p.edge_exit(40, 55, "caverna-b", (40, 2), "Descer para as Galerias de Cristal")
    p.blob(36, 30, 22, 16, "terra", 0, salt=61, rough=.15)
    p.pool(34, 28, 13, 9, 0, salt=9)                   # o lago
    p.blob(30, 25, 4.5, 3, "grama", 0, salt=63)        # ilha
    p.ponte(30, 28, 32, 37, 0)                        # ponte de pedra até a ilha
    p.path([(40, 50), (40, 42)], 3, "terra", 0)
    p.path([(54, 30), (63, 30)], 3, "terra", 0)
    p.edge_exit(63, 30, "planicie-c", (3, 29), "Sair para o vale escondido")
    p.blob(36, 10, 9, 3.5, "terra", 1, salt=65)        # varanda norte
    p.stairs(35, 14, 3, 0)
    p.rect(27, 10, 29, 12, "agua", 0)                 # tanque da varanda (rebaixado)
    p.rect(27, 13, 29, 19, "agua", -1)
    p.fall(27, 12, 3)
    p.blob(10, 40, 5, 4, "grama", 0, salt=67)          # recanto oeste (sem saída)
    p.path([(14, 40), (20, 40)], 3, "terra", 0)
    for kind, u, v in [("cristal-azul", 12, 38), ("cogumelos-gruta", 8, 42), ("estalagmite-alta", 50, 40), ("coluna-calcario", 22, 44),
                       ("cristal-ambar", 42, 9), ("estalagmite-baixa", 56, 26), ("rocha-solta", 46, 44)]:
        p.cave(kind, u, v, "Formação da gruta")
    p.bau(30, 25, "moedas", 80)
    p.event("npc", "Estratonte", 32, 24, {"acao": "grutaBoss", "storySpritePath": "res://assets/campaign/planicies-v1/estratonte.png",
                                          "ocultar_apos": "grutaEstratonteVencido", "bloqueia": True})
    p.bau(9, 40, "kit-remendo", 1)
    p.bau(40, 8, "linha-encerada", 3)
    p.placa("Lago Subterrâneo", 44, 36, "Um lago parado no escuro. A cachoeira do norte é o único som; no meio, uma ilha com um baú que ninguém abriu.")
    p.placa("Varanda norte", 36, 9, "Daqui se vê o lago inteiro e, do outro lado, a luz do vale entrando pela saída leste.")
    p.event("interacao", "Fonte de água fresca", 52, 32, {"acao": "wildRest"})
    for name, u, v in [("entrada", 40, 48), ("lago", 34, 30), ("ilha", 30, 26), ("cachoeira", 28, 14), ("saida", 58, 30)]:
        p.shot(name, u, v)
    return p


AREAS = {"pa": planicie_a, "pb": planicie_b, "pc": planicie_c, "ca": caverna_a, "cb": caverna_b, "cc": caverna_c}

if __name__ == "__main__":
    for key in (sys.argv[1:] or list(AREAS)):
        plan = AREAS[key]()
        plan.write()
        print("escrito", plan.scene, len(plan.pieces), "peças", len(plan.events), "eventos")
