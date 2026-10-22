# Soulmonster pixel-art generator, v1.
# A species is data (shape, parts, palette); each frame is a pose of a rig whose parts are geometry,
# rasterised straight onto the pixel grid (no rotation of pixels, no smoothing), outlined part by part.
import json, math, os, sys
from PIL import Image, ImageDraw

CLEAR = (0, 0, 0, 0)
def hexc(h, a=255): h = h.lstrip('#'); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (a,)

# ------------------------------------------------------------------ pixel helpers
def outline(layer, ink):
    w, h = layer.size; src = layer.load(); out = layer.copy(); px = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3]: continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] == 255: px[x, y] = ink; break
    return out

def clean_orphans(layer):
    """Remove single pixels sticking out of a shape (staircase noise after rasterising rotated polygons)."""
    w, h = layer.size; px = layer.load(); kill = []
    for y in range(h):
        for x in range(w):
            if not px[x, y][3]: continue
            n = sum(1 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) if 0 <= x + dx < w and 0 <= y + dy < h and px[x + dx, y + dy][3])
            if n <= 1: kill.append((x, y))
    for p in kill: px[p] = CLEAR
    return layer

def rot(p, c, a):
    s, co = math.sin(a), math.cos(a); x, y = p[0] - c[0], p[1] - c[1]
    return (c[0] + x * co - y * s, c[1] + x * s + y * co)

def poly(d, pts, fill): d.polygon([(round(x), round(y)) for x, y in pts], fill=fill)

# ------------------------------------------------------------------ parts library
def part_diamond_body(sp, pose, P):
    """Kite sail: four paper planes lit from the upper left, bamboo cross, knot on top."""
    L = Image.new('RGBA', (sp['grid'], sp['grid']), CLEAR); d = ImageDraw.Draw(L)
    b = sp['body']; c = pose['center']; a = math.radians(pose['tilt'])
    sq = pose.get('squash', 0)
    top, bot = (0, -b['up'] * (1 - sq)), (0, b['down'] * (1 - sq * .5))
    lef, rig = (-b['half'] * (1 + sq * .4), 0), (b['half'] * (1 + sq * .4), 0)
    T = lambda p: rot((c[0] + p[0], c[1] + p[1]), c, a)
    o = (0, 0)
    poly(d, [T(top), T(lef), T(o)], P['body_light']); poly(d, [T(top), T(rig), T(o)], P['body_mid'])
    poly(d, [T(lef), T(bot), T(o)], P['body_mid']); poly(d, [T(rig), T(bot), T(o)], P['body_dark'])
    # paper fold highlight along the upper-left edge
    p0, p1 = T((-1, -b['up'] * (1 - sq) + 3)), T((lef[0] + 3, -1))
    d.line([(round(p0[0]), round(p0[1])), (round(p1[0]), round(p1[1]))], fill=P['body_shine'])
    # bamboo spars, faint
    for p0, p1 in ((top, bot), (lef, rig)):
        q0, q1 = T((p0[0] * .86, p0[1] * .86)), T((p1[0] * .86, p1[1] * .86)); d.line([(round(q0[0]), round(q0[1])), (round(q1[0]), round(q1[1]))], fill=P['spar'])
    L = clean_orphans(L)
    # knot on top
    k = T((0, -b['up'] * (1 - sq) - 2)); d = ImageDraw.Draw(L); d.rectangle((round(k[0]) - 1, round(k[1]) - 1, round(k[0]) + 1, round(k[1]) + 1), fill=P['knot'])
    return L, {'bottom': T(bot), 'left': T(lef), 'right': T(rig), 'face': T((0, b.get('face_y', 0)))}

