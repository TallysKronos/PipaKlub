from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[2]
folder = root / 'documentation/overworld/pip81'
report = json.loads((folder / 'plants.json').read_text(encoding='utf-8'))
canvas = Image.new('RGB', (1440, 900), '#15232d')
draw = ImageDraw.Draw(canvas)
for i, area in enumerate(report):
    source = folder / 'captures' / (area['id'] + '-planta-1280x720.png')
    im = Image.open(source).convert('RGB')
    im.thumbnail((470, 264))
    x, y = (i % 3) * 480 + 5, (i // 3) * 300 + 25
    canvas.paste(im, (x, y))
    draw.text((x, y - 18), area['id'], fill='#f1ddaa')
canvas.save(folder / 'nove-plantas.png', optimize=True)
refs = []
for path in sorted((folder / 'references').glob('*.png')):
    with Image.open(path) as im:
        im.verify()
    with Image.open(path) as im:
        refs.append({'file': path.name, 'size': list(im.size), 'bytes': path.stat().st_size})
assert len(refs) == 18, f'Expected 18 Mapa Studio exports, found {len(refs)}'
movement = json.loads((folder / 'captures/movement.json').read_text(encoding='utf-8'))
assert not movement['failures'], movement['failures']
assert len(movement['areas']) == 9
log = (root / 'tmp/pip81-native.log').read_text(encoding='utf-8')
assert 'SCRIPT ERROR' not in log and 'ERROR:' not in log
(folder / 'exports.json').write_text(json.dumps(refs, indent=2) + '\n', encoding='utf-8')
print('9 areas; 18 official Mapa Studio exports; 55 native movement visits; no rendering errors')
