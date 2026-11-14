#!/usr/bin/env python3
"""Verify Kronasta art kit PNGs and, optionally, build the visual QA sheet."""
import argparse
import json
from pathlib import Path
import os
import re
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
KITS = ROOT / 'godot/assets/overworld/kits'
QA = ROOT / 'documentation/qa/kits-tiles-v1'
NEAREST = Image.Resampling.NEAREST
EXPECTED = {
    'morro-v2': ('pedra-clara cimento-laje terra-batida grama-quintal telha-barro muro-arrimo tijolo-aparente reboco-pintado-rosa reboco-pintado-creme reboco-pintado-amarela reboco-pintado-azul reboco-pintado-verde', 'caixa-dagua:2x2 varal:2x1 antena:1x1 vaso-planta:1x1 gato-de-luz:1x1 escadaria-cimento:1x2'),
    'cavernas-cristal-v1': ('rocha-gruta cascalho cristal-chao agua-gruta parede-cristal parede-gruta-umida', 'cristal-grande:2x2 cristal-pequeno:1x1 estalagmite:1x1 cogumelo-luz:1x1 ponte-corda:1x1'),
    'planicies-v1': ('capim-alto campo-flor trilha-terra pedregulho barranco-campo', 'moinho:2x2 cerca:1x1 feno:1x1 arvore-solitaria:2x2 pedra-marco:1x1 biruta:1x1'),
}


def check(condition, reason):
    if not condition:
        raise ValueError(reason)


def manifest(folder, name):
    return json.loads((folder / name).read_text(encoding='utf-8'))


def read_png(folder, entry, group, item, mode):
    target = f'{group}/{item}.png'
    check(entry['file'] == target, f'arquivo esperado: {target}')
    with Image.open(folder / target) as im:
        check(im.format == 'PNG' and im.mode == mode, f'esperado PNG {mode}; encontrado {im.format} {im.mode}')
        check(list(im.size) == entry['size'], f'dimensões não coincidem com manifesto: {im.size}')
        return im.copy()


def edge_difference(im, first, last):
    return max(high for _, high in ImageChops.difference(im.crop(first), im.crop(last)).getextrema())


def polygon_at(anchor, a, b):
    x, y = anchor
    return [(x+16*(b-a), y-8*(a+b)), (x+16*(a+b), y+8*(a-b)),
            (x+16*(a-b), y+8*(a+b)), (x-16*(a+b), y+8*(b-a))]


def halo_pixels(im):
    """Find white matte pixels adjacent to transparency, not interior highlights."""
    px = im.load()
    count = 0
    for y in range(1, im.height - 1):
        for x in range(1, im.width - 1):
            r, g, b, a = px[x, y]
            if a and min(r, g, b) >= 228 and max(r, g, b)-min(r, g, b) <= 20:
                if any(not px[x+dx, y+dy][3] for dx, dy in ((1,0), (-1,0), (0,1), (0,-1))):
                    count += 1
    return count