def part_wing(sp, pose, P, side, anchors):
    """Bird wing as ONE silhouette: an arm that goes out and slightly up from the shoulder (coverts),
    with long feathers hanging down and outward from it, ending in separate pointed 'fingers'.
    Tone bands: light coverts, orange feathers, dark tips; 1px darker separations between feathers."""
    g = sp['grid']; w = sp['wing']; s = -1 if side == 'left' else 1; L_ = w['length']
    base = anchors['left' if side == 'left' else 'right']
    sh = (base[0] - s * w['inset'], base[1] - w['raise'])
    ang = math.radians(pose['wing'][0 if side == 'left' else 1]) + math.radians(pose['tilt']) * s
    def T(p):  # local: +x outward, +y down; positive flap rotates the wing up around the shoulder
        x, y = p[0] * L_, p[1] * L_; c, si = math.cos(-ang), math.sin(-ang)
        return (sh[0] + s * (x * c - y * si), sh[1] + (x * si + y * c))
    n = w['feathers']; arm_end = (1.0, -w['lift'])
    # feather fingers: roots spread along the arm, tips fan from out-down (outer) to down (inner)
    fingers = []
    for k in range(n):
        u = 1 - k / n                                   # outer first
        root = (u * arm_end[0] * .95, u * arm_end[1] + .05)
        dirx, diry = w.get('fan', .35) * u + .08, .9    # outer feathers point more outward
        ln = w['drop'] * (.7 + .5 * u)
        fingers.append(((root[0] + dirx * ln, root[1] + diry * ln), root))
    shape = [(0, -.08), (.5, -.12 - w['lift'] * .5), arm_end]
    for k, (tip, root) in enumerate(fingers):
        shape.append(tip)
        if k < n - 1:
            nxt = fingers[k + 1][0]
            shape.append(((tip[0] + nxt[0]) / 2 - .02, (tip[1] + nxt[1]) / 2 - w['notch']))
    shape += [(.02, .3)]
    Lyr = Image.new('RGBA', (g, g), CLEAR); d = ImageDraw.Draw(Lyr)
    poly(d, [T(p) for p in shape], P['wing_mid'])
    for k, (tip, root) in enumerate(fingers):     # dark tips on each finger
        a_ = (root[0] + (tip[0] - root[0]) * .62, root[1] + (tip[1] - root[1]) * .62)
        poly(d, [T((a_[0] - .07, a_[1])), T(tip), T((a_[0] + .07, a_[1]))], P['wing_tip'])
    for k in range(n - 1):                         # separations from notch upward
        tip, nxt = fingers[k][0], fingers[k + 1][0]
        m = ((tip[0] + nxt[0]) / 2 - .02, (tip[1] + nxt[1]) / 2 - w['notch'])
        r_ = fingers[k][1]; q0, q1 = T(m), T(((m[0] + r_[0]) / 2, (m[1] + r_[1]) / 2))
        d.line([(round(q0[0]), round(q0[1])), (round(q1[0]), round(q1[1]))], fill=P['wing_dark'])
    cov = [(0, -.08), (.5, -.12 - w['lift'] * .5), arm_end, (.85, -w['lift'] + .18), (.45, .14), (.02, .2)]
    poly(d, [T(p) for p in cov], P['wing_light'])
    return outline(clean_orphans(Lyr), P['ink'])

