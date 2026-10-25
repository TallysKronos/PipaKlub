"""Normalize measured ImageGen pieces; register only eye/brow windows, never repaint anatomy."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter,ImageChops
import json,hashlib
ROOT=Path(__file__).resolve().parent/'color-rig-v2'
BOXES={'body':(15,70,439,381),'head':(431,0,713,420),'sail':(703,35,1080,370),'frontNear':(95,370,335,730),'frontFar':(440,373,650,730),'tail':(650,365,1080,745),'hindNear':(150,730,350,1065),'hindFar':(485,730,650,1070),'fierce':(742,716,1045,1130),'hurt':(50,1060,365,1440),'happy':(397,1055,715,1440)}
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
window=(round(w*.60),round(h*.39),round(w*.95),round(h*.62))
mask=Image.new('L',base.size)
ImageDraw.Draw(mask).rounded_rectangle(window,radius=4,fill=255)
mask=mask.filter(ImageFilter.GaussianBlur(.5));mask.save(ROOT/'face-mask.png')
expressions={}
for face in ('fierce','hurt','happy'):
    variant=images[face].resize(base.size,Image.Resampling.LANCZOS)
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
