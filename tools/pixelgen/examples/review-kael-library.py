"""Review sheets and synchronized eight-facing GIFs, always integer nearest-neighbor."""
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'art/characters/kael-eight-directions-v1'
p = json.loads((OUT / 'kael-library.pixelgen.json').read_text())
W, H = p['width'], p['height']
pal = [v for c in p['palette'] for v in c[:3]]
pal += [0] * (768-len(pal))
def frame(i, scale=3):
    im = Image.new('P', (W,H)); im.putpalette(pal); im.putdata(p['frames'][i]['indices'])
    im.info['transparency'] = 0
    return im.convert('RGBA').resize((W*scale,H*scale), Image.Resampling.NEAREST)
dirs = ['S','SO','O','NO','N','NE','E','SE']
actions = ['idle','walk','run','interact','attack','hurt','victory','fall']
canvas = Image.new('RGB',(8*160+100,8*222+50),'#172433'); draw=ImageDraw.Draw(canvas)
for x,d in enumerate(dirs): draw.text((110+x*160,16),d,fill='#f6d48a')
for y,act in enumerate(actions):
    draw.text((8,68+y*222),act,fill='#f6d48a')
    for x,d in enumerate(dirs):
        s=next(s for s in p['sequences'] if s['name']==f'{act}-{d}')
        idx=s['start']+({'idle':0,'walk':0,'run':0,'interact':2,'attack':2,'hurt':0,'victory':1,'fall':3}[act])
        im=frame(idx); canvas.paste(im,(100+x*160,42+y*222),im)
canvas.save(OUT/'review-directions-actions.png')
for act in actions:
    seqs=[next(s for s in p['sequences'] if s['name']==f'{act}-{d}') for d in dirs]
    keys=[]
    film=Image.new('RGB',((seqs[0]['end']-seqs[0]['start']+1)*160+60,8*210),'#172433'); fd=ImageDraw.Draw(film)
    for j in range(seqs[0]['end']-seqs[0]['start']+1):
        image=Image.new('RGB',(8*160,230),'#172433'); dd=ImageDraw.Draw(image)
        for x,(d,s) in enumerate(zip(dirs,seqs)):
            im=frame(s['start']+j); image.paste(im,(x*160+8,30),im); dd.text((x*160+12,10),d,fill='#f6d48a')
            film.paste(im,(60+j*160,x*210+15),im);fd.text((8,x*210+60),d,fill='#f6d48a')
        keys.append(image)
    film.save(OUT/f'review-{act}.png')
    timings=[p['frames'][i]['duration'] for i in range(seqs[0]['start'],seqs[0]['end']+1)]
    # Shared palette for review GIFs, avoiding per-frame quantization shimmer.
    colors=Image.new('P',(1,1));colors.putpalette([23,36,51]+pal[3:])
    gif=[im.quantize(palette=colors,dither=Image.Dither.NONE) for im in keys]
    gif[0].save(OUT/f'preview-{act}.gif',save_all=True,append_images=gif[1:],duration=timings,loop=0,disposal=2,optimize=False)
print('8 filmstrips, 8 synchronized GIFs, direction/action overview')
