from pathlib import Path
import json,shutil,hashlib,os,html,importlib.util
from PIL import Image,ImageOps,ImageDraw,ImageFont
D=Path(__file__).resolve().parent;R=D.parents[2]
data=json.loads((D/'producao.json').read_text(encoding='utf-8'))
def write(p,t):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t,encoding='utf-8')
def dump(p,v):write(p,json.dumps(v,ensure_ascii=False,indent=2)+'\n')
def rel(p,b):return os.path.relpath(p,b).replace('\\','/')
reviews={
'lupunhal':'Dois braços e duas pernas visíveis, duas mãos segurando adagas independentes; rosto adulto lupino e olhos menta. Guarda de vareta atrás das orelhas, couraça e articulações legíveis. Rabiola única divide o terminal em três bandeirolas. Dobras de tronco e braços mais numerosas que o ideal; não certificam material ou movimento em outros ângulos.',
'dirubastiao':'Quatro patas e quatro pés separados; couraça central sobre peito profundo, grevas e ombreiras volumosas. Balista com dois suportes sobre o dorso, arco e seta acima da cabeça. Cordas da balista são mecanismo, distintas da única rabiola com estandarte. Rosto maduro, olhos violetas. Folga dinâmica da arma e rotação de ombros ainda precisam de estudo para animação.',
'etruslanca':'Dois braços e duas pernas, ambas as mãos fechadas no mesmo cabo contínuo. Cabeça lupina adulta, gola alta sem cobrir o focinho; armadura roxa e três painéis amplos de saia. Vela da lança legível, rabiola posterior separada. Arma e pés completos; extremidades da lâmina próximas da margem superior/direita. Movimento em corredor é limitação proposta.',
'miralis':'Quatro pernas longas e quatro pés; pescoço e focinho estreitos, armadura leve e olho azul-ciano. Arma de carretel apoiada em dois encaixes dorsais, cano passa acima das orelhas sem atravessar a cabeça nesta vista. Uma rabiola traseira, distinta da linha da arma. Retículo próximo da borda direita, completo; folga em giro e sistema de mira são hipóteses a validar em vistas adicionais.'
}
font=lambda n:ImageFont.truetype('C:/Windows/Fonts/arial.ttf',n)
board=Image.new('RGB',(2400,2000),'#eee9df');dr=ImageDraw.Draw(board)
dr.text((40,20),'ARMADA DOS LOBOS',font=font(56),fill='#18313d')
dr.text((42,95),'Quatro linhagens · quatro armas · um pacto proposto',font=font(27),fill='#536671')
cards=[];records=[];checks=[]
spec=importlib.util.spec_from_file_location('validator',R/'.agents/skills/soulmonsters-charts/scripts/validar_chart.py')
validator=importlib.util.module_from_spec(spec);spec.loader.exec_module(validator)
for i,m in enumerate(data['members']):
 p=R/'art/creatures'/m['id']/'concept-v1';p.mkdir(parents=True,exist_ok=True)
 shutil.copy2(m['source'],p/'concept.png');write(p/'prompt.txt',m['prompt']+'\n')
 source=data['sources'][i if i==0 else {1:2,2:3,3:1}[i]]
 brief=f'# {m["name"]} — Armada dos Lobos\n\n## Definido pelo autor\n\nGrupo “Armada dos Lobos”, quatro espécies de lobos de diferentes épocas, adultos quadrúpedes e bípedes, armamentos distintos, incluindo adagas e sniper. Traço autoral de Soulmonsters.\n\n## Proposta\n\n{m["epoch"]} · {m["species"]}. Adulto, estágio IV. Armamento: {m["weapon"]}. Verbo: {m["verb"]}.\n\n{m["story"]}\n\nNome, função, lore, material e habilidades são propostas. Não é evolução de Dóber, Dobrácula ou lobo-em-pele-de-cordeiro; nenhuma relação existente foi alterada.\n\n## Construção\n\n{m["design"]}\n\n45% criatura, 45% pipa viva, 10% contorno seletivo e 2D mangá. Corpo em membranas amplas tensionadas, armadura com hierarquia. Uma alma na rabiola, sem cristal automático. Armamento fantástico sem detalhamento de engenharia real.\n\n## Referência factual e interpretação\n\n[{source["title"]}]({source["url"]}) — {source["entity"]}. {source["fact"]}\n\n{source["application"]} Consulta textual; imagem externa não usada como input. O Grifarca próprio forneceu acabamento e construção, sem transportar sua espécie ou cristal.\n\n## Observado\n\n{reviews[m["id"]]}\n\n[Lore compartilhada]({rel(D/"LORE.md",p)}). Pré-evoluções, obtenção, raridade, facção na campanha e balanceamento indefinidos.\n'
 write(p/'brief.md',brief)
 write(p/'revisao.md',f'# Revisão — {m["name"]}\n\n{reviews[m["id"]]}\n\nInspeção individual após geração e comparação na prancha. Concept proposto. Não equivale a pixel art técnico, recorte, rig, animação ou integração. Fundo branco preservado. Dimensões e hash no manifesto.\n')
 with Image.open(p/'concept.png') as im:meta=dict(width=im.width,height=im.height,mode=im.mode,alpha_extrema=im.getextrema()[-1] if im.mode=='RGBA' else None)
 digest=hashlib.sha256((p/'concept.png').read_bytes()).hexdigest()
 dump(p/'manifest.json',dict(id=m['id'],name=m['name'],group='Armada dos Lobos',stage=4,date='2026-11-07',decision_status='proposed',production_status='concept',implementation_status='not_integrated',source=m['source'],sha256=digest,tool='image_gen.imagegen integrado',prompt='prompt.txt',reference=rel(R/'art/creatures/grifarca/concept-v2/concept.png',p),reference_role='Acabamento e material autorais; sem transportar identidade ou cristal.',**meta))
 c=R/'documentation/creatures'/f'{m["id"]}-chart-v1';c.mkdir(parents=True,exist_ok=True)
 chart=dict(family_id=m['id'],scope='Concept adulto da Armada dos Lobos; nenhuma pré-evolução ou ligação evolutiva definida.',nodes=[dict(id=m['id'],name=m['name'],kind='stage',stage=4,identity=m['weapon']+' · '+m['epoch'],story=m['story'],decision_status='proposed',production_status='concept',art=rel(p/'concept.png',c),brief=rel(p/'brief.md',c))],edges=[])
 dump(c/'chart.json',chart);errors=validator.validate(chart,c);assert not errors,errors
 checks.append(dict(family=m['id'],nodes=1,edges=0,errors=errors))
 write(c/'CHART.md',f'# {m["name"]}\n\nAdulto proposto da Armada dos Lobos. {m["story"]}\n\n[Concept]({rel(p/"concept.png",c)}) · [Brief]({rel(p/"brief.md",c)}) · [Grupo]({rel(D/"index.html",c)}).\n\nSem pré-evoluções ou condições de aquisição definidas.\n')
 x=25+(i%2)*1190;y=155+(i//2)*905
 dr.rounded_rectangle((x,y,x+1160,y+875),radius=16,fill='white')
 with Image.open(p/'concept.png') as im:thumb=ImageOps.contain(im.convert('RGB'),(1120,710),Image.Resampling.LANCZOS)
 board.paste(thumb,(x+(1160-thumb.width)//2,y+10+(710-thumb.height)//2))
 dr.text((x+24,y+725),m['name']+' · '+m['weapon'],font=font(32),fill='#18313d')
 dr.text((x+24,y+780),m['epoch'],font=font(26),fill='#536671')
 art=rel(p/'concept.png',D);br=rel(p/'brief.md',D)
 records.append(dict(id=m['id'],name=m['name'],art=art,brief=br,species=m['species'],weapon=m['weapon']))
 cards.append(f'<article><a href="{art}"><img src="{art}" alt="{m["name"]}, {m["weapon"]}"></a><h2>{m["name"]}</h2><h3>{m["weapon"]}</h3><p>{m["epoch"]} · <i>{m["species"]}</i></p><p>{m["story"]}</p><p><a href="{br}">Brief</a> · <a href="{rel(p/"revisao.md",D)}">Revisão</a></p></article>')
board.save(D/'armada-dos-lobos.png')
dump(D/'grupo.json',dict(name='Armada dos Lobos',decision_status='proposed',members=records))
dump(D/'fontes.json',data['sources'])
write(D/'PESQUISA.md','# Pesquisa — quatro espécies, épocas distintas\n\nDuas espécies atuais e duas extintas do Pleistoceno. Não são quatro períodos geológicos diferentes nem reconstruções científicas das pelagens. A diversidade de épocas orienta a criação, não uma genealogia entre elas. Consulta textual de fontes primárias; nenhuma fotografia ou arte externa entrou como input de geração.\n\n'+'\n\n'.join(f'## [{s["title"]}]({s["url"]})\n\n{s["entity"]} · consulta {s["accessed"]}.\n\nFato: {s["fact"]}\n\nAplicação proposta: {s["application"]}' for s in data['sources'])+'\n')
write(D/'LORE.md','# Armada dos Lobos\n\n## Definido pelo autor\n\nNome do grupo, quatro bases lupinas de épocas distintas, adultos quadrúpedes e bípedes e armamentos próprios, de adagas a sniper.\n\n## Lore proposta — A última passagem\n\nUma antiga rota entre bairros e ruínas teria deixado quatro modos de defender quem ficou para trás. A Armada não seria um exército de uma única era: cada rabiola guardaria a lembrança de uma maneira de lutar, remontada no presente por novos corpos de pipa. Isso não exige viagem temporal nem cria almas extras dentro de armas.\n\nSeu pacto seria: **“Nenhum do bando fica do outro lado.”** O sinal comum seria uma linha aberta entre duas presas: passagem preservada, em vez de brasão de dominação. Este emblema ainda é proposta textual; não é asset certificado nas quatro artes.\n\nLupunhal intercepta quem rompe a formação. Etruslança redireciona a investida e abre espaço. Dirubastião ancora a retaguarda. Miralís marca ameaças distantes para permitir a retirada. Nenhum domina sozinho a distância do outro: entrar, girar, fixar e aguardar são compromissos distintos.\n\nAs armas canalizam linha e almática; não utilizam pólvora ou balística real definida. A alma permanece exclusivamente na rabiola. São quatro famílias novas propostas, sem vínculo automático com os cavaleiros, Crystais Pipas, Bando do Cerol ou Carretéis das Sombras. Obtenção, encontros, alinhamento e pré-evoluções ficam indefinidos.\n')
css='*{box-sizing:border-box}body{margin:0;background:#142834;color:#f0eadf;font:18px/1.6 system-ui}main{max-width:1500px;margin:auto;padding:40px 24px}h1{font-size:clamp(38px,6vw,70px);line-height:1.1}a{color:#8bd8ce}a:focus-visible{outline:3px solid #ffda83;outline-offset:5px}.board{width:100%;height:auto}.cards{display:grid;grid-template-columns:1fr 1fr;gap:24px;margin-top:30px}article{padding:24px;border-radius:14px;background:#eee9df;color:#18313d}article a{color:#126678}article img{width:100%;height:430px;object-fit:contain;background:white}@media(max-width:740px){.cards{grid-template-columns:1fr}article img{height:auto}}'
write(D/'index.html','<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Armada dos Lobos · Soulmonsters</title><style>'+css+'</style><main><h1>Armada dos Lobos</h1><p>Quatro adultos, dois bípedes e dois quadrúpedes. Cada arma muda a postura, os apoios e o papel na formação. Nomes e lore propostos; concepts sem integração.</p><p><a href="LORE.md">Lore e pacto</a> · <a href="PESQUISA.md">Pesquisa e fontes</a> · <a href="grupo.json">Manifesto</a></p><a href="armada-dos-lobos.png"><img class="board" src="armada-dos-lobos.png" alt="Os quatro integrantes da Armada dos Lobos"></a><div class="cards">'+''.join(cards)+'</div></main></html>')
dump(D/'validacao.json',dict(charts=checks,concepts=4,structural_ok=True,visual_scope='Vista individual inspecionada; sem validação de movimento ou vistas ocultas.'))
# Aprovação recebida nesta conversa refere-se somente às 12 pré-evoluções das Quatro Marés.
old=R/'documentation/creatures/quatro-mares-pre-evolucoes-v1'
approved=json.loads((old/'producao.json').read_text(encoding='utf-8'))
note='Autor: “Aprovadissimos! Agora quero que você faça para um grupo chamado armada dos lobos” (2026-11-07). Escopo: aceitação visual das 12 pré-evoluções apresentadas; não aprova automaticamente lore, nomes, mecânicas ou integração.'
for f in approved['families']:
 c=R/'documentation/creatures'/f'{f["id"]}-chart-v1/chart.json';chart=json.loads(c.read_text(encoding='utf-8'))
 for form in f['forms']:
  p=R/'art/creatures'/f['id']/form[0]/'concept-v1'
  manifest=json.loads((p/'manifest.json').read_text(encoding='utf-8'));manifest.update(decision_status='approved',approval_note=note);dump(p/'manifest.json',manifest)
  review=(p/'revisao.md').read_text(encoding='utf-8')
  if note not in review:write(p/'revisao.md',review+'\n## Decisão posterior\n\n'+note+'\n')
  for n in chart['nodes']:
   if n['id']==form[0]:n.update(decision_status='approved',approval_note=note)
 dump(c,chart)
print('Quatro adultos registrados, quatro charts válidos, lore, fontes e galeria. Aprovação visual anterior registrada com escopo.')
