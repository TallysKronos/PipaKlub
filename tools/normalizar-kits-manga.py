#!/usr/bin/env python3
"""Normalize approved 2D manga art masters to the existing Kronasta kit contracts."""
import argparse
import importlib.util
import json
from pathlib import Path
from statistics import median

from PIL import Image, ImageDraw

REPO=Path(__file__).resolve().parents[1]
SOURCE=REPO/'documentation/qa/kits-tiles-v1/revisao-manga'
KITS=REPO/'godot/assets/overworld/kits'
spec=importlib.util.spec_from_file_location('pilot',REPO/'tools/normalizar-piloto-manga.py')
pilot=importlib.util.module_from_spec(spec)
spec.loader.exec_module(pilot)

def alpha_cut(im):
    alpha=im.getchannel('A').point(lambda a:255 if a>=128 else 0)
    im=Image.composite(im.convert('RGB').convert('RGBA'),Image.new('RGBA',im.size),alpha)
    box=alpha.getbbox()
    if not box or box==(0,0,*im.size):
        raise ValueError('sprite sem recorte transparente')
    return im.crop(box)

def base_points(a,b):
    return [(16*(b-a),-8*(a+b)),(16*(a+b),8*(a-b)),(16*(a-b),8*(a+b)),(-16*(a+b),8*(b-a))]

def fit_bridge(path):
    # Measure the painted lower deck corners in the full master: side tips
    # (193,722), (1147,722), and front (672,989).
    im=Image.open(path).convert('RGBA')
    cx,cy=36,50
    sx,sy=(1147-193)/64,(989-722)/16
    tx=193-(cx-32+.5)*sx
    ty=722-(cy+.5)*sy
    fit=im.transform((73,73),Image.Transform.AFFINE,(sx,0,tx,0,sy,ty),resample=Image.Resampling.BICUBIC)
    alpha=fit.getchannel('A').point(lambda v:255 if v>=106 else 0)
    fit=Image.composite(fit.convert('RGB').convert('RGBA'),Image.new('RGBA',fit.size),alpha)
    left,top,right,bottom=alpha.getbbox()
    box=(left-4,top-4,right+4,bottom+4)
    ax,ay=cx-box[0],cy-box[1]
    return fit.crop(box),[ax,ay],[[ax+x,ay+y] for x,y in base_points(1,1)]

def fit_stairs(path):
    # The master supplies the ink, concrete and cel colours. Project its
    # painted planes onto the exact eight-riser geometry used by the kit.
    master=Image.open(path).convert('RGBA')
    image=Image.new('RGBA',(124,132))
    ox,oy=62,102
    def point(u,v,z=0):
        return (round(ox+32*(u-v+.5)),round(oy+16*(u+v-1.5)-z))
    def texel(x,y):
        return master.getpixel((round(x*master.width/1294),round(y*master.height/1198)))
    def face(poly, source):
        (x0,y0),(x1,y1),_,(x3,y3)=poly
        (u0,v0),(u1,v1),(u3,v3)=[(x*master.width/1294,y*master.height/1198) for x,y in source]
        ax,ay,bx,by=x1-x0,y1-y0,x3-x0,y3-y0
        det=ax*by-ay*bx
        uv=[]
        for p0,p1,p3 in ((u0,u1,u3),(v0,v1,v3)):
            aa=((p1-p0)*by-(p3-p0)*ay)/det
            bb=((p3-p0)*ax-(p1-p0)*bx)/det
            uv.extend([aa,bb,p0-aa*x0-bb*y0])
        layer=master.transform(image.size,Image.Transform.AFFINE,uv,resample=Image.Resampling.BICUBIC)
        mask=Image.new('L',image.size)
        ImageDraw.Draw(mask).polygon(poly,fill=255)
        image.paste(layer,(0,0),mask)
    ink=texel(510,1019)
    ink=(70,63,62,255) if ink[3]<128 or min(ink[:3])>100 else ink
    for i in range(8):
        v=i/4
        z=(8-i)*8
        top=[point(0,v,z),point(1,v,z),point(1,v+.25,z),point(0,v+.25,z)]
        side=[top[1],top[2],point(1,v+.25),point(1,v)]
        riser=[top[3],top[2],point(1,v+.25,z-8),point(0,v+.25,z-8)]
        ImageDraw.Draw(image).polygon(side,fill=texel(990,645)[:3]+(255,))
        ImageDraw.Draw(image).polygon(riser,fill=texel(700,700)[:3]+(255,))
        # Two quiet variants avoid a mechanical highlight on every stair.
        patch=([(434,853),(539,903),(415,864)] if i%3 else
               [(338,823),(479,896),(320,833)])
        face(top,patch)
        ImageDraw.Draw(image).line([top[3],top[2]],fill=ink)
    ImageDraw.Draw(image).line([point(1,0),point(1,2)],fill=ink)
    box=image.getbbox()
    crop=(box[0]-4,box[1]-4,box[2]+4,box[3]+4)
    ax,ay=ox-crop[0],oy-crop[1]
    return alpha_cut_to_binary(image.crop(crop)),[ax,ay],[[ax+x,ay+y] for x,y in base_points(1,2)]

def alpha_cut_to_binary(im):
    alpha=im.getchannel('A').point(lambda v:255 if v>=106 else 0)
    return Image.composite(im.convert('RGB').convert('RGBA'),Image.new('RGBA',im.size),alpha)

