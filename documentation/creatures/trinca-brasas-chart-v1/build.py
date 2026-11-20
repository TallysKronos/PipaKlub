from pathlib import Path
from html import escape
from html.parser import HTMLParser
from PIL import Image,ImageOps,ImageDraw,ImageFont
import json,hashlib
DOC=Path(__file__).resolve().parent;ROOT=DOC.parents[2]
ART=ROOT/'art/creatures/trinca-brasas-family-v1'
sources=json.loads((DOC/'sources.json').read_text(encoding='utf-8'))
specs=[
 ('braseco','Braseco',1,'Bebê','Espiar em conjunto','Corpo baixo de envelope de papel, três pequenas cabeças e quatro patas curtas.','Aprende a coordenar três focos de atenção num só indivíduo.','Novo nome e design propostos.'),
 ('trinca-brasas','Trinca-brasas',2,'Criança existente','Explorar e proteger','Três cabeças caninas, corpo pequeno carvão/laranja, chaves e rabiola de três folhas.','Companhia, coragem e proteção do lar constam no catálogo existente.','Montagem final aprovada, registrada no README do Soulgen; associação de maturidade é documental.'),
 ('trincaguarda','Trincaguarda',3,'Jovem quadrúpede','Interpor e vigiar','Cão tricéfalo quadrúpede, peito alto, cintura e primeiras placas de guarda.','A vigilância passa a ser sustentada pelo corpo e pela coordenação.','Novo nome e design propostos; quadrupedia definida pelo autor.'),
 ('tricordio','Tricórdio',4,'Adulto cavaleiro','Guardar e deliberar','Cabeça de elmo fechado, ombreiras caninas, couraça/escudo de copas, lança e chaves.','A proteção ganha intenção e instrumentos; voto de ouvir antes de julgar continua proposta.','Autor aprovou concept-v4 com “aprovado”; aprovação visual, não receita ou história.')]
