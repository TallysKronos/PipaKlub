#!/usr/bin/env python3
"""Serra Gelada (região de gelo, exploração), áreas A–C.

Três mapas de 64×56 ligados em sequência: a saída no alto de A chega no pé de B, e a de B
no pé de C. Em C fica a arena do chefe (Borealvo, kind "geleira-boss").

Matéria do bioma (forest.ice, renderizador kronasta_forest.gd + ice_structures.gd):
  grama = neve · terra = trilha batida (pegadas) · piso = gelo (lago congelado, andável)
  agua = água corrente (forest.stream) · rocha = fundo de fenda · bosque = neve fechada fora do caminho
Quedas: forest.waterFalls (água correndo) e forest.iceFalls (cachoeira congelada).

    python3 tools/gerar-mapas-geleira.py && node tools/compilar-mapas.mjs serra-gelada-a serra-gelada-b serra-gelada-c

Escadas sobem para v− (o fundo da tela), como no Morro (tools/gerar-mapas-morro.py).
"""
import importlib.util
import os

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("morro", os.path.join(HERE, "gerar-mapas-morro.py"))
morro = importlib.util.module_from_spec(spec)
spec.loader.exec_module(morro)
W, H, cidade = morro.W, morro.H, morro.cidade


class Gelo(morro.Morro):
    def __init__(self, part, title, event_base):
        super().__init__(0)
        self.scene = self.game_scene = "serra-gelada-" + part
        self.name, self.region, self.part, self.title = "Serra Gelada", "serra-gelada", part.upper(), "Serra Gelada · " + title
        self.mat = [["bosque"] * W for _ in range(H)]         # fora do caminho: neve fechada
        self.forest = {"ice": True, "baseLevel": 3, "softTone": True, "stream": True, "nativeProps": True, "closedStairs": True, "trails": [], "shots": []}
        self._event_id = event_base
        self._item_id = event_base + 30

    def placa(self, name, u, v, texto, **extra):
        self.event("interacao", name, u, v, dict({"texto": texto}, **extra))

    def write(self):
        super().write()
        import json
        path = os.path.join(cidade.MAPS, self.scene + ".tmj")
        tmj = json.load(open(path))
        for prop in tmj["properties"]:
            if prop["name"] == "bioma":
                prop["value"] = "floresta"
        json.dump(tmj, open(path, "w"), ensure_ascii=False, indent=1)

    # ---- chão ----
    def neve(self, u0, v0, u1, v1, level):
        self.rect(u0, v0, u1, v1, "grama", level)

    def trilha(self, u0, v0, u1, v1, level):
        self.rect(u0, v0, u1, v1, "terra", level)

    def lago(self, u0, v0, u1, v1, terrace):
        """Lago congelado rebaixado um nível em relação ao terraço (andável)."""
        morro.Plan.rect(self, u0, v0, u1, v1, "piso", terrace + self.BASE - 1)

    def gelo(self, u0, v0, u1, v1, level):
        """Placa de gelo no nível do terraço (andável)."""
        self.rect(u0, v0, u1, v1, "piso", level)

    def icefall(self, u, v, width):
        """Cachoeira congelada na face da frente (+v) das células (u…u+width−1, v)."""
        drop = self.lvl[v][u] - self.lvl[v + 1][u]
        for du in range(width):
            assert self.lvl[v][u + du] - self.lvl[v + 1][u + du] == drop >= 1, f"queda congelada irregular em {u + du},{v}"
        self.forest.setdefault("iceFalls", []).append({"u": u, "v": v, "width": width, "drop": drop})

    def trail(self, points):
        self.forest["trails"].append([[u, v] for u, v in points])

    # ---- entradas e saídas ----
    def chegada(self, u, back_scene, back_u, name):
        self.trilha(u - 3, H - 6, u + 3, H - 1, 0)
        self.event("entrada", "Chegada", u, H - 3, {})
        props = {"destino": back_scene}
        if back_scene != "kronasta":
            props.update({"chegada_u": back_u, "chegada_v": 1})
        self.event("saida", name, u, H - 1, props)

    def subida(self, u, level, next_scene, next_u, name):
        self.trilha(u - 2, 0, u + 2, 1, level)
        self.event("saida", name, u, 0, {"destino": next_scene, "chegada_u": next_u, "chegada_v": H - 4})

    # ---- peças ----
    def prop(self, kind, u, v, fu, fv, name, blocks=True, **extra):
        for dv in range(fv):
            for du in range(fu):
                assert not self.ramp[v + dv][u + du] and self.mat[v + dv][u + du] not in ("agua",), f"{kind} sobre escada ou água em {u},{v}"
        self.piece("gelo-prop", u, v, fu, fv, blocks, kind, name, {k: str(val) for k, val in extra.items()})

    def pinheiros(self, cells):
        for u, v in cells:
            self.prop("pinheiro", u, v, 1, 1, "Pinheiro nevado")

    def estacas(self, cells):
        for u, v in cells:
            self.piece("gelo-marker", u, v, 1, 1, True, "estaca", "Estaca da expedição")

    def frame_trees(self):
        """Moldura: pinheiros sobre o paredão perto do que se anda (sem colisão nova)."""
        walk = {(u, v) for v in range(H) for u in range(W) if self.mat[v][u] not in ("rocha", "bosque")}
        for v in range(H):
            for u in range(W):
                if self.mat[v][u] != "bosque" or self.lvl[v][u] != 0:
                    continue
                near = any((u + du, v + dv) in walk for du in range(-2, 3) for dv in range(-2, 3))
                if near and cidade._hash(u, v, 41) < .22:
                    self.piece("gelo-prop", u, v, 1, 1, False, "pinheiro", "Pinheiro nevado")


