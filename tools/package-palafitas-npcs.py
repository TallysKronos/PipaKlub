"""Normalize approved alpha sources; retain the connected character, discard stray pixels."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'art/characters/palafitas-overworld-v1'
TARGET = ROOT / 'godot/assets/npc-ds/palafitas-v1'
TARGET.mkdir(parents=True, exist_ok=True)
NAMES = ['caio', 'seyran', 'oruvo', 'kessai', 'veldren']
report = []
board = Image.new('RGBA', (850, 370), '#263c46')
draw = ImageDraw.Draw(board)
draw.rectangle((0, 185, 850, 370), fill='#f0e4ca')
for i, name in enumerate(NAMES):
    source = Image.open(SOURCE / f'{name}-source.png').convert('RGBA')
    alpha = source.getchannel('A')
    assert alpha.getextrema()[0] == 0 and alpha.getextrema()[1] >= 250
    core = alpha.point(lambda a: 255 if a >= 128 else 0)
    # Torso seed is selected from the central row; the connected silhouette includes
    # costume, hair, hands and feet. No color-keying or painted anatomy changes.
    y = source.height // 2
    spans = [x for x in range(source.width) if core.getpixel((x, y)) == 255]
    assert spans, name
    seed = min(spans, key=lambda x: abs(x-source.width//2))
    ImageDraw.floodfill(core, (seed, y), 128)
    component = core.point(lambda a: 255 if a == 128 else 0)
    support = component.filter(ImageFilter.MaxFilter(5))
    clean = Image.new('RGBA', source.size)
    clean.paste(source, (0, 0))
    clean.putalpha(Image.composite(alpha, Image.new('L', source.size), support))
    box = clean.getchannel('A').getbbox()
    assert box and 0 < box[0] < box[2] < source.width and 0 < box[1] < box[3] < source.height, name
    removed = sum(1 for before, after in zip(alpha.getdata(), clean.getchannel('A').getdata()) if before and not after)
    sprite = clean.crop(box)
    sprite = sprite.resize((round(sprite.width*112/sprite.height), 112), Image.Resampling.LANCZOS)
    sprite.save(TARGET / f'{name}.png')
    assert sprite.height == 112 and sprite.getchannel('A').getextrema()[0] == 0
    for row in range(2):
        board.alpha_composite(sprite, (i*170+(170-sprite.width)//2, 30+row*185))
        draw.text((i*170+45, 150+row*185), name, fill='white' if row == 0 else '#263c46')
    report.append({'name':name,'sourceSize':source.size,'sourceBox':box,'removedStrayPixels':removed,'size':sprite.size,'alpha':sprite.getchannel('A').getextrema(),'frames':1,'facing':'southeast','animated':False,'pivot':[sprite.width/2,112]})
board.convert('RGB').save(SOURCE / 'preview-112.png')
(SOURCE / 'qa.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print('PASS: five connected silhouettes, source margins intact, height112; native review still required')
