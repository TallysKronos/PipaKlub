"""Read-only raster QA for the trailer illustration delivery."""
import json
import hashlib
from pathlib import Path
from PIL import Image, ImageChops

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'manifest-ilustracoes.json').read_text(encoding='utf-8'))
reports = []
for asset in manifest['assets']:
    path = (root / asset['final']).resolve()
    with Image.open(path) as image:
        alpha = image.getchannel('A') if image.mode == 'RGBA' else None
        transparent = alpha.histogram()[0] if alpha is not None else 0
        expected = (1024,1536) if asset['type']=='portrait' else (1536,1024) if asset['type']=='lettering' else (1920,1080)
        ok = image.size == expected and (not asset['alpha'] or transparent > 0)
        reports.append(dict(id=asset['id'],file=asset['final'],width=image.width,height=image.height,mode=image.mode,alpha_extrema=alpha.getextrema() if alpha else None,transparent_pixels=transparent,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),ok=ok))
with Image.open(root/'onomatopeias/grrraaaooo.png') as whole:
    assembled=Image.new('RGBA',whole.size)
    for part in manifest['roarPieces']['parts']:
        with Image.open(root/part['file']) as piece:
            assembled.paste(piece,(part['rect'][0],part['rect'][1]))
    difference = ImageChops.difference(whole.convert('RGBA'), assembled)
    reconstructed_exactly = not any(band.getbbox() for band in difference.split())
report=dict(ok=all(x['ok'] for x in reports) and reconstructed_exactly,assets=reports,roar_reconstruction_pixel_exact=reconstructed_exactly,limits='Technical raster QA and authoring visual review only; no runtime playback or owner acceptance implied.')
(root/'qa-ilustracoes.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(dict(ok=report['ok'],checked_assets=len(reports),roar_reconstruction_pixel_exact=reconstructed_exactly)))
