from pathlib import Path
import json,shutil,hashlib,html
from PIL import Image,ImageOps,ImageDraw
A=Path(__file__).resolve().parent
R=A.parents[2]
D=R/'documentation/creatures/gambalhote-chart-v1'
D.mkdir(parents=True,exist_ok=True)
G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f')
items=json.loads((A/'line-v1-geracao.json').read_text(encoding='utf-8'))
nodes=[]
for item in items:
    F=A/item['id']/'concept-v1'; F.mkdir(parents=True,exist_ok=True)
    shutil.copy2(G/item['source'],F/'concept.png')
    (F/'prompt.txt').write_text(item['prompt'],encoding='utf-8')
    (F/'brief.md').write_text('# '+item['name']+' do Gambalhote — proposta\n\nDefinido pelo autor: bebê, jovem e adulto. Adulto cavaleiro manipulado por pipa suspensa, elmo com shape de gambá cobrindo olhos e parte inferior facial humanoide; referência de linguagem de armadura Beelzebumon.\n\nProposta: '+item['story']+'\n\nHerança: marfim/carvão, petróleo/coral, orelhas arredondadas, focinho-vareta e nós. Ação: articular, falsear e conter usando fios. Limitação proposta: perda de tensão nos fios compromete precisão. Bebê explora; jovem coordena o corpo; adulto atua com precisão por intermédio da armadura.\n\nNão decidido: nomes finais, elemento, habilidades, níveis, obtenção, regras de controle. Uma única identidade almática; rabiola preservada, não um novo parceiro ou Entrelaço.\n',encoding='utf-8')
    (F/'revisao.md').write_text('# Conferência\n\n'+item['review']+'\n\nConcept proposto, aprovação pendente. Sem recortes, rig, animação ou integração. Ilustração raster não é pixel art técnico. Apenas referências próprias usadas como inputs de geração.\n',encoding='utf-8')
    im=Image.open(F/'concept.png')
    refs=[dict(path='../../concept-v1/concept.png',role='Identidade e acabamento do Gambalhote')]
    if item['stage']==4: refs.append(dict(path='../../../onze-cavaleiros-v1/yaguarion/concept-v2/concept.png',role='Regra do elmo e maturidade facial, sem transferir espécie ou paleta'))
    (F/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen',source=item['source'],sha256=hashlib.sha256((F/'concept.png').read_bytes()).hexdigest(),dimensions=list(im.size),mode=im.mode,alpha='A' in im.getbands(),prompt='prompt.txt',own_reference_inputs=refs,decision_status='proposed',production_status='concept',integration_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
    rel='../../../art/creatures/gambalhote/'+item['id']+'/concept-v1/'
    nodes.append(dict(id=item['id'],name=item['name']+' (nome pendente)',kind='stage',stage=item['stage'],maturity=item['name'],identity=item['story'],story=item['story'],decision_status='proposed',production_status='concept',art=rel+'concept.png',brief=rel+'brief.md'))
note='Autor: "ótimo crie uma baby, uma jovem, e uma adulto", em 2026-11-04, aceita o concept anterior como base da linha. Aprovação visual da base; nomes e mecânicas seguem propostas.'
base=A/'concept-v1'
m=json.loads((base/'manifest.json').read_text(encoding='utf-8'));m.update(decision_status='approved',approval_note=note)
(base/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
rev=base/'revisao.md';content=rev.read_text(encoding='utf-8')
if note not in content:rev.write_text(content+'\n\n## Aprovação posterior da base\n\n'+note+'\n',encoding='utf-8')
nodes.append(dict(id='gambalhote',name='Gambalhote (nome proposto)',kind='stage',stage=2,maturity='Criança',identity='Gambá-pipa com focinho de vareta e cauda que controla cruzeta.',story='Aprende a manipular os próprios braços e a blefar com o alcance do focinho.',decision_status='approved',approval_note=note,production_status='concept',art='../../../art/creatures/gambalhote/concept-v1/concept.png',brief='../../../art/creatures/gambalhote/concept-v1/brief.md'))
nodes.sort(key=lambda n:n['stage'])
edges=[dict(**{'from':nodes[i]['id'],'to':nodes[i+1]['id']},kind='reweaving',reason=nodes[i+1]['story'],decision_status='proposed') for i in range(3)]
(D/'chart.json').write_text(json.dumps(dict(family_id='gambalhote',scope='Linha de concepts; base aceita, destinos propostos. Sem integração.',nodes=nodes,edges=edges),ensure_ascii=False,indent=2),encoding='utf-8')
sheet=Image.new('RGB',(2200,850),'white')
for i,n in enumerate(nodes):
    im=ImageOps.contain(Image.open(D/n['art']).convert('RGB'),(530,760))
    sheet.paste(im,(550*i+(550-im.width)//2,60+(760-im.height)//2))
    label=['Bebe / proposta','Crianca / base aceita','Jovem / proposta','Adulto / proposta'][i]
    ImageDraw.Draw(sheet).text((550*i+18,20),label,fill='black')
sheet.save(D/'familia.png')
(D/'CHART.md').write_text('# Gambalhote — linha de marionetes\n\nBebê pipa-rosto → criança que manipula braços → jovem que articula quatro membros → adulto pipa-cavaleiro. Gambalhote é nome proposto; destinos sem nomes finais. Base aceita pelo autor; as três novas artes aguardam aprovação.\n\nAdulto definido: cavaleiro escuro, pipa suspensa manipulando o corpo, elmo de gambá e boca humanoide. Interpretação proposta: uma identidade, rabiola vinculada à pipa superior, sem duas almas e sem Entrelaço. Narrativa proposta: domínio crescente do gesto e do blefe. Não define regras de combate.\n\nBeelzebumon estudado por perfil e arte oficial local: base flexível escura, volumes articulados e contraste entre corpo estreito e extremidades. Aplicação original: placas carvão, juntas livres, nó e membrana de pipa no peito. Não transportados armas de fogo, motocicleta, terceiro olho, figurino ou silhueta exata. Yaguarion próprio usado para regra facial do elmo.\n\nRevisão: jovem tem percursos de fio parcialmente sobrepostos; adulto tem marcas de superfície a simplificar para sprites. Sem produção técnica ou integração.\n',encoding='utf-8')
sources=json.loads((base/'fontes.json').read_text(encoding='utf-8'))
sources.append(dict(url='https://digimon.net/reference_en/detail.php?directory_name=beelzebumon',title='Beelzemon — Digimon Encyclopedia',entity='Digimon Web / Bandai',access='2026-11-04',fact='Perfil e arte oficial consultados; arte também disponível no benchmark local papel-collie.',observation='Leitura visual: estrutura esguia, base escura flexível, placas sobre articulações, grandes extremidades.',application='Contraste de volumes e segmentação original de armadura; armas e desenho específico não transferidos.',external_generation_input=False))
(D/'fontes.json').write_text(json.dumps(sources,ensure_ascii=False,indent=2),encoding='utf-8')
cards=''.join('<article><h2>'+html.escape(n['maturity'])+'</h2><img src="'+n['art']+'" alt="'+html.escape(n['identity'])+'"><p>'+html.escape(n['story'])+'</p><p>'+('Base aceita' if n['decision_status']=='approved' else 'Proposta')+'</p><a href="'+n['brief']+'">Brief</a></article>' for n in nodes)
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Gambalhote: linha evolutiva</title><style>body{font:18px system-ui;background:#f6f2e9;color:#29262b;margin:40px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:24px}article{background:white;padding:22px;border:1px solid #b8b1a8}img{width:100%;height:420px;object-fit:contain}a:focus{outline:3px solid #008c91}</style><h1>Gambalhote: linha evolutiva</h1><p>Bebê → criança → jovem → adulto. Nomes dos destinos pendentes.</p><main>'+cards+'</main></html>',encoding='utf-8')
(A/'DECISOES.md').write_text('# Linha do Gambalhote\n\n'+note+'\n\n2026-11-04: autor pediu bebê, jovem e adulto cavaleiro, com pipa superior manipulando-o, elmo de gambá e boca humanoide. Três concepts gerados como propostas. Mecânicas, nomes e integração não definidos.\n',encoding='utf-8')
print(D)
if (D/'aplicar_acabamento_v2.py').exists():
    import runpy
    runpy.run_path(str(D/'aplicar_acabamento_v2.py'))
