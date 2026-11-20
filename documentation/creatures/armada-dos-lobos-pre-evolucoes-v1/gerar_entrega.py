from pathlib import Path
import json,os,shutil,hashlib,importlib.util
from PIL import Image,ImageOps,ImageDraw,ImageFont
D=Path(__file__).resolve().parent;R=D.parents[2]
data=json.loads((D/'producao.json').read_text(encoding='utf-8'))
def write(p,t):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t,encoding='utf-8')
def dump(p,v):write(p,json.dumps(v,ensure_ascii=False,indent=2)+'\n')
def rel(p,b):return os.path.relpath(p,b).replace('\\','/')
stages=['Bebê','Criança','Jovem','Adulto']
stories={
'lupunhal':'De perceber a tensão no próprio corpo a prender e soltar linhas com os punhos; aprende a interceptar com duas adagas e, adulto, redirecionar dois adversários sem romper a formação.',
'miralis':'Começa ouvindo, depois aprende a observar sem se expor; no jovem sustenta uma linha de precisão, e no adulto mantém cobertura para a retirada dos outros.',
'dirubastiao':'De equilibrar o próprio peso a apoiar uma pequena estrutura; aprende a disparar em movimento e, adulto, escolhe ancorar o corpo inteiro para proteger a retaguarda.',
'etruslanca':'Do equilíbrio de uma vela pequena à condução do vento com o corpo; aprende a guiar uma haste e, adulto, redireciona a investida de uma formação.'}
notes={
'lunim':'Rosto e corpo em losango fundido, sem membros; duas abas teal, arco superior e uma rabiola com bandeirola de pegada. Olhos menta e superfícies amplas.',
'lupisco':'Quatro pernas e quatro pés, corpo baixo de criança e rosto curioso. Abas de punho e pequeno manto apoiado por arco; aprende a prender linha sem portar adagas. Mais dobras e proteção do que o brief mínimo pediu; ainda muito menos massa que jovem e adulto.',
'mirim-fio':'Pacote central com orelhas longas e duas abas laterais amplas; olhos ciano, sem pernas ou torso separado. Rabiola curta com terminal bifurcado. Silhueta horizontal nas abas, não apenas losango estreito.',
'mirafim':'Quatro pernas e quatro pés, cabeça infantil alongada, uma vela dorsal sustentada por vareta e pequeno peitoral. Sem arma ou grevas, corpo leve distinto do jovem armado.',
'dirum':'Corpo-rosto achatado e largo, bochechas grandes dobradas, sem membros. Rabiola sai do lado posterior e leva estandarte; nó inferior é acabamento de estrutura, não segunda alma. Padrões dourados herdados são mais elaborados que o pedido mínimo.',
'dirupac':'Quatro patas, uma dianteira levantada; rosto curioso e corpo compacto. Arco dorsal com linha frouxa sem projétil; ombros e punhos já têm pequenas proteções. O conceito mantém mais grevas que o brief pediu; revisitar simplificação se o autor preferir.',
'dirubalu':'Quatro patas separadas, pernas traseiras sem grevas, corpo comprido e peito ainda leve. Balestra pequena com seta e dois apoios; volume muito inferior à balista e couraça adulta.',
'etrim':'Rosto e corpo fundidos, três velas móveis em torno do losango e rabiola inferior bifurcada. Sem membros ou arma. Tem três abas e pequena aba inferior, em vez da aba única solicitada; conjunto continua simples.',
'etrupim':'Quatro patas, expressão curiosa e pequeno manto de papel; vela única nas costas e rabiola bifurcada. Sem arma ou couraça pesada; postura erguida e infantil.',
'etrusvara':'Dois braços e duas pernas; duas mãos no mesmo cabo contínuo, ponta pequena e vela lateral. Colete, ombreiras e caneleiras leves. Duas velas dorsais adicionais surgiram na geração, distintas da rabiola; não implicam asas de voo ou capacidade nova aprovada.'}
approval='Autor: “ótimo adorei agora crie as pré-evo pra todos” (2026-11-07). Aprovação visual de Lupregente e Miralcaide apresentados no turno anterior; sem certificação de integração, mecânicas ou aprovação automática das novas pré-evoluções.'
for m in data['forms']:
 p=R/'art/creatures'/m['family']/m['id']/'concept-v1';p.mkdir(parents=True,exist_ok=True)
 shutil.copy2(m['source'],p/'concept.png');write(p/'prompt.txt',m['prompt']+'\n')
 write(p/'brief.md',f'# {m["name"]} — {stages[m["stage"]-1]}\n\n## Definido pelo autor\n\nCompletar as pré-evoluções das quatro linhas da Armada dos Lobos. Lupunhal e Miralís são jovens; Lupregente e Miralcaide, os adultos visuais aprovados.\n\n## Proposta de história\n\n{stories[m["family"]]}\n\nNome, vínculos e capacidades desta pré-evolução são propostas.\n\n## Construção solicitada\n\n{m["spec"]}\n\n## Observado na arte\n\n{notes[m["id"]]}\n\n## Continuidade\n\n45% criatura, 45% pipa viva e 10% contorno seletivo/2D mangá. A alma continua na rabiola única. Mudança de arquitetura e atuação antes do aumento de armadura. [Pesquisa das espécies]({rel(R/"documentation/creatures/armada-dos-lobos-v1/PESQUISA.md",p)}), sem novas alegações zoológicas. Referência visual: arte autoral da própria família.\n\nNíveis, itens, obtenção e integração indefinidos.\n')
 write(p/'revisao.md',f'# Revisão — {m["name"]}\n\n{notes[m["id"]]}\n\nImagem inspecionada individualmente após geração e comparada na prancha de quatro estágios. Concept proposto, fundo branco, sem recortes, rig, animação ou integração. Não é pixel art em grade validada. Vistas ocultas e folgas sob movimento não certificadas.\n')
 with Image.open(p/'concept.png') as im:meta=dict(width=im.width,height=im.height,mode=im.mode,alpha_extrema=im.getextrema()[-1] if im.mode=='RGBA' else None)
 dump(p/'manifest.json',dict(id=m['id'],name=m['name'],family_id=m['family'],stage=m['stage'],date='2026-11-07',decision_status='proposed',production_status='concept',implementation_status='not_integrated',tool='image_gen.imagegen integrado',source=m['source'],reference=rel(R/'art/creatures'/m['ref']/'concept-v1/concept.png',p),reference_role='Identidade própria da família e acabamento, sem inputs externos.',sha256=hashlib.sha256((p/'concept.png').read_bytes()).hexdigest(),prompt='prompt.txt',**meta))