def part_tail(sp, pose, P, anchors):
    """Rabiola: bow under the sail, two wide ribbons sweeping to one side in a long curve (different lengths),
    tassels aligned with the ribbon end. Reads as fabric in the wind, not as legs."""
    g = sp['grid']; t = sp['tail']; a = anchors['bottom']; ph = pose['tail_phase']; wind = pose.get('wind', 0)
    out = Image.new('RGBA', (g, g), CLEAR)
    for r, (ln, lag, spread) in enumerate(((t['length'], 0, -1), (t['length'] * .75, 1.3, 1))):
        L = Image.new('RGBA', (g, g), CLEAR); d = ImageDraw.Draw(L); pts = []
        for k in range(t['segments'] + 1):
            u = k / t['segments']
            sweep = t['sweep'] + wind * .9                     # how much the ribbon bends sideways
            x = a[0] + spread * 1.5 * u - sweep * ln * u * u + math.sin(ph + lag + u * 3.2) * t['sway'] * u
            y = a[1] + 3 + ln * u * (1 - .55 * min(1, abs(sweep)) * u)
            pts.append((x, y))
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            d.line([(round(x0), round(y0)), (round(x1), round(y1))], fill=P['tail'], width=t['width'])
        for (x0, y0), (x1, y1) in zip(pts[2::3], pts[3::3]):
            d.line([(round(x0), round(y0) + 1), (round(x1), round(y1) + 1)], fill=P['tail_dark'])
        # tassel along the end tangent
        (x0, y0), (x1, y1) = pts[-2], pts[-1]; tl = math.hypot(x1 - x0, y1 - y0) or 1; ux, uy = (x1 - x0) / tl, (y1 - y0) / tl; nx, ny = -uy, ux
        cap = [(x1 + nx * 2, y1 + ny * 2), (x1 - nx * 2, y1 - ny * 2), (x1 - nx * 3 + ux * 5, y1 - ny * 3 + uy * 5), (x1 + nx * 3 + ux * 5, y1 + ny * 3 + uy * 5)]
        poly(d, cap, P['tail'])
        d.line([(round(x1 + nx * 2), round(y1 + ny * 2)), (round(x1 - nx * 2), round(y1 - ny * 2))], fill=P['tail_dark'])
        for f_ in (-1.5, 0, 1.5): d.line([(round(x1 + nx * f_ + ux * 2), round(y1 + ny * f_ + uy * 2)), (round(x1 + nx * f_ * 1.3 + ux * 5), round(y1 + ny * f_ * 1.3 + uy * 5))], fill=P['tail_dark'])
        out.alpha_composite(outline(clean_orphans(L), P['ink']))
    K = Image.new('RGBA', (g, g), CLEAR); d = ImageDraw.Draw(K); kx, ky = round(a[0]), round(a[1]) + 2
    poly(d, [(kx, ky), (kx - 4, ky - 2), (kx - 4, ky + 2)], P['tail']); poly(d, [(kx, ky), (kx + 4, ky - 2), (kx + 4, ky + 2)], P['tail'])
    d.rectangle((kx - 1, ky - 1, kx + 1, ky + 1), fill=P['tail_dark'])
    out.alpha_composite(outline(K, P['ink']))
    return out

