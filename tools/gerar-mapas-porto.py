#!/usr/bin/env python3
"""Plantas próprias do Porto Novo (bairro 11, ato 6, Nv.36–40), partes A–C.

Até 08/11 as três partes eram o Cais Velho (mesmo .tmj) com fachadas cinza. Este gerador
escreve um .tmj por parte em art/overworld/mapas/ usando o que o harbor_structures.gd já sabe
desenhar: cais de concreto acima do mar (água rebaixada, muro até a cota da água), galpões do
distrito, galpão do terminal, docas, navios, bancas, mastros e cargas (bobina, cabeço, rede,
contêiner, pórtico, tambores, poste). Eventos (rivais, campeão, saídas) vêm da versão anterior,
com posição nova quando a planta pede.

    python3 tools/gerar-mapas-porto.py && node tools/compilar-mapas.mjs kronasta-porto-a kronasta-porto-b kronasta-porto-c
"""
import importlib.util
import json
import os
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("cidade", os.path.join(HERE, "gerar-mapas-cidade.py"))
cidade = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cidade)
Plan, W, H, ROOT = cidade.Plan, cidade.W, cidade.H, cidade.ROOT
BASE_REVISION = "5e4838fd"  # última versão com o Porto copiado do Cais


class Porto(Plan):
    def __init__(self, scene, name, title):
        super().__init__(scene, name, "porto", scene[-1].upper(), title)
        self.mat = [["agua"] * W for _ in range(H)]
        self.forest = {"harbor": True, "nativeProps": True, "buildings": [], "docks": [], "props": [], "ships": [], "shots": []}

    def keep_events(self, moves=None, rename=None):
        source = subprocess.run(["git", "show", f"{BASE_REVISION}:godot/assets/overworld/maps/{self.scene}.json"],
                                cwd=ROOT, capture_output=True, text=True, check=True).stdout
        for e in json.loads(source)["events"]:
            u, v = (moves or {}).get(e["id"], (e["u"], e["v"]))
            props = []
            for k, val in e["props"].items():
                kind = "bool" if isinstance(val, bool) else "int" if isinstance(val, int) else "float" if isinstance(val, float) else "string"
                props.append({"name": k, "type": kind, "value": val})
            name = (rename or {}).get(e["id"], e["name"])
            self.events.append({"id": e["id"], "name": name, "type": e["type"], "x": u * 32 + 16, "y": v * 32 + 16,
                                "point": True, "properties": props})

    def building(self, u, v, w, h, name, height=160):
        self.forest["buildings"].append({"u": u, "v": v, "w": w, "h": h, "height": height, "name": name})
        self.piece("cais-volume", u, v, w, h, True, None, name)

    def dock(self, u, v, w, h, level=1):
        self.rect(u, v, u + w - 1, v + h - 1, "piso", level)
        self.forest["docks"].append({"u": u, "v": v, "w": w, "h": h})

    def ship(self, u, v):
        assert self.mat[v][u] == "agua", f"navio fora da água em {u},{v}"
        self.forest["ships"].append({"u": u, "v": v})

    def prop(self, asset, u, v, w, h, width, name):
        self.forest["props"].append({"asset": asset, "u": u, "v": v, "w": w, "h": h, "width": width})
        self.piece("cais-" + asset, u, v, w, h, True, None, name)

    def cargo(self, kind, u, v, name, fu=1, fv=1):
        self.piece("porto-" + kind, u, v, fu, fv, True, None, name)

    def shot(self, name, u, v):
        self.forest["shots"].append({"name": name, "u": u, "v": v, "zoom": 1, "kind": "jogo"})

    def write(self):
        # Mureta nas bordas voltadas para a câmera (+u, +v) onde o chão cai; nada sobre escadas.
        stair_cells = {(s["u"] + du, s["v"] + dv) for s in self.stairs_info for du in range(s["width"]) for dv in range(-1, 3)}
        guards = []
        for v in range(H):
            for u in range(W):
                if self.mat[v][u] == "agua" or (u, v) in stair_cells:
                    continue
                for side, (nu, nv) in (("u", (u + 1, v)), ("v", (u, v + 1))):
                    if nu >= W or nv >= H or (nu, nv) in stair_cells:
                        continue
                    lower = self.mat[nv][nu] == "agua" or self.lvl[nv][nu] < self.lvl[v][u]
                    if lower and not self.ramp[v][u] and not self.ramp[nv][nu]:
                        guards.append({"u": u, "v": v, "side": side})
        super().write()
        path = os.path.join(cidade.MAPS, self.scene + ".tmj")
        tmj = json.load(open(path))
        for prop in tmj["properties"]:
            if prop["name"] == "forest":
                forest = json.loads(prop["value"])
                forest.update(self.forest)
                forest.pop("market", None)
                forest["guards"] = guards
                prop["value"] = json.dumps(forest, ensure_ascii=False, separators=(",", ":"))
        json.dump(tmj, open(path, "w"), ensure_ascii=False, indent=1)


