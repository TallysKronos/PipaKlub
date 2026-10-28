"""Normalize the neighborhood's illustrated surface family, preserving originals."""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageOps, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'art/overworld/kits/bairro-inicial-v2'
GAME = ROOT / 'godot/assets/overworld/kits/bairro-inicial-v2'
SOURCE = ART / 'fontes/pisos-v4'


def mirror_repeat(image):
    """Reflect a complete painted sample, so joins share their full edge profile."""
    result = Image.new('RGB', (1024, 1024))
    result.paste(image, (0, 0))
    result.paste(ImageOps.mirror(image), (512, 0))
    result.paste(ImageOps.flip(image), (0, 512))
    result.paste(ImageOps.flip(ImageOps.mirror(image)), (512, 512))
    return result


def main():
    images = {}
    for name, colors in [('passeio', 12), ('grama', 8)]:
        source = Image.open(SOURCE / f'{name}-original.png').convert('RGB')
        source = source.resize((512, 512), Image.Resampling.LANCZOS)
        # Preserve the drawing while removing generated grain and watercolor noise.
        source = source.quantize(colors=colors, dither=Image.Dither.NONE).convert('RGB')
        images[name] = mirror_repeat(source)
    asphalt = Image.open(GAME / 'surfaces/asfalto.png').convert('RGB').resize((512, 512))
    values = np.asarray(asphalt, dtype=float)
    mean = values.mean(axis=(0, 1))
    values = np.clip((values - mean) * .30 + [68, 88, 107], 0, 255).astype('uint8')
    asphalt = Image.fromarray(values).quantize(colors=5, dither=Image.Dither.NONE).convert('RGB')
    images['asfalto'] = mirror_repeat(asphalt)
    # Same limestone drawing on the retaining wall, with a quieter warm shadow value.
    wall = np.asarray(images['passeio'], dtype=float)
    images['pedra'] = Image.fromarray(np.clip(wall * [.81, .80, .77], 0, 255).astype('uint8'))
    # Reuse painted cut-earth strata for the monolithic map foundation.
    earth = Image.open(ROOT / 'godot/assets/overworld/kits/terrenos-v1/superficies/terra-barranco.png').convert('RGB').resize((512, 512), Image.Resampling.LANCZOS)
    values = np.asarray(earth, dtype=float)
    mean = values.mean(axis=(0, 1))
    values = np.clip((values - mean) * .58 + [140, 102, 72], 0, 255).astype('uint8')
    earth = Image.fromarray(values).quantize(colors=8, dither=Image.Dither.NONE).convert('RGB')
    foundation = Image.new('RGB', (1024, 512))
    foundation.paste(earth, (0, 0)); foundation.paste(ImageOps.mirror(earth), (512, 0))
    for base in [ART, GAME]:
        foundation.save(base / 'surfaces/terra-fundacao.png')
    for name, image in images.items():
        for base in [ART, GAME]:
            image.save(base / 'surfaces' / f'{name}-manga-v4.png')
    board = Image.new('RGB', (1024, 768), '#20343E')
    draw = ImageDraw.Draw(board)
    for i, (name, image) in enumerate(images.items()):
        repeated = Image.new('RGB', (3072, 3072))
        for x in range(3):
            for y in range(3):
                repeated.paste(image, (x * 1024, y * 1024))
        x, y = i % 2 * 512, i // 2 * 384
        board.paste(repeated.resize((512, 352), Image.Resampling.LANCZOS), (x, y + 32))
        draw.text((x + 12, y + 10), name.upper() + ' / 3 x 3', fill='#F4E7C7')
    out = ROOT / 'documentation/overworld/bairro-inicial-v2'
    board.save(out / 'PISOS-V4-REPETICAO.png')
    record = json.loads((SOURCE / 'origem.json').read_text(encoding='utf-8'))
    record['foundation']={'source':'godot/assets/overworld/kits/terrenos-v1/superficies/terra-barranco.png','runtimeSize':[1024,512],'normalization':'8 colors, 58% contrast, earth-brown palette, horizontal mirror repeat','geometry':'perimeter walls to z=-40, shared vertices and bottom cap'}
    record.update({'runtimeSize': [1024, 1024], 'normalization': '512px painted sample; no dithering; 12 paving / 8 grass colors; reflected 2x2 wrap; asphalt reduced contrast; limestone wall from same paving painting', 'consumer': 'godot/scripts/overworld/starter_neighborhood.gd', 'collisionChanges': False})
    (SOURCE / 'producao.json').write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding='utf-8')
    print('Four coordinated neighborhood surfaces prepared; 3x3 wrap sheet saved.')


if __name__ == '__main__':
    main()
