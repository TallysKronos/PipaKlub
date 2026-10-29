"""Preserve generated FLACs and create listening previews with technical metadata."""
from pathlib import Path
import argparse
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'art/soundtrack-study'
FF = ROOT / 'tmp/video-encoder/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe'
JOBS = {
    '01-vila-v1': '74c606ad-d7d9-4701-af4d-caf1306081ae',
    '02-parque-v1': '2d8cc89b-5cd6-4d94-909a-5840f3998acd',
    '03-batalha-v1': '4f077b57-081d-48bc-903f-8267c77927a0',
}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--version', choices=['v1','v2'], default='v1')
    args = parser.parse_args()
    jobs = JOBS if args.version == 'v1' else {j['id']:j['prompt_id'] for j in json.loads((BASE / 'jobs-v2.json').read_text(encoding='utf-8-sig'))}
    previews = BASE / 'previews'
    previews.mkdir(exist_ok=True)
    records = []
    for track in json.loads((BASE / f'prompts-{args.version}.json').read_text(encoding='utf-8-sig'))['tracks']:
        source = next((BASE / 'originals' / track['id']).glob('*.flac'))
        command = [str(FF), '-nostdin', '-hide_banner', '-i', str(source)]
        result = subprocess.run(command + ['-af', 'volumedetect', '-f', 'null', '-'], capture_output=True, text=True)
        if result.returncode:
            raise RuntimeError(result.stderr[-2000:])
        duration = re.search(r'Duration: (\d+):(\d+):(\d+\.\d+)', result.stderr)
        seconds = int(duration[1])*3600 + int(duration[2])*60 + float(duration[3])
        maximum = re.search(r'max_volume: ([\-\w.]+) dB', result.stderr)
        mean = re.search(r'mean_volume: ([\-\w.]+) dB', result.stderr)
        audio = re.search(r'Audio: ([^\r\n]+)', result.stderr)
        preview = previews / (track['id'] + '.mp3')
        subprocess.run(command + ['-y', '-map', '0:a:0', '-map_metadata', '-1', '-af', 'volume=-4dB', '-c:a', 'libmp3lame', '-b:a', '192k', str(preview)], capture_output=True, check=True)
        records.append({
            **track, 'prompt_id': jobs[track['id']],
            'source': str(source.relative_to(ROOT)), 'preview': str(preview.relative_to(ROOT)),
            'duration_seconds': seconds, 'format': audio[1] if audio else None,
            'max_volume_dbfs': maximum[1] if maximum else None,
            'mean_volume_dbfs': mean[1] if mean else None,
            'decode_ok': True, 'preview_gain_db': -4,
        })
    manifest = {
        'version': args.version,
        'tool': 'ComfyUI ACE-Step 1.5 Turbo, native local nodes, 8 diffusion steps',
        'status': 'three generated direction studies for listening review',
        'paid_nodes': False, 'reference_audio_uploaded': False,
        'reference_role': 'User supplied Digimon Main Lobby and Central Park examples as direction context; no audio was uploaded, sampled, or used for cover generation.',
        'validation': 'Full decode and level measurements only; no claim of perceptual listening review, matching melodies, or finished seamless loops.',
        'integrated_in_game': False, 'tracks': records,
    }
    (BASE / f'manifest-{args.version}.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps([{k: t[k] for k in ['id','duration_seconds','format','max_volume_dbfs','mean_volume_dbfs']} for t in records], indent=2))

if __name__ == '__main__':
    main()
