"""Mechanical atlas slicing/resampling only. Original drawing and alpha are preserved."""
from pathlib import Path
from PIL import Image
import json
import hashlib

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[3]
OUT = REPO / 'godot/assets/ui/mural-v1'
records = []


def cut(source, name, box, kind):
    image = Image.open(ROOT / 'fontes' / source).convert('RGBA')
    cell = image.crop(box)
    # Ignore sub-visible generation specks when finding the crop; keep the
    # original pixels/alpha inside the resulting rectangle unchanged.
    bounds = cell.getchannel('A').point(lambda alpha:255 if alpha>=96 else 0).getbbox()
    if bounds is None:
        raise ValueError('Empty cell: ' + name)
    cell = cell.crop(bounds)
    if kind == 'icons':
        cell.thumbnail((224, 224), Image.Resampling.LANCZOS)
        result = Image.new('RGBA', (256, 256))
        result.alpha_composite(cell, ((256-cell.width)//2, (256-cell.height)//2))
    else:
        scale = 320 / cell.width
        cell = cell.resize((320, round(cell.height*scale)), Image.Resampling.LANCZOS)
        result = Image.new('RGBA', (328, cell.height+8))
        result.alpha_composite(cell, (4, 4))
    folder = OUT / kind
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / (name + '.png')
    result.save(path)
    records.append(dict(id=name, file=str(path.relative_to(REPO)).replace('\\', '/'),
                        source=source, cell=list(box), alphaBounds=list(bounds),
                        dimensions=list(result.size), sha256=hashlib.sha256(path.read_bytes()).hexdigest()))


panels = ['paper', 'selected', 'ink', 'title-paper', 'title-sun', 'clips']
for n, name in enumerate(panels):
    x, y = n % 3 * 724, n // 3 * 362
    cut('panels-source.png', name, (x, y, x+724, y+362), 'pieces')

with Image.open(ROOT / 'fontes/boards-source.png') as board_source:
    width, height = board_source.size
for n, name in enumerate(['board-paper','board-ink','board-sun']):
    cut('boards-source.png', name, (round(n*width/3),0,round((n+1)*width/3),height), 'pieces')

with Image.open(ROOT / 'fontes/title-paper-corners-source.png') as title_source:
    width, height = title_source.size
cut('title-paper-corners-source.png', 'title-paper-v2', (0,0,width,height), 'pieces')

# The generated sheet's optical rows are not mathematically equal. Cuts follow
# the transparent gutters, inspected before export, instead of clipping art.
xs, ys = [0, 386, 730, 1094, 1448], [0, 402, 735, 1086]
icons = ['team', 'bag', 'missions', 'emblems', 'identity', 'workshop', 'save',
         'settings', 'dex', 'evolution', 'varal', 'puxao']
for n, name in enumerate(icons):
    col, row = n % 4, n // 4
    box = (xs[col], ys[row], xs[col+1], ys[row+1])
    # The top row has different gutters: avoid importing the neighboring
    # satchel/map's edge fragments into the larger pop-out illustrations.
    if name == 'team': box = (0,0,370,402)
    if name == 'bag': box = (370,0,730,402)
    if name == 'missions': box = (730,0,1110,402)
    if name == 'emblems': box = (1110,0,1448,402)
    cut('icons-source.png', name, box, 'icons')

manifest = dict(version=1, direction='Mural de Kronasta', pieces=records,
                processing='Atlas cuts, alpha trim, uniform resample and transparent padding only; no repaint or palette conversion.',
                styleboxTextureMargins=dict(left=28, top=36, right=28, bottom=28),
                nativeText=True)
(ROOT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
(OUT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print('Exported', len(records), 'RGBA pieces/icons')
