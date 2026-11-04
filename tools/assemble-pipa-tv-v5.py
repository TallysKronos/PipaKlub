"""Append the generated petal transition to V4, exporting review media only."""
import argparse
import importlib.util
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('pipa_edit', ROOT/'tools/assemble-pipa-tv-v2.py')
edit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(edit)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('transition', type=Path)
    args = parser.parse_args()
    clips = [ROOT/'art/pipa-tv-cinematic-v4/video-original/pipa-tv-v4-montagem-nativa.mp4',
             args.transition.resolve(strict=True)]
    ff = edit.imageio_ffmpeg.get_ffmpeg_exe()
    info = [edit.probe(ff, p) for p in clips]
    if not all(m['audio'] for m in info):
        raise RuntimeError('Both source clips must contain their generated audio.')
    out = ROOT/'documentation/pipa-tv-cinematic-v5'
    out.mkdir(parents=True, exist_ok=True)
    master = ROOT/'art/pipa-tv-cinematic-v5/video-original/pipa-tv-v5-montagem.mp4'
    master.parent.mkdir(parents=True, exist_ok=True)
    common = [ff, '-nostdin', '-hide_banner', '-loglevel', 'error', '-y',
              '-filter_threads', '1', '-filter_complex_threads', '1']
    filters = []
    fit = 'scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2'
    for i, details in enumerate(info):
        filters.append(f'[{i}:v]{fit},setsar=1,format=yuv420p,setpts=PTS-STARTPTS,fps=24,settb=AVTB[v{i}]')
        filters.append(f'[{i}:a]aresample=48000,aformat=channel_layouts=stereo,apad,'
                       f'atrim=duration={details["seconds"]},asetpts=PTS-STARTPTS[a{i}]')
    overlap = .20
    filters += [f'[v0][v1]xfade=transition=fade:duration={overlap}:'
                f'offset={info[0]["seconds"]-overlap},fps=24[v]',
                f'[a0][a1]acrossfade=d={overlap}:c1=tri:c2=tri[a]']
    subprocess.run(common+['-i', str(clips[0]), '-i', str(clips[1]), '-filter_complex', ';'.join(filters),
                          '-map', '[v]', '-map', '[a]', '-c:v', 'libx264', '-threads', '2',
                          '-preset', 'medium', '-crf', '18', '-c:a', 'aac', '-b:a', '160k',
                          '-movflags', '+faststart', str(master)], check=True)
    preview = out/'pipa-tv-abertura-completa-v5.mp4'
    subprocess.run(common+['-i', str(master), '-c', 'copy', '-movflags', '+faststart', str(preview)], check=True)
    standalone = out/'kael-tyler-petalas.mp4'
    subprocess.run(common+['-i', str(clips[1]), '-vf', fit, '-c:v', 'libx264', '-threads', '2',
                          '-crf', '18', '-c:a', 'copy', '-movflags', '+faststart', str(standalone)], check=True)
    subprocess.run(common+['-i', str(clips[1]), '-vf', 'fps=1.2,scale=400:-1,tile=4x2',
                          '-frames:v', '1', str(out/'transicao-planos.png')], check=True)
    report = {'sources': [{'path': str(p.relative_to(ROOT)), **m} for p, m in zip(clips, info)],
              'preview': str(preview.relative_to(ROOT)), 'standalone': str(standalone.relative_to(ROOT)),
              'film_metadata': edit.probe(ff, preview), 'overlap_seconds': overlap,
              'export_note': '1280x720 is an aspect-preserving resized review export, not native HD generation.',
              'runtime_changed': False}
    (out/'montagem.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