def sprite(path, entry, name, calibration):
    if name=='ponte-corda':
        return fit_bridge(path)
    if name=='escadaria-cimento':
        return fit_stairs(path)
    im=alpha_cut(Image.open(path).convert('RGBA'))
    a,b=entry['footprint']; w,h=im.size
    points=base_points(a,b)
    expected_width=32*(a+b)
    alpha=im.getchannel('A')
    front_band=alpha.crop((0,h-max(3,h//100),w,h)).getbbox()
    front_x=(front_band[0]+front_band[2]-1)/2
    front_y=h-1
    # The corners of a support are in the lower part of the image, below
    # overhanging foliage, sails and fabric. A calibration can override
    # the measured pivots for a particular master without touching the art.
    band_y=round(h*(.66 if name not in {'feno','ponte-corda'} else .55))
    base=alpha.crop((0,band_y,w,h)).getbbox()
    left,right=base[0],base[2]-1
    if calibration:
        left,front_x,right,front_y=calibration
    scale=expected_width/max(1,right-left)
    # Preserve artist-drawn proportions; reserve room for overhanging art.
    scale=min(scale,(entry['fitReferenceSize'][1]+12)/h)
    size=(max(1,round(w*scale)),max(1,round(h*scale)))
    fit=im.resize(size,Image.Resampling.LANCZOS)
    # Place the front-most support point over the cell footprint's front corner.
    xoff=round(points[2][0]-front_x*size[0]/w)
    yoff=round(points[2][1]-front_y*size[1]/h)
    xs=[p[0] for p in points]+[xoff,xoff+fit.width]
    ys=[p[1] for p in points]+[yoff,yoff+fit.height]
    x0,y0=min(xs)-4,min(ys)-4
    out=Image.new('RGBA',(max(xs)-x0+5,max(ys)-y0+5))
    polygon=[(x-x0,y-y0) for x,y in points]
    if name!='escadaria-cimento':
        # Pixel-exact foundation under the painted prop. Pull the color from
        # the source's own ground contact so the join reads as one plinth.
        samples=[]
        py=im.load()
        for y in range(round(h*.84),h):
            for x in range(0,w,4):
                r,g,bv,al=py[x,y]
                if al and max(r,g,bv)<226:
                    samples.append((r,g,bv))
        fill=tuple(round(median(c)) for c in zip(*samples)) if samples else (113,100,85)
        ink=fill if name in {'arvore-solitaria','cristal-grande','cristal-pequeno','estalagmite','cogumelo-luz'} else tuple(round(c*.88) for c in fill)
        ImageDraw.Draw(out).polygon(polygon,fill=fill+(255,),outline=ink+(255,))
    out.alpha_composite(fit,(xoff-x0,yoff-y0))
    alpha=out.getchannel('A').point(lambda v:255 if v>=106 else 0)
    out=Image.composite(out.convert('RGB').convert('RGBA'),Image.new('RGBA',out.size),alpha)
    box=alpha.getbbox()
    crop=(box[0]-4,box[1]-4,box[2]+4,box[3]+4)
    result=out.crop(crop)
    ax,ay=-x0-crop[0],-y0-crop[1]
    return result,[ax,ay],[[ax+x,ay+y] for x,y in points]

def save_json(path,doc):
    path.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def main():
    cli=argparse.ArgumentParser(description=__doc__)
    cli.add_argument('kit',choices=['morro-v2','cavernas-cristal-v1','planicies-v1'])
    cli.add_argument('--only',help='Process only one ID')
    args=cli.parse_args()
    folder=KITS/args.kit
    sources=SOURCE/args.kit
    anchors=sources/'calibracao.json'
    calibration=json.loads(anchors.read_text(encoding='utf-8')) if anchors.exists() else {}
    lib=json.loads((folder/'library.json').read_text(encoding='utf-8'))
    index=json.loads((folder/'kit.json').read_text(encoding='utf-8'))
    for entry in lib['surfaces']:
        name=entry['id']
        path=sources/f'{name}.png'
        if not path.exists() or args.only and args.only!=name:
            continue
        accents={
            'campo-flor': '6D874C 78914F 879E53 95A65B AAB263 D2BB69',
            'cristal-chao': '453F5D 4C4665 554D71 5E567E 6D6690 7F8EA7',
        }
        palette=accents[name].split() if name in accents else None
        im=pilot.texture_file(path,6 if name in {'cristal-chao','parede-cristal','campo-flor'} else 5,palette)
        im.save(folder/entry['file'],optimize=True)
        entry['palette']=sorted(''.join(f'{v:02X}' for v in c) for _,c in im.getcolors())
        entry.update(colors=len(entry['palette']),source='image_gen; manga style revision')
        print(args.kit,name,'512 x 512',entry['colors'])
    for name,entry in index['assets'].items():
        path=sources/f'{name}.png'
        if not path.exists() or args.only and args.only!=name:
            continue
        entry.setdefault('fitReferenceSize',entry['size'])
        im,anchor,points=sprite(path,entry,name,calibration.get(name))
        im.save(folder/entry['file'],optimize=True)
        entry.update(size=list(im.size),anchor=anchor,basePolygon=points,source='image_gen; manga style revision')
        print(args.kit,name,im.size,anchor)
    save_json(folder/'library.json',lib)
    save_json(folder/'kit.json',index)

if __name__=='__main__':
    main()
