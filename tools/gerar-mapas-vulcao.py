#!/usr/bin/env python3
"""Vulcão de Kronasta · Caldeira (região de lava, exploração).

Um mapa de 64×56 com sete andares. A base inteira é lava (células "agua" com o material de
lava do renderizador, forest.lava). O jogador sobe por ilhas e prateleiras de basalto:
passarelas sobre a lava, dois caminhos (oeste e leste) que se reencontram, um lago de lava
elevado dentro da cratera e a boca do vulcão no alto.

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

    def lava(self, u0, v0, u1, v1, level):
        """Poça ou lago de lava no nível do terraço."""
        self.rect(u0, v0, u1, v1, "agua", level)

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
    p = Vulcao("vulcao-a", "Vulcão de Kronasta · Caldeira")
    # Nível 1 — três ilhas na lava e a ilha do meio
    p.rect(26, 48, 38, 54, "piso", 1)                 # ilha de chegada
    p.rect(6, 46, 18, 52, "piso", 1)                  # ilha oeste
    p.rect(46, 46, 58, 52, "piso", 1)                 # ilha leste
    p.ponte(19, 49, 25, 50, 1)
    p.ponte(39, 49, 45, 50, 1)
    p.rect(27, 39, 37, 43, "piso", 1)                 # ilha do meio (sem saída)
    p.ponte(31, 44, 33, 47, 1)
    # Nível 2 — prateleiras oeste e leste
    p.rect(4, 38, 22, 43, "piso", 2)
    p.rect(42, 38, 60, 43, "piso", 2)
    p.stairs(10, 44, 3, 1)
    p.stairs(50, 44, 3, 1)
    # Nível 3 — o terraço das poças, onde os dois caminhos se encontram
    p.rect(8, 30, 56, 35, "piso", 3)
    p.stairs(16, 36, 3, 2)
    p.stairs(46, 36, 3, 2)
    p.lava(20, 31, 25, 33, 3)
    p.lava(39, 32, 44, 34, 3)
    # Nível 4 — a cratera: um anel em volta do lago de lava
    p.rect(10, 20, 54, 27, "piso", 4)
    p.lava(22, 21, 42, 25, 4)
    p.stairs(30, 28, 5, 3)
    # Nível 5 — as duas cristas e a ponte alta
    p.rect(8, 12, 24, 17, "piso", 5)
    p.rect(40, 12, 56, 17, "piso", 5)
    p.stairs(12, 18, 3, 4)
    p.stairs(50, 18, 3, 4)
    p.ponte(25, 14, 39, 15, 5)
    p.rect(29, 12, 35, 13, "piso", 5)
    # Nível 6 — a boca do vulcão
    p.rect(22, 2, 42, 9, "piso", 6)
    p.lava(29, 4, 35, 6, 6)
    p.stairs(31, 10, 3, 5)
    p.event("entrada", "Chegada à caldeira", CX, 52, {})
    # Histórias e pausa
    p.morador("Celina", "celina", 34, 51, "Eu estudo o vulcão faz anos. A lava daqui não esfria: alguma coisa lá embaixo mantém ela acesa. Suba com calma, o basalto aguenta.")
    p.placa("Marco de pedra", 30, 41, "Uma pipa riscada no basalto, com a rabiola apontando para o alto. Alguém já soltou pipa no meio da lava.")
    p.placa("Borda da cratera", 32, 27, "O lago de lava borbulha devagar. O ar quente sobe em coluna: o vento perfeito para uma pipa, se ela não fosse de papel.")
    p.placa("Boca do vulcão", 32, 8, "Daqui dá para ver Kronasta inteira: a Serra, o Porto, o Morro do Sol. No fundo da boca, a lava pulsa como um coração.")
    p.placa("Acampamento abandonado", 54, 14, "Restos de uma expedição: uma lona queimada e um caderno com desenhos de pipas feitas de pedra-pomes.")
    p.event("interacao", "Abrigo da crista", 10, 14, {"acao": "wildRest"})
    p.bench(10, 13, "concreto")
    # Rochas: bordas, marcos e gargalos (nunca nos pés das escadas)
    p.rochas([(7, 47), (17, 51), (47, 47), (57, 51), (27, 53), (37, 49), (28, 40), (36, 42),
              (5, 39), (21, 42), (43, 39), (59, 42), (9, 31), (55, 34), (28, 31), (36, 34),
              (11, 21), (53, 26), (20, 26), (44, 21), (9, 13), (23, 16), (41, 13), (55, 16),
              (23, 3), (41, 8), (27, 8), (37, 3)])
    p.kites([(15, 47), (52, 40), (18, 22), (38, 7)])
    # Achados: ilha do meio, pontas das prateleiras, anel da cratera, crista leste e a boca
    p.tesouro(36, 40, "linha-encerada")
    p.tesouro(5, 42, "papel-seda")
    p.tesouro(59, 39, "cola-reparo")
    p.tesouro(53, 21, "papel-seda")
    p.tesouro(55, 13, "linha-encerada")
    p.tesouro(40, 3, "cola-reparo")
    p.tesouro(12, 34, "papel-seda", escondido=False)
    for name, u, v in [("chegada", 32, 50), ("ilha-do-meio", 32, 42), ("pocas", 32, 33), ("cratera", 32, 24), ("ponte-alta", 32, 15), ("boca", 32, 6)]:
        p.shot(name, u, v)
    return p


if __name__ == "__main__":
    plan = caldeira()
    plan.write()
    print("escrito", plan.scene, len(plan.pieces), "peças", len(plan.events), "eventos")
