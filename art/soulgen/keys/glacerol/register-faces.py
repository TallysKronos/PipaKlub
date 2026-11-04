"""Register generated eye windows; preserve canonical head outside window and alpha."""
from pathlib import Path
from PIL import Image, ImageChops
import json, shutil

ROOT = Path(__file__).resolve().parent / 'cutout-rig-v1'
source = Image.open(ROOT / 'expressions-source.png').convert('RGBA')
head = Image.open(ROOT / 'head.png').convert('RGBA')
window = (97, 158, 190, 225)
canonical_bounds = head.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()
report = {'method': 'Generated eye regions registered to canonical alpha bounds; only fixed eye window composited.', 'windows': [[97, 158, 93, 67]], 'expressions': {}}
review = Image.new('RGBA', (head.width * 4, head.height), '#f3ead6')
review.alpha_composite(head, (0, 0))
for index, face in enumerate(['fierce', 'hurt', 'happy']):
    left = round(index * source.width / 3)
    right = round((index + 1) * source.width / 3)
    generated = source.crop((left, 0, right, source.height))
    bounds = generated.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()
    assert bounds
    aligned = Image.new('RGBA', head.size)
    target = (canonical_bounds[2] - canonical_bounds[0], canonical_bounds[3] - canonical_bounds[1])
    aligned.paste(generated.crop(bounds).resize(target, Image.Resampling.NEAREST), canonical_bounds[:2])
    result = head.copy()
    result.paste(aligned.crop(window), window[:2])
    result.putalpha(head.getchannel('A'))
    outside = ImageChops.difference(head, result)
    outside.paste((0, 0, 0, 0), window)
    assert not outside.convert('RGB').getbbox(), face
    assert not ImageChops.difference(head.getchannel('A'), result.getchannel('A')).getbbox(), face
    result.save(ROOT / ('head-' + face + '.png'))
    review.alpha_composite(result, ((index + 1) * head.width, 0))
    report['expressions'][face] = {'alpha_identical': True, 'outside_window_identical': True, 'source_bounds': bounds}
review.convert('RGB').save(ROOT / 'expressions-review.png')
(ROOT / 'registration.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf8')
print(report)
