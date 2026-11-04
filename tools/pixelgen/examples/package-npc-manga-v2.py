"""Package regenerated manga reference sheets. Does not change original pixels."""
import json
import zipfile
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'art/characters/npc-manga-sheets-v2'
IDS=['mae','nina','bia','juninho','lia','zeca','tiao','professor']
records=[]
board=Image.new('RGB',(1536,2048),'white')
for i,id in enumerate(IDS):
    path=OUT/(id+'-sheet.png')
    with Image.open(path) as im:
        im.load()
        records.append({'id':id,'file':path.name,'dimensions':list(im.size),'mode':im.mode,
                        'status':'artistically approved by user on 2026-10-29'})
        preview=im.convert('RGB').resize((768,512),Image.Resampling.LANCZOS)
        board.paste(preview,(i%2*768,i//2*512))
board.save(OUT/'elenco-v2-preview.jpg',quality=92)
report={'sheets':records,'newSheets':8,'reusedSheets':0,'runtimeModified':False,
        'approval':{'date':'2026-10-29','source':'direct user message','quote':'Essas estão aprovadas','scope':'all eight v2 character reference sheets'},
        'visualReference':'referencias/kael-estilo-aprovado.png',
        'priorRejection':'V1 too rounded/cartoon, not approved as style reference.',
        'direction':['thin dark grey lines','smaller eyes with upper lids','more angular face construction',
                     'elongated proportions','flat muted colors and economical shadows'],
        'limitations':['Raster character reference sheets, not rigs, transparent cutouts or animation.',
                       'Approval covers the reference artwork; runtime integration and animation remain separate.']}
(OUT/'review.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
with zipfile.ZipFile(OUT/'elenco-manga-v2.zip','w',zipfile.ZIP_DEFLATED) as bundle:
    for path in [*[OUT/(id+'-sheet.png') for id in IDS],OUT/'prompts.json',OUT/'README.md',OUT/'review.json',OUT/'elenco-v2-preview.jpg']:
        bundle.write(path,path.relative_to(OUT))
print(json.dumps(records,ensure_ascii=False))
