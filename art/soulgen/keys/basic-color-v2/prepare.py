"""Measured crops and expression registration of the image_gen revision.
No character features are painted by this script. Original PNGs remain intact.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import json,hashlib
ROOT=Path(__file__).resolve().parents[1]
BOXES={
 'mata-verde':dict(body=(70,5,420,480),wingNear=(440,130,825,420),wingFar=(830,130,1235,420),tail=(50,490,425,830),fierce=(435,440,785,880),hurt=(835,440,1190,880),happy=(65,840,415,1270)),
 'azulao':dict(body=(35,0,395,440),wingNear=(435,90,805,430),wingFar=(865,90,1255,430),tail=(100,450,350,845),fierce=(425,430,790,870),hurt=(845,430,1210,870),happy=(20,840,380,1275)),
 'raio-de-sol':dict(body=(45,15,420,455),wingNear=(440,140,760,420),wingFar=(855,140,1185,420),tail=(55,480,425,845),fierce=(440,450,825,885),hurt=(850,450,1235,885),happy=(50,855,430,1265)),
 'rabbito':dict(body=(20,190,415,550),head=(390,240,735,545),earNear=(660,30,1020,550),earFar=(1015,25,1265,550),armFar=(50,590,310,855),armNear=(375,600,575,855),tail=(610,550,1095,860),fierce=(15,895,380,1225),hurt=(425,895,800,1225),happy=(845,895,1230,1225))
}
WINDOWS={
 'mata-verde':[(.15,.55,.64,.76)],
 'azulao':[(.14,.49,.28,.61),(.42,.50,.61,.67)],
 'raio-de-sol':[(.20,.43,.70,.65)],
 'rabbito':[(.40,.29,.65,.65),(.78,.28,.95,.65)]
}
def isolate(im):
 alpha=im.getchannel('A'); todo={(x,y) for y in range(im.height) for x in range(im.width) if alpha.getpixel((x,y))>12};groups=[]
 while todo:
  start=todo.pop();group={start};stack=[start]
  while stack:
   x,y=stack.pop()
   for n in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
    if n in todo:todo.remove(n);group.add(n);stack.append(n)
  groups.append(group)
 keep=max(groups,key=len);out=Image.new('RGBA',im.size);src=im.load();dst=out.load()
 for x,y in keep:dst[x,y]=src[x,y]
 bbox=out.getbbox();return out.crop(bbox),bbox
for species,boxes in BOXES.items():
 folder=ROOT/species/'color-rig-v2';source=Image.open(folder/'source.png').convert('RGBA');scale=source.width/1280;crops={};measured={}
 for part,box in boxes.items():
  absolute=tuple(round(v*scale) for v in box);im,bbox=isolate(source.crop(absolute));crops[part]=im
  measured[part]=[absolute[0]+bbox[0],absolute[1]+bbox[1],im.width,im.height]
  if part not in ('fierce','hurt','happy'):im.save(folder/(part+'.png'))
 face='head' if species=='rabbito' else 'body';base=crops[face];w,h=base.size;mask=Image.new('L',base.size);windows=[]
 for box in WINDOWS[species]:
  win=tuple(round(v*(w if i%2==0 else h)) for i,v in enumerate(box));windows.append([win[0],win[1],win[2]-win[0],win[3]-win[1]])
  patch=Image.new('L',(win[2]-win[0],win[3]-win[1]));ImageDraw.Draw(patch).rounded_rectangle((3,3,patch.width-4,patch.height-4),radius=5,fill=255);patch=patch.filter(ImageFilter.GaussianBlur(1));mask.paste(patch,win[:2])
 # Landmarks measured on the canonical face: the beak/nose must never change
 # merely because a generated eye patch extends towards them.
 protected=Image.new('L',base.size)
 if species=='azulao':ImageDraw.Draw(protected).polygon([(86,236),(117,249),(124,276),(54,318),(51,297),(55,255)],fill=255)
 if species=='rabbito':ImageDraw.Draw(protected).rectangle((219,165,267,194),fill=255)
 mask.paste(0,(0,0),protected)
 mask.save(folder/'face-mask.png');report={}
 for expression in ('fierce','hurt','happy'):
  candidate=crops[expression].resize(base.size,Image.Resampling.LANCZOS);result=Image.composite(candidate,base,mask);result.putalpha(base.getchannel('A'))
  pairs=list(zip(base.get_flattened_data(),result.get_flattened_data(),mask.get_flattened_data()))
  assert all(a[3]==b[3] for a,b,m in pairs);assert all(a==b for a,b,m in pairs if m==0)
  assert all(a==b for (a,b,m),lock in zip(pairs,protected.get_flattened_data()) if lock)
  file=folder/(face+'-'+expression+'.png');result.save(file);report[expression]={'alpha_identical':True,'outside_face_identical':True,'beak_or_nose_identical':True,'changed_pixels':sum(a!=b for a,b,m in pairs),'sha256':hashlib.sha256(file.read_bytes()).hexdigest()}
 strip=Image.new('RGBA',(w*4,h))
 for i,exp in enumerate(('normal','fierce','hurt','happy')):strip.alpha_composite(base if exp=='normal' else Image.open(folder/(face+'-'+exp+'.png')),(i*w,0))
 strip.save(folder/'expressions-review.png')
 reg={'sourceSize':source.size,'sourceRects':measured,'facialPart':face,'faceWindows':windows,'expressions':report,'sizes':{p:im.size for p,im in crops.items() if p not in ('fierce','hurt','happy')}}
 (folder/'registration.json').write_text(json.dumps(reg,indent=2),encoding='utf8');print(species,reg['sizes'])
