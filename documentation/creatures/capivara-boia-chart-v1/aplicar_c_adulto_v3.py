from pathlib import Path
import json,shutil,hashlib,os
from PIL import Image
D=Path(__file__).resolve().parent;R=D.parents[2];F=R/'art/creatures/capivara-boia-family-v1/capiboia-tececorrente';P=F/'concept-v3'
source=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-9a58c064-211a-4b3f-b7df-3b645144dd3c.png')
if not(P/'concept.png').exists():shutil.copy2(source,P/'concept.png')
with Image.open(P/'concept.png') as im:dimensions=list(im.size);mode=im.mode
(P/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen built-in',source=str(source),sha256=hashlib.sha256((P/'concept.png').read_bytes()).hexdigest(),dimensions=dimensions,mode=mode,reference_role='Own young C identity; Vikemon researched only, not image input',external_generation_inputs=False,decision_status='proposed',production_status='concept',implementation_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
old=F/'concept-v2/manifest.json';m=json.loads(old.read_text(encoding='utf-8'));m.update(decision_status='rejected',decision_note='Autor: não ficou bom, nem da pra entender como ele funciona; pediu referência em Vikemon.');old.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
chart=json.loads((D/'chart.json').read_text(encoding='utf-8'))
for n in chart['nodes']:
 if n['id']=='capiboia-tececorrente':n.update(name='Adulto de C — Mestre da vazante (proposta)',art=Path(os.path.relpath(P/'concept.png',D)).as_posix(),brief=Path(os.path.relpath(P/'brief.md',D)).as_posix(),identity='Capivara-pipa bípede robusta, dois braços com mãos distintas, manto curto e um remo reforçado.',story='Concentra a técnica dos remos num gesto de impacto preciso e abre passagem pela corrente.',decision_status='proposed',revision='concept-v3')
(D/'chart.json').write_text(json.dumps(chart,ensure_ascii=False,indent=2),encoding='utf-8')
note='\n\n## Adulto C v3 — estrutura orientada pelo estudo de Vikemon\n\n2026-11-04: v2 rejeitada por funcionamento pouco compreensível. Autor pediu Vikemon como referência. Nova proposta v3, bípede robusta com braços, mãos e um remo claramente separados; estudo externo sem imagem no input. Nomes e mecânicas indefinidos, em avaliação.\n'
for target in [D/'CHART.md',F.parent/'DECISOES.md']:
 t=target.read_text(encoding='utf-8')
 if '## Adulto C v3' not in t:target.write_text(t+note,encoding='utf-8')
exec(compile((D/'aplicar_alternativas_aprovadas.py').read_text(encoding='utf-8'),str(D/'aplicar_alternativas_aprovadas.py'),'exec'),{'__file__':str(D/'aplicar_alternativas_aprovadas.py')})
