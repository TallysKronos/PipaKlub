"""Galeria local de pesquisa, atribuição e conferência de artefatos."""
from pathlib import Path
from html import escape
from html.parser import HTMLParser
import re,json,hashlib
from PIL import Image
ROOT=Path(__file__).resolve().parent
cases=json.loads((ROOT/'fichas.json').read_text(encoding='utf-8'))
collection=json.loads((ROOT/'coleta.json').read_text(encoding='utf-8'))
lookup={it['id']:it for it in collection}
sources=[];cards=[]
for c in cases:
 it=lookup[c['id']];im=it['images'][0];path=ROOT/im['file']
 with Image.open(path)as picture:dimensions=list(picture.size)
 assert hashlib.sha256(path.read_bytes()).hexdigest()==im['sha256']
 src={'id':c['id'],'title':c['name']+' — Digimon Encyclopedia','publisher':'Digimon Web / BANDAI','url':it['url'],'consulted':'2026-11-03','fact_summary':c['historia'],'visual_evidence':{'file':im['file'],'url':im['url'],'sha256':im['sha256'],'dimensions':dimensions,'inspected':True},'interpretation':c['principio'],'proposed_use':c['aplicacao'],'generation_input':False}
 sources.append(src)
 fields=''.join('<h4>'+label+'</h4><p>'+escape(c[key])+'</p>'for key,label in [('anatomia','Anatomia · observado'),('armadura','Armadura · observado'),('pose','Pose estática · leitura visual'),('historia','História · perfil oficial, em paráfrase'),('principio','Princípio · interpretação'),('aplicacao','Soulmonsters · proposta')])
 cards.append(f'''<article id="{c['id']}"><div class="figure"><a href="{im['file']}"><img loading="lazy" src="{im['file']}" alt="Ilustração oficial de {escape(c['name'])}; referência externa de estudo"></a><p class="credit">Arte oficial Digimon · referência de terceiros<br><a href="{it['url']}">Abrir perfil oficial ↗</a></p></div><div><h3>{escape(c['name'])}</h3>{fields}</div></article>''')
sources.extend([
 {'id':'grupo','title':'Digimon Profile #036 — Royal Knights','publisher':'Digimon Web / BANDAI','url':'https://digimon.net/profile/report036/','consulted':'2026-11-03','fact_summary':'Treze cavaleiros interpretam ordens de modos próprios; podem cooperar ou entrar em conflito.','generation_input':False},
 {'id':'contexto-secundario','title':'Royal Knights — Wikimon','publisher':'Wikimon, enciclopédia comunitária','url':'https://wikimon.net/Royal_Knights','consulted':'2026-11-03','source_type':'secondary','fact_summary':'Associação à Távola Redonda; não usada para afirmar correspondência religiosa individual.','generation_input':False}
])
(ROOT/'fontes.json').write_text(json.dumps(sources,ensure_ascii=False,indent=2),encoding='utf-8')
# Não distribuir transcrições integrais: a coleta final guarda metadados; paráfrases ficam nas fichas.
for it in collection:it.pop('profile',None)
(ROOT/'coleta.json').write_text(json.dumps(collection,ensure_ascii=False,indent=2),encoding='utf-8')
def inline(t):
 t=escape(t);t=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',r'<a href="\2">\1</a>',t)
 return re.sub(r'\*\*([^*]+)\*\*',r'<strong>\1</strong>',t)
def markdown(name):
 parts=[];para=[];listing=False
 def flush():
  if para:parts.append('<p>'+inline(' '.join(para))+'</p>');para.clear()
 for line in (ROOT/name).read_text(encoding='utf-8').splitlines()+['']:
  if line.startswith('#'):
   flush()
   if listing:parts.append('</ul>');listing=False
   depth=min(len(line)-len(line.lstrip('#')),5);parts.append(f'<h{depth}>{inline(line[depth:].strip())}</h{depth}>')
  elif line.startswith('- ')or re.match(r'^\d+\. ',line):
   flush()
   if not listing:parts.append('<ul>');listing=True
   parts.append('<li>'+inline(re.sub(r'^(?:- |\d+\. )','',line))+'</li>')
  elif not line.strip():
   flush()
   if listing:parts.append('</ul>');listing=False
  else:para.append(line)
 return '\n'.join(parts)
