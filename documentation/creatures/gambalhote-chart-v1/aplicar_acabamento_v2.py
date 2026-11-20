from pathlib import Path
import json,shutil,hashlib
from PIL import Image,ImageOps,ImageDraw
D=Path(__file__).resolve().parent
R=D.parents[2]
A=R/'art/creatures/gambalhote'
F=A/'gambalhote-adult/concept-v2'
source=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-3d4d6d4f-e18b-41f3-abb3-d219e2e0be3c.png')
shutil.copy2(source,F/'concept.png')
shutil.copy2(F.parent/'concept-v1/brief.md',F/'brief.md')
note='Autor, 2026-11-04: "Gostei muito de todos por min estariam aprovados mas achei que o ultimo teve um acabamento de luz e sombras na armadura que fugiu do estilo?" Bebê e jovem aprovados; adulto tem design aceito com ressalva de acabamento. Nova versão de acabamento aguarda conferência.'
(F/'revisao.md').write_text('# Correção de acabamento\n\nV2 remove riscos, desgaste, reflexos fragmentados e múltiplos tons nas placas. Armadura em bases foscas carvão com sombra recortada; contornos e separações entre placas permanecem. Silhueta, pose, pipa superior, quatro fios e rabiola preservados na leitura visual. Pequenos contornos internos das placas foram simplificados pela edição generativa. Duas mãos e dois pés completos; boca humanoide sob elmo.\n\n'+note+'\n\nConcept, sem rig ou integração.\n',encoding='utf-8')
im=Image.open(F/'concept.png')
(F/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen',source=source.name,sha256=hashlib.sha256((F/'concept.png').read_bytes()).hexdigest(),dimensions=list(im.size),mode=im.mode,alpha='A' in im.getbands(),prompt='prompt.txt',own_reference_inputs=['../concept-v1/concept.png: alvo de edição','../../concept-v1/concept.png: acabamento da criança'],decision_status='proposed',design_approval=note,production_status='concept',integration_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
chart=json.loads((D/'chart.json').read_text(encoding='utf-8'))
for n in chart['nodes']:
    if n['id'] in ['gambalhote-baby','gambalhote-young']:
        n.update(decision_status='approved',approval_note=note)
        path=(D/n['art']).resolve().parent
        m=json.loads((path/'manifest.json').read_text(encoding='utf-8'));m.update(decision_status='approved',approval_note=note)
        (path/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
        rev=path/'revisao.md';old=rev.read_text(encoding='utf-8')
        if note not in old:rev.write_text(old+'\n\n## Decisão posterior\n\n'+note+'\n',encoding='utf-8')
    if n['id']=='gambalhote-adult':
        n.update(art=n['art'].replace('concept-v1','concept-v2'),brief=n['brief'].replace('concept-v1','concept-v2'),decision_status='proposed',design_approval=note)
(D/'chart.json').write_text(json.dumps(chart,ensure_ascii=False,indent=2),encoding='utf-8')
sheet=Image.new('RGB',(2200,850),'white')
for i,n in enumerate(chart['nodes']):
    thumb=ImageOps.contain(Image.open(D/n['art']).convert('RGB'),(530,760));sheet.paste(thumb,(550*i+(550-thumb.width)//2,60+(760-thumb.height)//2))
    label=['Bebe / aprovado','Crianca / base aceita','Jovem / aprovado','Adulto / acabamento v2'][i]
    ImageDraw.Draw(sheet).text((550*i+18,20),label,fill='black')
sheet.save(D/'familia.png')
p=D/'index.html';s=p.read_text(encoding='utf-8');s=s.replace('gambalhote-adult/concept-v1','gambalhote-adult/concept-v2').replace('<p>Proposta</p>','<p>Conferir estado no chart; bebê e jovem aprovados, adulto em acabamento v2.</p>');p.write_text(s,encoding='utf-8')
for p in [D/'CHART.md',A/'DECISOES.md']:
    s=p.read_text(encoding='utf-8')
    if note not in s:p.write_text(s+'\n\n## Revisão posterior de acabamento\n\n'+note+' V2 adulta é a visualização atual; V1 preservada como histórico.\n',encoding='utf-8')
print('Acabamento adulto v2 salvo; aprovações registradas com escopo.')
if (D/'aprovar_adulto_v2.py').exists():
    import runpy
    runpy.run_path(str(D/'aprovar_adulto_v2.py'))
