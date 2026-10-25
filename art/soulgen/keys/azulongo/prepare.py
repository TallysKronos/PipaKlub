"""Measured cutouts, proportional placement and canonical-alpha expression swaps."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageChops
import json, hashlib
ROOT=Path(__file__).resolve().parent/'color-rig-v2'
source=Image.open(ROOT/'body-chibi-source.png').convert('RGBA')
heads=Image.open(ROOT/'head-chibi-source.png').convert('RGBA')
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
for name,box in {'body':(0,0,.60,.55),'armNear':(.62,.10,1,.50),'armFar':(.05,.57,.45,.95),'tail':(.49,.56,1,.96)}.items():
    images[name],crops[name]=cut(source,box)
for name,box in {'head':(0,0,.505,.50),'fierce':(.505,0,1,.50),'hurt':(0,.50,.505,1),'happy':(.505,.50,1,1)}.items():
    images[name],crops[name]=cut(heads,box)
for name in ['body','head','armNear','armFar','tail']: images[name].save(ROOT/(name+'.png'))
base=images['head'];w,h=base.size
# Two feathered eye/brow windows; mouth and whiskers remain canonical.
windows=[[round(w*.49),round(h*.41),round(w*.21),round(h*.22)],[round(w*.70),round(h*.42),round(w*.12),round(h*.22)]]
mask=Image.new('L',base.size)
for x,y,ww,hh in windows:
    ImageDraw.Draw(mask).rounded_rectangle((x,y,x+ww,y+hh),radius=12,fill=255)
mask=mask.filter(ImageFilter.GaussianBlur(3))
mask.save(ROOT/'face-mask.png')
expressions={}
for face in ['fierce','hurt','happy']:
    variant=images[face].resize(base.size,Image.Resampling.LANCZOS)
    result=Image.composite(variant,base,mask);result.putalpha(base.getchannel('A'))
    result.save(ROOT/('head-'+face+'.png'))
    changed=sum(a!=b for a,b in zip(base.getdata(),result.getdata()))
    assert ImageChops.difference(base.getchannel('A'),result.getchannel('A')).getbbox() is None
    expressions[face]={'alpha_identical':True,'outside_face_identical':True,'changed_pixels':changed}
registration={'source_size':source.size,'head_source_size':heads.size,'sha256':hashlib.sha256((ROOT/'body-chibi-source.png').read_bytes()).hexdigest(),'crops':crops,'windows':windows,'expressions':expressions}
(ROOT/'registration.json').write_text(json.dumps(registration,indent=2)+'\n',encoding='utf-8')
print(json.dumps(crops))




