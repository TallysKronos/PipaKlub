from pathlib import Path
import json, hashlib, shutil, html
from PIL import Image, ImageOps, ImageDraw

A=Path(__file__).resolve().parent
R=A.parents[2]
D=R/'documentation/creatures/anaconda-retrato-chart-v1'
D.mkdir(parents=True, exist_ok=True)
G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f')
items=json.loads((A/'geracao.json').read_text(encoding='utf-8'))
nodes=[]
defined='Anaconda em quatro estágios; bebê, criança e jovem serpentinos. Adulto cavaleiro de armadura elegante ligado a Dorian Gray, espada fina e cabeças de serpentes esculpidas nas duas ombreiras e duas joelheiras.'
for item in items:
    F=A/item['id']/'concept-v1'; F.mkdir(parents=True,exist_ok=True)
    src=next(G.glob(item['prefix']+'*.png')); dst=F/'concept.png'; shutil.copy2(src,dst)
    (F/'prompt.txt').write_text(item['prompt'],encoding='utf-8')
    (F/'brief.md').write_text('# '+item['name']+'\n\n## Definido pelo autor\n'+defined+'\n\n## Proposta\n'+item['story']+'\nHerança: jade escuro, marfim, dourado contido, nós vinho, manchas ovais e membranas tensionadas. A moldura começa vazia, recebe a silhueta da serpente e termina com o retrato do cavaleiro marcado pelo tempo. Retrato é um objeto de papel vinculado, não outra alma. A rabiola da criatura permanece a sede da almática.\n\nVerbo: '+['proteger-se','explorar','conter','desviar e estocar'][item['stage']-1]+'. Limitação proposta: '+['alcance muito curto','ainda não sustenta grandes tensões','peso restringe mudanças bruscas de direção','esgrima exige distância e guarda precisa'][item['stage']-1]+'.\n\n## Desconhecido\nNomes definitivos, elementos, números de combate, obtenção, requisitos e efeito real do retrato. Não foram decididos nem integrados.\n',encoding='utf-8')
    review=('Figura serpentina sem membros; cabeça, corpo e terminal visíveis. ' if item['stage']<4 else 'Dois braços, duas pernas, uma espada fina completa; duas ombreiras e duas joelheiras com esculturas serpentinas. Cabeça pequena, viseira inferior fechada. ')
    review+='Acabamento observado: contorno escuro limpo, cores amplas e sombra em blocos. São concepts de alta resolução, não pixel art técnico validado. '
    if item['stage']==3: review+='As membranas laterais lembram uma gola aberta; são construção de pipa, não anatomia de capelo de naja. Sobreposição da espira precisa de estudo em vistas antes de rig. '
    if item['stage']==4: review+='A moldura tem um cabo próprio na cintura; numa produção futura, distinguir esse vínculo acessório da rabiola caudal, sem criar segunda almática. O retrato apenas sugere marcas; absorver dano ou envelhecimento é proposta, não regra de gameplay. '
    (F/'revisao.md').write_text('# Conferência\n\n'+review+'\n\nEstado: proposto. Sem vistas adicionais, recortes, rig, animações ou integração.\n',encoding='utf-8')
    im=Image.open(dst)
    refs=['mico-samurai-family-v1/micoshiro/concept-v1/concept.png (somente acabamento)'] if item['stage']==4 else ['Adulto e/ou bebê/criança desta própria família: parentesco e acabamento; sem arte externa como input.']
    (F/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen',source=src.name,sha256=hashlib.sha256(dst.read_bytes()).hexdigest(),dimensions=list(im.size),mode=im.mode,alpha='A' in im.getbands(),prompt='prompt.txt',own_reference_inputs=refs,decision_status='proposed',production_status='concept',integration_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
    rel='../../../art/creatures/anaconda-retrato-family-v1/'+item['id']+'/concept-v1/'
    nodes.append(dict(id=item['id'],name=item['name'],kind='stage',stage=item['stage'],maturity=item['name'],identity='Manchas ovais, membrana marfim, jade escuro, vareta dourada e linha vinho.',story=item['story'],decision_status='proposed',production_status='concept',art=rel+'concept.png',brief=rel+'brief.md'))
edges=[dict(**{'from':nodes[i]['id'],'to':nodes[i+1]['id']},kind='reweaving',reason=nodes[i+1]['story'],decision_status='proposed') for i in range(3)]
(D/'chart.json').write_text(json.dumps(dict(family_id='anaconda-retrato',scope='Quatro concepts; sem gameplay ou integração.',nodes=nodes,edges=edges),ensure_ascii=False,indent=2),encoding='utf-8')
sheet=Image.new('RGB',(2400,900),'white')
draw=ImageDraw.Draw(sheet)
for i,n in enumerate(nodes):
    im=ImageOps.contain(Image.open(D/n['art']).convert('RGB'),(565,790))
    sheet.paste(im,(600*i+(600-im.width)//2,70+(790-im.height)//2))
    draw.text((600*i+20,24),['Bebe','Crianca','Jovem','Adulto / cavaleiro'][i]+' - proposta',fill='#173a30')
sheet.save(D/'familia.png')
(D/'CHART.md').write_text('# Anaconda do retrato — linha proposta\n\nBebê → criança → jovem → adulto cavaleiro. As três primeiras formas permanecem serpentinas. A quarta troca constrição por precisão de esgrima.\n\nDefinido: '+defined+'\n\nProposta de narrativa: proteger a própria imagem, cultivar vaidade e esconder marcas num retrato físico. Não é história canônica nem mecânica aprovada. O retrato não é uma segunda alma. A moldura é vazia na criança, leva uma silhueta no jovem e o cavaleiro no adulto. Manchas viram molduras ovais no traje.\n\nI Cafifa / II Pipa / III Arraia / IV Pandorga: correspondência documental proposta. Ligações de Remonta, custos e nomes próprios continuam indefinidos. Ver ESTUDO.md e as revisões de cada forma.\n',encoding='utf-8')
(D/'ESTUDO.md').write_text('# Pesquisa e tradução autoral\n\n## Anaconda\nSmithsonian, https://nationalzoo.si.edu/animals/green-anaconda — consultado em 2026-11-04. Texto descreve coloração verde-oliva e manchas ovais, grande corpo de constritora e olhos/narinas altos. Tradução: corpo espesso no jovem, marca oval familiar e cabeça baixa; jade/marfim são escolha autoral. Não tratamos o acabamento como zoologia literal. As membranas laterais são pipa, não capelo natural de naja.\n\n## Dorian Gray\nOscar Wilde, The Picture of Dorian Gray, disponibilizado pelo Project Gutenberg: https://www.gutenberg.org/ebooks/26740 — consultado em 2026-11-04. A página de catálogo resume o contraste entre aparência preservada e retrato que registra a degradação. Essa sinopse é identificada pelo site como automática; não afirmamos leitura integral do romance nesta tarefa. Tradução proposta: armadura impecável e retrato de seda com fissuras gráficas, sem copiar ator, adaptação ou figurino.\n\n## Arte e limites\nNenhuma imagem externa entrou na geração. O adulto do mico foi referência própria de acabamento; as formas seguintes usam apenas esta família. Os motivos de joelhos e ombros são esculturas, não quatro cabeças vivas. O vínculo do retrato precisa ser separado semanticamente da rabiola em eventual rig. Não foi atribuído poder definitivo de absorver dano.\n',encoding='utf-8')
cards=''.join('<article><h2>'+html.escape(n['name'])+'</h2><a href="'+n['art']+'"><img src="'+n['art']+'" alt="'+html.escape(n['story'])+'"></a><p>'+html.escape(n['story'])+'</p><a href="'+n['brief']+'">Brief</a></article>' for n in nodes)
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Anaconda do retrato</title><style>body{font:18px system-ui;background:#eef0e7;color:#173a30;margin:32px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:24px}article{padding:24px;background:white;border:1px solid #9baa9d}img{width:100%;height:450px;object-fit:contain}a:focus-visible{outline:3px solid #992d4b}p{line-height:1.5}</style><h1>Anaconda do retrato</h1><p>Quatro concepts propostos. Primeiras três formas serpentinas; adulto cavaleiro. <a href="ESTUDO.md">Pesquisa e limites</a> · <a href="CHART.md">Chart</a></p><main>'+cards+'</main></html>',encoding='utf-8')
(A/'DECISOES.md').write_text('# Decisões\n\n2026-11-04 — autor pediu quatro estágios de anaconda, com adulto cavaleiro elegante ligado a Dorian Gray, espada fina e cabeças esculpidas de serpente nas ombreiras e joelheiras.\n\nQuatro concepts apresentados, ainda propostos. Paleta, retrato, funções e história de vaidade são propostas. Sem integração ou publicação.\n',encoding='utf-8')
print(D)
import runpy
runpy.run_path(str(D/'aprovar.py'))
