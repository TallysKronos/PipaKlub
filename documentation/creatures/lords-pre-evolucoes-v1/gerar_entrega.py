from pathlib import Path
import json, shutil, os, hashlib, importlib.util
from html import escape
from html.parser import HTMLParser
from PIL import Image, ImageOps, ImageDraw, ImageFont
D=Path(__file__).resolve().parent
R=D.parents[2]
plan=json.loads((D/'PLANO.json').read_text(encoding='utf-8'))
production=json.loads((D/'producao.json').read_text(encoding='utf-8'))
families=plan['families']
labels=['Bebê · I Cafifa','Criança · II Pipa','Jovem · III Arraia','Adulto · IV Pandorga']
slugs=['baby','child','young']
def write(p,t):
    p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t,encoding='utf-8')
def dump(p,v):write(p,json.dumps(v,ensure_ascii=False,indent=2)+'\n')
def rel(p,b):return os.path.relpath(p,b).replace('\\','/')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
spec=importlib.util.spec_from_file_location('v',R/'.agents/skills/soulmonsters-charts/scripts/validar_chart.py')
v=importlib.util.module_from_spec(spec);spec.loader.exec_module(v)
notes=[
['Bolsa suspensa de papel, sem pernas; duas abas laterais curtas e uma rabiola com etiqueta quadrada. Olhos mais arredondados que o adulto, simplificação de bebê.',
 'Correção localizada retirou a quinta pata gerada. Quatro membros na versão atual: um dianteiro erguido, outro no chão e dois traseiros. Uma braçadeira e uma alça nas costas. Um fragmento de papel solto representa o exercício de segurar, sem outra criatura.',
 'Quatro patas, ombros baixos, dois ganchos simples e uma tira dorsal. Rabiola única. O peso está nos apoios dianteiros; o adulto muda para postura bípede e amplia as velas.'],
['Cabeça-pipa sem tronco ou patas, duas orelhas-velas e uma rabiola. Grandes áreas quietas e olhos violetas.',
 'Quatro patas, pequenas abas nos ombros e duas orelhas com varetas. Sem braceletes; expressão ainda curiosa. Uma rabiola.',
 'Quatro patas longas e corpo esguio. As duas velas laterais ficaram grandes, embora o manto seja mais simples e menos envolvente que o adulto. Dois braceletes anteriores, proteção de um ombro e uma rabiola.'],
['Broto arredondado sem membros, focinho coral, duas orelhas e uma rabiola curta. As grandes formas simples favorecem o estágio inicial.',
 'Quadrúpede com quatro cascos fendidos, presas pequenas e crista coral. Sem braçadeiras ou grande placa de impacto.',
 'Dois braços e duas pernas; ombro menor, apenas um punho protegido, torso bem mais estreito e presas laterais. As dobras do torso são numerosas em comparação com o bebê, mas permanecem planas.'],
['Serpente simples sem braços, capuz em crescente e uma rabiola. A cauda em espiral ficou mais longa que a cabeça-broto inicialmente imaginada; não é apenas uma cabeça flutuante.',
 'Serpente sem braços; dois painéis de capuz com varetas e borda petróleo. Corpo fita com vão na curva e rabiola única.',
 'Dois braços, nenhuma perna; capuz de três painéis, só um aro aberto e duas tiras simples nos braços. Corpo estreito e cauda de apoio sem placas grandes.'],
['Bolota-cabeça de papel com duas asas pequenas, sem pés. A rabiola nasce no alto da cabeça junto a um nó claro e termina em folha. Essa raiz é própria desta forma, não uma segunda cauda.',
 'Duas asas-braços e dois pés de ave; uma folha por asa e pequeno colar de visco. A rabiola continua pela raiz superior da cabeça; não há rabiola adicional no quadril.',
 'Duas asas-braços, duas pernas longas e peito esguio, nós de visco nos punhos. Folhas em camadas ficaram mais numerosas que as duas vanes solicitadas; o conjunto ainda tem menos massa que o adulto. Uma rabiola no quadril e pequeno fio funcional entre as pontas de uma garra.'],
['Cabeça-pipa com duas orelhas verdes e símbolo de olho sem íris na testa. O símbolo ficou aberto em contorno, em vez da pálpebra fechada pedida; não é terceiro olho biológico. Duas vistas oculares do rosto e uma rabiola.',
 'Quatro pernas leves, dois pequenos chifres e duas velas com olhos. Sem proteção de pernas, apenas colar verde. Rabiola única.',
 'Quatro patas; dois arcos com quatro velas-olhos no total e tirantes para um colar simples. O adulto amplia para seis velas e recebe o prumo; jovem sem joelheiras.'],
['Corpo pequeno sob uma única dobra de casco; duas abas em vez de pernas desenvolvidas. Olho azul e rabiola curta. O volume do casco já antecipa o abrigo.',
 'Quatro pés visíveis; portinhola pequena com rolinho de papel. O casco ganhou uma sobreposição superior além da cúpula pedida; permanece sem cabine ou degraus.',
 'Quatro pés, duas placas de teto, piso, manta enrolada, apoio único da tampa e aba de carga. Não há banco, pessoa ou escada de passageiro. Uma rabiola.'],
['Célula hexagonal sem pernas/asas, duas antenas, marca de mel e uma pipa no terminal da rabiola. Olhos em facetas sem pupila desenhada.',
 'Correção acrescentou um apoio distante para explicitar seis membros: duas garras e quatro patas. Duas asas, duas antenas, uma gota no compartimento e ferrão-pipa único.',
 'Seis membros, quatro asas, duas antenas e um cubo de mel ligado à saída. As aletas ficaram em três, em vez das duas pedidas; corpo e peito são mais estreitos que a adulta. Surgiram folhas de papel manipuladas pelas garras, extensão proposta da ação de organizar sinais. Uma rabiola-ferrão.']]
