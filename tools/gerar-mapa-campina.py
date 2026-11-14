#!/usr/bin/env python3
"""Vila Campina (planicie-d): mapa grande, 112×96, com uma cidade no meio da planície.

Quarta área das Planícies de Kronasta. Chega pelo norte (Vale das Pedras) ou pelo oeste
(viagem por Kronasta). Em volta da cidade: campos de capim alto (criaturas selvagens), hortas,
o rio que desce do norte e passa pela ponte da estrada oeste, a colina do moinho grande no
noroeste e o lago da cachoeira no sudeste. A cidade tem praça com chafariz, mercado, ruas de
calçamento, casas em quarteirões e o Alto da Vila, um terraço com a casa do prefeito.

    python3 tools/gerar-mapa-campina.py && node tools/compilar-mapas.mjs planicie-d

Escadas sobem para v− (o fundo da tela).
"""
import importlib.util
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, os.path.join(HERE, path))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


morro = load("morro", "gerar-mapas-morro.py")
# Tamanho próprio: os módulos leem W e H na hora de cada chamada.
W, H = 112, 96
morro.W, morro.H = W, H
morro.cidade.W, morro.cidade.H = W, H
sys.argv = [sys.argv[0], "nenhuma"]          # carregar o módulo das planícies sem gerar nada
pl = load("planicie", "gerar-mapas-planicie.py")
sys.argv = sys.argv[:1]
pl.W, pl.H = W, H
pl.morro.W, pl.morro.H = W, H
pl.cidade.W, pl.cidade.H = W, H
pl.cidade.W = pl.morro.cidade.W = W
pl.morro.cidade.H = H

# Quarteirões: (u0, v0, u1, v1) entre as ruas; casas 4×4 com recuo de uma célula.
STREET = "terra"
SIDEWALK = "piso"


