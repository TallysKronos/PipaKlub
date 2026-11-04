"""Validate imported/flat asset contracts without touching runtime or other kits."""
from pathlib import Path
import json, xml.etree.ElementTree as ET
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/parque'
GAME=ROOT/'godot/assets/overworld/kits/parque'
kit=json.loads((ART/'kit.json').read_text(encoding='utf-8'))
checks=0;files=set()
def check(value,message):
    global checks
    checks+=1
    if not value: raise AssertionError(message)
for material in kit['materials'].values():
    check(len(material['variants'])==4,'Material sem quatro variantes')
    files.update(material['variants'])
for pair,transition in kit['transitions'].items():
    check(len(transition['files'])==16,f'Máscaras incompletas: {pair}')
    files.update(transition['files'])
for group in kit['pieces'].values():
    for entry in group['variants'].values():
        files.update([entry['file'],entry['shadow']])
        check(len(entry['anchor'])==2 and all(n>0 for n in entry['footprint']),'Âncora ou pegada inválida')
        with Image.open(ART/entry['file']) as im:
            check(list(im.size)==entry['size'],'Tamanho da peça não confere')
            check(im.convert('RGBA').getchannel('A').getextrema()[0]==0,'Peça sem transparência real')
for sides in kit['walls'].values():
    for variants in sides.values():files.update(variants)
files.update(kit.get('paintSurfaces',{}).values())
files.update(entry['file'] for entry in kit.get('bridges',{}).values())
bridge=kit.get('continuousBridge',{})
if bridge:
    files.add(bridge['file']);files.update(bridge['rails'].values())
    check(bridge['footprint']==[3,11],'Ponte deve preservar a pegada nativa 3×11')
for file in sorted(files):
    check((ART/file).is_file(),f'Fonte ausente: {file}')
    check((GAME/file).read_bytes()==(ART/file).read_bytes(),f'Cópia Godot diverge: {file}')
    if file.endswith('.svg'):
        svg=ET.parse(ART/file).getroot()
        expected=[512,256] if file in kit.get('paintSurfaces',{}).values() else bridge.get('size') if file in [bridge.get('file'),*bridge.get('rails',{}).values()] else [64,32]
        check([int(svg.attrib['width']),int(svg.attrib['height'])]==expected,f'Dimensões nativas inválidas: {file}')
        check(not any(e.tag.endswith('text') for e in svg.iter()),'Texto indevido em tile')
        check(not any(e.tag.endswith('image') for e in svg.iter()),'Raster externo indevido em SVG')
coreto=kit['pieces']['coreto']['variants']['default']
check(coreto['footprint']==[4,4],'Coreto alterou pegada lógica')
report=dict(checks=checks,failures=0,referenced_files=len(files),materials=len(kit['materials']),
            transitions=len(kit['transitions']),scope='asset dimensions, alpha, paths, source parity and masks; not final art approval')
out=ROOT/'art/overworld/revisao/jardim-das-pipas/kit-conferencia.json'
out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report))
