"""Join three reviewed local H3 clips, retaining original clips and provenance."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tmp/video-encoder'))
import imageio_ffmpeg


def probe(ffmpeg, path):
    result = subprocess.run([ffmpeg, '-nostdin', '-hide_banner', '-i', str(path)],
                            capture_output=True, text=True, encoding='utf-8', errors='replace')
    match = re.search(r'Duration: (\d+):(\d+):(\d+(?:\.\d+)?)', result.stderr)
    if not match:
        raise RuntimeError(f'Cannot read duration: {path}')
    h, m, s = map(float, match.groups())
    size = re.search(r'Video:.*?\b(\d{2,5})x(\d{2,5})\b', result.stderr)
    return {'seconds': h * 3600 + m * 60 + s,
            'audio': bool(re.search(r'Stream .*Audio:', result.stderr)),
            'dimensions': list(map(int,size.groups())) if size else None}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('clips', type=Path, nargs=3, metavar='MP4')
    parser.add_argument('--overlap', type=float, default=0.16)
    args = parser.parse_args()
    clips = [p.resolve(strict=True) for p in args.clips]
    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
    info = [probe(ffmpeg, p) for p in clips]
    durations = [v['seconds'] for v in info]
    overlap = args.overlap
    if not 0 <= overlap < min(durations) / 4:
        raise ValueError('Overlap must be nonnegative and shorter than a quarter of each clip.')
    out = ROOT / 'documentation/pipa-tv-cinematic-v2'
    out.mkdir(parents=True, exist_ok=True)
    master = ROOT / 'art/pipa-tv-cinematic-v2/video-original/pipa-tv-v2-montagem-nativa.mp4'
    master.parent.mkdir(parents=True, exist_ok=True)
    command = [ffmpeg, '-nostdin', '-hide_banner', '-loglevel', 'error', '-y', '-filter_complex_threads', '1']
    for path in clips:
        command += ['-i', str(path)]
    filters = []
    for i, details in enumerate(info):
        filters.append(f'[{i}:v]scale=864:480:force_original_aspect_ratio=decrease,'
                       f'pad=864:480:(ow-iw)/2:(oh-ih)/2,setsar=1,format=yuv420p,'
                       f'setpts=PTS-STARTPTS,fps=24,settb=AVTB[v{i}]')
        audio = f'[{i}:a]' if details['audio'] else 'anullsrc=r=48000:cl=stereo,'
        filters.append(f'{audio}aresample=48000,aformat=channel_layouts=stereo,'
                       f'apad,atrim=duration={durations[i]},asetpts=PTS-STARTPTS[a{i}]')
    if overlap:
        filters += [f'[v0][v1]xfade=transition=fade:duration={overlap}:'
                    f'offset={durations[0]-overlap},fps=24,settb=AVTB[v01]',
                    f'[v01][v2]xfade=transition=fade:duration={overlap}:'
                    f'offset={durations[0]+durations[1]-overlap*2},fps=24[joined]',
                    f'[a0][a1]acrossfade=d={overlap}:c1=tri:c2=tri[a01]',
                    f'[a01][a2]acrossfade=d={overlap}:c1=tri:c2=tri[sound]']
    else:
        filters += ['[v0][a0][v1][a1][v2][a2]concat=n=3:v=1:a=1[joined][sound]']
    command += ['-filter_complex', ';'.join(filters), '-map', '[joined]', '-map', '[sound]',
                '-c:v', 'libx264', '-threads', '2', '-preset', 'medium', '-crf', '18', '-pix_fmt', 'yuv420p',
                '-c:a', 'aac', '-b:a', '160k', '-movflags', '+faststart', str(master)]
    subprocess.run(command, check=True)
    scale = 'scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2'
    preview = out / 'pipa-tv-apresentacao-pipeiros-batalha.mp4'
    common = [ffmpeg, '-nostdin', '-hide_banner', '-loglevel', 'error', '-y', '-threads', '2', '-filter_threads', '1']
    subprocess.run(common + ['-i', str(master), '-vf', scale, '-c:v', 'libx264', '-crf', '18',
                   '-preset', 'medium', '-c:a', 'copy', '-movflags', '+faststart', str(preview)], check=True)
    runtime = ROOT / 'godot/assets/campaign/cinematics/pipa-tv-abertura-v2.ogv'
    subprocess.run(common + ['-i', str(master), '-vf', scale, '-c:v', 'libtheora', '-q:v', '7',
                   '-c:a', 'libvorbis', '-q:a', '4', str(runtime)], check=True)
    subprocess.run(common + ['-ss', '1', '-i', str(master), '-frames:v', '1', str(out/'poster.png')], check=True)
    subprocess.run(common + ['-i', str(master), '-vf', 'fps=0.6,scale=320:-1,tile=4x3',
                   '-frames:v', '1', str(out/'planos.png')], check=True)
    # Frame samples give a consistent visual review surface without running game tests.
    for i, path in enumerate(clips, start=1):
        subprocess.run(common + ['-i', str(path), '-vf', 'fps=1.2,scale=320:-1,tile=4x2',
                       '-frames:v', '1', str(out/f'clipe-{i:02d}-planos.png')], check=True)
    report = {'sources': [{'path': str(p.relative_to(ROOT)), **v} for p,v in zip(clips,info)],
              'transition': {'kind': 'short dissolve with audio crossfade', 'seconds': overlap},
              'master': str(master.relative_to(ROOT)), 'master_metadata': probe(ffmpeg,master),
              'preview': str(preview.relative_to(ROOT)), 'runtime': str(runtime.relative_to(ROOT)),
              'native_generation': '864x480, 24 fps; 1280x720 exports are resized, not native HD'}
    (out/'montagem.json').write_text(json.dumps(report,ensure_ascii=False,indent=2), encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
