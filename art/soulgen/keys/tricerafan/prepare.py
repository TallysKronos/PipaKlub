"""Measured cutouts, proportional placement and canonical-alpha expression swaps."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageChops
import json, hashlib
ROOT=Path(__file__).resolve().parent/'color-rig-v2'
source=Image.open(ROOT/'seamless-source.png').convert('RGBA')
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
    assert bbox and bbox[0]>0 and bbox[1]>0 and bbox[2]<crop.width and bbox[3]<crop.height, ('Cut touches boundary',box,bbox)
    return crop.crop(bbox),[box[0]+bbox[0],box[1]+bbox[1],bbox[2]-bbox[0],bbox[3]-bbox[1]]
images={};crops={}
for name,box in {'body':(.025,.10,.415,.33),'head':(.415,.12,.71,.34),'sail':(.71,.055,.99,.35),'frontNear':(.08,.35,.25,.54),'frontFar':(.43,.35,.59,.54),'hindNear':(.74,.35,.91,.54),'hindFar':(.09,.55,.25,.74),'tail':(.31,.58,.64,.74),'fierce':(.66,.55,.96,.75),'hurt':(.025,.77,.31,.97),'happy':(.315,.77,.61,.97)}.items():
    images[name],crops[name]=cut(source,box)
for name in ['body','head','sail','frontNear','frontFar','hindNear','hindFar','tail']:images[name].save(ROOT/(name+'.png'))
base=images['head'];w,h=base.size
windows=[[round(w*.53),round(h*.49),round(w*.18),round(h*.25)]]
mask=Image.new('L',base.size)
for x,y,ww,hh in windows:ImageDraw.Draw(mask).rounded_rectangle((x,y,x+ww,y+hh),radius=6,fill=255)
mask=mask.filter(ImageFilter.GaussianBlur(1))
mask.save(ROOT/'face-mask.png')
expressions={}
for face in ['fierce','hurt','happy']:
    variant=images[face].resize(base.size,Image.Resampling.LANCZOS)
    result=Image.composite(variant,base,mask);result.putalpha(base.getchannel('A'))
    result.save(ROOT/('head-'+face+'.png'))
    changed=sum(a!=b for a,b in zip(base.getdata(),result.getdata()))
    assert ImageChops.difference(base.getchannel('A'),result.getchannel('A')).getbbox() is None
    expressions[face]={'alpha_identical':True,'outside_face_identical':True,'changed_pixels':changed}
registration={'source_size':source.size,'head_source_size':heads.size,'sha256':hashlib.sha256((ROOT/'seamless-source.png').read_bytes()).hexdigest(),'crops':crops,'windows':windows,'expressions':expressions}
(ROOT/'registration.json').write_text(json.dumps(registration,indent=2)+'\n',encoding='utf-8')
print(json.dumps(crops))
