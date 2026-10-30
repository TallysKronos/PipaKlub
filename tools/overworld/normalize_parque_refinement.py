"""Normalize generated sources, retaining originals and recording provenance."""
from pathlib import Path
from PIL import Image
import json
import shutil
import sys

root = Path(__file__).resolve().parents[2]
names = ('grama', 'terra', 'barranco')
records = []
for name, original in zip(names, sys.argv[1:], strict=True):
    source = root / 'art/overworld/kits/parque/pintura-v4/fontes' / (name + '.png')
    source.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(original, source)
    with Image.open(source) as image:
        dimensions = image.size
        normalized = image.convert('RGB').resize((512, 512), Image.Resampling.LANCZOS)
    for prefix in ('art/overworld/kits', 'godot/assets/overworld/kits'):
        target = root / prefix / 'parque/pintura-v4' / (name + '.png')
        target.parent.mkdir(parents=True, exist_ok=True)
        normalized.save(target)
    records.append(dict(file=name+'.png', source='fontes/'+name+'.png',
                        originalSize=dimensions, size=[512, 512],
                        generator='image_gen.imagegen',
                        normalization='RGB and uniform 512x512 Lanczos resize; no painted edits',
                        role='orthographic material; native geometry owns height and silhouette'))
manifest = dict(date='2026-10-29', approval='pending_owner_visual_review',
                direction='restrained 2D manga cel painting; quiet sage grass, tan packed earth without large cracks, broad earth strata',
                repetition='mirrored world-space sampling, audited at game scale and 3x3', files=records)
(root/'art/overworld/kits/parque/pintura-v4/MANIFESTO.json').write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
