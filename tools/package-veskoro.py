"""Normalize native generated alpha and register a static battle pose, not a rig."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFilter
root=Path(__file__).resolve().parent.parent
folder=root/'art/creatures/veskoro/battle-v1'
target=root/'godot/assets/campaign/veskoro-v1'
target.mkdir(parents=True,exist_ok=True)
image=Image.open(folder/'source.png').convert('RGBA')
alpha=image.getchannel('A')
assert alpha.getextrema()[0]==0
mask=alpha.point(lambda a:255 if a>=128 else 0)
seed=(image.width//2,image.height//2)
assert mask.getpixel(seed)==255
ImageDraw.floodfill(mask,seed,128)
support=mask.point(lambda a:255 if a==128 else 0).filter(ImageFilter.MaxFilter(5))
image.putalpha(Image.composite(alpha,Image.new('L',image.size),support))
box=image.getchannel('A').getbbox()
assert box and box[0]>0 and box[1]>0 and box[2]<image.width and box[3]<image.height
sprite=image.crop(box)
sprite=sprite.resize((768,round(sprite.height*768/sprite.width)),Image.Resampling.LANCZOS)
sprite.save(target/'veskoro.png')
frame={'x':0,'y':0,'w':sprite.width,'h':sprite.height}
content_path=root/'godot/assets/campaign/content.json'
content=json.loads(content_path.read_text(encoding='utf-8'))
content['combat']['veskoro']={'image':'veskoro-v1/veskoro.png','animations':{key:[frame.copy()] for key in ['idle','flight','attack','hurt','victory','defeat']}}
content_path.write_text(json.dumps(content,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for filename,region in [('sprite-bounds.json',[0,0,sprite.width,sprite.height]),('portrait-regions.json',[round(sprite.width*.63),round(sprite.height*.33),round(sprite.width*.36),round(sprite.height*.37)])]:
 path=root/'godot/assets/campaign/battle-ink'/filename
 data=json.loads(path.read_text(encoding='utf-8'));data['veskoro']=region
 path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
catalog_path=root/'godot/assets/campaign/championship/districts.json'
catalog=json.loads(catalog_path.read_text(encoding='utf-8'))
next(d for d in catalog['districts'] if d['id']=='palafitas')['stages'][4]['foes'][0]['modelId']='veskoro'
catalog_path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(folder/'qa.json').write_text(json.dumps({'size':sprite.size,'alpha':sprite.getchannel('A').getextrema(),'sourceBox':box,'frames':1,'facing':'right','animated':False},indent=2)+'\n',encoding='utf-8')
print('Veskoro static pose:',sprite.size,'alpha',sprite.getchannel('A').getextrema())
