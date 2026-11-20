from pathlib import Path
import json, shutil, hashlib, os, importlib.util
from html import escape
from PIL import Image, ImageOps, ImageDraw, ImageFont

D=Path(__file__).resolve().parent
R=D.parents[2]
data=json.loads((D/'producao.json').read_text(encoding='utf-8'))
initial=json.loads((D/'producao-inicial.json').read_text(encoding='utf-8'))
def write(p,t):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(t,encoding='utf-8')
def dump(p,v):write(p,json.dumps(v,ensure_ascii=False,indent=2)+'\n')
def rel(p,b):return os.path.relpath(p,b).replace('\\','/')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

notes={
'gravurso':'Dois braços enormes com mãos abertas e duas pernas compactas; cabeça pequena diante dos antebraços. Braçadeiras e gola bronze deixam o corpo marfim visível. As velas posteriores são amplas. Rabiola única completa. Há mais dobras de superfície que o mínimo imaginado; ainda são planos largos, sem estrias de carne.',
'avelince':'Quatro patas e pés distintos, cabeça felina exposta e duas orelhas-velas. Manto lateral sustentado por varetas e proteção ameixa localizada nos ombros/antepernas. Pequeno detalhe violeta na articulação é proposta de dobradiça, não Crystai Pipa. Uma rabiola completa.',
'torvargo':'Dois braços, duas pernas curtas, face de javali com presas laterais e ombro de impacto assimétrico. Corpo carvão/marfim exposto entre as placas coral. Rabiola única completa. A mão distante tem dedos parcialmente sobrepostos; vistas técnicas futuras devem resolver a contagem e o apoio.',
'najarcal':'Dois braços e nenhuma perna, sustentação por cauda serpentina contínua. Dois aros abertos conectados aos punhos, duas palmas expostas e capuz de varetas. Uma rabiola ao final da cauda. A gola ganhou dobras que lembram uma juba curta de papel; é construção fantástica, não estudo zoológico.',
'raptorio':'V2: duas asas-braços com mãos, duas pernas de ave e uma rabiola trançada com terminal de carvalho. Três grandes folhas lobadas por asa substituem as penas anteriores; varetas claras sustentam as folhas. Ramos de visco com bagas-nós claras aparecem nos pontos de tensão, sustentando uma linha entre as garras. Cabeça adulta, olhos verdes pequenos e peito marfim exposto preservados. A linha entre mãos é ferramenta de ação, não segunda rabiola. As folhas estão mais verdes que no primeiro concept; mudança solicitada pelo motivo botânico.',
'cervoraculo':'V2: quatro pernas com cascos fendidos. Dois arcos de chifres possuem seis velas com olhos, três por arco; os seis motivos são desenhos de papel, não outras almas. Linhas tensionam as velas até a proteção dos ombros, e um pequeno prumo suspenso ocupa o vão. Olhos reais violetas e cabeça pequena preservam a leitura adulta. O gesto continua frontal em três quartos, sem o olhar para trás imaginado no brief inicial. Rabiola única completa.',
'cascoronte':'V2: abertura lateral com moldura, banco, piso, janela ao fundo, alçapão superior e dois degraus. Silhueta humana anônima sentada demonstra escala; não é personagem novo ou definição de lotação. Três pés estão expostos; o quarto apoio está oculto pela escada/corpo, portanto esta vista não certifica sua geometria. Casco abriga um compartimento acima do corpo, não um vazio no abdômen. Há mais estrutura de cabine que no abrigo inicial; animação de fechar/andar e escala canônica ainda não existem. Rabiola única completa.',
'melicodia':'Nova proposta em substituição ao Mantigardo rejeitado. Seis membros: duas garras operárias dianteiras e quatro patas de apoio; quatro asas em dois pares, duas antenas. Abdômen-colmeia com aletas e saída contínua para três cubos de mel. Ferrão é uma pipa em losango com varetas, nós, ponta escura e conexão única à cauda; essa conexão é a rabiola. Face insetoide, olhos ciano e corpo compacto. A caixa torácica remete deliberadamente a um processador; juntas e membros mantêm leitura de criatura. Há pequenas faixas de luz no mel, sem textura fotográfica.'
}
materials={
'gravurso':['Marfim / ardósia','Bronze fosco','Umber','Azul gelo'],
'avelince':['Cinza claro','Ameixa','Marfim','Violeta'],
'torvargo':['Carvão / marfim','Coral','Vermelho escuro','Menta'],
'najarcal':['Areia / marfim','Petróleo','Cinza','Azul'],
'raptorio':['Marfim','Nogueira','Verde de carvalho','Verde menta'],
'cervoraculo':['Marfim / cinza','Verde floresta','Varetas claras','Violeta'],
'cascoronte':['Marfim / cinza quente','Bordô','Grafite','Azul'],
'melicodia':['Grafite','Cera marfim','Mel âmbar','Ciano']}
unknown='Nomes, títulos e lore são propostas. Pré-evoluções, facção, obtenção, poderes, escala canônica e integração não definidos. Concepts não certificam recortes, rig, animações ou grade técnica de pixel art.'
spec=importlib.util.spec_from_file_location('chart_validator',R/'.agents/skills/soulmonsters-charts/scripts/validar_chart.py')
v=importlib.util.module_from_spec(spec);spec.loader.exec_module(v)
checks=[];records=[]

