"""Copy approved Soulgen cutouts and author small native-vector care tools.
No raster artwork is synthesized or altered here; the room uses imagegen.
"""
from pathlib import Path
import json,shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'godot/assets/care-room-v1'
registry={}
for model,name in {'rabbito':'rabbito','mata':'mata-verde','azulao':'azulao','raio':'raio-de-sol','lacertubo':'lacertubo'}.items():
    source=ROOT/f'art/soulgen/keys/{name}/color-rig-v2/{name}.soulgen.json'
    data=json.loads(source.read_text(encoding='utf-8'))
    folder=OUT/model;folder.mkdir(parents=True,exist_ok=True)
    for asset,entry in data['assets'].items():
        file=ROOT/entry['src'].lstrip('/')
        shutil.copyfile(file,folder/f'{asset}.png')
        entry['src']=f'res://assets/care-room-v1/{model}/{asset}.png'
    data['careSource']=str(source.relative_to(ROOT)).replace('\\','/')
    (folder/'rig.json').write_text(json.dumps(data,ensure_ascii=False),encoding='utf-8')
    registry[model]=f'res://assets/care-room-v1/{model}/rig.json'
(OUT/'rigs.json').write_text(json.dumps(registry,indent=2))
head='<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96"><g stroke="#253744" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">'
shapes={
'hand-open':'<path d="m29 81-10-26c-4-10 3-15 8-7l5 10-8-32c-2-10 9-13 11-3l6 23-1-32c0-10 12-10 12 0l1 31 5-26c2-10 13-7 11 3l-5 29 9-16c5-8 14-2 10 6L69 76l-10 12Z" fill="#f7d5a6"/><path d="m29 75 35 4-3 13-34-4Z" fill="#2997a2"/><path d="m39 60 7 4m9-9 8 4" fill="none"/>',
'hand-pet':'<path d="m22 71-6-21c-2-7 5-10 9-4l7 13 27-31c5-6 12 1 7 7L50 54l25-13c8-4 12 5 5 9L61 62l19-5c8-2 11 8 3 10l-23 9-8 10Z" fill="#f7d5a6"/><path d="m22 72 32 8-5 13-31-9Z" fill="#2997a2"/>',
'hand-point':'<path d="m28 80-9-26c-2-8 7-11 11-3l3 6 1-39c0-11 12-11 12 0v27c4-7 12-6 14 1 6-5 12-1 12 5 8-2 13 4 10 14L67 85Z" fill="#f7d5a6"/><path d="m28 77 39 5-3 12-37-5Z" fill="#2997a2"/>',
'cloth':'<path d="m12 28 57-15 15 51-58 18-13-18 9-18Z" fill="#c0e1db"/><path d="m22 46 11 13 41-12m-48 35 7-23" fill="none"/><path d="m47 25 10-3 3 11-10 3Z" fill="#fff2ca"/>',
'patch':'<path d="m13 33 55-18 16 46-56 19Z" fill="#f4d78f"/><path d="m21 38 42-14 12 32-42 14Z" fill="#e7b96e" stroke-dasharray="4 6"/><path d="m40 18 5-10h18l4 10v14l-25 9Z" fill="#f5eee0"/><path d="m45 8 3-6h12l3 6Z" fill="#e9724e"/>',
'spool':'<path d="m28 22 34-5 9 53-35 8Z" fill="#f5dfb7"/><path d="m29 32 35-6m-34 15 35-6m-34 15 35-6m-33 15 35-6m-34 15 34-6" fill="none" stroke="#c9975c"/><ellipse cx="44" cy="20" rx="26" ry="10" fill="#c78b51"/><ellipse cx="53" cy="75" rx="26" ry="10" fill="#c78b51"/><path d="M72 73q20 10 9 18" fill="none"/>',
'heart':'<path d="M48 81 14 48C-8 23 24 3 48 28 72 3 104 23 82 48Z" fill="#ed8f79"/>',
'basket':'<path d="m8 41 80-3-9 43-60 6Z" fill="#cd9d61"/><path d="m16 46 8 34m8-35 6 33m8-34 3 33m10-33v32m12-33-3 32M15 58l66-3M18 71l60-4" fill="none" stroke="#946539"/><path d="m22 40q5-43 45-4" fill="none" stroke-width="7"/>',
}
for name,body in shapes.items():(OUT/f'{name}.svg').write_text(head+body+'</g></svg>',encoding='utf-8')
print('Prepared',len(registry),'approved rigs and',len(shapes),'vector care assets')

import subprocess
subprocess.run(['node',str(ROOT/'tools/prepare-care-room-basica.mjs')],check=True)
