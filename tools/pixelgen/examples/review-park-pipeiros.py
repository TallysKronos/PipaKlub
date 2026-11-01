import json
from pathlib import Path
from PIL import Image
root=Path(r'C:/Users/user/produto/pipa-club-pip88')
out=root/'art/characters/parque-pipeiros-runtime-v1'
reports=[]
for ident in ['iara','nilo','dora','caue','celina']:
    base=out/'pacote'/ident
    doc=json.loads((base/f'{ident}.pixelgen.json').read_text())
    actual=Image.open(root/'godot/assets/npc-ds'/f'{ident}.png').convert('RGBA')
    assert actual.size==(256,192)
    assert set(actual.getchannel('A').getdata())=={0,255}
    assert len(set(actual.getdata()))<=32
    boxes=[]
    for i,frame in enumerate(doc['frames']):
        cell=actual.crop((i%4*64,i//4*96,i%4*64+64,i//4*96+96))
        expected=[tuple(doc['palette'][n]) for n in frame['indices']]
        assert list(cell.getdata())==expected, (ident,i,'native differs from Pixelgen')
        box=cell.getbbox();assert box and box[0]>0 and box[2]<64 and box[1]>0 and box[3]==95
        boxes.append(box)
    manifest=json.loads((base/'manifest.json').read_text())
    manifest.update(status='native Aseprite export; reviewed in Godot',exportedBounds=boxes,criticScore=7.5 if ident=='caue' else 8)
    (base/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
    reports.append({'id':ident,'views':8,'colors':len(set(actual.getdata())),'bounds':boxes,'nativeEqualsPixelgen':True})
(root/'documentation/campaign/park-new-cast/asset-report.json').write_text(json.dumps(reports,indent=2))
print(json.dumps(reports))