def validate(kit):
    folder = KITS / kit
    library = manifest(folder, 'library.json')
    index = manifest(folder, 'kit.json')
    check(index['id'] == kit and library['grid'] == [64,32], 'identidade ou grade inválida')
    specs = library['surfaces']
    assets = index['assets']
    ids = {e['id'] for e in specs}
    check(len(specs) == len(ids), 'IDs de superfície duplicados')
    for item in ids | assets.keys():
        check(re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', item), f'ID inválido: {item}')
    if kit in EXPECTED:
        surfaces, pieces = EXPECTED[kit]
        footprints = {p.split(':')[0]: list(map(int,p.split(':')[1].split('x'))) for p in pieces.split()}
        check(ids == set(surfaces.split()) and assets.keys() == footprints.keys(), 'lista incompleta ou inesperada')
    else:
        footprints = {}
    check({p.stem for p in (folder/'surfaces').glob('*.png')} == ids, 'PNGs de superfícies não batem com o índice')
    check({p.stem for p in (folder/'pecas').glob('*.png')} == assets.keys(), 'PNGs de peças não batem com o índice')
    textures, sprites = [], []
    errors = []
    for e in specs:
        name = e['id']
        try:
            im = read_png(folder, e, 'surfaces', name, 'RGB')
            check(im.size == (512,512), 'textura precisa ter 512 x 512 px')
            colors = im.getcolors(7) or []
            palette = {''.join(f'{ch:02X}' for ch in color) for _, color in colors}
            check(4 <= len(colors) <= 6 and e['colors'] == len(colors), 'esperado 4–6 cores e contagem igual à do manifesto')
            check(palette == set(e['palette']) and len(e['palette']) == len(palette), 'paleta não coincide com o PNG')
            x = edge_difference(im, (0,0,1,512), (511,0,512,512))
            y = edge_difference(im, (0,0,512,1), (0,511,512,512))
            check(x == e['oppositeXMaxDifference'] == y == e['oppositeYMaxDifference'] == 0, f'emenda: diferença X={x}, Y={y}')
            print(f'  OK  {name}: RGB 512x512; {len(colors)} cores; bordas X={x}, Y={y}')
            textures.append((name, im, e['kind']))
        except (ValueError, OSError, KeyError) as exc:
            errors.append(f'{name}: {exc}')
    for name, e in assets.items():
        try:
            im = read_png(folder, e, 'pecas', name, 'RGBA')
            a, b = e['footprint']
            check(all(type(n) is int and n > 0 for n in (a,b)) and e['footprint'] == footprints.get(name, e['footprint']), 'pegada inválida')
            ax, ay = e['anchor']
            check(0 <= ax < im.width and 0 <= ay < im.height, 'pivô fora da tela')
            # Four corners of the world-space base, projected around its center.
            expected = polygon_at((ax,ay),a,b)
            check(expected == [tuple(p) for p in e['basePolygon']], 'basePolygon não segue a projeção 64x32')
            alpha = im.getchannel('A')
            hist = alpha.histogram()
            check(hist[0] and hist[255] and not sum(hist[1:255]), 'recorte precisa ter transparência real e alpha binário')
            box = alpha.getbbox()
            margin = (box[0], box[1], im.width-box[2], im.height-box[3])
            check(all(1 <= m <= 6 for m in margin), f'fundo ou margem excedente: {margin}')
            check(not halo_pixels(im), 'halo branco nas bordas transparentes')
            # Non-elevated pads must reach the four ground corners. The staircase
            # is elevated at the uphill end, so review its supports on the sheet.
            if name not in {'escadaria-cimento'}:
                check(all(0 <= x < im.width and 0 <= y < im.height and alpha.getpixel((x,y))
                          for x,y in expected), 'arte não alcança os quatro vértices da base')
            print(f'  OK  {name}: RGBA {im.width}x{im.height}; {a}x{b}; apoio ({ax},{ay}); alpha limpo')
            sprites.append((name, im, e))
        except (ValueError, OSError, KeyError) as exc:
            errors.append(f'{name}: {exc}')
    if errors:
        raise ValueError('\n  '.join(errors))
    print(f'  PASSOU: {len(textures)} texturas e {len(sprites)} peças')
    return textures, sprites


def diamond(texture, a, b):
    w, h = 32*(a+b), 16*(a+b)
    im = Image.new('RGBA',(w+1,h+1))
    px = im.load()
    base = texture.resize((128,128), NEAREST)
    for y in range(h+1):
        for x in range(w+1):
            u = (y/16+(x-32*b)/32)/2
            v = (y/16-(x-32*b)/32)/2
            if 0 <= u <= a and 0 <= v <= b:
                px[x,y] = (*base.getpixel((int(u*64)%128,int(v*64)%128)),255)
    return im


def board(kit, textures, sprites):
    cols, tile, box = 4, 96, 326
    rows = (len(textures)+cols-1)//cols
    objrows = (len(sprites)+cols-1)//cols
    width = cols*box+36
    height = 98+rows*box+64+objrows*310+24
    img = Image.new('RGB',(width,height),'#1D2528')
    d = ImageDraw.Draw(img)
    def font(n):
        try:
            return ImageFont.truetype('DejaVuSans.ttf',n)
        except OSError:
            candidate = Path(os.environ.get('WINDIR', 'C:/Windows')) / 'Fonts/segoeui.ttf'
            if candidate.is_file():
                return ImageFont.truetype(str(candidate), n)
            return ImageFont.load_default(size=n)
    title, label, detail = font(33), font(16), font(13)
    d.text((24,16),kit,font=title,fill='#F1DFB8')
    d.text((26,62),'SUPERFÍCIES · repetição 3 × 3 · PNG RGB 512 × 512',font=label,fill='#B9C7BA')
    for i,(name,im,kind) in enumerate(textures):
        x, y = 25+i%cols*box, 99+i//cols*box
        tile_im=im.resize((tile,tile),NEAREST)
        for v in range(3):
            for u in range(3):
                img.paste(tile_im,(x+u*tile,y+v*tile))
        d.text((x,y+293),name,font=label,fill='#F2E5CC')
        d.text((x,y+311),f'{kind}  /  {len(im.getcolors())} cores  /  emendas 0, 0',font=detail,fill='#A9BBAF')
    by=106+rows*box
    d.text((25,by),'PEÇAS · escala nativa 1:1 · apoio no centro geométrico',font=label,fill='#B9C7BA')
    floor=next(im for _,im,k in textures if k=='ground')
    for i,(name,im,e) in enumerate(sprites):
        x,y=25+i%cols*box,by+35+i//cols*310
        d.rounded_rectangle((x,y,x+box-23,y+298),radius=6,fill='#2C3537',outline='#54605B')
        a,b=e['footprint']
        # One extra cell around the object exposes contact with neighbouring floor.
        base=diamond(floor,a+2,b+2)
        ax,ay=e['anchor']
        px=x+(box-23)//2
        py=y+190
        ground_origin=(px-base.width//2,py-base.height//2)
        img.paste(base,ground_origin,base)
        # Draw the footprint on the surface before the piece, then show the
        # pivot and projected footprint beside its labels as a small inset.
        img.paste(im,(px-ax,py-ay),im)
        d.text((x+14,y+263),name,font=label,fill='#F2E5CC')
        d.text((x+14,y+281),f'{a}×{b} células · apoio {ax}, {ay} px',font=detail,fill='#B9C7BA')
        poly=polygon_at((x+box-55,y+279),a,b)
        center=(x+box-55,y+279)
        p=[(center[0]+(u-center[0])//5,center[1]+(v-center[1])//5) for u,v in poly]
        d.line(p+[p[0]],fill='#D9B884')
        d.rectangle((center[0]-1,center[1]-1,center[0]+1,center[1]+1),fill='#EAD19A')
    QA.mkdir(parents=True,exist_ok=True)
    img.save(QA/f'{kit}.png',optimize=True)


def main():
    cli=argparse.ArgumentParser(description=__doc__)
    cli.add_argument('kit',choices=EXPECTED)
    cli.add_argument('--prancha',action='store_true')
    args=cli.parse_args()
    print(args.kit)
    try:
        textures,sprites=validate(args.kit)
        if args.prancha:
            board(args.kit,textures,sprites)
    except (ValueError, OSError, KeyError) as exc:
        print(f'  FALHOU: {exc}',file=sys.stderr)
        return 1
    return 0


if __name__=='__main__':
    sys.exit(main())
