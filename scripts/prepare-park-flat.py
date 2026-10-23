"""Normalize the deliberately reviewed sprite regions of the flat park family."""
from PIL import Image, ImageFilter, ImageChops
from collections import deque
from pathlib import Path
import sys, shutil, json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'art/soulgen/keys/park-wind-v2'
OUT.mkdir(parents=True,exist_ok=True)
source=Path(sys.argv[1]) if len(sys.argv)>1 else OUT/'source-atlas.png'
if source.resolve()!=(OUT/'source-atlas.png').resolve():shutil.copy2(source,OUT/'source-atlas.png')
im=Image.open(source).convert('RGBA')
cells={
 'canopy':(35,0,445,308),'trunk':(520,0,840,309),'coreto':(920,0,1260,307),'bench':(1380,20,1750,299),
 'shrub':(75,310,450,512),'flowers':(525,312,840,512),'planter':(925,310,1300,510),'sign':(1415,290,1720,535),
 'fenceA':(85,512,450,708),'fenceB':(500,512,805,708),'lamp':(1070,480,1180,727),'bin':(1480,535,1625,710),
 'pole':(165,678,345,887),'sock':(520,712,840,851),'bunting':(910,718,1370,860),'kite':(1390,690,1740,887)}
assets={}
def isolate(sprite):
    # Discard detached pieces from neighbouring rows, retaining the principal sprite
    # and its original antialiased alpha. This does not repaint generated pixels.
    w,h=sprite.size; pixels=sprite.getchannel('A').tobytes(); seen=set(); largest=[]
    for i,a in enumerate(pixels):
        if a<=32 or i in seen:continue
        q=deque([i]);seen.add(i);component=[]
        while q:
            j=q.popleft();component.append(j);x=j%w;y=j//w
            for nx,ny in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
                n=ny*w+nx
                if 0<=nx<w and 0<=ny<h and n not in seen and pixels[n]>32:seen.add(n);q.append(n)
        if len(component)>len(largest):largest=component
    keep=set(largest)
    mask=Image.new('L',(w,h));mask.putdata([255 if i in keep else 0 for i in range(w*h)])
    sprite.putalpha(ImageChops.multiply(sprite.getchannel('A'),mask.filter(ImageFilter.MaxFilter(5))))
    return sprite
for key,cell in cells.items():
    sprite=isolate(im.crop(cell))
    box=sprite.getchannel('A').point(lambda a:255 if a>32 else 0).getbbox()
    sprite=sprite.crop(box)
    out=Image.new('RGBA',(sprite.width+12,sprite.height+12));out.paste(sprite,(6,6))
    out.save(OUT/(key+'.png'))
    assets[key]={'name':key,'src':'/art/soulgen/keys/park-wind-v2/'+key+'.png','width':out.width,'height':out.height,'sourceCell':list(cell),'alphaMin':0}
(OUT/'slices.json').write_text(json.dumps(assets,indent=2)+'\n',encoding='utf8')
print({k:[a['width'],a['height']] for k,a in assets.items()})
