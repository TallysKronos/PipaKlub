"""Prepare deterministic trailer stems; this does not record or assemble video.

Music is an explicitly labelled edit of the existing Vento aventura recording,
not a new composition or isolated instrumental stems. The roar is synthesized.
"""
from pathlib import Path
import json
import shutil
import subprocess
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
SR = 48000


def ffmpeg():
    exe = shutil.which('ffmpeg')
    if exe:
        return exe
    import imageio_ffmpeg
    return imageio_ffmpeg.get_ffmpeg_exe()


def load(path):
    raw = subprocess.run([ffmpeg(), '-v', 'error', '-i', str(path), '-ac', '2',
        '-ar', str(SR), '-f', 'f32le', '-'], capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype='<f4').reshape(-1, 2).copy()


def wav(path, samples):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), 'wb') as out:
        out.setparams((2, 2, SR, 0, 'NONE', 'not compressed'))
        out.writeframes((np.clip(samples, -1, 1) * 32767).astype('<i2').tobytes())


def faded(samples, seconds=.08):
    samples = samples.copy()
    n = min(int(SR * seconds), len(samples) // 2)
    samples[:n] *= np.linspace(0, 1, n)[:, None]
    samples[-n:] *= np.linspace(1, 0, n)[:, None]
    return samples


def prepare():
    source = ROOT / 'godot/assets/audio/music/opening-theme-v1/vento-aventura.ogg'
    music = load(source)
    bus = np.zeros((SR * 140, 2), np.float32)
    # Each section is explicit, so the editor can replace/re-time it without
    # changing the original music or adding copyrighted third-party material.
    segments = [(0, 16, 0, .22), (16, 72, 16, .78), (72, 94, 40, .92),
                (94, 110, 8, .40), (110, 122, 24, .70),
                (132, 140, max(0, len(music) / SR - 8), .80)]
    for start, end, offset, gain in segments:
        count = round((end - start) * SR)
        i = round(offset * SR)
        part = music[i:i + count]
        if len(part) < count:
            part = np.tile(part, (int(np.ceil(count / max(1, len(part)))), 1))[:count]
        bus[round(start * SR):round(end * SR)] += faded(part, .08) * gain
    # Subtle regular musical accents match the eight 3.5-second walking cuts.
    pulse_t = np.arange(round(.16 * SR)) / SR
    pulse = np.sin(2 * np.pi * (76 * pulse_t - 70 * pulse_t ** 2)) * np.exp(-pulse_t * 30) * .09
    for start in np.arange(22, 50, 3.5):
        i = round(start * SR)
        bus[i:i + len(pulse)] += pulse[:, None]
    # Silence throughout the legendary reveal; roar is a separate editable stem.
    bus[122 * SR:132 * SR] = 0
    bus[-SR:] *= np.linspace(1, 0, SR)[:, None]
    peak = float(np.max(np.abs(bus)))
    bus *= min(1, 10 ** (-3 / 20) / max(peak, 1e-8))
    out = ROOT / 'godot/assets/audio/music/trailer-v2'
    out.mkdir(parents=True, exist_ok=True)
    master = ROOT / 'tmp/trailer-v2/trailer-v2-edit-master.wav'
    wav(master, bus)
    subprocess.run([ffmpeg(), '-v', 'error', '-y', '-i', str(master),
                    '-c:a', 'libvorbis', '-q:a', '6', str(out / 'trailer-v2.ogg')], check=True)

    # Vocal-like harmonic growl plus shaped broadband breath, not a pitch-shifted
    # recording of a person/animal. Seeded noise makes regeneration reproducible.
    t = np.arange(round(2.9 * SR)) / SR
    freq = 44 + 38 * np.exp(-t * 1.8) + 5 * np.sin(t * 9)
    phase = 2 * np.pi * np.cumsum(freq) / SR
    voice = sum(np.sin(k * phase + .13 * k) * np.exp(-k / 9) / k ** .72 for k in range(1, 25))
    rng = np.random.default_rng(126)
    noise = rng.normal(0, 1, len(t))
    bins = np.fft.rfftfreq(len(t), 1 / SR)
    shape = (np.exp(-((bins - 190) / 140) ** 2) + .7 * np.exp(-((bins - 570) / 300) ** 2)
             + .3 * np.exp(-((bins - 1250) / 450) ** 2))
    breath = np.fft.irfft(np.fft.rfft(noise) * shape, n=len(t))
    envelope = np.minimum(1, t / .15) * np.minimum(1, np.maximum(0, 2.35 - t) / .65)
    dry = (voice * .55 + breath * .85) * envelope * (.85 + .15 * np.sin(t * 25))
    stereo = np.stack([dry, dry], axis=1)
    for delay, gain in [(.09, .22), (.19, .18), (.33, .11), (.48, .06)]:
        n = round(delay * SR)
        stereo[n:, 0] += dry[:-n] * gain
        stereo[n:, 1] += dry[:-n] * gain * .91
    stereo = faded(stereo, .025)
    stereo *= 10 ** (-3 / 20) / max(float(np.max(np.abs(stereo))), 1e-8)
    roar = ROOT / 'godot/assets/audio/sfx-v1/creature/eremor_rugido_01.wav'
    wav(roar, stereo)
    markers = dict(duration_seconds=140, sample_rate=SR,
        type='edited existing project music; not a new composition', source=source.relative_to(ROOT).as_posix(),
        source_segments=[dict(at=a, until=b, source_offset=c, gain=d) for a,b,c,d in segments],
        markers=[dict(at=s, event=e) for s,e in [(0,'contained introduction'),(16,'beat entry'),
            (22,'walking cuts every3.5seconds'),(50,'panels'),(72,'duel intensity'),
            (94,'portraits breathing room'),(122,'silence; no music through132'),
            (123,'suggested separate roar onset'),(132,'final chord section'),(140,'end')]],
        walking_cuts_seconds=[float(s) for s in np.arange(22,50,3.5)],
        limitation='Intro is attenuated existing mix, not an isolated single-instrument stem; final section is the source ending, not a newly composed chord.')
    (out / 'marcos.json').write_text(json.dumps(markers, indent=2) + '\n', encoding='utf-8')
    decoded = load(out / 'trailer-v2.ogg')
    metrics = dict(music_duration=len(decoded)/SR, roar_duration=len(stereo)/SR,
        music_sample_peak_dbfs=20*np.log10(max(float(np.max(np.abs(decoded))),1e-8)),
        roar_sample_peak_dbfs=20*np.log10(max(float(np.max(np.abs(stereo))),1e-8)),
        music_silence_122_123_max=float(np.max(np.abs(decoded[122*SR:123*SR]))),
        clipping_samples=int(np.sum(np.abs(decoded)>=1)),
        listening_review='pending human review; numerical checks do not establish sound quality')
    assert abs(metrics['music_duration']-140)<.05 and metrics['clipping_samples']==0
    assert metrics['music_silence_122_123_max']<.002
    (out / 'validacao.json').write_text(json.dumps(metrics, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(metrics))


if __name__ == '__main__':
    prepare()