unknown='Nomes individuais das pré-formas, requisitos de Remonta, níveis, escala canônica e habilidades de jogo não definidos. Desenhos de olhos, objetos carregados e dados de mel não criam almas extras. Concepts com fundo branco; sem rig, animações ou integração. Não são pixel art em grade técnica validada.'
checks=[];groups=[]
for fi,f in enumerate(families):
    chartdir=R/'documentation/creatures'/f'{f["id"]}-chart-v1'
    oldchart=chartdir/'chart.json'
    if oldchart.exists() and not (chartdir/'chart-adulto-anterior.json').exists():
        shutil.copy2(oldchart,chartdir/'chart-adulto-anterior.json')
    nodes=[];arts=[]
    for si in range(3):
        g=next(g for g in production['results'] if g['fi']==fi and g['si']==si)
        p=R/'art/creatures'/f['id']/slugs[si]/'concept-v1'
        p.mkdir(parents=True,exist_ok=True)
        shutil.copy2(g['source'],p/'concept.png');write(p/'prompt.txt',g['prompt']+'\n')
        if g.get('correction'):
            write(p/'prompt-correcao.txt',g['correction']+'\n');shutil.copy2(g['previous'],p/'antes-correcao.png')
        with Image.open(p/'concept.png') as im:
            im.verify()
        with Image.open(p/'concept.png') as im:
            meta=dict(width=im.width,height=im.height,mode=im.mode,alpha_extrema=im.getextrema()[-1] if im.mode=='RGBA' else None)
        write(p/'brief.md',f'# {f["adult"]["name"]} — {labels[si]}\n\n## Definido pelo autor\n\nCriar as pré-evoluções dos oito Lords atuais, incluindo os quatro revisados. A criatura adulta e sua especialidade são a base; Mantigardo rejeitado não participa.\n\n## História proposta\n\n{f["story"]}\n\nAção desta forma: **{f["stages"][si][1]}**.\n\n## Construção proposta\n\n{f["stages"][si][0]}\n\n## Observado na arte\n\n{notes[fi][si]}\n\n## Limites\n\n{unknown}\n')
        write(p/'revisao.md',f'# Conferência — {f["adult"]["name"]}, {labels[si]}\n\n{notes[fi][si]}\n\nImagem aberta individualmente após geração; comparação com o adulto e prancha da família. Proposta visual ainda sem aprovação específica. {unknown}\n')
        dump(p/'manifest.json',dict(id=f['id']+'-'+slugs[si],family_id=f['id'],stage=si+1,date='2026-11-07',decision_status='proposed',production_status='concept',implementation_status='not_integrated',tool='image_gen.imagegen',source=g['source'],sha256=sha(p/'concept.png'),reference=rel(Path(f['reference']),p),reference_role='Adulto próprio: identidade, material e parentesco; estrutura pré-evolutiva nova.',prompt='prompt.txt',correction='prompt-correcao.txt' if g.get('correction') else None,**meta))
        node=dict(id=f['id']+'-'+slugs[si],name=f['adult']['name']+' — '+['Bebê','Criança','Jovem'][si],kind='stage',stage=si+1,identity=f['stages'][si][1],story=f['story'],decision_status='proposed',production_status='concept',art=rel(p/'concept.png',chartdir),brief=rel(p/'brief.md',chartdir))
        nodes.append(node);arts.append(p/'concept.png')
    adult=f['adult'];ap=Path(f['reference'])
    nodes.append(dict(id=f['id'],name=adult['name'],kind='stage',stage=4,identity=adult['species']+' · '+adult['verb'],story=adult['lore'],decision_status='proposed',production_status='concept',art=rel(ap,chartdir),brief=rel(ap.parent/'brief.md',chartdir),approval_note='Base mantida pelo pedido de criar pré-evoluções; sem nova declaração de integração.'))
    arts.append(ap)
    edges=[dict(**{'from':nodes[i]['id'],'to':nodes[i+1]['id']},kind='reweaving',reason=f'Passa de {f["stages"][i][1].lower()} para '+(f['stages'][i+1][1].lower() if i<2 else adult['verb'].lower())+'. '+f['story'],decision_status='proposed') for i in range(3)]
    chart=dict(family_id=f['id'],scope='Linha com três pré-formas propostas e adulto existente; sem regras de jogo ou integração.',story=f['story'],nodes=nodes,edges=edges)
    dump(chartdir/'chart.json',chart)
    errors=v.validate(chart,chartdir);assert not errors,errors
    checks.append(dict(family=f['id'],nodes=4,edges=3,errors=errors))
    write(chartdir/'CHART.md',f'# Família {adult["name"]}\n\n{f["story"]}\n\n[Prancha completa]({rel(D/(f["id"]+"-linha.png"),chartdir)}) · [Galeria das oito famílias]({rel(D/"index.html",chartdir)}).\n\n'+ '\n\n'.join(f'## {labels[i]}\n\n{nodes[i]["identity"]}\n\n[Arte]({nodes[i]["art"]}) · [Brief]({nodes[i]["brief"]})' for i in range(4))+'\n\n'+unknown+'\n')
    groups.append(dict(id=f['id'],name=adult['name'],story=f['story'],nodes=nodes,arts=arts,chart=rel(chartdir/'chart.json',D)))

