# Cleans overworld actor sheets: true alpha (manual 05.2) without touching drawing, size or manifest.
# Usage: python3 tools/clean-actor-alpha.py . <output folder>  (review the output, then copy over the sheets)
# - alpha < HAZE becomes 0 (dark halo left by background removal)
# - isolated specks (connected pieces smaller than MIN_PIECE px) are removed, per frame cell
# - alpha >= SOLID becomes 255 (bodies were 252-253, slightly see-through)
# - the anti-aliased edge between those limits is kept as it was
import json, sys, os
from collections import deque
from PIL import Image

HAZE, SOLID, MIN_PIECE = 16, 240, 60

def clean(path, frames, out):
    im = Image.open(path).convert('RGBA'); w, h = im.size
    a = bytearray(im.getchannel('A').tobytes())
    before = {'visible': sum(1 for v in a if v), 'haze': sum(1 for v in a if 0 < v < HAZE)}
    for i, v in enumerate(a):
        if v < HAZE: a[i] = 0
        elif v >= SOLID: a[i] = 255
    removed = 0
    for f in frames:  # connected pieces per cell (8-neighbour)
        x0, y0, x1, y1 = f['x'], f['y'], f['x'] + f['w'], f['y'] + f['h']
        seen = bytearray((x1 - x0) * (y1 - y0)); cw = x1 - x0
        for y in range(y0, y1):
            for x in range(x0, x1):
                k = (y - y0) * cw + (x - x0)
                if seen[k] or not a[y * w + x]: continue
                piece, q = [], deque([(x, y)]); seen[k] = 1
                while q:
                    px, py = q.popleft(); piece.append(py * w + px)
                    for dx in (-1, 0, 1):
                        for dy in (-1, 0, 1):
                            nx, ny = px + dx, py + dy
                            if x0 <= nx < x1 and y0 <= ny < y1:
                                kk = (ny - y0) * cw + (nx - x0)
                                if not seen[kk] and a[ny * w + nx]: seen[kk] = 1; q.append((nx, ny))
                if len(piece) < MIN_PIECE:
                    for p in piece: a[p] = 0
                    removed += len(piece)
    rgba = im.copy(); rgba.putalpha(Image.frombytes('L', (w, h), bytes(a)))
    # transparent pixels carry no colour: zero RGB so PNG compresses and nothing bleeds when filtered
    px = rgba.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0: px[x, y] = (0, 0, 0, 0)
    rgba.save(out, optimize=True)
    # manifest check: every cleaned silhouette must stay inside its measured bounds
    issues = []
    for i, f in enumerate(frames):
        cell = rgba.crop((f['x'], f['y'], f['x'] + f['w'], f['y'] + f['h'])).getchannel('A').point(lambda v: 255 if v >= 128 else 0).getbbox()
        b = f['bounds']
        if cell and (cell[0] < b['x'] - 2 or cell[1] < b['y'] - 2 or cell[2] > b['x'] + b['w'] + 2 or cell[3] > b['y'] + b['h'] + 2):
            issues.append((i, cell, b))
    after = sum(1 for v in a if v)
    return before, after, removed, issues

if __name__ == '__main__':
    root, outdir = sys.argv[1], sys.argv[2]; os.makedirs(outdir, exist_ok=True)
    m = json.load(open(f'{root}/assets/characters/overworld-v1/manifest.json'))
    jobs = [(f"{root}/assets/{c['image']}", c['frames'], k) for k, c in m['characters'].items()]
    hub = json.load(open(f'{root}/assets/hub/praca-v1/manifest.json'))
    jobs.append((f'{root}/assets/hub/praca-v1/kael.png', hub['actor']['frames'], 'kael'))
    for path, frames, name in jobs:
        out = f'{outdir}/{name}.png'
        before, after, removed, issues = clean(path, frames, out)
        print(f"{name:9} visíveis {before['visible']:>7} -> {after:>7} | halo {before['haze']:>6} | pontos soltos {removed:>5} | "
              f"PNG {os.path.getsize(path)//1024:>5} KB -> {os.path.getsize(out)//1024:>5} KB | bounds {'ok' if not issues else issues}")