def porto_a():
    p = Porto("kronasta-porto-a", "Porto Novo", "Terminal de chegada")
    p.rect(21, 30, 29, 39, "piso", 1)                # passarela de chegada
    p.rect(6, 19, 40, 31, "piso", 1)                 # praça do terminal
    p.rect(12, 4, 38, 17, "piso", 2)                 # deque de embarque (elevado)
    p.rect(23, 0, 27, 3, "piso", 2)                  # saída para as docas
    p.rect(14, 23, 19, 27, "agua")                   # espelho d'água da praça (rebaixado)
    p.stairs(22, 18, 5, 1)                           # escadaria central ao deque
    p.stairs(34, 18, 3, 1)                           # escada lateral leste
    p.dock(41, 22, 5, 3)                             # píer das balsas
    p.dock(39, 9, 6, 3, 2)                           # píer do deque
    p.keep_events(moves={20201: (24, 27), 20202: (18, 12)}, rename={11: "Chegada ao Porto"})
    p.building(32, 6, 5, 5, "Galpão do terminal")    # arte própria do terminal (harbor_structures)
    p.building(14, 5, 5, 4, "Bilheteria")
    p.building(7, 26, 5, 5, "Agência marítima")
    p.prop("mastro", 28, 5, 2, 2, 140, "Mastro de sinais")
    p.prop("banca", 30, 26, 3, 2, 170, "Banca do terminal")
    p.prop("materiais", 9, 20, 2, 2, 130, "Bagagens")
    for u, v in [(21, 31), (29, 31), (12, 19), (39, 21), (13, 16), (37, 16), (20, 4), (31, 4)]:
        p.cargo("poste", u, v, "Iluminação do terminal")
    for u, v in [(40, 20), (40, 26), (38, 11)]:
        p.cargo("cabeco", u, v, "Amarração")
    p.cargo("bobina", 26, 12, "Bobina de cabo")
    p.cargo("rede", 39, 30, "Rede de pesca")
    p.cargo("tambores", 12, 30, "Tambores")
    p.bench(16, 21, "concreto")
    p.bench(26, 22, "concreto")
    p.ship(44, 19)
    p.ship(44, 27)
    p.ship(3, 22)
    p.item(110, 7, 20, "linha-encerada", "escondido")
    p.item(111, 37, 13, "papel-seda")
    for name, u, v in [("praca", 24, 28), ("deque", 24, 10), ("pier", 42, 23), ("chegada", 25, 35)]:
        p.shot(name, u, v)
    return p


