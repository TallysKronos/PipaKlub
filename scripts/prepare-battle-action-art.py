"""Normalize generated originals without repainting: uniform fit, padding, alpha QA."""
from pathlib import Path
from PIL import Image
import json, hashlib
root=Path(__file__).resolve().parents[1]
source=root/'art/ui/battle-actions-manga-v1'
runtime=root/'godot/assets/campaign/battle-ink/actions-painted-v1'
runtime.mkdir(parents=True,exist_ok=True)
entries=json.loads((source/'generation.json').read_text(encoding='utf-8'))
report=[]
for item in entries:
    file=source/(item['id']+'-source.png')
    art=Image.open(file).convert('RGBA')
    alpha=art.getchannel('A')
    if alpha.getextrema()[0]!=0: raise ValueError('Missing transparency: '+str(file))
    bounds=alpha.point(lambda a:255 if a>8 else 0).getbbox()
    crop=art.crop(bounds)
    crop.thumbnail((232,232),Image.Resampling.LANCZOS)
    target=Image.new('RGBA',(256,256))
    target.alpha_composite(crop,((256-crop.width)//2,(256-crop.height)//2))
    target.save(runtime/(item['id']+'.png'))
    report.append({'id':item['id'],'sourceSha256':hashlib.sha256(file.read_bytes()).hexdigest(),'sourceSize':art.size,'alphaRange':alpha.getextrema(),'sourceCrop':bounds,'runtimeSize':[256,256],'processing':'alpha bounds crop, uniform fit within 232px, centered transparent padding; no repaint or palette replacement'})
(source/'manifest.json').write_text(json.dumps({'tool':'built-in image_gen','approval':'pending-owner-review','runtime':str(runtime.relative_to(root)),'filter':'linear','assets':report},indent=2,ensure_ascii=False),encoding='utf-8')
print('Six painted action assets prepared with transparent padding.')
