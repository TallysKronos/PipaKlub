"""Reuse compatible native assets from the pinned art study; preserve map geometry."""
from pathlib import Path
import subprocess, json, copy
ROOT=Path(__file__).resolve().parents[2]
REV='f3df6373316305ff0c9dec449d1229f2cd0c4526'
SOURCE='art/overworld/kits/veredas/'
DEST=[ROOT/'art/overworld/kits/parque', ROOT/'godot/assets/overworld/kits/parque']
def blob(path): return subprocess.check_output(['git','show',f'{REV}:{path}'],cwd=ROOT)
remote=json.loads(blob(SOURCE+'kit.json'))
kit=json.loads((DEST[0]/'kit.json').read_text(encoding='utf-8'))
records=[]
def transfer(file):
    target='ambientacao-v2/'+file
    data=blob(SOURCE+file)
    for folder in DEST:
        path=folder/target;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
    records.append({'source':SOURCE+file,'file':target})
    return target
for key in ['buriti','capim-margem','canos-patio']:
    entry=copy.deepcopy(remote['pieces'][key])
    for variant in entry['variants'].values():
        variant['file']=transfer(variant['file'])
        variant['shadow']=transfer(variant['shadow'])
        variant.pop('scene',None)
    kit['pieces'][key]=entry
kit['walls']['pedra']={side:[transfer(f) for f in files] for side,files in remote['walls']['pedra'].items()}
kit['bridges']={axis:{'file':transfer(entry['file'])} for axis,entry in remote['bridges'].items()}
kit['materials']['agua']=copy.deepcopy(remote['materials']['agua'])
kit['materials']['agua']['variants']=[transfer(f) for f in kit['materials']['agua']['variants']]
kit['dressingRevision']=REV
kit['paintSurfaces']={name:transfer('superficies/'+name+'.png') for name in ['grama','terra','mato','piso','bosque']}
for folder in DEST:
    (folder/'kit.json').write_text(json.dumps(kit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(DEST[0]/'ambientacao-v2/ORIGEM.json').write_text(json.dumps({'revision':REV,'files':records,'approval':'pending visual review','scope':'static native assets; no remote renderer or placements imported'},indent=2)+'\n',encoding='utf-8')
print(f'{len(records)} assets applied')
