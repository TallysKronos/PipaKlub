"""Package villain design reference sheets; does not modify source artwork."""
import json
import zipfile
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'art/characters/cerol-hunters-v1'
IDS=['grunt-feminino','grunt-masculino','ronne','malvadocia']
records=[]
preview=Image.new('RGB',(1536,1024),'white')
for i,id in enumerate(IDS):
    file=OUT/(id+'-sheet.png')
    with Image.open(file) as im:
        im.load()
        records.append({'id':id,'file':file.name,'dimensions':list(im.size),'mode':im.mode,
                        'status':'concept; awaiting user artistic approval'})
        thumb=im.convert('RGB').resize((768,512),Image.Resampling.LANCZOS)
        preview.paste(thumb,(i%2*768,i//2*512))
preview.save(OUT/'cerol-hunters-preview.jpg',quality=93)
report={'characters':records,'count':4,'runtimeModified':False,'approval':'pending',
        'style':'approved clean 2D manga of Kael and cast v2',
        'designProposal':['black and charcoal cloth masses','bone mummy-like fabric wraps','cut-kite emblem',
                          'shared grunt uniform; distinct leader silhouettes'],
        'limitations':['Raster reference sheets, not separated rigs or animation.',
                       'Design choices and crest remain proposals until user approval.']}
(OUT/'review.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
with zipfile.ZipFile(OUT/'cerol-hunters-conceitos-v1.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for path in [*[OUT/(id+'-sheet.png') for id in IDS],OUT/'prompts.json',OUT/'prompts-bosses-v2.json',OUT/'direcao-bosses-v2.md',OUT/'README.md',OUT/'review.json',OUT/'cerol-hunters-preview.jpg']:
        archive.write(path,path.relative_to(OUT))
print(json.dumps(records,ensure_ascii=False))
