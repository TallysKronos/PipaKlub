from pathlib import Path
import os,json,hashlib
from html import escape
from html.parser import HTMLParser
from PIL import Image,ImageOps,ImageDraw,ImageFont
DOC=Path(__file__).resolve().parent;ROOT=DOC.parents[2]
sources=json.loads((DOC/'sources.json').read_text(encoding='utf-8'))
refs=[dict(path='art/soulgen/keys/flautrevo/color-rig-v2/preview.png',role='identidade própria atual'),dict(path='art/creatures/onze-cavaleiros-v1/vesperalia/concept-v1/concept.png',role='destino aprovado'),dict(path='art/creatures/rabbito-family-v1/arauto-da-tempestade/concept-v2/concept.png',role='acabamento aprovado')]
specs=[
 dict(id='sussurim',name='Sussurim',stage=1,age='Bebê',action='Escutar e responder',identity='Uma cabeça-pipa com duas pequenas asas e rabiola curta; sem tronco, braços ou patas.',story='Descobre escuta, equilíbrio e resposta ao primeiro som.',status='proposed',art='art/creatures/flautrevo-family-v1/sussurim/concept-v2/concept.png'),
 dict(id='flautrevo',name='Flautrevo',stage=2,age='Criança existente',action='Recolher notas',identity='Morcego roxo/creme, orelha enrolada, asas com varetas-flauta e rabiola com sino.',story='Recolhe assobios esquecidos e cria trilhas de vento no catálogo existente.',status='approved',approval='README registra revisão final das asas e montagem aprovadas pelo autor; maturidade documental proposta.',art='art/soulgen/keys/flautrevo/color-rig-v2/preview.png',brief='art/soulgen/keys/flautrevo/README.md'),
 dict(id='vesperina',name='Vesperina',stage=3,age='Jovem arauto',action='Sinalizar caminhos',identity='Corpo esguio de pipa, asas grandes, duas mãos e pernas, flauta-galhardete e proteção inicial.',story='Aprende a orientar os outros sem transformar a melodia em imposição.',status='proposed',art='art/creatures/flautrevo-family-v1/vesperina/concept-v1/concept.png'),
 dict(id='vesperalia',name='Vesperália',stage=4,age='Adulta cavaleira',action='Conduzir e proteger',identity='Elmo fechado de orelhas reinterpretadas, armadura completa, asas-flauta e estandarte.',story='Assume responsabilidade de conduzir; voto de respeitar a escolha alheia continua proposta.',status='approved',approval='Autor aprovou a arte concept-v1 com “aprovadíssimo” e pediu bebê e jovem; escopo visual.',art='art/creatures/onze-cavaleiros-v1/vesperalia/concept-v1/concept.png',brief='art/creatures/onze-cavaleiros-v1/vesperalia/concept-v1/brief.md')]
