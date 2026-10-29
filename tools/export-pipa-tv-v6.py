"""Export and inspect a single generated H3 shot without joining clips."""
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
    parser.add_argument('source', type=Path)
    args = parser.parse_args()
    source = args.source.resolve(strict=True)
    ff = edit.imageio_ffmpeg.get_ffmpeg_exe()
    out = ROOT/'documentation/pipa-tv-cinematic-v6'
    out.mkdir(parents=True, exist_ok=True)
    common = [ff, '-nostdin', '-hide_banner', '-loglevel', 'error', '-y', '-filter_threads', '1']
    preview = out/'kael-janela-tyler-plano-continuo.mp4'
    subprocess.run(common+['-i', str(source), '-vf',
                          'scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2',
                          '-c:v', 'libx264', '-threads', '2', '-crf', '18', '-c:a', 'copy',
                          '-movflags', '+faststart', str(preview)], check=True)
    subprocess.run(common+['-i', str(source), '-vf', 'fps=1.5,scale=400:-1,tile=4x3',
                          '-frames:v', '1', str(out/'planos.png')], check=True)
    metadata = edit.probe(ff, source)
    for name, seconds in [('quarto', 0), ('janela', 3), ('tyler', 7), ('final', metadata['seconds']-.1)]:
        subprocess.run(common+['-ss', str(seconds), '-i', str(source), '-frames:v', '1',
                              str(out/f'{name}.png')], check=True)
    report = {'source': str(source.relative_to(ROOT)), 'source_metadata': metadata,
              'preview': str(preview.relative_to(ROOT)), 'preview_metadata': edit.probe(ff, preview),
              'single_generation': True, 'editing': 'Only proportional resize and encoding; no cuts, holds or dissolves.',
              'runtime_changed': False, 'native_hd': False}
    (out/'metadados.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
