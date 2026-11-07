"""Monta somente documentação e apresentação dos concepts de Carcará."""
import hashlib
import html
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps

DOC=Path(__file__).resolve().parent
ROOT=DOC.parents[2]
ART=ROOT/'art/creatures/carcara-family-v1'
SPECS=[
 ('carquim','Carquim',1,'Bebê','Ensaiar equilíbrio','Filhote em gota com peito arredondado, asas curtas dobradas e uma pena direcional.',
  'A forma imatura aprende a sustentar o próprio equilíbrio antes de procurar trajetórias.',
  'Asas recolhidas e rabiola dupla curta ajudam nos pequenos saltos.', 'Pouca sustentação e distância; não é um voador adulto miniaturizado.'),
 ('caravento','Caravento',3,'Jovem','Corrigir a decolagem','Corpo-quilha estreito e ereto, pernas longas e asas recuadas em gesto de direção.',
  'Escolher a corrente amadurece em escolher também o ponto de apoio e a saída.',
  'Pernas permitem travar e lançar; asas estreitas e rabiola dupla orientam a mudança.', 'Mudanças bruscas exigem recuperação antes de uma nova saída.'),
 ('caramastro','Caramastro',4,'Adulto','Conduzir pela corrente','Corpo horizontal de pipa-quilha e asas de grandes painéis com pontas de direção separadas.',
  'De dominar a própria saída passa a oferecer um exemplo estável que outros podem seguir.',
  'Asas amplas distribuem pressão e duas rabiolas completas estabilizam o planeio.', 'A envergadura exige espaço para curva; não prioriza arrancadas curtas.'),
]
sources=json.loads((DOC/'sources.json').read_text(encoding='utf-8'))
references=[{'path':'art/creatures/carcara-family-v1/references/carcara-identity.png','role':'Identidade própria: crop de célula do atlas existente'},
 {'path':'art/creatures/rabbito-family-v1/arauto-da-tempestade/concept-v2/concept.png','role':'Acabamento limpo aprovado, sem importar espécie/paleta'}]
