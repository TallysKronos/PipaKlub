"""Publica estudo local de 28 casos com fontes atribuídas e navegação acessível."""
from pathlib import Path
from html import escape
from html.parser import HTMLParser
from collections import Counter
import json,re,hashlib
from PIL import Image,ImageOps,ImageDraw,ImageFont
D=Path(__file__).resolve().parent
collection=json.loads((D/'coleta-trabalho.json').read_text(encoding='utf-8'))
cases=json.loads((D/'fichas.json').read_text(encoding='utf-8'));lookup={i['id']:i for i in collection};assert len(cases)==28
stats=Counter();sources=[];cards=[];md=['# 28 fichas — Baby I, Baby II e Rookie','', 'Anatomia, apoio e expressão são observações da arte; fato é paráfrase do perfil; princípio e aplicação são interpretação/proposta. Ilustrações estáticas não comprovam ciclos de animação.','']
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',22)
for c in cases:
 i=lookup[c['id']];assert 'image' in i,i
 im=i['image'];p=D/im['file'];assert p.is_file() and hashlib.sha256(p.read_bytes()).hexdigest()==im['sha256'];assert c['visual_inspected']
 stage='rookie' if i['level']=='Rookie' else ('baby2' if 'Ⅱ' in i['level'] else 'baby1');c['group']=stage;c['name']=i['name'];c['level']=i['level'];c['image']=im['file'];stats[stage]+=1
 with Image.open(p) as picture:dimensions=list(picture.size)
 sources.append(dict(id=i['id'],title=i['name']+' — Digimon Encyclopedia',publisher='Digimon Web / BANDAI',url=i['url'],consulted='2026-11-04',level=i['level'],type=i['type'],fact_paraphrase=c['fato'],interpretation=c['principio'],proposed_application=c['aplicacao'],visual_evidence=dict(**im,dimensions=dimensions,inspected=True),generation_input=False))
 md.extend([f'<a id="{c["id"]}"></a>',f'## {i["name"]} · {i["level"]}',f'[Perfil oficial]({i["url"]}) · [Arte inspecionada]({im["file"]})',f'**Arquitetura:** {c["architecture"]}.',f'**Anatomia observada:** {c["anatomia"]}',f'**Apoio/ação:** {c["apoio"]}',f'**Expressão:** {c["expressao"]}',f'**Fato do perfil:** {c["fato"]}',f'**Princípio interpretado:** {c["principio"]}',f'**Aplicação proposta:** {c["aplicacao"]}',''])
 cards.append(f'<article id="{c["id"]}" data-stage="{stage}" data-arch="{c["architecture"]}"><p class="label">{escape(i["level"])} · {escape(c["architecture"])}</p><h3>{escape(i["name"])}</h3><a href="{im["file"]}"><img loading="lazy" src="{im["file"]}" alt="Arte oficial de {escape(i["name"])}; referência de estudo de terceiros"></a><p>{escape(c["anatomia"])}</p><button type="button" data-compare="{c["id"]}">Comparar {escape(i["name"])}</button><p><a href="FICHAS.md#{c["id"]}">Ficha aprofundada</a> · <a href="{i["url"]}">Perfil oficial ↗</a></p><small>Arte oficial Digimon · pesquisa, não input de geração.</small></article>')
assert stats==dict(baby1=6,baby2=8,rookie=14),stats
(D/'FICHAS.md').write_text('\n\n'.join(md),encoding='utf-8');(D/'fontes.json').write_text(json.dumps(sources,ensure_ascii=False,indent=2),encoding='utf-8')
# Coleção final sem transcrição integral de perfis. Slugs inválidos não viram referências.
for i in collection:i.pop('profile',None)
(D/'coleta-trabalho.json').write_text(json.dumps(collection,ensure_ascii=False,indent=2),encoding='utf-8');(D/'coleta.json').write_text(json.dumps(collection,ensure_ascii=False,indent=2),encoding='utf-8')
# Folhas analíticas: mesmo espaço de comparação, não mesma escala física.
for k in range(0,len(cases),6):
 sheet=Image.new('RGB',(1320,920),'white');d=ImageDraw.Draw(sheet)
 for j,c in enumerate(cases[k:k+6]):
  with Image.open(D/c['image']) as im:t=ImageOps.contain(im.convert('RGB'),(410,365),Image.Resampling.LANCZOS)
  x=j%3*440;y=j//3*460;sheet.paste(t,(x+(440-t.width)//2,y+(370-t.height)//2));d.text((x+12,y+380),c['name'],font=font,fill='#172c39');label={'baby1':'Baby I / In-Training I','baby2':'Baby II / In-Training II','rookie':'Rookie'}[c['group']];d.text((x+12,y+410),label,font=font,fill='#73563e')
 sheet.save(D/f'estudo-{k//6+1}.jpg',quality=94)
