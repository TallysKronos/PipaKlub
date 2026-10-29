"""Refresh only the twenty footstep assets; preserve other sounds and wiring metadata."""
import importlib.util
import json
from pathlib import Path
import subprocess
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('builder', ROOT / 'tools/build-soulmonsters-sfx.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)
catalog = json.loads((builder.OUT / 'catalog.json').read_text(encoding='utf-8'))
review_path = builder.ART / 'technical-review.json'
review = json.loads(review_path.read_text(encoding='utf-8'))
measurements = {f['path']: f for f in review['files']}
reel = []
for event in catalog['events']:
    if not event['id'].startswith('world.step_'):
        continue
    event['revision'] = 'soft-sole-v2'
    event['notes'] = 'Contato curto de sola, sem apito; cinco variantes, evita duas últimas; passos por deslocamento, intervalo mínimo 280 ms.'
    event['max_voices'] = 2
    event['cooldown_ms'] = 180
    event['pitch_variation'] = .018
    event['review_status'] = 'technical_pass_listening_pending'
    for i, file in enumerate(event['files']):
        x = builder.render(event, i)
        path = ROOT / 'godot' / file['path'].removeprefix('res://')
        builder.write_wav(path, x)
        with wave.open(str(path), 'rb') as wav:
            pcm = np.frombuffer(wav.readframes(wav.getnframes()), dtype='<i2').astype(float) / 32768
        peak = round(float(20 * np.log10(np.max(np.abs(pcm)))), 2)
        rms = round(float(20 * np.log10(np.sqrt(np.mean(pcm ** 2)))), 2)
        file['sample_peak_dbfs'] = peak
        measurements[file['path']].update(sample_peak_dbfs=peak, rms_dbfs=rms)
        # Match in-game footstep gain; space the audition like walking.
        reel.extend([x * 10 ** (-6/20), np.zeros(round((.42-len(x)/builder.SR)*builder.SR))])
    reel.append(np.zeros(builder.SR))
for path in [builder.OUT / 'catalog.json', builder.ART / 'catalog.json']:
    path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2), encoding='utf-8')
review['footsteps_revision'] = 'soft-sole-v2; 20 files refreshed, PCM peak/RMS checked; listening pending'
review_path.write_text(json.dumps(review, ensure_ascii=False, indent=2), encoding='utf-8')
preview = builder.ART / 'previews/footsteps-v2.wav'
builder.write_wav(preview, np.concatenate(reel))
ff = ROOT / 'tmp/video-encoder/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe'
subprocess.run([str(ff), '-nostdin', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(preview),
                '-c:a', 'libmp3lame', '-b:a', '160k', str(preview.with_suffix('.mp3'))], check=True)
builder.build_board(catalog['events'])
print('Updated 20 footsteps; catalogs, technical measurements and footsteps-v2 preview refreshed.')
