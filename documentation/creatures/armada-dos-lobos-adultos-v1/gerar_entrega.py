from pathlib import Path
import json,shutil,hashlib,os,importlib.util
from PIL import Image,ImageOps,ImageDraw,ImageFont
D=Path(__file__).resolve().parent;R=D.parents[2]
data=json.loads((D/'producao.json').read_text(encoding='utf-8'))
def write(p,t):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t,encoding='utf-8')
def dump(p,v):write(p,json.dumps(v,ensure_ascii=False,indent=2)+'\n')
def rel(p,b):return os.path.relpath(p,b).replace('\\','/')
changes=[('Prender e redirecionar duas linhas com lâminas curvas, dominando o espaço em vez de apenas interceptar.','Dois braços e duas pernas completos; duas adagas curvas, cabeça menor em relação ao peito profundo, manto amplo e saia aberta sem ocultar apoios. Rabiola trançada com três terminais. A guarda craniana permanece aberta, mais próxima de diadema estrutural que de helmet completo. Corpo não reduzido a humano com cabeça de lobo.'),('Tensionar uma linha de cobertura mantendo quatro apoios estáveis; perde a liberdade de avançar enquanto cobre a retirada.','Quatro pernas e quatro pés separados; peito alto e profundo, rosto alongado com olhos pequenos sob meia-máscara, duas abas de bochecha e manto em planos largos. Arma em dois suportes dorsais, sem cruzar face nesta vista; rabiola única distinta da linha da arma. Rotação, recuo e folgas sob movimento ainda não validados.')]
note='Autor: “lupunhal e miralís são como jovens [...] pode ter uma adulto pra eles com muito mais presença” (2026-11-07). Estágio dos dois concepts anteriores passa de adulto proposto para jovem por orientação do autor. Não implica aprovação das novas artes ou nomes.'
board=Image.new('RGB',(2400,1700),'#eee9df');dr=ImageDraw.Draw(board);font=lambda n:ImageFont.truetype('C:/Windows/Fonts/arial.ttf',n)
dr.text((35,20),'ARMADA DOS LOBOS · JOVEM → ADULTO',font=font(48),fill='#18313d')
sections=[];checks=[]
spec=importlib.util.spec_from_file_location('v',R/'.agents/skills/soulmonsters-charts/scripts/validar_chart.py');v=importlib.util.module_from_spec(spec);spec.loader.exec_module(v)
for i,m in enumerate(data['members']):
 p=R/'art/creatures'/m['family']/m['id']/'concept-v1';p.mkdir(parents=True,exist_ok=True)
 shutil.copy2(m['source'],p/'concept.png');write(p/'prompt.txt',m['prompt']+'\n')
 action,review=changes[i]
 write(p/'brief.md',f'# {m["name"]}\n\nAdulto proposto de {m["family"]}, mantido como jovem por decisão do autor. Nome novo e habilidades propostos.\n\n## Mudança e função\n\n{action}\n\n{review}\n\n## Direção\n\n45% criatura, 45% pipa viva e 10% contorno/2D mangá. Preservar cores e função da família, mudar proporções, postura e autoridade. Referência única: jovem autoral da própria família, não desenho externo.\n\n## Construção solicitada\n\n{m["prompt"]}\n\nFontes zoológicas herdadas: [pesquisa do grupo]({rel(R/"documentation/creatures/armada-dos-lobos-v1/PESQUISA.md",p)}). Sem novas afirmações zoológicas. Obtenção e condições evolutivas indefinidas.\n')
 write(p/'revisao.md',f'# Conferência — {m["name"]}\n\n{review}\n\nComparado individualmente ao jovem. Concept proposto, sem rig, animações, integração ou grade técnica de pixel art. Fundo branco.\n')
 with Image.open(p/'concept.png') as im:meta=dict(width=im.width,height=im.height,mode=im.mode,alpha_extrema=im.getextrema()[-1] if im.mode=='RGBA' else None)
 dump(p/'manifest.json',dict(id=m['id'],name=m['name'],family_id=m['family'],stage=4,decision_status='proposed',production_status='concept',implementation_status='not_integrated',tool='image_gen.imagegen integrado',source=m['source'],reference=rel(R/'art/creatures'/m['family']/'concept-v1/concept.png',p),sha256=hashlib.sha256((p/'concept.png').read_bytes()).hexdigest(),date='2026-11-07',**meta))
 old=R/'art/creatures'/m['family']/'concept-v1';man=json.loads((old/'manifest.json').read_text(encoding='utf-8'));man.update(stage=3,stage_note=note);dump(old/'manifest.json',man)
 for file in ['brief.md','revisao.md']:
  t=(old/file).read_text(encoding='utf-8')
  if note not in t:write(old/file,t+'\n## Decisão posterior — prevalece sobre adulto proposto acima\n\n'+note+'\n')
 c=R/'documentation/creatures'/f'{m["family"]}-chart-v1';chart=json.loads((c/'chart.json').read_text(encoding='utf-8'));young=next(n for n in chart['nodes'] if n['id']==m['family']);young.update(stage=3,maturity='Jovem',stage_note=note)
 adult=dict(id=m['id'],name=m['name'],kind='stage',stage=4,identity=review,story=action,decision_status='proposed',production_status='concept',art=rel(p/'concept.png',c),brief=rel(p/'brief.md',c))
 chart.update(scope='Jovem definido pelo autor e adulto novo proposto; sem integração.',nodes=[young,adult],edges=[{'from':young['id'],'to':adult['id'],'kind':'reweaving','reason':action,'decision_status':'proposed'}]);dump(c/'chart.json',chart)
 errors=v.validate(chart,c);assert not errors,errors;checks.append(dict(family=m['family'],errors=errors,nodes=2,edges=1))
 write(c/'CHART.md',f'# {young["name"]} → {m["name"]}\n\nJovem → adulto. {action}\n\n{note}\n\n[Comparação]({rel(D/"index.html",c)}). Nome adulto e ligação propostos; sem condições de evolução ou integração.\n')
 cards=[]
 for j,(name,stage,img) in enumerate([(young['name'],'Jovem',old/'concept.png'),(m['name'],'Adulto proposto',p/'concept.png')]):
  x=25+j*1190;y=105+i*790;dr.rectangle((x,y,x+1160,y+755),fill='white')
  with Image.open(img) as im:thumb=ImageOps.contain(im.convert('RGB'),(1100,650),Image.Resampling.LANCZOS)
  board.paste(thumb,(x+(1160-thumb.width)//2,y+(650-thumb.height)//2))
  dr.text((x+24,y+665),name+' · '+stage,font=font(34),fill='#18313d')
  cards.append(f'<article><a href="{rel(img,D)}"><img src="{rel(img,D)}" alt="{name}, {stage}"></a><h3>{name} · {stage}</h3></article>')
 sections.append('<section><h2>'+young['name']+' → '+m['name']+'</h2><p>'+action+'</p><div class="cards">'+''.join(cards)+'</div></section>')
board.save(D/'jovens-adultos.png')
write(D/'index.html','<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Armada — jovens e adultos</title><style>*{box-sizing:border-box}body{margin:0;background:#142834;color:#eee9df;font:18px/1.6 system-ui}main{max-width:1500px;margin:auto;padding:35px 24px}.cards{display:grid;grid-template-columns:1fr 1fr;gap:24px}article{background:white;color:#18313d;padding:20px}img{width:100%;height:530px;object-fit:contain}a{color:#8bd8ce}a:focus-visible{outline:3px solid gold}@media(max-width:740px){.cards{grid-template-columns:1fr}img{height:auto}}</style><main><h1>Armada dos Lobos · maturidade</h1><p>Artes anteriores preservadas como jovens por decisão do autor. Dois novos adultos, nomes e vínculos propostos. Comparação de design, não escala de gameplay.</p>'+''.join(sections)+'</main></html>')
dump(D/'validacao.json',dict(charts=checks,structural_ok=True,new_concepts=2))
group=R/'documentation/creatures/armada-dos-lobos-v1/index.html';t=group.read_text(encoding='utf-8');link='<p><a href="../armada-dos-lobos-adultos-v1/index.html">Atualização: Lupunhal e Miralís são jovens; ver seus novos adultos</a></p>'
if link not in t:write(group,t.replace('<h1>Armada dos Lobos</h1>','<h1>Armada dos Lobos</h1>'+link).replace('Quatro adultos, dois bípedes e dois quadrúpedes.','Quatro integrantes iniciais, dois bípedes e dois quadrúpedes. Lupunhal e Miralís foram reclassificados como jovens; os adultos novos estão na atualização.'))
print('Dois novos adultos, jovens preservados, dois charts válidos e comparação registrada.')
