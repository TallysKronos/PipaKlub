"""Synchronize BEFORE/AFTER Godot captures for the Anaconda sheet pilot.

This only composes presentation captures. Authored PNGs are never modified.
"""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / 'tmp/overworld-prancha'
MODEL = 'anaconda-cavaleiro'
for variant in ('antes', 'depois'):
    report = json.loads((EVIDENCE / variant / 'report.json').read_text())
    assert not report['failures'], f'{variant}: failed playtest'
before = sorted((EVIDENCE / 'antes').glob(f'{MODEL}-[0-9][0-9][0-9].png'))
after = sorted((EVIDENCE / 'depois').glob(f'{MODEL}-[0-9][0-9][0-9].png'))
assert len(before) == len(after) == 40
pairs = []
for left, right in zip(before, after):
    canvas = Image.new('RGB', (840, 304), '#112b34')
    canvas.paste(Image.open(left), (0, 24))
    canvas.paste(Image.open(right), (420, 24))
    draw = ImageDraw.Draw(canvas)
    draw.text((12, 6), 'ANTES - ciclo regional', fill='#f6e9ce')
    draw.text((432, 6), 'DEPOIS - prancha ImageGen finalizada', fill='#f6e9ce')
    pairs.append(canvas)
atlas = Image.new('RGB', (840, 304*len(pairs)))
for i, pair in enumerate(pairs):
    atlas.paste(pair, (0, 304*i))
palette = atlas.quantize(colors=256, dither=Image.Dither.NONE)
frames = [pair.quantize(palette=palette, dither=Image.Dither.NONE) for pair in pairs]
durations = [10*(round((i+1)*100/15)-round(i*100/15)) for i in range(len(frames))]
frames[0].save(EVIDENCE / 'comparacao-in-game.gif', save_all=True,
               append_images=frames[1:], duration=durations, disposal=2,
               loop=0, optimize=False)
print('Synchronized comparison: 40 pairs, native scale, shared GIF palette')
