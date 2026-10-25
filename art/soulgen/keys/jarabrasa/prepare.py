"""Normalize measured ImageGen pieces; register only eye/brow windows, never repaint anatomy."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter,ImageChops
import json,hashlib
ROOT=Path(__file__).resolve().parent/'color-rig-v2'
BOXES={'body':(190,20,535,462),'wingNear':(620,65,905,432),'wingFar':(985,65,1260,432),'tail':(20,505,492,870),'fierce':(525,455,870,887),'hurt':(930,455,1280,887),'happy':(120,810,462,1210)}
source=Image.open(ROOT/'source.png').convert('RGBA')
BOXES={name:tuple(round(v*(source.width/1280 if i%2==0 else source.height/1280)) for i,v in enumerate(box)) for name,box in BOXES.items()}

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

# A component touching the sampling window may have been truncated before export.
tailBox=BOXES['tail'];tx,ty,tw,th=measured['tail']
assert tx>tailBox[0] and ty>tailBox[1] and tx+tw<tailBox[2] and ty+th<tailBox[3], 'Tail touches crop window; expand it before exporting'
base=images['body'];w,h=base.size
# Eyes and eyebrows only. Nose, muzzle, ears, neck silhouette and all alpha stay canonical.
window=(round(w*.48),round(h*.26),round(w*.98),round(h*.41))
mask=Image.new('L',base.size)
ImageDraw.Draw(mask).rounded_rectangle(window,radius=4,fill=255)
mask=mask.filter(ImageFilter.GaussianBlur(.5));mask.save(ROOT/'face-mask.png')
expressions={}
for face in ('fierce','hurt','happy'):
    variant=images[face].resize(base.size,Image.Resampling.LANCZOS)
    result=Image.composite(variant,base,mask);result.putalpha(base.getchannel('A'))
    result.save(ROOT/('body-'+face+'.png'))
    changed=outside=0
    for y in range(h):
        for x in range(w):
            diff=base.getpixel((x,y))!=result.getpixel((x,y))
            changed+=diff
            if not mask.getpixel((x,y)): outside+=diff
    assert outside==0
    assert ImageChops.difference(base.getchannel('A'),result.getchannel('A')).getbbox() is None
    expressions[face]={'alpha_identical':True,'outside_face_identical':True,'changed_pixels':changed,'nose_muzzle_ears_preserved':True}

registration={'source_size':source.size,'sha256':hashlib.sha256((ROOT/'source.png').read_bytes()).hexdigest(),'crops':measured,'windows':[[window[0],window[1],window[2]-window[0],window[3]-window[1]]],'expressions':expressions}
(ROOT/'registration.json').write_text(json.dumps(registration,indent=2)+'\n',encoding='utf-8')
print(json.dumps(registration,indent=2))

# Dedicated same-pose expressions; replace only the two eye regions.
expr=Image.open(ROOT/'expressions-source.png').convert('RGBA');windows=[[180,109,79,62],[283,122,35,40]];mask=Image.new('L',base.size)
for x,y,pw,ph in windows:ImageDraw.Draw(mask).rounded_rectangle((x,y,x+pw-1,y+ph-1),radius=4,fill=255)
mask=mask.filter(ImageFilter.GaussianBlur(.5));mask.save(ROOT/'face-mask.png')
for index,face in enumerate(['fierce','hurt','happy']):
 part=expr.crop((index*expr.width//3,0,(index+1)*expr.width//3,expr.height));part=part.crop(part.getchannel('A').point(lambda a:255 if a>12 else 0).getbbox());variant=part.resize(base.size,Image.Resampling.LANCZOS);aligned=base.copy();aligned.paste(variant,(0,7));variant=aligned;result=Image.composite(variant,base,mask);result.putalpha(base.getchannel('A'));result.save(ROOT/('body-'+face+'.png'))
 changed=outside=0
 for y in range(h):
  for x in range(w):
   diff=result.getpixel((x,y))!=base.getpixel((x,y));changed+=diff
   if not mask.getpixel((x,y)):outside+=diff
 assert outside==0
 assert ImageChops.difference(base.getchannel('A'),result.getchannel('A')).getbbox() is None
 registration['expressions'][face]={'source':'expressions-source.png','alpha_identical':True,'outside_face_identical':True,'changed_pixels':changed}
registration['windows']=windows
(ROOT/'registration.json').write_text(json.dumps(registration,indent=2)+'\n',encoding='utf-8')
