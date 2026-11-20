from pathlib import Path
import json,os,hashlib,shutil,html
from PIL import Image,ImageOps,ImageDraw,ImageFont

D=Path(__file__).resolve().parent;R=D.parents[2]
data=json.loads((D/'producao.json').read_text(encoding='utf-8'))
def write(p,t):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t,encoding='utf-8')
def dump(p,v):write(p,json.dumps(v,ensure_ascii=False,indent=2)+'\n')
def rel(p,b):return os.path.relpath(p,b).replace('\\','/')
reviews={
 'alvorraia':'Duas nadadeiras-velas e dois lobos cefálicos curvos, sem patas. Rosto adulto estreito, fendas inferiores e rabiola única com terminal de leque. Varetas e nós sustentam o disco corporal; contorno completo apesar de margens mais estreitas que o pedido.',
 'coroabissal':'Duas nadadeiras anteriores e cauda em dois lobos horizontais, corpo compacto sem patas. Câmara dorsal em espiral, boca e olho verde-menta maduros. Rabiola fina no dorso posterior separada da cauda; nó frontal tem abas curtas decorativas, sem segunda linha longa.',
 'vortentaculo':'Oito braços com pontas distintas: quatro à frente e quatro atrás. Sifão lateral curto é parte do corpo, rabiola fina sai do topo posterior do manto. Olhos azul-gelo e nós-discos nas faces inferiores. Raízes legíveis nesta pose, conferir verso antes de rig.',
 'reciferreo':'Correção dirigida retirou uma pata excedente atrás da pinça-escudo. Seis patas de apoio e dois braços de pinça. Olhos rosa-gelo em pedúnculos, placas em três patamares, rabiola única. Três vanes dorsais grandes estão visíveis; a quarta pedida não foi certificada nesta vista.'
}
members=[]
for m in data['members']:
 p=R/'art/creatures'/m['id']/'concept-v1';p.mkdir(parents=True,exist_ok=True)
 shutil.copy2(m['source'],p/'concept.png')
 if m['intermediate']:shutil.copy2(m['intermediate'],p/'tentativa-anterior.png')
 write(p/'prompt.txt',m['prompt']+'\n')
 if m['correction']:write(p/'prompt-correcao.txt',m['correction']+'\n')
 write(p/'brief.md',f'# {m["name"]} — Quatro Marés\n\n## Definido pelo autor\n\nCriar quatro Soulmonsters aquáticos do grupo “Quatro Marés”. Direção vigente: 45% criatura, 45% pipa viva, 10% contorno e 2D mangá. A alma permanece na rabiola.\n\n## Proposta de identidade\n\nAdulto · IV Pandorga. {m["tide"]}: {m["verb"]}. {m["role"]}\n\nPaleta: {m["palette"]}.\n\n{m["prompt"].split(chr(10))[-1]}\n\n## Lore\n\n[Lore compartilhada]({rel(D/"LORE.md",p)}). Nome individual, estágio, capacidades, matéria resistente à água, lugar e obtenção são propostas. Não é evolução do Makaréu nem do Grifarca. Sem cristal ancestral automático.\n\n## Observado e conferido\n\n{reviews[m["id"]]}\n\nLimites: concept de fundo branco, sem grid de pixel art técnico, recorte, vistas extras, rig ou animação certificados.\n')
 write(p/'revisao.md',f'# Conferência — {m["name"]}\n\n{reviews[m["id"]]}\n\nImagem aberta individualmente e comparada na prancha do grupo. Refere-se à vista apresentada; não certifica anatomia oculta ou continuidade de animação. Método: ferramenta image_gen integrada, apenas imagens autorais como guias de acabamento. Nenhuma imagem externa como input.\n\nDecisão visual: proposta. Produção: concept. Implementação: não integrado.\n')
 reference=R/'art/creatures'/('grifarca' if m['id']=='reciferreo' else 'makareu')/'concept-v2/concept.png'
 with Image.open(p/'concept.png') as im:meta=dict(width=im.width,height=im.height,mode=im.mode,alpha_extrema=im.getextrema()[-1] if im.mode=='RGBA' else None)
 dump(p/'manifest.json',dict(id=m['id'],name=m['name'],group='Quatro Marés',stage=4,date='2026-11-07',decision_status='proposed',production_status='concept',implementation_status='not_integrated',tool='image_gen.imagegen (integrado)',source=m['source'],reference=rel(reference,p),reference_role='Acabamento e construção autorais; não identidade nem vínculo evolutivo.',sha256=hashlib.sha256((p/'concept.png').read_bytes()).hexdigest(),prompt='prompt.txt',correction='prompt-correcao.txt' if m['correction'] else None,**meta))
 write(p.parent/'DECISOES.md','# Registro de criação\n\n2026-11-07. Autor: “crie quatro soulmonsters aquaticos de um grupo chamado quatro marés”. Nome do grupo definido; quatro designs individuais, nomes, maturidade adulta, funções e lore propostos para avaliação. Sem linhas evolutivas extras, rig ou gameplay.\n')
 members.append(dict(id=m['id'],name=m['name'],tide=m['tide'],action=m['verb'],role=m['role'],decision_status='proposed',production_status='concept',implementation_status='not_integrated',art=rel(p/'concept.png',D),brief=rel(p/'brief.md',D),review=rel(p/'revisao.md',D)))
