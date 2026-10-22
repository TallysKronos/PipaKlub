# Soulmonster generator v8: a 3/4 pseudo-3D rig with lit surfaces.
# Parts live in body space (x right, y down, z toward the viewer), are turned by roll/yaw/pitch and projected
# orthographically. Each pixel is shaded from its surface normal against one light (top-left-front) into
# hue-shifted ramps; outlines are selective (dark on the shadow side, a ramp tone on the lit side).
# Data format, anchors, cells and the linter stay those of v7 (soulgen.py / lint.py).
import colorsys, json, math, os, sys
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import procedural as v7

CLEAR = (0, 0, 0, 0)
def hexc(h): h = h.lstrip('#'); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)
def tohex(c): return '#%02x%02x%02x' % c[:3]

# ------------------------------------------------------------------ hue-shifted ramps
def ramp(base, n, dark_shift=-14, light_shift=10, dark_v=.42, light_v=1.22, sat_dark=1.08, sat_light=.72):
    """n tones from shadow to light: shadows drift toward red/purple and get more saturated, lights toward yellow and paler."""
    r, g, b = (v / 255 for v in hexc(base)[:3]); h, s, v = colorsys.rgb_to_hsv(r, g, b); out = []
    for i in range(n):
        t = i / (n - 1) if n > 1 else .5   # 0 shadow .. 1 light
        k = t * 2 - 1
        hh = (h + (dark_shift if k < 0 else light_shift) * abs(k) / 360) % 1
        vv = v * (1 + (light_v - 1) * k) if k > 0 else v * (1 - (1 - dark_v) * -k)
        ss = s * (sat_light if k > 0 else sat_dark) ** abs(k)
        rr, gg, bb = colorsys.hsv_to_rgb(hh, min(1, ss), min(1, vv)); out.append((round(rr * 255), round(gg * 255), round(bb * 255), 255))
    return out

def make_palette(sp):
    c = sp['colors']
    P = {'ink': hexc(c['ink'])}
    P['body'] = ramp(c['body'], 4); P['face'] = ramp(c['face'], 2, dark_v=.86, light_v=1.06)
    P['cap'] = ramp(c['cap'], 2, dark_v=.7, light_v=1.25); P['wing'] = ramp(c['wing'], 3)
    P['beak'] = ramp(c['beak'], 2, dark_v=.72, light_v=1.08)
    slots = [P['ink']] + P['body'] + P['face'] + P['cap'] + P['wing'] + P['beak']
    return P, {('ink' if i == 0 else f's{i}'): tohex(x) for i, x in enumerate(slots)}

# ------------------------------------------------------------------ 3D helpers
L = (-.55, -.68, .48); _n = math.sqrt(sum(v * v for v in L)); L = tuple(v / _n for v in L)
def norm(v): n = math.sqrt(sum(a * a for a in v)) or 1; return tuple(a / n for a in v)
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])

class Cam:
    def __init__(self, c, roll, yaw, pitch):
        self.c, self.r, self.y, self.p = c, math.radians(roll), math.radians(yaw), math.radians(pitch)
    def rot(self, v):
        x, y, z = v; cr, sr = math.cos(self.r), math.sin(self.r)
        x, y = x * cr - y * sr, x * sr + y * cr
        cy, sy = math.cos(self.y), math.sin(self.y); x, z = x * cy + z * sy, -x * sy + z * cy
        cp, sp_ = math.cos(self.p), math.sin(self.p); y, z = y * cp - z * sp_, y * sp_ + z * cp
        return (x, y, z)
    def proj(self, v): x, y, z = self.rot(v); return (self.c[0] + x, self.c[1] + y, z)
    def light(self, n):
        n = norm(self.rot(n));
        if n[2] < 0: n = (-n[0], -n[1], -n[2])          # two-sided paper
        return max(0, sum(a * b for a, b in zip(n, L)))

def tone(rmp, lam, bias=0):
    """lambert 0..1 -> ramp index, with a little ambient so nothing goes pure black."""
    v = .34 + .78 * lam + bias; return rmp[max(0, min(len(rmp) - 1, int(v * len(rmp))))]

def sel_outline(layer, ink, lit):
    """Selective outline: outline pixels above/left of the shape (lit side) take the part's dark tone, the rest ink."""
    w, h = layer.size; src = layer.load(); out = layer.copy(); px = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3]: continue
            hit = None
            for dx, dy in ((1, 0), (0, 1), (-1, 0), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3]: hit = (dx, dy); break
            if hit: px[x, y] = lit if hit in ((1, 0), (0, 1)) else ink
    return out

