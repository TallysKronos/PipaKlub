from pathlib import Path
import json,hashlib,shutil,html
from PIL import Image,ImageOps,ImageDraw
A=Path(__file__).resolve().parent;R=A.parents[2];D=R/'documentation/creatures/mico-samurai-chart-v1';D.mkdir(parents=True,exist_ok=True)
G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f');items=json.loads((A/'geracao.json').read_text(encoding='utf-8'));nodes=[]
for item in items:
 F=A/item['id']/'concept-v1';F.mkdir(parents=True,exist_ok=True);src=next(G.glob(item['prefix']+'*.png'));shutil.copy2(src,F/'concept.png')
 (F/'prompt.txt').write_text(item['prompt'],encoding='utf-8')
 (F/'brief.md').write_text('# '+item['name']+'\n\nDefinido pelo autor: linha mico + samurai, adulto esguio, duas katanas nas mãos, cabeça pequena de elmo angular com detalhes que interrompam contorno liso. Referências Omega-Shoutmon, Beelzebumon e Anubismon.\n\nProposta: '+item['story']+' Herança: verde-floresta, marfim, cobre/terracota, nós ameixa, olhos turquesa e cauda anelada. Tufos de orelha tornam-se placas do elmo; peito é membrana com varetas, não emblema decorativo. Limitação proposta: precisão requer espaço entre lâminas e controle do contrapeso.\n\nNomes finais, elemento, habilidades, obtenção e níveis indefinidos. Rabiola porta a mesma identidade. Sem integração.\n',encoding='utf-8')
 review='Dois braços, duas pernas e uma cauda nas formas corporais; bebê tem duas abas de apoio e cauda, sem torso. Rabiola completa com dois terminais. Duas peças empunhadas nas formas de treino e duas katanas na adulta. '
 if item['stage']==4:review+='Cabeça pequena de visor fechado, três grandes placas por tufo; punho baixo mostra um pequeno cilindro adicional junto ao bracelete que pode confundir com cabo extra e deve ser esclarecido antes de recorte. '
 if item['stage']==3:review+='Rosto animal exposto sob visor parcial. Armadura ficou mais completa nas canelas que a intenção inicial; diferenciação atual depende também da face aberta e postura baixa. '
 (F/'revisao.md').write_text('# Conferência\n\n'+review+'Concept proposto; sem aprovação. Traço limpo, sombra ampla; não certificar contagem exata de cores nem pixel art técnico. Sem vistas, rig, animação ou integração.\n',encoding='utf-8')
 im=Image.open(F/'concept.png');(F/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen',source=src.name,sha256=hashlib.sha256((F/'concept.png').read_bytes()).hexdigest(),dimensions=list(im.size),mode=im.mode,alpha='A' in im.getbands(),prompt='prompt.txt',own_reference_inputs='Adulto próprio para bebê, criança e jovem; Gambalhote adulto v2 apenas para acabamento do adulto.',decision_status='proposed',production_status='concept',integration_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
 rel='../../../art/creatures/mico-samurai-family-v1/'+item['id']+'/concept-v1/';nodes.append(dict(id=item['id'],name=item['name'],kind='stage',stage=item['stage'],maturity=['Bebê','Criança','Jovem','Adulto'][item['stage']-1],identity=item['story'],story=item['story'],decision_status='proposed',production_status='concept',art=rel+'concept.png',brief=rel+'brief.md'))
edges=[dict(**{'from':nodes[i]['id'],'to':nodes[i+1]['id']},kind='reweaving',reason=nodes[i+1]['story'],decision_status='proposed') for i in range(3)]
(D/'chart.json').write_text(json.dumps(dict(family_id='mico-samurai',scope='Quatro concepts propostos e estudo; sem integração.',nodes=nodes,edges=edges),ensure_ascii=False,indent=2),encoding='utf-8')
sheet=Image.new('RGB',(2400,850),'white')
for i,n in enumerate(nodes):
 im=ImageOps.contain(Image.open(D/n['art']).convert('RGB'),(570,750));sheet.paste(im,(600*i+(600-im.width)//2,65+(750-im.height)//2));ImageDraw.Draw(sheet).text((600*i+18,20),['Bebe','Crianca','Jovem','Adulto'][i]+' / proposta',fill='black')
sheet.save(D/'familia.png')
(D/'CHART.md').write_text('# Mico-samurai\n\nBebê → criança de treino → jovem de visor parcial → Micoshiro, adulto esguio de duas katanas (nome proposto). Todas as artes e relações propostas. Tufos, cauda anelada, paleta e peito tensionado ligam as formas. A cabeça adulta é um elmo angular, não um robô; não há lore mecânica.\n\nVer ESTUDO.md. Limites: bracelete adulto com cilindro que merece esclarecimento técnico; jovem com placas de canela mais completas que planejado. Sem integração.\n',encoding='utf-8')
cards=''.join('<article><h2>'+html.escape(n['name'])+'</h2><img src="'+n['art']+'" alt="'+html.escape(n['identity'])+'"><p>'+html.escape(n['story'])+'</p><a href="'+n['brief']+'">Brief</a></article>' for n in nodes)
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Mico-samurai</title><style>body{font:18px system-ui;background:#f1f3e8;color:#24352d;margin:40px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:24px}article{background:white;padding:22px;border:1px solid #b0b8a6}img{width:100%;height:420px;object-fit:contain}a:focus{outline:3px solid #bd5b35}</style><h1>Mico-samurai</h1><p>Concepts propostos. <a href="ESTUDO.md">Estudo das referências</a></p><main>'+cards+'</main></html>',encoding='utf-8')
(A/'DECISOES.md').write_text('# Mico-samurai\n\nAutor pediu linha mico-samurai com adulto esguio, duas katanas e cabeça pequena angular detalhada. Quatro concepts propostos; Micoshiro nome provisório. Sem aprovação ou integração.\n',encoding='utf-8')
print(D)
import runpy
runpy.run_path(str(D/'aprovar.py'))