def campina():
    p = pl.planicie("d", "Vila Campina", 25600)
    p.forest["market"] = True                                    # casas e calçamento da cidade (como no Morro)
    # ---- planície ----
    p.blob(56, 48, 59, 51, "grama", 0, salt=71, rough=.06)
    # moldura de mata: 3 a 5 células nas bordas (as estradas abrem passagem depois)
    for v in range(H):
        for u in range(W):
            edge = min(u, v, W - 1 - u, H - 1 - v)
            if edge < 3 + int(pl.noise(u, v, 81) * 3):
                p.mat[v][u] = "bosque"
    for cu, cv, rx, ry, salt in [(18, 62, 12, 9, 72), (96, 54, 9, 12, 73), (40, 84, 13, 6, 74), (84, 14, 10, 6, 75), (24, 34, 8, 6, 76)]:
        p.blob(cu, cv, rx, ry, "mato", 0, salt=salt)             # capim alto: encontros
    # hortas (canteiros) com caminhos de terra no meio
    for u0, v0, u1, v1 in [(8, 74, 20, 80), (8, 83, 20, 88), (96, 30, 106, 36), (70, 82, 82, 88)]:
        p.rect(u0, v0, u1, v1, "canteiro", 0)
    p.rect(8, 81, 20, 82, "terra", 0)
    # ---- estradas ----
    p.path([(65, 0), (65, 30)], 3, "terra", 0)                    # norte: Vale das Pedras
    p.path([(0, 52), (46, 52)], 3, "terra", 0)                    # oeste: Kronasta
    p.path([(68, 74), (72, 82), (76, 90)], 3, "terra", 0)         # sul: hortas e lago
    p.path([(89, 52), (100, 52), (100, 62), (92, 70)], 3, "terra", 0)  # leste: lago da cachoeira
    p.path([(20, 52), (16, 40), (14, 24)], 3, "terra", 0)         # noroeste: moinho grande
    p.path([(14, 52), (14, 72), (14, 82)], 3, "terra", 0)         # sudoeste: hortas
    p.arrival(65, 3, "Chegada pelo norte")
    p.arrival(3, 52, "Chegada pela estrada oeste")
    p.edge_exit(65, 0, "planicie-c", (44, 52), "Subir para o Vale das Pedras")
    p.edge_exit(0, 52, "kronasta", name="Voltar a Kronasta")
    # ---- rio (rebaixado) com a ponte da estrada oeste ----
    p.path([(48, 0), (46, 10), (36, 22), (28, 34), (27, 44), (27, 60), (30, 70), (22, 82), (18, 95)], 4, "agua", -1)
    p.ponte(24, 51, 30, 53, 0)
    # ---- colina do moinho grande (noroeste) ----
    p.blob(13, 16, 10, 7, "grama", 1, salt=77)
    p.rect(12, 19, 16, 22, "grama", 1)                         # patamar da escada
    p.stairs(13, 23, 3, 0)
    p.blob(11, 10, 6, 3.5, "grama", 2, salt=78)
    p.stairs(10, 13, 3, 1)
    p.piece("biruta", 13, 9, 1, 1, True, "default", "Moinho grande")
    # ---- paredão da cachoeira e o lago (sudeste) ----
    p.blob(104, 72, 6, 6, "rocha", 2, salt=79, rough=.1)
    p.rect(99, 66, 101, 74, "agua", 1)                          # o córrego corre por cima do paredão
    p.rect(97, 75, 101, 77, "agua", -1)
    p.fall(99, 74, 3)
    p.pool(91, 79, 8, 4, 0, salt=8)
    # ---- cidade ----
    p.rect(46, 32, 89, 74, "grama", 0)
    # ruas: anel, avenida norte-sul, rua leste-oeste e transversais
    for u0, v0, u1, v1 in [(46, 32, 89, 34), (46, 72, 89, 74), (46, 32, 48, 74), (87, 32, 89, 74),
                           (64, 32, 66, 74), (46, 51, 89, 53), (46, 42, 89, 43), (46, 62, 89, 63),
                           (55, 32, 56, 74), (76, 32, 77, 74)]:
        p.rect(u0, v0, u1, v1, STREET, 0)
    # praça central (calçada) com chafariz rebaixado e o mercado
    p.rect(58, 45, 72, 59, SIDEWALK, 0)
    p.piece("centro-fonte", 64, 51, 2, 2, True, "default", "Chafariz da Vila")
    for u, v in [(62, 52), (67, 52)]:
        p.piece("centro-jardineira", u, v, 1, 1, True, "default", "Jardineira")
    p.rect(64, 45, 66, 49, SIDEWALK, 0)
    for u, v, variant in [(60, 47, "teal"), (60, 56, "coral"), (68, 47, "amarela"), (68, 56, "teal")]:
        p.kiosk(u, v, variant, "Banca do mercado")
    for u, v in [(61, 49), (68, 49), (61, 55), (68, 55)]:
        p.bench(u, v, "madeira")
    for u, v in [(58, 45), (71, 45), (58, 58), (71, 58)]:
        p.tree(u, v)
    # casas nos quarteirões (fora da praça)
    blocks = [(49, 35, 54, 41), (57, 35, 63, 41), (67, 35, 75, 41), (78, 35, 86, 41),
              (49, 44, 54, 50), (78, 44, 86, 50), (49, 54, 54, 61), (78, 54, 86, 61),
              (49, 64, 54, 71), (57, 64, 63, 71), (67, 64, 75, 71), (78, 64, 86, 71)]
    n = 0
    for u0, v0, u1, v1 in blocks:
        u = u0
        while u + 3 <= u1:
            if all(p.mat[v][x] == "grama" for v in range(v0, v0 + 4) for x in range(u, u + 4)):
                p.casa(u, v0, "Casa da Vila")
                n += 1
            u += 5
    for u, v in [(57, 44), (73, 44), (57, 60), (73, 60), (60, 33), (70, 33), (60, 72), (70, 72)]:
        p.post(u, v)
    # sítios espalhados pelo campo, perto das hortas e das estradas
    for u, v in [(100, 38), (5, 72), (36, 66), (40, 22), (91, 62), (74, 76), (100, 44)]:
        p.casa(u, v, "Sítio")
        n += 1
    # ---- Alto da Vila: terraço com a casa do prefeito e o mirante ----
    p.rect(68, 22, 90, 31, "grama", 1)
    p.rect(68, 22, 90, 23, SIDEWALK, 1)
    p.stairs(78, 32, 3, 0)
    p.casa(72, 25, "Casa do prefeito")
    p.casa(82, 25, "Casa do relógio")
    p.bench(78, 23, "concreto")
    # ---- gente e placas ----
    p.morador("Dona Lurdes", "mae", 63, 56, "Bem-vinda à Vila Campina! O mercado abre todo dia. As pipas daqui são feitas com o papel do moinho grande, lá no noroeste.")
    p.morador("Zeca", "zeca", 58, 52, "Se for para o capim alto, cuidado: os Papiscos andam em bando e os Javalis correm sem olhar.")
    p.morador("Cauê", "caue", 80, 52, "Pela estrada leste se chega ao lago da cachoeira. A água desce da colina e é a mais fria da planície.")
    p.morador("Lia", "lia", 66, 38, "A avenida norte vai dar no Vale das Pedras. Meu avô dizia que a vila nasceu em volta do chafariz.")
    p.morador("Seu Tião", "tiao", 14, 76, "Estas hortas alimentam a vila inteira. Quando venta forte, as pipas ajudam a espantar os passarinhos.")
    p.morador("Nilo", "nilo", 34, 52, "A ponte do rio é a única passagem da estrada oeste. Do outro lado começa o caminho para Kronasta.")
    p.placa("Chafariz da Vila", 65, 49, "A vila nasceu em volta deste chafariz. A água vem do rio por um cano antigo, enterrado sob a avenida.")
    p.placa("Moinho grande", 12, 8, "O maior moinho das planícies. As pás são de pipa de papel encerado e giram com qualquer brisa.")
    p.placa("Lago da Cachoeira", 84, 73, "A água cai da colina e o lago nunca seca. Nas tardes de vento, as pipas se refletem na água.")
    p.placa("Alto da Vila", 86, 23, "Daqui se vê a vila inteira, as hortas e, longe, a serra das Colinas do Moinho.")
    p.event("interacao", "Banco da praça", 61, 50, {"acao": "wildRest"})
    p.event("interacao", "Sombra do moinho", 16, 20, {"acao": "wildRest"})
    p.event("interacao", "Beira do lago", 88, 72, {"acao": "wildRest"})
    pl.decorate_field(p,
                      trees=[(6, 44), (36, 40), (38, 62), (34, 74), (94, 42), (102, 70), (60, 86), (84, 6), (100, 22), (40, 12), (4, 30), (30, 90)],
                      groves=[(4, 8), (24, 6), (106, 10), (108, 44), (106, 92), (50, 92), (4, 92), (2, 70)],
                      rocks=[(30, 44), (40, 30), (94, 66), (52, 82), (20, 28), (104, 26)],
                      flowers=[(44, 50), (60, 30), (90, 40), (36, 56), (12, 50), (70, 78), (96, 60), (22, 70), (46, 20), (80, 92)],
                      kites=[(30, 20), (98, 58), (60, 80), (12, 12)])
    p.tesouros([(10, 9, "linha-encerada", True), (94, 33, "papel-seda", True), (18, 81, "cola-reparo", True),
                (80, 78, "moedas", False), (88, 29, "linha-encerada", True), (40, 90, "papel-seda", True)])
    for name, u, v in [("praca", 65, 54), ("mercado", 62, 48), ("alto", 80, 26), ("ponte", 27, 52), ("moinho", 13, 14),
                       ("lago", 90, 76), ("hortas", 14, 80), ("chegada", 65, 8)]:
        p.shot(name, u, v)
    p.frame_trees()
    print("casas:", n + 2)
    return p


if __name__ == "__main__":
    plan = campina()
    plan.write()
    print("escrito", plan.scene, len(plan.pieces), "peças", len(plan.events), "eventos")
