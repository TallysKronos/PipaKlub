"""Measured crops and registration only. Anatomy and expressions come from ImageGen."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageChops
import json, hashlib
ROOT=Path(__file__).resolve().parent/'color-rig-v2'
BOXES={'body':(40,20,455,435),'armNear':(500,100,840,400),'armFar':(920,100,1240,400),'legNear':(70,480,350,790),'legFar':(490,480,760,790),'fierce':(830,430,1265,840),'hurt':(15,825,435,1260),'happy':(440,825,865,1260)}
source=Image.open(ROOT/'source.png').convert('RGBA')
assert source.width==source.height,source.size
BOXES={name:tuple(round(value*source.width/1280) for value in box) for name,box in BOXES.items()}

def isolate(box):
    crop=source.crop(box)
    alpha=crop.getchannel('A')
    remaining={(x,y) for y in range(crop.height) for x in range(crop.width) if alpha.getpixel((x,y))>12}
    groups=[]
    while remaining:
        start=remaining.pop();stack=[start];group=[start]
        while stack:
            x,y=stack.pop()
            for q in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if q in remaining: remaining.remove(q);stack.append(q);group.append(q)
        groups.append(group)
    group=max(groups,key=len)
    # Keep antialiasing around the measured main component without neighbouring pieces.
    mask=Image.new('L',crop.size)
    for point in group: mask.putpixel(point,255)
    mask=mask.filter(ImageFilter.MaxFilter(3))
    out=Image.new('RGBA',crop.size);out.paste(crop,(0,0),mask)
    bbox=out.getbbox();out=out.crop(bbox)
    return out,[box[0]+bbox[0],box[1]+bbox[1],out.width,out.height]

def turquoise_bounds(im):
    pixels=[]
    for y in range(im.height):
        for x in range(im.width):
            r,g,b,a=im.getpixel((x,y))
            if a>220 and g>r*1.30 and b>r*1.25 and g>65: pixels.append((x,y))
    assert len(pixels)>500
    return (min(x for x,y in pixels),min(y for x,y in pixels),max(x for x,y in pixels)+1,max(y for x,y in pixels)+1)

images={};measurements={}
for name,box in BOXES.items():
    images[name],measurements[name]=isolate(box)
    if name not in ('fierce','hurt','happy'): images[name].save(ROOT/(name+'.png'))

base=images['body'];face=turquoise_bounds(base)
x0,y0,x1,y1=face;w=x1-x0;h=y1-y0
# A fixed interior face window protects all cord strands, repair, loops and outer silhouette.
window=(round(x0+w*.20),round(y0+h*.06),round(x0+w*.98),round(y0+h*.93))
mask=Image.new('L',base.size)
ImageDraw.Draw(mask).rounded_rectangle(window,radius=6,fill=255)
mask=mask.filter(ImageFilter.GaussianBlur(.6))
mask.save(ROOT/'face-mask.png')
expressions={}
for name in ('fierce','hurt','happy'):
    variant=images[name];vb=turquoise_bounds(variant)
    registered=base.copy()
    patch=variant.crop(vb).resize((w,h),Image.Resampling.LANCZOS)
    registered.paste(patch,(x0,y0))
    result=Image.composite(registered,base,mask)
    result.putalpha(base.getchannel('A'))
    result.save(ROOT/('body-'+name+'.png'))
    difference=ImageChops.difference(base,result)
    outside=ImageChops.multiply(difference.convert('RGB').convert('L'),ImageChops.invert(mask.point(lambda a:255 if a else 0)))
    assert outside.getbbox() is None
    assert ImageChops.difference(base.getchannel('A'),result.getchannel('A')).getbbox() is None
    expressions[name]={'alpha_identical':True,'outside_face_identical':True,'changed_pixels':sum(base.getpixel((x,y))!=result.getpixel((x,y)) for y in range(base.height) for x in range(base.width)),'source_face_bounds':vb}

registration={'source_size':source.size,'source_sha256':hashlib.sha256((ROOT/'source.png').read_bytes()).hexdigest(),'crops':measurements,'face_bounds':face,'windows':[[window[0],window[1],window[2]-window[0],window[3]-window[1]]],'expressions':expressions}
(ROOT/'registration.json').write_text(json.dumps(registration,indent=2)+'\n',encoding='utf-8')
print(json.dumps(registration,indent=2))
