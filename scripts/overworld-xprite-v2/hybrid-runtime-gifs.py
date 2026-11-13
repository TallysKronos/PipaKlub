"""Present actual Godot test captures without modifying authored sprite pixels."""
from pathlib import Path
import argparse
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--evidence', default='tmp/overworld-hybrid/playtest')
args = parser.parse_args()
folder = ROOT / args.evidence
report = json.loads((folder / 'report.json').read_text(encoding='utf-8'))
assert not report['failures'], 'Do not present a failed playtest as a completed validation'
for model in report['models']:
    name = model['id']
    for action, pattern, duration in [('movimento', f'{name}-[0-9][0-9][0-9].png', 1000/15),
                                      ('idle', f'{name}-idle-[0-9][0-9].png', 150)]:
        files = sorted(folder.glob(pattern))
        if not files:
            continue
        # Explicit palette shared by the captured sequence keeps GIF background
        # colors stable; resizing uses nearest neighbor and is presentation only.
        images = [Image.open(f).convert('RGB') for f in files]
        palette = Image.new('RGB', (420, 280 * len(images)))
        for i, image in enumerate(images):
            palette.paste(image, (0, 280*i))
        palette = palette.quantize(colors=256, dither=Image.Dither.NONE)
        frames = [im.quantize(palette=palette, dither=Image.Dither.NONE).resize((840, 560), Image.Resampling.NEAREST) for im in images]
        path = folder / f'{name}-{action}-in-game.gif'
        # GIF timing is quantized to 10ms: alternate 60/70ms rather than
        # truncating every 66.7ms capture interval to 60ms and speeding it up.
        durations = [10 * (round((i+1)*duration/10) - round(i*duration/10)) for i in range(len(frames))]
        frames[0].save(path, save_all=True, append_images=frames[1:], duration=durations,
                       loop=0, disposal=2, optimize=False)
        print(f'{name}/{action}: {len(frames)} captured frames -> {path}')
