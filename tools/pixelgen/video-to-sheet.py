"""Extract selected video poses to one fixed canvas/palette. Output is a review draft.

Uses a SINGLE crop/scale/ground line for the whole clip selection, never per-frame
auto-fit. Source video and selected timestamps remain in the manifest. No interpolation
or claim that palette quantisation restores artist-authored pixel clusters.
"""
import argparse
import json
import math
from pathlib import Path
import subprocess
import sys

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
FFMPEG = ROOT / 'tmp/video-encoder/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe'


def key_image(image, tolerance=110):
    """Binary chroma mask; hue test also removes compressed magenta edge fringes."""
    out = image.convert('RGBA')
    data = []
    for r, g, b, _ in out.getdata():
        background = ((r - 255)**2 + g*g + (b - 255)**2 < tolerance*tolerance
                      or (r > g + 65 and b > g + 55))
        data.append((r, g, b, 0 if background else 255))
    out.putdata(data)
    return out


def pack(images, width=48, height=64, colors=20):
    boxes = [im.getchannel('A').getbbox() for im in images]
    if any(b is None for b in boxes):
        raise ValueError('Quadro vazio depois do chroma; revise fundo e seleção.')
    left, top = min(b[0] for b in boxes), min(b[1] for b in boxes)
    right, bottom = max(b[2] for b in boxes), max(b[3] for b in boxes)
    crop = (left, top, right, bottom)
    scale = min((width-4)/(right-left), (height-6)/(bottom-top))
    size = (max(1, round((right-left)*scale)), max(1, round((bottom-top)*scale)))
    offset = ((width-size[0])//2, height-2-size[1])
    natives = []
    for im in images:
        native = Image.new('RGBA', (width, height))
        native.paste(im.crop(crop).resize(size, Image.Resampling.NEAREST), offset)
        natives.append(native)
    # Only opaque pixels participate; chroma/empty margins cannot consume palette slots.
    samples = [rgb[:3] for im in natives for rgb in im.getdata() if rgb[3]]
    sw = min(4096, len(samples)); sh = math.ceil(len(samples)/sw)
    sample = Image.new('RGB', (sw, sh), samples[0])
    sample.putdata(samples + [samples[0]]*(sw*sh-len(samples)))
    palette_image = sample.quantize(colors=colors, method=Image.Quantize.MEDIANCUT)
    raw = palette_image.getpalette()
    used = sorted({v for _, v in palette_image.getcolors()})
    palette = [[0, 0, 0, 0]] + [raw[v*3:v*3+3]+[255] for v in used]
    mapping = {v: min(range(1, len(palette)), key=lambda i: sum((raw[v*3+k]-palette[i][k])**2 for k in range(3))) for v in range(len(raw)//3)}
    frames, indices = [], []
    for native in natives:
        q = native.convert('RGB').quantize(palette=palette_image, dither=Image.Dither.NONE)
        ind = [mapping[v] if a else 0 for v, a in zip(q.getdata(), native.getchannel('A').getdata())]
        frame = Image.new('RGBA', (width, height)); frame.putdata([tuple(palette[v]) for v in ind])
        frames.append(frame); indices.append(ind)
    return frames, indices, palette, {'crop': list(crop), 'scale': scale, 'resized': list(size), 'offset': list(offset)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('video', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--times', help='Timestamps explícitos em segundos, separados por vírgula')
    parser.add_argument('--start', type=float, default=1)
    parser.add_argument('--duration', type=float, default=1)
    parser.add_argument('--frames', type=int, default=8)
    parser.add_argument('--width', type=int, default=48)
    parser.add_argument('--height', type=int, default=64)
    parser.add_argument('--colors', type=int, default=20)
    parser.add_argument('--name', default='Kael · vídeo · rascunho')
    parser.add_argument('--sequence', default='walk-E')
    args = parser.parse_args()
    if not (1 <= args.frames <= 16 and 8 <= args.width <= 128 and 8 <= args.height <= 128 and 2 <= args.colors <= 64):
        parser.error('Limites: 1–16 quadros, 8–128 px e 2–64 cores.')
    times = ([float(v) for v in args.times.split(',')] if args.times else
             [args.start+i*args.duration/args.frames for i in range(args.frames)])
    if not 1 <= len(times) <= 16 or any(not math.isfinite(t) or t < 0 for t in times):
        parser.error('Use 1–16 tempos finitos e positivos.')
    if any(b <= a for a, b in zip(times, times[1:])):
        parser.error('Timestamps devem estar em ordem crescente.')
    if not math.isfinite(args.duration) or args.duration <= 0:
        parser.error('Duração deve ser finita e positiva.')
    video = args.video.resolve(strict=True); out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    source = out/'frames-fonte'; source.mkdir(exist_ok=True)
    images = []
    for i, t in enumerate(times):
        filename = source/f'{i:02d}.png'
        filename.unlink(missing_ok=True)
        subprocess.run([str(FFMPEG), '-hide_banner', '-loglevel', 'error', '-y', '-ss', str(t), '-i', str(video), '-frames:v', '1', str(filename)], check=True)
        with Image.open(filename) as im:
            images.append(key_image(im))
    frames, indices, palette, alignment = pack(images, args.width, args.height, args.colors)
    sheet = Image.new('RGBA', (args.width*len(frames), args.height))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i*args.width, 0)); frame.save(out/f'frame-{i:02d}.png')
    sheet.save(out/'sheet.png')
    preview = Image.new('RGB', (len(frames)*args.width*4, args.height*4+20), '#e9e4d8')
    draw = ImageDraw.Draw(preview)
    for i, frame in enumerate(frames):
        enlarged = frame.resize((args.width*4, args.height*4), Image.Resampling.NEAREST)
        preview.paste(enlarged, (i*args.width*4, 0), enlarged)
        draw.text((i*args.width*4+4, args.height*4+3), f'{i+1} / {times[i]:.3f}s', fill='#172237')
    preview.save(out/'revisao.png')
    deltas = [b-a for a, b in zip(times, times[1:])]
    delays = [max(20, min(2000, round(t*1000))) for t in deltas+[deltas[-1] if deltas else args.duration]]
    project = {'kind': 'pixelgen', 'version': 2, 'name': args.name, 'width': args.width, 'height': args.height,
               'cols': len(frames), 'rows': 1, 'palette': palette, 'layers': [{'name': 'Arte do vídeo', 'visible': True, 'locked': False}],
               'settings': {'width': args.width, 'height': args.height, 'cols': len(frames), 'rows': 1, 'margin': 2, 'colors': args.colors},
               'frames': [{'name': f'{args.sequence}-{i+1}', 'duration': delays[i], 'indices': ind, 'cels': [ind]} for i, ind in enumerate(indices)],
               'sequences': [{'name': args.sequence, 'start': 0, 'end': len(frames)-1, 'loop': True, 'direction': 'forward'}]}
    (out/'video.pixelgen.json').write_text(json.dumps(project, ensure_ascii=False), encoding='utf-8')
    manifest = {'sourceVideo': str(video), 'timestamps': times, 'cell': [args.width, args.height], 'paletteColors': len(palette)-1,
                'alignment': alignment, 'status': 'rascunho: revisar identidade, juntas, loop, clusters e leitura 1x',
                'limitations': ['A quantização limita cores; não recupera automaticamente clusters desenhados.',
                                'Sem separação anatômica ou pose inferida: camada única para retoque.',
                                'Loop e anatomia exigem inspeção; timestamps são seleção de quadros, não certificação.']}
    (out/'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(manifest, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