nav=''.join(f'<a href="#{c["id"]}">{escape(c["name"].split(" / ")[0])}</a>'for c in cases)
style='''*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:24px}body{margin:0;background:#f3f0e9;color:#172b34;font:17px/1.65 system-ui,sans-serif}a{color:#18575c;text-underline-offset:4px}a:focus-visible{outline:3px solid #bc4d31;outline-offset:5px}header{background:#142d37;color:#f7f2e8;padding:52px max(24px,calc((100vw - 1180px)/2))}header a{color:#ffce79}h1{font-size:clamp(30px,4vw,48px);line-height:1.15;max-width:940px}h2{font-size:28px;line-height:1.3;margin-top:48px}h3{font-size:25px;line-height:1.3}h4{margin:20px 0 4px;font-size:15px;letter-spacing:.03em;color:#705036}p{margin:8px 0 20px}main{max-width:1228px;padding:24px;margin:auto}nav{display:flex;gap:12px;flex-wrap:wrap;margin:22px 0}nav a{background:white;padding:8px 14px;border:1px solid #bfc7c4;border-radius:4px}.pill{font-size:13px;text-transform:uppercase;letter-spacing:.1em;color:#ffce79}.intro{max-width:920px}.notice{border-left:4px solid #ba512f;padding:16px 22px;background:#fff9e8}article{display:grid;grid-template-columns:minmax(240px,370px) minmax(0,1fr);gap:32px;background:white;border:1px solid #cbd2cc;padding:30px;margin:28px 0}.figure img{width:100%;max-height:500px;object-fit:contain;background:#fff}.credit{font-size:13px;color:#5a625d}.report{max-width:960px;margin:64px auto;border-top:3px solid #253d45}.report h1{font-size:36px}.report li{margin-bottom:12px}.comparisons img{display:block;width:100%;height:auto;border:1px solid #d0d0c8;margin:14px 0}.links{display:flex;gap:20px;flex-wrap:wrap}footer{border-top:1px solid #bdc7c3;padding:30px 0;font-size:14px}@media(max-width:720px){article{display:block;padding:20px}.figure img{max-height:360px}header{padding:34px 24px}h2{font-size:24px}}@media(prefers-reduced-motion:reduce){html{scroll-behavior:auto}}'''
page='''<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Royal Knights · benchmark para Soulmonsters</title><style>'''+style+'''</style></head><body><header><p class="pill">Pesquisa visual · 03.11.2026 · 13 perfis + 13 artes principais</p><h1>O que faz uma criatura parecer um cavaleiro lendário?</h1><p class="intro">Anatomia, arquitetura da armadura, gesto e história. Estudo dos Royal Knights para construir os onze cavaleiros de Soulmonsters com identidade própria.</p><nav aria-label="Capítulos"><a href="#analise">Estudo completo</a><a href="#comparacoes">Comparar artes</a><a href="#fichas">13 fichas</a><a href="#onze">Aplicação aos onze</a><a href="#modelo">Ficha de criação</a></nav></header><main><aside class="notice">Observação da arte, fatos de perfil e propostas estão separados. Nenhuma imagem de Digimon será usada como input de geração. Concepts e rigs aprovados do projeto permanecem intactos.</aside><section id="comparacoes" class="comparisons"><h2>Distribuição de massas e equipamentos</h2><p>As montagens igualam áreas de apresentação, não escala física canônica. Clique para ampliar.</p>'''+''.join(f'<a href="comparativo-{i}.jpg"><img src="comparativo-{i}.jpg" alt="Grupo {i} de ilustrações oficiais, com nomes abaixo de cada figura"></a>'for i in [1,2,3])+'''</section><section id="fichas"><h2>As treze leituras individuais</h2><nav aria-label="Cavaleiros">'''+nav+'''</nav>'''+''.join(cards)+'''</section><section id="analise" class="report">'''+markdown('ANALISE.md')+'''</section><section id="onze" class="report">'''+markdown('APLICACAO-ONZE.md')+'''</section><section id="modelo" class="report">'''+markdown('FICHA-DE-CRIACAO.md')+'''</section><footer><div class="links"><a href="ANALISE.md">ANALISE.md</a><a href="APLICACAO-ONZE.md">Aplicação aos onze</a><a href="FICHA-DE-CRIACAO.md">Modelo de brief</a><a href="fontes.json">Fontes e hashes</a></div><p>Ilustrações oficiais: direitos de seus respectivos titulares, conforme créditos do Digimon Web (BANDAI / Akiyoshi Hongo / Toei Animation). Uso aqui: referência de pesquisa atribuída; não são assets do Soulmonsters. Layout e análise editorial próprios.</p></footer></main></body></html>'''
(ROOT/'index.html').write_text(page,encoding='utf-8')
class Links(HTMLParser):
 def __init__(self):super().__init__();self.links=[];self.ids=[]
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if'id'in a:self.ids.append(a['id'])
  for k in['href','src']:
   if k in a:self.links.append(a[k])
p=Links();p.feed(page);errors=[]
for url in p.links:
 if url.startswith(('http:','https:')):continue
 if url.startswith('#'):
  if url[1:]not in p.ids:errors.append(url)
 elif not(ROOT/url).is_file():errors.append(url)
assert len(cases)==13
assert len({c['id']for c in cases})==13
assert len(p.ids)==len(set(p.ids))
report={'ok':not errors,'cases':13,'main_images':13,'sources':len(sources),'errors':errors,'scope':'Estrutura, arquivos, hashes e links internos; arte inspecionada em montagens e quatro imagens individuais. Sem teste de navegador, movimento ou integração.'}
(ROOT/'validacao.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=True))
raise SystemExit(bool(errors))
