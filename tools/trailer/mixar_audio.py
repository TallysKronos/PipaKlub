#!/usr/bin/env python3
"""Áudio do trailer: "Vento · aventura" + efeitos do jogo + sub-grave e riser sintetizados.
Os tempos acompanham tools/trailer/montar_trailer.py (mesma linha do tempo de 56 s).

    python3 tools/trailer/mixar_audio.py --out trailer-audio.wav
"""
import argparse
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from montar_trailer import G, DUR, MUSIC, MUSIC_IN, MUSIC_OFFSET  # noqa: E402

SR = 48000
SFX = os.path.join(G, "assets/audio/sfx-v1")

def load(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "2", "-ar", str(SR), "-f", "f32le", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32).reshape(-1, 2).copy()

def sub_boom(dur=1.6, f0=95, f1=34, gain=0.9):
    t = np.arange(int(SR * dur)) / SR
    f = f1 + (f0 - f1) * np.exp(-t * 5)
    ph = 2 * np.pi * np.cumsum(f) / SR
    env = np.exp(-t * 2.6) * np.minimum(1, t / 0.004)
    s = np.sin(ph) * env * gain
    click = np.random.default_rng(1).normal(0, 1, len(t)) * np.exp(-t * 90) * 0.25
    s = s + click
    return np.stack([s, s], 1).astype(np.float32)

def riser(dur=2.0, gain=0.35):
    n = int(SR * dur)
    t = np.arange(n) / SR
    noise = np.random.default_rng(2).normal(0, 1, n)
    # simple rising band: noise × rising sine sweep, swelling
    sweep = np.sin(2 * np.pi * np.cumsum(300 + 2600 * (t / dur) ** 2) / SR)
    s = (noise * 0.6 * (t / dur) ** 2 + sweep * 0.35 * (t / dur) ** 3) * gain
    s[-int(SR * 0.02):] *= np.linspace(1, 0, int(SR * 0.02))
    return np.stack([s, s * 0.95], 1).astype(np.float32)

def place(bus, clip, at, gain=1.0):
    i = int(at * SR)
    if i >= len(bus):
        return
    n = min(len(clip), len(bus) - i)
    bus[i:i + n] += clip[:n] * gain

def main(out):
    total = int(DUR * SR)
    bus = np.zeros((total, 2), np.float32)
    # ---- music: enters at MUSIC_IN, breath before the reveal, final hit at 50 s
    music = load(MUSIC)
    start = int(MUSIC_OFFSET * SR)
    seg = music[start:start + total - int(MUSIC_IN * SR)]
    env = np.ones(len(seg), np.float32)
    t = np.arange(len(seg)) / SR + MUSIC_IN
    env *= np.clip((t - MUSIC_IN) / 0.25, 0, 1)
    duck = (t >= 48.8) & (t < 50.0)
    env[duck] = 0.12 + 0.88 * np.clip((48.95 - t[duck]) / 0.15, 0, 1)
    env *= np.where(t > 54.6, np.clip((56.0 - t) / 1.4, 0, 1), 1)
    place(bus, seg * env[:, None] * 0.85, MUSIC_IN)
    # ---- cold open
    wind = load(os.path.join(SFX, "ambience/wind_01.wav"))
    wind_env = np.clip(np.arange(len(wind)) / SR / 1.0, 0, 1)[:, None]
    place(bus, wind * wind_env, 0.0, 0.7)
    place(bus, load(os.path.join(SFX, "workshop/paper_cut_01.wav")), 1.8, 0.9)
    place(bus, load(os.path.join(SFX, "workshop/paper_cut_02.wav")), 2.5, 0.9)
    place(bus, sub_boom(gain=0.6), 2.55)
    place(bus, load(os.path.join(SFX, "workshop/paper_tear_01.wav")), 3.55, 1.0)
    # ---- panel slides (whooshes)
    gusts = [os.path.join(SFX, f"workshop/gust_0{i}.wav") for i in (1, 2, 3)]
    for i, at in enumerate([4.1, 7.4, 9.75, 11.2, 13.0, 14.8, 16.55, 17.95, 24.6, 37.4, 41.2]):
        place(bus, load(gusts[i % 3]), at - 0.12, 0.7)
    # ---- name cards and Rabbito
    for at in (8.45, 10.15, 18.15, 39.1):
        place(bus, load(os.path.join(SFX, "battle/critical_02.wav")), at, 0.55)
        place(bus, sub_boom(dur=0.8, gain=0.35), at)
    place(bus, load(os.path.join(SFX, "creature/rabbito_01.wav")), 10.25, 0.9)
    # ---- duel cuts: impact frames
    hits = [19.3, 20.6, 21.95, 23.3, 28.2, 29.4, 30.6, 31.8, 34.15, 35.45, 36.5]
    for i, at in enumerate(hits):
        place(bus, load(os.path.join(SFX, f"battle/line_hit_0{1 + i % 3}.wav")), at, 0.85)
        place(bus, load(os.path.join(SFX, f"battle/critical_0{1 + i % 3}.wav")), at + 0.02, 0.5)
        place(bus, sub_boom(dur=0.9, gain=0.45), at)
    # ---- villains
    place(bus, load(os.path.join(SFX, "battle/boss_intro_01.wav")), 24.65, 0.9)
    place(bus, sub_boom(gain=0.7), 24.65)
    # ---- climax: risers and the motto
    place(bus, riser(2.0), 43.0)
    place(bus, sub_boom(gain=0.75), 45.0)
    place(bus, riser(1.8, gain=0.3), 47.0)
    place(bus, load(os.path.join(SFX, "workshop/paper_cut_03.wav")), 47.0, 0.9)
    # ---- reveal
    place(bus, sub_boom(dur=2.4, gain=1.0), 50.0)
    place(bus, load(os.path.join(SFX, "workshop/paper_tear_02.wav")), 50.0, 1.0)
    place(bus, load(os.path.join(SFX, "workshop/soul_charge_01.wav")), 51.0, 0.5)
    # ---- master: soft limiter
    peak = np.abs(bus).max()
    bus = np.tanh(bus * 1.1) / np.tanh(1.1)
    bus *= 0.93 / max(1e-6, np.abs(bus).max())
    pcm = (bus * 32767).astype(np.int16)
    with wave.open(out, "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("áudio", out, f"{len(bus)/SR:.1f}s pico bruto {peak:.2f}")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="trailer-audio.wav")
    main(ap.parse_args().out)
