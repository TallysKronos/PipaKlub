#!/usr/bin/env python3
"""Trailer mangá de Soulmonsters · Elo das Ruínas.

Monta o vídeo quadro a quadro (PIL + numpy) e manda direto para o ffmpeg. Fontes:
- gameplay gravado no Godot por tools/trailer_capture.gd (pasta --clips, um .mp4 por plano);
- cenas do próprio jogo (godot/assets/campaign/cinematics);
- retratos mangá e a tela de título do jogo;
- trilha "Vento · aventura" (godot/assets/audio/music/opening-theme-v1) e efeitos do jogo.

    python3 tools/trailer/montar_trailer.py --clips <pasta> --out trailer.mp4 [--preview 4]

Sem spoilers grandes (decisão do dono, 08/11): nada de Eremor, origem do Tyler ou desfecho
da final.
"""
import argparse
import json
import math
import os
import random
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps, ImageChops, ImageEnhance

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
G = os.path.join(ROOT, "godot")
W, H, FPS = 1920, 1080, 30
DUR = 56.0
FONT_DIR = os.path.join(G, "assets/campaign/ui-modern/fonts")
BANGERS = os.path.join(FONT_DIR, "Bangers-Regular.ttf")
BARLOW = os.path.join(FONT_DIR, "BarlowCondensed-Bold.ttf")
PAPER = (244, 238, 224)
INK = (18, 18, 22)
RED = (214, 40, 46)
MUSIC = os.path.join(G, "assets/audio/music/opening-theme-v1/vento-aventura.ogg")
MUSIC_IN = 4.0          # trailer time where the music enters
MUSIC_HIT = 81.26       # final hit of the track
REVEAL = 50.0           # trailer time of the title reveal (= MUSIC_HIT)
MUSIC_OFFSET = MUSIC_HIT - (REVEAL - MUSIC_IN)

# ---------------------------------------------------------------- helpers

def ease_out(x):
    x = min(max(x, 0.0), 1.0)
    return 1 - (1 - x) ** 3

def ease_in_out(x):
    x = min(max(x, 0.0), 1.0)
    return 3 * x * x - 2 * x * x * x

def back_out(x, s=1.9):
    x = min(max(x, 0.0), 1.0) - 1
    return x * x * ((s + 1) * x + s) + 1

_fonts = {}
def font(path, size):
    key = (path, size)
    if key not in _fonts:
        _fonts[key] = ImageFont.truetype(path, size)
    return _fonts[key]

def rgba(im):
    return im if im.mode == "RGBA" else im.convert("RGBA")

def cover(im, w, h, zoom=1.0, cx=0.5, cy=0.5):
    """Scale to cover w×h (times zoom) centred on (cx, cy) of the source."""
    sw, sh = im.size
    s = max(w / sw, h / sh) * zoom
    nw, nh = max(1, int(sw * s)), max(1, int(sh * s))
    big = im.resize((nw, nh), Image.LANCZOS if s < 1 else Image.BICUBIC)
    x = int(min(max(cx * nw - w / 2, 0), nw - w))
    y = int(min(max(cy * nh - h / 2, 0), nh - h))
    return big.crop((x, y, x + w, y + h))

# ---------------------------------------------------------------- textures

rng = np.random.default_rng(7)
_yy, _xx = np.mgrid[0:H, 0:W].astype(np.float32)

def _halftone_screen(period=9.0, angle=math.radians(45), h=H, w=W):
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    c, s = math.cos(angle), math.sin(angle)
    u = (xx * c + yy * s) / period
    v = (-xx * s + yy * c) / period
    fu, fv = u - np.floor(u) - 0.5, v - np.floor(v) - 0.5
    d = np.sqrt(fu * fu + fv * fv) / 0.7071
    return np.clip(d, 0, 1)

SCREEN = _halftone_screen()
_screens = {}
def _screen_for(h, w):
    if (h, w) not in _screens:
        _screens[(h, w)] = _halftone_screen(h=h, w=w)
    return _screens[(h, w)]
