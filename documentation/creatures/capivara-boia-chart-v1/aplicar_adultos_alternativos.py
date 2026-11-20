from pathlib import Path
import json,shutil,hashlib,os
from PIL import Image
D=Path(__file__).resolve().parent;R=D.parents[2];F=R/'art/creatures/capivara-boia-family-v1'
specs=json.loads((F/'adultos-alternativos-v1.json').read_text(encoding='utf-8'))['specs'];chart=json.loads((D/'chart.json').read_text(encoding='utf-8'))
reviews=[
'Quatro apoios e três abas. Peito e membranas maiores e pescoço alongado distinguem o adulto do jovem B. Cabeça pequena, olhar contido e petróleo dominante reforçam maturidade. A pose não prova que há abrigo utilizável entre as membranas; requer costas e vistas de abertura. Há mais de duas nervuras visíveis por sobreposição; não tratar as superfícies como asas adicionais sem estudar raízes.',
'Duas pernas, dois braços e três abas. Cabeça e pescoço mais alongados, olhos menores e planos petróleo marcam maturidade. Membrana dianteira tem continuidade visual com o antebraço, porém o nó terminal ainda pode ler como pega; precisa de vista de perfil e gesto de recolhimento para confirmar desenho anatômico. Não é ciclo animado validado.'
]
for k,s in enumerate(specs):
 p=F/s['id']/'concept-v1';p.mkdir(parents=True,exist_ok=True)
 if not(p/'concept.png').exists():shutil.copy2(s['source'],p/'concept.png')
 (p/'prompt.txt').write_text(s['prompt'],encoding='utf-8')
 (p/'brief.md').write_text('# '+s['name']+'\n\nDefinido pelo autor: B e C são jovens alternativas; criar uma evolução adulta acima de cada uma. Proposta: arquitetura, papel, nome descritivo e limite desta forma. Referência própria: '+s['ref']+'.\n\n'+s['detail']+'\n\nNão substitui Marévia ou Capibaluarte. Nenhuma imagem externa foi input. Princípios de corpo/função/material: benchmark Ultimate/Mega 2026-11-04.',encoding='utf-8')
 (p/'revisao.md').write_text('# Revisão\n\n'+reviews[k]+'\n\nConcept em avaliação. Fundo branco intencional; ilustração manga limpa com sombreado suave residual, não pixel art técnico. Sem vistas completas, recortes, rig ou integração.',encoding='utf-8')
 with Image.open(p/'concept.png') as im:dimensions=list(im.size);mode=im.mode
 manifest=dict(tool='image_gen.imagegen built-in',source=s['source'],sha256=hashlib.sha256((p/'concept.png').read_bytes()).hexdigest(),dimensions=dimensions,mode=mode,reference_role='Own approved young '+s['ref'],external_generation_inputs=False,decision_status='proposed',production_status='concept',implementation_status='not_integrated')
 existing=p/'manifest.json'
 if existing.exists():
  old=json.loads(existing.read_text(encoding='utf-8'))
  for field in ['decision_status','approval_note','approval_date','approval_scope']:
   if field in old:manifest[field]=old[field]
 existing.write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
 rel=lambda file:Path(os.path.relpath(p/file,D)).as_posix()
 node=dict(id=s['id'],name=s['name'],age='Adulto',kind='stage',stage=4,identity=('Quadrúpede de peito elevado e membranas quebra-mar integradas.' if k==0 else 'Semiereto de pescoço longo e antebraços de membranas condutoras.'),story=('Conter torna-se abrigar: reorganiza a proteção ao redor da passagem.' if k==0 else 'Conduzir torna-se coordenar: recolhe e abre as superfícies para distribuir o fluxo.'),decision_status=manifest['decision_status'],production_status='concept',implementation_status='not_integrated',art=rel('concept.png'),brief=rel('brief.md'),name_status='descriptive_label_not_final_species_name',unknowns=['Nome definitivo','Requisitos','Ações e limites de jogo'])
 chart['nodes']=[n for n in chart['nodes'] if n['id']!=s['id']]+[node]
 chart['edges']=[e for e in chart['edges'] if e['to']!=s['id']]+[dict(**{'from':s['parent'],'to':s['id']},kind='reweaving',reason=node['story'],decision_status='proposed',requirements_status='undefined')]
chart['scope']='B e C aprovadas como jovens alternativas; dois adultos acima delas em avaliação. Linha anterior e Capibaluarte preservados; sem integração.'
(D/'chart.json').write_text(json.dumps(chart,ensure_ascii=False,indent=2),encoding='utf-8')
note='\n\n## Adultos acima de B e C — 2026-11-04\n\nB e C permanecem jovens (III Arraia). Criados dois adultos propostos (IV Pandorga): B → Porto vivo; C → Tecelão de correntes. Rótulos descritivos, não nomes de espécie definitivos. Conceitos em avaliação, sem substituir Marévia ou o Capibaluarte aprovado.\n'
for target in [D/'CHART.md',F/'DECISOES.md']:
 text=target.read_text(encoding='utf-8')
 if '## Adultos acima de B e C' not in text:target.write_text(text+note,encoding='utf-8')
exec(compile((D/'aplicar_alternativas_aprovadas.py').read_text(encoding='utf-8'),str(D/'aplicar_alternativas_aprovadas.py'),'exec'),{'__file__':str(D/'aplicar_alternativas_aprovadas.py')})
exec(compile((D/'aplicar_c_adulto_v2.py').read_text(encoding='utf-8'),str(D/'aplicar_c_adulto_v2.py'),'exec'),{'__file__':str(D/'aplicar_c_adulto_v2.py')})