def area_a():
    """Vale Congelado (6 níveis). Chegada no sul. A oeste, o lago congelado rebaixado e um
    campo de neve; no meio, uma fenda funda cortada por uma ponte; a leste, a nascente que
    despenca três níveis pela grota até o poço. O caminho sobe pelo leste até o passo norte."""
    p = Gelo("a", "Vale Congelado", 23000)
    p.chegada(42, "kronasta", 0, "Voltar a Kronasta")
    # Nível 0 — margem sul e campo de neve a oeste
    p.neve(30, 42, 58, 50, 0)
    p.trilha(38, 44, 46, 50, 0)
    p.neve(4, 38, 28, 45, 0)
    p.neve(24, 42, 34, 47, 0)
    p.lago(6, 46, 24, 53, 0)                          # lago congelado (um nível abaixo)
    p.stairs(12, 44, 3, -1)
    p.water(50, 44, 57, 49, 0)                        # poço da cachoeira
    # Nível 1 — patamares leste e oeste
    p.neve(36, 28, 49, 40, 1)
    p.stairs(40, 41, 3, 0)
    p.neve(4, 32, 22, 37, 1)
    p.stairs(14, 38, 3, 0)
    # Nível 2 — o meio e o terraço oeste, separados pela fenda
    p.neve(4, 20, 24, 31, 2)
    p.stairs(8, 32, 3, 1)
    p.neve(28, 19, 48, 27, 2)
    p.trilha(30, 22, 46, 24, 2)
    p.stairs(42, 28, 3, 1)
    p.grota(25, 12, 27, 40)                           # fenda funda
    p.ponte(25, 22, 27, 24, 2)
    # Nível 3 — pico oeste (sem saída) e o terraço da nascente
    p.neve(4, 10, 16, 19, 3)
    p.stairs(8, 20, 3, 2)
    p.gelo(5, 11, 9, 13, 3)
    p.neve(40, 8, 60, 18, 3)
    p.stairs(44, 19, 3, 2)
    p.water(52, 11, 57, 14, 3)                        # nascente
    p.water(53, 15, 54, 18, 3)
    p.grota(50, 19, 59, 43)
    p.water(53, 19, 54, 43, 0)                        # a água desce a grota até o poço
    p.fall(53, 18, 2)
    # Nível 4 — o passo norte
    p.neve(40, 0, 56, 7, 4)
    p.stairs(46, 8, 3, 3)
    p.subida(49, 4, "serra-gelada-b", 49, "Seguir pelo passo norte")
    p.icefall(5, 19, 3)                               # cortina de gelo no pico oeste
    # Gente, placas e pausa
    p.morador("Celina", "celina", 44, 47, "A Serra Gelada parece parada, mas a água corre por baixo do gelo. Siga o barulho da nascente: o passo norte fica lá em cima.")
    p.placa("Lago congelado", 15, 49, "O gelo é grosso e firme. Por baixo, peixes prateados passam devagar, como pipas num céu escuro.")
    p.placa("Ponte da fenda", 28, 23, "Tábuas amarradas com linha de pipa. Alguém da expedição confiou a travessia ao mesmo fio que solta as pipas.")
    p.placa("Pico oeste", 6, 15, "Daqui se vê o vale inteiro. A cortina de gelo desce do pico como um véu parado no tempo.")
    p.placa("Nascente", 50, 12, "A água brota quente da pedra e fumega no ar gelado. Por isso a nascente nunca congela.")
    p.prop("abrigo", 30, 44, 3, 3, "Abrigo da expedição")
    p.event("interacao", "Fogueira do abrigo", 33, 47, {"acao": "wildRest"})
    p.prop("formacao", 16, 48, 3, 3, "Formação de gelo")
    p.prop("cristal", 44, 33, 2, 2, "Cristal de gelo")
    p.prop("rocha", 30, 25, 3, 2, "Rocha nevada")
    p.prop("cristal", 58, 12, 2, 2, "Cristal da nascente")
    p.pinheiros([(6, 39), (20, 40), (36, 42), (57, 42), (5, 33), (20, 35), (37, 29), (48, 30), (6, 22), (22, 29), (29, 20), (46, 26), (14, 11), (41, 9), (59, 17), (42, 2), (55, 6)])
    p.estacas([(39, 49), (41, 37), (43, 22), (45, 15), (47, 5)])
    p.kites([(10, 41), (34, 26)])
    p.trail([(42, 52), (42, 42), (41, 37), (43, 28), (43, 21), (45, 16), (47, 6), (49, 1)])
    p.tesouro(22, 52, "papel-seda")                   # fundo do lago
    p.tesouro(7, 12, "linha-encerada")                # pico oeste
    p.tesouro(58, 47, "cola-reparo")                  # beira do poço
    p.tesouro(59, 9, "papel-seda")                    # atrás da nascente
    p.tesouro(5, 30, "linha-encerada", escondido=False)
    for name, u, v in [("chegada", 42, 47), ("lago", 15, 49), ("fenda", 26, 23), ("nascente", 53, 15), ("pico-oeste", 9, 14), ("passo", 48, 4)]:
        p.shot(name, u, v)
    p.frame_trees()
    return p