def save_art(m,folder,status,note):
    folder.mkdir(parents=True,exist_ok=True)
    shutil.copy2(m['source'],folder/'concept.png')
    write(folder/'prompt.txt',m['prompt']+'\n')
    if m.get('correction'):
        write(folder/'prompt-correcao.txt',m['correction']+'\n')
        if m.get('intermediate'):shutil.copy2(m['intermediate'],folder/'antes-correcao.png')
    with Image.open(folder/'concept.png') as im:
        meta=dict(width=im.width,height=im.height,mode=im.mode,alpha_extrema=im.getextrema()[-1] if im.mode=='RGBA' else None)
    dump(folder/'manifest.json',dict(id=m['id'],name=m['name'],date=data['date'],stage=4,decision_status=status,production_status='concept',implementation_status='not_integrated',tool='image_gen.imagegen',source=m['source'],sha256=sha(folder/'concept.png'),reference_role='Arte própria do mon como alvo de edição; Grifarca próprio somente para acabamento nas gerações novas. Benchmark externo estudado, não anexado.',prompt='prompt.txt',correction='prompt-correcao.txt' if m.get('correction') else None,**meta))
    write(folder/'revisao.md',f'# Conferência — {m["name"]}\n\n{note}\n\nEstado: {status}. Fundo branco opaco. {unknown}\n')

# Guardar os desenhos anteriores, sem apresentá-los como revisão aprovada.
for m in initial['members']:
    if m['id'] in ['raptorio','cervoraculo','cascoronte','mantigardo']:
        rejected=m['id']=='mantigardo'
        note='Rejeitado pelo autor: “o último insectoid ficou o suco do genericismo”; substituído na seleção por uma Lord Abelha original, sem vínculo evolutivo.' if rejected else 'Versão inicial preservada; o autor solicitou desenvolvimento específico dos motivos e da função. A seleção atual está em concept-v2.'
        save_art(m,R/'art/creatures'/m['id']/'concept-v1','rejected' if rejected else 'superseded',note)

