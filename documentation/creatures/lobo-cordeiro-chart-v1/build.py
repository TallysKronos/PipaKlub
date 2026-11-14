"""Documentação de quatro concepts, sem escrever no jogo ou rigs."""
import hashlib,html,json
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
DOC=Path(__file__).resolve().parent;ROOT=DOC.parents[2];ART=ROOT/'art/creatures/lobo-cordeiro-family-v1'
SPECS=[
 ('lanzinho','Lãzinho',1,'Bebê','Espiar e recolher','Botão de lã de papel, focinho pequeno espiando, quatro patas curtas e vela enrolada.', 'Aprende quando se recolher e quando se aproximar.', 'Manto fechado e pequenos apoios conservam o equilíbrio.', 'Alcance e sustentação pequenos.'),
 ('fiafalso','Fiafalso',3,'Jovem','Revelar e desviar','Lobo esguio de pernas longas e manto dividido em duas abas de envelope.', 'Começa a escolher quando mostrar o próprio corpo em vez de somente esconder.', 'Abas abertas revelam apoios leves; quilha dorsal orienta a esquiva.', 'Manto aberto oferece menos cobertura imediata.'),
 ('velalvo','Velalvo',4,'Adulto natural','Abrigar e guardar','Quadrúpede compacto de peito amplo; lã e vela viram dois grandes painéis de abrigo.', 'A cobertura que escondia passa a abrigar outros.', 'Bordas de vareta e grandes curvas da lã sustentam pressão e cobertura.', 'Painéis largos comprometem agilidade em espaços estreitos.'),
 ('voto-do-elo','Voto do Elo',None,'Guerreiro · especial','Interpor a proteção','Lobo bípede digitígrado; pelagem convertida em placas de papel-armadura, Nó do Elo no peitoral.', 'O abrigo se transforma em proteção ativa sem ocultar a identidade do lobo.', 'Grandes curvas da pelagem condensam-se em placas articuladas por nós; patas e juntas ficam livres.', 'Maior proteção reduz a capacidade de recolher o manto e se disfarçar.'),
]
sources=json.loads((DOC/'sources.json').read_text(encoding='utf-8'));nodes=[]
for ident,name,stage,age,action,anatomy,story,mechanism,limit in SPECS:
 folder=ART/ident/'concept-v1';image=folder/'concept.png'
 if not image.is_file()or not(folder/'prompt.txt').is_file():raise FileNotFoundError(folder)
 brief=f'''# {name} — concept proposto

## Definido pelo autor
Bebê, jovem, adulto e guerreiro lobo; pelagem vira armadura; símbolo de Eremor no peito. Base Soulgen editada pelo autor fica intacta. Novo nome/design, níveis, receitas e filiação narrativa ainda não aprovados.

## Observado e proposto
Herança: lobo carvão com olhos âmbar e marcas vermelhas, manto creme de lã de papel, vela dorsal e rabiola com fio e três bandeirolas grandes. Sino do concept antigo não é âncora obrigatória porque não integra o rig atual.
Maturidade: {age}. Anatomia: {anatomy}
Verbo: {action}. Construção: {mechanism}
História interpretativa: {story}
Limitação proposta: {limit}

## Símbolo e acabamento
Eremor tem Nó do Elo terracota com acento turquesa no conceito próprio. No guerreiro, vira emblema proposto da couraça; isso não cria ordem, divindade ou juramento canônico. Royal Knights estudados em perfis oficiais, sem usar suas imagens na geração ou copiar design.
Contorno marinho nítido, planos amplos e poucas dobras; equilíbrio autoral45/45/10. Concept raster, não grid técnico, rig ou integração.
'''
 (folder/'brief.md').write_text(brief,encoding='utf-8')
 refs=[{'path':'art/soulgen/keys/lobo-cordeiro/concept-v1/lobo-cordeiro.png','role':'Identidade própria'}, {'path':'art/creatures/rabbito-family-v1/arauto-da-tempestade/concept-v2/concept.png','role':'Acabamento aprovado'}]
 if ident=='voto-do-elo':refs.append({'path':'art/concepts/eremor-v1/eremor.png','role':'Somente nó terracota/turquesa do peito'})
 with Image.open(image)as im:
  manifest=dict(id=ident,tool='image_gen.imagegen',source=sources[ident],sha256=hashlib.sha256(image.read_bytes()).hexdigest(),width=im.width,height=im.height,mode=im.mode,alpha='A'in im.getbands(),references=refs,prompt='prompt.txt',decision_status='proposed',production_status='concept',implementation='não integrado',technical_pixel_art=False)
 (folder/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
 nodes.append(dict(id=ident,name=name,stage=stage,kind='configuration'if stage is None else'stage',age=age,identity=anatomy,story=story,action=action,mechanism=mechanism,tradeoff=limit,decision_status='proposed',production_status='concept',implementation='não integrado',art=f'../../../art/creatures/lobo-cordeiro-family-v1/{ident}/concept-v1/concept.png',brief=f'../../../art/creatures/lobo-cordeiro-family-v1/{ident}/concept-v1/brief.md'))
nodes.insert(1,dict(id='lobo-cordeiro',name='Lobo em pele de cordeiro',stage=2,kind='stage',age='Base · criança no estudo',identity='Lobo carvão coberto por papel-lã creme, vermelho e vela de pipa.',story='Identidade e montagem do autor preservadas; associação de maturidade é proposta.',decision_status='approved',approval_note='Referência própria e projeto editado pelo autor em art/soulgen/keys/lobo-cordeiro; não certifica estágio mecânico.',production_status='concept',implementation='base preservada',art='../../../art/soulgen/keys/lobo-cordeiro/concept-v1/lobo-cordeiro.png',brief='../../../art/soulgen/keys/lobo-cordeiro/README.md'))
edges=[{'from':a,'to':b,'kind':k,'decision_status':'proposed','reason':r}for a,b,k,r in [('lanzinho','lobo-cordeiro','reweaving','O botão começa a explorar sem perder sua cobertura.'),('lobo-cordeiro','fiafalso','reweaving','Escolher quando aparecer alonga apoios e divide o manto.'),('fiafalso','velalvo','reweaving','Revelar-se amadurece em oferecer abrigo.'),('velalvo','voto-do-elo','configuration','O manto condensa as próprias dobras em placas protetoras; não é quinto estágio.')]]
data=dict(family_id='lobo-cordeiro',scope='Quatro concepts e base intacta; sem integração.',nodes=nodes,edges=edges)
(DOC/'chart.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
mini=DOC/'miniaturas';mini.mkdir(exist_ok=True)
for n in nodes:
 with Image.open(DOC/n['art'])as im:
  rgba=im.convert('RGBA');b=rgba.getchannel('A').getbbox()
  if b:rgba=rgba.crop(b)
  white=Image.new('RGBA',rgba.size,'white');white.alpha_composite(rgba);t=ImageOps.contain(white.convert('RGB'),(620,530),Image.Resampling.LANCZOS)
 t.save(mini/f"{n['id']}.png")
page=(DOC.parent/'carcara-chart-v1/index.html').read_text(encoding='utf-8')
s=page.index('const data=')+len('const data=');e=page.index(';function select',s);page=page[:s]+json.dumps(data,ensure_ascii=False)+page[e:]
s=page.index('<section class="grid"');s=page.index('>',s)+1;e=page.index('</section>',s)
cards=''.join(f'<button data-id="{n["id"]}" aria-pressed="false"><img src="miniaturas/{n["id"]}.png" alt="{html.escape(n["name"])}"><strong>{n["name"]}</strong><span>{n["age"]}</span></button>'for n in nodes)
page=page[:s]+cards+page[e:]
page=page.replace('Carcará · aprender a corrente','Lobo e cordeiro · a cobertura que protege').replace('TRÊS NOVOS CONCEPTS · APROVADOS','QUATRO NOVOS CONCEPTS · PROPOSTAS')
page=page.replace('Do primeiro equilíbrio ao voo econômico que outros podem acompanhar. Identidade quente e rabiola dupla preservadas; novas proporções, silhuetas e funções a cada maturidade.','Do botão recolhido ao adulto que abriga. Na forma guerreira, a pelagem se torna armadura e recebe no peito uma reinterpretação do nó de Eremor. Novos nomes e designs em avaliação.')
page=page.replace('I · Carquim (bebê) → II · Carcará (base) → III · Caravento (jovem) → IV · Caramastro (adulto)','Lãzinho → Lobo em pele de cordeiro → Fiafalso → Velalvo → Voto do Elo (configuração especial). Graus mecânicos e obtenção não definidos.')
page=page.replace(":'carcara'",":'voto-do-elo'")
(DOC/'index.html').write_text(page,encoding='utf-8');(DOC/'viewer-script.js').write_text(page.split('<script>')[1].split('</script>')[0],encoding='utf-8')
sheet=Image.new('RGB',(1800,1240),'white');draw=ImageDraw.Draw(sheet)
try:font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24)
except OSError:font=ImageFont.load_default()
for i,n in enumerate(nodes):
 x,y=(i%3)*600,(i//3)*620
 with Image.open(mini/f"{n['id']}.png")as im:
  t=ImageOps.contain(im,(565,530),Image.Resampling.LANCZOS);sheet.paste(t,(x+(600-t.width)//2,y+(540-t.height)//2))
 draw.text((x+18,y+560),n['name'],font=font,fill='#3f2635')
sheet.save(DOC/'familia.png')
for n in nodes:
 for key in ['art','brief']:
  if not(DOC/n[key]).is_file():raise FileNotFoundError(n[key])
print(json.dumps({'nodes':len(nodes),'edges':len(edges),'new_concepts':4,'index':str(DOC/'index.html')}))