font=lambda n:ImageFont.truetype('C:/Windows/Fonts/arial.ttf',n)
def strip(group):
    cw,ch,top=900,800,105
    out=Image.new('RGB',(cw*4,ch+top),'#eee9df');dr=ImageDraw.Draw(out)
    dr.text((28,20),'FAMÍLIA '+group['name'].upper(),font=font(42),fill='#18313d')
    scales=[.57,.73,.87,1.0]
    for i,p in enumerate(group['arts']):
        x=i*cw+12;y=top
        dr.rectangle((x,y,x+cw-24,y+ch-16),fill='white')
        with Image.open(p) as src:
            thumb=ImageOps.contain(src.convert('RGB'),(int((cw-58)*scales[i]),int((ch-125)*scales[i])),Image.Resampling.LANCZOS)
        out.paste(thumb,(x+(cw-24-thumb.width)//2,y+12+(ch-125-thumb.height)//2))
        dr.text((x+22,y+ch-92),labels[i],font=font(30),fill='#18313d')
        if i<3:dr.text((x+22,y+ch-48),families[next(k for k,f in enumerate(families) if f['id']==group['id'])]['stages'][i][1],font=font(23),fill='#536671')
    path=D/(group['id']+'-linha.png');out.save(path);return path
for g in groups:strip(g)
def overview(selected,name):
    out=Image.new('RGB',(3600,905*len(selected)),'#eee9df')
    for i,g in enumerate(selected):
        with Image.open(D/(g['id']+'-linha.png')) as im:out.paste(im,(0,905*i))
    out.save(D/name)
overview(groups[:4],'linhas-1-4.png');overview(groups[4:],'linhas-5-8.png')
html=[]
for g in groups:
    cards=[]
    for i,p in enumerate(g['arts']):
        cards.append(f'<a href="{rel(p,D)}"><img src="{rel(p,D)}" alt="{escape(g["name"]+" — "+labels[i])}"><strong>{labels[i]}</strong></a>')
    html.append(f'<section id="{g["id"]}"><h2>{g["name"]}</h2><p>{g["story"]}</p><div class="stages">'+''.join(cards)+f'</div><p><a href="{g["id"]}-linha.png">Prancha completa</a> · <a href="{g["chart"]}">Chart e relações</a></p></section>')
css='*{box-sizing:border-box}body{margin:0;background:#142834;color:#eee9df;font:18px/1.65 system-ui}main{max-width:1900px;margin:auto;padding:36px 24px}h1{font-size:clamp(35px,5vw,66px);line-height:1.15}a{color:#8bd8ce}a:focus-visible{outline:3px solid gold;outline-offset:4px}nav{display:flex;gap:20px;flex-wrap:wrap}section{padding:30px 0;border-top:1px solid #61717a;margin-top:32px}.stages{display:grid;grid-template-columns:repeat(4,1fr);gap:15px}.stages a{display:block;background:white;color:#18313d;padding:15px;text-align:center}.stages img{width:100%;height:310px;object-fit:contain;display:block}strong{display:block;padding:12px 0}@media(max-width:1050px){.stages{grid-template-columns:1fr 1fr}}@media(max-width:560px){.stages{grid-template-columns:1fr}.stages img{height:auto}}'
write(D/'index.html','<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Oito linhas dos Lords · Soulmonsters</title><style>'+css+'</style><main><h1>Oito Lords, oito histórias de amadurecimento</h1><p>24 pré-evoluções novas: bebê, criança e jovem para cada adulto. Corpo e função se desenvolvem juntos. As pranchas usam tamanhos relativos de apresentação; não definem escala física canônica.</p><nav>'+''.join(f'<a href="#{g["id"]}">{g["name"]}</a>' for g in groups)+'</nav><p><a href="REVISAO.md">Conferência e limites</a> · <a href="PESQUISA.md">Direção e referências</a> · <a href="linhas-1-4.png">Linhas 1–4</a> · <a href="linhas-5-8.png">Linhas 5–8</a></p>'+''.join(html)+'<p>Pré-formas com nomes descritivos provisórios. Sem alterações no jogo.</p></main></html>')
write(D/'REVISAO.md','# Conferência das 24 pré-evoluções\n\n'+ '\n\n'.join(f'## {f["adult"]["name"]}\n\n'+ '\n\n'.join(f'**{labels[si]}:** {notes[fi][si]}' for si in range(3)) for fi,f in enumerate(families))+'\n\n## Alcance da validação\n\nAs 24 imagens foram abertas após geração. Duas correções dirigidas de contagem de membros foram guardadas: Gravurso criança e Melicódia criança. Os oito adultos foram preservados. Os oito charts possuem quatro nós e três relações documentais; o helper verificou estrutura e caminhos, não a qualidade artística. As pranchas indicam maturidade por proporção, não uma escala canônica medida.\n\n'+unknown+'\n')
write(D/'PESQUISA.md','# Referências de construção\n\nBase: [oito Lords atuais](../lords-creatures-v1/index.html), [destrincho da fera armadurada](../../../art/benchmarks/fera-armadurada-2026-11-07/ANALISE.md) e referências de direção/entrega da skill de charts. As imagens próprias dos adultos são as únicas referências visuais anexadas às gerações.\n\nA aplicação aqui é narrativa e fantástica: bebês com poucas formas e capacidade incipiente; crianças já experimentam uma ação; jovens aprendem a sustentá-la; adultos assumem responsabilidade por outros. O desenvolvimento não é uma alegação de anatomia ou metamorfose biológica real. Não houve um novo levantamento de uma franquia externa nesta etapa. Nenhuma arte externa foi anexada à geração.\n\n## O que permanece na família\n\n'+ '\n\n'.join(f'### {f["adult"]["name"]}\n\nMateriais: '+', '.join(f['adult']['materials'])+'.\n\n'+f['story'] for f in families)+'\n\nOs olhos de Cervoráculo são motivos nos painéis. O mel de Melicódia não contém outra alma. A rabiola continua como portadora da alma conforme a bíblia do projeto.\n')
serial=[]
for g in groups:
    serial.append({**g,'arts':[rel(p,D) for p in g['arts']]})
dump(D/'grupo.json',dict(date='2026-11-07',new_concepts=24,adult_references=8,decision_status='proposed',families=serial))
class Links(HTMLParser):
    def __init__(self):super().__init__();self.refs=[]
    def handle_starttag(self,tag,attrs):
        for key,val in attrs:
            if key in ('src','href') and val and not val.startswith(('#','http')):self.refs.append(val)
parser=Links();parser.feed((D/'index.html').read_text(encoding='utf-8'))
missing=[s for s in parser.refs if not (D/s).resolve().exists()]
assert not missing,missing
dump(D/'validacao.json',dict(new_concepts=24,charts=checks,gallery_links=len(parser.refs),missing_links=missing,structural_ok=True,visual_scope='24 imagens individuais; pranchas comparativas. Sem teste de animação, rig ou jogo.'))
print('24 PNGs e documentos salvos, oito charts de quatro estágios válidos, oito pranchas de família, duas visões gerais e galeria com links verificados.')
