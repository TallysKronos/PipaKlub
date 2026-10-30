"""Compare native Aseprite exports to Pixelgen and assemble review artifacts."""
import json
import zipfile
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'art/characters/npc-ds-directions-v1'
def main():
    brief=json.loads((OUT/'brief.json').read_text(encoding='utf8'))
    board=Image.new('RGB',(1152,816),'#e8e2d4');draw=ImageDraw.Draw(board)
    full=Image.new('RGB',(1024,1536),'#e8e2d4')
    reports=[]
    for row,e in enumerate(brief['characters']):
        folder=OUT/'pacote'/e['id'];p=json.loads((folder/(e['id']+'.pixelgen.json')).read_text(encoding='utf8'))
        sheet=Image.new('RGBA',(256,192));frames=[]
        for i,f in enumerate(p['frames']):
            expected=Image.new('RGBA',(64,96));expected.putdata([tuple(p['palette'][v]) for v in f['indices']])
            native=Image.open(folder/f'native-{i}.png').convert('RGBA')
            assert expected.tobytes()==native.tobytes(),(e['id'],i,'native mismatch')
            alpha=set(native.getchannel('A').getdata());assert alpha=={0,255}
            box=native.getbbox();assert box[3]==95 and 0<box[0]<box[2]<64 and box[1]>0,(e['id'],i,box)
            sheet.paste(native,(i%4*64,i//4*96));frames.append(native)
            x=128+i*120;y=row*102+4
            board.paste(native,(x,y),native)
        sheet.save(folder/(e['id']+'-directions.png'))
        atlas={'image':e['id']+'-directions.png','cell':[64,96],'pivot':[32,94],
               'frames':{f['name']:{'x':i%4*64,'y':i//4*96,'w':64,'h':96,'durationMs':f['duration']} for i,f in enumerate(p['frames'])}}
        (folder/(e['id']+'-atlas.json')).write_text(json.dumps(atlas,indent=2),encoding='utf8')
        manifest=json.loads((folder/'manifest.json').read_text(encoding='utf8'))
        manifest.update(status='validated technically; independent visual review 8/10; awaiting user approval',
                        nativeRoundtripExact=True,integratedInGame=False,reviewScore=8)
        if e['id']=='lia':manifest['targetedCorrection']='shorts plum ramp restored in eight annotated regions'
        if e['id']=='nina':manifest['targetedCorrection']='left profile and right-hip bag continuity in SW/NE corrected'
        (folder/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
        enlarged=sheet.resize((768,576),Image.Resampling.NEAREST)
        bg=Image.new('RGB',enlarged.size,'#e8e2d4');bg.paste(enlarged,mask=enlarged.getchannel('A'));bg.save(folder/'preview-3x.png')
        draw.text((10,row*102+36),e['name'],fill='#152339')
        hero=frames[7].resize((192,288),Image.Resampling.NEAREST)
        x=row%4*256+32;y=row//4*384+40
        full.paste(hero,(x,y),hero)
        ImageDraw.Draw(full).text((row%4*256+28,row//4*384+12),e['name'],fill='#152339')
        reports.append({'id':e['id'],'frames':8,'nativeRoundtripExact':True,'alpha':'0/255','pivot':[32,94],
                        'opaqueColors':len({tuple(p['palette'][v]) for f in p['frames'] for v in f['indices'] if v}),
                        'aseprite':(folder/(e['id']+'.aseprite')).exists()})
    board.save(OUT/'todos-1x.png');full.crop((0,0,1024,768)).save(OUT/'elenco-3x.png')
    (OUT/'qa.json').write_text(json.dumps({'characters':reports,'totalDirections':64,'animation':'static directions, not walk'},ensure_ascii=False,indent=2),encoding='utf8')
    with zipfile.ZipFile(OUT/'npc-directions-v1.zip','w',zipfile.ZIP_DEFLATED) as bundle:
        for file in (OUT/'pacote').rglob('*'):
            if file.is_file() and file.name not in ['native-plan.json','candidate.png'] and not file.name.startswith(('native-','before-','lia-corrected')):
                bundle.write(file,file.relative_to(OUT))
        for name in ['brief.json','qa.json','todos-1x.png','elenco-3x.png','README.md']:
            if (OUT/name).exists():bundle.write(OUT/name,name)
    print(json.dumps(reports,ensure_ascii=False))
if __name__=='__main__':main()
