from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageFont
from html import escape
import json,hashlib,shutil,os
D=Path(__file__).resolve().parent;R=D.parents[2];P=R/'art/creatures/paleorix/concept-v1'
source=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-d0bd962f-5a18-41e3-857b-ae3e38bd4e8d.png');shutil.copy2(source,P/'concept.png')
brief='''# Paleórix — Entrelaço de Estratonte + Rexestrato

## Definido pelo autor
Criar uma fusão desses dois Soulmonsters e estudar Omnimon, Paildramon, Chaosmon e GraceNovamon. Artes dos parceiros aprovadas, preservadas.

## Proposta de identidade
Nome Paleórix. Colosso fóssil bípede de duas pernas e dois braços. Mandíbula no antebraço de ruptura, braço vertebral com escudo de pipa no lado protetor. Centro novo: costelas e membranas âmbar/verde-água no peito, ressonador raso abaixo; pequena cobertura dorsal bipartida. Crânio novo combina sobrancelha robusta e focinho mais baixo, pescoço de vértebras curtas. Marfim, lavanda, índigo, cobre e ocre mesclam heranças sem divisão literal em duas metades.

## História e função propostas
O impulso de projetar um chamado aprende a ser contido pela capacidade de abrigar. Conter e direcionar vibração exige apoio e coordenação dos dois lados; reforço defensivo e abertura da mandíbula não são vantagens livres simultâneas. Isso é intenção de design, não regra de batalha.

## Rabiolas e incógnitas
Os fios continuam visíveis: curto entrelaço antes de dois conjuntos de flâmulas herdadas. Sem nova alma no peito. Reversibilidade, duração, custo, requisitos, estágio, elementos e destino das identidades após a fusão não foram definidos. A representação não resolve essas questões. Não escrever na bíblia como fato.
'''
(P/'brief.md').write_text(brief,encoding='utf-8')
(P/'revisao.md').write_text('# Conferência\n\nPiloto inspecionado: uma cabeça, dois braços conectados e duas pernas. Escudo lateral com dois suportes e mão fora dele. Punho de ruptura com mandíbula abstrata sem olho próprio, mão escura central. Cauda única com dois fios/conjuntos de flâmulas. Ambos os parceiros legíveis sem manter corpos inteiros.\n\nLimites: encaixes e garras em perspectiva precisam de vistas; peito tem vincos a simplificar caso aprovado. Pequenas transições suaves residuais. Concept estático, não pixel art de grade, recorte, rig, animação ou integração. Nova arte em avaliação. Referências externas estudadas, nunca inputs.\n',encoding='utf-8')
with Image.open(P/'concept.png') as im:size=list(im.size);mode=im.mode
(P/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen built-in',source=str(source),sha256=hashlib.sha256((P/'concept.png').read_bytes()).hexdigest(),dimensions=size,mode=mode,alpha=False,prompt='prompt.txt',reference_role='Own approved Estratonte v1 + Rexestrato v1 as identity inputs',external_generation_inputs=False,decision_status='proposed',production_status='concept',implementation_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
ref=lambda p:Path(os.path.relpath(p,D)).as_posix()
nodes=[]
for id,name,family,note in [('estratonte','Estratonte','estratonte-family-v1','Autor aprovou família com jovem v3: “Aprovados”.'),('rexestrato','Rexestrato','rexestrato-family-v1','Autor aprovou linha T-rex: “Aprovado! Faça um fossil brontossauro”.')]:
 p=R/'art/creatures'/family/id/'concept-v1'
 nodes.append(dict(id=id,name=name,kind='stage',stage=4,identity='Parceiro fóssil aprovado; arte original preservada.',story='Fonte de '+('proteção e sustentação.' if id=='estratonte' else 'ruptura e ressonância.'),decision_status='approved',approval_note=note,production_status='concept',art=ref(p/'concept.png'),brief=ref(p/'brief.md')))
nodes.append(dict(id='paleorix',name='Paleórix (proposto)',kind='configuration',stage=None,identity='Colosso fóssil de braços assimétricos, ressonador compartilhado e rabiolas entrelaçadas.',story='Coordenação entre conter e projetar vibração.',decision_status='proposed',production_status='concept',partners=['estratonte','rexestrato'],unknowns=['requisitos','duração','custos','reversibilidade','estágio','efeitos sobre identidades'],art=ref(P/'concept.png'),brief=ref(P/'brief.md')))
edges=[dict(**{'from':id,'to':'paleorix'},kind='interweaving',partners=['estratonte','rexestrato'],reason=why,decision_status='proposed') for id,why in [('estratonte','Sustentação e cobertura reorganizam proteção e direção da pressão.'),('rexestrato','Mandíbula, tórax e membranas fornecem ressonância e ruptura.')]]
(D/'chart.json').write_text(json.dumps(dict(family_id='estrato-rex-entrelaco-v1',scope='Proposta visual de Entrelaço solicitada; dois pais aprovados, fusão em avaliação. Sem estágio V ou integração.',nodes=nodes,edges=edges),ensure_ascii=False,indent=2),encoding='utf-8')
sources=[]
for slug,title,principle in [('omegamon','Omnimon','Heranças localizadas por função.'),('paildramon','Paildramon','Partes reorganizadas em corpo integrado.'),('chaosmon','Chaosmon','História de compatibilidade não equivale a regra universal.'),('gracenovamon','GraceNovamon','Um terceiro conceito reúne as identidades.')]:
 p=D/'referencias'/f'{slug}.jpg'
 sources.append(dict(title=title,entity='Bandai / Digimon Web',url=f'https://digimon.net/reference_en/detail.php?directory_name={slug}',image_url=f'https://digimon.net/cimages/digimon/{slug}.jpg',access='2026-11-04',local_art=f'referencias/{slug}.jpg',sha256=hashlib.sha256(p.read_bytes()).hexdigest(),inspection='Perfil lido e arte aberta individualmente',interpretation=principle,proposed_use='Análise no ESTUDO.md; nenhum input externo na geração.'))
(D/'fontes.json').write_text(json.dumps(sources,ensure_ascii=False,indent=2),encoding='utf-8')
(D/'CHART.md').write_text('# Entrelaço proposto\n\nEstratonte + Rexestrato → Paleórix. Os parceiros são conceitos aprovados, o destino é proposta visual sem estágio numérico decidido. Ver ESTUDO.md para fatos, observações e interpretações separados. Requisitos e efeitos ainda indefinidos. Sem integração.\n',encoding='utf-8')
sheet=Image.new('RGB',(2200,1450),'#f4f1e9');dr=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',30)
for i,n in enumerate(nodes):
 x,y,w,h=(0,i*725,850,625) if i<2 else (900,60,1250,1280)
 with Image.open(D/n['art']) as im:tile=ImageOps.contain(im.convert('RGB'),(w,h));sheet.paste(tile,(x+(w-tile.width)//2,y+65+(h-tile.height)//2))
 dr.text((x+24,y+15),n['name']+(' — aprovado' if i<2 else ' — Entrelaço'),font=font,fill='#303750')
sheet.save(D/'comparativo.png')
cards=''.join(f'<article><h2>{escape(n["name"])}</h2><p>{"Aprovado" if n["decision_status"]=="approved" else "Em avaliação"}</p><a href="{n["art"]}"><img src="{n["art"]}" alt="{escape(n["identity"])}"></a><p>{escape(n["story"])}</p><a href="{n["brief"]}">Brief</a></article>' for n in nodes)
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Paleórix · Entrelaço</title><style>body{max-width:1350px;margin:auto;padding:28px;background:#f4f1e9;color:#303750;font:18px/1.6 system-ui}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:24px}article{padding:20px;background:white}img{width:100%;height:460px;object-fit:contain}a:focus-visible{outline:4px solid #a65500}@media(max-width:800px){.grid{grid-template-columns:1fr}}</style><h1>Estratonte + Rexestrato → Paleórix</h1><p>Entrelaço em avaliação; requisitos e mecânicas indefinidos.</p><a href="ESTUDO.md">Estudo das quatro referências</a> · <a href="fontes.json">Fontes</a> · <a href="comparativo.png">Comparativo</a><main class="grid">'+cards+'</main></html>',encoding='utf-8')
print('Estudo, concept e chart de Entrelaço salvos. Pais preservados.')
if (D/'aplicar_v2.py').exists():
 import runpy
 runpy.run_path(str(D/'aplicar_v2.py'))