def area_b():
    """Desfiladeiro de Gelo (5 níveis). O caminho sobe em zigue-zague pela encosta leste e
    atravessa para o oeste por uma passarela. No centro, uma cascata congelada despenca três
    níveis do platô até a fenda, sobre a Gruta da Cascata, um recanto sem saída. A oeste, um riacho cai num
    poço ao lado das ruínas de um acampamento."""
    p = Gelo("b", "Desfiladeiro de Gelo", 23100)
    p.chegada(49, "serra-gelada-a", 49, "Voltar ao Vale Congelado")
    # Nível 0 — fundo do desfiladeiro
    p.neve(36, 44, 60, 50, 0)
    p.trilha(46, 45, 52, 50, 0)
    p.neve(18, 30, 36, 40, 0)                         # Gruta da Cascata (sem saída)
    p.gelo(22, 30, 32, 34, 0)
    p.neve(30, 40, 40, 46, 0)
    # Nível 1 — encosta leste
    p.neve(44, 34, 60, 41, 1)
    p.stairs(52, 42, 3, 0)
    # Nível 2
    p.neve(40, 24, 60, 31, 2)
    p.stairs(46, 32, 3, 1)
    p.trilha(42, 26, 58, 28, 2)
    # Nível 3 — a passarela e o oeste
    p.neve(46, 14, 60, 21, 3)
    p.stairs(54, 22, 3, 2)
    p.ponte(36, 16, 45, 18, 3)                        # passarela sobre o desfiladeiro
    p.neve(4, 12, 35, 20, 3)
    p.water(8, 13, 13, 15, 3)                         # riacho do acampamento
    p.water(10, 16, 11, 20, 3)
    p.grota(6, 21, 16, 34)
    p.water(10, 21, 11, 30, 0)
    p.water(7, 31, 14, 34, 0)                         # poço do acampamento
    p.fall(10, 20, 2)
    p.neve(4, 35, 17, 42, 0)                          # margem do poço (sem saída, chega pela gruta)
    p.neve(16, 38, 20, 41, 0)
    # A cascata congelada: borda do platô alto sobre a gruta
    p.neve(20, 22, 34, 28, 2)                         # platô da cascata (desce do oeste)
    p.stairs(26, 21, 3, 2)
    p.gelo(22, 27, 32, 28, 2)
    p.grota(18, 29, 36, 29)
    # Nível 4 — o alto e a saída
    p.neve(4, 2, 30, 9, 4)
    p.stairs(12, 10, 3, 3)
    p.subida(18, 4, "serra-gelada-c", 32, "Subir para a Coroa Glacial")
    p.icefall(22, 28, 11)
    p.morador("Nilo", "nilo", 48, 37, "O desfiladeiro engana: o caminho sobe pelo leste e volta pelo alto. Lá embaixo, atrás da cortina de gelo, tem uma gruta que pouca gente conhece.")
    p.placa("Gruta da Cascata", 29, 33, "Atrás da cascata congelada o gelo é azul-escuro e faz eco. No chão, marcas de pata maiores que um homem.")
    p.placa("Passarela", 40, 17, "Uma passarela de tábuas sobre o desfiladeiro. O vento assobia por baixo, num tom que lembra uma pipa cortando o ar.")
    p.placa("Acampamento abandonado", 8, 37, "Barracas rasgadas e um caderno com uma frase repetida: \"ele protege o topo; não suba sem estar pronto\".")
    p.prop("abrigo", 5, 38, 3, 3, "Acampamento abandonado")
    p.prop("formacao", 24, 36, 4, 3, "Formação de gelo")
    p.prop("cristal", 56, 46, 2, 2, "Cristal de gelo")
    p.prop("rocha", 41, 45, 3, 2, "Rocha nevada")
    p.prop("cristal", 33, 13, 2, 2, "Cristal de gelo")
    p.event("interacao", "Abrigo da passarela", 58, 16, {"acao": "wildRest"})
    p.prop("abrigo", 57, 18, 3, 3, "Abrigo da passarela")
    p.pinheiros([(38, 45), (59, 45), (31, 41), (45, 35), (59, 39), (41, 25), (59, 29), (47, 15), (5, 13), (20, 19), (30, 13), (5, 3), (29, 8), (21, 23), (33, 25)])
    p.estacas([(50, 46), (53, 40), (47, 30), (55, 20), (44, 17), (27, 18), (16, 13), (17, 3)])
    p.kites([(57, 26), (16, 14)])
    p.trail([(49, 52), (52, 44), (47, 33), (55, 23), (46, 17), (36, 17), (27, 19), (13, 12), (18, 1)])
    p.tesouro(33, 32, "cola-reparo")                  # gruta da cascata
    p.tesouro(16, 40, "papel-seda")                   # beira do poço
    p.tesouro(5, 9, "linha-encerada")                 # canto do alto
    p.tesouro(33, 27, "papel-seda")                   # beira da cascata
    p.tesouro(59, 49, "linha-encerada", escondido=False)
    for name, u, v in [("chegada", 49, 47), ("gruta", 27, 34), ("cascata", 27, 26), ("passarela", 40, 17), ("acampamento", 9, 36), ("alto", 18, 5)]:
        p.shot(name, u, v)
    p.frame_trees()
    return p