for m in data['members']:
    p=R/'art/creatures'/m['id']/f'concept-v{m["version"]}'
    save_art(m,p,'proposed',notes[m['id']])
    defined=data['critique'] if m['id'] in ['raptorio','cervoraculo','cascoronte','melicodia'] else 'Criar oito Lords Creatures com base no estudo destrinchado da fera armadurada.'
    write(p/'brief.md',f'# {m["name"]} — {m["title"]}\n\n## Definido pelo autor\n\n{defined}\n\nDireção: 45% criatura, 45% pipa viva e 10% acabamento pixel/2D mangá; corpo e rosto bestiais, proteção localizada, cor por material.\n\n## Proposta\n\nAdulto (IV), {m["species"]}. Ação: **{m["verb"]}**.\n\n{m["lore"]}\n\n## Construção solicitada\n\n{m["prompt"]}\n\n## Observado\n\n{notes[m["id"]]}\n\n## Desconhecido\n\n{unknown}\n')
    chartdir=R/'documentation/creatures'/f'{m["id"]}-chart-v1'
    chart=dict(family_id=m['id'],scope='Um adulto proposto de Lords Creatures; sem ligações evolutivas ou integração.',nodes=[dict(id=m['id'],name=m['name'],kind='stage',stage=4,identity=m['species']+' · '+m['verb'],story=m['lore'],decision_status='proposed',production_status='concept',art=rel(p/'concept.png',chartdir),brief=rel(p/'brief.md',chartdir))],edges=[])
    dump(chartdir/'chart.json',chart)
    errs=v.validate(chart,chartdir);assert not errs,errs
    checks.append(dict(id=m['id'],errors=errs))
    write(chartdir/'CHART.md',f'# {m["name"]}\n\nAdulto proposto · {m["species"]}. {m["lore"]}\n\n[Arte]({rel(p/"concept.png",chartdir)}) · [Brief]({rel(p/"brief.md",chartdir)}) · [Conjunto]({rel(D/"index.html",chartdir)}).\n\n{unknown}\n')
    rec={k:m[k] for k in ['id','name','species','title','verb','lore','version']}
    rec.update(art=rel(p/'concept.png',D),brief=rel(p/'brief.md',D),review=rel(p/'revisao.md',D),materials=materials[m['id']])
    records.append(rec)

