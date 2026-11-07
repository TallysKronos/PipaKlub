"""Inspeciona alpha da referência, sem modificar seus pixels."""
from pathlib import Path
from PIL import Image
import json

root = Path(__file__).parent
im = Image.open(root / 'referencia.png').convert('RGBA')
px = im.load()
bands = []
for y in range(im.height):
    if any(px[x, y][3] > 127 for x in range(im.width)):
        if not bands or y > bands[-1][-1] + 1:
            bands.append([y])
        else:
            bands[-1].append(y)
out = []
for band in bands:
    lo, hi = band[0], band[-1]
    groups = []
    for x in range(im.width):
        if any(px[x, y][3] > 127 for y in range(lo, hi + 1)):
            if not groups or x > groups[-1][-1] + 1:
                groups.append([x])
            else:
                groups[-1].append(x)
    out.append({'y': lo, 'height': hi-lo+1, 'groups': [
        {'x': g[0], 'width': len(g)} for g in groups
    ]})
report = {'width': im.width, 'height': im.height, 'alphaThreshold': 127,
          'note': 'Grupos por projeção alpha; não são células confirmadas do atlas original.',
          'bands': out}
(root / 'medidas.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(f'{im.width}x{im.height}; {len(out)} faixas; pixels preservados.')
