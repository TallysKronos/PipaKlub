"""Normalize measured ImageGen pieces; register only eye/brow windows, never repaint anatomy."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter,ImageChops
import json,hashlib
ROOT=Path(__file__).resolve().parent/'color-rig-v2'
BOXES={'body':(20,85,355,320),'headCenter':(375,15,645,320),'headFar':(685,50,960,320),'headNear':(1005,50,1275,320),'frontNear':(35,350,290,610),'frontFar':(435,410,630,610),'hindNear':(725,360,970,610),'hindFar':(1050,410,1260,610),'tail':(15,620,355,980),'centerFierce':(375,660,650,960),'farFierce':(685,675,960,960),'nearFierce':(1005,675,1275,960),'centerHurt':(50,970,335,1275),'centerHappy':(375,970,650,1275),'farHappy':(685,1000,960,1275),'nearHappy':(1005,1000,1275,1275)}
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
for name,box in BOXES.items():images[name],measured[name]=isolate(box)
for name in ('body','headCenter','headFar','headNear','frontNear','frontFar','hindNear','hindFar','tail'):images[name].save(ROOT/(name+'.png'))
expressions={};windows={}
for key,variants in [('headCenter',{'Fierce':'centerFierce','Hurt':'centerHurt','Happy':'centerHappy'}),('headFar',{'Fierce':'farFierce','Happy':'farHappy'}),('headNear',{'Fierce':'nearFierce','Happy':'nearHappy'})]:
 base=images[key];w,h=base.size
 window=(round(w*.30),round(h*.44),round(w*.85),round(h*.66))
 mask=Image.new('L',base.size);ImageDraw.Draw(mask).rounded_rectangle(window,radius=3,fill=255);mask=mask.filter(ImageFilter.GaussianBlur(.5));mask.save(ROOT/(key+'-face-mask.png'));windows[key]=[[window[0],window[1],window[2]-window[0],window[3]-window[1]]]
 for face,sourceKey in variants.items():
  variant=images[sourceKey].resize(base.size,Image.Resampling.LANCZOS);result=Image.composite(variant,base,mask);result.putalpha(base.getchannel('A'));result.save(ROOT/(key+face+'.png'))
  outside=changed=0
  for y in range(h):
   for x in range(w):
    diff=result.getpixel((x,y))!=base.getpixel((x,y));changed+=diff
    if not mask.getpixel((x,y)):outside+=diff
  assert outside==0
  assert ImageChops.difference(base.getchannel('A'),result.getchannel('A')).getbbox() is None
  expressions[key+face]={'alpha_identical':True,'outside_face_identical':True,'changed_pixels':changed}
registration={'source_size':source.size,'sha256':hashlib.sha256((ROOT/'source.png').read_bytes()).hexdigest(),'crops':measured,'windows':windows,'expressions':expressions}
(ROOT/'registration.json').write_text(json.dumps(registration,indent=2)+'\n',encoding='utf-8')
print('Measured',len(measured),'pieces;',len(expressions),'registered expressions')

# ImageGen repaired torso: deterministic alpha crop only, no painted anatomy.
repair=Image.open(ROOT/'body-repair-source.png').convert('RGBA');repair=repair.crop(repair.getbbox());repair.save(ROOT/'body.png')

# Torso-only kite revision requested by the author; keep prior sources intact.
kite=Image.open(ROOT/'body-kite-source.png').convert('RGBA');kite=kite.crop(kite.getbbox());kite.save(ROOT/'body.png')