def area_c():
    """Coroa Glacial (7 níveis). A subida final contorna o pico pelo oeste, cruza um lago
    congelado elevado e chega à arena: um platô de gelo cercado de cristais onde o Borealvo
    guarda o topo. Atrás da arena, o santuário (aberto depois da vitória) e um mirante."""
    p = Gelo("c", "Coroa Glacial", 23200)
    p.chegada(32, "serra-gelada-b", 18, "Voltar ao Desfiladeiro de Gelo")
    # Nível 0 e 1 — a base
    p.neve(20, 44, 46, 50, 0)
    p.trilha(29, 45, 35, 50, 0)
    p.neve(4, 36, 26, 43, 1)
    p.stairs(22, 44, 3, 0)
    p.neve(42, 38, 60, 46, 0)                         # beira do riacho (sem saída)
    p.water(46, 40, 58, 44, 0)
    # Nível 2 — o lago elevado
    p.neve(4, 26, 34, 33, 2)
    p.stairs(8, 34, 3, 1)
    p.gelo(12, 28, 26, 31, 2)                         # lago congelado (rente, atravessável)
    p.stairs(5, 26, 3, 2)                             # subida para o terraço do mirante
    # Nível 3 e 4 — a rampa do pico
    p.neve(30, 18, 48, 25, 3)
    p.stairs(30, 26, 3, 2)
    p.neve(50, 12, 61, 25, 4)
    p.stairs(52, 26, 3, 3)
    p.neve(48, 26, 58, 33, 3)
    p.water(53, 14, 58, 18, 4)                        # degelo do pico
    p.water(55, 19, 56, 25, 4)
    p.grota(53, 34, 59, 37)
    p.water(55, 26, 56, 39, 0)                        # o degelo desce até o riacho
    p.fall(55, 25, 2)
    p.neve(4, 14, 22, 21, 4)                          # mirante oeste (sem saída)
    p.neve(4, 22, 22, 25, 3)
    p.stairs(10, 22, 3, 3)
    p.icefall(4, 21, 4)
    # Nível 5 e 6 — a arena do chefe
    p.neve(24, 4, 50, 15, 5)
    p.neve(42, 16, 49, 19, 4)                         # patamar da arena
    p.stairs(44, 20, 3, 3)
    p.stairs(42, 16, 3, 4)
    p.gelo(28, 6, 46, 13, 5)                          # platô de gelo da arena
    p.neve(28, 0, 38, 3, 6)                           # santuário (só depois da vitória)
    p.stairs(32, 4, 3, 5)
    p.icefall(46, 15, 3)
    p.event("npc", "Borealvo", 37, 9, {"acao": "geleiraBoss", "storySpritePath": "res://assets/campaign/geleira-v1/borealvo.png", "ocultar_apos": "geleiraBorealvoVencido", "bloqueia": True})
    p.placa("Marcas de garra", 44, 18, "Riscos fundos no gelo, em círculo. Algo grande anda em volta do topo, vigiando.")
    p.placa("Santuário da Coroa", 33, 1, "Uma pipa de gelo presa no altar, intacta. Diziam que só quem o Borealvo aceitasse poderia chegar até aqui.", requer="geleiraBorealvoVencido")
    p.placa("Mirante oeste", 6, 16, "A cortina de gelo cai do mirante até o terraço de baixo. Daqui se vê a Serra Gelada inteira e, longe, o Morro do Sol.")
    p.placa("Lago elevado", 14, 30, "Um lago preso no alto da serra. O gelo canta quando alguém passa.")
    p.morador("Iara", "iara", 26, 47, "Lá em cima mora o Borealvo, o guardião da Coroa. Ele não ataca à toa, mas não deixa ninguém passar sem provar a força.")
    p.event("interacao", "Abrigo do pico", 52, 22, {"acao": "wildRest"})
    p.prop("abrigo", 57, 21, 3, 3, "Abrigo do pico")
    for u, v in [(28, 5), (46, 5), (26, 10), (48, 11), (30, 14), (40, 4)]:
        p.prop("cristal", u, v, 2, 2, "Cristal da arena")
    p.prop("formacao", 6, 37, 3, 3, "Formação de gelo")
    p.prop("rocha", 32, 20, 3, 2, "Rocha nevada")
    p.pinheiros([(21, 45), (45, 45), (5, 41), (25, 38), (43, 39), (9, 29), (33, 28), (31, 19), (47, 23), (5, 15), (21, 20), (61, 13), (49, 30)])
    p.estacas([(30, 47), (23, 40), (12, 33), (31, 24), (47, 22), (53, 24), (48, 18)])
    p.trail([(32, 52), (23, 44), (9, 36), (31, 28), (40, 22), (53, 27), (53, 20), (43, 17), (37, 12)])
    p.tesouro(57, 45, "cola-reparo")                  # beira do riacho
    p.tesouro(5, 19, "linha-encerada")                # mirante oeste
    p.tesouro(25, 28, "papel-seda")                   # ilha do lago
    p.tesouro(60, 15, "papel-seda")                   # degelo do pico
    p.item(p._item_id + 10, 36, 1, "linha-encerada", "brilho", "Linha do santuário")
    p.events[-1]["properties"].append({"name": "requer", "type": "string", "value": "geleiraBorealvoVencido"})
    for name, u, v in [("chegada", 32, 47), ("lago", 18, 30), ("degelo", 55, 22), ("arena", 37, 9), ("mirante", 9, 17), ("santuario", 33, 2)]:
        p.shot(name, u, v)
    p.frame_trees()
    return p


AREAS = {"a": area_a, "b": area_b, "c": area_c}

if __name__ == "__main__":
    import sys
    for key in (sys.argv[1:] or sorted(AREAS)):
        plan = AREAS[key]()
        plan.write()
        print("escrito", plan.scene, len(plan.pieces), "peças", len(plan.events), "eventos")
