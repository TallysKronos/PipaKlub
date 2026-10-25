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
    assert bbox and bbox[0]>0 and bbox[1]>0 and bbox[2]<crop.width and bbox[3]<crop.height, ('Cut touches boundary',box,bbox)
    return crop.crop(bbox),[box[0]+bbox[0],box[1]+bbox[1],bbox[2]-bbox[0],bbox[3]-bbox[1]]
images={};crops={}
for name,box in {'body':(.035,.01,.34,.26),'head':(.39,.02,.67,.26),'sail':(.74,.01,.95,.26),'frontNear':(.07,.28,.32,.49),'frontFar':(.42,.30,.65,.49),'hindNear':(.75,.25,.94,.51),'hindFar':(.105,.50,.31,.75),'tail':(.34,.54,.67,.75),'fierce':(.70,.54,.98,.76),'hurt':(.055,.775,.33,.995),'happy':(.37,.775,.65,.995)}.items():
    images[name],crops[name]=cut(Image.open(ROOT/'source-closed-torso.png').convert('RGBA') if name=='body' else source,box)
for name in ['body','head','sail','frontNear','frontFar','hindNear','hindFar','tail']:images[name].save(ROOT/(name+'.png'))
base=images['head'];w,h=base.size
windows=[[round(w*.55),round(h*.22),round(w*.19),round(h*.22)]]
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
registration={'source_size':source.size,'head_source_size':heads.size,'sha256':hashlib.sha256((ROOT/'source.png').read_bytes()).hexdigest(),'crops':crops,'windows':windows,'expressions':expressions}
(ROOT/'registration.json').write_text(json.dumps(registration,indent=2)+'\n',encoding='utf-8')
print(json.dumps(crops))
