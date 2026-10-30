"""Correct the wrapped anatomical left calf in the two rear diagonals only."""
import json
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]
BASE=ROOT/'art/characters/cerol-overworld-v1/pacote/ronne'
file=BASE/'ronne.pixelgen.json'
p=json.loads(file.read_text(encoding='utf8'))
for i,lx,rx,y0,y1 in [(3,24,37,82,85),(5,22,34,81,84)]:
    f=p['frames'][i]
    for y in range(y0,y1+1):
        for x in range(rx,rx+6):
            at=y*64+x
            if 2<=f['indices'][at]<=9:f['indices'][at]=18 if y%2 else 21
        for x in range(lx,lx+5):
            at=y*64+x
            if f['indices'][at]>1:f['indices'][at]=8 if y%2 else 4
    f['cels']=[f['indices']]
file.write_text(json.dumps(p,ensure_ascii=False),encoding='utf8')
glyphs='.ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef'
legend={glyphs[i]:'#'+''.join(f'{v:02x}' for v in c) for i,c in enumerate(p['palette'])}
grids=[{'kind':'grid','x':0,'y':0,'legend':legend,'rows':[''.join(glyphs[v] for v in f['indices'][y*64:(y+1)*64]) for y in range(96)]} for f in p['frames']]
(BASE/'native-plan.json').write_text(json.dumps({'palette':list(legend.values()),'grids':grids}),encoding='utf8')
sheet=Image.new('RGBA',(256,192))
for i,f in enumerate(p['frames']):
    im=Image.new('RGBA',(64,96));im.putdata([tuple(p['palette'][v]) for v in f['indices']]);sheet.paste(im,(i%4*64,i//4*96))
sheet.save(BASE/'candidate-final.png')
