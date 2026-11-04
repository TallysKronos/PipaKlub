"""Record code-connected events separately from acoustic/runtime acceptance."""
from pathlib import Path
import json
import re

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'art/sfx-study-v1'
sources=[
    'godot/scripts/campaign/sound_director.gd','godot/scripts/campaign/sound_observer.gd',
    'godot/scripts/campaign/front_end.gd','godot/scripts/campaign/hud_dialogue.gd',
    'godot/scripts/overworld/fruit_tree.gd',
]
connected=set()
for source in sources:
    connected.update(re.findall(r'"((?:ui|dialogue|progress|inventory|world|workshop|battle|creature|ambience)\.[a-z0-9_]+)"',(ROOT/source).read_text(encoding='utf-8')))
connected.update('world.step_'+s for s in ['wood','stone','soil','grass'])
connected.update('creature.'+s for s in ['rabbito','carcara','azulao','mata','raio','lacertubo'])
catalog=json.loads((BASE/'catalog.json').read_text(encoding='utf-8'))
for event in catalog['events']:
    event['integration_status']='connected_in_native_client' if event['id'] in connected else 'reserved_asset'
connected=sorted(e['id'] for e in catalog['events'] if e['integration_status']=='connected_in_native_client')
reserved=sorted(e['id'] for e in catalog['events'] if e['integration_status']=='reserved_asset')
report={'date':'2026-10-28','connected_count':len(connected),'connected_events':connected,
    'reserved_count':len(reserved),'reserved_events':reserved,'sources':sources,
    'verification':'Code connections and static GDScript parsing; 215 WAVs imported. No gameplay suite, listening review or packaged build executed.',
    'note':'Connected means a concrete code path, not proof that it was exercised during this task. AI textures and future mechanics remain reserved.'}
(BASE/'integration.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
for path in [BASE/'catalog.json',ROOT/'godot/assets/audio/sfx-v1/catalog.json']:
    path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'connected':len(connected),'reserved':len(reserved)},indent=2))
