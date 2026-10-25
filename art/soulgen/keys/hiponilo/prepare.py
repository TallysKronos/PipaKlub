"""Normalize measured ImageGen pieces; register only eye/brow windows, never repaint anatomy."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter,ImageChops
import json,hashlib
ROOT=Path(__file__).resolve().parent/'color-rig-v2'
BOXES={'body':(15,180,405,440),'head':(410,185,695,450),'sail':(695,85,1080,440),'frontNear':(80,480,320,750),'frontFar':(460,530,665,754),'tail':(735,455,1065,775),'hindNear':(60,800,315,1080),'hindFar':(445,850,666,1080),'fierce':(755,800,1070,1095),'hurt':(65,1110,370,1395),'happy':(415,1110,725,1395)}
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

base=images['head'];w,h=base.size
# Eyes and eyebrows only. Nose, muzzle, ears, neck silhouette and all alpha stay canonical.
window=(round(w*.35),round(h*.34),round(w*.88),round(h*.51))
mask=Image.new('L',base.size)
ImageDraw.Draw(mask).rounded_rectangle(window,radius=4,fill=255)
mask=mask.filter(ImageFilter.GaussianBlur(.5));mask.save(ROOT/'face-mask.png')
expressions={}
for face in ('fierce','hurt','happy'):
    variant=images[face].resize(base.size,Image.Resampling.LANCZOS)
    if face=='fierce':
        scaled=images[face].resize((w,round(images[face].height*w/images[face].width)),Image.Resampling.LANCZOS);variant=base.copy();variant.paste(scaled,(round(w*.02),round(h*.07)))
    result=Image.composite(variant,base,mask);result.putalpha(base.getchannel('A'))
    result.save(ROOT/('head-'+face+'.png'))
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

core=Image.open(ROOT/'body-core-source.png').convert('RGBA');core=core.crop(core.getchannel('A').point(lambda a:255 if a>12 else 0).getbbox());core.save(ROOT/'body.png')

# Dedicated canonical-head expressions avoid the open-mouth study's registration drift.
expr=Image.open(ROOT/'expressions-source.png').convert('RGBA')
mask=Image.new('L',base.size);window=(round(w*.32),round(h*.27),round(w*.89),round(h*.51));ImageDraw.Draw(mask).rounded_rectangle(window,radius=4,fill=255);mask.save(ROOT/'face-mask.png')
for face,box in [('fierce',(0,0,expr.width//2,expr.height)),('happy',(expr.width//2,0,expr.width,expr.height))]:
 part=expr.crop(box);part=part.crop(part.getchannel('A').point(lambda a:255 if a>12 else 0).getbbox());variant=part.resize(base.size,Image.Resampling.LANCZOS);result=Image.composite(variant,base,mask);result.putalpha(base.getchannel('A'));result.save(ROOT/('head-'+face+'.png'))
 assert ImageChops.difference(base.getchannel('A'),result.getchannel('A')).getbbox() is None
 for y in range(h):
  for x in range(w):
   if not mask.getpixel((x,y)):assert result.getpixel((x,y))==base.getpixel((x,y))
 registration['expressions'][face]['source']='expressions-source.png'
registration['windows']=[[window[0],window[1],window[2]-window[0],window[3]-window[1]]]
(ROOT/'registration.json').write_text(json.dumps(registration,indent=2)+'\n',encoding='utf-8')
