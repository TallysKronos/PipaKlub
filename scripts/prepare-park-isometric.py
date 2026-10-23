"""Deterministic slicing only; source art and alpha are retained unchanged."""
from PIL import Image
from pathlib import Path
import json, shutil, sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'art/soulgen/keys/park-wind-v1'
OUT.mkdir(parents=True, exist_ok=True)
SOURCE = Path(sys.argv[1]) if len(sys.argv)>1 else OUT / 'source-atlas.png'
if SOURCE.resolve() != (OUT/'source-atlas.png').resolve():
    shutil.copy2(SOURCE, OUT / 'source-atlas.png')
im = Image.open(SOURCE).convert('RGBA')
cells = {
 'canopy': (0,0,512,330), 'trunk': (512,0,1024,385),
 'treeSmall': (1024,0,1536,390), 'coreto': (0,330,512,705),
 'bench': (512,390,1024,725), 'flowers': (1024,390,1536,725),
 'pole': (0,705,512,1024), 'sock': (512,745,1024,1024),
 'bunting': (1024,745,1536,1024)
}
assets = {}
for key, cell in cells.items():
    crop = im.crop(cell)
    # Trim fully transparent padding. Do not repaint, key out colors or erode edges.
    box = crop.getchannel('A').point(lambda a: 255 if a > 16 else 0).getbbox()
    crop = crop.crop(box)
    padded = Image.new('RGBA', (crop.width+8, crop.height+8))
    padded.paste(crop,(4,4))
    if key == 'canopy':
        padded.save(OUT/'canopyLandmark.png')
        assets['canopyLandmark'] = {'name':'canopyLandmark','src':'/art/soulgen/keys/park-wind-v1/canopyLandmark.png','width':padded.width,'height':padded.height,'sourceCell':list(cell),'alphaMin':0}
        alternate=OUT/'source-canopy-plain.png'
        if alternate.exists():
            plain=Image.open(alternate).convert('RGBA')
            plain=plain.crop(plain.getchannel('A').point(lambda a:255 if a>16 else 0).getbbox())
            plain.thumbnail((padded.width-8,padded.height-8),Image.Resampling.LANCZOS)
            padded=Image.new('RGBA',padded.size)
            padded.paste(plain,((padded.width-plain.width)//2,(padded.height-plain.height)//2))
    padded.save(OUT / (key+'.png'))
    assets[key] = {'name':key, 'src':'/art/soulgen/keys/park-wind-v1/'+key+'.png',
      'width':padded.width, 'height':padded.height,
      'sourceCell':list(cell), 'alphaMin':padded.getchannel('A').getextrema()[0]}
(OUT/'slices.json').write_text(json.dumps(assets,indent=2)+'\n',encoding='utf8')
print(json.dumps({k:[v['width'],v['height']] for k,v in assets.items()}))
