"""Normalize generated transparent static sprites; never color-key concept sheets."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'art/characters/vila-operaria-overworld-v1'
TARGET = ROOT / 'godot/assets/npc-ds/vila-operaria-v1'
TARGET.mkdir(parents=True, exist_ok=True)
report = []
normalized = []
for path in sorted(SOURCE.glob('*-source.png')):
    name = path.name.removesuffix('-source.png')
    sprite = Image.open(path).convert('RGBA')
    alpha = sprite.getchannel('A')
    assert alpha.getextrema() == (0, 255), f'{name}: genuine alpha required'
    box = alpha.point(lambda a: 255 if a > 32 else 0).getbbox()
    assert box and box[0] > 0 and box[1] > 0 and box[2] < sprite.width and box[3] < sprite.height, f'{name}: clipped source'
    content = sprite.crop(box)
    content = content.resize((round(content.width * 112 / content.height), 112), Image.Resampling.LANCZOS)
    content.save(TARGET / f'{name}.png')
    normalized.append((name, content))
    report.append({'name': name, 'size': list(content.size), 'alpha': list(content.getchannel('A').getextrema()), 'sourceBox': list(box), 'frames': 1, 'facing': 'southeast', 'animated': False})
assert report, 'no sources'
preview = Image.new('RGBA', (len(normalized) * 170, 210), '#263c46')
draw = ImageDraw.Draw(preview)
for i, (name, content) in enumerate(normalized):
    preview.alpha_composite(content, (i * 170 + (170-content.width)//2, 45))
    draw.text((i * 170 + 20, 177), name, fill='white')
preview.convert('RGB').save(SOURCE / 'preview-112.png')
(SOURCE / 'qa.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(f'PASS: {len(report)} static sprites; genuine alpha; unclipped source bounds; height112')