def part_face(sp, pose, P, anchors):
    """Rounded eyes (never rotated): white with ink rim and cut corners, brown iris low and inward, pupil,
    2px highlight; brows; beak between and below the eyes."""
    L = Image.new('RGBA', (sp['grid'], sp['grid']), CLEAR); d = ImageDraw.Draw(L); px = L.load()
    f = sp['face']; cx, cy = (round(v) for v in anchors['face']); e = pose.get('expr', 'normal'); look = pose.get('look', 0)
    W_, H_ = f['eye_w'], f['eye_h']
    for s in (-1, 1):
        ex = cx + (f['eye_gap'] // 2 + 1 if s > 0 else -(f['eye_gap'] // 2) - W_); ey = cy - H_ // 2 + f.get('eye_dy', 0)
        if e == 'happy':
            d.line([(ex, ey + 3), (ex + 1, ey + 1), (ex + W_ - 2, ey + 1), (ex + W_ - 1, ey + 3)], fill=P['ink'])
        elif e == 'blink':
            d.line([(ex, ey + H_ // 2 + 1), (ex + W_ - 1, ey + H_ // 2 + 1)], fill=P['ink']); d.point((ex + (0 if s < 0 else W_ - 1), ey + H_ // 2 + 2), fill=P['ink'])
        elif e == 'hurt':
            pts = [(ex, ey + 1), (ex + W_ - 1, ey + 3), (ex, ey + 5)] if s < 0 else [(ex + W_ - 1, ey + 1), (ex, ey + 3), (ex + W_ - 1, ey + 5)]
            d.line(pts, fill=P['ink'])
        else:
            # oval: rim drawn as an ellipse, then sclera, big iris low and toward the beak, pupil, 2x2 highlight
            d.ellipse((ex - 1, ey - 1, ex + W_, ey + H_), fill=P['ink'])
            d.ellipse((ex, ey, ex + W_ - 1, ey + H_ - 1), fill=P['eye_white'])
            ix0 = ex + (1 if s < 0 else 0) + look; ix0 = max(ex, min(ex + 1, ix0))
            d.ellipse((ix0, ey + 1, ix0 + W_ - 2, ey + H_ - 1), fill=P['iris'])
            d.rectangle((ix0 + 1, ey + 3, ix0 + W_ - 3, ey + H_ - 2), fill=P['ink'])
            d.rectangle((ix0 + 1, ey + 2, ix0 + 2, ey + 3), fill=P['eye_white'])
            d.point((ix0 + W_ - 3, ey + H_ - 2), fill=P['iris_light'])
        by = ey - 3
        if e == 'fierce':
            d.line([(ex - 1, by + 1), (ex + W_, by + 2)] if s < 0 else [(ex - 1, by + 2), (ex + W_, by + 1)], fill=P['ink'])
            d.line([(ex + (W_ - 2 if s < 0 else 0), by + 2), (ex + (W_ if s < 0 else -1), by + 3)], fill=P['ink'])
    bx, by_ = cx, cy + H_ // 2 + f['beak_dy']
    poly(d, [(bx - 2, by_), (bx + 2, by_), (bx, by_ + 3)], P['beak']); d.point((bx + 1, by_ + 1), fill=P['beak_dark']); d.point((bx, by_ + 3), fill=P['beak_dark'])
    return L

def fx_layer(sp, pose, P, anchors):
    L = Image.new('RGBA', (sp['grid'], sp['grid']), CLEAR); d = ImageDraw.Draw(L); fx = pose.get('fx'); t = pose.get('fx_t', 0)
    c = anchors['face']
    if fx == 'slash':    # feather slash: an arc of warm light with a feather at the head
        r = 19 + t * 5; a0, a1 = -100 + t * 40, 10 + t * 120
        for k in range(3):
            d.arc((c[0] - r + k, c[1] - r + k + 6, c[0] + r - k, c[1] + r - k + 6), a0, a1, fill=[P['fx_hot'], P['fx_mid'], P['fx_dim']][k])
        hx, hy = c[0] + math.cos(math.radians(a1)) * r, c[1] + 6 + math.sin(math.radians(a1)) * r
        poly(d, [(hx - 3, hy), (hx, hy - 2), (hx + 4, hy + 1), (hx, hy + 2)], P['fx_hot'])
    if fx in ('slash', 'charge'):  # drifting feathers
        for i, (ox, oy) in enumerate(((-20, -14), (18, -18), (22, 8), (-24, 6))):
            if (i + int(t * 4)) % 2: continue
            x, y = c[0] + ox + t * 3 * (1 if ox > 0 else -1), c[1] + oy - t * 4
            d.line([(round(x), round(y)), (round(x) + 2, round(y) - 1)], fill=P['fx_mid'])
    if fx == 'sparkle':
        for i, (ox, oy) in enumerate(((-22, -16), (21, -12), (-18, 10), (24, 14))):
            if (i + pose.get('frame', 0)) % 2 == 0:
                x, y = round(c[0] + ox), round(c[1] + oy)
                d.line([(x - 2, y), (x + 2, y)], fill=P['fx_hot']); d.line([(x, y - 2), (x, y + 2)], fill=P['fx_hot']); d.point((x, y), fill=P['body_shine'])
    if fx == 'hit':
        for ox, oy in ((-12, -15), (-8, -18), (-4, -16)):
            d.line([(round(c[0] + ox), round(c[1] + oy)), (round(c[0] + ox) - 2, round(c[1] + oy) - 3)], fill=P['ink'])
    return L

# ------------------------------------------------------------------ palette: 15 fixed slots (manual: <=15 colours + transparent)
# Every drawing role points to a slot, so variants and shinies are a swap of slot values, never a redraw.
SLOTS = ['ink', 'shine', 'body_light', 'body_mid', 'body_dark', 'accent_light', 'accent_mid', 'accent_dark', 'deep',
         'eye_white', 'iris', 'beak', 'beak_dark', 'fx_hot', 'fx_mid']
ROLES = {'ink': 'ink', 'body_shine': 'shine', 'body_light': 'body_light', 'body_mid': 'body_mid', 'body_dark': 'body_dark',
         'spar': 'body_dark', 'knot': 'deep', 'wing_light': 'accent_light', 'wing_mid': 'accent_mid', 'wing_dark': 'accent_dark',
         'wing_tip': 'deep', 'tail': 'accent_mid', 'tail_dark': 'accent_dark', 'eye_white': 'eye_white', 'iris': 'iris',
         'iris_light': 'accent_mid', 'brow': 'deep', 'beak': 'beak', 'beak_dark': 'beak_dark', 'fx_hot': 'fx_hot', 'fx_mid': 'fx_mid',
         'fx_dim': 'accent_mid', 'fx_edge': 'body_dark'}

def palette(sp, variant=None):
    slots = dict(sp['palette'])
    if variant: slots.update(sp['variants'][variant])
    return {role: hexc(slots[slot]) for role, slot in ROLES.items()}

# ------------------------------------------------------------------ render a pose on a working canvas
def render(sp, pose, variant=None):
    P = palette(sp, variant)
    body, anchors = part_diamond_body(sp, pose, P)
    layers = [part_tail(sp, pose, P, anchors), part_wing(sp, pose, P, 'left', anchors), part_wing(sp, pose, P, 'right', anchors),
              outline(body, P['ink']), part_face(sp, pose, P, anchors)]
    img = Image.new('RGBA', (sp['grid'], sp['grid']), CLEAR)
    for l in layers: img.alpha_composite(l)
    fx = fx_layer(sp, pose, P, anchors)
    if fx.getbbox(): img.alpha_composite(outline(fx, P['fx_edge']) if pose.get('fx') == 'slash' else fx)
    c = pose['center']
    pts = {'head': anchors['face'], 'center': c, 'effect': anchors['face'] if pose.get('fx') != 'slash' else anchors['face'],
           'tail': anchors['bottom'], 'ground': (c[0], sp['ground_y'])}
    return img, {k: (round(v[0]), round(v[1])) for k, v in pts.items()}

# ------------------------------------------------------------------ animation spec (AnimData-like) and poses
# durations are ticks of 1/60 s; rush/hit/return mark gameplay timing inside the clip.
DEFAULT_ANIMS = [
    {'name': 'idle', 'index': 0, 'cell': [64, 64], 'durations': [36, 8, 6, 10], 'loop': True},
    {'name': 'flight', 'index': 1, 'cell': [64, 64], 'durations': [6, 8, 6, 10], 'loop': True},
    {'name': 'skill', 'index': 2, 'cell': [80, 64], 'durations': [14, 2, 4, 16], 'loop': False, 'rushFrame': 0, 'hitFrame': 1, 'returnFrame': 3},
    {'name': 'hurt', 'index': 3, 'cell': [64, 64], 'durations': [3, 12], 'loop': False},
    {'name': 'victory', 'index': 4, 'cell': [64, 64], 'durations': [16, 16], 'loop': True},
]
REQUIRED = {1: ['idle'], 2: ['idle', 'flight', 'skill', 'hurt', 'victory']}

def clips(sp):
    g = sp['grid']; base = sp['cell']; oy = (g - base) / 2
    C = (g / 2, oy + base * sp.get('center_y', .42))
    def at(dx=0, dy=0): return (C[0] + dx, C[1] + dy)
    idle = [dict(center=at(0, b), tilt=0, wing=(w, w), tail_phase=i * 1.57, expr='blink' if i == 2 else 'normal') for i, (b, w) in enumerate(((0, 0), (-1, 8), (-1, 14), (0, 6)))]
    flight = [dict(center=at(-1, b), tilt=16, wing=(w, w - 4), tail_phase=i * 1.57, wind=.55, expr='fierce', look=1) for i, (b, w) in enumerate(((0, -18), (-1, 10), (-2, 32), (-1, 4)))]
    skill = [dict(center=at(-2, 0), tilt=-10, wing=(38, 38), tail_phase=0, expr='fierce', fx='charge', fx_t=0),
             dict(center=at(1, -1), tilt=8, wing=(-22, -22), tail_phase=1.5, wind=.3, expr='fierce', fx='slash', fx_t=0),
             dict(center=at(-1, -1), tilt=12, wing=(-26, -22), tail_phase=3, wind=.5, expr='fierce', fx='slash', fx_t=1),
             dict(center=at(0, 0), tilt=4, wing=(6, 6), tail_phase=4.5, wind=.2, expr='normal', fx='charge', fx_t=.6)]
    hurt = [dict(center=at(-1, 1), tilt=-12, wing=(-10, 20), tail_phase=1, wind=-.4, expr='hurt', squash=.12, fx='hit'),
            dict(center=at(-1, 0), tilt=-6, wing=(4, 10), tail_phase=2.5, wind=-.2, expr='hurt')]
    victory = [dict(center=at(0, 0), tilt=0, wing=(40, 40), tail_phase=0, expr='happy', fx='sparkle', frame=0),
               dict(center=at(0, -1), tilt=0, wing=(30, 30), tail_phase=1.6, expr='happy', fx='sparkle', frame=1)]
    return {'idle': idle, 'flight': flight, 'skill': skill, 'hurt': hurt, 'victory': victory}

def crop_cell(sp, img, pts, cell):
    """Cut the anim's own cell from the working canvas: body centred horizontally, same vertical frame for every anim."""
    g, base = sp['grid'], sp['cell']; fw, fh = cell
    x0, y0 = (g - fw) // 2, (g - base) // 2 + (base - fh)
    return img.crop((x0, y0, x0 + fw, y0 + fh)), {k: (v[0] - x0, v[1] - y0) for k, v in pts.items()}

def build(species_path, out, variant=None):
    sp = json.load(open(species_path)); os.makedirs(out, exist_ok=True)
    sp['grid'] = sp.get('canvas', 96); sp['ground_y'] = (sp['grid'] - sp['cell']) // 2 + sp['cell'] - 2
    anims = sp.get('anims', DEFAULT_ANIMS); poses = clips(sp)
    tag = sp['id'] + (f'-{variant}' if variant else '')
    rows, data = [], {'id': sp['id'], 'name': sp['name'], 'variant': variant, 'shadowSize': sp.get('shadowSize', 1),
                      'sizeClass': sp.get('sizeClass', 'medium'), 'tier': sp.get('tier', 2), 'palette': sp['palette'],
                      'image': f'{tag}.png', 'anims': []}
    y = 0
    for a in anims:
        frames, anchors = [], []
        for pose in poses[a['name']]:
            img, pts = render(sp, pose, variant); im, pts = crop_cell(sp, img, pts, a['cell']); frames.append(im); anchors.append(pts)
        rows.append((a, frames)); entry = {k: v for k, v in a.items()}
        entry.update({'y': y, 'frames': len(frames), 'anchors': anchors}); data['anims'].append(entry); y += a['cell'][1]
    W = max(a['cell'][0] * len(f) for a, f in rows)
    sheet = Image.new('RGBA', (W, y), CLEAR)
    for (a, frames), e in zip(rows, data['anims']):
        for i, im in enumerate(frames): sheet.alpha_composite(im, (i * a['cell'][0], e['y']))
    sheet.save(f'{out}/{tag}.png'); json.dump(data, open(f'{out}/{tag}.json', 'w'), ensure_ascii=False, indent=1)
    # export in the format the game reads today (atlas.json): frames by rect, durations in ms
    atlas = {'frames': {}, 'animations': {}, 'playback': {}, 'meta': {'image': f'creatures/pixel-v1/{tag}.png', 'size': {'w': W, 'h': y}, 'transparent': True, 'pixelArt': True}}
    n = 0
    for e in data['anims']:
        ids = []
        for i in range(e['frames']):
            atlas['frames'][str(n)] = {'frame': {'x': i * e['cell'][0], 'y': e['y'], 'w': e['cell'][0], 'h': e['cell'][1]}, 'pivot': {'x': .5, 'y': .5}}; ids.append(str(n)); n += 1
        atlas['animations'][e['name']] = ids
        atlas['playback'][e['name']] = {'durations': [round(t * 1000 / 60) for t in e['durations']], 'loop': e['loop']}
    json.dump(atlas, open(f'{out}/{tag}-atlas.json', 'w'), indent=1)
    # GIFs with the real timing, x6
    for (a, frames) in rows:
        big = []
        for im in frames:
            b = Image.new('RGBA', (im.width * 6, im.height * 6), (246, 234, 208, 255)); b.alpha_composite(im.resize(b.size, Image.NEAREST)); big.append(b)
        big[0].save(f'{out}/{tag}-{a["name"]}.gif', save_all=True, append_images=big[1:], duration=[round(t * 1000 / 60) for t in a['durations']], loop=0)
    return sp, data, rows

if __name__ == '__main__':
    build(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None); print('ok')
