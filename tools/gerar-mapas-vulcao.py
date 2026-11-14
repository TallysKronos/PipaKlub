#!/usr/bin/env python3
"""Vulcão de Kronasta · Caldeira (região de lava, exploração).

Um mapa de 64×56 com sete andares. A base inteira é lava (células "agua" com o material de
lava do renderizador, forest.lava). O jogador sobe por ilhas e prateleiras de basalto:
passarelas sobre a lava, um maciço alto a oeste, a cratera com o lago de lava a leste,
quedas de lava (forest.lavaFalls) e pontos sem saída com achados.

    python3 tools/gerar-mapas-vulcao.py && node tools/compilar-mapas.mjs vulcao-a

Escadas sobem para v− (o fundo da tela), como no Morro (tools/gerar-mapas-morro.py).
"""
import importlib.util
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("morro", os.path.join(HERE, "gerar-mapas-morro.py"))
morro = importlib.util.module_from_spec(spec)
spec.loader.exec_module(morro)
W, H, CX, cidade = morro.W, morro.H, morro.CX, morro.cidade


class Vulcao(morro.Morro):
    def __init__(self, scene, title):
        super().__init__(0)
        self.scene = scene
        self.game_scene = scene
        self.name, self.region, self.part, self.title = "Vulcão de Kronasta", "vulcao", "A", title
        self.mat = [["agua"] * W for _ in range(H)]          # tudo o que não é rocha é lava
        self.forest = {"harbor": True, "lava": True, "nativeProps": True, "closedStairs": True, "shots": []}
        self._event_id = 22000
        self._item_id = 22040

    def lava(self, u0, v0, u1, v1, terrace):
        """Poça ou lago de lava rebaixado um nível em relação ao terraço: as bordas viram
        paredes internas com o brilho da lava no pé (antes ficava rente ao chão, chapada)."""
        morro.Plan.rect(self, u0, v0, u1, v1, "agua", terrace + self.BASE - 1)

    def lavafall(self, u, v, width):
        """Queda de lava na face da frente (+v) das células (u…u+width−1, v); a altura sai do
        terreno (célula da borda menos a da frente)."""
        drop = self.lvl[v][u] - self.lvl[v + 1][u]
        for du in range(width):
            assert self.mat[v][u + du] == "agua" and self.mat[v + 1][u + du] == "agua", f"queda fora da lava em {u + du},{v}"
            assert self.lvl[v][u + du] - self.lvl[v + 1][u + du] == drop >= 1, f"queda irregular em {u + du},{v}"
        self.forest.setdefault("lavaFalls", []).append({"u": u, "v": v, "width": width, "drop": drop})

    def ponte(self, u0, v0, u1, v1, level):
        self.rect(u0, v0, u1, v1, "ponte", level)

    def rochas(self, cells):
        for i, (u, v) in enumerate(cells):
            assert self.mat[v][u] not in ("agua", "ponte") and not self.ramp[v][u], f"rocha fora do basalto em {u},{v}"
            self.piece("pedra", u, v, 1, 1, True, str((u + v + i) % 3), "Rocha vulcânica")

    def erode(self):
        """Bordas irregulares: come cantos e alguns trechos de borda das ilhas (nunca perto de
        escadas, pontes, eventos, peças ou poças), para o basalto não parecer caixote."""
        keep = set()
        def protect(u, v, r):
            for dv in range(-r, r + 1):
                for du in range(-r, r + 1):
                    keep.add((u + du, v + dv))
        for v in range(H):
            for u in range(W):
                if self.ramp[v][u] or self.mat[v][u] == "ponte" or (self.mat[v][u] == "agua" and self.lvl[v][u] > 0):
                    protect(u, v, 2)
        for obj in self.events + self.pieces:
            protect(obj["x"] // 32, obj["y"] // 32, 2)
        def sea(u, v):
            return not (0 <= u < W and 0 <= v < H) or (self.mat[v][u] == "agua" and self.lvl[v][u] == 0)
        cut = []
        for v in range(H):
            for u in range(W):
                if self.mat[v][u] == "agua" or (u, v) in keep:
                    continue
                n = [sea(u + 1, v), sea(u - 1, v), sea(u, v + 1), sea(u, v - 1)]
                # Só a borda que dá para a lava do nível do chão (mar de lava), não entre terraços.
                lower = [0 <= u + du < W and 0 <= v + dv < H and self.mat[v + dv][u + du] != "agua" and self.lvl[v + dv][u + du] != self.lvl[v][u]
                         for du, dv in ((1, 0), (-1, 0), (0, 1), (0, -1))]
                if any(lower):
                    continue
                chance = cidade._hash(u, v, 77)
                if sum(n) >= 2 or (sum(n) == 1 and chance < .3):
                    cut.append((u, v))
        for u, v in cut:
            self.mat[v][u] = "agua"
            self.lvl[v][u] = 0

    def write(self):
        self.erode()
        super().write()
        path = os.path.join(cidade.MAPS, self.scene + ".tmj")
        tmj = json.load(open(path))
        for prop in tmj["properties"]:
            if prop["name"] == "bioma":
                prop["value"] = "floresta"
        json.dump(tmj, open(path, "w"), ensure_ascii=False, indent=1)


def caldeira():
    """Desenho assimétrico (v2, 11/11): chegada no sudoeste; um maciço alto a oeste (seis
    níveis empilhados, com fendas até o mar de lava); a cratera deslocada para o leste, com a
    boca no nível 7. Quatro quedas de lava e cinco pontos sem saída."""
    p = Vulcao("vulcao-a", "Vulcão de Kronasta · Caldeira")
    # Nível 1 — a costa: ilha de chegada, ilhota, ilha leste e o rochedo isolado
    p.rect(8, 47, 22, 54, "piso", 1)                  # ilha de chegada (sudoeste)
    p.ponte(23, 50, 27, 51, 1)
    p.rect(28, 48, 34, 53, "piso", 1)                 # ilhota
    p.ponte(35, 49, 39, 50, 1)
    p.rect(40, 46, 50, 53, "piso", 1)                 # ilha leste
    p.ponte(51, 51, 54, 52, 1)
    p.rect(55, 49, 60, 54, "piso", 1)                 # rochedo isolado (sem saída)
    # Maciço oeste — níveis 2 a 6, um em cima do outro
    p.rect(5, 39, 20, 44, "piso", 2)
    p.stairs(10, 45, 3, 1)
    p.rect(9, 30, 24, 36, "piso", 3)
    p.stairs(15, 37, 3, 2)
    p.lava(18, 31, 21, 33, 3)                         # poça do terraço
    p.rect(3, 30, 7, 35, "piso", 3)                   # gruta do eco (degrau rebaixado, sem saída)
    p.rect(4, 21, 18, 27, "piso", 4)
    p.stairs(11, 28, 3, 3)
    p.stairs(4, 28, 3, 3)                             # descida para a gruta
    p.lava(14, 25, 16, 27, 4)                         # nascente que despenca na fenda
    p.rect(3, 13, 14, 18, "piso", 5)
    p.stairs(6, 19, 3, 4)
    p.lava(10, 16, 12, 18, 5)                         # nascente alta
    p.rect(5, 4, 16, 10, "piso", 6)                   # pico oeste (sem saída)
    p.stairs(9, 11, 3, 5)
    # Miolo — a mesa central liga os dois lados no nível 3
    p.ponte(25, 33, 31, 34, 3)
    p.rect(32, 30, 46, 36, "piso", 3)
    p.lava(34, 32, 36, 33, 3)
    # Leste — prateleira, cratera, crista e a boca
    p.rect(40, 38, 52, 43, "piso", 2)
    p.stairs(44, 44, 3, 1)
    p.stairs(42, 36, 3, 2)
    p.rect(30, 20, 58, 27, "piso", 4)                 # anel da cratera
    p.lava(40, 21, 54, 24, 4)                         # lago de lava
    p.lava(47, 25, 49, 27, 4)                         # sangradouro do lago
    p.stairs(36, 28, 3, 3)
    p.rect(22, 22, 29, 26, "piso", 4)                 # varanda da queda
    p.ponte(19, 23, 21, 24, 4)                        # ponte alta entre o maciço e a cratera
    p.rect(46, 12, 60, 17, "piso", 5)
    p.stairs(54, 18, 3, 4)
    p.rect(40, 5, 56, 9, "piso", 6)
    p.stairs(48, 10, 3, 5)
    p.lava(52, 7, 54, 9, 6)                           # nascente da crista
    p.rect(38, 0, 52, 2, "piso", 7)                   # boca do vulcão
    p.stairs(44, 3, 3, 6)
    p.lava(48, 0, 51, 1, 7)
    p.lavafall(47, 27, 3)                             # o lago sangra para o mar
    p.lavafall(14, 27, 3)                             # nascente do maciço
    p.lavafall(10, 18, 3)                             # nascente alta, na fenda
    p.lavafall(52, 9, 3)                              # crista leste
    p.event("entrada", "Chegada à caldeira", 14, 52, {})
    # Histórias e pausa
    p.morador("Celina", "celina", 17, 50, "Eu estudo o vulcão faz anos. A lava daqui não esfria: alguma coisa lá embaixo mantém ela acesa. O maciço a oeste é o caminho mais alto; a cratera fica do outro lado.")
    p.placa("Marco de pedra", 31, 50, "Uma pipa riscada no basalto, com a rabiola apontando para o alto. Alguém já soltou pipa no meio da lava.")
    p.placa("Garrafa no rochedo", 57, 51, "Uma garrafa presa entre as pedras, com um bilhete: \"Se você chegou até aqui, olhe para cima. O caminho de verdade é pelo alto.\"")
    p.placa("Gruta do eco", 5, 32, "A parede devolve qualquer som três vezes. Alguém riscou nomes de pipas na pedra, um embaixo do outro.")
    p.placa("Borda da cratera", 44, 26, "O lago de lava borbulha devagar. O ar quente sobe em coluna: o vento perfeito para uma pipa, se ela não fosse de papel.")
    p.placa("Varanda da queda", 24, 24, "Daqui se vê a lava do maciço despencar na fenda. O chão treme de leve, no ritmo da queda.")
    p.placa("Pico oeste", 7, 6, "O ponto mais alto do maciço. Do outro lado da caldeira, a boca do vulcão solta uma coluna de calor.")
    p.placa("Boca do vulcão", 41, 1, "Daqui dá para ver Kronasta inteira: a Serra, o Porto, o Morro do Sol. No fundo da boca, a lava pulsa como um coração.")
    p.event("interacao", "Abrigo da crista", 58, 14, {"acao": "wildRest"})
    # Missões e guardião (godot/scripts/campaign/side_regions.gd, região "vulcao")
    p.quest_npc("Mestre Brasa", "tiao", *p.spot(11, 50), "vulcaoBrasa")
    p.quest_npc("Dona Cinza", "mae", *p.spot(20, 49), "vulcaoCinza")
    u, v = p.spot(21, 51)
    p.event("npc", "Caco", u, v, {"district": "morro", "npcIdentity": "zeca", "bloqueia": False, "requer": "vulcaoCacoAchado",
                                  "texto": "Caco: Do alto dá para ver a lava pulsando, como se o vulcão respirasse. Ainda vou medir isso direito."})
    p.quest_npc("Caco", "zeca", *p.spot(45, 7), "vulcaoCaco", requer="vulcaoCacoPedido", ocultar_apos="vulcaoCacoAchado")
    for u, v in [(45, 50), (40, 34), (10, 7)]:
        p.quest_item(*p.spot(u, v), "pedra-de-brasa", "Pedra de brasa", "vulcaoBrasaPedido")
    p.event("npc", "Tricórdio", *p.spot(43, 1), {"acao": "vulcaoBoss", "storySpritePath": "res://assets/campaign/regioes-v1/tricordio.png",
                                                  "ocultar_apos": "vulcaoTricordioVencido", "bloqueia": True})
    p.bench(58, 13, "concreto")
    p.rochas([(9, 48), (21, 53), (29, 52), (41, 47), (49, 52), (59, 50), (6, 40), (19, 43),
              (41, 39), (51, 42), (10, 31), (23, 35), (33, 31), (45, 35), (5, 22), (17, 22),
              (31, 21), (57, 26), (28, 22), (4, 14), (13, 14), (47, 13), (59, 16), (6, 5), (15, 9),
              (41, 6), (55, 6), (39, 1)])
    p.kites([(12, 42), (38, 34), (33, 25), (8, 8)])
    # Achados nos pontos sem saída e nos cantos fora do caminho
    p.tesouro(59, 53, "linha-encerada")               # rochedo isolado
    p.tesouro(4, 34, "cola-reparo")                   # gruta do eco
    p.tesouro(14, 5, "papel-seda")                    # pico oeste
    p.tesouro(23, 25, "papel-seda")                   # varanda da queda
    p.tesouro(57, 21, "linha-encerada")               # canto leste do anel
    p.tesouro(51, 2, "cola-reparo")                   # boca
    p.tesouro(6, 43, "papel-seda", escondido=False)
    for name, u, v in [("chegada", 16, 50), ("fenda", 13, 24), ("mesa", 36, 33), ("cratera", 46, 24), ("pico-oeste", 10, 8), ("boca", 46, 4)]:
        p.shot(name, u, v)
    return p


if __name__ == "__main__":
    plan = caldeira()
    plan.write()
    print("escrito", plan.scene, len(plan.pieces), "peças", len(plan.events), "eventos")
