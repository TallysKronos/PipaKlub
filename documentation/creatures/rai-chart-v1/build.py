"""Publica estudo Rai e Entrelaço. Sem alterações no jogo ou rigs."""
import hashlib
import html
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps

DOC = Path(__file__).resolve().parent
ROOT = DOC.parents[2]
ART = ROOT / 'art/creatures/rai-family-v1'
SPECS = [
    ('raibroto', 'Raibroto', 1, 'Origem', 'Escutar e aproximar',
     'Filhote em botão baixo e arredondado; quatro patas curtas, presas pequenas e vela ainda fechada.',
     'A curiosidade antecede a escolha de acompanhar alguém; comportamento proposto, não flashback canônico.',
     'O sino grande orienta a atenção; a vela curta conserva tensão sem exigir coordenação adulta.',
     'Pouca sustentação e alcance; depende de passos pequenos.'),
    ('raigume', 'Raigume', 3, 'Interceptação', 'Interceptar a passagem',
     'Jovem baixo e comprido de ombros altos, patas dianteiras fortes e uma quilha de vela estreita.',
     'Aprende a escolher o instante de intervir em vez de saltar a qualquer movimento.',
     'Ombros de membrana tensionada e pés largos concentram o bote; quilha orienta a mudança.',
     'Um bote comprometido exige recuperação antes de nova mudança de direção.'),
    ('raisoberano', 'Raisoberano', 4, 'Interceptação', 'Guardar uma passagem',
     'Adulto quadrúpede amplo e compacto, peito de pipa tensionada e vela aberta em portal protetor.',
     'A potência amadurece em responsabilidade: escolhe o que proteger.',
     'Base larga e grande arco dorsal distribuem pressão sem perder o apoio.',
     'Guardar uma posição custa agilidade e torna perseguições curtas mais lentas.'),
    ('raivela', 'Raivela', 3, 'Condução', 'Contornar a pressão',
     'Jovem felino planar de corpo em losango baixo e duas velas laterais amplas; patas recolhidas.',
     'Aprende a escutar a direção da força e usar o espaço entre dois movimentos.',
     'Velas laterais e cauda de pétalas governam o desvio; corpo leve conserva tensão.',
     'Precisa de espaço lateral e perde eficiência em passagens estreitas.'),
    ('raiatar', 'Raiatar', 4, 'Condução', 'Alinhar a tensão com outro',
     'Adulto felino semiereto em ampulheta, braços livres e duas velas dorsais formando tear oval aberto.',
     'Deixa de depender só do próprio corte e aprende a coordenar forças diferentes.',
     'Postura estável e tear dorsal permitem orientar a linha em conjunto; presas e mãos não seguram armas.',
     'Preparar uma ligação exige apoio e atenção, comprometendo resposta imediata.'),
    ('entreflor', 'Entreflor', None, 'Entrelaço', 'Trançar e redirecionar duas linhas',
     'Corpo único de pipa viva com apoios dos dois parceiros; um braço termina na boca do Arauto e o outro na boca de sabre do Raiatar. Duas linhas saem das respectivas bocas.',
     'Impulso e direção se tornam cooperação: nenhum dos dois é apagado para que a união exista.',
     'Bocas integrais nos antebraços conduzem os dois chicotes físicos; torso e apoios misturam a construção de ambos.',
     'Descompasso das duas direções compromete a tensão; duração, retorno e custo não definidos.'),
]
sources = json.loads((DOC / 'sources.json').read_text(encoding='utf-8'))
references = json.loads((DOC / 'generation-references.json').read_text(encoding='utf-8'))
nodes = []
for ident, name, stage, route, action, anatomy, story, mechanism, tradeoff in SPECS:
    folder = ART / ident / 'concept-v1'
    image = folder / 'concept.png'
    if not image.is_file() or not (folder/'prompt.txt').is_file():
        raise FileNotFoundError(folder)
    node = dict(id=ident, name=name, kind='configuration' if stage is None else 'stage', stage=stage,
                route=route, identity=anatomy, story=story, action=action, mechanism=mechanism,
                tradeoff=tradeoff, decision_status='approved',
                approval_note='Autor: "Todos aprovados!" após a entrega do chart completo. Aprovação dos nomes e concepts, incluindo Entreflor; sem certificar regras, rigs ou integração.',
                production_status='concept',
                implementation='não integrado', art=f'../../../art/creatures/rai-family-v1/{ident}/concept-v1/concept.png',
                brief=f'../../../art/creatures/rai-family-v1/{ident}/concept-v1/brief.md')
    if ident == 'entreflor':
        node['partners'] = ['raiatar', 'arauto-da-tempestade']
        node['user_requirement'] = 'Dois braços com as respectivas bocas dos parceiros, cada uma emitindo chicote de linha; corpo e pipa dos dois reunidos.'
    brief = f'''# {name} — concept aprovado

## Definido pelo autor
Rai é o parceiro de Tyler, está na forma criança e pode ter bebê, jovem, adulto e rotas. O Entrelaço com o Arauto deve ter uma boca em cada braço e dois chicotes de linha de pipa. Rai/Saber são o mesmo parceiro. Após a entrega, o autor declarou “Todos aprovados!”: os nomes e concepts atuais estão aprovados, incluindo Entreflor.

## Observado
Base marfim/rosa/carvão com olhos vermelhos, presas de sabre, sino dourado, vela sakura e rabiola de quatro pétalas. Fonte: rig e arte aprovados em `art/soulgen/keys/rai`.

## Proposta
Maturidade: {stage if stage else 'Entrelaço sem quinto estágio'}. Rota: {route}.
Anatomia: {anatomy}
História interpretativa: {story}
Verbo: {action}. Construção: {mechanism}
Limitação: {tradeoff}

## Direção e incógnitas
Traço limpo aprovado nas famílias Rabbito e Rai: contorno marinho, cor ampla e sombra simples; construção de pipa viva no equilíbrio 45/45/10. Níveis, obtenção, custos e regras não foram definidos. Não se presume origem artificial de Rai. Concept raster, não grid técnico, rig ou integração.
'''
    (folder/'brief.md').write_text(brief, encoding='utf-8')
    with Image.open(image) as im:
        manifest = dict(id=ident, tool='image_gen.imagegen', source=sources[ident],
                        sha256=hashlib.sha256(image.read_bytes()).hexdigest(), width=im.width, height=im.height,
                        mode=im.mode, alpha='A' in im.getbands(), prompt='prompt.txt',
                        references=references[ident], decision_status='approved', approval_note=node['approval_note'], production_status='concept',
                        implementation='não integrado', technical_pixel_art=False)
    if (folder/'prompt-correcao.txt').exists():
        manifest['correction'] = {'input':'tentativa-01.png', 'prompt':'prompt-correcao.txt'}
    (folder/'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    nodes.append(node)
nodes.insert(1, dict(id='rai', name='Rai / Saber', kind='stage', stage=2, route='Base · criança',
    identity='Parceiro felino branco de Tyler, duas presas, olhos vermelhos, vela sakura, sino e rabiola de quatro pétalas.',
    story='Parceiro de Tyler na Bíblia. O autor define esta forma como criança; sua origem não foi reescrita.',
    decision_status='approved', approval_note='Arte e projeto editados pelo autor em art/soulgen/keys/rai; maturidade criança explicitamente definida no pedido atual.',
    production_status='concept', implementation='base preservada',
    art='../../../art/soulgen/keys/rai/cutout-rig-v1/preview.png', brief='../evolucoes-v1/briefs/rai.md'))
nodes.append(dict(id='arauto-da-tempestade', name='Arauto da Tempestade', kind='stage', stage=4,
    route='Parceiro externo · Rabbito', external_family='rabbito',
    identity='Lebre adulta bípede creme/turquesa/dourado, arco auricular de pipa e três laços.',
    story='Forma visualmente aprovada da família Rabbito; participa do Entrelaço pedido pelo autor.',
    decision_status='approved', approval_note='Autor aprovou todos os concepts atuais da família Rabbito; neste pedido escolheu o Arauto para a fusão.',
    production_status='concept', implementation='não integrado',
    art='../../../art/creatures/rabbito-family-v1/arauto-da-tempestade/concept-v2/concept.png',
    brief='../../../art/creatures/rabbito-family-v1/arauto-da-tempestade/concept-v2/brief.md'))
edges = []
for origin, target, why in [
    ('raibroto','rai','O botão de vela abre e o filhote passa a escolher seu caminho.'),
    ('rai','raigume','Aprender quando intervir desenvolve apoio dianteiro e quilha de interceptação.'),
    ('raigume','raisoberano','Intervir amadurece em sustentar uma posição para proteger.'),
    ('rai','raivela','Perceber a pressão lateral reorganiza corpo e vela para contornar.'),
    ('raivela','raiatar','Ler o vento amadurece em coordenar tensão com outro parceiro.')]:
    edges.append({'from':origin,'to':target,'kind':'reweaving','decision_status':'proposed','reason':why})
for partner in ['raiatar','arauto-da-tempestade']:
    edges.append({'from':partner,'to':'entreflor','kind':'interweaving','decision_status':'proposed',
                  'partners':['raiatar','arauto-da-tempestade'], 'requires_all_partners':True,
                  'reason':'Duas entradas obrigatórias: Raiatar orienta a tensão e Arauto fornece impulso; cada braço conserva uma boca/linha do parceiro.'})
data = dict(family_id='rai', scope='Seis novos concepts, incluindo o Entrelaço; sem jogo, rigs ou canonização automática.',
            stage_mapping='Rai criança definido pelo autor; associação I Cafifa /II Pipa /III Arraia /IV Pandorga organiza o estudo.',
            nodes=nodes, edges=edges)
(DOC/'chart.json').write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
# Miniaturas de apresentação, não novos assets nem pintura.
thumbdir = DOC/'miniaturas'; thumbdir.mkdir(exist_ok=True)
for n in nodes:
    with Image.open(DOC/n['art']) as im:
        rgba = im.convert('RGBA'); box = rgba.getchannel('A').getbbox()
        if box: rgba = rgba.crop(box)
        white = Image.new('RGBA', rgba.size, 'white'); white.alpha_composite(rgba)
        thumb = ImageOps.contain(white.convert('RGB'), (530,530), Image.Resampling.LANCZOS)
    thumb.save(thumbdir/f"{n['id']}.png")
cards=''.join(f'<button data-id="{n["id"]}" aria-pressed="false"><img src="miniaturas/{n["id"]}.png" alt="{html.escape(n["name"])}"><strong>{html.escape(n["name"])}</strong><span>{html.escape(n["route"])}</span><small>'+('Referência existente' if n['decision_status']=='approved' else 'Novo concept · proposta')+'</small></button>' for n in nodes)
page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Rai · laços de sakura</title><style>*{box-sizing:border-box}body{margin:0;background:#211a27;color:#fff3e6;font:17px system-ui}header,main{max-width:1480px;margin:auto;padding:30px}h1{font-size:clamp(32px,5vw,64px);margin:12px 0}p{line-height:1.7;max-width:95ch}a{color:#ffbfcc}nav{display:flex;gap:26px;flex-wrap:wrap}.routes{background:#382735;padding:24px;border-left:5px solid #e8b65f;margin:24px 0}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:24px}button{font:inherit;color:#251d29;background:#fff;border:3px solid transparent;border-radius:12px;padding:16px;display:flex;flex-direction:column;text-align:left;cursor:pointer;gap:9px}button img{width:100%;aspect-ratio:1;object-fit:contain}button strong{font-size:24px}button span,button small{line-height:1.5}button:focus-visible,button[aria-pressed=true]{outline:4px solid #f4c871;outline-offset:4px}aside{padding:28px;background:#382735;margin:38px 0;border-radius:12px}dt{font-weight:750;color:#ffd486}dd{margin:8px 0 24px;line-height:1.7}.links{display:flex;gap:24px}footer{line-height:1.6;margin:32px 0}@media(max-width:850px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(max-width:490px){.grid{grid-template-columns:1fr}main,header{padding:22px}}</style><header><p>ESTUDO AUTORAL · SEIS NOVAS PROPOSTAS</p><h1>Rai · laços de sakura</h1><p>Do botão que escuta o próprio sino ao guardião que escolhe proteger ou alinhar sua força com outra. Arte base de Rai e Arauto preservada; nomes e novos designs aguardam avaliação.</p><nav><a href="CHART.md">História e decisões</a><a href="PESQUISA.md">Pesquisa dirigida</a><a href="familia.png">Comparar artes</a><a href="chart.json">Dados</a></nav></header><main><section class="routes"><p><b>Bebê → criança:</b> Raibroto → Rai<br><b>Interceptação:</b> Rai → Raigume → Raisoberano<br><b>Condução:</b> Rai → Raivela → Raiatar<br><b>Entrelaço de duas entradas:</b> Raiatar + Arauto da Tempestade → Entreflor</p><p>No Entreflor, um braço possui a boca do Arauto, outro a boca de sabre do Raiatar. Cada boca lança seu próprio chicote de linha de pipa. Corpo e apoios reorganizam os dois parceiros.</p></section><section class="grid" aria-label="Selecionar forma">CARDS</section><aside id="details" aria-live="polite"></aside><footer>Nomes, anatomias e especialidades novos são propostas. Maturidade de Rai criança definida pelo autor. Os custos, requisitos, duração e retorno do Entrelaço não foram decididos. Concepts raster; sem recortes, rigs, animações ou integração.</footer></main><script>const data=DATA;function select(id){const n=data.nodes.find(n=>n.id===id);document.querySelectorAll('[data-id]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.id===id)));const d=document.querySelector('#details');d.replaceChildren();const h=document.createElement('h2');h.textContent=n.name;d.append(h);const p=document.createElement('p');p.textContent=n.decision_status==='approved'?'Referência existente preservada':'Novo design e nome propostos · não integrado';d.append(p);const dl=document.createElement('dl');for(const [key,label]of Object.entries({identity:'Anatomia e parentesco',story:'História',action:'Verbo',mechanism:'Construção funcional',tradeoff:'Limitação proposta',user_requirement:'Exigência do autor'})){if(!n[key])continue;const dt=document.createElement('dt'),dd=document.createElement('dd');dt.textContent=label;dd.textContent=n[key];dl.append(dt,dd)}d.append(dl);const links=document.createElement('div');links.className='links';for(const [url,label]of [[n.art,'Arte original'],[n.brief,'Brief e incógnitas']]){const a=document.createElement('a');a.href=url;a.textContent=label;links.append(a)}d.append(links);location.hash=id}document.querySelectorAll('[data-id]').forEach(b=>b.addEventListener('click',()=>select(b.dataset.id)));select(data.nodes.some(n=>n.id===location.hash.slice(1))?location.hash.slice(1):'rai');</script></html>'''.replace('CARDS',cards).replace('DATA',json.dumps(data,ensure_ascii=False))
page = page.replace('ESTUDO AUTORAL · SEIS NOVAS PROPOSTAS', 'SEIS NOVOS CONCEPTS · TODOS APROVADOS')
page = page.replace('nomes e novos designs aguardam avaliação.', 'nomes e novos designs aprovados pelo autor.')
page = page.replace('Referência existente', 'Concept aprovado')
page = page.replace('Novo concept · proposta', 'Concept aprovado')
page = page.replace('Nomes, anatomias e especialidades novos são propostas.', 'Nomes e designs aprovados; especialidades e regras de jogo seguem propostas.')
page = page.replace('Referência existente preservada', 'Concept aprovado visualmente; sem certificação de rig ou integração')
(DOC/'index.html').write_text(page, encoding='utf-8')
sheet = Image.new('RGB', (1800,1280), 'white'); draw=ImageDraw.Draw(sheet)
try: font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',25)
except OSError: font=ImageFont.load_default()
for i,n in enumerate(nodes):
    x,y=(i%4)*450,(i//4)*640
    with Image.open(thumbdir/f"{n['id']}.png") as im:
        small=ImageOps.contain(im,(420,540),Image.Resampling.LANCZOS)
        sheet.paste(small,(x+(450-small.width)//2,y+(550-small.height)//2))
    draw.text((x+18,y+562),n['name'],font=font,fill='#302238')
    draw.text((x+18,y+600),n['route'],font=font,fill='#694452')
sheet.save(DOC/'familia.png')
for n in nodes:
    for field in ['art','brief']:
        if not (DOC/n[field]).is_file(): raise FileNotFoundError(n[field])
print(json.dumps({'nodes':len(nodes),'edges':len(edges),'new_concepts':6,'index':str(DOC/'index.html')}))