nodes=[]
for ident,name,stage,age,verb,anatomy,story,mechanism,limit in SPECS:
 folder=ART/ident/'concept-v1'; image=folder/'concept.png'
 if not image.is_file() or not (folder/'prompt.txt').is_file():raise FileNotFoundError(folder)
 brief=f'''# {name} — concept proposto

## Definido e observado
O autor pediu bebê, jovem e adulto para Carcará no traço limpo aprovado. Base e rig preservados. Fonte local registra pipa remendada, promessa de voltar a voar e aprendizado de esperar a corrente. Paleta laranja/creme/castanho, bico amarelo, asas de pipa e rabiola dupla conservam a identidade.

## Proposta
Maturidade: {age}, grau {stage} no chart documental. Nome proposto: {name}.
Anatomia: {anatomy}
História interpretativa: {story}
Verbo: {verb}. Construção: {mechanism}
Limitação proposta: {limit}

## Acabamento e limites
Contorno marinho nítido, áreas de cor amplas e poucas dobras úteis. Equilíbrio 45% criatura /45% pipa /10% pixel e 2D mangá. Não é pixel art técnico, rig ou animação. Nome, obtenção, níveis e regras aguardam decisão. O bebê não afirma infância biológica anterior ao despertar descrito no catálogo.
'''
 (folder/'brief.md').write_text(brief,encoding='utf-8')
 with Image.open(image)as im:
  manifest=dict(id=ident,tool='image_gen.imagegen',source=sources[ident],sha256=hashlib.sha256(image.read_bytes()).hexdigest(),width=im.width,height=im.height,mode=im.mode,alpha='A'in im.getbands(),references=references,prompt='prompt.txt',decision_status='approved',approval_note='Autor: aprovados, antes do pedido Mata Verde. Aprovação visual, não integração.',production_status='concept',implementation='não integrado',technical_pixel_art=False)
 (folder/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
 nodes.append(dict(id=ident,name=name,kind='stage',stage=stage,age=age,identity=anatomy,story=story,action=verb,mechanism=mechanism,tradeoff=limit,decision_status='approved',approval_note='Autor: aprovados, antes do pedido Mata Verde. Aprovação visual, não integração.',production_status='concept',implementation='não integrado',art=f'../../../art/creatures/carcara-family-v1/{ident}/concept-v1/concept.png',brief=f'../../../art/creatures/carcara-family-v1/{ident}/concept-v1/brief.md'))
nodes.insert(1,dict(id='carcara',name='Carcará',kind='stage',stage=2,age='Base · criança neste estudo',identity='Ave-pipa em losango laranja e creme, asas castanhas e rabiola dupla com nós.',story='Pipa remendada que ensina a esperar a corrente; fonte do catálogo preservada.',decision_status='approved',approval_note='Identidade de Carcará existente preservada; II/criança é organização proposta deste chart, não regra mecânica.',production_status='concept',implementation='base intacta',art='../../../art/creatures/carcara-family-v1/references/carcara-identity.png',brief='../evolucoes-v1/briefs/carcara.md'))
edges=[{'from':a,'to':b,'kind':'reweaving','decision_status':'proposed','reason':why}for a,b,why in [
 ('carquim','carcara','Ensaiar equilíbrio abre as asas e permite reconhecer a corrente.'),
 ('carcara','caravento','Esperar o vento evolui para escolher apoio e corrigir a saída.'),
 ('caravento','caramastro','Precisão própria amadurece em estabilidade para conduzir pelo exemplo.')]]
data=dict(family_id='carcara',scope='Três concepts novos e base preservada; sem integração.',stage_mapping='I/II/III/IV organizam bebê/base/jovem/adulto como proposta.',nodes=nodes,edges=edges)
(DOC/'chart.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
# Apresentação normalizada; nenhuma pintura ou alteração dos originais.
mini=DOC/'miniaturas';mini.mkdir(exist_ok=True)
for n in nodes:
 with Image.open(DOC/n['art'])as im:
  rgba=im.convert('RGBA');box=rgba.getchannel('A').getbbox()
  if box:rgba=rgba.crop(box)
  white=Image.new('RGBA',rgba.size,'white');white.alpha_composite(rgba)
  thumb=ImageOps.contain(white.convert('RGB'),(640,500),Image.Resampling.LANCZOS)
 thumb.save(mini/f"{n['id']}.png")
cards=''.join(f'<button data-id="{n["id"]}" aria-pressed="false"><img src="miniaturas/{n["id"]}.png" alt="{html.escape(n["name"])}"><strong>{n["name"]}</strong><span>{n["age"]}</span></button>'for n in nodes)
page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Carcará · aprender a corrente</title><style>*{box-sizing:border-box}body{margin:0;background:#281d19;color:#fff1d4;font:17px system-ui}header,main{max-width:1380px;margin:auto;padding:30px}h1{font-size:clamp(32px,5vw,62px);margin:10px 0}p{line-height:1.7;max-width:85ch}a{color:#ffd18e}nav{display:flex;gap:24px;flex-wrap:wrap}.route{padding:22px;background:#483025;border-left:5px solid #ffac44;margin:24px 0;line-height:1.8}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}button{font:inherit;color:#30231a;background:white;border:3px solid transparent;border-radius:12px;padding:18px;cursor:pointer;text-align:left;display:flex;flex-direction:column;gap:12px}button img{width:100%;height:350px;object-fit:contain}button strong{font-size:26px}button:focus-visible,button[aria-pressed=true]{outline:4px solid #ffac44;outline-offset:4px}aside{padding:28px;background:#483025;border-radius:12px;margin:32px 0}dt{font-weight:750;color:#ffd18e}dd{margin:10px 0 22px;line-height:1.7}.links{display:flex;gap:24px}footer{line-height:1.6;margin:28px 0}@media(max-width:700px){.grid{grid-template-columns:1fr}main,header{padding:22px}button img{height:300px}}</style><header><p>TRÊS NOVOS CONCEPTS · PROPOSTAS</p><h1>Carcará · aprender a corrente</h1><p>Do primeiro equilíbrio ao voo econômico que outros podem acompanhar. Identidade quente e rabiola dupla preservadas; novas proporções, silhuetas e funções a cada maturidade.</p><nav><a href="CHART.md">História e decisões</a><a href="PESQUISA.md">Pesquisa</a><a href="familia.png">Comparar artes</a><a href="chart.json">Dados</a></nav></header><main><div class="route">I · Carquim (bebê) → II · Carcará (base) → III · Caravento (jovem) → IV · Caramastro (adulto)<br>Nomes e organização de estágios propostos; sem definir níveis, custos ou obtenção.</div><section class="grid" aria-label="Selecionar forma">CARDS</section><aside id="details" aria-live="polite"></aside><footer>Concepts raster em fundo branco. Sem rigs, animações ou integração. Base e atlas existentes preservados.</footer></main><script>const data=DATA;function select(id){const n=data.nodes.find(n=>n.id===id);document.querySelectorAll('[data-id]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.id===id)));const d=document.querySelector('#details');d.replaceChildren();const h=document.createElement('h2');h.textContent=n.name;d.append(h);const p=document.createElement('p');p.textContent=n.decision_status==='approved'?'Identidade existente preservada':'Novo nome e design em avaliação';d.append(p);const dl=document.createElement('dl');for(const[k,label]of Object.entries({identity:'Anatomia',story:'História',action:'Verbo',mechanism:'Construção',tradeoff:'Limitação proposta'})){if(!n[k])continue;const dt=document.createElement('dt'),dd=document.createElement('dd');dt.textContent=label;dd.textContent=n[k];dl.append(dt,dd)}d.append(dl);const links=document.createElement('div');links.className='links';for(const[url,label]of[[n.art,'Arte original'],[n.brief,'Brief']]){const a=document.createElement('a');a.href=url;a.textContent=label;links.append(a)}d.append(links);location.hash=id}document.querySelectorAll('[data-id]').forEach(b=>b.addEventListener('click',()=>select(b.dataset.id)));select(data.nodes.some(n=>n.id===location.hash.slice(1))?location.hash.slice(1):'carcara');</script></html>'''.replace('CARDS',cards).replace('DATA',json.dumps(data,ensure_ascii=False))
page=page.replace('TRÊS NOVOS CONCEPTS · PROPOSTAS','TRÊS NOVOS CONCEPTS · APROVADOS').replace('Identidade existente preservada','Concept aprovado visualmente; regras e integração separadas')
(DOC/'index.html').write_text(page,encoding='utf-8')
(DOC/'viewer-script.js').write_text(page.split('<script>')[1].split('</script>')[0],encoding='utf-8')
sheet=Image.new('RGB',(1600,1180),'white');draw=ImageDraw.Draw(sheet)
try:font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',28)
except OSError:font=ImageFont.load_default()
for i,n in enumerate(nodes):
 x,y=(i%2)*800,(i//2)*590
 with Image.open(mini/f"{n['id']}.png")as im:
  thumb=ImageOps.contain(im,(760,485),Image.Resampling.LANCZOS);sheet.paste(thumb,(x+(800-thumb.width)//2,y+(495-thumb.height)//2))
 draw.text((x+24,y+518),f"{n['name']} · {n['age']}",font=font,fill='#452819')
sheet.save(DOC/'familia.png')
for n in nodes:
 for field in ['art','brief']:
  if not(DOC/n[field]).is_file():raise FileNotFoundError(n[field])
print(json.dumps({'nodes':len(nodes),'edges':len(edges),'new_concepts':3,'index':str(DOC/'index.html')}))
