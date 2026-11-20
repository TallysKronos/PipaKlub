"""Documenta três concepts de Mata Verde; sem mudanças em jogo ou rigs."""
import hashlib, html, json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps

DOC=Path(__file__).resolve().parent
ROOT=DOC.parents[2]
ART=ROOT/'art/creatures/mata-verde-family-v1'
SPECS=[
 ('brotim','Brotim',1,'Bebê','Espiar antes de saltar','Botão de papel-folha baixo e enrolado; seis patas curtas, duas folhas fechadas e cipó curto.', 'Ensaiar equilíbrio permite explorar sem se abrir ao primeiro sopro.', 'Patas pequenas agarram o apoio; folhas recolhidas mantêm volume compacto.', 'Pouco alcance e sustentação.'),
 ('folhante','Folhante',3,'Jovem','Girar e aparar','Inseto foliar em vírgula suspensa, seis membros, asas curtas e folha-palma de aparo.', 'Escapar amadurece em controlar o próprio eixo antes de escolher a saída.', 'Abdômen e cipó contrabalançam; membros anteriores desviam pressão.', 'Exige espaço lateral para completar o giro.'),
 ('verdestrama','Verdestrama',4,'Adulto','Desviar e avançar com precisão','Inseto-fada hexápode de tórax-quilha e quatro asas-folhas; antebraço prolongado em rapieira de nervura.', 'Aprende a abrir uma passagem precisa em vez de somente escapar dela.', 'Seis membros distribuem funções; quatro velas e guarda de folha organizam postura e avanço.', 'Comprometer o eixo no avanço exige recuperar a guarda.'),
]
sources=json.loads((DOC/'sources.json').read_text(encoding='utf-8'))
refs=[{'path':'art/soulgen/keys/mata-verde/color-rig-v2/concept.png','role':'Identidade existente'}, {'path':'art/creatures/rabbito-family-v1/arauto-da-tempestade/concept-v2/concept.png','role':'Acabamento aprovado'}]
nodes=[]
for ident,name,stage,age,action,anatomy,story,mechanism,limit in SPECS:
 folder=ART/ident/'concept-v1';image=folder/'concept.png'
 if not image.is_file() or not(folder/'prompt.txt').is_file():raise FileNotFoundError(folder)
 brief=f'''# {name} — concept proposto

## Pedido e identidade
Autor solicita bebê, jovem e adulto para Mata Verde; o adulto deve ser inseto-fada rapieira. Base e rig intactos. Verde-folha/lima, creme, verde profundo, três pontas de broto e rabiola de cipó/folha conservam parentesco. O formato da base não é um rosto obrigatório para o adulto inseto.

## Proposta
Maturidade: {age}, grau {stage} documental. Nome: {name} (proposto).
Anatomia: {anatomy}
História interpretativa: {story}
Verbo: {action}. Construção: {mechanism}
Limitação proposta: {limit}

## Direção e limites
Traço 2D mangá limpo, áreas amplas de cor, poucas dobras úteis, construção funcional de pipa viva. Equilíbrio artístico 45/45/10. Nomes, receitas, níveis e mecânicas não aprovados. Não se inventa infância anterior ao despertar da folha registrado no catálogo. Sem rig, animação ou integração; concept raster não certifica grid técnico de pixel art.
'''
 (folder/'brief.md').write_text(brief,encoding='utf-8')
 with Image.open(image)as im:
  m=dict(id=ident,tool='image_gen.imagegen',source=sources[ident],sha256=hashlib.sha256(image.read_bytes()).hexdigest(),width=im.width,height=im.height,mode=im.mode,alpha='A'in im.getbands(),references=refs,prompt='prompt.txt',decision_status='proposed',production_status='concept',implementation='não integrado',technical_pixel_art=False)
 if(folder/'prompt-correcao.txt').is_file():m['correction']={'input':'tentativa-01.png','prompt':'prompt-correcao.txt'}
 (folder/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
 nodes.append(dict(id=ident,name=name,stage=stage,kind='stage',age=age,action=action,identity=anatomy,story=story,mechanism=mechanism,tradeoff=limit,decision_status='proposed',production_status='concept',implementation='não integrado',art=f'../../../art/creatures/mata-verde-family-v1/{ident}/concept-v1/concept.png',brief=f'../../../art/creatures/mata-verde-family-v1/{ident}/concept-v1/brief.md'))
nodes.insert(1,dict(id='mata-verde',name='Mata Verde',kind='stage',stage=2,age='Base · criança no estudo',identity='Pipa foliar verde com face creme, três pontas de broto, asas-folhas e cipó com folha terminal.',story='Folha que se enrolou na linha da pipa e aprendeu a dançar entre galhos, segundo o catálogo local.',decision_status='approved',approval_note='Identidade existente preservada; não é nova aprovação do rig ou do grau mecânico.',production_status='concept',implementation='base intacta',art='../../../art/soulgen/keys/mata-verde/color-rig-v2/concept.png',brief='../evolucoes-v1/briefs/mata-verde.md'))
edges=[{'from':a,'to':b,'kind':'reweaving','decision_status':'proposed','reason':r}for a,b,r in [('brotim','mata-verde','Ensaio de apoio permite abrir as folhas e explorar a corrente.'),('mata-verde','folhante','Esquiva livre amadurece em domínio do giro e aparo.'),('folhante','verdestrama','Controlar o eixo permite usar seis apoios e avanço preciso na forma de inseto-fada.')]]
data=dict(family_id='mata-verde',scope='Três novos concepts e base preservada; sem integração.',nodes=nodes,edges=edges)
(DOC/'chart.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
mini=DOC/'miniaturas';mini.mkdir(exist_ok=True)
for n in nodes:
 with Image.open(DOC/n['art'])as im:
  rgba=im.convert('RGBA');b=rgba.getchannel('A').getbbox()
  if b:rgba=rgba.crop(b)
  white=Image.new('RGBA',rgba.size,'white');white.alpha_composite(rgba)
  thumb=ImageOps.contain(white.convert('RGB'),(680,510),Image.Resampling.LANCZOS)
 thumb.save(mini/f"{n['id']}.png")
# Reutilizar somente apresentação documental existente; dados e artes são desta família.
template=(DOC.parent/'carcara-chart-v1/index.html').read_text(encoding='utf-8')
start=template.index('const data=')+len('const data=');end=template.index(';function select',start)
page=template[:start]+json.dumps(data,ensure_ascii=False)+template[end:]
start=page.index('<section class="grid"');content=page.index('>',start)+1;end=page.index('</section>',content)
cards=''.join(f'<button data-id="{n["id"]}" aria-pressed="false"><img src="miniaturas/{n["id"]}.png" alt="{html.escape(n["name"])}"><strong>{n["name"]}</strong><span>{n["age"]}</span></button>'for n in nodes)
page=page[:content]+cards+page[end:]
page=page.replace('Carcará · aprender a corrente','Mata Verde · dança da nervura')
page=page.replace('Do primeiro equilíbrio ao voo econômico que outros podem acompanhar. Identidade quente e rabiola dupla preservadas; novas proporções, silhuetas e funções a cada maturidade.','Do broto recolhido ao inseto-fada esgrimista. Identidade foliar e cipó preservados; corpo, face e apoios mudam de função a cada maturidade.')
page=page.replace('I · Carquim (bebê) → II · Carcará (base) → III · Caravento (jovem) → IV · Caramastro (adulto)','I · Brotim (bebê) → II · Mata Verde (base) → III · Folhante (jovem) → IV · Verdestrama (adulto inseto-fada rapieira)')
page=page.replace(":'carcara'",":'mata-verde'")
for old,new in [('#281d19','#142d23'),('#fff1d4','#f5f7da'),('#ffd18e','#c5e88b'),('#483025','#254a35'),('#ffac44','#b4d85c'),('#30231a','#173c29')]:page=page.replace(old,new)
(DOC/'index.html').write_text(page,encoding='utf-8')
(DOC/'viewer-script.js').write_text(page.split('<script>')[1].split('</script>')[0],encoding='utf-8')
sheet=Image.new('RGB',(1600,1200),'white');draw=ImageDraw.Draw(sheet)
try:font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',28)
except OSError:font=ImageFont.load_default()
for i,n in enumerate(nodes):
 x,y=(i%2)*800,(i//2)*600
 with Image.open(mini/f"{n['id']}.png")as im:
  t=ImageOps.contain(im,(760,510),Image.Resampling.LANCZOS);sheet.paste(t,(x+(800-t.width)//2,y+(520-t.height)//2))
 draw.text((x+24,y+548),f"{n['name']} · {n['age']}",font=font,fill='#183e29')
sheet.save(DOC/'familia.png')
for n in nodes:
 for field in ('art','brief'):
  if not(DOC/n[field]).is_file():raise FileNotFoundError(n[field])
print(json.dumps({'nodes':len(nodes),'edges':len(edges),'new_concepts':3,'index':str(DOC/'index.html')}))
