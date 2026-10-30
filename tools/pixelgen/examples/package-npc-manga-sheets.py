"""Package reference sheets and a reduced contact sheet; never edits source art."""
import json
import zipfile
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'art/characters/npc-manga-sheets-v1'
IDS=['mae','nina','bia','juninho','lia','zeca','tiao','professor']
board=Image.new('RGB',(1536,2048),'white')
records=[]
for i,id in enumerate(IDS):
    path=OUT/(id+'-sheet.png')
    with Image.open(path) as im:
        im.load()
        records.append({'id':id,'file':path.name,'dimensions':list(im.size),'mode':im.mode,
                        'newlyGenerated':id!='professor','status':'visual review complete; awaiting user approval'})
        preview=im.convert('RGB').resize((768,512),Image.Resampling.LANCZOS)
        board.paste(preview,(i%2*768,i//2*512))
board.save(OUT/'elenco-pranchas-preview.jpg',quality=92)
report={'sheets':records,'newSheets':7,'reusedApprovedSheets':1,'runtimeModified':False,
        'review':['Matched Kael supplied sheet for line, faces, color restraint and layout.',
                  'Checked front/back identity, head/hair continuity, hands, full feet and expression count.',
                  'Nina full-body strap corrected from anatomical left shoulder to right-hip satchel; strap omitted in expression studies; previous versions retained.',
                  'Juninho cap stays backward; Lia shorts remain plum; reel hands remain on their anatomical sides.'],
        'limitations':['Single raster reference sheets, no rig, transparent cutouts or animation.',
                       'Expression studies describe a design; final production poses may need redraw for continuity.']}
(OUT/'review.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
with zipfile.ZipFile(OUT/'elenco-manga-pranchas-v1.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for name in [*[id+'-sheet.png' for id in IDS],'prompts.json','revisions.json','README.md','review.json','elenco-pranchas-preview.jpg']:
        archive.write(OUT/name,name)
print(json.dumps(records,ensure_ascii=False))
