"""Normalize generated art only: alpha crop, resize and record technical metadata."""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art/workshop-manga-v1/fontes'
DEST = ROOT / 'godot/assets/campaign/workshop-manga-v1'
DEST.mkdir(parents=True, exist_ok=True)
records = []
for name, source, maximum, alpha in [
    ('bancada', 'bancada-manga', (1440, 960), False),
    ('vareta', 'vareta', (24, 384), True),
    ('tesoura', 'tesoura', (196, 308), True),
]:
    image = Image.open(SOURCE / (source + '.png')).convert('RGBA')
    original_size = image.size
    bounds = None
    if alpha:
        # Ignore nearly invisible generator residue far outside the silhouette.
        bounds = image.getchannel('A').point(lambda a: 255 if a >= 96 else 0).getbbox()
        if bounds is None:
            raise ValueError(f'Empty asset: {source}')
        image = image.crop(bounds)
    image.thumbnail(maximum, Image.Resampling.LANCZOS)
    if not alpha:
        image = image.convert('RGB')
    image.save(DEST / (name + '.png'), optimize=True)
    records.append(dict(id=name, source=source+'.png', source_size=original_size,
                        crop=bounds, size=image.size, alpha=alpha,
                        pivot='center', collision='none; existing model owns hit regions',
                        status='integrated locally; artistic review pending'))
(ROOT / 'art/workshop-manga-v1/manifest.json').write_text(
    json.dumps(dict(generator='built-in image_gen', assets=records), indent=2), encoding='utf-8')
print(json.dumps(records))
