"""Normalize generated palm pieces; preserve original artwork and rig separation."""
from pathlib import Path
import json
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'art/overworld/kits/cais-v1'
GAME = ROOT / 'godot/assets/overworld/kits/cais-v1'
SOURCE = ART / 'fontes/coqueiro-manga'


def main():
    SOURCE.mkdir(parents=True, exist_ok=True)
    specs = json.loads((ART / 'fontes/coqueiro-manga-origem.json').read_text())
    specs['fruit'] = json.loads((ART / 'fontes/coqueiro-manga-fruto.json').read_text())
    pieces = {}
    for name, info in specs.items():
        original = SOURCE / f'{name}.png'
        if not original.exists():
            shutil.copy2(info['path'], original)
        im = Image.open(original).convert('RGBA')
        # Generated alpha includes a faint peripheral matte. Keep the opaque
        # illustration, remove that matte, then resample with edge antialiasing.
        alpha = im.getchannel('A').point(lambda a: 255 if a >= 200 else 0)
        bounds = alpha.getbbox()
        im.putalpha(alpha)
        im = im.crop(bounds)
        # Prefilter to the actual prop scale; oversized linework shimmers when
        # sampled as an 80px canopy without a mip chain.
        limit = {'canopy': 256, 'trunk': 384, 'fruit': 64}[name]
        im.thumbnail((limit, limit), Image.Resampling.LANCZOS)
        pieces[name] = (im, bounds)
        info['workspaceOriginal'] = str(original.relative_to(ROOT))
        info['opaqueCrop'] = list(bounds)
        info['runtimeSize'] = list(im.size)
        for base in [ART, GAME]:
            (base / 'palma').mkdir(parents=True, exist_ok=True)
            im.save(base / 'palma' / f'{name}.png')

    rig = json.loads((ROOT / 'godot/assets/overworld/kits/frutiferas/rigs/coqueiro/rig.json').read_text())
    rig['name'] = 'Coqueiro do cais · mangá de papel vivo'
    # Explicit source anchors: trunk root, top socket and canopy central node.
    trunk_bounds = pieces['trunk'][1]
    scale = 171.5 / (trunk_bounds[3] - trunk_bounds[1])
    tx = 160 - (580 - trunk_bounds[0]) * scale
    ty = 269 - (1500 - trunk_bounds[1]) * scale
    socket = [tx + (345 - trunk_bounds[0]) * scale,
              ty + (60 - trunk_bounds[1]) * scale]
    cw = 174.0
    cb = pieces['canopy'][1]
    cs = cw / (cb[2] - cb[0])
    canopy_rect = [socket[0] - (807 - cb[0]) * cs,
                   socket[1] - (490 - cb[1]) * cs,
                   cw, (cb[3] - cb[1]) * cs]
    rects = {'trunk': [tx, ty, (trunk_bounds[2] - trunk_bounds[0]) * scale, 171.5],
             'canopy': canopy_rect}
    for name, (im, _) in pieces.items():
        rig['assets'][name] = {'src': f'/art/overworld/kits/cais-v1/palma/{name}.png',
                               'width': im.width, 'height': im.height, 'name': name}
    for part in rig['parts']:
        im = pieces[part['asset']][0]
        part['source'] = [0, 0, im.width, im.height]
        if part['id'] in rects:
            part['rect'] = rects[part['id']]
            part['pivot'] = [160, 269] if part['id'] == 'trunk' else socket
        else:
            index = int(part['id'][-1]) - 1
            w, h = 10, 10 * im.height / im.width
            x, y = socket[0] - 8 + index * 6, socket[1] + 2 + (index % 2) * 5
            part['rect'] = [x, y, w, h]
            part['pivot'] = [x + w / 2, y]
    # Old anatomical ratios describe the old silhouette, not this new artwork.
    rig['anatomy'] = {'version': 1, 'ratios': [], 'behind': [{'part': 'trunk', 'other': 'canopy'}],
                      'joints': [], 'notes': 'New explicit mount anchors; static native scene reviewed. Animation extremes still require separate review.'}
    rig['environment']['jointStatus'] = 'static_native_review_animation_extremes_pending'
    rig['environment']['cropBounds'] = [list(pieces[n][1]) for n in ['trunk', 'canopy', 'fruit']]
    rig['brief']['notes'] = 'Broad folded fronds, sage and teal cel planes. Independent trunk, canopy and detachable fruit. Pier renders resting pose.'
    for base in [ART, GAME]:
        (base / 'palma/rig.json').write_text(json.dumps(rig, ensure_ascii=False, indent=2), encoding='utf-8')
    (SOURCE / 'origem.json').write_text(json.dumps({'tool': 'built-in image_gen', 'pieces': specs,
        'mount': socket, 'scope': 'pier asset library; original fruit tree library preserved'}, ensure_ascii=False, indent=2), encoding='utf-8')
    # Assembly proof uses precisely the runtime rectangles, without repainting.
    proof = Image.new('RGBA', (640, 634), '#DCD8BC')
    for part in sorted(rig['parts'], key=lambda p: p['z']):
        im = pieces[part['asset']][0]
        x, y, w, h = part['rect']
        proof.alpha_composite(im.resize((round(w * 2), round(h * 2)), Image.Resampling.LANCZOS), (round(x * 2), round(y * 2)))
    proof.convert('RGB').save(ROOT / 'documentation/overworld/cais-v1/coqueiro-manga-montagem.png')
    print('New palm pieces, explicit mounts and source provenance saved.')


if __name__ == '__main__':
    main()
