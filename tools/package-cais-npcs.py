"""Package transparent static Cais NPCs without background color keying."""
from pathlib import Path
from PIL import Image, ImageDraw
import json

root = Path(__file__).resolve().parent.parent
source = root / 'art/characters/cais-overworld-v1'
target = root / 'godot/assets/npc-ds/cais-v1'
target.mkdir(parents=True, exist_ok=True)
names = ['neril', 'ossian', 'vaelis', 'rhuna', 'marisol']
sheet = Image.new('RGBA', (800, 220), '#263c46')
draw = ImageDraw.Draw(sheet)
report = []
for i, name in enumerate(names):
    image = Image.open(source / (name + '-source.png')).convert('RGBA')
    assert image.getchannel('A').getextrema() == (0, 255), name
    box = image.getchannel('A').point(lambda a: 255 if a > 32 else 0).getbbox()
    assert box and box[0] > 0 and box[1] > 0 and box[2] < image.width and box[3] < image.height
    image = image.crop(box)
    image = image.resize((round(image.width * 112 / image.height), 112), Image.Resampling.LANCZOS)
    image.save(target / (name + '.png'))
    sheet.alpha_composite(image, (i * 160 + (160-image.width)//2, 45))
    draw.text((i*160+40, 180), name, fill='white')
    report.append({'name': name, 'size': image.size, 'alpha': image.getchannel('A').getextrema(), 'sourceBox': box})
sheet.convert('RGB').save(source / 'preview.png')
(source / 'qa.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print('PASS: 5 static sprites, genuine alpha, complete margins, height 112')
