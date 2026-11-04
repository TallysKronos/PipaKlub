"""Local corrections of canonical anatomical sides; keeps previous drafts."""
import json
import shutil
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]
BASE=ROOT/'art/characters/cerol-grunts-overworld-v1/pacote'
glyphs='.ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef'
def band(p,i,x0,x1,y0,y1,light,shade):
    f=p['frames'][i]['indices']
    for y in range(y0,y1+1):
        for x in range(x0,x1+1):
            at=y*64+x
            if f[at]>1:f[at]=shade if (y-y0)%3==2 else light
def darken(p,i,x0,x1,y0,y1,only_light=False):
    f=p['frames'][i]['indices']
    for y in range(y0,y1+1):
        for x in range(x0,x1+1):
            at=y*64+x
            if f[at]>1 and (not only_light or f[at]<=7):f[at]=9 if x%2 else 11
def reel(p,i,x,y):
    f=p['frames'][i]['indices']
    for dy,row in enumerate(['AGBCA','GBCCG','GBCBG','AGBCA']):
        for dx,v in enumerate(row):f[(y+dy)*64+x+dx]=glyphs.index(v)
for id in ['grunt-feminino','grunt-masculino']:
    folder=BASE/id;file=folder/(id+'.pixelgen.json')
    shutil.copyfile(file,folder/'before-sides.pixelgen.json')
    p=json.loads(file.read_text(encoding='utf8'))
    if id=='grunt-feminino':
        band(p,2,33,36,54,59,2,3)
        band(p,6,26,32,78,82,2,3)
    else:
        darken(p,3,36,43,78,84,True)
        band(p,3,25,29,78,83,2,6)
        band(p,2,29,34,78,82,2,6)
        darken(p,6,28,33,59,63)
        darken(p,5,37,41,58,62)
        reel(p,2,26,58)
        reel(p,5,25,58)
    for f in p['frames']:f['cels']=[f['indices']]
    file.write_text(json.dumps(p,ensure_ascii=False),encoding='utf8')
    legend={glyphs[i]:'#'+''.join(f'{v:02x}' for v in c) for i,c in enumerate(p['palette'])}
    grids=[{'kind':'grid','x':0,'y':0,'legend':legend,'rows':[''.join(glyphs[v] for v in f['indices'][y*64:(y+1)*64]) for y in range(96)]} for f in p['frames']]
    (folder/'native-plan.json').write_text(json.dumps({'palette':list(legend.values()),'grids':grids}),encoding='utf8')
    sheet=Image.new('RGBA',(256,192))
    for i,f in enumerate(p['frames']):
        im=Image.new('RGBA',(64,96));im.putdata([tuple(p['palette'][v]) for v in f['indices']]);sheet.paste(im,(i%4*64,i//4*96))
    sheet.save(folder/'candidate-final.png')
    sheet.resize((768,576),Image.Resampling.NEAREST).save(folder/'candidate-final-3x.png')
