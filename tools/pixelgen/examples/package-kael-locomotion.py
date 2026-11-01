"""Register Aseprite exports in Pixelgen and check the native-pixel contract.

This reads raster exports, writes only project/manifest JSON, and never changes
sprite pixels. Aseprite remains the source of the PNG and editable layered art.
"""
from pathlib import Path
import json
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'art/characters/kael-locomotion-v1'
DIRS=['s','sw','w','nw','n','ne','e','se']
TIMES={'idle':[480,150,320,150,480,150,320,150],'run':[80]*8}
palette=json.loads((OUT/'palette.json').read_text())
rgba=[tuple(bytes.fromhex(c[1:])) if len(c)==9 else tuple(bytes.fromhex(c[1:]))+(255,) for c in palette]
indices={c:i for i,c in enumerate(rgba)}
report={}
for action in TIMES:
    path=ROOT/'godot/assets/kael-video'/f'kael-{action}-eight.png'
    image=Image.open(path).convert('RGBA')
    assert image.size==(512,768),image.size
    frames=[];sequences=[]
    for row,direction in enumerate(DIRS):
        soles=None;unique=set()
        for column in range(8):
            cell=image.crop((column*64,row*96,column*64+64,(row+1)*96))
            pixels=[]
            for color in cell.getdata():
                assert color[3] in [0,255],('soft alpha',color)
                pixels.append(indices[color] if color[3] else 0)
            assert any(pixels),('empty',action,direction,column)
            unique.add(tuple(pixels))
            if action=='idle':
                feet=cell.crop((0,78,64,96)).tobytes()
                if soles is None:soles=feet
                assert feet==soles,('sliding idle feet',direction,column)
            frames.append({'name':f'{action}-{direction.upper()}-{column+1}','duration':TIMES[action][column],'indices':pixels,'cels':[pixels]})
        assert len(unique)>= (3 if action=='idle' else 6),(action,direction,len(unique))
        sequences.append({'name':f'{action}-{direction.upper()}','start':row*8,'end':row*8+7,'loop':True,'direction':'forward'})
    project={'kind':'pixelgen','version':2,'name':'Kael · '+action,'width':64,'height':96,'cols':8,'rows':8,'palette':[list(c) for c in rgba],
        'settings':{'width':64,'height':96,'cols':8,'rows':8,'colors':32,'margin':2},'layers':[{'name':'Arte revisada','visible':True,'locked':False}],
        'sheet':{'nome':'Kael','altura':86,'base':94,'cores':32,'notas':'Prancheta editável em aseprite/. Fonte do idle: poses aprovadas; corrida: H3 local e seleção de ciclos. Sem alteração da caminhada.'},
        'frames':frames,'sequences':sequences}
    (OUT/f'kael-{action}.pixelgen.json').write_text(json.dumps(project,ensure_ascii=False),encoding='utf-8')
    report[action]={'size':list(image.size),'cell':[64,96],'pivot':[32,94],'directions':DIRS,'framesPerDirection':8,'durationsMs':TIMES[action],
        'colors':len(set(image.getdata())-{(0,0,0,0)}),'binaryAlpha':True,'existingPalette':True,'idleFeetFixed':action=='idle','runtime':str(path.relative_to(ROOT))}
(OUT/'review/technical.json').write_text(json.dumps(report,indent=2))
(OUT/'manifest.json').write_text(json.dumps({'character':'kael','origin':{'idle':'existing approved eight-direction rest references, layered respiration in Aseprite','run':'local installed MiniMax H3 reference-to-video; workflows/prompts/jobs and selected source frames retained'},'sourceApproval':'existing Kael design, new animations pending player feedback','animations':report},indent=2))
print(json.dumps(report,indent=2))