def inline(t):
 t=escape(t);t=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',r'<a href="\2">\1</a>',t);return re.sub(r'\*\*([^*]+)\*\*',r'<strong>\1</strong>',t)
def markdown(file):
 out=[];buf=[]
 def flush():
  if buf:out.append('<p>'+inline(' '.join(buf))+'</p>');buf.clear()
 for l in (D/file).read_text(encoding='utf-8').splitlines()+['']:
  if not l:flush()
  elif l.startswith('#'):
   flush();n=min(5,len(l)-len(l.lstrip('#')));out.append(f'<h{n}>'+inline(l[n:].strip())+f'</h{n}>')
  elif l.startswith('|'):flush();out.append('<p class="tableline">'+inline(l)+'</p>')
  elif l.startswith('- ') or re.match(r'^\d+\. ',l):flush();out.append('<p class="point">'+inline(l)+'</p>')
  else:buf.append(l)
 return '\n'.join(out)
data=[{k:c[k] for k in ['id','name','level','architecture','image','anatomia','apoio','principio']} for c in cases]
opts=''.join(f'<option value="{escape(a)}">{escape(a)}</option>' for a in sorted({c['architecture']for c in cases}))
page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Baby e Rookie · estudo de construção</title><style>
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f2efe7;color:#1c3038;font:17px/1.65 system-ui}header{background:#163e47;color:#fff8e8;padding:44px max(24px,calc((100vw - 1220px)/2))}header p{max-width:75ch}h1{font-size:clamp(30px,5vw,52px);line-height:1.13}header a{color:#ffe1a2}main{max-width:1300px;margin:auto;padding:26px}nav{display:flex;gap:18px;flex-wrap:wrap}a{color:#146174;text-underline-offset:4px}button,select{font:inherit;padding:10px 13px;border:1px solid #8da8a9;background:#fffdf8;border-radius:4px;color:#173f48}button{cursor:pointer}a:focus-visible,button:focus-visible,select:focus-visible{outline:3px solid #cb642d;outline-offset:4px}.filters{display:flex;flex-wrap:wrap;align-items:end;gap:20px;padding:22px;background:#e3eae3}.filters label{display:grid;gap:6px}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:22px;margin:25px 0}article{background:white;padding:24px;min-width:0;border-top:4px solid #276b73}article img{width:100%;height:260px;object-fit:contain}article h3{margin:2px 0 10px;font-size:25px}.label{font-size:13px;color:#73503c;margin:0}small{color:#56656c}.reading{max-width:920px;background:#fffdf7;padding:clamp(22px,4vw,48px);margin:32px auto}.reading h2{line-height:1.25;margin-top:38px}.point{border-left:3px solid #b7794d;padding-left:16px}.compare{display:grid;grid-template-columns:1fr 1fr;gap:22px}.compare img{height:230px;object-fit:contain;width:100%}.slot{padding:24px;background:white;border:2px solid #58908b}.note{background:#fff0d7;padding:20px;border-left:4px solid #a96e35}summary{font-weight:bold;font-size:23px;cursor:pointer;padding:18px 0}.tableline{font-family:monospace;font-size:13px;overflow-wrap:anywhere}[hidden]{display:none!important}@media(max-width:900px){.grid{grid-template-columns:1fr 1fr}}@media(max-width:600px){.grid,.compare{grid-template-columns:1fr}main{padding:16px}article img{height:280px}}@media(prefers-reduced-motion:reduce){html{scroll-behavior:auto}}</style>
<header><p>SOULMONSTERS · BENCHMARK DE CONSTRUÇÃO · 04 NOV 2026</p><h1>Antes de crescer,<br>uma criatura precisa ter vida.</h1><p>28 estudos oficiais: 6 Baby I, 8 Baby II e 14 Rookie. Anatomia, matéria, apoio, expressão e mudança de capacidade. Referências externas de pesquisa, sem inputs de geração.</p><nav><a href="#galeria">Galeria</a><a href="#comparar">Comparar</a><a href="#analise">Estudo completo</a><a href="#capivara">Aplicar à capivara</a><a href="FICHAS.md">28 fichas</a></nav></header><main><aside class="note"><b>Escopo honesto:</b> artes estáticas e perfis oficiais. Leitura visual não é intenção comprovada dos designers. A galeria não prova animação nem uma árvore evolutiva universal. O bebê atual da capivara permanece rejeitado, sem substituição por outro concept nesta etapa.</aside>
<section id="galeria"><h2>Arquiteturas, não uma fórmula de fofura</h2><div class="filters"><label>Estágio<select id="stage"><option value="all">Todos · 28</option><option value="baby1">Baby I · 6</option><option value="baby2">Baby II · 8</option><option value="rookie">Rookie · 14</option></select></label><label>Arquitetura<select id="arch"><option value="all">Todas</option>'''+opts+'''</select></label><p id="count" role="status" aria-live="polite">28 casos</p></div><div class="grid">'''+''.join(cards)+'''</div></section><section id="comparar"><h2>Comparar duas construções</h2><p>Use “Comparar” nos cartões. A terceira seleção substitui a mais antiga. Espaço normalizado; não representa escala física.</p><button id="clear" type="button">Limpar comparação</button><div id="slots" class="compare" aria-live="polite"><p>Selecione dois casos na galeria.</p></div></section>
<section id="analise" class="reading">'''+markdown('ANALISE.md')+'''</section><section id="capivara" class="reading">'''+markdown('APLICACAO-CAPIVARA.md')+'''</section><details class="reading"><summary>Ficha reutilizável para criação</summary>'''+markdown('FICHA-DE-CRIACAO.md')+'''</details><footer><p>Arte oficial Digimon © respectivos titulares indicados nas fontes. Referências de terceiros para análise; nenhuma licença de reutilização como asset do jogo é presumida. <a href="fontes.json">Fontes e evidências</a> · <a href="validacao.json">Verificação local</a>.</p><p>Folhas de inspeção: '''+''.join(f'<a href="estudo-{i}.jpg">{i}</a> 'for i in range(1,6))+'''</p></footer></main><script>
const data='''+json.dumps(data,ensure_ascii=False).replace('</',r'<\/')+''';const stage=document.querySelector('#stage'),arch=document.querySelector('#arch');function filter(){let n=0;document.querySelectorAll('article[data-stage]').forEach(c=>{c.hidden=!((stage.value==='all'||c.dataset.stage===stage.value)&&(arch.value==='all'||c.dataset.arch===arch.value));if(!c.hidden)n++});document.querySelector('#count').textContent=n+' casos'}stage.addEventListener('change',filter);arch.addEventListener('change',filter);let selected=[];const slots=document.querySelector('#slots');function show(){slots.replaceChildren();if(!selected.length){const p=document.createElement('p');p.textContent='Selecione dois casos na galeria.';slots.append(p)}selected.forEach(id=>{const c=data.find(x=>x.id===id),s=document.createElement('section');s.className='slot';const h=document.createElement('h3');h.textContent=c.name+' · '+c.level;s.append(h);const im=document.createElement('img');im.src=c.image;im.alt='Referência oficial de '+c.name;s.append(im);['anatomia','apoio','principio'].forEach(k=>{const p=document.createElement('p');p.textContent=c[k];s.append(p)});slots.append(s)})}document.querySelectorAll('[data-compare]').forEach(b=>b.addEventListener('click',()=>{if(selected.includes(b.dataset.compare))return;selected.push(b.dataset.compare);if(selected.length>2)selected.shift();show();document.querySelector('#comparar').scrollIntoView({block:'start'})}));document.querySelector('#clear').addEventListener('click',()=>{selected=[];show()});
</script></html>'''
(D/'index.html').write_text(page,encoding='utf-8')
class Check(HTMLParser):
 def __init__(self):super().__init__();self.links=[];self.ids=[];self.alts=[]
 def handle_starttag(self,t,attrs):
  a=dict(attrs)
  if 'id' in a:self.ids.append(a['id'])
  if t=='img':self.alts.append(a.get('alt',''))
  self.links.extend(v for k,v in attrs if k in ('href','src'))
c=Check();c.feed(page);missing=[]
for l in c.links:
 if l.startswith(('https:','http:','#')):continue
 target=l.split('#')[0]
 if target=='validacao.json':continue
 if not(D/target).is_file():missing.append(l)
duplicate_ids=sorted({v for v in c.ids if c.ids.count(v)>1});assert not duplicate_ids
result=dict(ok=not missing,profiles=28,official_images=28,stage_counts=dict(stats),visual_inspection='28 artes, cinco folhas comparativas e oito inspeções individuais',missing_links=missing,duplicate_ids=duplicate_ids,all_images_have_alt=all(c.alts),limits='Estrutura, fontes, hashes e arquivos; JS não testado num navegador e anatomia não medida por landmarks.')
(D/'validacao.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(result,ensure_ascii=True));raise SystemExit(bool(missing))