def fill_poly(img, pts, fn):
    """Rasterise a projected polygon; fn(x, y) gives each pixel's colour (or None)."""
    mask = Image.new('L', img.size, 0); ImageDraw.Draw(mask).polygon([(round(p[0]), round(p[1])) for p in pts], fill=255)
    bb = mask.getbbox()
    if not bb: return
    mp, px = mask.load(), img.load()
    for y in range(bb[1], bb[3]):
        for x in range(bb[0], bb[2]):
            if mp[x, y]:
                c = fn(x, y)
                if c: px[x, y] = c

# ------------------------------------------------------------------ parts
def body_layer(sp, cam, P, pose):
    """Kite sail as a shallow pyramid over the cross spars (four lit panels), with the carcará's dark cap,
    cream face mask, small eyes, hooked beak, bamboo spars and a stitched patch."""
    g = sp['grid']; b = sp['body']; sq = pose.get('squash', 0)
    up, dn, hw = b['up'] * (1 - sq), b['down'] * (1 - sq * .5), b['half'] * (1 + sq * .35)
    img = Image.new('RGBA', (g, g), CLEAR)
    # inverse of the planar projection (z = 0): screen offset -> body (x, y)
    cr, sr = math.cos(cam.r), math.sin(cam.r); cy, sy = math.cos(cam.y), math.sin(cam.y); cp, spp = math.cos(cam.p), math.sin(cam.p)
    a11, a12, a21, a22 = cy, 0, -(-sy) * spp, cp   # y'' = y*cp - z'*sp with z' = -x*sy
    a21 = sy * spp
    det = a11 * a22 - a12 * a21
    def local(X, Y):
        dx, dy = X - cam.c[0], Y - cam.c[1]
        xr = (a22 * dx - a12 * dy) / det; yr = (-a21 * dx + a11 * dy) / det
        return xr * cr + yr * sr, -xr * sr + yr * cr
    corners = [cam.proj(p) for p in ((0, -up, 0), (hw, 0, 0), (0, dn, 0), (-hw, 0, 0))]
    cap_line = lambda x: -up * .5 + abs(x) * .3       # V brow: dips to the centre, stern look
    k = b.get('pyramid', .45)
    def col(X, Y):
        x, y = local(X + .5, Y + .5)
        if abs(x) / hw + (abs(y) / (up if y < 0 else dn)) > 1.02: return None
        sx, sy_ = (1 if x >= 0 else -1), (1 if y >= 0 else -1)
        lam = cam.light((sx * k, sy_ * k, 1))
        if y < cap_line(x): return tone(P['cap'], lam, .05)
        if abs(x) < hw * .7 and (x / (hw * .7)) ** 2 + ((y + up * .2) / (up * .42)) ** 2 < 1: return tone(P['face'], lam, .2)
        return tone(P['body'], lam)
    fill_poly(img, corners, col)
    px = img.load(); d = ImageDraw.Draw(img)
    rim = []
    for y in range(1, g - 1):
        for x in range(1, g - 1):
            if px[x, y][3] and (not px[x - 1, y][3] or not px[x, y - 1][3]) and px[x, y][:3] in [c[:3] for c in P['body'][1:]]: rim.append((x, y))
    for p in rim: px[p] = P['body'][3]
    # bamboo spars, shaded: lit segments lighter
    for p0, p1 in (((0, -up * .9, .6), (0, dn * .92, .6)), ((-hw * .9, 0, .6), (hw * .9, 0, .6))):
        q0, q1 = cam.proj(p0), cam.proj(p1); n = int(max(abs(q1[0] - q0[0]), abs(q1[1] - q0[1]))) + 1
        for i in range(n):
            t = i / max(1, n - 1); x, y = round(q0[0] + (q1[0] - q0[0]) * t), round(q0[1] + (q1[1] - q0[1]) * t)
            if 0 <= x < g and 0 <= y < g and px[x, y][3] and not (P['face'][0][:3] == px[x, y][:3] or P['face'][1][:3] == px[x, y][:3]):
                px[x, y] = P['beak'][0] if i % 6 == 0 else P['body'][0]
    # stitched patch (remendo) on the lower-far panel
    pc = cam.proj((hw * .3, dn * .45, 0)); x0, y0 = round(pc[0]) - 2, round(pc[1]) - 1
    for yy in range(y0, y0 + 4):
        for xx in range(x0, x0 + 5):
            if 0 <= xx < g and 0 <= yy < g and px[xx, yy][3]:
                edge = yy in (y0, y0 + 3) or xx in (x0, x0 + 4)
                px[xx, yy] = (P['body'][0] if (xx + yy) % 2 else P['body'][1]) if edge else P['body'][3]
    # knot on top
    kt = cam.proj((0, -up - 1.5, .5)); d.rectangle((round(kt[0]) - 1, round(kt[1]) - 1, round(kt[0]) + 1, round(kt[1]) + 1), fill=P['cap'][0]); px[round(kt[0]) - 1, round(kt[1]) - 1] = P['cap'][1]
    # eyes: small, inside the face mask, just under the cap edge; far eye narrower
    e = pose.get('expr', 'normal')
    for s in (-1, 1):
        ex, ey = s * hw * .3, cap_line(s * hw * .3) + 2.4
        q = cam.proj((ex, ey, .8)); X, Y = round(q[0]), round(q[1]); far = (cam.rot((s, 0, 0))[2] < 0)
        if e in ('happy',): px[X - 1, Y] = px[X, Y - 1] = px[X + 1, Y] = P['ink']
        elif e in ('blink', 'hurt'): px[X - 1, Y] = px[X, Y] = P['ink']; px[X + (0 if far else 1), Y] = P['ink']
        else:
            px[X, Y] = px[X, Y + 1] = P['ink']
            if not far: px[X + 1, Y] = px[X + 1, Y + 1] = P['ink']; px[X, Y] = P['face'][1]
            if e == 'fierce': px[X - 1 if s < 0 else X, Y - 1] = P['ink']
    # hooked beak, protruding toward the facing side
    bq = cam.proj((0, up * .02, 3.0)); bx, by = round(bq[0]), round(bq[1]); face = -1 if cam.rot((1, 0, 0))[2] > 0 else 1
    for dx, dy, c in ((0, 0, 'l'), (1, 0, 'l'), (-1, 0, 'l'), (0, 1, 'l'), (face, 1, 'd'), (face, 2, 'd'), (-face, 1, 'l')):
        if 0 <= bx + dx < g and 0 <= by + dy < g: px[bx + dx, by + dy] = P['beak'][1] if c == 'l' else P['beak'][0]
    return sel_outline(img, P['ink'], P['body'][0]), {'face': cam.proj((0, cap_line(0) + 2, 0))[:2], 'bottom': cam.proj((0, dn, 0))[:2],
                                                       'left': cam.proj((-hw, 0, 0))[:2], 'right': cam.proj((hw, 0, 0))[:2]}

