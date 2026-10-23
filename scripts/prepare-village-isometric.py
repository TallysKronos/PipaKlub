"""Reproduce reviewed sprite slices. No resampling or background replacement."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art/soulgen/keys/village-isometric-v1'
DEST = ROOT / 'assets/world/village-isometric-v1'
cells = json.loads((SOURCE / 'slices.json').read_text())
old = json.loads((DEST / 'manifest.json').read_text())
images = {}
for name, (atlas, cell) in cells.items():
    source = Image.open(SOURCE / f'source-{atlas}.png').convert('RGBA').crop(cell)
    if name == 'desk':
        # The reviewed atlas cell also contains a disconnected tip of the next
        # row. Keep the table component, including its antialiased edge.
        alpha = source.getchannel('A')
        pixels = alpha.load()
        unseen = {(x, y) for y in range(source.height) for x in range(source.width) if pixels[x, y] > 32}
        components = []
        while unseen:
            seed = unseen.pop()
            component, pending = {seed}, [seed]
            while pending:
                x, y = pending.pop()
                for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
                    p = (x + dx, y + dy)
                    if p in unseen:
                        unseen.remove(p)
                        component.add(p)
                        pending.append(p)
            components.append(component)
        keep = max(components, key=len)
        mask = Image.new('L', source.size)
        for p in keep:
            mask.putpixel(p, 255)
        from PIL import ImageFilter, ImageChops
        source.putalpha(ImageChops.multiply(alpha, mask.filter(ImageFilter.MaxFilter(5))))
    bounds = source.getchannel('A').point(lambda a: 255 if a > 32 else 0).getbbox()
    if not bounds:
        raise ValueError(f'Empty sprite: {name}')
    sprite = source.crop(bounds)
    out = Image.new('RGBA', (sprite.width + 12, sprite.height + 12))
    out.paste(sprite, (6, 6))
    out.save(DEST / f'{name}.png')
    images[name] = dict(image=f'world/village-isometric-v1/{name}.png',
                        width=out.width, height=out.height,
                        pivot=old['images'][name]['pivot'],
                        source=dict(atlas=atlas, cell=cell, crop=list(bounds)))
(DEST / 'manifest.json').write_text(json.dumps(dict(version=1, projection=[.82, .41], images=images), indent=2) + '\n')
