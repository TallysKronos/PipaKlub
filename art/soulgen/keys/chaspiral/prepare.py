"""Normalize measured ImageGen pieces; register only eye/brow windows, never repaint anatomy."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter,ImageChops
import json,hashlib
ROOT=Path(__file__).resolve().parent/'color-rig-v2'
BOXES={'body':(28,68,383,461),'wingNear':(400,65,740,461),'wingFar':(747,92,1057,422),'armNear':(87,490,355,720),'armFar':(448,555,641,680),'tail':(784,487,1030,751)}
source=Image.open(ROOT/'source.png').convert('RGBA')
BOXES={name:tuple(round(v*(source.width/1080 if i%2==0 else source.height/1440)) for i,v in enumerate(box)) for name,box in BOXES.items()}

def isolate(box):
    crop=source.crop(box);alpha=crop.getchannel('A')
    remaining={(x,y) for y in range(crop.height) for x in range(crop.width) if alpha.getpixel((x,y))>12}
    groups=[]
    while remaining:
        start=remaining.pop();stack=[start];group=[start]
        while stack:
            x,y=stack.pop()
            for q in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if q in remaining:remaining.remove(q);stack.append(q);group.append(q)
        groups.append(group)
    mask=Image.new('L',crop.size)
    for q in max(groups,key=len):mask.putpixel(q,255)
    mask=mask.filter(ImageFilter.MaxFilter(3))
    out=Image.new('RGBA',crop.size);out.paste(crop,(0,0),mask)
    bbox=out.getbbox();out=out.crop(bbox)
    return out,[box[0]+bbox[0],box[1]+bbox[1],out.width,out.height]

images={};measured={}
for name,box in BOXES.items():
    images[name],measured[name]=isolate(box)
    if name not in ('fierce','hurt','happy'): images[name].save(ROOT/(name+'.png'))

base=images['body'];w,h=base.size
# Register eye patches from the expression studies without importing their wings/body.
scaleX=source.width/1080;scaleY=source.height/1440
origin=measured['body']
targets=[(151,242,207,297),(225,263,270,300)]
windows=[]
for box in targets:
 x1,y1,x2,y2=[round(v*(scaleX if i%2==0 else scaleY)) for i,v in enumerate(box)];windows.append([x1-origin[0],y1-origin[1],x2-x1,y2-y1])
mask=Image.new('L',base.size)
for x,y,pw,ph in windows:ImageDraw.Draw(mask).rounded_rectangle((x,y,x+pw-1,y+ph-1),radius=3,fill=255)
mask.save(ROOT/'face-mask.png');expressions={}
patches={'fierce':[(171,888,211,920),(230,909,265,940)],'hurt':[(531,891,573,924),(588,914,626,943)],'happy':[(890,899,931,933),(943,919,984,948)]}
for face,boxes in patches.items():
 variant=base.copy()
 for box,(x,y,pw,ph) in zip(boxes,windows):
  box=tuple(round(v*(scaleX if i%2==0 else scaleY)) for i,v in enumerate(box));patch=source.crop(box).resize((pw,ph),Image.Resampling.LANCZOS);variant.paste(patch,(x,y))
 result=Image.composite(variant,base,mask);result.putalpha(base.getchannel('A'));result.save(ROOT/('body-'+face+'.png'))
 assert ImageChops.difference(base.getchannel('A'),result.getchannel('A')).getbbox() is None
 changed=outside=0
 for y in range(h):
  for x in range(w):
   diff=base.getpixel((x,y))!=result.getpixel((x,y));changed+=diff
   if not mask.getpixel((x,y)):outside+=diff
 assert outside==0
 expressions[face]={'alpha_identical':True,'outside_face_identical':True,'changed_pixels':changed}
registration={'source_size':source.size,'sha256':hashlib.sha256((ROOT/'source.png').read_bytes()).hexdigest(),'crops':measured,'windows':windows,'expressions':expressions}
(ROOT/'registration.json').write_text(json.dumps(registration,indent=2)+'\n',encoding='utf-8')

# Corrected expressions generated directly from the canonical body, not assembled poses.
expressionSource=Image.open(ROOT/'expressions-source-v2.png').convert('RGBA')
for face,box in [('fierce',(0,0,expressionSource.width//2,expressionSource.height)),('happy',(expressionSource.width//2,0,expressionSource.width,expressionSource.height))]:
 piece=expressionSource.crop(box);piece=piece.crop(piece.getchannel('A').point(lambda a:255 if a>12 else 0).getbbox());variant=piece.resize(base.size,Image.Resampling.LANCZOS)
 result=Image.composite(variant,base,mask);result.putalpha(base.getchannel('A'));result.save(ROOT/('body-'+face+'.png'))
 assert ImageChops.difference(base.getchannel('A'),result.getchannel('A')).getbbox() is None
 for y in range(h):
  for x in range(w):
   if not mask.getpixel((x,y)):assert base.getpixel((x,y))==result.getpixel((x,y))
 registration['expressions'][face]['source']='expressions-source-v2.png'
(ROOT/'registration.json').write_text(json.dumps(registration,indent=2)+'\n',encoding='utf-8')
