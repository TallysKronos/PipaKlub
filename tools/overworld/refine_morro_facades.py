"""PIP-87: normalize generated facades without changing collision or anchors."""
from pathlib import Path
import json, shutil
from PIL import Image
from build_art import studio, scale_board

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'art/overworld/kits/morro'
RUNTIME = ROOT / 'godot/assets/overworld/kits/morro'

def main():
    kit = json.loads((ART / 'kit.json').read_text(encoding='utf-8'))
    report = []
    for variant, entry in kit['pieces']['casa-morro']['variants'].items():
        if variant.endswith('-direita'): continue
        source = f'fontes/fachadas-v3/{variant}.png'
        image = Image.open(ART / source).convert('RGBA')
        image.putalpha(image.getchannel('A').point(lambda a: 0 if a < 160 else a))
        image = image.crop(image.getchannel('A').getbbox())
        # Keep the established projected width. Never stretch either axis.
        factor = (entry['size'][0] - 4) / image.width
        image = image.resize((round(image.width * factor), round(image.height * factor)), Image.Resampling.LANCZOS)
        output = Image.new('RGBA', tuple(entry['size']))
        offset = (entry['anchor'][0] - image.width // 2, entry['anchor'][1] - image.height)
        output.alpha_composite(image, offset)
        entry['file'] = f'pecas/casa-morro-{variant}-v3.png'
        entry['groundAnchor'] = 'front'
        output.save(ART / entry['file'])
        shutil.copy2(ART / entry['file'], RUNTIME / entry['file'])
        entry.update(rasterSize=list(image.size), source={'file': source, 'tool': 'image_gen.imagegen', 'geometryGuide': f'fontes/geometria/casa-morro-{variant}.png', 'normalization': 'alpha cleanup, tight crop, uniform width fit, existing front base anchor'}, approval='pending_owner_review')
        report.append({'variant': variant, 'size': list(image.size), 'offset': list(offset), 'footprint': entry['footprint'], 'anchor': entry['anchor']})
    for path in [ART / 'kit.json', RUNTIME / 'kit.json']:
        path.write_text(json.dumps(kit, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    studio(kit)
    scale_board(kit)
    print(json.dumps(report))

if __name__ == '__main__':
    main()
