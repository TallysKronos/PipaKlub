"""Reserve RGB black for transparency: plan opaque ink fixes in native Aseprite."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
BASE=ROOT/'art/characters/npc-ds-directions-v1/pacote'
glyphs='.ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef'
for folder in BASE.iterdir():
    if not folder.is_dir():continue
    file=folder/(folder.name+'.pixelgen.json');p=json.loads(file.read_text(encoding='utf8'))
    black=[i for i,v in enumerate(p['palette']) if i>0 and v[:3]==[0,0,0]]
    count=0
    for f in p['frames']:
        count+=sum(v in black for v in f['indices'])
        f['indices']=[1 if v in black else v for v in f['indices']];f['cels']=[f['indices']]
    for i in black:p['palette'][i]=p['palette'][1]
    file.write_text(json.dumps(p,ensure_ascii=False),encoding='utf8')
    legend={glyphs[i]:'#'+''.join(f'{c:02x}' for c in v) for i,v in enumerate(p['palette'])}
    grids=[{'kind':'grid','x':0,'y':0,'legend':legend,'rows':[''.join(glyphs[v] for v in f['indices'][y*64:(y+1)*64]) for y in range(96)]} for f in p['frames']]
    (folder/'native-plan.json').write_text(json.dumps({'palette':list(legend.values()),'grids':grids}),encoding='utf8')
    print(folder.name,count)
