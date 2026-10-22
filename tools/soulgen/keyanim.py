# Animates a hand-drawn key pose (art/soulgen/keys/<id>/) into the full Soulmonster sheet.
# The artist (Codex or a person) draws one 3/4 pose split into layers; this script moves the layers
# (body bob/lean, wings rotated at the shoulder, rabiola swaying, faces swapped, effects) and exports
# the same data as the procedural generator: <id>.png, <id>.json (anims, ticks, hit frames, anchors),
# <id>-atlas.json for the game, GIFs for review. Rotation uses a RotSprite-style nearest pass, so no new
# colours appear: the linter's 15-colour rule keeps holding.
# Usage: python3 tools/soulgen/keyanim.py art/soulgen/keys/<id> art/soulgen/out [variant]
import json, math, os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import procedural as core

CLEAR = (0, 0, 0, 0)
def hexc(h): return core.hexc(h)

def rotsprite(layer, pivot, deg, k=8):
    """Rotate pixel art without inventing colours: upscale x k (nearest), rotate (nearest), sample block centres."""
    if abs(deg) < .01: return layer
    w, h = layer.size; big = layer.resize((w * k, h * k), Image.NEAREST)
    big = big.rotate(deg, resample=Image.NEAREST, center=(pivot[0] * k + k / 2, pivot[1] * k + k / 2))
    out = Image.new('RGBA', (w, h), CLEAR); src, dst = big.load(), out.load()
    for y in range(h):
        for x in range(w): dst[x, y] = src[x * k + k // 2, y * k + k // 2]
    return out

def put(img, layer, dx, dy):
    """Composite a layer moved by (dx, dy); paste clips at the borders, so negative offsets are fine."""
    tmp = Image.new('RGBA', img.size, CLEAR); tmp.paste(layer, (dx, dy)); img.alpha_composite(tmp)

def sway(layer, pivot, phase, amp):
    """Rabiola in the wind: rows below the pivot slide sideways more the further they hang."""
    w, h = layer.size; out = Image.new('RGBA', (w, h), CLEAR); src, dst = layer.load(), out.load(); span = max(1, h - pivot[1])
    for y in range(h):
        u = max(0, y - pivot[1]) / span; off = round(amp * u * math.sin(phase + u * 3.2))
        for x in range(w):
            if src[x, y][3] and 0 <= x + off < w: dst[x + off, y] = src[x, y]
    return out

# motion per animation: body (dx, dy, lean°), wings (near°, far°: + raises the tip), tail (phase, amp), face, fx
MOTION = {
    'idle':    [dict(b=(0, 0, 0), w=(0, 0), t=(0, 1.5), face='normal'), dict(b=(0, -1, 0), w=(6, 4), t=(1.6, 1.5), face='normal'),
                dict(b=(0, -1, 0), w=(10, 8), t=(3.1, 1.5), face='blink'), dict(b=(0, 0, 0), w=(4, 2), t=(4.7, 1.5), face='normal')],
    'flight':  [dict(b=(-1, 0, -8), w=(-18, -12), t=(0, 4), face='fierce'), dict(b=(-1, -1, -8), w=(10, 8), t=(1.6, 4), face='fierce'),
                dict(b=(-1, -2, -8), w=(30, 24), t=(3.1, 4), face='fierce'), dict(b=(-1, -1, -8), w=(4, 2), t=(4.7, 4), face='fierce')],
    'skill':   [dict(b=(-2, 0, 8), w=(34, 30), t=(0, 2), face='fierce', fx='charge', fx_t=0),
                dict(b=(2, -1, -10), w=(-24, -18), t=(1.5, 3), face='fierce', fx='slash', fx_t=0),
                dict(b=(1, -1, -12), w=(-28, -22), t=(3, 3), face='fierce', fx='slash', fx_t=1),
                dict(b=(0, 0, -2), w=(6, 4), t=(4.5, 2), face='normal', fx='charge', fx_t=.6)],
    'hurt':    [dict(b=(-2, 1, 10), w=(-12, 16), t=(1, 3), face='hurt', fx='hit'), dict(b=(-1, 0, 5), w=(4, 8), t=(2.5, 2), face='hurt')],
    'victory': [dict(b=(0, -1, 0), w=(36, 32), t=(0, 1.5), face='happy', fx='sparkle', frame=0),
                dict(b=(0, -2, 0), w=(26, 22), t=(1.6, 1.5), face='happy', fx='sparkle', frame=1)],
}

def pose_frame(key, layers, m):
    g = key['canvas']; dx, dy, lean = m['b']; c = key['anchors']['center']
    img = Image.new('RGBA', (g, g), CLEAR)
    def place(layer, rot_pivot=None, deg=0):
        l = rotsprite(layer, rot_pivot, deg) if rot_pivot else layer
        l = rotsprite(l, c, lean) if lean else l                     # whole body leans together
        put(img, l, dx, dy)
    P = key['parts']
    tail = sway(layers['tail'], P['tail']['pivot'], m['t'][0], m['t'][1]); place(tail)
    for name, idx in (('wing_far', 1),):
        side = 1 if P[name]['side'] == 'right' else -1; place(layers[name], P[name]['pivot'], m['w'][idx] * side)
    place(layers['body'])
    face = layers['faces'].get(m.get('face', 'normal')) or layers['faces']['normal']; place(face)
    side = 1 if P['wing_near']['side'] == 'right' else -1; place(layers['wing_near'], P['wing_near']['pivot'], m['w'][0] * side)
    # anchors move with the body
    def mv(p):
        x, y = p; a = math.radians(-lean); cx, cy = c
        x, y = cx + (x - cx) * math.cos(a) - (y - cy) * math.sin(a), cy + (x - cx) * math.sin(a) + (y - cy) * math.cos(a)
        return (round(x + dx), round(y + dy))
    A = {k: mv(v) for k, v in key['anchors'].items()}; A['ground'] = (round(c[0]), key['ground_y'])
    # effects in the key's own palette roles
    if m.get('fx'):
        fx = key['fx']; P_ = {'fx_hot': hexc(fx['hot']), 'fx_mid': hexc(fx['mid']), 'fx_dim': hexc(fx['dim']), 'ink': hexc(key['palette'][0]),
                             'body_shine': hexc(fx['hot']), 'fx_edge': hexc(fx['edge'])}
        sp = {'grid': g}; pose = {k: v for k, v in m.items() if k in ('fx', 'fx_t', 'frame')}
        lay = core.fx_layer(sp, pose, P_, {'face': A['head'], 'bottom': A.get('tail', A['center'])})
        img.alpha_composite(core.outline(lay, P_['fx_edge']) if m['fx'] == 'slash' else lay)
    return img, A

def build(key_dir, out, variant=None):
    key = json.load(open(os.path.join(key_dir, 'key.json'))); os.makedirs(out, exist_ok=True)
    def load(f):
        im = Image.open(os.path.join(key_dir, f)).convert('RGBA')
        if variant:  # palette swap by slot index
            src = [hexc(x)[:3] for x in key['palette']]; dst = [hexc(x)[:3] for x in key['variants'][variant]]
            m = dict(zip(src, dst)); px = im.load()
            for y in range(im.height):
                for x in range(im.width):
                    p = px[x, y]
                    if p[3] and p[:3] in m: px[x, y] = m[p[:3]] + (255,)
        return im
    P = key['parts']
    layers = {n: load(P[n]['file']) for n in ('body', 'wing_near', 'wing_far', 'tail')}
    layers['faces'] = {k: load(f) for k, f in key['faces'].items()}
    if variant:
        vm = dict(zip(key['palette'], key['variants'][variant])); key = {**key, 'fx': {k: vm.get(v, v) for k, v in key['fx'].items()}, 'palette': key['variants'][variant]}
    g = key['canvas'] = layers['body'].width; key['ground_y'] = (g - key['cell']) // 2 + key['cell'] - 2
    sp = {'grid': g, 'cell': key['cell']}
    anims = key.get('anims', core.DEFAULT_ANIMS)
    tag = key['id'] + (f'-{variant}' if variant else '')
    data = {'id': key['id'], 'name': key['name'], 'variant': variant, 'source': 'key', 'shadowSize': key.get('shadowSize', 1),
            'sizeClass': key.get('sizeClass', 'medium'), 'tier': key.get('tier', 2),
            'palette': {('ink' if i == 0 else f's{i}'): c for i, c in enumerate(key['palette'])}, 'image': f'{tag}.png', 'anims': []}
    rows, y = [], 0
    for a in anims:
        frames, anchors = [], []
        for m in MOTION[a['name']]:
            img, A = pose_frame(key, layers, m); im, A = core.crop_cell(sp, img, A, a['cell']); frames.append(im); anchors.append(A)
        e = dict(a); e.update({'y': y, 'frames': len(frames), 'anchors': anchors}); data['anims'].append(e); rows.append((a, frames)); y += a['cell'][1]
    W = max(a['cell'][0] * len(f) for a, f in rows); sheet = Image.new('RGBA', (W, y), CLEAR)
    for (a, frames), e in zip(rows, data['anims']):
        for i, im in enumerate(frames): sheet.alpha_composite(im, (i * a['cell'][0], e['y']))
    sheet.save(f'{out}/{tag}.png'); json.dump(data, open(f'{out}/{tag}.json', 'w'), ensure_ascii=False, indent=1)
    atlas = {'frames': {}, 'animations': {}, 'playback': {}, 'meta': {'image': f'creatures/pixel-v1/{tag}.png', 'size': {'w': W, 'h': y}, 'transparent': True, 'pixelArt': True}}
    n = 0
    for e in data['anims']:
        ids = []
        for i in range(e['frames']):
            atlas['frames'][str(n)] = {'frame': {'x': i * e['cell'][0], 'y': e['y'], 'w': e['cell'][0], 'h': e['cell'][1]}, 'pivot': {'x': .5, 'y': .5}}; ids.append(str(n)); n += 1
        atlas['animations'][e['name']] = ids; atlas['playback'][e['name']] = {'durations': [round(t * 1000 / 60) for t in e['durations']], 'loop': e['loop']}
    json.dump(atlas, open(f'{out}/{tag}-atlas.json', 'w'), indent=1)
    for a, frames in rows:
        big = []
        for im in frames:
            b = Image.new('RGBA', (im.width * 6, im.height * 6), (246, 234, 208, 255)); b.alpha_composite(im.resize(b.size, Image.NEAREST)); big.append(b)
        big[0].save(f'{out}/{tag}-{a["name"]}.gif', save_all=True, append_images=big[1:], duration=[round(t * 1000 / 60) for t in a['durations']], loop=0)
    return data

if __name__ == '__main__':
    build(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None); print('ok')