def porto_b():
    p = Porto("kronasta-porto-b", "Porto Novo", "Docas de carga")
    p.rect(19, 30, 31, 39, "piso", 1)                # passarela de chegada
    p.rect(4, 8, 42, 31, "piso", 1)                  # pátio de contêineres
    p.rect(30, 2, 41, 7, "piso", 1)                  # frente do galpão de triagem
    p.rect(22, 0, 28, 7, "piso", 1)                  # rampa norte para o cais do capitão
    p.rect(17, 17, 27, 22, "agua")                   # dique seco (rebaixado)
    p.rect(4, 3, 14, 7, "piso", 2)                   # escritório da doca (elevado)
    p.stairs(8, 8, 4, 1)                             # escada do escritório
    p.dock(43, 12, 4, 3)                             # píer de atracação
    p.dock(43, 24, 4, 3)
    p.keep_events(moves={20203: (31, 33), 20204: (12, 12)}, rename={12: "Chegada às docas"})
    p.building(5, 3, 5, 4, "Escritório da doca")
    p.building(33, 3, 6, 5, "Galpão de triagem")
    p.prop("mastro", 41, 9, 2, 2, 140, "Sinal da doca")
    # Fileiras de contêineres com corredores; o centro fica livre em volta do dique.
    for v in (12, 15, 26, 29):
        for u in (30, 33, 36):
            p.cargo("conteiner", u, v, "Contêiner", 2, 1)
    for v in (26, 29):
        for u in (6, 9, 13):
            p.cargo("conteiner", u, v, "Contêiner", 2, 1)
    for u, v in [(40, 12), (40, 18), (40, 24)]:
        p.cargo("portico", u, v, "Pórtico de içamento", 2, 1)
    for u, v in [(14, 24), (29, 15), (30, 23), (12, 18)]:
        p.cargo("tambores", u, v, "Tambores")
    for u, v in [(16, 16), (28, 16), (16, 23), (28, 23)]:
        p.cargo("cabeco", u, v, "Cabeço do dique")
    for u, v in [(21, 31), (29, 31), (23, 8), (27, 8), (5, 21), (42, 30)]:
        p.cargo("poste", u, v, "Iluminação do pátio")
    p.cargo("bobina", 18, 12, "Bobina de cabo")
    p.cargo("bobina", 34, 20, "Bobina de cabo")
    p.ship(22, 19)                                   # navio no dique
    p.ship(45, 18)
    p.ship(45, 30)
    p.item(112, 37, 31, "cola-reparo", "escondido")
    p.item(113, 12, 4, "papel-seda")
    for name, u, v in [("dique", 22, 24), ("conteineres", 33, 12), ("escritorio", 9, 5), ("chegada", 25, 35)]:
        p.shot(name, u, v)
    return p


def porto_c():
    p = Porto("kronasta-porto-c", "Porto Novo", "Cais do Capitão")
    p.rect(14, 30, 36, 39, "piso", 1)                # cais de chegada
    p.rect(22, 13, 27, 29, "piso", 1)                # quebra-mar até o capitão
    p.rect(14, 2, 34, 11, "piso", 2)                 # plataforma do Capitão Jurandir
    p.rect(6, 26, 13, 33, "piso", 1)                 # mercado de peixe (oeste)
    p.rect(37, 25, 43, 33, "piso", 1)                # farol (leste)
    p.stairs(23, 12, 4, 1)                           # subida à plataforma
    p.dock(16, 16, 6, 2)                             # ancoradouros no quebra-mar
    p.dock(28, 20, 6, 2)
    p.keep_events(moves={20205: (24, 6), 6: (34, 36)}, rename={10: "Chegada ao cais"})
    p.building(7, 27, 5, 4, "Peixaria")
    p.building(15, 3, 4, 4, "Casa do capitão")
    p.prop("mastro", 39, 26, 2, 2, 140, "Farol de bandeiras")
    p.prop("banca", 9, 31, 3, 2, 170, "Banca de peixe")
    p.forest["landmark"] = {"kind": "arena", "u": 25.5, "v": 6.5}
    for u, v in [(22, 14), (27, 14), (22, 22), (27, 22), (14, 11), (34, 11), (14, 2), (34, 2), (15, 31), (35, 31)]:
        p.cargo("poste", u, v, "Lampião do quebra-mar")
    for u, v in [(20, 16), (33, 20), (31, 3), (31, 10)]:
        p.cargo("cabeco", u, v, "Amarração")
    p.cargo("rede", 12, 28, "Rede de reparo")
    p.cargo("bobina", 41, 31, "Bobina de sinais")
    p.cargo("tambores", 30, 33, "Tambores")
    p.bench(17, 34, "madeira")
    p.bench(31, 34, "madeira")
    p.ship(17, 14)
    p.ship(32, 18)
    p.ship(38, 6)
    p.ship(9, 6)
    p.item(114, 42, 32, "linha-encerada", "escondido")
    p.item(115, 7, 32, "cola-reparo")
    for name, u, v in [("plataforma", 24, 8), ("quebra-mar", 24, 20), ("farol", 40, 29), ("chegada", 25, 35)]:
        p.shot(name, u, v)
    return p


if __name__ == "__main__":
    for build in (porto_a, porto_b, porto_c):
        plan = build()
        plan.write()
        print("escrito", plan.scene, len(plan.pieces), "peças", len(plan.events), "eventos", len(plan.forest["ships"]), "navios")
