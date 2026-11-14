"""Galeria documental de três concepts, sem alterar jogo ou rig."""
import hashlib, html, json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps
DOC=Path(__file__).resolve().parent
ROOT=DOC.parents[2]
ART=ROOT/'art/creatures/raio-de-sol-family-v1'
SPECS=[
 ('solim','Solim','Bebê','Recolher e observar','Botão dourado em meia-lua com duas abas, patas mínimas e braços recolhidos.', 'O olhar curioso aprende a distinguir uma abertura antes de agir.', 'Abas de papel protegem o rosto; duas rabiolas curtas equilibram.', 'Pouco alcance e sustentação.'),
 ('raio-de-sol-crianca','Raio de Sol','Criança · novo concept','Ensaiar a guarda','Filhote leonino compacto, focinho curto, juba em duas abas e pequenos leques nos punhos.', 'Observar amadurece em experimentar como se proteger.', 'Braços sanfonados aproximam pequenos painéis do rosto.', 'Painéis ainda pequenos deixam passagens abertas.'),
 ('solguarda','Solguarda','Adulto','Fechar a guarda solar','Leão bípede magricela, juba-capuz corporal e punhos em meios-escudos complementares.', 'Ler a situação amadurece em escolher a abertura e sustentar uma guarda.', 'Dois meios-discos solares unem bordas diante do peito; varetas e sanfonas articulam.', 'Fechar a guarda compromete o alcance lateral até abri-la de novo.'),
]
sources=json.loads((DOC/'sources.json').read_text(encoding='utf-8'))
refs=[{'path':'art/soulgen/keys/raio-de-sol/color-rig-v2/concept.png','role':'Identidade original preservada'}, {'path':'art/creatures/rabbito-family-v1/arauto-da-tempestade/concept-v2/concept.png','role':'Acabamento aprovado'}]
nodes=[]
for ident,name,age,action,anatomy,story,mechanism,limit in SPECS:
 folder=ART/ident/'concept-v1';image=folder/'concept.png'
 if not image.is_file() or not(folder/'prompt.txt').is_file():raise FileNotFoundError(folder)
 brief=f'''# {name} — {age}

## Pedido do autor
Bebê, criança e adulto do quarto inicial, Raio de Sol. Adulto leão bípede magricela, juba-capuz e punhos-escudos que se fecham em sol. Interpretação visual: dois meios-escudos complementares, unidos em um disco solar diante do peito. Base e rig existentes não substituídos.

## Proposta
Anatomia: {anatomy}
Verbo: {action}. Construção: {mechanism}
História interpretativa: {story}
Limitação: {limit}

## Herança e acabamento
Ouro/creme/laranja, braços sanfonados e duas rabiolas com terminais triangulares vêm da arte existente. Traço limpo 2D mangá, planos amplos e poucas dobras, equilíbrio artístico 45/45/10. O adulto tem focinho leonino de fato, não rosto da base sobre corpo humano.

## Incógnitas e limites
Nomes novos, designs, obtenção, níveis e regras aguardam aprovação. Três idades solicitadas não autorizam inventar jovem ou salto de grau no jogo; stage fica null. Sem recortes, rigs, animação ou integração. Concept raster não certifica grid técnico. Bebê não prova infância biológica anterior ao despertar do catálogo.
'''
 (folder/'brief.md').write_text(brief,encoding='utf-8')
 with Image.open(image)as im:
  manifest=dict(id=ident,tool='image_gen.imagegen',source=sources[ident],sha256=hashlib.sha256(image.read_bytes()).hexdigest(),width=im.width,height=im.height,mode=im.mode,alpha='A'in im.getbands(),references=refs,prompt='prompt.txt',decision_status='proposed',production_status='concept',implementation='não integrado',technical_pixel_art=False)
 if ident=='solguarda':manifest['functional_study']={'image':'guarda-fechada.png','prompt':'prompt-guarda.txt','scope':'Outra pose explicativa, não animação ou rig'}
 (folder/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
 nodes.append(dict(id=ident,name=name,age=age,stage=None,kind='stage',identity=anatomy,story=story,action=action,mechanism=mechanism,tradeoff=limit,decision_status='proposed',production_status='concept',implementation='não integrado',art=f'../../../art/creatures/raio-de-sol-family-v1/{ident}/concept-v1/concept.png',brief=f'../../../art/creatures/raio-de-sol-family-v1/{ident}/concept-v1/brief.md'))
edges=[{'from':a,'to':b,'kind':'reweaving','decision_status':'proposed','reason':r}for a,b,r in [('solim','raio-de-sol-crianca','O botão abre em filhote que ensaia guarda.'),('raio-de-sol-crianca','solguarda','Amadurecimento visual da guarda em leão magro com dois meios-escudos. Graus intermediários e requisitos não definidos.')]]
data=dict(family_id='raio-de-sol',scope='Três concepts e uma pose funcional; base original preservada.',stage_mapping='Idades de design; graus mecânicos indefinidos, jovem não solicitado.',nodes=nodes,edges=edges)
(DOC/'chart.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
mini=DOC/'miniaturas';mini.mkdir(exist_ok=True)
for n in nodes:
 with Image.open(DOC/n['art'])as im:
  rgba=im.convert('RGBA');b=rgba.getchannel('A').getbbox()
  if b:rgba=rgba.crop(b)
  white=Image.new('RGBA',rgba.size,'white');white.alpha_composite(rgba)
  t=ImageOps.contain(white.convert('RGB'),(660,540),Image.Resampling.LANCZOS)
 t.save(mini/f"{n['id']}.png")
page=(DOC.parent/'carcara-chart-v1/index.html').read_text(encoding='utf-8')
start=page.index('const data=')+len('const data=');end=page.index(';function select',start)
page=page[:start]+json.dumps(data,ensure_ascii=False)+page[end:]
start=page.index('<section class="grid"');content=page.index('>',start)+1;end=page.index('</section>',content)
cards=''.join(f'<button data-id="{n["id"]}" aria-pressed="false"><img src="miniaturas/{n["id"]}.png" alt="{html.escape(n["name"])}"><strong>{n["name"]}</strong><span>{n["age"]}</span></button>'for n in nodes)
page=page[:content]+cards+page[end:]
page=page.replace('Carcará · aprender a corrente','Raio de Sol · guarda do amanhecer').replace('TRÊS NOVOS CONCEPTS · APROVADOS','TRÊS NOVOS CONCEPTS · PROPOSTAS')
page=page.replace('Do primeiro equilíbrio ao voo econômico que outros podem acompanhar. Identidade quente e rabiola dupla preservadas; novas proporções, silhuetas e funções a cada maturidade.','Bebê recolhido, criança leonina e adulto magricela de juba-capuz. Os dois punhos-escudos fecham uma guarda solar; nomes e novos designs em avaliação.')
page=page.replace('I · Carquim (bebê) → II · Carcará (base) → III · Caravento (jovem) → IV · Caramastro (adulto)','Solim (bebê) → Raio de Sol (criança, novo concept) → Solguarda (adulto). Graus de remonta não definidos.')
page=page.replace(":'carcara'",":'solguarda'")
page=page.replace('<a href="chart.json">Dados</a>','<a href="chart.json">Dados</a><a href="../../../art/creatures/raio-de-sol-family-v1/solguarda/concept-v1/guarda-fechada.png">Escudos unidos</a><a href="../../../art/soulgen/keys/raio-de-sol/color-rig-v2/concept.png">Base original preservada</a>')
(DOC/'index.html').write_text(page,encoding='utf-8')
(DOC/'viewer-script.js').write_text(page.split('<script>')[1].split('</script>')[0],encoding='utf-8')
sheet=Image.new('RGB',(1800,800),'white');draw=ImageDraw.Draw(sheet)
try:font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',26)
except OSError:font=ImageFont.load_default()
for i,n in enumerate(nodes):
 with Image.open(mini/f"{n['id']}.png")as im:
  t=ImageOps.contain(im,(565,660),Image.Resampling.LANCZOS);sheet.paste(t,(i*600+(600-t.width)//2,(680-t.height)//2))
 draw.text((i*600+20,718),n['name']+' · '+n['age'],font=font,fill='#553315')
sheet.save(DOC/'familia.png')
for n in nodes:
 for field in ['art','brief']:
  if not(DOC/n[field]).is_file():raise FileNotFoundError(n[field])
if not(ART/'solguarda/concept-v1/guarda-fechada.png').is_file():raise FileNotFoundError('guarda-fechada.png')
print(json.dumps({'nodes':len(nodes),'edges':len(edges),'new_concepts':3,'functional_pose':1,'index':str(DOC/'index.html')}))
