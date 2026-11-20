from pathlib import Path
import json,hashlib,shutil,html
from PIL import Image,ImageOps,ImageDraw
A=Path(__file__).resolve().parent; R=A.parents[2]
D=R/'documentation/creatures/gata-lunar-chart-v1';D.mkdir(parents=True,exist_ok=True)
G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f')
items=json.loads((A/'geracao.json').read_text(encoding='utf-8'))
nodes=[]
sources={1:['../noctiluna/concept-v1/concept.png: identidade e acabamento'],2:['../noctiluna/concept-v1/concept.png: destino','../gata-lunar-baby/concept-v1/concept.png: rosto de origem'],3:['../gata-lunar-child/concept-v1/concept.png: origem','../noctiluna/concept-v1/concept.png: destino'],4:['../../gambalhote/gambalhote-adult/concept-v2/concept.png: acabamento apenas']}
for item in items:
    F=A/item['id']/'concept-v1';F.mkdir(parents=True,exist_ok=True)
    shutil.copy2(G/item['source'],F/'concept.png')
    (F/'prompt.txt').write_text(item['prompt'],encoding='utf-8')
    (F/'brief.md').write_text('# '+item['name']+' — gata lunar\n\nDefinido pelo autor: linha de gato preto culminando em cavaleira-bruxa de armadura leve e cajado de lua; estudar estrutura de Sakuyamon e manter nosso traço.\n\nProposta: '+item['story']+'\n\nHerança: preto-violeta, marfim, vinho e olhos jade; lua crescente, orelhas triangulares, peito tensionado e rabiola. A membrana participa da ação. Personalidade proposta: cautela curiosa amadurece em autoridade calma. Especialidade proposta: orientar e conter pela tensão das membranas. Limitação proposta: gestos amplos precisam de espaço livre.\n\nNão definidos: nomes finais, elemento, skills, requisitos de evolução, papel canônico e integração. Rabiola segue portando a mesma identidade, sem nova alma no cajado.\n',encoding='utf-8')
    (F/'revisao.md').write_text('# Conferência\n\n'+item['review']+'\n\nConcept proposto, sem aprovação. Contornos e planos amplos coerentes com a direção 2D; ilustração não certificada como pixel art técnico. Sem rig, animação ou integração. Referências externas estudadas não foram inputs de geração.\n',encoding='utf-8')
    im=Image.open(F/'concept.png')
    (F/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen',source=item['source'],sha256=hashlib.sha256((F/'concept.png').read_bytes()).hexdigest(),dimensions=list(im.size),mode=im.mode,alpha='A' in im.getbands(),prompt='prompt.txt',own_reference_inputs=sources[item['stage']],decision_status='proposed',production_status='concept',integration_status='not_integrated'),indent=2,ensure_ascii=False),encoding='utf-8')
    rel='../../../art/creatures/gata-lunar-family-v1/'+item['id']+'/concept-v1/'
    nodes.append(dict(id=item['id'],name=item['name'],kind='stage',stage=item['stage'],maturity=['Bebê','Criança','Jovem','Adulto'][item['stage']-1],identity=item['story'],story=item['story'],decision_status='proposed',production_status='concept',art=rel+'concept.png',brief=rel+'brief.md'))
edges=[dict(**{'from':nodes[i]['id'],'to':nodes[i+1]['id']},kind='reweaving',reason=nodes[i+1]['story'],decision_status='proposed') for i in range(3)]
(D/'chart.json').write_text(json.dumps(dict(family_id='gata-lunar',scope='Concepts de quatro estágios e pesquisa; sem integração.',nodes=nodes,edges=edges),indent=2,ensure_ascii=False),encoding='utf-8')
sheet=Image.new('RGB',(2200,850),'white')
for i,n in enumerate(nodes):
    im=ImageOps.contain(Image.open(D/n['art']).convert('RGB'),(530,760));sheet.paste(im,(550*i+(550-im.width)//2,60+(760-im.height)//2))
    ImageDraw.Draw(sheet).text((550*i+18,20),['Bebe','Crianca','Jovem','Adulta'][i]+' / proposta',fill='black')
sheet.save(D/'familia.png')
(D/'CHART.md').write_text('# Gata lunar — linha proposta\n\nBebê pipa-rosto → criança felina → jovem esguia → Noctiluna, cavaleira-bruxa (nome proposto). Quatro concepts e três ligações propostos. Nomes, elemento e regras permanecem abertos.\n\nO estudo anatômico e a distinção entre referência e criação estão em ESTUDO.md. A adulta mantém juntas móveis, armadura seletiva e cajado lunar como armação; não reproduz o traje de Sakuyamon. A família muda proporções, postura e função de membranas ao crescer.\n\nLimites: leves destaques em algumas bordas; diferentes enquadramentos são normalizados apenas no comparativo. Sem pixel art técnico, rig ou integração.\n',encoding='utf-8')
(D/'fontes.json').write_text(json.dumps([dict(url='https://digimon.net/reference_en/detail.php?directory_name=sakuyamon',title='Sakuyamon — Digimon Encyclopedia',entity='Digimon Web / Bandai',access='2026-11-04',fact='Perfil descreve sacerdotisa, magia xamânica, quatro tubos/raposas e técnica de cajado.',observation='Uma arte oficial inspecionada: corpo esguio, placas seletivas, juntas livres, pose ritual angular e cajado.',application='Proporções adultas e lógica de distribuição da armadura. Forma, paleta, elmo, membranas e cajado redesenhados como gato-pipa lunar.',external_generation_input=False,local_art='referencias/sakuyamon.jpg',art_url='https://digimon.net/cimages/digimon/sakuyamon.jpg')],indent=2,ensure_ascii=False),encoding='utf-8')
cards=''.join('<article><h2>'+html.escape(n['name'])+'</h2><img src="'+n['art']+'" alt="'+html.escape(n['identity'])+'"><p>'+html.escape(n['story'])+'</p><a href="'+n['brief']+'">Brief</a></article>' for n in nodes)
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Gata lunar: linha evolutiva</title><style>body{font:18px system-ui;background:#f4eef6;color:#29212f;margin:40px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:24px}article{background:white;padding:22px;border:1px solid #b9a6ba}img{width:100%;height:420px;object-fit:contain}a:focus{outline:3px solid #982b69}</style><h1>Gata lunar: linha evolutiva</h1><p>Concepts propostos. <a href="ESTUDO.md">Estudo da estrutura e armadura</a></p><main>'+cards+'</main></html>',encoding='utf-8')
(A/'DECISOES.md').write_text('# Gata lunar\n\nAutor pediu linha de gato preto terminando em cavaleira-bruxa, armadura leve com estudo de Sakuyamon e cajado de lua. Quatro concepts gerados como propostas; Noctiluna é nome proposto, sem nomes definidos para os anteriores. Nenhuma aprovação ou integração registrada.\n',encoding='utf-8')
print(D)
if (D/'aprovar.py').exists():
    import runpy
    runpy.run_path(str(D/'aprovar.py'))
