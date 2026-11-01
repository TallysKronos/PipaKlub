"""Verify native exports and package directional bases without claiming animation."""
import json
import zipfile
import sys
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[3]
GRUNTS='--grunts' in sys.argv
OUT=ROOT/('art/characters/cerol-grunts-overworld-v1' if GRUNTS else 'art/characters/cerol-overworld-v1')
entries=json.loads((OUT/'brief.json').read_text(encoding='utf8'))['characters']
reports=[]
board=Image.new('RGB',(1152,628),'#223040')
draw=ImageDraw.Draw(board)
draw.text((24,16),'CEROL HUNTERS | Bases de overworld | 8 direcoes estaticas',fill='#fff0d2')
for row,entry in enumerate(entries):
    id=entry['id']
    folder=OUT/'pacote'/id
    p=json.loads((folder/(id+'.pixelgen.json')).read_text(encoding='utf8'))
    sheet=Image.new('RGBA',(256,192))
    measurements=[]
    for i,f in enumerate(p['frames']):
        expected=Image.new('RGBA',(64,96))
        expected.putdata([tuple(p['palette'][v]) for v in f['indices']])
        native=Image.open(folder/f'native-{i}.png').convert('RGBA')
        assert expected.tobytes()==native.tobytes(),(id,i,'native mismatch')
        assert set(native.getchannel('A').getdata())=={0,255}
        box=native.getbbox()
        assert box[3]==95 and box[0]>0 and box[2]<64 and box[1]>0,(id,i,box)
        measurements.append({'direction':f['name'],'bounds':box,'height':box[3]-box[1]})
        sheet.paste(native,(i%4*64,i//4*96))
        enlarged=native.resize((128,192),Image.Resampling.NEAREST)
        board.paste(enlarged,(24+i*140,64+row*270),enlarged)
        draw.text((24+i*140,260+row*270),f['name'].replace('idle-',''),fill='#fff0d2')
    sheet.save(folder/(id+'-directions.png'))
    big=sheet.resize((768,576),Image.Resampling.NEAREST)
    background=Image.new('RGB',big.size,'#223040');background.paste(big,mask=big.getchannel('A'))
    background.save(folder/'preview-3x.png')
    draw.text((24,42+row*270),entry.get('name',id.title()),fill='#fff0d2')
    atlas={'image':id+'-directions.png','cell':[64,96],'pivot':[32,94],
           'frames':{f['name']:{'x':i%4*64,'y':i//4*96,'w':64,'h':96,'durationMs':f['duration']} for i,f in enumerate(p['frames'])}}
    (folder/(id+'-atlas.json')).write_text(json.dumps(atlas,indent=2),encoding='utf8')
    manifest_path=folder/'manifest.json'
    manifest=json.loads(manifest_path.read_text(encoding='utf8'))
    manifest.update(status='native export verified; user artistic approval pending',
                    nativeRoundtripExact=True,integratedInGame=False,measurements=measurements,
                    opaqueColors=len({tuple(p['palette'][v]) for f in p['frames'] for v in f['indices'] if v}))
    manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
    reports.append({'id':id,'frames':8,'nativeRoundtripExact':True,'alpha':'binary0/255',
                    'colors':len({tuple(p['palette'][v]) for f in p['frames'] for v in f['indices'] if v}),
                    'measurements':measurements,'aseprite':(folder/(id+'.aseprite')).exists()})
board.save(OUT/'cerol-overworld-preview.png')
scale_board=Image.new('RGB',(720,360),'#223040');sd=ImageDraw.Draw(scale_board)
kael=Image.open(ROOT/'godot/assets/kael-video/kael-walk-eight.png').convert('RGBA').crop((0,7*96,64,8*96))
actors=[(e.get('name',e['id']),Image.open(OUT/'pacote'/e['id']/'native-7.png').convert('RGBA')) for e in entries]
actors.insert(1,('Kael',kael))
for column,(name,im) in enumerate(actors):
    body=im.crop(im.getbbox());body=body.resize((body.width*3,body.height*3),Image.Resampling.NEAREST)
    scale_board.paste(body,(column*240+(240-body.width)//2,315-body.height),body)
    sd.text((column*240+75,330),name,fill='#fff0d2')
scale_board.save(OUT/'escala-kael.png')
(OUT/'qa.json').write_text(json.dumps({'characters':reports,'totalDirections':16,'animation':False,'runtimeModified':False},ensure_ascii=False,indent=2),encoding='utf8')
with zipfile.ZipFile(OUT/('cerol-grunts-overworld-v1.zip' if GRUNTS else 'cerol-overworld-v1.zip'),'w',zipfile.ZIP_DEFLATED) as bundle:
    for file in (OUT/'pacote').rglob('*'):
        if file.is_file() and file.name != 'native-plan.json' and not file.name.startswith(('native-','before-','candidate')):
            bundle.write(file,file.relative_to(OUT))
    for name in ['brief.json','qa.json','visual-review.md','README.md','cerol-overworld-preview.png','escala-kael.png']:
        if (OUT/name).exists():bundle.write(OUT/name,name)
print(json.dumps(reports,ensure_ascii=False))