nodes=[]
for s in specs:
 image=ROOT/s['art'];folder=image.parent
 if s['id']in sources:
  brief=folder/'brief.md';s['brief']=str(brief.relative_to(ROOT)).replace('\\','/')
  brief.write_text(f'''# {s['name']} — proposta {s['age']}\n\nDefinido: novo bebê e jovem anteriores à adulta Vesperália aprovada, mantendo Flautrevo existente. Nome e anatomia nova continuam propostas.\nIdentidade: {s['identity']}\nVerbo: {s['action']}. Interpretação: {s['story']}\nHerança: roxo/creme, olhos âmbar, orelhas diferentes, uma em voluta; varetas-flauta douradas e rabiola azul-petróleo inteira com sino. Um só indivíduo, alma preservada na rabiola.\nBebê tem corpo compacto, asas curtas e pouco equipamento; jovem muda proporções, ação e proteção, preparando postura da cavaleira.\nAcabamento 45/45/10: construção de pipa viva, contorno limpo, cores amplas e sombras cel simples. Sem tesselação ou textura 3D.\nNão define atributo, obtenção, receita, idade de banco ou novo papel canônico. Não é rig, integração ou pixel art técnico.\n''',encoding='utf-8')
  brief.write_text(brief.read_text(encoding='utf-8').replace('Bebê tem corpo compacto, asas curtas e pouco equipamento','Bebê tem apenas cabeça-pipa, duas asas simples e rabiola, sem tronco ou patas'),encoding='utf-8')
  input_refs=[dict(path='art/creatures/flautrevo-family-v1/sussurim/concept-v1/concept.png',role='alvo de simplificação'),dict(path='art/soulgen/keys/flautrevo/color-rig-v2/preview.png',role='identidade própria')]if s['id']=='sussurim'else refs
  with Image.open(image)as im:manifest=dict(id=s['id'],tool='image_gen.imagegen',source=sources[s['id']],sha256=hashlib.sha256(image.read_bytes()).hexdigest(),width=im.width,height=im.height,mode=im.mode,alpha='A'in im.getbands(),prompt='prompt.txt',references=input_refs,decision_status='proposed',production_status='concept',implementation='não integrado',technical_pixel_art=False)
  (folder/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
 relative=lambda p:os.path.relpath(ROOT/p,DOC).replace('\\','/')
 node=dict(id=s['id'],name=s['name'],kind='stage',stage=s['stage'],age=s['age'],action=s['action'],identity=s['identity'],story=s['story'],decision_status=s['status'],production_status='concept',implementation='não integrado por este estudo',art=relative(s['art']),brief=relative(s['brief']))
 if s['status']=='approved':node['approval_note']=s['approval']
 nodes.append(node)
edges=[dict(**{'from':a,'to':b},kind='reweaving',decision_status='proposed',reason=r)for a,b,r in[('sussurim','flautrevo','Escutar e equilibrar-se prepara as primeiras trilhas de notas.'),('flautrevo','vesperina','Novos apoios e sinais permitem orientar outros.'),('vesperina','vesperalia','O gesto de arauto assume armadura e estandarte; corpo se reorganiza sem trocar a alma.')]]
(DOC/'chart.json').write_text(json.dumps(dict(family_id='flautrevo',scope='Dois concepts novos e duas bases preservadas; maturidade documental, sem integração.',nodes=nodes,edges=edges),ensure_ascii=False,indent=2),encoding='utf-8')
mini=DOC/'miniaturas';mini.mkdir(exist_ok=True)
for n in nodes:
 with Image.open(DOC/n['art'])as im:
  rgba=im.convert('RGBA');box=rgba.getchannel('A').getbbox()
  if box:rgba=rgba.crop(box)
  white=Image.new('RGBA',rgba.size,'white');white.alpha_composite(rgba);t=ImageOps.contain(white.convert('RGB'),(700,600),Image.Resampling.LANCZOS)
 t.save(mini/(n['id']+'.png'))
sheet=Image.new('RGB',(1600,1420),'white');draw=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',25)
for i,n in enumerate(nodes):
 x,y=i%2*800,i//2*710
 with Image.open(mini/(n['id']+'.png'))as im:
  t=ImageOps.contain(im,(750,600),Image.Resampling.LANCZOS);sheet.paste(t,(x+(800-t.width)//2,y+(610-t.height)//2))
 draw.text((x+25,y+630),n['name']+' · '+n['age'],font=font,fill='#35253e')
sheet.save(DOC/'familia.png')
cards=''.join(f'<article><h2>{escape(n["name"])}</h2><p>{n["age"]} · {"visual aprovado"if n["decision_status"]=="approved"else"proposta"}</p><a href="{n["art"]}"><img src="miniaturas/{n["id"]}.png" alt="{escape(n["identity"])}"></a><h3>{n["action"]}</h3><p>{n["story"]}</p><a href="{n["art"]}">Arte completa</a> · <a href="{n["brief"]}">Brief e origem</a></article>'for n in nodes)
page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Flautrevo · do primeiro eco ao estandarte</title><style>*{box-sizing:border-box}body{margin:0;background:#f5f1e9;color:#32293b;font:17px/1.6 system-ui}header{background:#39233f;color:#fff4dc;padding:38px max(24px,calc((100vw - 1180px)/2))}h1{font-size:clamp(28px,4vw,43px);line-height:1.2}main{max-width:1230px;margin:auto;padding:24px}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}article{padding:25px;background:white;border:1px solid #d5c7ce}h2{margin:0}img{width:100%;height:450px;object-fit:contain}a{color:#78355f;text-underline-offset:4px}a:focus-visible{outline:3px solid #15868b;outline-offset:5px}header a{color:#ffe2a4}.note{padding:20px;border-left:4px solid #903f74;background:#fff8eb;margin-bottom:25px}@media(max-width:650px){.grid{grid-template-columns:1fr}img{height:350px}}</style><header><h1>Flautrevo · do primeiro eco ao estandarte</h1><p>Sussurim → Flautrevo → Vesperina → Vesperália</p><a href="familia.png">Comparar família</a> · <a href="CHART.md">Decisões e continuidade</a></header><main><aside class="note">Bebê e jovem: novos concepts em avaliação. Flautrevo e adulta: aprovações visuais anteriores preservadas. Novos nomes, ligações e requisitos são propostas; sem integração.</aside><section class="grid">'''+cards+'''</section><p>A montagem não representa escala física canônica. <a href="chart.json">Chart documental</a>.</p></main></html>'''
(DOC/'index.html').write_text(page,encoding='utf-8')
class Check(HTMLParser):
 def __init__(self):super().__init__();self.links=[]
 def handle_starttag(self,t,attrs):
  for k,v in attrs:
   if k in['href','src']:self.links.append(v)
c=Check();c.feed(page);errors=[l for l in c.links if not(DOC/l).is_file()]
result=dict(ok=not errors,nodes=4,edges=3,new_concepts=2,missing=errors,scope='Arquivos, hashes, imagens e links; não teste de navegador, animação ou jogo.')
(DOC/'validacao.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(result,ensure_ascii=True));raise SystemExit(bool(errors))
