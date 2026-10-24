"""Deterministic crop/registration of image_gen art. No procedural character drawing.
Coordinates are measured on a 1280-unit diagnostic view; original PNGs stay intact.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import json, hashlib

ROOT=Path(__file__).resolve().parents[1]
BOXES={
 'mata-verde':dict(body=(20,40,420,415),wingNear=(440,130,820,355),wingFar=(870,130,1250,355),tail=(40,465,385,830),fierce=(430,435,830,805),hurt=(845,435,1245,805),happy=(20,835,420,1210)),
 'azulao':dict(body=(60,55,410,445),wingNear=(465,145,775,385),wingFar=(870,145,1180,385),tail=(30,490,375,850),fierce=(460,465,800,860),hurt=(875,465,1220,860),happy=(60,850,410,1245)),
 'raio-de-sol':dict(body=(40,30,420,430),wingNear=(450,105,810,410),wingFar=(850,105,1210,410),tail=(100,450,425,840),fierce=(435,445,820,840),hurt=(850,445,1235,840),happy=(40,825,420,1225)),
 'rabbito':dict(body=(15,240,335,555),head=(340,260,670,550),earNear=(660,50,1025,540),earFar=(1030,40,1240,540),armFar=(45,640,225,855),armNear=(350,640,550,855),tail=(600,620,1010,875),fierce=(15,920,340,1215),hurt=(340,920,645,1215),happy=(635,920,960,1215))
}
# Windows are confined to facial paper, away from silhouette, crown and framework.
WINDOWS={'mata-verde':(.26,.43,.76,.76),'azulao':(.23,.36,.80,.65),'raio-de-sol':(.23,.39,.80,.70),'rabbito':(.37,.34,.92,.87)}

for species,boxes in BOXES.items():
 folder=ROOT/species/'color-rig'; source=Image.open(folder/'source.png').convert('RGBA')
 s=source.width/1280; crops={}; measured={}
 for part,box in boxes.items():
  absolute=tuple(round(v*s) for v in box); im=source.crop(absolute)
  # Ignore only nearly invisible fringe when measuring; preserve pixels inside the crop.
  bbox=im.getchannel('A').point(lambda a:255 if a>12 else 0).getbbox()
  if not bbox: raise ValueError((species,part,'empty'))
  im=im.crop(bbox)
  if species=='rabbito' and part=='earNear':
   # This source slot includes a detached fringe from the neighbouring head.
   # Keep the actual connected ear, rather than importing that unrelated fragment.
   alpha=im.getchannel('A'); todo={(x,y) for y in range(im.height) for x in range(im.width) if alpha.getpixel((x,y))>12}; components=[]
   while todo:
    start=todo.pop(); group={start}; stack=[start]
    while stack:
     x,y=stack.pop()
     for n in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
      if n in todo:todo.remove(n);group.add(n);stack.append(n)
    components.append(group)
   keep=max(components,key=len); pixels=im.load()
   for y in range(im.height):
    for x in range(im.width):
     if (x,y) not in keep:pixels[x,y]=(0,0,0,0)
  crops[part]=im
  measured[part]=[absolute[0]+bbox[0],absolute[1]+bbox[1],im.width,im.height]
  if part not in ('fierce','hurt','happy'): im.save(folder/(part+'.png'))
 face='head' if species=='rabbito' else 'body'; base=crops[face]; w,h=base.size
 window=tuple(round(v*(w if i%2==0 else h)) for i,v in enumerate(WINDOWS[species]))
 mask=Image.new('L',base.size); inner=Image.new('L',(window[2]-window[0],window[3]-window[1]))
 ImageDraw.Draw(inner).rounded_rectangle((5,5,inner.width-6,inner.height-6),radius=12,fill=255)
 inner=inner.filter(ImageFilter.GaussianBlur(2)); mask.paste(inner,window[:2]); mask.save(folder/'face-mask.png')
 report={}
 for expression in ('fierce','hurt','happy'):
  candidate=crops[expression].resize(base.size,Image.Resampling.LANCZOS)
  result=Image.composite(candidate,base,mask); result.putalpha(base.getchannel('A'))
  pixels=list(zip(base.getdata(),result.getdata(),mask.getdata()))
  assert all(a[3]==b[3] for a,b,m in pixels)
  assert all(a==b for a,b,m in pixels if m==0)
  file=folder/(face+'-'+expression+'.png');result.save(file)
  report[expression]={'alpha_identical':True,'outside_face_identical':True,'changed_pixels':sum(a!=b for a,b,m in pixels),'sha256':hashlib.sha256(file.read_bytes()).hexdigest()}
 strip=Image.new('RGBA',(w*4,h))
 for i,exp in enumerate(('normal','fierce','hurt','happy')):
  im=base if exp=='normal' else Image.open(folder/(face+'-'+exp+'.png'))
  strip.alpha_composite(im,(i*w,0))
 strip.save(folder/'expressions-review.png')
 manifest={'sourceSize':source.size,'sourceRects':measured,'facialPart':face,'faceWindow':[window[0],window[1],window[2]-window[0],window[3]-window[1]],'expressions':report,'sizes':{p:im.size for p,im in crops.items() if p not in ('fierce','hurt','happy')}}
 (folder/'registration.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
 print(species,manifest['sizes'])
