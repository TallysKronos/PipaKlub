"""Registra 16 concepts e monta pranchas sem redesenhar pixels ou alterar o jogo."""
from pathlib import Path
import json, os, shutil, hashlib, html, importlib.util
from PIL import Image, ImageOps, ImageDraw, ImageFont

OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[2]
data=json.loads((OUT/'producao.json').read_text(encoding='utf-8'))
families=data['families']
def write(p,t):
 p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t,encoding='utf-8')
def dump(p,d): write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def rel(p,b): return os.path.relpath(p,b).replace('\\','/')
ages=['Bebê · I Cafifa','Criança · II Pipa','Jovem · III Arraia','Adulto · IV Pandorga']
observations={
 'selim':'Rosto integrado no rolo; abas de apoio parcialmente visíveis, duas antenas curtas e rabiola única. Ficou com mais camadas e aro que o brief mínimo, mas sem torso/membros adultos.',
 'lacrulo':'Correção retirou uma pata central excedente. Quatro patas de apoio e dois braços com a faixa; duas antenas e rabiola. Couraça abaulada com X das faixas.',
 'selatrava':'Quatro patas e dois braços-prensa, dois élitros abertos e rabiola. Fase baixa e larga antecede a redistribuição da carga na forma adulta bípede.',
 'selacrabio':'Duas pernas e dois braços-prensa, duas portas-élitros atrás dos ombros. Selos complementares legíveis, cabeça pequena com olhos rosa e rabiola completa. Construção rica e sombra em blocos; extremidades próximas das margens, completas.',
 'penim':'Rosto e corpo na pipa, duas pequenas abas, dois pés em abas, bico curto e olhos menta; faixa marcada e rabiola. Massa simples em contraste com a ave adulta.',
 'ibisco':'Duas pernas e duas asas curtas com raízes; bico e pescoço mais desenvolvidos que o bebê. Uma rabiola. Pescoço mais alongado que o brief, mas proporção de cabeça/asa ainda infantil.',
 'caligibis':'Duas pernas longas e duas asas de lâminas largas, bico curvo e rabiola-pergaminho. Menos manto e mais intervalo entre lâminas que no adulto. Contagem exata de seis lâminas por asa não é uniformemente legível; não prometer rig com essa contagem.',
 'ibiscrito':'Duas pernas e duas asas amplas, pescoço enfaixado, bico longo curvo, crista de pena e rabiola-pergaminho. As faixas saem de raízes de asa; sem braços humanos adicionais.',
 'atadim':'Cabeça/corpo num estojo curto, dois apoios em abas e ponto posterior; faixa, aba dorsal pequena e rabiola. Olhos lavanda, sem dentes adultos.',
 'crocote':'Revisão retirou a couraça adulta em miniatura; quatro patas pequenas, corpo mais esguio, focinho maior e uma única placa dorsal. Rabiola distinta da cauda. Face tem curvas mais suaves e olhos maiores, coerentes com criança, mas requer calibração em futuras vistas.',
 'crocurna':'Estudo inicial da criança realocado como jovem após correção da criança. Quatro patas, três placas/arqueamentos dorsais, olhos grandes e sem grevas adultas. Jovem robusto; difere do brief atlético inicial, cuja versão foi abandonada. Original preservado.',
 'crocafago':'Quatro patas com garras, couraça em três tampas e uma parcialmente aberta; faixas conectam raízes e apoios. Uma cauda corporal compacta e uma rabiola trançada distinta. Focinho curto proposital, olhos lavanda e proteção adulta.',
 'velim':'Corpo-embrulho com dois apoios em abas, duas orelhas compridas dobradas, pequena corcova e uma rabiola. Rosto arredondado de estágio inicial; não é cavalo adulto miniaturizado.',
 'dunelo':'Quatro patas baixas, cabeça camelídea, corcova pequena, olhos azuis e uma rabiola. Os pés saíram com três separações visuais, enquanto jovem/adulto usam dois apoios digitais; unificar vistas antes de rig.',
 'velaruta':'Quatro patas compridas, focinho camelídeo, um ressonador e dois painéis menores na corcova. Um único terminal de rabiola com abas. Proteção parcial e massa leve em comparação ao adulto.',
 'velaravan':'Correção dirigida deu focinho camelídeo e reduziu orelhas. Quatro apoios, dois painéis na corcova e três câmaras cerâmicas com raízes próprias, rabiola única. Estrutura de sombra plana; bordas completas apesar das margens estreitas.'
}
for row in data['forms']:
 f=next(x for x in families if x['id']==row['family'])
 p=ROOT/'art/creatures'/f['id']/row['id']/'concept-v1';p.mkdir(parents=True,exist_ok=True)
 shutil.copy2(row['source'],p/'concept.png')
 if row['intermediate']: shutil.copy2(row['intermediate'],p/'tentativa-anterior.png')
 write(p/'prompt.txt',row['prompt']+'\n')
 if row['correction']: write(p/'prompt-correcao.txt',row['correction']+'\n')
 description=f['forms'][row['stage']-1][2]
 write(p/'brief.md',f'# {row["name"]} — {ages[row["stage"]-1]}\n\n## Definido pelo autor\n\nCriar quatro linhas de Soulmonsters mumificados e uma lore, no traço 2D mangá e construção de pipa viva das famílias aprovadas. A rabiola porta a alma.\n\n## Proposta de identidade\n\nFamília {f["name"]}: {f["role"]}. Paleta: {f["palette"]}.\n\n{description}\n\n## História de amadurecimento\n\n{f["story"]}\n\n## Conferência observada\n\n{observations[row["id"]]}\n\n## Lore e incógnitas\n\nVer [Enfaixados do Fio Quieto]({rel(OUT/"LORE.md",p)}). Nome, função, rotas, locais, elementos e condições de remonta são propostas; sem integração. Faixas conservam papel e registros, não recebem alma extra.\n')
 write(p/'revisao.md',f'# Revisão de {row["name"]}\n\n{observations[row["id"]]}\n\nImagem aberta individualmente; comparar na prancha de família. Concept 2D de fundo branco; não é pixel art técnico certificado, spritesheet, recorte, rig ou animação. Novas artes seguem propostas para avaliação; não recebem aprovação por terem usado acabamento aprovado.\n'+ ('\nHistórico: '+row['reclassification']+'\n' if row['reclassification'] else ''))
 with Image.open(p/'concept.png') as im:
  dims={'width':im.width,'height':im.height,'mode':im.mode,'alpha_extrema':im.getextrema()[-1] if im.mode=='RGBA' else None}
 reference=('../../../grifarca/concept-v2/concept.png' if row['family']!='crocafago' else '../../../gevoraz/concept-v2/concept.png') if row['stage']==4 else f'../../{f["id"]}/concept-v1/concept.png'
 dump(p/'manifest.json',dict(id=row['id'],family_id=f['id'],stage=row['stage'],name=row['name'],date='2026-11-07',decision_status='proposed',production_status='concept',implementation_status='not_integrated',tool='image_gen.imagegen (integrado)',source=row['source'],reference=reference,reference_role='Acabamento autoral, sem identidade' if row['stage']==4 else 'Identidade do adulto autoral desta família',sha256=hashlib.sha256((p/'concept.png').read_bytes()).hexdigest(),prompt='prompt.txt',correction='prompt-correcao.txt' if row['correction'] else None,reclassification=row['reclassification'],**dims))

