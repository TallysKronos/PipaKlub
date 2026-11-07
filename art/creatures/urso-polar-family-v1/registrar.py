from pathlib import Path
import json,hashlib,shutil,html
from PIL import Image,ImageOps,ImageDraw
A=Path(__file__).resolve().parent;R=A.parents[2]
D=R/'documentation/creatures/urso-polar-chart-v1';D.mkdir(parents=True,exist_ok=True)
G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f')
items=json.loads((A/'geracao.json').read_text(encoding='utf-8'))
refs={1:['borealvo/concept-v1/concept.png: identidade e acabamento'],2:['borealvo/concept-v1/concept.png: destino','urso-polar-baby/concept-v1/concept.png: origem'],3:['urso-polar-child/concept-v1/concept.png: origem','borealvo/concept-v1/concept.png: destino'],4:['../gambalhote/gambalhote-adult/concept-v2/concept.png: acabamento apenas']}
nodes=[]
for item in items:
    F=A/item['id']/'concept-v1';F.mkdir(parents=True,exist_ok=True)
    shutil.copy2(G/item['source'],F/'concept.png')
    (F/'prompt.txt').write_text(item['prompt'],encoding='utf-8')
    (F/'brief.md').write_text('# '+item['name']+' — linha polar\n\nDefinido pelo autor: evo line de urso polar; adulto pode usar BanchoLeomon e Vikemon como referências. Preservar traço autoral.\n\nProposta: '+item['story']+'\n\nHerança: marfim, azul-frio, turquesa, faixas azul-marinho, nós cinábrio e rabiola. Patas e proteção são membranas tensionadas com suporte de varetas, não animal comum fantasiado. Verbo da família: estabilizar → apoiar → sustentar → abrir caminho. Limitação proposta: massa e superfície largas dificultam mudanças bruscas de direção. Malho só aparece no adulto.\n\nNão definidos: nomes finais, elemento, skills, obtenção, níveis e regras. Rabiola porta uma identidade; ferramenta sem alma adicional.\n',encoding='utf-8')
    (F/'revisao.md').write_text('# Conferência\n\n'+item['review']+'\n\nConcept proposto; sem aprovação. Sem vistas técnicas, recortes, rig, animação ou integração. Imagem raster não certificada como pixel art técnico. Referências externas estudadas não entram na geração.\n',encoding='utf-8')
    im=Image.open(F/'concept.png')
    (F/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen',source=item['source'],sha256=hashlib.sha256((F/'concept.png').read_bytes()).hexdigest(),dimensions=list(im.size),mode=im.mode,alpha='A' in im.getbands(),prompt='prompt.txt',own_reference_inputs=refs[item['stage']],reference_paths_relative_to='art/creatures/urso-polar-family-v1',decision_status='proposed',production_status='concept',integration_status='not_integrated'),indent=2,ensure_ascii=False),encoding='utf-8')
    rel='../../../art/creatures/urso-polar-family-v1/'+item['id']+'/concept-v1/'
    nodes.append(dict(id=item['id'],name=item['name'],kind='stage',stage=item['stage'],maturity=['Bebê','Criança','Jovem','Adulto'][item['stage']-1],identity=item['story'],story=item['story'],decision_status='proposed',production_status='concept',art=rel+'concept.png',brief=rel+'brief.md'))
edges=[dict(**{'from':nodes[i]['id'],'to':nodes[i+1]['id']},kind='reweaving',reason=nodes[i+1]['story'],decision_status='proposed') for i in range(3)]
(D/'chart.json').write_text(json.dumps(dict(family_id='urso-polar',scope='Quatro concepts propostos; pesquisa de referências; sem integração.',nodes=nodes,edges=edges),indent=2,ensure_ascii=False),encoding='utf-8')
sheet=Image.new('RGB',(2200,850),'white')
for i,n in enumerate(nodes):
    im=ImageOps.contain(Image.open(D/n['art']).convert('RGB'),(530,760));sheet.paste(im,(550*i+(550-im.width)//2,60+(760-im.height)//2))
    ImageDraw.Draw(sheet).text((550*i+18,20),['Bebe','Crianca','Jovem','Adulto'][i]+' / proposta',fill='black')
sheet.save(D/'familia.png')
(D/'CHART.md').write_text('# Urso polar — linha quebra-gelo\n\nBebê pipa-bloco → criança de patas largas → jovem quadrúpede com braceletes de membrana → adulto Borealvo, chefe quebra-gelo (nome proposto). Quatro concepts propostos, três ligações propostas. Nomes finais e regras abertos.\n\nPesquisa visual e distinção entre referência e design próprio em ESTUDO.md. Forma adulta combina postura vertical de líder e peso polar; mantém rosto ursino e construção de pipa sem traje copiado. Histórias e especialidades são propostas.\n\nLimites: contagem variável de unhas e alguns destaques/transições suaves no claro; não são sprites ou folhas técnicas. Sem integração.\n',encoding='utf-8')
(D/'fontes.json').write_text(json.dumps([dict(url='https://digimon.net/reference_en/detail.php?directory_name='+slug,title=name+' — Digimon Encyclopedia',entity='Digimon Web / Bandai',access='2026-11-04',fact=fact,observation=obs,application=app,external_generation_input=False,local_art='referencias/'+slug+'.jpg',art_url='https://digimon.net/cimages/digimon/'+slug+'.jpg') for slug,name,fact,obs,app in [('bancholeomon','BanchoLeomon','Perfil enfatiza senso próprio de justiça, peça sobre os ombros como defesa e golpe de punho.','Cabeça pequena, pernas plantadas e silhueta prolongada pela peça dos ombros.','Postura de chefe e manto funcional; sem uniforme, espada ou juba.'),('vikemon','Vikemon','Perfil enfatiza liderança ártica, arma pesada e cuidado com subordinados.','Massa corporal larga, mãos e pés grandes e cabeça pequena.','Peso, apoio e ferramenta de impacto; sem presas, elmo e arma específica.')]],indent=2,ensure_ascii=False),encoding='utf-8')
cards=''.join('<article><h2>'+html.escape(n['name'])+'</h2><img src="'+n['art']+'" alt="'+html.escape(n['identity'])+'"><p>'+html.escape(n['story'])+'</p><a href="'+n['brief']+'">Brief</a></article>' for n in nodes)
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Urso polar: linha evolutiva</title><style>body{font:18px system-ui;background:#edf4f6;color:#182b40;margin:40px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:24px}article{background:white;padding:22px;border:1px solid #99b8bf}img{width:100%;height:420px;object-fit:contain}a:focus{outline:3px solid #be3b30}</style><h1>Urso polar: linha evolutiva</h1><p>Concepts propostos. <a href="ESTUDO.md">Estudo das referências</a></p><main>'+cards+'</main></html>',encoding='utf-8')
(A/'DECISOES.md').write_text('# Urso polar\n\nAutor pediu evo line de urso polar com BanchoLeomon e Vikemon como referências possíveis do adulto. Quatro concepts gerados como propostas; Borealvo nome proposto. Sem aprovação de nomes, design, mecânicas ou integração.\n',encoding='utf-8')
print(D)
if (D/'aplicar_cabeca_v2.py').exists():
    import runpy
    runpy.run_path(str(D/'aplicar_cabeca_v2.py'))