def wing_layer(sp, cam, P, pose, side):
    """Three feather rows in a wing plane hinged at the shoulder: coverts (light, scalloped), secondaries,
    primaries with dark tips. Each feather is lit by the wing plane; feathers are separated by the darkest
    wing tone, the silhouette gets a selective outline."""
    g = sp['grid']; w = sp['wing']; b = sp['body']; s = 1 if side == 'right' else -1
    flap = math.radians(pose['wing'][1 if side == 'right' else 0])
    sh = (s * (b['half'] - 2.5), -b['up'] * .12, 0)
    A = (s * math.cos(flap), -math.sin(flap), s * w.get('sweep', .25))           # arm direction
    B = (s * .18, 1, -.2)                                                         # down the feathers
    n = norm(cross(A, B)); lam = cam.light(n)
    def pt(u, v): return cam.proj((sh[0] + A[0] * u + B[0] * v, sh[1] + A[1] * u + B[1] * v, sh[2] + A[2] * u + B[2] * v))
    img = Image.new('RGBA', (g, g), CLEAR); Ln = w['length']
    def feather(root_u, root_v, du, dv, ln, wd, tone_fn):
        tip = (root_u + du * ln, root_v + dv * ln); nu, nv = -dv, du
        poly = [(root_u + nu * wd * .5, root_v + nv * wd * .5), (root_u + du * ln * .55 + nu * wd, root_v + dv * ln * .55 + nv * wd), tip,
                (root_u + du * ln * .55 - nu * wd, root_v + dv * ln * .55 - nv * wd), (root_u - nu * wd * .5, root_v - nv * wd * .5)]
        F = Image.new('RGBA', (g, g), CLEAR); proj = [pt(*p) for p in poly]
        r0, t0 = pt(root_u, root_v), pt(*tip); L2 = (t0[0] - r0[0]) ** 2 + (t0[1] - r0[1]) ** 2 or 1
        def c(X, Y):
            t = ((X - r0[0]) * (t0[0] - r0[0]) + (Y - r0[1]) * (t0[1] - r0[1])) / L2   # 0 root .. 1 tip
            return tone_fn(t)
        fill_poly(F, proj, c)
        # separation: feather edge in the darkest wing tone (inner lines, not ink)
        sep = sel_outline(F, P['wing'][0], P['wing'][0]); img.alpha_composite(sep)
    # primaries: outer, long, fanning out-down, dark tips
    for i in range(w['primaries']):
        u = 1 - i * .13; ang = math.radians(25 + i * 13)
        feather(u * Ln * .9, 1, math.cos(ang), math.sin(ang), Ln * (.9 - i * .07), 3.0,
                lambda t: P['cap'][0] if t > .82 else (P['cap'][1] if t > .7 else (P['wing'][2] if t < .18 else tone(P['wing'], lam, .15))))
    # secondaries: inner, pointing down
    S = Image.new('RGBA', (g, g), CLEAR)
    fill_poly(S, [pt(0, 0), pt(Ln * .62, 0), pt(Ln * .58, Ln * .42), pt(Ln * .38, Ln * .52), pt(Ln * .18, Ln * .44), pt(0, Ln * .3)], lambda X, Y: tone(P['wing'], lam))
    img.alpha_composite(sel_outline(S, P['wing'][0], P['wing'][0]))
    # coverts: scalloped band along the arm
    cov = [(0, -1)] + [(u * Ln, -1.5 + (.3 if i % 2 else 0)) for i, u in enumerate((.25, .5, .75, .95))] + [(Ln * .95, 2.5)]
    for i, u in enumerate((.85, .62, .4, .18)): cov += [(u * Ln + 2, 4.5 if i % 2 == 0 else 3.5), (u * Ln, 3.4)]
    cov += [(0, 3.5)]
    C = Image.new('RGBA', (g, g), CLEAR); fill_poly(C, [pt(*p) for p in cov], lambda X, Y: tone(P['wing'], lam, .35))
    img.alpha_composite(sel_outline(C, P['wing'][0], P['wing'][0]))
    hp = img.load()
    for i in range(40):
        q = pt(Ln * .95 * i / 39, -1.2); X, Y = round(q[0]), round(q[1])
        if 0 <= X < g and 0 <= Y < g and hp[X, Y][3]: hp[X, Y] = P['wing'][2]
    # silhouette outline over the whole wing
    sil = Image.new('RGBA', (g, g), CLEAR); sil.alpha_composite(img)
    return sel_outline(sil, P['ink'], P['wing'][0])