sources=[
 dict(url='https://www.metmuseum.org/art/collection/search/552096',title='Sacred animal mummy of an ibis',entity='The Metropolitan Museum of Art',accessed='2026-11-07',fact='O texto do acervo descreve ênfase linear escura obtida com linho tingido no invólucro de um íbis.',interpretation='Alternar faixas claras e marca escura dá hierarquia e superfície de registro ao Ibiscrito; não copiar corpo, símbolos religiosos ou rituais.',used_as_generation_input=False),
 dict(url='https://collections.lacma.org/object/98288',title='Heart Scarab',entity='LACMA',accessed='2026-11-07',fact='As notas curatoriais descrevem amuletos de escaravelho ligados a regeneração e proteção, com inscrição e colocação junto ao enfaixe.',interpretation='Função de preservar e selar pode organizar um escaravelho; a prensa e a história das Ruínas são invenções nossas, sem transferência de crenças para o cânone.',used_as_generation_input=False),
 dict(url='https://www.museum.qld.gov.au/kurilpa/discovering-ancient-egypt-self-guided-tours/self-guided-tour/09-mummified-animals',title='09 | Mummified animals',entity='Queensland Museum Kurilpa',accessed='2026-11-07',fact='O texto descreve crocodilo modelado por camadas sobrepostas de hastes vegetais e linho, e detalhes representados sobre o envoltório.',interpretation='Camadas podem construir anatomia e suporte em vez de apenas cobrir um animal. Aplicação proposta em Crocáfago; não é reconstrução histórica. Dromedário acústico inteiramente inventado.',used_as_generation_input=False)
]
dump(OUT/'fontes.json',sources)
write(OUT/'PESQUISA.md','# Pesquisa aplicada\n\nLeitura textual de três páginas de acervos museológicos, consultadas em 2026-11-07. Não se alega inspeção de coleções inteiras. As imagens desses acervos não entraram na geração.\n\n'+ '\n\n'.join(f'## [{s["title"]}]({s["url"]})\n\n{s["entity"]}. Fato descrito: {s["fact"]}\n\nLeitura de design: {s["interpretation"]}' for s in sources)+'\n\nO equilíbrio 45/45/10, acabamento e estágios vêm dos estudos e artes autorais locais. Mumificação histórica e nossa conservação de papel vivo são contextos distintos, identificados como tal na lore.\n')
allcharts=[]
for f in families:
 d=ROOT/'documentation/creatures'/f'{f["id"]}-chart-v1';d.mkdir(parents=True,exist_ok=True)
 nodes=[]
 for n,s in enumerate(f['forms'],1):
  p=ROOT/'art/creatures'/f['id']/s[0]/'concept-v1'
  nodes.append(dict(id=s[0],name=s[1],kind='stage',stage=n,maturity=ages[n-1],identity=observations[s[0]],story=f['story'],action=['perceber e proteger a si','explorar a função','coordenar apoio e ação',f['role']][n-1],tradeoff=['Pouca autonomia de movimento.','Proteção e controle ainda limitados.','Estrutura em desenvolvimento, alcance parcial.','Especialização exige preparar apoio e controlar tensão.'][n-1],decision_status='proposed',production_status='concept',art=rel(p/'concept.png',d),brief=rel(p/'brief.md',d)))
 reasons=[f'{nodes[0]["name"]} ganha apoios e partes próprias para começar a função de {f["role"].lower()}.',f'{nodes[1]["name"]} desenvolve sustentação e articulações para coordenar essa função em {nodes[2]["name"]}.',f'{nodes[2]["name"]} reorganiza seus apoios e faixas na estrutura especializada de {nodes[3]["name"]}; {f["story"]}']
 edges=[dict(**{'from':nodes[n]['id'],'to':nodes[n+1]['id']},kind='reweaving',reason=reasons[n],decision_status='proposed') for n in range(3)]
 chart=dict(family_id=f['id'],scope='Concept e lore propostas; sem integração.',nodes=nodes,edges=edges)
 dump(d/'chart.json',chart);dump(d/'fontes.json',sources)
 write(d/'CHART.md',f'# Família {f["name"]}\n\n{f["role"]}.\n\n'+ ' → '.join(n['name'] for n in nodes)+'\n\n'+f['story']+'\n\n'+'\n\n'.join(reasons)+f'\n\n[Lore compartilhada]({rel(OUT/"LORE.md",d)})\n\nArtes, nomes e condições propostos; não integrados.\n')
 write(ROOT/'art/creatures'/f['id']/'DECISOES.md','# Registro de criação\n\n2026-11-07. Autor: “Agora quero que você crie 4 linhas de soulmonsters mumificados, crie uma lore”. Produção de quatro concepts de estágio por família autorizada, sem pausa de aprovação. Artes e história novas aguardam avaliação. Sem alteração de gameplay ou rig.\n')
 allcharts.append((f,d,chart))

