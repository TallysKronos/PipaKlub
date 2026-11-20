"""Trailer v3 · montagem em linguagem de mangá/comics (140 s, 1920×1080, 30 fps).

Lê os planos gravados no jogo por godot/tools/trailer_capture.gd (pasta --planos), compõe
quadro a quadro com PIL (quadros, sarjeta de papel, retícula, linhas de velocidade,
onomatopeias) e codifica com ffmpeg junto da trilha do trailer v2 e do rugido.

    python3 tools/trailer/montar_trailer_v3.py --planos <pasta> --saida trailer-v3.mp4 [--de 0 --ate 140]

Planos esperados (nome.mp4): ver PLANOS em documentation/trailer/TRAILER-V3-ROTEIRO.md.
"""
import argparse
import json
import math
import os
import random
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
W, H, FPS = 1920, 1080, 30
DURACAO = 140.0
PAPEL = (244, 233, 210)
TINTA = (11, 16, 23)
SOL = (255, 194, 61)
RABIOLA = (255, 90, 54)
CEU = (46, 200, 227)
FONTES = os.path.join(RAIZ, "godot/assets/campaign/ui-modern/fonts")
ARTE = os.path.join(RAIZ, "art/trailer-v2")
CAMPANHA = os.path.join(RAIZ, "godot/assets/campaign")


def fonte(nome, tamanho):
    return ImageFont.truetype(os.path.join(FONTES, nome), tamanho)


BANGERS = {}
LILITA = {}


def bangers(t):
    if t not in BANGERS:
        BANGERS[t] = fonte("Bangers-Regular.ttf", t)
    return BANGERS[t]


def lilita(t):
    if t not in LILITA:
        LILITA[t] = fonte("LilitaOne-Regular.ttf", t)
    return LILITA[t]


