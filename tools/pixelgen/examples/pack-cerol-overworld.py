"""Normalize generated directional drafts with the existing NPC Pixelgen contract.

This is automated draft preparation, not hand-drawn cluster art or animation.
Native Aseprite exports and independent visual review follow separately.
"""
import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / ('art/characters/cerol-grunts-overworld-v1' if '--grunts' in sys.argv else 'art/characters/cerol-overworld-v1')
spec = importlib.util.spec_from_file_location('npc_pack', Path(__file__).with_name('pack-npc-directions.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
module.OUT = OUT
brief = json.loads((OUT/'brief.json').read_text(encoding='utf8'))
reports = [module.prepare(entry) for entry in brief['characters']]
# Reserve index zero for transparency; near-black opaque cloth stays opaque.
for entry in brief['characters']:
    folder = OUT/'pacote'/entry['id']
    file = folder/(entry['id']+'.pixelgen.json')
    project = json.loads(file.read_text(encoding='utf8'))
    black = [i for i,c in enumerate(project['palette']) if i and c[:3] == [0,0,0]]
    for frame in project['frames']:
        frame['indices'] = [1 if v in black else v for v in frame['indices']]
        frame['cels'] = [frame['indices']]
    for i in black:
        project['palette'][i] = project['palette'][1]
    file.write_text(json.dumps(project,ensure_ascii=False),encoding='utf8')
    legend = {module.GLYPHS[i]:'#'+''.join(f'{v:02x}' for v in color) for i,color in enumerate(project['palette'])}
    grids = [{'kind':'grid','x':0,'y':0,'legend':legend,'rows':[''.join(module.GLYPHS[v] for v in f['indices'][y*64:(y+1)*64]) for y in range(96)]} for f in project['frames']]
    (folder/'native-plan.json').write_text(json.dumps({'palette':list(legend.values()),'grids':grids}),encoding='utf8')
print(json.dumps(reports,ensure_ascii=False))
