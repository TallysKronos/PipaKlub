"""Measure generated sheets without changing any image pixels.

Usage: python scripts/build-overworld-companions.py
Sources and direction order are recorded in assets/creatures/overworld-v1/sources.json.
"""
import hashlib
import json
import shutil
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/creatures/overworld-v1'
sources = json.loads((OUT / 'sources.json').read_text(encoding='utf-8'))
manifest = {'version': 1, 'kind': 'soulmonster-overworld',
            'directions': ['south', 'west', 'east', 'north'],
            'basics': ['carcara', 'mata-verde', 'azulao', 'raio-de-sol'], 'species': {}}
reports = []
for source in sources:
    sid = source['id']
    origin = Path(source['source'])
    dest = OUT / (sid + '.png')
    if not origin.exists():
        origin = dest
    if origin.resolve() != dest.resolve():
        shutil.copy2(origin, dest)
    image = Image.open(dest)
    assert image.mode == 'RGBA', (sid, 'missing alpha')
    alpha = image.getchannel('A')
    assert alpha.getextrema()[0] == 0, (sid, 'no transparent pixels')
    width, height = image.size
    frames = []
    margins = []
    for i in range(8):
        x, right = round((i % 4) * width / 4), round((i % 4 + 1) * width / 4)
        y, bottom = round((i // 4) * height / 2), round((i // 4 + 1) * height / 2)
        cell = alpha.crop((x, y, right, bottom))
        box = cell.point(lambda v: 255 if v > 32 else 0).getbbox()
        assert box, (sid, i, 'empty frame')
        left, top, r, b = box
        margin = min(left, top, right-x-r, bottom-y-b)
        assert margin >= 3, (sid, i, 'clipped or touching cell')
        margins.append(margin)
        # Explicit anchors can override the measured silhouette center, which
        # includes a tail. The source PNG is always preserved unchanged.
        anchor = source.get('anchors', {}).get(str(i), [(left+r)/2, b])
        frames.append({'x': x, 'y': y, 'w': right-x, 'h': bottom-y,
                       'bounds': {'x': left, 'y': top, 'w': r-left, 'h': b-top},
                       'footAnchor': {'x': anchor[0], 'y': anchor[1]}})
    columns = source.get('columnsByDirection', [0, 1, 2, 3])
    actor = {'id': sid, 'name': source['name'], 'image': 'creatures/overworld-v1/'+sid+'.png',
             'referenceHeight': max(f['bounds']['h'] for f in frames),
             'scale': source.get('scale', 1), 'frameMs': 200, 'frames': frames,
             'animations': {'idle': [[i] for i in columns],
                            'move': [[i, i+4] for i in columns]},
             'status': 'integrated-locally-pending-art-review'}
    manifest['species'][sid] = actor
    reports.append({'id': sid, 'size': [width, height], 'frames': 8,
                    'minCellMargin': min(margins), 'alphaRange': alpha.getextrema(),
                    'sha256': hashlib.sha256(dest.read_bytes()).hexdigest(),
                    'columnsByDirection': columns,
                    'geometryValid': True, 'animationApproval': 'manual-review-required'})
(OUT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
(OUT / 'validation.json').write_text(json.dumps(reports, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print(json.dumps({'species': len(reports), 'geometryValid': True}, ensure_ascii=False))