font=lambda n:ImageFont.truetype('C:/Windows/Fonts/arial.ttf',n)
def board(items,cols,filename,title):
    cw,ch=1000,880;top=118;rows=(len(items)+cols-1)//cols
    out=Image.new('RGB',(cols*cw,top+rows*ch),'#eee9df');dr=ImageDraw.Draw(out)
    dr.text((30,22),title,font=font(44),fill='#18313d')
    for k,r in enumerate(items):
        x=k%cols*cw+15;y=top+k//cols*ch
        dr.rectangle((x,y,x+cw-30,y+ch-20),fill='white')
        with Image.open((D/r['art']).resolve()) as src:im=ImageOps.contain(src.convert('RGB'),(cw-65,ch-155),Image.Resampling.LANCZOS)
        out.paste(im,(x+(cw-30-im.width)//2,y+12+(ch-155-im.height)//2))
        dr.text((x+24,y+ch-122),r['name'],font=font(38),fill='#18313d')
        dr.text((x+24,y+ch-65),r['verb']+' · '+r['species'],font=font(25),fill='#536671')
    out.save(D/filename)
board(records,4,'oito-lords.png','LORDS CREATURES · OITO PROPOSTAS')
revised=[r for r in records if r['id'] in ['raptorio','cervoraculo','cascoronte','melicodia']]
board(revised,2,'quatro-revisoes.png','LORDS CREATURES · QUATRO IDENTIDADES REFINADAS')
dump(D/'grupo.json',dict(title='Lords Creatures',date=data['date'],decision_status='proposed',members=records,rejected='Mantigardo preservado no histórico; substituído por Melicódia, não sua evolução.'))
write(D/'LORE.md','# Lords Creatures\n\nO nome do conjunto vem do pedido do autor; os nomes individuais, títulos e histórias abaixo são propostas. A alma continua na rabiola de cada criatura. Os olhos oraculares de Cervoráculo são motivos nas velas; os dados de mel de Melicódia são matéria codificada, sem almas adicionais.\n\n'+ '\n\n'.join(f'## {r["name"]} — {r["title"]}\n\n**{r["verb"]}** · {r["species"]}.\n\n{r["lore"]}' for r in records)+'\n\n'+unknown+'\n')
write(D/'PESQUISA.md','# Direção aplicada\n\nBase direta: [destrincho da fera armadurada](../../../art/benchmarks/fera-armadurada-2026-11-07/ANALISE.md), incluindo a distinção entre corpo bestial, proteção localizada, forma funcional e cor por material. Não se copiou a paleta, os braceletes inscritos, a capa ou a anatomia do desenho externo. A referência externa não entrou na geração.\n\nReferência própria de acabamento: [Grifarca](../../../art/creatures/grifarca/concept-v2/concept.png). Revisões usam o concept próprio anterior como alvo de edição. Carvalho, visco, olhos nos chifres, transporte na carapaça e abelha/processador são direções expressas pelo autor; a aplicação é fantástica. Não se apresenta essa construção como pesquisa botânica, anatômica zoológica ou arquitetura computacional real.\n\n## Cor por material\n\n'+ '\n'.join(f'- **{r["name"]}:** corpo {r["materials"][0]}; proteção {r["materials"][1]}; suporte/membrana {r["materials"][2]}; acento {r["materials"][3]}.' for r in records)+'\n\nSão massas de cor para reprodução, não uma paleta indexada já quantizada. Sombras locais e pequenas luzes não são novos materiais.\n')
write(D/'REVISAO.md','# Revisão da seleção\n\n'+ '\n\n'.join(f'## {r["name"]}\n\n{notes[r["id"]]}' for r in records)+'\n\n## Histórico\n\n'+data['critique']+'\n\nMantigardo teve uma pata extra removida antes da crítica de identidade. Mesmo corrigido, foi rejeitado por genericismo e não integra a seleção atual. As três versões anteriores permanecem preservadas; as quatro propostas novas aguardam avaliação do autor.\n\n## Limites\n\nInspeção visual individual e prancha conjunta. O helper valida estrutura e caminhos dos oito charts, não originalidade, ergonomia da cabine ou animações. Nenhum código do jogo alterado. '+unknown+'\n')
cards=[]
for r in revised+records[:4]:
    cards.append(f'<article><a href="{r["art"]}"><img src="{r["art"]}" alt="{escape(r["name"]+": "+r["species"])}"></a><h2>{r["name"]}</h2><h3>{r["title"]} · {r["verb"]}</h3><p>{r["lore"]}</p><p><a href="{r["brief"]}">Brief</a> · <a href="{r["review"]}">Conferência</a> · <a href="{r["art"]}">Imagem original</a></p></article>')
css='*{box-sizing:border-box}body{margin:0;background:#142834;color:#eee9df;font:18px/1.6 system-ui}main{max-width:1700px;margin:auto;padding:32px 24px}h1{font-size:clamp(36px,6vw,70px);line-height:1.1}a{color:#8bd8ce}a:focus-visible{outline:3px solid gold;outline-offset:5px}.board{width:100%;height:auto}.cards{display:grid;grid-template-columns:1fr 1fr;gap:24px;margin-top:32px}article{background:#eee9df;color:#18313d;padding:24px;border-radius:10px}article a{color:#126678}article img{width:100%;height:520px;object-fit:contain;background:white}h2,h3{line-height:1.3}@media(max-width:760px){.cards{grid-template-columns:1fr}article img{height:auto}}'
write(D/'index.html','<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Lords Creatures · Soulmonsters</title><style>'+css+'</style><main><h1>Lords Creatures</h1><p>Oito adultos propostos: corpo bestial primeiro, armadura localizada e matéria de pipa viva. As revisões desenvolvem carvalho e visco, um oráculo de seis olhos, transporte na carapaça e uma colmeia que codifica mel.</p><p><a href="LORE.md">Lore</a> · <a href="PESQUISA.md">Direção e materiais</a> · <a href="REVISAO.md">Conferência</a> · <a href="oito-lords.png">Ver os oito</a></p><a href="quatro-revisoes.png"><img class="board" src="quatro-revisoes.png" alt="Raptório, Cervoráculo, Cascoronte e Melicódia, quatro propostas refinadas"></a><div class="cards">'+''.join(cards)+'</div><p>Nomes e lore propostos. Mantigardo foi rejeitado e permanece apenas no histórico. Concepts com fundo branco; ainda sem recortes, rigs ou integração.</p></main></html>')
dump(D/'validacao.json',dict(date=data['date'],charts=checks,concepts_current=8,structural_ok=True,scope='Arquivos, imagens, hashes e charts. Inspeção visual individual e prancha; não certifica integração ou movimento.'))
print('8 Lords atuais; 3 versões anteriores e Mantigardo arquivados; 8 charts válidos; 2 pranchas e galeria geradas.')
