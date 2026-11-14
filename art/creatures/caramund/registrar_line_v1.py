from pathlib import Path
import json,shutil,hashlib,html
from PIL import Image,ImageOps,ImageDraw
A=Path(__file__).resolve().parent
R=A.parents[2]
D=R/'documentation/creatures/caramund-chart-v1';D.mkdir(parents=True,exist_ok=True)
G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f')
items=json.loads((A/'line-v1-geracao.json').read_text(encoding='utf-8'))
nodes=[]
for item in items:
    F=A/item['id']/'concept-v1';F.mkdir(parents=True,exist_ok=True)
    shutil.copy2(G/item['source'],F/'concept.png')
    (F/'prompt.txt').write_text(item['prompt'],encoding='utf-8')
    (F/'brief.md').write_text('# '+item['name']+' — linha caramelo\n\nDefinido pelo autor: gerar bebê, criança e jovem da base Caramund.\n\nProposta: '+item['story']+'\n\nHerança visual: caramelo/marfim/índigo, uma orelha caída, folha verde, nós e rabiola. Gomos e varetas estruturam o corpo em vez de apenas acessórios. Amadurecimento proposto: explorar → proteger → interceptar → aparar e contra-atacar. A resistência tem uma exceção simbolizada pela folha, sem regra de combate definida.\n\nDesconhecidos: nomes finais, elemento, requisitos, níveis, habilidades e papel canônico. Espada surge somente no adulto.\n',encoding='utf-8')
    (F/'revisao.md').write_text('# Conferência\n\n'+item['review']+'\n\nConcept proposto. Sem aprovação, recortes, vistas técnicas, rig ou integração. Ilustração não é pixel art técnico.\n',encoding='utf-8')
    im=Image.open(F/'concept.png')
    refs=[dict(path='../../concept-v1/concept.png',role='Identidade e acabamento do adulto Caramund')]
    if item['stage']==2:refs.append(dict(path='../../caramund-baby/concept-v1/concept.png',role='Continuidade facial do bebê'))
    (F/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen',source=item['source'],sha256=hashlib.sha256((F/'concept.png').read_bytes()).hexdigest(),dimensions=list(im.size),mode=im.mode,alpha='A' in im.getbands(),prompt='prompt.txt',own_reference_inputs=refs,decision_status='proposed',production_status='concept',integration_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
    rel='../../../art/creatures/caramund/'+item['id']+'/concept-v1/'
    nodes.append(dict(id=item['id'],name=item['name']+' (nome pendente)',kind='stage',stage=item['stage'],maturity=item['name'],identity=item['story'],story=item['story'],decision_status='proposed',production_status='concept',art=rel+'concept.png',brief=rel+'brief.md'))
nodes.append(dict(id='caramund',name='Caramund (nome proposto)',kind='stage',stage=4,maturity='Adulto',identity='Cavaleiro caramelo com elmo de orelha caída, ombreira de pipa e folha na proteção.',story='Protege o bairro com postura firme, espada de duas mãos e armadura de grandes escamas.',decision_status='proposed',production_status='concept',art='../../../art/creatures/caramund/concept-v1/concept.png',brief='../../../art/creatures/caramund/concept-v1/brief.md'))
edges=[dict(**{'from':nodes[i]['id'],'to':nodes[i+1]['id']},kind='reweaving',reason=nodes[i+1]['story'],decision_status='proposed') for i in range(3)]
(D/'chart.json').write_text(json.dumps(dict(family_id='caramund',scope='Linha visual proposta, sem integração ou regras de evolução.',nodes=nodes,edges=edges),ensure_ascii=False,indent=2),encoding='utf-8')
sheet=Image.new('RGB',(2200,850),'white')
for i,n in enumerate(nodes):
    im=ImageOps.contain(Image.open(D/n['art']).convert('RGB'),(530,760));sheet.paste(im,(550*i+(550-im.width)//2,60+(760-im.height)//2))
    ImageDraw.Draw(sheet).text((550*i+18,20),['Bebe','Crianca','Jovem','Adulto'][i]+' / proposta',fill='black')
sheet.save(D/'familia.png')
(D/'CHART.md').write_text('# Caramund — linha caramelo\n\nBebê pipa-rosto → criança quadrúpede de peito tensionado → jovem quadrúpede com proteção de escamas → adulto cavaleiro. Formas e ligações propostas; nomes finais e regras indefinidos.\n\nPreserva orelhas assimétricas, caramelo/marfim/índigo, marca de folha e rabiola. Cada estágio muda proporções e ação: descoberta do vento, exploração, interceptação e proteção. A espada é exclusiva do concept adulto.\n\nBase mitológica interpretada como Siegfried/Sigurd, conforme brief anterior; armadura é criação original, não traje histórico definido pela lenda. Marca da folha deslocada para ombreira por legibilidade. A rabiola porta uma identidade almática, sem outra alma no emblema.\n\nLimites: leves transições suaves em cores claras e contagem variável de unhas no jovem. Sem rig, sprites ou integração.\n',encoding='utf-8')
shutil.copy2(A/'concept-v1/fontes.json',D/'fontes.json')
cards=''.join('<article><h2>'+html.escape(n['maturity'])+'</h2><img src="'+n['art']+'" alt="'+html.escape(n['identity'])+'"><p>'+html.escape(n['story'])+'</p><a href="'+n['brief']+'">Brief</a></article>' for n in nodes)
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Caramund: linha caramelo</title><style>body{font:18px system-ui;background:#fbf5e7;color:#302737;margin:40px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:24px}article{background:white;padding:22px;border:1px solid #cdb994}img{width:100%;height:420px;object-fit:contain}a:focus{outline:3px solid #ac5200}</style><h1>Caramund: linha caramelo</h1><p>Bebê → criança → jovem → adulto. Concepts propostos; nomes e regras pendentes.</p><main>'+cards+'</main></html>',encoding='utf-8')
(A/'DECISOES.md').write_text('# Linha caramelo\n\nAutor pediu cavaleiro caramelo inspirado em Sieghart; referência interpretada como Siegfried/Sigurd e explicitada. Depois solicitou bebê, criança e jovem. Quatro concepts atuais propostos; nenhuma aprovação explícita nova registrada. Sem mecânicas ou integração.\n',encoding='utf-8')
print(D)
