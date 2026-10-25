"""Measured cutouts, proportional placement and canonical-alpha expression swaps."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageChops
import json, hashlib
ROOT=Path(__file__).resolve().parent/'color-rig-v2'
source=Image.open(ROOT/'source.png').convert('RGBA')
heads=source
def cut(image,box):
    box=tuple(round(v*image.size[i%2]) for i,v in enumerate(box))
    crop=image.crop(box)
    alpha=crop.getchannel('A')
    remaining={(x,y) for y in range(crop.height) for x in range(crop.width) if alpha.getpixel((x,y))>20}
    groups=[]
    while remaining:
        start=remaining.pop();stack=[start];group=[start]
        while stack:
            x,y=stack.pop()
            for q in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
                if q in remaining: remaining.remove(q);stack.append(q);group.append(q)
        groups.append(group)
    mask=Image.new('L',crop.size)
    for q in max(groups,key=len):mask.putpixel(q,255)
    mask=mask.filter(ImageFilter.MaxFilter(3))
    clean=Image.new('RGBA',crop.size);clean.paste(crop,(0,0),mask);crop=clean
    bbox=crop.getchannel('A').getbbox()
    assert bbox and (box[1]>source.height*.65 or (bbox[0]>0 and bbox[1]>0 and bbox[2]<crop.width and bbox[3]<crop.height)), ('Cut touches boundary',box,bbox)
    return crop.crop(bbox),[box[0]+bbox[0],box[1]+bbox[1],bbox[2]-bbox[0],bbox[3]-bbox[1]]
images={};crops={}
for name,box in {'body':(.015,.005,.305,.36),'wingNear':(.308,.005,.667,.36),'wingFar':(.675,.025,.995,.36),'footNear':(.065,.40,.305,.63),'footFar':(.39,.40,.605,.63),'tail':(.61,.38,.995,.66),'fierce':(.01,.66,.31,.999),'hurt':(.345,.66,.64,.999),'happy':(.675,.66,.98,.999)}.items():
    images[name],crops[name]=cut(source,box)
for name in ['body','wingNear','wingFar','footNear','footFar','tail']:images[name].save(ROOT/(name+'.png'))
base=images['body'];w,h=base.size
windows=[[round(w*.55),round(h*.24),round(w*.25),round(h*.25)]]
mask=Image.new('L',base.size)
for x,y,ww,hh in windows:ImageDraw.Draw(mask).rounded_rectangle((x,y,x+ww,y+hh),radius=6,fill=255)
mask=mask.filter(ImageFilter.GaussianBlur(1))
mask.save(ROOT/'face-mask.png')
expressions={}
for face in ['fierce','hurt','happy']:
    variant=images[face].resize(base.size,Image.Resampling.LANCZOS)
    result=Image.composite(variant,base,mask);result.putalpha(base.getchannel('A'))
    result.save(ROOT/('body-'+face+'.png'))
    changed=sum(a!=b for a,b in zip(base.getdata(),result.getdata()))
    assert ImageChops.difference(base.getchannel('A'),result.getchannel('A')).getbbox() is None
    expressions[face]={'alpha_identical':True,'outside_face_identical':True,'changed_pixels':changed}
registration={'source_size':source.size,'head_source_size':heads.size,'sha256':hashlib.sha256((ROOT/'source.png').read_bytes()).hexdigest(),'crops':crops,'windows':windows,'expressions':expressions}
(ROOT/'registration.json').write_text(json.dumps(registration,indent=2)+'\n',encoding='utf-8')
print(json.dumps(crops))
