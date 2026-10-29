"""Reuse pinned park art as DATA only; no merge, runtime edits or map mutations."""
from pathlib import Path
import subprocess, json, hashlib, shutil
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
REV='18dec6b87808a45ec23853ff4eb526c37a331b9a'
PREFIX='art/overworld/kits/parque'
ART=ROOT/PREFIX
GAME=ROOT/'godot/assets/overworld/kits/parque'

def blob(path):
    return subprocess.check_output(['git','show',f'{REV}:{path}'],cwd=ROOT)

source=json.loads(blob(PREFIX+'/kit.json'))
kit={k:source.get(k,{}) for k in ['schema','biome','grid','pieces','materials','transitions','walls','stairs','bridges']}
kit['approval']='pending_owner_review_jardim_nina'
kit['styleBoard']='../../estilo/PRANCHA-ESTILO.png'
kit['sourceRevision']=REV
kit['scope']='static compatible subset; no automatic foliage placement, animated grass, layered gazebo or shader changes'

files=set()
for group in kit['pieces'].values():
    for entry in group['variants'].values():
        files.update([entry['file'],entry['shadow']])
        # This renderer consumes the full transparent object, never a stale scene.
        entry.pop('scene',None)
        entry['approval']='pending_owner_review'
for material in kit['materials'].values(): files.update(material['variants'])
for transition in kit['transitions'].values(): files.update(transition['files'])
for sides in kit['walls'].values():
    for variants in sides.values(): files.update(variants)

records=[]
for relative in sorted(files):
    if '..' in Path(relative).parts: raise ValueError(relative)
    data=blob(PREFIX+'/'+relative)
    for directory in [ART,GAME]:
        target=directory/relative
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_bytes(data)
    with Image.open(ART/relative) as im:
        records.append(dict(file=relative,size=list(im.size),sha256=hashlib.sha256(data).hexdigest(),
                            alpha_min=im.convert('RGBA').getchannel('A').getextrema()[0]))

# Same family's existing masonry. Reuse art pixels, keep geometry from the map.
morro=json.loads((ROOT/'art/overworld/kits/morro/kit.json').read_text(encoding='utf-8'))
kit['walls']['pedra']={}
for side,variants in morro['walls']['pedra'].items():
    kit['walls']['pedra'][side]=[]
    for file in variants:
        relative='muros-reuso/'+Path(file).name
        data=(ROOT/'art/overworld/kits/morro'/file).read_bytes()
        for directory in [ART,GAME]:
            target=directory/relative;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
        kit['walls']['pedra'][side].append(relative)
        records.append(dict(file=relative,source='art/overworld/kits/morro/'+file,sha256=hashlib.sha256(data).hexdigest()))

for directory in [ART,GAME]:
    (directory/'kit.json').write_text(json.dumps(kit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
ART.mkdir(parents=True,exist_ok=True)
(ART/'FONTES-REMOTAS.md').write_text('''# Parque: subconjunto estático para revisão do Jardim

Origem do conteúdo reutilizado: repositório TallysKronos/PipaKlub, branch de história,
commit `'''+REV+'''`, `art/overworld/kits/parque/`.
Não houve merge nem cópia de código dessa branch. A origem dos arquivos e o estado
de revisão das fontes não foram convertidos em aprovação do novo mapa.

O manifesto inclui os PNGs consumidos pelo renderer atual: terrenos, transições e
peças inteiras. Não inclui os posicionamentos automáticos de vegetação da planta
antiga 24×16, que seriam incompatíveis com a planta nova 40×32. Não liga shaders,
capim animado ou o coreto em camadas. O coreto é um objeto estático bloqueante 4×4
nesta proposta; entrar nele requer outra revisão de colisão e profundidade.

Muros reaproveitam as pinturas de pedra do kit local `morro`, com referência de
origem por arquivo em `importacao.json`. Âncoras e pegadas originais do parque foram
preservadas. Os arquivos fonte de geração não são duplicados integralmente: o
registro fixado no Git e o README original abaixo preservam a rastreabilidade.
Este arquivo não concede uma licença nova nem atribui terceiros como autores.

Reprodução: `python tools/overworld/import_parque_review.py`.
''',encoding='utf-8')
(ART/'README-ORIGEM.md').write_bytes(blob(PREFIX+'/README.md'))
(ART/'manifesto-origem.json').write_text(json.dumps(source,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
report=dict(revision=REV,files=records,files_count=len(records),map_geometry_edited=False,
            engine_code_edited=False,approval='pending_owner_review')
(ART/'importacao.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(dict(files=len(records),materials=len(kit['materials']),transitions=len(kit['transitions']),
                     pieces=list(kit['pieces']),geometry_changed=False)))
