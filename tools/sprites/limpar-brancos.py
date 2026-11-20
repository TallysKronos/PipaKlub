"""Remove restos de fundo branco presos dentro de recortes (entre pernas, sob o corpo).

Um resto é uma mancha contínua de branco puro (todos os canais >= LIMIAR) com pelo menos
MINIMO pixels. A mancha e a franja clara em volta dela viram transparentes; o contorno escuro
e as cores da criatura ficam como estão.

Uso (a partir da raiz do repositório):
    python3 tools/sprites/limpar-brancos.py --conferir saida.png arte1.png arte2.png ...
    python3 tools/sprites/limpar-brancos.py --aplicar arte1.png arte2.png ...

--conferir pinta de verde o que seria removido (para revisar antes); --aplicar grava no lugar.
Branco que faz parte do desenho (nuvens, espuma, pelo) também é branco puro: confira e deixe
essas artes fora da lista.
"""
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

LIMIAR = 244
MINIMO = 150
FRANJA = 215


def mascara(rgba: np.ndarray) -> np.ndarray:
    visivel = rgba[..., 3] > 0
    branco = visivel & (rgba[..., :3].min(-1) >= LIMIAR)
    rotulos, total = ndimage.label(branco)
    if total == 0:
        return np.zeros(branco.shape, bool)
    tamanhos = ndimage.sum(branco, rotulos, range(1, total + 1))
    grandes = [i + 1 for i, t in enumerate(tamanhos) if t >= MINIMO]
    resto = np.isin(rotulos, grandes)
    # Franja: pixels claros e quase sem cor encostados na mancha (antisserrilhado do recorte).
    claro = visivel & (rgba[..., :3].min(-1) >= FRANJA) & ((rgba[..., :3].max(-1) - rgba[..., :3].min(-1)) < 28)
    for _ in range(3):
        resto |= ndimage.binary_dilation(resto) & claro
    return resto


def main() -> None:
    args = sys.argv[1:]
    if args[:1] == ["--conferir"]:
        saida, arquivos = args[1], args[2:]
        quadros = []
        for caminho in arquivos:
            rgba = np.array(Image.open(caminho).convert("RGBA")).astype(int)
            m = mascara(rgba)
            fundo = np.zeros_like(rgba)
            fundo[...] = (255, 0, 255, 255)
            alfa = rgba[..., 3:4] / 255
            prova = (rgba[..., :3] * alfa + fundo[..., :3] * (1 - alfa)).astype(np.uint8)
            prova[m] = (0, 200, 0)
            quadro = Image.fromarray(prova)
            quadro.thumbnail((360, 300))
            quadros.append(quadro)
            print(caminho, int(m.sum()), "pixels")
        largura = sum(q.width for q in quadros)
        altura = max(q.height for q in quadros)
        folha = Image.new("RGB", (largura, altura), (30, 30, 30))
        x = 0
        for q in quadros:
            folha.paste(q, (x, 0))
            x += q.width
        folha.save(saida)
    elif args[:1] == ["--aplicar"]:
        for caminho in args[1:]:
            imagem = Image.open(caminho).convert("RGBA")
            rgba = np.array(imagem)
            m = mascara(rgba.astype(int))
            rgba[m, 3] = 0
            Image.fromarray(rgba).save(caminho, optimize=True)
            print(caminho, int(m.sum()), "pixels removidos")
    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