PAPER_NOISE = (rng.normal(0, 1, (H // 4, W // 4)).astype(np.float32))
PAPER_NOISE = np.array(Image.fromarray(((PAPER_NOISE * 18) + 128).clip(0, 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)).astype(np.float32) - 128

def paper_bg(tint=PAPER):
    base = np.empty((H, W, 3), np.float32)
    base[:] = tint
    base += PAPER_NOISE[..., None] * 0.35
    return Image.fromarray(base.clip(0, 255).astype(np.uint8))

PAPER_IMG = paper_bg()
BLACK_IMG = Image.new("RGB", (W, H), INK)

def manga(im, accent=None, halftone=0.55, contrast=1.35):
    """Black-and-white manga treatment with halftone. accent: list of (hue_lo, hue_hi)
    in 0–360 whose saturated pixels keep their colour (selective colour)."""
    w, h = im.size
    rgb = np.asarray(im.convert("RGB"), np.float32)
    gray = rgb @ np.array([0.299, 0.587, 0.114], np.float32)
    gray = ((gray - 128) * contrast + 128 + 8).clip(0, 255)
    screen = SCREEN[:h, :w] if (h <= H and w <= W) else _screen_for(h, w)
    ink = np.where(gray / 255.0 > screen, 255.0, 0.0)
    mono = gray * (1 - halftone) + ink * halftone
    paper = np.array(PAPER, np.float32)
    inkc = np.array(INK, np.float32)
    out = inkc + (paper - inkc) * (mono[..., None] / 255.0)
    if accent:
        hsv = np.asarray(im.convert("RGB").convert("HSV"), np.float32)
        hue = hsv[..., 0] * 360 / 255
        sat = hsv[..., 1] / 255
        val = hsv[..., 2] / 255
        mask = np.zeros(hue.shape, np.float32)
        for lo, hi in accent:
            mask = np.maximum(mask, ((hue >= lo) & (hue <= hi)).astype(np.float32))
        mask *= np.clip((sat - 0.35) * 3, 0, 1) * np.clip((val - 0.2) * 3, 0, 1)
        mask = np.asarray(Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.5)), np.float32)[..., None] / 255
        boosted = np.asarray(ImageEnhance.Color(im.convert("RGB")).enhance(1.35), np.float32)
        out = out * (1 - mask) + boosted * mask
    return Image.fromarray(out.clip(0, 255).astype(np.uint8))

def grade(im, sat=1.12, con=1.06):
    im = ImageEnhance.Color(im).enhance(sat)
    return ImageEnhance.Contrast(im).enhance(con)

def impact(im):
    """Impact frame: inverted, crushed to ink, with radial speed lines."""
    g = ImageOps.grayscale(im)
    g = ImageOps.autocontrast(g, cutoff=4)
    g = g.point(lambda p: 255 if p > 120 else 0)
    inv = ImageOps.invert(g).convert("RGB")
    return inv

_speed_cache = {}
def speed_lines(cx=W / 2, cy=H / 2, count=170, inner=260, seed=1, color=INK, alpha=255, width_range=(2, 9)):
    key = (int(cx), int(cy), count, inner, seed, color, alpha)
    if key in _speed_cache:
        return _speed_cache[key]
    r = random.Random(seed)
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    far = math.hypot(W, H)
    for _ in range(count):
        a = r.uniform(0, math.tau)
        w = r.uniform(*width_range) / 360.0
        r0 = inner * r.uniform(0.9, 1.7)
        p0 = (cx + math.cos(a) * r0, cy + math.sin(a) * r0)
        p1 = (cx + math.cos(a - w) * far, cy + math.sin(a - w) * far)
        p2 = (cx + math.cos(a + w) * far, cy + math.sin(a + w) * far)
        d.polygon([p0, p1, p2], fill=color + (alpha,))
    _speed_cache[key] = layer
    return layer

def ink_mask(progress, seed=3, origin=(W / 2, H / 2)):
    """Organic ink-splash reveal mask (L), growing from origin with progress 0..1."""
    r = random.Random(seed)
    m = Image.new("L", (W // 4, H // 4), 0)
    d = ImageDraw.Draw(m)
    ox, oy = origin[0] / 4, origin[1] / 4
    reach = ease_out(progress) * 700 / 4 * 1.25
    for i in range(60):
        a = r.uniform(0, math.tau)
        dist = r.uniform(0, 1) ** 0.7 * reach
        rad = r.uniform(0.12, 0.34) * reach + 2
        x, y = ox + math.cos(a) * dist, oy + math.sin(a) * dist
        d.ellipse((x - rad, y - rad, x + rad, y + rad), fill=255)
    d.ellipse((ox - reach * .7, oy - reach * .7, ox + reach * .7, oy + reach * .7), fill=255)
    return m.resize((W, H), Image.BICUBIC).filter(ImageFilter.GaussianBlur(2)).point(lambda p: 255 if p > 110 else 0)

# ---------------------------------------------------------------- typography

def text_layer(txt, size, fill=(255, 255, 255), stroke=INK, stroke_w=10, path=BANGERS, shadow=True, tracking=0):
    f = font(path, size)
    bbox = f.getbbox(txt, stroke_width=stroke_w)
    tw = bbox[2] - bbox[0] + tracking * max(0, len(txt) - 1) + 40
    th = bbox[3] - bbox[1] + 40
    layer = Image.new("RGBA", (tw + 24, th + 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x0, y0 = 20 - bbox[0], 20 - bbox[1]
    if shadow:
        if tracking:
            x = x0
            for ch in txt:
                d.text((x + 10, y0 + 10), ch, font=f, fill=INK + (255,), stroke_width=stroke_w, stroke_fill=INK)
                x += f.getlength(ch) + tracking
        else:
            d.text((x0 + 10, y0 + 10), txt, font=f, fill=INK + (255,), stroke_width=stroke_w, stroke_fill=INK)
    if tracking:
        x = x0
        for ch in txt:
            d.text((x, y0), ch, font=f, fill=fill, stroke_width=stroke_w, stroke_fill=stroke)
            x += f.getlength(ch) + tracking
    else:
        d.text((x0, y0), txt, font=f, fill=fill, stroke_width=stroke_w, stroke_fill=stroke)
    return layer

def put(canvas, layer, cx, cy, scale=1.0, angle=0.0, alpha=1.0):
    if scale <= 0.01 or alpha <= 0.01:
        return
    l = layer
    if abs(scale - 1) > 1e-3:
        l = l.resize((max(1, int(l.width * scale)), max(1, int(l.height * scale))), Image.BICUBIC)
    if abs(angle) > 0.05:
        l = l.rotate(angle, resample=Image.BICUBIC, expand=True)
    if alpha < 1:
        a = l.getchannel("A").point(lambda p: int(p * alpha))
        l = l.copy(); l.putalpha(a)
    canvas.paste(l, (int(cx - l.width / 2), int(cy - l.height / 2)), l)

def pop_text(canvas, txt, t, t0, cx, cy, size=170, angle=-4, fill=(255, 255, 255), dur=None, path=BANGERS, stroke_w=10, tracking=0):
    """Text that slams in (scale overshoot) at t0 and optionally leaves after dur."""
    if t < t0:
        return
    k = (t - t0) / 0.22
    scale = back_out(k) if k < 1 else 1.0 + 0.012 * (t - t0 - 0.22)
    alpha = 1.0
    if dur is not None and t > t0 + dur:
        alpha = max(0.0, 1 - (t - t0 - dur) / 0.15)
    put(canvas, text_layer(txt, size, fill=fill, stroke_w=stroke_w, path=path, tracking=tracking), cx, cy, scale, angle, alpha)

def type_text(canvas, txt, t, t0, cps, cx, cy, size, fill=PAPER, path=BARLOW, stroke_w=0, shadow=False):
    if t < t0:
        return
    n = int((t - t0) * cps)
    if n <= 0:
        return
    shown = txt[:n]
    layer = text_layer(shown, size, fill=fill, stroke_w=stroke_w, path=path, shadow=shadow)
    full = text_layer(txt, size, fill=fill, stroke_w=stroke_w, path=path, shadow=shadow)
    canvas.paste(layer, (int(cx - full.width / 2), int(cy - layer.height / 2)), layer)

def caption_box(canvas, txt, t, t0, x, y, size=44, dur=None):
    """Manga narration box: white box, ink border, slides in from the left."""
    if t < t0:
        return
    k = ease_out((t - t0) / 0.3)
    alpha = 1.0 if dur is None or t < t0 + dur else max(0, 1 - (t - t0 - dur) / 0.2)
    f = font(BARLOW, size)
    tw = int(f.getlength(txt)) + 56
    th = size + 34
    box = Image.new("RGBA", (tw + 12, th + 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(box)
    d.rectangle((10, 10, tw + 10, th + 10), fill=INK + (255,))
    d.rectangle((0, 0, tw, th), fill=PAPER + (255,), outline=INK + (255,), width=5)
    d.text((28, 14), txt, font=f, fill=INK)
    put(canvas, box, x + box.width / 2 - (1 - k) * 260, y + box.height / 2, 1.0, 0, alpha * k)

def name_card(canvas, name, subtitle, t, t0, side="right"):
    """Character introduction lettering over a freeze frame."""
    if t < t0:
        return
    k = ease_out((t - t0) / 0.35)
    big = text_layer(name, 230, fill=(255, 255, 255), stroke_w=12)
    small = text_layer(subtitle, 52, fill=PAPER, stroke_w=6, path=BARLOW, shadow=False)
    x = W * (0.70 if side == "right" else 0.30)
    put(canvas, big, x + (1 - k) * (300 if side == "right" else -300), H * 0.42, 1.0, -5, k)
    if t > t0 + 0.25:
        k2 = ease_out((t - t0 - 0.25) / 0.3)
        bar = Image.new("RGBA", (small.width + 40, small.height + 6), RED + (255,))
        bar.paste(small, (20, 3), small)
        put(canvas, bar, x, H * 0.42 + 150, 1.0, -5, k2)

# ---------------------------------------------------------------- sources

class Clip:
    """Sequential frame reader for a video file (ffmpeg pipe)."""
    def __init__(self, path, start=0.0, speed=1.0, size=(W, H)):
        self.path, self.speed, self.size = path, speed, size
        self.proc = subprocess.Popen(["ffmpeg", "-v", "error", "-ss", f"{start:.3f}", "-i", path,
                                      "-vf", f"fps={FPS},scale={size[0]}:{size[1]}:flags=lanczos",
                                      "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)
        self.pos = -1.0
        self.last = None
        self.read_index = -1

    def _read(self):
        n = self.size[0] * self.size[1] * 3
        buf = self.proc.stdout.read(n)
        if len(buf) < n:
            return self.last
        self.read_index += 1
        self.last = Image.frombuffer("RGB", self.size, buf, "raw", "RGB", 0, 1)
        return self.last

    def frame(self, k):
        """Frame for output step k (k-th frame since this clip started)."""
        want = int(k * self.speed)
        while self.read_index < want:
            if self._read() is None:
                break
        return self.last if self.last is not None else Image.new("RGB", self.size, INK)

    def close(self):
        try:
            self.proc.kill()
        except Exception:
            pass

def load_img(rel):
    return Image.open(os.path.join(ROOT, rel)).convert("RGBA")

# ---------------------------------------------------------------- timeline

class Shot:
    def __init__(self, t0, t1, render, clips=None):
        self.t0, self.t1, self.render = t0, t1, render
        self.clips = clips or {}
        self.opened = {}
        self.start_frame = None

    def clip(self, name):
        if name not in self.opened:
            spec = self.clips[name]
            self.opened[name] = Clip(*spec)
            self.opened[name].k0 = self.frame_index
        return self.opened[name]

    def close(self):
        for c in self.opened.values():
            c.close()
        self.opened = {}

def build(args):
    clips_dir = args.clips
    ready = {}
    log = os.path.join(clips_dir, "captura.log")
    if os.path.exists(log):
        for line in open(log):
            parts = line.split()
            if len(parts) >= 2 and parts[1].startswith("ready="):
                try:
                    ready[parts[0]] = int(parts[1][6:]) / FPS
                except ValueError:
                    pass

    def gp(name, after=0.0, speed=1.0):
        """Gameplay clip spec, skipping the title/loading frames before READY."""
        return (os.path.join(clips_dir, name + ".mp4"), ready.get(name, 1.7) + 0.4 + after, speed)

    CIN = os.path.join(G, "assets/campaign/cinematics")
    portraits = {n: load_img(f"godot/assets/campaign/portrait-{n}.png") for n in
                 ["kael-manga-v4", "tyler-manga-v1", "nina", "jamile-manga-v1", "rato-manga-v1", "gollia-manga-v1",
                  "lohan-manga-v1", "kleie-manga-v1", "marisol-manga-v1", "zulmira-manga-v1", "announcer"]}

    shots = []
    def shot(t0, t1, clips=None):
        def deco(fn):
            shots.append(Shot(t0, t1, fn, clips))
            return fn
        return deco

    # ---- 1. HOOK ---------------------------------------------------------
    @shot(0.0, 1.7)
    def hook_line(s, t, c):
        canvas = BLACK_IMG.copy()
        d = ImageDraw.Draw(canvas)
        k = ease_in_out(t / 1.4)
        y = H * 0.52 + math.sin(t * 3) * 6
        d.line((0, y, W * k, y - 80 * k), fill=PAPER, width=3)
        type_text(canvas, "EM KRONASTA,", t, 0.45, 18, W / 2, H * 0.40, 64, fill=PAPER, path=BARLOW)
        return canvas

    @shot(1.7, 3.55, {"duel": (os.path.join(CIN, "pipa-tv-duelo-h3.ogv"), 3.9, 0.35)})
    def hook_eye(s, t, c):
        lt = t - s.t0
        fr = s.clip("duel").frame(c - s.start_frame)
        img = cover(fr, W, H, zoom=1.55 + lt * 0.08, cx=0.68, cy=0.42)
        canvas = manga(img, accent=[(195, 235)], halftone=0.5)
        put(canvas, speed_lines(W * 0.68, H * 0.45, 120, 380, 4, color=INK, alpha=150), W / 2, H / 2)
        pop_text(canvas, "TODA PIPA", t, 1.85, W * 0.30, H * 0.36, 190, angle=-6)
        pop_text(canvas, "TEM ALMA.", t, 2.55, W * 0.34, H * 0.62, 240, angle=-3, fill=(255, 238, 120))
        return canvas

    @shot(3.55, 4.1)
    def hook_cut(s, t, c):
        lt = t - s.t0
        canvas = BLACK_IMG.copy()
        m = ink_mask(lt / 0.55, seed=11)
        canvas.paste(PAPER_IMG, (0, 0), m)
        return canvas

    # ---- 2. ATMOSPHERE ---------------------------------------------------
    @shot(4.1, 7.4, {"tv": (os.path.join(CIN, "pipa-tv-abertura-v4.ogv"), 6.0, 1.15)})
    def world_tv(s, t, c):
        lt = t - s.t0
        canvas = PAPER_IMG.copy()
        fr = s.clip("tv").frame(c - s.start_frame)
        k = ease_out(lt / 0.45)
        pw, ph = 1700, 760
        panel = grade(cover(fr, pw, ph, zoom=1.04 + lt * 0.015))
        panel = ImageOps.expand(panel, border=9, fill=INK)
        put(canvas, rgba(panel), W / 2 + (1 - k) * W, H / 2 - 10, 1.0, -1.2)
        caption_box(canvas, "A FINAL DA LIGA PASSA NA TV.", t, 4.5, 140, 70, 46)
        return canvas

    @shot(7.4, 9.75, {"tv": (os.path.join(CIN, "pipa-tv-abertura-v4.ogv"), 20.6, 1.0)})
    def kael_room(s, t, c):
        lt = t - s.t0
        fr = s.clip("tv").frame(c - s.start_frame)
        if lt < 0.9:
            canvas = grade(cover(fr, W, H, zoom=1.05 + lt * 0.05))
            caption_box(canvas, "NO QUARTO, UM GAROTO ASSISTE.", t, 7.55, 140, 70, 46)
            return canvas
        # freeze frame → character introduction
        if not hasattr(s, "freeze"):
            s.freeze = manga(cover(fr, W, H, zoom=1.1), accent=[(190, 250)], halftone=0.45)
        canvas = s.freeze.copy()
        put(canvas, speed_lines(W * 0.3, H * 0.5, 160, 420, 8, color=INK, alpha=170), W / 2, H / 2)
        k = ease_out((lt - 0.9) / 0.3)
        por = portraits["kael-manga-v4"]
        ph = int(H * 1.05)
        p = por.resize((int(por.width * ph / por.height), ph), Image.LANCZOS)
        canvas.paste(p, (int(W * 0.08 - (1 - k) * 500), int(H * 0.02)), p)
        name_card(canvas, "KAEL", "INVENTOU O PRÓPRIO PARCEIRO", t, 8.45, side="right")
        return canvas

    @shot(9.75, 11.2, {"duel": gp("duelo-mirante", 1.5)})
    def rabbito(s, t, c):
        lt = t - s.t0
        fr = s.clip("duel").frame(c - s.start_frame if lt < 0.35 else int(0.35 * FPS))
        if lt < 0.35:
            return grade(cover(fr, W, H, zoom=1.0 + lt * 0.3, cx=0.3, cy=0.55))
        if not hasattr(s, "freeze"):
            s.freeze = manga(cover(fr, W, H, zoom=2.1, cx=0.26, cy=0.55), accent=[(150, 200), (40, 60)], halftone=0.4)
        canvas = s.freeze.copy()
        put(canvas, speed_lines(W * 0.35, H * 0.5, 150, 360, 9, color=PAPER, alpha=120), W / 2, H / 2)
        name_card(canvas, "RABBITO", "UMA PIPA COM ALMA", t, 10.15, side="right")
        return canvas

    world_clips = {
        "a": gp("bambuzal", 0.2), "b": gp("centro-praca", 0.6), "c": gp("porto-quebra-mar", 0.8),
        "d": gp("palafitas", 0.2), "e": gp("mirante", 0.2), "f": gp("lajes-piscina", 0.6),
    }

    @shot(11.2, 16.55, world_clips)
    def world_panels(s, t, c):
        lt = t - s.t0
        canvas = PAPER_IMG.copy()
        k = c - s.start_frame
        # three beats: 2 panels, 3 panels, full bleed
        if lt < 1.8:
            layout = [("a", (60, 60, 1010, 1020), -1.5), ("b", (930, 40, 1860, 1000), 1.5)]
            txt = ("DOZE BAIRROS.", 11.4)
        elif lt < 3.6:
            layout = [("c", (40, 40, 980, 600), -1.0), ("d", (1000, 60, 1880, 560), 1.2), ("e", (180, 560, 1740, 1040), -0.6)]
            txt = ("DOZE CAMPEÕES.", 13.05)
        else:
            layout = [("f", (0, 0, W, H), 0)]
            txt = ("UMA LIGA.", 14.85)
        for i, (name, box, ang) in enumerate(layout):
            x0, y0, x1, y1 = box
            pw, ph = x1 - x0, y1 - y0
            fr = s.clip(name).frame(k)
            p = grade(cover(fr, pw, ph, zoom=1.08 + 0.02 * math.sin(lt + i)))
            p = rgba(ImageOps.expand(p, border=10 if pw < W else 0, fill=INK))
            seg_t = lt if lt < 1.8 else (lt - 1.8 if lt < 3.6 else lt - 3.6)
            kk = ease_out((seg_t - i * 0.12) / 0.32)
            put(canvas, p, (x0 + x1) / 2 + (1 - kk) * (380 if i % 2 else -380), (y0 + y1) / 2, 1.0, ang, max(0.0, min(1.0, kk * 1.4)))
        pop_text(canvas, txt[0], t, txt[1], W / 2, H * 0.5, 210, angle=-4)
        return canvas

    # champions strip: four slanted portrait panels
    @shot(16.55, 17.95)
    def champions(s, t, c):
        lt = t - s.t0
        canvas = BLACK_IMG.copy()
        names = ["lohan-manga-v1", "kleie-manga-v1", "marisol-manga-v1", "zulmira-manga-v1"]
        colw = W // 4
        for i, n in enumerate(names):
            kk = ease_out((lt - i * 0.08) / 0.3)
            if kk <= 0:
                continue
            por = portraits[n]
            ph = int(H * 1.15)
            p = por.resize((int(por.width * ph / por.height), ph), Image.LANCZOS)
            panel = Image.new("RGBA", (colw + 60, H + 200), PAPER + (255,))
            panel = Image.fromarray(np.asarray(manga(panel.convert("RGB"), halftone=0.2))).convert("RGBA")
            panel.paste(p, (int((colw + 60 - p.width) / 2), 120), p)
            panel = ImageOps.expand(panel.convert("RGB"), border=8, fill=INK).convert("RGBA")
            put(canvas, panel, colw * i + colw / 2, H / 2 + (1 - kk) * (H if i % 2 else -H), 1.0, 6)
        if lt > 0.5:
            pop_text(canvas, "CADA BAIRRO TEM UM CAMPEÃO.", t, s.t0 + 0.5, W / 2, H * 0.84, 110, angle=-3, fill=(255, 238, 120))
        return canvas

    @shot(17.95, 19.3)
    def tyler(s, t, c):
        lt = t - s.t0
        canvas = PAPER_IMG.copy()
        put(canvas, speed_lines(W * 0.3, H * 0.5, 170, 300, 13, color=INK, alpha=200), W / 2, H / 2)
        por = portraits["tyler-manga-v1"]
        ph = int(H * 1.05)
        p = por.resize((int(por.width * ph / por.height), ph), Image.LANCZOS)
        k = ease_out(lt / 0.3)
        canvas.paste(p, (int(W * 0.10 - (1 - k) * 600), int(H * 0.02)), p)
        name_card(canvas, "TYLER", "AMIGO. RIVAL. REMENDA A PRÓPRIA LINHA.", t, s.t0 + 0.2, side="right")
        return canvas

    # ---- 3. ESCALATION ---------------------------------------------------
    duel_clips = {"m": gp("duelo-mirante", 3.0), "c": gp("duelo-centro", 2.0), "s": gp("duelo-serra", 2.0), "n": gp("porto-docas", 0.5)}

    @shot(19.3, 24.6, duel_clips)
    def duels_a(s, t, c):
        lt = t - s.t0
        k = c - s.start_frame
        beats = [0.0, 1.3, 2.65, 4.0]
        idx = max(i for i, b in enumerate(beats) if lt >= b)
        since = lt - beats[idx]
        src = ["m", "c", "s", "m"][idx]
        fr = s.clip(src).frame(k)
        if since < 0.1:          # impact frame on every cut
            canvas = impact(cover(fr, W, H, zoom=1.15))
            put(canvas, speed_lines(W / 2, H / 2, 200, 220, 20 + idx, color=INK, alpha=255), W / 2, H / 2)
            return canvas
        canvas = grade(cover(fr, W, H, zoom=1.04 + since * 0.04))
        if idx == 2:             # split screen with the second duel
            other = grade(cover(s.clip("c").frame(k), W // 2, H, zoom=1.2))
            mask = Image.new("L", (W, H), 0)
            ImageDraw.Draw(mask).polygon([(W * 0.55, 0), (W, 0), (W, H), (W * 0.45, H)], fill=255)
            big = Image.new("RGB", (W, H)); big.paste(other, (W // 2, 0))
            canvas.paste(big, (0, 0), mask)
            ImageDraw.Draw(canvas).line([(W * 0.55, 0), (W * 0.45, H)], fill=INK, width=16)
        texts = {0: ("LEIA O VENTO.", 0.25), 1: ("CRUZE AS LINHAS.", 0.2), 2: ("CORTE!", 0.15), 3: ("SEGURE FIRME.", 0.2)}
        txt, delay = texts[idx]
        pop_text(canvas, txt, lt, beats[idx] + delay, W / 2, H * 0.80, 170 if txt != "CORTE!" else 300, angle=-5)
        return canvas

    @shot(24.6, 28.2)
    def villains(s, t, c):
        lt = t - s.t0
        canvas = BLACK_IMG.copy()
        put(canvas, speed_lines(W * 0.5, H * 0.5, 140, 500, 30, color=(60, 10, 14), alpha=255), W / 2, H / 2)
        por = portraits["rato-manga-v1"]
        ph = int(H * 1.2)
        p = por.resize((int(por.width * ph / por.height), ph), Image.LANCZOS)
        mono = manga(Image.alpha_composite(Image.new("RGBA", p.size, INK + (255,)), p).convert("RGB"), accent=[(100, 160)], halftone=0.3)
        mono = mono.convert("RGBA"); mono.putalpha(p.getchannel("A"))
        k = ease_out(lt / 0.5)
        canvas.paste(mono, (int(W * 0.56 + (1 - k) * 400), int(-H * 0.06)), mono)
        if lt > 1.6:
            g = portraits["gollia-manga-v1"]
            gh = int(H * 0.95)
            gp_ = g.resize((int(g.width * gh / g.height), gh), Image.LANCZOS)
            gm = manga(Image.alpha_composite(Image.new("RGBA", gp_.size, INK + (255,)), gp_).convert("RGB"), halftone=0.35).convert("RGBA")
            gm.putalpha(gp_.getchannel("A"))
            kk = ease_out((lt - 1.6) / 0.4)
            canvas.paste(gm, (int(W * 0.02 - (1 - kk) * 300), int(H * 0.08)), gm)
        pop_text(canvas, "O BANDO DO CEROL", t, s.t0 + 0.2, W * 0.36, H * 0.30, 150, angle=-5, fill=RED)
        pop_text(canvas, "CORTA RABIOLAS...", t, s.t0 + 1.1, W * 0.38, H * 0.55, 120, angle=-3)
        pop_text(canvas, "...E LEVA AS ALMAS.", t, s.t0 + 2.2, W * 0.45, H * 0.80, 150, angle=-4, fill=(255, 238, 120))
        return canvas

    @shot(28.2, 33.0, {"s": gp("serra-cume", 0.2), "p": gp("porto-docas", 1.5), "b": gp("bosque", 0.2), "d": gp("duelo-serra", 4.0)})
    def journey(s, t, c):
        lt = t - s.t0
        k = c - s.start_frame
        canvas = PAPER_IMG.copy()
        order = [("s", "SUBA A SERRA."), ("p", "ATRAVESSE O PORTO."), ("b", "SOLTE OS VENTOS."), ("d", "")]
        idx = min(3, int(lt / 1.2))
        since = lt - idx * 1.2
        name, txt = order[idx]
        fr = s.clip(name).frame(k)
        if since < 0.08:
            return impact(cover(fr, W, H, zoom=1.2))
        ang = [-2.5, 2, -1.5, 0][idx]
        pw, ph = (1760, 940) if idx < 3 else (W, H)
        p = grade(cover(fr, pw, ph, zoom=1.06 + since * 0.05))
        if idx < 3:
            p = rgba(ImageOps.expand(p, border=10, fill=INK))
            put(canvas, p, W / 2, H / 2, 1.0, ang)
        else:
            canvas = p
            put(canvas, speed_lines(W / 2, H / 2, 160, 420, 41, color=PAPER, alpha=110), W / 2, H / 2)
        if txt:
            caption_box(canvas, txt, lt, idx * 1.2 + 0.15, 120, H - 190, 56)
        return canvas

    # ---- 4. PEAK -----------------------------------------------------------
    @shot(33.0, 37.4, {"duel": (os.path.join(CIN, "pipa-tv-duelo-h3.ogv"), 0.0, 1.5)})
    def peak_cinematic(s, t, c):
        lt = t - s.t0
        fr = s.clip("duel").frame(c - s.start_frame)
        canvas = grade(cover(fr, W, H, zoom=1.04 + lt * 0.03), sat=1.2)
        hits = [1.15, 2.45, 3.5]
        for h_ in hits:
            if 0 <= lt - h_ < 0.09:
                canvas = impact(canvas)
                put(canvas, speed_lines(W / 2, H / 2, 220, 200, 50 + int(h_ * 10), color=INK, alpha=255), W / 2, H / 2)
                return canvas
        pop_text(canvas, "VUUSH!", lt, 1.2, W * 0.24, H * 0.25, 230, angle=-12, fill=(255, 238, 120))
        pop_text(canvas, "ZÁS!", lt, 2.5, W * 0.78, H * 0.72, 260, angle=8, fill=(255, 255, 255))
        return canvas

    @shot(37.4, 41.2, {"e": gp("duelo-estadio", 1.0)})
    def jamile(s, t, c):
        lt = t - s.t0
        k = c - s.start_frame
        if lt < 1.5:
            fr = s.clip("e").frame(k)
            canvas = grade(cover(fr, W, H, zoom=1.03 + lt * 0.04))
            pop_text(canvas, "A FINAL DE KRONASTA.", t, s.t0 + 0.2, W / 2, H * 0.82, 150, angle=-4)
            return canvas
        canvas = PAPER_IMG.copy()
        put(canvas, speed_lines(W * 0.32, H * 0.5, 190, 300, 61, color=INK, alpha=220), W / 2, H / 2)
        por = portraits["jamile-manga-v1"]
        ph = int(H * 1.05)
        p = por.resize((int(por.width * ph / por.height), ph), Image.LANCZOS)
        kk = ease_out((lt - 1.5) / 0.3)
        canvas.paste(p, (int(W * 0.08 - (1 - kk) * 600), int(H * 0.02)), p)
        name_card(canvas, "JAMILE", "A CAMPEÃ DA TV", t, s.t0 + 1.7, side="right")
        return canvas

    @shot(41.2, 45.0, {"m": gp("duelo-mirante", 5.0, 1.5), "c": gp("duelo-centro", 5.0, 1.5), "s": gp("duelo-serra", 6.0, 1.5), "e": gp("duelo-estadio", 4.0, 1.5)})
    def grid(s, t, c):
        lt = t - s.t0
        k = c - s.start_frame
        canvas = BLACK_IMG.copy()
        cells = [("m", 0, 0), ("c", 1, 0), ("s", 0, 1), ("e", 1, 1)]
        n = min(4, 1 + int(lt / 0.45))
        for i, (name, cx, cy) in enumerate(cells[:n]):
            x0, y0 = cx * W // 2, cy * H // 2
            fr = s.clip(name).frame(k)
            p = grade(cover(fr, W // 2 - 12, H // 2 - 12, zoom=1.15))
            canvas.paste(p, (x0 + 6, y0 + 6))
        if lt > 2.0:
            put(canvas, speed_lines(W / 2, H / 2, 200, 120, 71, color=PAPER, alpha=int(80 + 120 * min(1, (lt - 2) / 1.5))), W / 2, H / 2)
        if lt > 2.4:
            pop_text(canvas, "QUEM VAI SEGURAR A LINHA?", t, s.t0 + 2.4, W / 2, H / 2, 150, angle=-4, fill=(255, 238, 120))
        return canvas

    @shot(45.0, 49.0)
    def motto(s, t, c):
        lt = t - s.t0
        canvas = BLACK_IMG.copy()
        if not hasattr(s, "bg"):
            por = portraits["kael-manga-v4"]
            ph = int(H * 1.2)
            p = por.resize((int(por.width * ph / por.height), ph), Image.LANCZOS)
            base = Image.new("RGBA", (W, H), INK + (255,))
            base.paste(p, (int(W * 0.62), -60), p)
            m = manga(base.convert("RGB"), accent=[(190, 250)], halftone=0.5)
            s.bg = ImageEnhance.Brightness(m).enhance(0.55)
        canvas = s.bg.copy() if lt > 0.2 else canvas
        type_text(canvas, "QUEM ESTICA A LINHA À FORÇA", t, s.t0 + 0.25, 22, W * 0.40, H * 0.42, 92, fill=PAPER, path=BANGERS)
        if lt > 2.0:
            pop_text(canvas, "NÃO FORMA LAÇO.", t, s.t0 + 2.0, W * 0.40, H * 0.60, 190, angle=-3, fill=(255, 238, 120))
        return canvas

    @shot(49.0, 50.0)
    def breath(s, t, c):
        lt = t - s.t0
        canvas = BLACK_IMG.copy()
        d = ImageDraw.Draw(canvas)
        k = ease_in_out(lt / 0.9)
        y = H * 0.52
        d.line((W * (1 - k), y + 80 * k, W, y), fill=PAPER, width=3)
        return canvas

    # ---- 5. REVEAL ----------------------------------------------------------
    @shot(50.0, DUR, {"title": (os.path.join(clips_dir, "titulo.mp4"), 0.6, 1.0)})
    def reveal(s, t, c):
        lt = t - s.t0
        fr = s.clip("title").frame(c - s.start_frame)
        title = grade(cover(fr, W, H, zoom=1.06 - min(lt, 6) * 0.008, cx=0.38, cy=0.42), sat=1.08)
        # hide the "PRESSIONE START" prompt of the title screen
        d = ImageDraw.Draw(title)
        if lt < 0.12:
            canvas = Image.new("RGB", (W, H), PAPER)
        else:
            canvas = BLACK_IMG.copy()
            canvas.paste(title, (0, 0), ink_mask(min(1, (lt - 0.12) / 0.55), seed=91, origin=(W * 0.38, H * 0.4)))
        if lt > 1.2:
            band = Image.new("RGBA", (W, 150), INK + (int(200 * min(1, (lt - 1.2) / 0.4)),))
            canvas.paste(band, (0, H - 220), band)
            type_text(canvas, "Antes das ruínas, já existia um elo.", t, s.t0 + 1.4, 30, W / 2, H - 145, 64, fill=PAPER, path=BARLOW)
        if lt > DUR - s.t0 - 0.6:
            a = (lt - (DUR - s.t0 - 0.6)) / 0.6
            canvas = Image.blend(canvas, BLACK_IMG, min(1, a))
        return canvas

    return shots

# ---------------------------------------------------------------- render

def render(args):
    shots = build(args)
    total = int(DUR * FPS)
    frames = range(total)
    if args.preview:
        frames = [int(x * FPS) for x in np.arange(0.2, DUR, args.preview)]
    out = args.out
    if args.stills:
        os.makedirs(args.stills, exist_ok=True)
        proc = None
    else:
        proc = subprocess.Popen(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS),
                                 "-i", "-", "-c:v", "libx264", "-preset", "medium", "-crf", "16", "-pix_fmt", "yuv420p", out],
                                stdin=subprocess.PIPE)
    active = None
    for c in frames:
        t = c / FPS
        sh = next((s for s in shots if s.t0 <= t < s.t1), shots[-1])
        if sh is not active:
            if active is not None:
                active.close()
            active = sh
            sh.start_frame = int(round(sh.t0 * FPS))
            sh.frame_index = c
        img = sh.render(sh, t, c)
        img = img.convert("RGB")
        if img.size != (W, H):
            img = img.resize((W, H))
        if proc:
            proc.stdin.write(img.tobytes())
        else:
            img.save(os.path.join(args.stills, f"{t:05.2f}.jpg"), quality=88)
        if c % 60 == 0:
            print(f"quadro {c}/{total}", flush=True)
    if active:
        active.close()
    if proc:
        proc.stdin.close()
        proc.wait()

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--clips", required=True)
    ap.add_argument("--out", default="trailer-video.mp4")
    ap.add_argument("--preview", type=float, default=0.0, help="segundos entre quadros de prévia (gera JPGs)")
    ap.add_argument("--stills", default="")
    render(ap.parse_args())