def suave(a, b, x):
    if b == a:
        return 1.0 if x >= b else 0.0
    t = min(1.0, max(0.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def saida(t):
    return 1 - (1 - t) ** 3


# ---------------------------------------------------------------- planos gravados
class Plano:
    """Lê um plano gravado em sequência, a partir de um instante, quadro a quadro."""

    def __init__(self, pasta, nome, inicio=0.0):
        caminho = os.path.join(pasta, nome + ".mp4")
        if not os.path.exists(caminho):
            raise SystemExit("plano ausente: " + caminho)
        self.proc = subprocess.Popen(
            ["ffmpeg", "-loglevel", "error", "-ss", str(inicio), "-i", caminho, "-vf", f"scale={W}:{H}",
             "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)
        self.ultimo = Image.new("RGB", (W, H), TINTA)

    def quadro(self):
        dados = self.proc.stdout.read(W * H * 3) if self.proc else b""
        if len(dados) == W * H * 3:
            self.ultimo = Image.frombuffer("RGB", (W, H), dados)
        return self.ultimo

    def fechar(self):
        if self.proc:
            self.proc.stdout.close()
            self.proc.kill()
            self.proc = None


class Leitores:
    """Abre cada plano na primeira vez que a cena pede e fecha quando a cena acaba."""

    def __init__(self, pasta):
        self.pasta = pasta
        self.abertos = {}

    def get(self, chave, nome, inicio):
        if chave not in self.abertos:
            self.abertos[chave] = Plano(self.pasta, nome, inicio)
        return self.abertos[chave]

    def fechar_exceto(self, vivos):
        for chave in list(self.abertos):
            if chave not in vivos:
                self.abertos.pop(chave).fechar()


# ---------------------------------------------------------------- desenho
def cobrir(img, tamanho, foco=(.5, .5), zoom=1.0):
    """Recorta img para cobrir tamanho (w, h), centrado em foco, com zoom extra."""
    w, h = tamanho
    escala = max(w / img.width, h / img.height) * zoom
    nw, nh = int(img.width * escala + .5), int(img.height * escala + .5)
    redim = img.resize((nw, nh), Image.BILINEAR)
    x = int((nw - w) * foco[0])
    y = int((nh - h) * foco[1])
    x = min(max(0, x), nw - w)
    y = min(max(0, y), nh - h)
    return redim.crop((x, y, x + w, y + h))


def caixa(poly):
    xs = [p[0] for p in poly]
    ys = [p[1] for p in poly]
    return int(min(xs)), int(min(ys)), int(math.ceil(max(xs))), int(math.ceil(max(ys)))


def quadro(tela, poly, img, deslocar=(0, 0), foco=(.5, .5), zoom=1.0, borda=9):
    """Cola img dentro do polígono (quadro de mangá) com contorno de nanquim."""
    poly = [(x + deslocar[0], y + deslocar[1]) for x, y in poly]
    x0, y0, x1, y1 = caixa(poly)
    if x1 <= 0 or y1 <= 0 or x0 >= W or y0 >= H or x1 - x0 < 2 or y1 - y0 < 2:
        return
    conteudo = cobrir(img, (x1 - x0, y1 - y0), foco, zoom)
    mascara = Image.new("L", (x1 - x0, y1 - y0), 0)
    ImageDraw.Draw(mascara).polygon([(x - x0, y - y0) for x, y in poly], fill=255)
    tela.paste(conteudo, (x0, y0), mascara)
    ImageDraw.Draw(tela).line(poly + [poly[0]], fill=TINTA, width=borda, joint="curve")


def papel(tela, alpha=1.0):
    if alpha >= 1:
        tela.paste(PAPEL, (0, 0, W, H))


_RETICULA = {}


def reticula(tamanho, passo=14, cor=(0, 0, 0), opacidade=60):
    chave = (tamanho, passo, cor, opacidade)
    if chave not in _RETICULA:
        w, h = tamanho
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        for j, y in enumerate(range(0, h + passo, passo)):
            raio = 1.2 + 3.2 * (y / max(1, h))
            for x in range(-passo, w + passo, passo):
                cx = x + (passo / 2 if j % 2 else 0)
                d.ellipse((cx - raio, y - raio, cx + raio, y + raio), fill=cor + (opacidade,))
        _RETICULA[chave] = img
    return _RETICULA[chave]


_LINHAS = {}


def linhas_radiais(semente=1, opacidade=150, centro=(W / 2, H / 2)):
    chave = (semente, opacidade, centro)
    if chave not in _LINHAS:
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        r = random.Random(semente)
        for i in range(120):
            a = r.uniform(0, math.tau)
            ini = r.uniform(.42, .62) * W
            fim = W * 1.3
            larg = r.uniform(.004, .014)
            p = [(centro[0] + math.cos(a - larg) * fim, centro[1] + math.sin(a - larg) * fim),
                 (centro[0] + math.cos(a) * ini, centro[1] + math.sin(a) * ini),
                 (centro[0] + math.cos(a + larg) * fim, centro[1] + math.sin(a + larg) * fim)]
            d.polygon(p, fill=TINTA + (opacidade,))
        _LINHAS[chave] = img
    return _LINHAS[chave]


def letreiro(tela, texto, centro, tamanho, cor=PAPEL, contorno=TINTA, angulo=0.0, alpha=1.0, fonte_fn=bangers, espessura=None):
    """Letras de mangá: preenchimento, contorno grosso, rotação."""
    if alpha <= 0:
        return
    f = fonte_fn(tamanho)
    esp = espessura if espessura is not None else max(4, tamanho // 9)
    bbox = f.getbbox(texto, stroke_width=esp)
    w, h = bbox[2] - bbox[0] + 20, bbox[3] - bbox[1] + 20
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(img).text((10 - bbox[0], 10 - bbox[1]), texto, font=f, fill=cor + (255,), stroke_width=esp, stroke_fill=contorno + (255,))
    if angulo:
        img = img.rotate(angulo, resample=Image.BICUBIC, expand=True)
    if alpha < 1:
        img.putalpha(img.getchannel("A").point(lambda v: int(v * alpha)))
    tela.paste(img, (int(centro[0] - img.width / 2), int(centro[1] - img.height / 2)), img)


def legenda(tela, texto, alpha=1.0, y=None, tamanho=60):
    """Caixa de narração de mangá (retângulo de papel com borda)."""
    if alpha <= 0:
        return
    f = lilita(tamanho)
    bbox = f.getbbox(texto)
    w = bbox[2] - bbox[0] + 64
    h = bbox[3] - bbox[1] + 40
    x = 70
    y = H - h - 70 if y is None else y
    caixa_img = Image.new("RGBA", (w + 12, h + 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(caixa_img)
    d.rectangle((12, 12, w + 11, h + 11), fill=TINTA + (255,))
    d.rectangle((0, 0, w, h), fill=PAPEL + (255,), outline=TINTA + (255,), width=6)
    d.text((32 - bbox[0], 20 - bbox[1]), texto, font=f, fill=TINTA + (255,))
    if alpha < 1:
        caixa_img.putalpha(caixa_img.getchannel("A").point(lambda v: int(v * alpha)))
    deslize = int((1 - alpha) * -40)
    tela.paste(caixa_img, (x + deslize, y), caixa_img)


def onomatopeia(tela, arquivo, centro, largura, angulo=0.0, alpha=1.0, tremor=0.0, t=0.0):
    img = carregar_rgba(os.path.join(ARTE, "onomatopeias", arquivo))
    escala = largura / img.width
    img = img.resize((int(img.width * escala), int(img.height * escala)), Image.BICUBIC)
    if angulo:
        img = img.rotate(angulo, resample=Image.BICUBIC, expand=True)
    if alpha < 1:
        img.putalpha(img.getchannel("A").point(lambda v: int(v * alpha)))
    dx = math.sin(t * 61) * tremor
    dy = math.cos(t * 53) * tremor
    tela.paste(img, (int(centro[0] - img.width / 2 + dx), int(centro[1] - img.height / 2 + dy)), img)


_CACHE = {}


def carregar_rgba(caminho):
    if caminho not in _CACHE:
        _CACHE[caminho] = Image.open(caminho).convert("RGBA")
    return _CACHE[caminho]


def carregar_rgb(caminho):
    chave = caminho + "#rgb"
    if chave not in _CACHE:
        _CACHE[chave] = Image.open(caminho).convert("RGB")
    return _CACHE[chave]


def preto_e_branco(img):
    """Quadro de impacto: cinza com contraste duro e retícula."""
    g = ImageOps.autocontrast(img.convert("L"), cutoff=2)
    g = g.point(lambda v: 255 if v > 168 else (150 if v > 92 else 18))
    out = g.convert("RGB")
    out.paste(reticula((W, H), 12, (0, 0, 0), 70), (0, 0), reticula((W, H), 12, (0, 0, 0), 70))
    return out


def tremer(img, t, forca):
    if forca <= 0:
        return img
    dx = int(math.sin(t * 57) * forca)
    dy = int(math.cos(t * 43) * forca)
    out = Image.new("RGB", (W, H), TINTA)
    out.paste(img, (dx, dy))
    return out


def faixas(tela, altura=0.08):
    a = int(H * altura)
    tela.paste(TINTA, (0, 0, W, a))
    tela.paste(TINTA, (0, H - a, W, H))


# ---------------------------------------------------------------- mosaico de criaturas
_MOSAICO = {}


def criaturas():
    if "lista" not in _MOSAICO:
        dados = json.load(open(os.path.join(CAMPANHA, "overworld-animations-v1/manifest.json")))
        lista = []
        for especie in sorted(dados):
            caminho = os.path.join(CAMPANHA, "overworld-animations-v1", especie, "walk.png")
            if not os.path.exists(caminho):
                continue
            folha = carregar_rgba(caminho)
            n = int(dados[especie].get("frame_counts", {}).get("walk", folha.width // 112))
            quadros = [folha.crop((i * 112 + 14, 112 + 18, (i + 1) * 112 - 14, 224 - 4)) for i in range(n)]
            lista.append(quadros)
        _MOSAICO["lista"] = lista
    return _MOSAICO["lista"]


def mosaico(t, duracao):
    """Todas as folhas de overworld andando; a página se afasta até virar mosaico."""
    lista = criaturas()
    colunas = 20
    linhas = math.ceil(len(lista) / colunas)
    cw, ch = 84, 90
    pagina = Image.new("RGB", (colunas * cw, linhas * ch), PAPEL)
    for i, quadros in enumerate(lista):
        q = quadros[int((t * 10) + i) % len(quadros)]
        x = (i % colunas) * cw
        y = (i // colunas) * ch
        pagina.paste(q, (x, y), q)
    z = 3.2 + (1.0 - 3.2) * saida(suave(0.4, duracao - 2.6, t))
    largura = int(W / z * (pagina.width / W) * (W / pagina.width) * z)
    escala = (W / pagina.width) * 0.94 * z
    nw, nh = int(pagina.width * escala), int(pagina.height * escala)
    redim = pagina.resize((nw, nh), Image.NEAREST)
    tela = Image.new("RGB", (W, H), PAPEL)
    cx = nw * 0.30 + (nw * 0.5 - nw * 0.30) * suave(0.4, duracao - 2.6, t)
    cy = nh * 0.25 + (nh * 0.5 - nh * 0.25) * suave(0.4, duracao - 2.6, t)
    tela.paste(redim, (int(W / 2 - cx), int(H / 2 - cy)))
    return tela, len(lista)


# ---------------------------------------------------------------- cenas
def cena_ceu(t, d, L):
    tela = Image.new("RGB", (W, H), TINTA)
    abre = saida(suave(0.3, 1.6, t))
    altura = int(40 + (H * .78 - 40) * abre)
    ceu = carregar_rgb(os.path.join(ARTE, "kronasta-ceu-r4.png"))
    zoom = 1.04 + .06 * t / d
    y0 = (H - altura) // 2
    poly = [(60, y0), (W - 60, y0 - 18 * abre), (W - 60, y0 + altura), (60, y0 + altura + 18 * abre)]
    quadro(tela, poly, ceu, foco=(.35 + .3 * t / d, .5), zoom=zoom, borda=10)
    tela.paste(linhas_radiais(3, int(60 * abre)), (0, 0), linhas_radiais(3, int(60 * abre)))
    legenda(tela, "Kronasta. Doze bairros, um céu.", suave(3.2, 3.8, t) * (1 - suave(d - .5, d, t)))
    return tela


def faixa_motivo(tela, img, y, altura, entrada, t, inclina=0, borda=9):
    """Faixa horizontal com o Kael andando (motivo recorrente)."""
    desliza = (1 - saida(suave(entrada, entrada + .35, t))) * W * 1.1
    poly = [(40, y + inclina), (W - 40, y - inclina), (W - 40, y + altura - inclina), (40, y + altura + inclina)]
    quadro(tela, poly, img, deslocar=(desliza, 0), foco=(.5, .55), zoom=1.0, borda=borda)


def cena_primeiro(t, d, L):
    tela = Image.new("RGB", (W, H), PAPEL)
    img = L.get("m01", "m01", 1.0).quadro()
    faixa_motivo(tela, img, 170, 740, 0, t, inclina=0)
    legenda(tela, "O Rabbito foi o primeiro.", suave(1.8, 2.3, t))
    return tela


CAMINHADA = [("m02", "Bebê."), ("m03", "Criança."), ("m04", ""), ("m06", "Jovem."), ("m07", "Adulto.")]


def cena_caminhada(t, d, L):
    """Cinco cortes de 3 s: a página vira e a sarjeta passa pela tela."""
    passo = d / len(CAMINHADA)
    i = min(len(CAMINHADA) - 1, int(t / passo))
    local = t - i * passo
    tela = Image.new("RGB", (W, H), PAPEL)
    if i > 0 and local < .4:
        anterior = L.get(CAMINHADA[i - 1][0], CAMINHADA[i - 1][0], 1.0).quadro()
        faixa_motivo(tela, anterior, 170, 740, -10, t)
    img = L.get(CAMINHADA[i][0], CAMINHADA[i][0], 1.0).quadro()
    faixa_motivo(tela, img, 170, 740, i * passo if i > 0 else -10, t)
    texto = CAMINHADA[i][1]
    if texto:
        letreiro(tela, texto, (W - 330, 120), 110, cor=SOL, angulo=4, alpha=suave(.3, .6, local))
    return tela


def cena_tres_faixas(t, d, L):
    tela = Image.new("RGB", (W, H), PAPEL)
    nomes = ["m08", "m10", "m11"]
    alt = 300
    for k, nome in enumerate(nomes):
        img = L.get(nome, nome, 1.2).quadro()
        faixa_motivo(tela, img, 60 + k * (alt + 30), alt, k * .45, t, inclina=(-14 if k % 2 else 14))
    return tela


def cena_grade(t, d, L):
    tela = Image.new("RGB", (W, H), PAPEL)
    nomes = ["m09", "m12", "m13", "m14"]
    g = 22
    cel = [(40, 40, W / 2 - g / 2, H / 2 - g / 2), (W / 2 + g / 2, 40, W - 40, H / 2 - g / 2),
           (40, H / 2 + g / 2, W / 2 - g / 2, H - 40), (W / 2 + g / 2, H / 2 + g / 2, W - 40, H - 40)]
    for k, (nome, (x0, y0, x1, y1)) in enumerate(zip(nomes, cel)):
        entra = suave(k * .3, k * .3 + .25, t)
        if entra <= 0:
            continue
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        s = .6 + .4 * saida(entra)
        poly = [(cx + (x - cx) * s, cy + (y - cy) * s) for x, y in [(x0, y0), (x1, y0 + (12 if k % 2 else -12)), (x1, y1), (x0, y1)]]
        img = L.get(nome, nome, 1.2).quadro()
        quadro(tela, poly, img, foco=(.5, .55), zoom=1.15)
    legenda(tela, "Um parceiro em cada bairro.", suave(2.0, 2.5, t), y=H // 2 - 50)
    return tela


def cena_evolucao(t, d, L):
    """Rabbito → Rastro dos Ventos (ritual), depois a escolha dos cinco caminhos e o ritual
    do Mestre dos Fios (planos evo-rastro e evo-mestre, ritual real do jogo)."""
    tela = Image.new("RGB", (W, H), PAPEL)
    if t < 7.0:
        # 1º ritual: o plano começa na página do santuário (4,6 s do plano, depois da transição).
        img = L.get("evo1", "evo-rastro", 4.6).quadro()
        poly = [(40, 40), (W - 40, 40), (W - 40, H - 40), (40, H - 40)]
        quadro(tela, poly, img, foco=(.5, .4), zoom=1.25 + .1 * t / 7)
        r = linhas_radiais(9, int(120 * suave(.5, 1.5, t) * (1 - suave(3.2, 4.0, t))))
        tela.paste(r, (0, 0), r)
        letreiro(tela, "RABBITO", (W * .2, H * .8), 92, cor=PAPEL, angulo=-4, alpha=suave(.3, .6, t) * (1 - suave(2.4, 2.7, t)))
        letreiro(tela, "RASTRO DOS VENTOS", (W * .7, H * .82), 92, cor=SOL, angulo=-3, alpha=suave(3.0, 3.3, t))
        return tela
    local = t - 7.0
    img = L.get("evo2", "evo-mestre", 2.6).quadro()
    if local < 3.0:
        poly = [(80, 120), (W - 60, 70), (W - 100, H - 90), (40, H - 130)]
        quadro(tela, poly, img, foco=(.5, .4), zoom=1.12)
        letreiro(tela, "CINCO CAMINHOS.", (W / 2, H - 70), 96, cor=SOL, angulo=-2, alpha=suave(.5, .8, local))
        return tela
    if local < 5.6:
        tela = cobrir(img, (W, H), foco=(.5, .45), zoom=1.3)
        r = linhas_radiais(11, int(130 * suave(3.0, 3.5, local)))
        tela.paste(r, (0, 0), r)
        onomatopeia(tela, "vuuum.png", (W * .78, H * .8), 560, angulo=-8, alpha=suave(4.6, 4.8, local), tremor=4, t=t)
        return tela
    poly = [(60, 60), (W - 60, 90), (W - 80, H - 60), (80, H - 90)]
    quadro(tela, poly, img, foco=(.5, .4), zoom=1.08)
    letreiro(tela, "VOCÊ ESCOLHE UM.", (W / 2, H - 80), 92, cor=SOL, angulo=2, alpha=suave(5.9, 6.2, local))
    return tela


def cena_mosaico(t, d, L):
    tela, total = mosaico(t, d)
    letreiro(tela, f"{total} SOULMONSTERS.", (W / 2, H - 110), 120, cor=SOL, angulo=-3, alpha=suave(d - 3.2, d - 2.8, t))
    return tela


GUARDIOES = ["g-mormacoStory", "g-grutaBoss", "g-vulcaoBoss", "g-abismoBoss", "g-geleiraBoss"]


def cena_guardioes(t, d, L):
    passo = d / len(GUARDIOES)
    i = min(len(GUARDIOES) - 1, int(t / passo))
    local = t - i * passo
    img = L.get(GUARDIOES[i], GUARDIOES[i], 4.0).quadro()
    tela = img.copy()
    if local < .08:
        tela = Image.new("RGB", (W, H), PAPEL)
    return tela


def cena_possessao(t, d, L):
    img = L.get("pos", "possessao", 1.6).quadro()
    tela = Image.new("RGB", (W, H), PAPEL)
    poly = [(40, 40), (W - 40, 40), (W - 40, H - 40), (40, H - 40)]
    quadro(tela, poly, img, foco=(.5, .45), zoom=1.0 + .12 * t / d)
    legenda(tela, "O Carretel Negro.", suave(2.4, 2.9, t) * (1 - suave(d - .6, d, t)), y=70)
    return tela


def cena_duelo(t, d, L):
    """Duelo em quadros diagonais; o mesmo plano em dois enquadramentos."""
    img = L.get("duelo", "duelo", 2.6).quadro()
    tela = Image.new("RGB", (W, H), PAPEL)
    meio = d * .55
    if t < meio:
        poly = [(30, 30), (W - 30, 30), (W - 30, H - 30), (30, H - 30)]
        quadro(tela, poly, img, zoom=1.0)
        if t > 2.0:
            onomatopeia(tela, "zaak.png", (W * .75, H * .3), 520, angulo=-10, alpha=suave(2.0, 2.2, t) * (1 - suave(3.4, 3.7, t)), tremor=5, t=t)
        return tela
    a = [(30, 30), (W * .62, 30), (W * .44, H - 30), (30, H - 30)]
    b = [(W * .62 + 24, 30), (W - 30, 30), (W - 30, H - 30), (W * .44 + 24, H - 30)]
    quadro(tela, a, img, foco=(.25, .55), zoom=1.5)
    quadro(tela, b, img, foco=(.62, .62), zoom=1.7)
    onomatopeia(tela, "krak.png", (W * .72, H * .72), 440, angulo=8, alpha=suave(meio + .8, meio + 1.0, t), tremor=4, t=t)
    return tela


def cena_impacto(t, d, L):
    arte = carregar_rgb(os.path.join(ARTE, "impact-especial-rabbito.png"))
    tela = tremer(cobrir(arte, (W, H), zoom=1.0 + .05 * t / d), t, 9 * (1 - suave(0, 1.2, t)))
    onomatopeia(tela, "fwush.png", (W * .25, H * .2), 620, angulo=-12, alpha=suave(.15, .3, t), tremor=3, t=t)
    letreiro(tela, "CRÍTICO!", (W * .72, H * .82), 140, cor=RABIOLA, angulo=6, alpha=suave(.6, .8, t))
    return tela


def cena_silencio(t, d, L):
    return Image.new("RGB", (W, H), TINTA)


def cena_lendario(t, d, L):
    """Página do guardião em silhueta (plano g-eremor); o rugido racha a página."""
    img = L.get("ere", "g-eremor", 3.6).quadro()
    forca = 6 * suave(.2, .8, t) + 10 * suave(1.5, 1.8, t) * (1 - suave(4.6, 5.2, t))
    tela = tremer(img, t, forca)
    if t > 1.7:
        abre = saida(suave(1.7, 2.6, t))
        largura = W * .6
        for k in range(3):
            pedaco = carregar_rgba(os.path.join(ARTE, "onomatopeias", f"grrraaaooo-0{k + 1}.png"))
            escala = (largura / 3) / pedaco.width * (.7 + .3 * abre)
            p = pedaco.resize((int(pedaco.width * escala), int(pedaco.height * escala)), Image.BICUBIC)
            p = p.rotate((k - 1) * 5 * abre, resample=Image.BICUBIC, expand=True)
            x = int(W * .7 - largura / 2 * (.7 + .3 * abre) + k * (largura / 3) * (.7 + .3 * abre) + (k - 1) * 50 * abre)
            y = int(H * .7 - p.height / 2 + (k - 1) * 26 * abre)
            tela.paste(p, (x, y), p)
        d2 = ImageDraw.Draw(tela)
        r = random.Random(7)
        for _ in range(int(9 * abre)):
            x, y = r.uniform(0, W), r.uniform(0, H)
            pts = [(x, y)]
            for _ in range(5):
                x += r.uniform(-140, 140)
                y += r.uniform(-90, 90)
                pts.append((x, y))
            d2.line(pts, fill=PAPEL, width=6)
            d2.line(pts, fill=TINTA, width=2)
    if t > d - .4:
        return Image.new("RGB", (W, H), (255, 255, 255))
    return tela


def cena_fecho(t, d, L):
    arte = carregar_rgb(os.path.join(ARTE, "fecho-estadio.png"))
    tela = cobrir(arte, (W, H), foco=(.5, .5), zoom=1.12 - .1 * t / d)
    branco = 1 - suave(0, .6, t)
    if branco > 0:
        tela = Image.blend(tela, Image.new("RGB", (W, H), (255, 255, 255)), branco)
    letreiro(tela, "SOULMONSTERS", (W / 2, H * .2), 190, cor=SOL, angulo=-2, alpha=suave(3.6, 4.1, t))
    letreiro(tela, "ELO DAS RUÍNAS", (W / 2, H * .34), 74, cor=PAPEL, alpha=suave(4.4, 4.9, t), fonte_fn=lilita, espessura=8)
    letreiro(tela, "EM BREVE", (W - 260, H - 110), 80, cor=PAPEL, angulo=-4, alpha=suave(7.0, 7.4, t))
    return tela


# (início, fim, cena, planos usados) — marcos da trilha do trailer v2.
ROTEIRO = [
    (0.0, 9.0, cena_ceu, []),
    (9.0, 16.0, cena_primeiro, ["m01"]),
    (16.0, 31.0, cena_caminhada, ["m02", "m03", "m04", "m06", "m07"]),
    (31.0, 38.5, cena_tres_faixas, ["m08", "m10", "m11"]),
    (38.5, 46.0, cena_grade, ["m09", "m12", "m13", "m14"]),
    (46.0, 62.0, cena_evolucao, ["evo1", "evo2"]),
    (62.0, 72.0, cena_mosaico, []),
    (72.0, 94.0, cena_guardioes, GUARDIOES),
    (94.0, 102.0, cena_possessao, ["pos"]),
    (102.0, 116.0, cena_duelo, ["duelo"]),
    (116.0, 122.0, cena_impacto, []),
    (122.0, 127.8, cena_lendario, ["ere"]),
    (127.8, 140.0, cena_fecho, []),
]


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--planos", required=True)
    p.add_argument("--saida", required=True)
    p.add_argument("--de", type=float, default=0.0)
    p.add_argument("--ate", type=float, default=DURACAO)
    p.add_argument("--amostras", default="", help="pasta: grava um PNG por segundo em vez do vídeo")
    a = p.parse_args()
    musica = os.path.join(RAIZ, "godot/assets/audio/music/trailer-v2/trailer-v2.ogg")
    rugido = os.path.join(RAIZ, "godot/assets/audio/sfx-v1/creature/eremor_rugido_01.wav")
    enc = None
    if not a.amostras:
        atraso = max(0, int((123.6 - a.de) * 1000))
        enc = subprocess.Popen([
            "ffmpeg", "-loglevel", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
            "-ss", str(a.de), "-i", musica, "-i", rugido,
            "-filter_complex", f"[2:a]adelay={atraso}|{atraso},volume=1.4[r];[1:a][r]amix=inputs=2:duration=first:normalize=0[aout]",
            "-map", "0:v", "-map", "[aout]", "-t", str(a.ate - a.de),
            "-c:v", "libx264", "-preset", "medium", "-crf", "19", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k", a.saida],
            stdin=subprocess.PIPE)
    else:
        os.makedirs(a.amostras, exist_ok=True)
    L = Leitores(a.planos)
    total = int(round((a.ate - a.de) * FPS))
    cena_atual = None
    for n in range(total):
        tempo = a.de + n / FPS
        for ini, fim, cena, _ in ROTEIRO:
            if ini <= tempo < fim:
                break
        if cena is not cena_atual:
            L.fechar_exceto(set())
            cena_atual = cena
        tela = cena(tempo - ini, fim - ini, L)
        if enc:
            enc.stdin.write(tela.convert("RGB").tobytes())
        elif n % FPS == 0:
            tela.convert("RGB").resize((W // 2, H // 2)).save(os.path.join(a.amostras, f"{tempo:06.1f}.png"))
        if n % (FPS * 10) == 0:
            print(f"{tempo:6.1f}s", flush=True)
    L.fechar_exceto(set())
    if enc:
        enc.stdin.close()
        enc.wait()
    print("pronto", a.saida if enc else a.amostras)


if __name__ == "__main__":
    main()
