"""Targeted detached-speck cleanup and stable standing height for these drafts."""
import json
import shutil
import sys
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/('art/characters/cerol-grunts-overworld-v1' if '--grunts' in sys.argv else 'art/characters/cerol-overworld-v1')
BASE=OUT/'pacote'
glyphs='.ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef'
entries=json.loads((OUT/'brief.json').read_text(encoding='utf8'))['characters']
for entry in entries:
    id,height=entry['id'],entry['height']
    folder=BASE/id
    file=folder/(id+'.pixelgen.json')
    backup=folder/'before-fix.pixelgen.json'
    if not backup.exists():shutil.copyfile(file,backup)
    p=json.loads(backup.read_text(encoding='utf8'))
    changes=[]
    for f in p['frames']:
        indices=f['indices'].copy();seen=set();removed=0
        for start,value in enumerate(indices):
            if not value or start in seen:continue
            stack=[start];seen.add(start);component=[]
            while stack:
                at=stack.pop();component.append(at);x,y=at%64,at//64
                for dy in [-1,0,1]:
                    for dx in [-1,0,1]:
                        xx,yy=x+dx,y+dy;pos=yy*64+xx
                        if 0<=xx<64 and 0<=yy<96 and indices[pos] and pos not in seen:
                            seen.add(pos);stack.append(pos)
            if len(component)<=16:
                for at in component:indices[at]=0;removed+=1
        image=Image.new('P',(64,96));image.putdata(indices)
        # getbbox on P images treats index zero as transparent.
        box=image.getbbox();body=image.crop(box)
        width=round(body.width*height/body.height)
        assert width<62,(id,width)
        body=body.resize((width,height),Image.Resampling.NEAREST)
        result=Image.new('P',(64,96));result.paste(body,((64-width)//2,95-height))
        f['indices']=list(result.getdata());f['cels']=[f['indices']]
        changes.append({'frame':f['name'],'specksRemoved':removed,'beforeHeight':box[3]-box[1],'afterHeight':height})
    file.write_text(json.dumps(p,ensure_ascii=False),encoding='utf8')
    legend={glyphs[i]:'#'+''.join(f'{v:02x}' for v in c) for i,c in enumerate(p['palette'])}
    grids=[{'kind':'grid','x':0,'y':0,'legend':legend,'rows':[''.join(glyphs[v] for v in f['indices'][y*64:(y+1)*64]) for y in range(96)]} for f in p['frames']]
    (folder/'native-plan.json').write_text(json.dumps({'palette':list(legend.values()),'grids':grids}),encoding='utf8')
    sheet=Image.new('RGBA',(256,192))
    for i,f in enumerate(p['frames']):
        im=Image.new('RGBA',(64,96));im.putdata([tuple(p['palette'][v]) for v in f['indices']]);sheet.paste(im,(i%4*64,i//4*96))
    sheet.save(folder/'candidate-fixed.png')
    (folder/'targeted-fix.json').write_text(json.dumps(changes,indent=2),encoding='utf8')
    print(id,changes)