def tail_layer(sp, cam, P, pose, anchors):
    """Rabiola: two ribbons trailing back and down in 3D, shaded by their twist; fringed tassels; bow knot."""
    g = sp['grid']; t = sp['tail']; ph = pose['tail_phase']; wind = pose.get('wind', 0); dn = sp['body']['down']
    out = Image.new('RGBA', (g, g), CLEAR)
    for r, (ln, lag, side) in enumerate(((t['length'], 0, -1), (t['length'] * .75, 1.4, 1))):
        Ly = Image.new('RGBA', (g, g), CLEAR); px = Ly.load(); prev = None; pts = []
        for k in range(t['segments'] + 1):
            u = k / t['segments']
            p = (side * 1.5 * u + math.sin(ph + lag + u * 3.4) * t['sway'] * u - wind * ln * u * .7 + t.get('drift', 6) * u * u, dn + 2 + ln * u * (1 - .45 * abs(wind)), -ln * u * (.55 + .4 * abs(wind)))
            pts.append(cam.proj(p))
        for k in range(len(pts) - 1):
            (x0, y0, _), (x1, y1, _) = pts[k], pts[k + 1]; tw = math.cos(ph + lag + k * .9)
            c = P['wing'][2] if tw > .45 else P['wing'][1] if tw > -.3 else P['wing'][0]
            steps = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
            for i in range(steps + 1):
                x, y = x0 + (x1 - x0) * i / steps, y0 + (y1 - y0) * i / steps
                for dx in range(-1, 2 if tw > -.3 else 1):
                    X, Y = round(x) + dx, round(y)
                    if 0 <= X < g and 0 <= Y < g: px[X, Y] = c
        ex, ey, _ = pts[-1]; ex, ey = round(ex), round(ey)
        for dy in range(0, 4):
            for dx in range(-1 - dy // 3, 2 + dy // 3):
                if 0 <= ex + dx < g and 0 <= ey + dy < g: px[ex + dx, ey + dy] = P['cap'][0] if dy == 0 else (P['wing'][0] if dx == 0 and dy > 1 else P['wing'][2] if dx < 0 else P['wing'][1])
        out.alpha_composite(sel_outline(Ly, P['ink'], P['wing'][0]))
    K = Image.new('RGBA', (g, g), CLEAR); d = ImageDraw.Draw(K); kq = cam.proj((0, dn + 1.5, 0)); kx, ky = round(kq[0]), round(kq[1])
    d.polygon([(kx, ky), (kx - 3, ky - 1), (kx - 3, ky + 1)], fill=P['wing'][2]); d.polygon([(kx, ky), (kx + 3, ky - 1), (kx + 3, ky + 1)], fill=P['wing'][1])
    d.point((kx, ky), fill=P['cap'][0])
    out.alpha_composite(sel_outline(K, P['ink'], P['wing'][0]))
    return out

def fx_layer(sp, pose, P, anchors):
    """Same effects as v7, in the new ramps (feathers and sparks of wing and beak tones)."""
    PP = {'fx_hot': P['face'][1], 'fx_mid': P['beak'][1], 'fx_dim': P['wing'][1], 'ink': P['ink'], 'body_shine': P['face'][1]}
    return v7.fx_layer(sp, pose, PP, anchors), P['body'][0]

def render(sp, pose, variant=None):
    P, _ = make_palette(sp if not variant else {**sp, 'colors': {**sp['colors'], **sp['variants'][variant]}})
    yaw = pose.get('yaw', sp.get('yaw', -32)); pitch = pose.get('pitch', sp.get('pitch', 14))
    cam = Cam(pose['center'], pose['tilt'], yaw, pitch)
    body, anchors = body_layer(sp, cam, P, pose)
    near = 'right' if cam.rot((1, 0, 0))[2] > 0 else 'left'; far = 'left' if near == 'right' else 'right'
    img = Image.new('RGBA', (sp['grid'], sp['grid']), CLEAR)
    for layer in (tail_layer(sp, cam, P, pose, anchors), wing_layer(sp, cam, P, pose, far), body, wing_layer(sp, cam, P, pose, near)):
        img.alpha_composite(layer)
    fx, edge = fx_layer(sp, pose, P, anchors)
    if fx.getbbox(): img.alpha_composite(v7.outline(fx, edge) if pose.get('fx') == 'slash' else fx)
    c = pose['center']
    pts = {'head': anchors['face'], 'center': c, 'effect': anchors['face'], 'tail': anchors['bottom'], 'ground': (c[0], sp['ground_y'])}
    return img, {k: (round(v[0]), round(v[1])) for k, v in pts.items()}

def build(species_path, out, variant=None):
    sp = json.load(open(species_path)); _, slots = make_palette(sp if not variant else {**sp, 'colors': {**sp['colors'], **sp['variants'][variant]}})
    base_slots = make_palette(sp)[1]
    tmp = dict(sp); tmp['palette'] = base_slots if variant is None else base_slots
    path = os.path.join(out, f'.{sp["id"]}-v8.json'); os.makedirs(out, exist_ok=True); json.dump(tmp, open(path, 'w'))
    v7.render = lambda spx, pose, var=None: render(spx, {**pose}, variant)
    v7_clips = v7.clips
    def clips(spx):
        cl = v7_clips(spx)
        for name, poses in cl.items():
            for p in poses: p.update(sp.get('pose_extra', {}).get(name, {}))
        return cl
    v7.clips = clips
    sp2, data, rows = v7.build(path, out, variant)
    if variant:  # record the variant's real slots for the linter's palette check
        data['palette'] = slots; json.dump(data, open(f'{out}/{sp["id"]}-{variant}.json', 'w'), ensure_ascii=False, indent=1)
    return sp2, data, rows

if __name__ == '__main__':
    build(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None); print('ok')
