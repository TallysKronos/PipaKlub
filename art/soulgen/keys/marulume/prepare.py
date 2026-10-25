"""Normalize measured ImageGen pieces; register only eye/brow windows, never repaint anatomy."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter,ImageChops
import json,hashlib
ROOT=Path(__file__).resolve().parent/'color-rig-v2'
BOXES={'body':(85,45,458,465),'wingNear':(547,185,860,408),'wingFar':(971,200,1215,400),'tail':(40,490,445,870),'fierce':(495,475,855,886),'hurt':(908,475,1270,886),'happy':(80,875,450,1265)}
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

base=images['body'];w,h=base.size
# Eyes and eyebrows only. Nose, muzzle, ears, neck silhouette and all alpha stay canonical.
window=(round(w*.51),round(h*.29),round(w*.91),round(h*.44))
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

# Register dedicated same-pose expressions using fixed art coordinates, not varying bounds.
expr=Image.open(ROOT/'expressions-source-v2.png').convert('RGBA')
windows=[[169,109,69,71],[275,122,42,54]]
mask=Image.new('L',base.size)
for x,y,pw,ph in windows:ImageDraw.Draw(mask).rounded_rectangle((x,y,x+pw-1,y+ph-1),radius=5,fill=255)
mask=mask.filter(ImageFilter.GaussianBlur(.6));mask.save(ROOT/'face-mask.png')
for face,left in [('fierce',0),('hurt',630),('happy',1256)]:
 variant=expr.crop((left,0,left+664,784)).resize(base.size,Image.Resampling.LANCZOS)
 result=Image.composite(variant,base,mask);result.putalpha(base.getchannel('A'));result.save(ROOT/('body-'+face+'.png'))
 changed=outside=0
 for y in range(h):
  for x in range(w):
   diff=result.getpixel((x,y))!=base.getpixel((x,y));changed+=diff
   if not mask.getpixel((x,y)):outside+=diff
 assert outside==0
 assert ImageChops.difference(base.getchannel('A'),result.getchannel('A')).getbbox() is None
 registration['expressions'][face]={'source':'expressions-source-v2.png','alpha_identical':True,'outside_face_identical':True,'changed_pixels':changed}
registration['windows']=windows
(ROOT/'registration.json').write_text(json.dumps(registration,indent=2)+'\n',encoding='utf-8')
