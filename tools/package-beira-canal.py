"""Mechanical alpha bounds and atlas packing; original generated art remains untouched."""
from pathlib import Path
from PIL import Image
import json
root=Path(__file__).resolve().parent.parent
source=root/'art/characters/beira-canal-v1/source.png'
im=Image.open(source).convert('RGBA')
columns=[(289,485),(605,782),(856,1114),(1207,1376),(1510,1688)]
names=['Vaeli','Noxen','Soryn','Eriska','Kleie']
out=Image.new('RGBA',(640,256)); sprites=[]
for row in range(2):
 for col,(x0,x1) in enumerate(columns):
  tile=im.crop((x0,row*396,x1,min(im.height,(row+1)*396)))
  box=tile.getchannel('A').point(lambda a:255 if a>32 else 0).getbbox()
  assert box is not None
  tile=tile.crop(box); scale=112/tile.height
  tile=tile.resize((round(tile.width*scale),112),Image.Resampling.NEAREST)
  x=col*128+(128-tile.width)//2;y=row*128+120-tile.height
  out.alpha_composite(tile,(x,y));sprites.append({'name':names[col],'facing':'se' if row==0 else 'nw','bounds':[x,y,tile.width,tile.height]})
target=root/'godot/assets/npc-ds/beira-canal-v1';target.mkdir(parents=True,exist_ok=True)
out.save(target/'atlas.png');(target/'atlas.json').write_text(json.dumps({'sprites':sprites},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Packed 10 non-overlapping alpha sprites:',out.size)

# Provisional story art. Packing preserves generated alpha; no painted retouching.
story=root/'godot/assets/campaign/beira-canal-v1';story.mkdir(parents=True,exist_ok=True)
grampo=Image.open(source.parent/'grampo-source.png').convert('RGBA')
box=grampo.getchannel('A').point(lambda a:255 if a>32 else 0).getbbox();grampo=grampo.crop(box)
grampo.resize((round(grampo.width*112/grampo.height),112),Image.Resampling.NEAREST).save(story/'grampo.png')
platyx=Image.open(source.parent/'platyx-source.png').convert('RGBA')
sheet=Image.new('RGBA',(1024,256));frames=[]
for i in range(4):
 tile=platyx.crop((i*platyx.width//4,0,(i+1)*platyx.width//4,platyx.height))
 box=tile.getchannel('A').point(lambda a:255 if a>32 else 0).getbbox();assert box is not None
 tile=tile.crop(box);scale=min(220/tile.width,176/tile.height)
 tile=tile.resize((round(tile.width*scale),round(tile.height*scale)),Image.Resampling.NEAREST)
 sheet.alpha_composite(tile,(i*256+(256-tile.width)//2,228-tile.height));frames.append({'x':i*256,'y':0,'w':256,'h':256})
sheet.save(story/'platyx.png')
p=root/'godot/assets/campaign/content.json';content=json.loads(p.read_text(encoding='utf-8'))
content['combat']['platyx-draft']={'image':'beira-canal-v1/platyx.png','animations':{key:frames for key in content['combat']['basic-carcara']['animations']}}
p.write_text(json.dumps(content,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