dump(D/'grupo.json',dict(name='Quatro Marés',name_status='author_defined',scope='Quatro concepts aquáticos individuais; lore e adultos propostos, sem integração.',members=members))
sources=[
 dict(url='https://oceanservice.noaa.gov/facts/tidescurrents.html',title="What's the difference between a tide and a current?",entity='NOAA National Ocean Service',accessed='2026-11-07',fact='Distingue variação vertical de nível e movimento horizontal das correntes; a subida e descida da maré podem criar correntes de maré.',interpretation='As quatro funções são uma metáfora narrativa do ciclo, não uma explicação de que criaturas causam marés astronômicas.',generation_input=False),
 dict(url='https://www.montereybayaquarium.org/animals-the-ocean/animals-a-to-z/giant-pacific-octopus',title='Giant Pacific octopus',entity='Monterey Bay Aquarium',accessed='2026-11-07',fact='Descreve oito braços com ventosas, aprendizado de tarefas e propulsão por sifão.',interpretation='Coordenar fixação/desenrosco e sifão fundamenta ação de Vortentáculo; materiais e discos-nó são autorais.',generation_input=False),
 dict(url='https://www.montereybayaquarium.org/animals-the-ocean/animals-a-to-z/bat-ray',title='Bat ray',entity='Monterey Bay Aquarium',accessed='2026-11-07',fact='Página de espécie e habitats costeiros; estudo textual de raias complementou a proposta.',interpretation='Usar nadadeiras amplas como arquitetura de sustentação. Alvorraia é criatura ficcional, sem alegação de reproduzir espécie ou espécie fotografada.',generation_input=False)
]
dump(D/'fontes.json',sources)
write(D/'PESQUISA.md','# Pesquisa aplicada\n\nConsulta textual de fontes primárias em 2026-11-07, sem imagens externas anexadas à geração. Não se alega inspeção de uma coleção inteira de fauna.\n\n'+'\n\n'.join(f'## [{s["title"]}]({s["url"]})\n\n{s["entity"]}. {s["fact"]}\n\nAplicação proposta: {s["interpretation"]}' for s in sources)+'\n\nReciférreo possui seis patas de apoio e dois braços por decisão de design ficcional. Não é reconstrução anatômica de um caranguejo real. Coroabissal combina sugestões de baleia e arquitetura espiral, sem alegação de uma linhagem biológica.\n')
font=lambda n:ImageFont.truetype('C:/Windows/Fonts/arial.ttf',n)
board=Image.new('RGB',(2400,1850),'#f1eee5');draw=ImageDraw.Draw(board)
draw.text((45,22),'QUATRO MARÉS',fill='#143d43',font=font(54))
draw.text((45,90),'Erguer · sustentar · liberar · resguardar',fill='#587077',font=font(26))
cards=[]
for i,(m,record) in enumerate(zip(data['members'],members)):
 x=25+(i%2)*1190;y=155+(i//2)*835
 draw.rounded_rectangle((x,y,x+1160,y+800),radius=18,fill='white')
 with Image.open((D/record['art']).resolve()) as source:thumb=ImageOps.contain(source.convert('RGB'),(1110,650),Image.Resampling.LANCZOS)
 board.paste(thumb,(x+(1160-thumb.width)//2,y+(650-thumb.height)//2))
 draw.text((x+25,y+675),m['name']+' · '+m['tide'],fill='#143d43',font=font(37))
 draw.text((x+25,y+735),m['verb'].capitalize(),fill='#587077',font=font(27))
 cards.append(f'<article><a href="{record["art"]}"><img src="{record["art"]}" alt="{m["name"]}, representante da {m["tide"]}"></a><h2>{m["name"]}</h2><h3>{m["tide"]} · {m["verb"]}</h3><p>{m["role"]}</p><p>{reviews[m["id"]]}</p><a href="{record["brief"]}">Brief e identidade</a> · <a href="{record["review"]}">Conferência</a></article>')
board.save(D/'quatro-mares.png')
css='*{box-sizing:border-box}body{margin:0;background:#0c2834;color:#f2efdf;font:18px/1.6 system-ui,sans-serif}main{max-width:1450px;margin:auto;padding:42px 28px}h1{font-size:clamp(38px,6vw,72px);line-height:1.1}a{color:#9ae4de}a:focus-visible{outline:3px solid #ffd57c;outline-offset:5px}.board{width:100%;height:auto}.cards{display:grid;grid-template-columns:1fr 1fr;gap:26px;margin-top:35px}article{background:#f1eee5;color:#143d43;border-radius:16px;padding:24px}article img{width:100%;height:380px;object-fit:contain;background:white}article a{color:#116b76}p{max-width:100ch}@media(max-width:750px){main{padding:25px 16px}.cards{grid-template-columns:1fr}article img{height:auto}}'
write(D/'index.html','<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Quatro Marés · Soulmonsters</title><style>'+css+'</style><main><h1>Quatro Marés</h1><p>Quatro adultos aquáticos propostos, quatro maneiras de proteger uma passagem. Grupo definido pelo autor; identidades e lore novas para avaliação. Cada corpo é criatura e pipa viva, com uma única rabiola.</p><p><a href="LORE.md">Ler a lore</a> · <a href="PESQUISA.md">Pesquisa e fontes</a> · <a href="grupo.json">Manifesto do grupo</a></p><a href="quatro-mares.png"><img class="board" src="quatro-mares.png" alt="Alvorraia, Coroabissal, Vortentáculo e Reciférreo reunidos"></a><div class="cards">'+''.join(cards)+'</div><p>Artes feitas com image_gen integrado. PNGs, prompts e revisão em cada pasta de concept. Sem rig, animações ou integração certificados.</p></main></html>')
print('Quatro conceitos, lore, manifestos e prancha registrados.')