nodes=[]
refs=[dict(path='art/soulgen/keys/trinca-brasas/color-rig-v2/preview.png',role='identidade da montagem aprovada'),dict(path='art/creatures/onze-cavaleiros-v1/tricordio/concept-v4/concept.png',role='destino aprovado'),dict(path='art/creatures/rabbito-family-v1/arauto-da-tempestade/concept-v2/concept.png',role='acabamento aprovado')]
for ident,name,stage,age,action,identity,story,note in specs:
 if ident=='trinca-brasas':image=ROOT/'art/soulgen/keys/trinca-brasas/color-rig-v2/preview.png';brief=ROOT/'art/soulgen/keys/trinca-brasas/README.md'
 elif ident=='tricordio':image=ROOT/'art/creatures/onze-cavaleiros-v1/tricordio/concept-v4/concept.png';brief=image.parent/'brief.md'
 else:
  folder=ART/ident/'concept-v1';image=folder/'concept.png';brief=folder/'brief.md'
  brief.write_text(f'''# {name} — {age}\n\nDefinido: bebê e jovem anteriores ao cavaleiro aprovado, jovem quadrúpede. Base Trinca-brasas preservada.\nProposta: nome {name}, anatomia específica e relação de maturidade documental.\nAnatomia: {identity}\nVerbo: {action}. História interpretativa: {story}\nHerança: carvão/laranja, focinhos creme antes do elmo, olhos âmbar, marca dourada, chaves e rabiola de três folhas. Bebê tem apenas uma pequena etiqueta-chave, menos equipamento que a criança; jovem começa a formar copas nas placas.\nUma alma e um corpo compartilhado, três cabeças não equivalem a três almas. Rabiola permanece inteira.\nAcabamento 45/45/10, planos amplos e sombra cel simples; não tesselação ou render metálico.\nNão integrado; não define obtenção, receitas, estágio de banco ou novo papel canônico. Concept raster não certifica rig.\n''',encoding='utf-8')
  with Image.open(image)as im:manifest=dict(id=ident,tool='image_gen.imagegen',source=sources[ident],sha256=hashlib.sha256(image.read_bytes()).hexdigest(),width=im.width,height=im.height,mode=im.mode,alpha='A'in im.getbands(),references=refs,prompt='prompt.txt',decision_status='proposed',production_status='concept',implementation='não integrado',technical_pixel_art=False)
  (folder/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
 status='approved'if ident in['trinca-brasas','tricordio']else'proposed'
 def relative(path):return Path(__import__('os').path.relpath(path,DOC)).as_posix()
 nodes.append(dict(id=ident,name=name,stage=stage,kind='stage',age=age,action=action,identity=identity,story=story,decision_status=status,approval_note=note if status=='approved'else None,production_status='concept',implementation='não integrado por este estudo',art=relative(image),brief=relative(brief)))
edges=[dict(**{'from':a,'to':b},kind='reweaving',decision_status='proposed',reason=r)for a,b,r in [('braseco','trinca-brasas','O bebê aprende a explorar e coordenar sua guarda.'),('trinca-brasas','trincaguarda','A vigilância exige novos apoios e primeiras proteções.'),('trincaguarda','tricordio','A guarda se reorganiza em corpo cavaleiresco e equipamento; transformação das cabeças segue direção do autor.')]]
data=dict(family_id='trinca-brasas',scope='Dois concepts novos e duas bases aprovadas; maturidade documental sem integração.',nodes=nodes,edges=edges)
(DOC/'chart.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
mini=DOC/'miniaturas';mini.mkdir(exist_ok=True)
for n in nodes:
 with Image.open(DOC/n['art'])as im:
  rgba=im.convert('RGBA');alpha=rgba.getchannel('A');box=alpha.getbbox()
  if box:rgba=rgba.crop(box)
  white=Image.new('RGBA',rgba.size,'white');white.alpha_composite(rgba);thumb=ImageOps.contain(white.convert('RGB'),(700,600),Image.Resampling.LANCZOS)
 thumb.save(mini/(n['id']+'.png'))
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',25);sheet=Image.new('RGB',(1600,1420),'white');draw=ImageDraw.Draw(sheet)
for i,n in enumerate(nodes):
 x,y=i%2*800,i//2*710
 with Image.open(mini/(n['id']+'.png'))as im:
  t=ImageOps.contain(im,(750,600),Image.Resampling.LANCZOS);sheet.paste(t,(x+(800-t.width)//2,y+(610-t.height)//2))
 draw.text((x+25,y+630),n['name']+' · '+n['age'],fill='#26333a',font=font)
sheet.save(DOC/'familia.png')
cards=''.join(f'''<article><h2>{escape(n['name'])}</h2><p class="age">{n['age']} · {'visual aprovado'if n['decision_status']=='approved'else'proposta'}</p><a href="{n['art']}"><img src="miniaturas/{n['id']}.png" alt="{escape(n['identity'])}"></a><h3>{n['action']}</h3><p>{n['story']}</p><p><a href="{n['art']}">Arte completa</a> · <a href="{n['brief']}">Brief e origem</a></p></article>'''for n in nodes)
page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Trinca-brasas · do primeiro cuidado ao cavaleiro</title><style>*{box-sizing:border-box}body{margin:0;background:#f4f1e9;color:#25323b;font:17px/1.6 system-ui}header{background:#25202d;color:#fff4de;padding:38px max(24px,calc((100vw - 1180px)/2))}h1{font-size:clamp(28px,4vw,43px);line-height:1.2}main{max-width:1230px;margin:auto;padding:24px}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}article{padding:25px;background:white;border:1px solid #d3c9ba}h2{margin:0}.age{font-size:14px;color:#6b5640}img{width:100%;height:450px;object-fit:contain}a{color:#8b3c16;text-underline-offset:4px}a:focus-visible{outline:3px solid #197e80;outline-offset:5px}.note{padding:20px;border-left:4px solid #d95819;background:#fff9ea;margin-bottom:25px}header a{color:#ffcf86}@media(max-width:650px){.grid{grid-template-columns:1fr}img{height:350px}}</style><header><h1>Trinca-brasas · do primeiro cuidado ao cavaleiro</h1><p>Braseco → Trinca-brasas → Trincaguarda → Tricórdio</p><p><a href="familia.png">Comparar família</a> · <a href="CHART.md">Decisões e história</a></p></header><main><aside class="note">Bebê e jovem são novos concepts em avaliação. Trinca-brasas e cavaleiro v4 preservam aprovações visuais anteriores. Nomes novos, maturidade, requisitos e ligações de jogo continuam propostas. Não há integração neste estudo.</aside><section class="grid">'''+cards+'''</section><p>Montagens e miniaturas não representam escala física canônica. <a href="chart.json">Chart documental</a>.</p></main></html>'''
(DOC/'index.html').write_text(page,encoding='utf-8')
class Check(HTMLParser):
 def __init__(self):super().__init__();self.links=[]
 def handle_starttag(self,t,attrs):
  for k,v in attrs:
   if k in['href','src']:self.links.append(v)
c=Check();c.feed(page);errors=[link for link in c.links if not(DOC/link).is_file()]
report=dict(ok=not errors,nodes=4,edges=3,new_concepts=2,missing=errors,scope='Arquivos, imagens, hashes e links; não teste de navegador, movimento ou jogo.')
(DOC/'validacao.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(report,ensure_ascii=True));raise SystemExit(bool(errors))
