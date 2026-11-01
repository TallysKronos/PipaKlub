"""Plan a limited shorts-material correction, applied in native Aseprite."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
P=ROOT/'art/characters/npc-ds-directions-v1/pacote/lia'
p=json.loads((P/'lia.pixelgen.json').read_text(encoding='utf8'))
(P/'before-plum.pixelgen.json').write_text(json.dumps(p),encoding='utf8')
# Recover three palette slots occupied by near-black duplicates, retaining ink.
p['palette'][29:32]=[[139,73,117,255],[105,53,88,255],[73,38,63,255]]
regions=[[23,62,43,76],[23,61,43,77],[27,61,40,77],[24,62,43,78],
         [23,63,43,78],[22,62,42,78],[25,61,41,77],[23,62,43,77]]
reports=[];glyphs='.ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef'
for f,region in zip(p['frames'],regions):
    old=f['indices'];out=[1 if v in [29,30,31] else v for v in old];changed=0
    l,t,r,b=region
    for y in range(t,b):
        for x in range(l,r):
            at=y*64+x;v=old[at]
            if v in [15,16,19]:out[at]={15:29,16:30,19:31}[v];changed+=1
    f['indices']=out;f['cels']=[out];reports.append(changed)
(P/'lia.pixelgen.json').write_text(json.dumps(p,ensure_ascii=False),encoding='utf8')
legend={glyphs[i]:'#'+''.join(f'{c:02x}' for c in rgba) for i,rgba in enumerate(p['palette'])}
grids=[{'kind':'grid','x':0,'y':0,'legend':legend,'rows':[''.join(glyphs[v] for v in f['indices'][y*64:(y+1)*64]) for y in range(96)]} for f in p['frames']]
(P/'native-plan.json').write_text(json.dumps({'palette':list(legend.values()),'grids':grids}),encoding='utf8')
(P/'plum-correction.json').write_text(json.dumps({'regions':regions,'recoloredShortPixels':reports,'nearBlackDuplicatesConsolidated':[29,30,31]},indent=2),encoding='utf8')
print(reports)
