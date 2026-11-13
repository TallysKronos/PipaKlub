from pathlib import Path
import json
from PIL import Image, ImageFilter, ImageColor

repo=Path(__file__).resolve().parents[1]
root=repo/'godot/assets/overworld/kits/morro-v2'
sources=repo/'documentation/qa/kits-tiles-v1/revisao-manga'

def wrap_x(im):
    # Keep the central 512 pixels. Join overlapping ends along a low-difference
    # seam, allowing the seam to follow paving joints instead of crossfading.
    assert im.width == 640
    width=128
    pix=im.load()
    rows=[]
    prev=[0]*width
    for y in range(im.height):
        cost=[]; parents=[]
        for x in range(width):
            j=min(range(max(0,x-1),min(width,x+2)),key=prev.__getitem__)
            error=sum(abs(a-b) for a,b in zip(pix[x,y],pix[x+512,y]))
            cost.append(prev[j]+error+abs(x-64)*.16)
            parents.append(j)
        rows.append(parents);prev=cost
    x=min(range(width),key=prev.__getitem__)
    seam=[]
    for parents in reversed(rows):
        seam.append(x);x=parents[x]
    out=im.crop((64,0,576,im.height))
    dst=out.load()
    for y,k in enumerate(reversed(seam)):
        for x in range(k):
            dst[(x-64)%512,y]=pix[x+512,y]
    return out

def texture_file(path, colors, palette=None):
    im=Image.open(path).convert('RGB').resize((640,640),Image.Resampling.LANCZOS)
    im=wrap_x(wrap_x(im).transpose(Image.Transpose.TRANSPOSE)).transpose(Image.Transpose.TRANSPOSE)
    im=im.filter(ImageFilter.MedianFilter(3))
    if palette:
        lookup=Image.new('P',(1,1))
        lookup.putpalette([v for color in palette for v in ImageColor.getrgb('#'+color)])
        im=im.quantize(palette=lookup,dither=Image.Dither.NONE).convert('RGB')
    else:
        im=im.quantize(colors=colors,dither=Image.Dither.NONE).convert('RGB')
    im.paste(im.crop((0,0,1,512)),(511,0))
    im.paste(im.crop((0,0,512,1)),(0,511))
    return im

def texture(name, colors):
    return texture_file(sources/f'{name}-estudo.png', colors)

def tank():
    im=Image.open(sources/'caixa-dagua-estudo.png').convert('RGBA')
    # Match the source silhouette's plinth extrema (x=210/1101, y=841)
    # to the projected base at +/-64px and the front to y+32px.
    sx=890/128; sy=247/32; y0=104
    params=(sx,0,210.65-4.5*sx,0,sy,841.0-(y0+.5)*sy)
    sprite=im.transform((137,142),Image.Transform.AFFINE,params,resample=Image.Resampling.BICUBIC)
    a=sprite.getchannel('A').point(lambda v:255 if v>=108 else 0)
    sprite=Image.composite(sprite.convert('RGB').convert('RGBA'),Image.new('RGBA',sprite.size),a)
    left,top,right,bottom=a.getbbox()
    bounds=(left-4,top-4,right+4,bottom+4)
    im=sprite.crop(bounds)
    x,y=68-bounds[0],y0-bounds[1]
    p=[[x,y-32],[x+64,y],[x,y+32],[x-64,y]]
    assert all(im.getpixel(tuple(q))[3] for q in p), (bounds,p,[im.getpixel(tuple(q)) for q in p])
    return im,[x,y],p

def update(name,fn):
    path=root/name; data=json.loads(path.read_text(encoding='utf-8'))
    fn(data)
    path.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')

def main():
    sprite,anchor,poly=tank()
    surfaces={name:texture(name,colors) for name,colors in [
        ('pedra-clara',5),('muro-arrimo',6),('tijolo-aparente',6),('reboco-pintado-rosa',5)]}
    plaster=surfaces['reboco-pintado-rosa']
    variants={
        'creme':'AA9174 BAA183 BEA688 C3AB8D D1B99A',
        'amarela':'AC8E60 BCA16B C1A570 C6AB75 D5B881',
        'azul':'708891 829BA4 879FA8 8DA5AD 9DB4BA',
        'verde':'6F886D 829B7A 879F7E 8DA482 9BB28E',
    }
    colors=sorted((c for _,c in plaster.getcolors()),key=lambda rgb:sum(a*b for a,b in zip(rgb,(.2126,.7152,.0722))))
    for variant, swatches in variants.items():
        table=dict(zip(colors,(ImageColor.getrgb('#'+c) for c in swatches.split()),strict=True))
        im=Image.new('RGB',plaster.size)
        im.putdata([table[c] for c in (plaster.get_flattened_data() if hasattr(plaster, 'get_flattened_data') else plaster.getdata())])
        surfaces[f'reboco-pintado-{variant}']=im
    sprite.save(root/'pecas/caixa-dagua.png',optimize=True)
    for name, im in surfaces.items():
        im.save(root/'surfaces'/f'{name}.png',optimize=True)
    def patch_kit(data):
        data['assets']['caixa-dagua'].update(size=list(sprite.size),anchor=anchor,basePolygon=poly,source='image_gen; manga style revision')
    def patch_library(data):
        for e in data['surfaces']:
            if e['id'] not in surfaces:
                continue
            im=surfaces[e['id']]
            e['palette']=sorted(''.join(f'{v:02X}' for v in c) for _,c in im.getcolors())
            e['colors']=len(e['palette'])
            e['source']='image_gen; manga style revision'
    update('kit.json',patch_kit)
    update('library.json',patch_library)

if __name__=='__main__':
    main()
