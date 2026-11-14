from pathlib import Path
from PIL import Image
import json
ROOT=Path(__file__).resolve().parents[2]
for id in ('alvacordo','papisco'):
 folder=ROOT/f'art/creatures/{id}-prancha-v1'
 sheet=Image.open(folder/'idle.png').convert('RGBA')
 before=Image.open(ROOT/f'tmp/idle-breathing-fix-v1/{id}-idle-before.png').convert('RGBA')
 frames=[];old=[];poses=Image.new('RGB',(896,448),'#263d48')
 report=json.loads((folder/'idle-fix-regioes.json').read_text())
 for f in range(4):
  pair=Image.new('RGBA',(224,112))
  oldpair=Image.new('RGBA',(224,112))
  for v in range(2):
   cell=sheet.crop((f*112,v*112,(f+1)*112,(v+1)*112))
   cell0=sheet.crop((0,v*112,112,(v+1)*112))
   assert cell.getchannel('A').tobytes()==cell0.getchannel('A').tobytes()
   regions=report['frames'][v*4+f]['regions']
   for y in range(112):
    for x in range(112):
     if cell.getpixel((x,y))!=cell0.getpixel((x,y)):
      assert any(r[0]<=x<r[2]and r[1]<=y<r[3]for r in regions)
   pair.paste(cell,(v*112,0))
   oldpair.paste(before.crop((f*112,v*112,(f+1)*112,(v+1)*112)),(v*112,0))
   big=cell.resize((224,224),Image.Resampling.NEAREST);poses.paste(big,(f*224,v*224),big)
  bg=Image.new('RGBA',(224,112),'#263d48');bg.alpha_composite(pair)
  obg=Image.new('RGBA',(224,112),'#263d48');obg.alpha_composite(oldpair)
  frames.append(bg.convert('RGB').resize((672,336),Image.Resampling.NEAREST))
  old.append(obg.convert('RGB').resize((672,336),Image.Resampling.NEAREST))
 frames[0].save(folder/'idle.gif',save_all=True,append_images=frames[1:],duration=[750,200,750,200],loop=0,disposal=2)
 poses.save(folder/'idle-poses.png')
 for sets,name,durations in [(frames,'after',[750,200,750,200]),(old,'before',[400,150,400,150])]:
  sets[0].save(ROOT/f'tmp/idle-breathing-fix-v1/{id}-{name}-compare.gif',save_all=True,append_images=sets[1:],duration=durations,loop=0,disposal=2)
 walk=Image.open(folder/'walk.png').convert('RGBA')
 oldwalk=Image.open(ROOT/f'tmp/idle-breathing-fix-v1/{id}-walk-before.png').convert('RGBA')
 assert walk.tobytes()==oldwalk.tobytes()
 print(id,'protected pixels and silhouette exact; walk untouched; GIF fixed cycle1900ms')