font=lambda n:ImageFont.truetype('C:/Windows/Fonts/arial.ttf',n)
sections=[];overview=Image.new('RGB',(2400,2960),'#f3efe6')
for row,(f,d,c) in enumerate(allcharts):
 im=Image.new('RGB',(2400,740),'#f3efe6');draw=ImageDraw.Draw(im)
 draw.text((35,20),f['name']+' · '+f['role'],font=font(38),fill='#16373a')
 draw.text((35,77),'Enfaixados do Fio Quieto · 2D mangá / papel vivo · lore proposta',font=font(23),fill='#52666a')
 cards=[]
 for col,n in enumerate(c['nodes']):
  x=20+595*col;y=135;draw.rounded_rectangle((x,y,x+575,y+575),radius=15,fill='white')
  source=(d/n['art']).resolve()
  with Image.open(source) as raw: thumb=ImageOps.contain(raw.convert('RGB'),(555,455),Image.Resampling.LANCZOS)
  im.paste(thumb,(x+(575-thumb.width)//2,y+(455-thumb.height)//2))
  draw.text((x+18,y+470),n['name'],font=font(29),fill='#16373a')
  draw.text((x+18,y+515),ages[col],font=font(23),fill='#52666a')
  src=rel(source,OUT);brief=rel((d/n['brief']).resolve(),OUT)
  cards.append(f'<article><a href="{src}"><img src="{src}" alt="{n["name"]}, {ages[col]}"></a><h3>{n["name"]}</h3><p>{ages[col]}</p><p>{html.escape(n["identity"])}</p><a href="{brief}">Brief</a></article>')
 im.save(OUT/f'{f["id"]}-familia.png');overview.paste(im,(0,row*740))
 sections.append(f'<section id="{f["id"]}"><h2>{f["name"]} · {f["role"]}</h2><p>{f["story"]}</p><a href="{f["id"]}-familia.png"><img class="family" src="{f["id"]}-familia.png" alt="Linha completa de {f["name"]}"></a><div class="cards">'+''.join(cards)+f'</div><p><a href="{rel(d/"chart.json",OUT)}">Chart JSON</a> · <a href="{rel(d/"CHART.md",OUT)}">História da família</a></p></section>')
overview.save(OUT/'quatro-linhas.png')
style='*{box-sizing:border-box}body{margin:0;background:#102b31;color:#f4edde;font:18px/1.6 system-ui,sans-serif}main{max-width:1500px;margin:auto;padding:42px 28px}h1{font-size:clamp(34px,5vw,62px);line-height:1.1}h2{line-height:1.3}p{max-width:100ch}a{color:#a2e8d9}a:focus-visible{outline:3px solid #ffce6a;outline-offset:5px}nav{display:flex;gap:25px;flex-wrap:wrap;margin:30px 0}.family{width:100%;height:auto;border-radius:12px}.cards{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:20px;margin-top:25px}article{background:#f3eee6;color:#183a40;border-radius:12px;padding:18px}article a{color:#13625e}article img{width:100%;height:210px;object-fit:contain;background:white}section{margin:60px 0}@media(max-width:950px){.cards{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(max-width:500px){.cards{grid-template-columns:1fr}main{padding:24px 16px}}'
write(OUT/'index.html','<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Enfaixados do Fio Quieto · Soulmonsters</title><style>'+style+'</style><main><h1>O cuidado que atravessou as Ruínas.</h1><p>Quatro linhas mumificadas, 16 concepts e uma lore original. As faixas conservam corpos de papel e seus registros; a alma continua na única rabiola. Novas artes e história propostas, sem integração.</p><p><a href="LORE.md">Ler a lore completa</a> · <a href="PESQUISA.md">Pesquisa e fontes</a> · <a href="REVISAO.md">Conferência</a> · <a href="quatro-linhas.png">Prancha geral</a></p><nav>'+''.join(f'<a href="#{f["id"]}">{f["name"]}</a>' for f in families)+'</nav>'+''.join(sections)+'<p>Ferramenta integrada image_gen; prompts e registros junto de cada PNG. Concepts de fundo branco, ainda sem recortes, vistas adicionais, rig ou animação.</p></main></html>')
write(OUT/'REVISAO.md','# Revisão do lote\n\n16 concepts finais abertos e conferidos individualmente, um mon por chamada, com referências apenas autorais. Conferidos membros, rabiolas, faces e contraste de maturidade.\n\nCorreções: Lácrulo perdeu pata excedente; Crocote perdeu couraça de adulto em miniatura; Velaravan recebeu focinho camelídeo e orelhas menores. Crocurna reutiliza o estudo mais robusto inicialmente destinado a Crocote, reclassificado como jovem após a criança ser redesenhada; três tentativas de um jovem mais atlético foram recusadas pela ferramenta e não produziram arquivos. Plano final e brief registram jovem robusto, não atlético.\n\nLimites: Selim ficou com mais aros/camadas que o brief mínimo. Ibisco tem pescoço mais longo que o pedido. Quantidade exata de lâminas nas asas de Caligíbis não certificada nesta vista. Dunelo tem três separações nos pés enquanto jovem/adulto usam duas; alinhar vistas antes de recorte/rig. Algumas pontas têm margens estreitas, mas estão completas. Concepts de fundo branco, sem alpha/grid técnico/rig/animação certificados.\n\nLore e novas artes são propostas. Verificação estrutural dos charts e links locais não equivale a inspeção de navegador nem implementação. Nenhuma mudança no código de jogo.\n')
dump(OUT/'catalogo.json',dict(date='2026-11-07',concept_count=16,families=[dict(id=f['id'],name=f['name'],chart=rel(d/'chart.json',OUT),sheet=f'{f["id"]}-familia.png') for f,d,c in allcharts]))
spec=importlib.util.spec_from_file_location('chartvalidator',ROOT/'.agents/skills/soulmonsters-charts/scripts/validar_chart.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
errors=[]
for f,d,c in allcharts: errors.extend(f'{f["name"]}: {e}' for e in module.validate(c,d))
dump(OUT/'validacao.json',dict(families=4,nodes=16,edges=12,errors=errors));assert not errors,errors
print('16 concepts, quatro charts e lore registrados; estrutura validada.')