spec=importlib.util.spec_from_file_location('v',R/'.agents/skills/soulmonsters-charts/scripts/validar_chart.py');v=importlib.util.module_from_spec(spec);spec.loader.exec_module(v)
font=lambda n:ImageFont.truetype('C:/Windows/Fonts/arial.ttf',n)
panels=[];sections=[];checks=[]
for fam in stories:
 c=R/'documentation/creatures'/f'{fam}-chart-v1';cp=c/'chart.json';chart=json.loads(cp.read_text(encoding='utf-8'))
 if not (c/'chart-before-pre-evolucoes.json').exists():shutil.copy2(cp,c/'chart-before-pre-evolucoes.json')
 old=[n for n in chart['nodes'] if n['id'] not in {m['id'] for m in data['forms']}]
 for n in old:
  if n['id'] in ['lupregente','miralcaide']:
   n.update(decision_status='approved',approval_note=approval)
   p=(c/n['art']).resolve().parent;man=json.loads((p/'manifest.json').read_text(encoding='utf-8'));man.update(decision_status='approved',approval_note=approval);dump(p/'manifest.json',man)
   text=(p/'revisao.md').read_text(encoding='utf-8')
   if approval not in text:write(p/'revisao.md',text+'\n## Aprovação posterior\n\n'+approval+'\n')
 new=[]
 for m in data['forms']:
  if m['family']!=fam:continue
  p=R/'art/creatures'/fam/m['id']/'concept-v1'
  new.append(dict(id=m['id'],name=m['name'],kind='stage',stage=m['stage'],maturity=stages[m['stage']-1],identity=notes[m['id']],story=stories[fam],decision_status='proposed',production_status='concept',art=rel(p/'concept.png',c),brief=rel(p/'brief.md',c)))
 nodes=sorted(new+old,key=lambda n:n['stage'])
 assert [n['stage'] for n in nodes]==[1,2,3,4]
 chart.update(scope='Quatro estágios documentais da Armada dos Lobos. Adultos anteriores preservados; novas pré-evoluções e vínculos propostos.',nodes=nodes,edges=[{'from':nodes[k]['id'],'to':nodes[k+1]['id'],'kind':'reweaving','reason':stories[fam],'decision_status':'proposed'} for k in range(3)])
 dump(cp,chart);errors=v.validate(chart,c);assert not errors,errors;checks.append(dict(family=fam,nodes=4,edges=3,errors=errors))
 write(c/'CHART.md','# '+ ' → '.join(n['name'] for n in nodes)+'\n\n'+stories[fam]+'\n\n'+'\n'.join(f'- {stages[n["stage"]-1]}: [{n["name"]}]({n["art"]}) · [brief]({n["brief"]}).' for n in nodes)+'\n\nNovas pré-evoluções, nomes e vínculos propostos. [Prancha completa](../armada-dos-lobos-pre-evolucoes-v1/index.html). Sem condições de obtenção ou integração.\n')
 board=Image.new('RGB',(2400,760),'#eee9df');dr=ImageDraw.Draw(board);dr.text((28,15),nodes[-1]['name'].upper()+' · ARMADA DOS LOBOS',font=font(37),fill='#18313d')
 cards=[]
 for j,n in enumerate(nodes):
  art=(c/n['art']).resolve();x=15+j*600;dr.rectangle((x,80,x+570,645),fill='white')
  with Image.open(art) as im:thumb=ImageOps.contain(im.convert('RGB'),(550,545),Image.Resampling.LANCZOS)
  board.paste(thumb,(x+(570-thumb.width)//2,85+(545-thumb.height)//2));dr.text((x+15,660),n['name'],font=font(31),fill='#18313d');dr.text((x+15,706),stages[j],font=font(24),fill='#536671')
  cards.append(f'<article><a href="{rel(art,D)}"><img src="{rel(art,D)}" alt="{n["name"]}, {stages[j]}"></a><h3>{n["name"]}</h3><p>{stages[j]}</p><a href="{rel((c/n["brief"]).resolve(),D)}">Brief e revisão</a></article>')
 board.save(D/f'{fam}-linha.png');panels.append(board)
 sections.append('<section><h2>'+' → '.join(n['name'] for n in nodes)+'</h2><p>'+stories[fam]+'</p><div class="cards">'+''.join(cards)+'</div></section>')
overview=Image.new('RGB',(2400,3040),'white')
for i,im in enumerate(panels):overview.paste(im,(0,i*760))
overview.save(D/'armada-linhas.png')
css='*{box-sizing:border-box}body{margin:0;background:#142834;color:#eee9df;font:18px/1.6 system-ui}main{max-width:1600px;margin:auto;padding:35px 24px}a{color:#8bd8ce}a:focus-visible{outline:3px solid gold;outline-offset:5px}.cards{display:grid;grid-template-columns:repeat(4,1fr);gap:16px}article{padding:16px;background:#eee9df;color:#18313d;border-radius:12px}article a{color:#126678}article img{width:100%;height:300px;object-fit:contain;background:white}section{margin:50px 0}@media(max-width:850px){.cards{grid-template-columns:repeat(2,1fr)}}@media(max-width:480px){.cards{grid-template-columns:1fr}}'
write(D/'index.html','<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Armada dos Lobos — quatro linhas</title><style>'+css+'</style><main><h1>Armada dos Lobos · linhas completas</h1><p>10 pré-evoluções novas e 6 concepts anteriores preservados: quatro linhas com bebê, criança, jovem e adulto. Nomes novos e vínculos propostos, sem integração. Pranchas comparam design, não escala de gameplay.</p><p><a href="armada-linhas.png">Prancha completa</a> · <a href="REVISAO.md">Conferência</a> · <a href="../armada-dos-lobos-v1/LORE.md">Lore</a> · <a href="../armada-dos-lobos-v1/PESQUISA.md">Pesquisa das espécies</a></p>'+''.join(sections)+'</main></html>')
write(D/'REVISAO.md','# Conferência das quatro linhas\n\n10 novos concepts inspecionados individualmente. Quatro bebês sem corpo/membros separados; quatro crianças quadrúpedes. Dirubalu é o jovem quadrúpede, Etrusvara o jovem bípede. Lupunhal e Miralís mantidos como jovens, Lupregente e Miralcaide como adultos visuais aprovados pelo autor.\n\nLupisco e Dirupac têm mais proteção e dobras que o brief mínimo, documentadas nas revisões. Etrim tem três abas superiores/laterais, não uma. Etrusvara tem duas velas dorsais adicionais que não definem voo aprovado. Todos preservam rabiola completa distinta de armas e varetas. Vistas adicionais, rotação de arma, rig e animações continuam fora desta entrega.\n\nValidação estrutural: 4 charts, 16 nós e 12 ligações, caminhos locais e hashes. Não é certificação automática da qualidade artística, anatomia oculta ou gameplay.\n')
dump(D/'validacao.json',dict(charts=checks,new_concepts=10,preserved_concepts=6,structural_ok=True))
for folder in ['armada-dos-lobos-v1','armada-dos-lobos-adultos-v1']:
 p=R/'documentation/creatures'/folder/'index.html';t=p.read_text(encoding='utf-8');link='<p><a href="../armada-dos-lobos-pre-evolucoes-v1/index.html">Ver as quatro linhas completas: bebê → criança → jovem → adulto</a></p>'
 if link not in t:write(p,t.replace('</main>',link+'</main>'))
print('10 concepts registrados; 4 charts válidos, 16 nós, 12 ligações; galeria e pranchas completas.')
