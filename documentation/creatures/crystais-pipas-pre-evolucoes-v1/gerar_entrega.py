"""Registra concepts autorais e monta catálogos; não altera pixels das artes originais."""
from pathlib import Path
import json, shutil, hashlib, os, html, importlib.util
from PIL import Image, ImageOps, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
plan = json.loads((OUT/'PLANO.json').read_text(encoding='utf-8'))
production = json.loads((OUT/'producao.json').read_text(encoding='utf-8'))
families = plan['families']
def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8')
def dump(path, value):
    write(path, json.dumps(value, ensure_ascii=False, indent=2)+'\n')
def rel(path, base):
    return os.path.relpath(path, base).replace('\\','/')
stages=['Bebê · I Cafifa','Criança · II Pipa','Jovem · III Arraia','Adulto · IV Pandorga']
reviews={
 'vespim':'Rosto e corpo integrados sob cobertura; dois apoios em abas, olhos violeta e rabiola única. Poucas massas grandes.',
 'vespardo':'Correção dirigida removeu quinto membro levantado. Quatro patas no chão; cobertura sustentada pelas varetas. Corpo baixo e rosto curioso diferem do adulto.',
 'vesperante':'Quatro apoios, ombros elevados e pelve baixa, duas coberturas e proteção parcial anterior. Peito sem cristal e pernas mais leves que no adulto.',
 'nimbim':'Face integrada na pipa triangular, duas pequenas abas laterais e rabiola contínua; sem patas. Mais largo que a ideia inicial de envelope arredondado, mas simples e distinto da criança.',
 'nimbala':'Duas velas independentes e corpo arredondado suspenso, sem patas; olhos ciano e uma rabiola. Ganha articulação em relação ao bebê.',
 'nimbordo':'Duas velas recortadas, quilha longa e curva, sem patas; rosto menor e rabiola íntegra. Perfil de manobra, diferente do manto pesado adulto.',
 'ofita':'Corpo-fita curto em vírgula, sem membros, rosto gentil e rabiola ligada por nó. A cobertura cefálica ficou mais larga que no brief; mantém poucas massas.',
 'ofirisco':'Uma espira aberta com continuidade corporal, gola curta e rosto reptiliano infantil; sem patas. Uma rabiola.',
 'ofirastro':'S contínuo com espira inferior, gola maior e proteção esparsa; dois dentes visíveis, olhos verdes. Menos massa e couraça que o adulto.',
 'cantim':'Corpo-semente e painel ressonador único, duas antenas e rabiola. Quatro abas de apoio visíveis nesta perspectiva; seis foram pedidas, mas a vista não permite certificar todas as raízes. Conferir verso antes do rig.',
 'cantilha':'Correção removeu pata excedente. Quatro patas de apoio e dois braços em diapasão; duas antenas e dois painéis dorsais fechados. Uma rabiola.',
 'cantivara':'Correção removeu pata excedente. Quatro patas e dois braços com lâminas tocando, duas antenas, dois painéis abertos. Corpo esguio e proteção parcial.',
 'grifim':'Rosto-pipa integrado, bico curto, duas abas e dois pequenos pés; rabiola com terminal bilobado. Sem corpo de adulto reduzido.',
 'grifote':'Quatro membros, anteriores com garras e posteriores com patas largas. Correção removeu linha decorativa entre pata e cauda. Uma rabiola. Um broto de asa está legível; contralateral fica oculto e requer vista posterior antes de rig.',
 'grifalce':'Quatro membros, duas asas com raízes separadas dos braços, bico mais firme e guarda parcial anterior. Rabiola única, sem cristal e sem peito adulto pesado.',
 'gevim':'Corpo e rosto em bolsa de papel, duas abas auriculares, dois apoios pequenos e rabiola. Expressão curiosa, sem máscara craniana adulta.',
 'gevisco':'Quatro patas, cabeça farejando, olhos rosa-gelo, três lâminas de juba e estrutura dorsal leve. Sem armadura pesada ou cristal.',
 'gevardente':'Quatro patas compridas, ombros altos, focinho alongado, crista ampla de papel e grevas parciais. Flancos limpos sem fibras retorcidas; rabiola contínua.',
 'makim':'Dois remos pequenos, cabeça/corpo integrados, cauda-leque e uma rabiola distinta da cauda. Sem chifres nem armadura; desenho compacto.',
 'makarim':'Dois membros anteriores, nenhum posterior; cauda-leque, dois chifres incipientes, brânquias e rabiola. Tromba ficou mais longa que o brief, mas a face e a massa ainda são infantis.',
 'makaronda':'Dois membros anteriores, corpo nadador contínuo, dois chifres parciais, duas guardas de ombro e uma rabiola distinta da cauda. Menos couraça, espessura e massa craniana que o adulto.'
}
for row in production['forms']:
    f=next(f for f in families if f['id']==row['family'])
    target=ROOT/'art/creatures'/f['id']/row['id']/'concept-v1'
    target.mkdir(parents=True, exist_ok=True)
    shutil.copy2(row['source'],target/'concept.png')
    if row['intermediate']:
        shutil.copy2(row['intermediate'],target/'tentativa-anterior.png')
    write(target/'prompt.txt',row['prompt']+'\n')
    if row['correction']: write(target/'prompt-correcao.txt',row['correction']+'\n')
    observed=reviews[row['id']]
    brief=f"# {row['name']} — {stages[row['stage']-1]}\n\n2026-11-07 · Família {f['name']}.\n\n## Definido pelo autor\n\nCriar todas as pré-evoluções sem pausas de aprovação, no equilíbrio 45% criatura /45% pipa /10% contorno e 2D mangá. Manter papel vivo sob proteções, sem pele retorcida. Isso autoriza produção e revisão autônoma, não constitui aprovação visual antecipada.\n\n## Observado na base\n\nBase de identidade: [adulto atual]({rel(ROOT/'art/creatures'/f['id']/f'concept-v{f["v"]}'/'concept.png',target)}). Sua anatomia, paleta, rabiola e cor de olhos orientam o parentesco.\n\n## Proposta de forma\n\n{f['forms'][row['stage']-1][2]}\n\n## História e função propostas\n\n{f['story']} A forma {row['stage']} representa {'começar a perceber o mundo com construção simples' if row['stage']==1 else 'explorar com apoios e órgãos próprios' if row['stage']==2 else 'especializar o movimento com proteção parcial'}. Sua limitação proposta é {'pouca autonomia e alcance' if row['stage']==1 else 'pouca resistência e controle' if row['stage']==2 else 'menor sustentação e proteção que o adulto'}.\n\n## Desconhecido\n\nNome definitivo, habitat, obtenção, níveis, condições de remonta, balanceamento e momento de aquisição do cristal. Cristal apenas no adulto é proposta; não há fragmento de alma adicional.\n"
    write(target/'brief.md',brief)
    write(target/'revisao.md',f"# Conferência — {row['name']}\n\n{observed}\n\nConcept aberto e conferido individualmente. Comparação entre estágios na prancha familiar. Superfícies amplas e sombras em blocos, sem alegação de pixel art técnico. A imagem não comprova consistência de verso, recortes ou animação.\n\nDecisão visual: proposta para avaliação do autor. Produção: concept. Implementação: não integrado. Método: image_gen integrado; apenas referência autoral da família, nenhuma imagem externa como input. Original e eventual tentativa anterior preservados.\n")
    with Image.open(target/'concept.png') as im:
        alpha=im.getextrema()[-1] if im.mode=='RGBA' else None
        meta=dict(width=im.width,height=im.height,mode=im.mode,alpha_extrema=alpha)
    dump(target/'manifest.json',dict(id=row['id'],family_id=f['id'],stage=row['stage'],name=row['name'],date='2026-11-07',decision_status='proposed',production_status='concept',implementation_status='not_integrated',tool='image_gen.imagegen (integrado)',source=row['source'],reference=rel(ROOT/'art/creatures'/f['id']/f'concept-v{f["v"]}'/'concept.png',target),sha256=hashlib.sha256((target/'concept.png').read_bytes()).hexdigest(),**meta,prompt='prompt.txt',correction='prompt-correcao.txt' if row['correction'] else None,review=observed))

allcharts=[]
for f in families:
    directory=ROOT/'documentation/creatures'/f'{f["id"]}-chart-v1'
    if (directory/'chart.json').exists():
        existing=json.loads((directory/'chart.json').read_text(encoding='utf-8'))
        if existing.get('scope')!='Concept e documentação; relações, nomes novos e condições propostas; sem integração.':
            raise RuntimeError('Chart externo à entrega, preservar: '+str(directory))
    directory.mkdir(parents=True,exist_ok=True)
    nodes=[]
    for n,s in enumerate(f['forms'],1):
        art=ROOT/'art/creatures'/f['id']/s[0]/'concept-v1'
        nodes.append(dict(id=s[0],name=s[1],kind='stage',stage=n,maturity=stages[n-1],identity=reviews[s[0]],story=f['story'],action=['perceber','explorar','especializar'][n-1],tradeoff=['Pouca autonomia e alcance.','Pouca resistência e controle.','Menor sustentação e proteção que o adulto.'][n-1],decision_status='proposed',production_status='concept',art=rel(art/'concept.png',directory),brief=rel(art/'brief.md',directory)))
    adult=ROOT/'art/creatures'/f['id']/f'concept-v{f["v"]}'
    node=dict(id=f['id'],name=f['name'],kind='stage',stage=4,maturity=stages[3],identity='Identidade da arte adulta atual preservada; cristal central, papel vivo e rabiola da própria família.',story=f['story'],decision_status='approved' if f['id']=='grifarca' else 'proposed',production_status='concept',art=rel(adult/'concept.png',directory),brief=rel(adult/'brief.md',directory))
    if f['id']=='grifarca': node['approval_note']='Autor: “Aprovado, agora faça isso com todos os outros que você criou também”. Aprovação visual apenas do adulto v2, não das novas pré-evoluções.'
    nodes.append(node)
    edges=[]
    reasons=[f'A construção simples de {nodes[0]["name"]} ganha corpo e órgãos de exploração em {nodes[1]["name"]}.',f'A exploração de {nodes[1]["name"]} exige movimento mais especializado e proteção parcial em {nodes[2]["name"]}.',f'{nodes[2]["name"]} desenvolve sustentação e controle para a arquitetura adulta de {f["name"]}; aquisição do cristal e condições continuam propostas.']
    for i in range(3): edges.append(dict(**{'from':nodes[i]['id'],'to':nodes[i+1]['id']},kind='reweaving',reason=reasons[i],decision_status='proposed'))
    chart=dict(family_id=f['id'],scope='Concept e documentação; relações, nomes novos e condições propostas; sem integração.',nodes=nodes,edges=edges,crystal_note=plan['crystal'])
    dump(directory/'chart.json',chart)
    write(directory/'CHART.md',f'# Família {f["name"]}\n\n{f["story"]}\n\n'+ ' → '.join(n['name'] for n in nodes)+'\n\n'+ '\n\n'.join(e['reason'] for e in edges)+'\n\n'+plan['crystal']+'\n\nNovas artes e nomes propostos. Autorização de loop não equivale a aprovação final. Sem níveis, obtenção ou código de jogo alterados.\n')
    sources=dict(local_base=rel(adult/'concept.png',directory),internal_benchmarks=['../benchmark-design-evolutivo-v1/ANALISE.md','../../../art/benchmarks/loogamon-line-2026-11-06/ANALISE.md'],external_note='Aprendizado de função e mudança de arquitetura reaproveitado dos estudos locais; imagens externas não anexadas à geração.',consulted=[dict(url='https://sg.portal-pokemon.com/pokedex/0736/',title='Grubbin — Pokédex oficial',entity='The Pokémon Company',accessed='2026-11-07',observed='Página identifica categoria larva, hábito subterrâneo e apresenta Grubbin/Charjabug/Vikavolt na seção Evolution.',interpretation='Uma função inicial concreta pode guiar diferenças posteriores de órgãos; aplicação direta apenas na concepção insetoide, sem copiar a anatomia nem alegar estudo visual completo da linha.')])
    dump(directory/'fontes.json',sources)
    decision=ROOT/'art/creatures'/f['id']/'DECISOES.md'
    old=decision.read_text(encoding='utf-8') if decision.exists() else ''
    write(decision,old+f'\n\n## 2026-11-07 — pré-evoluções em loop autorizado\n\nAutor: “crie as pré-evolução para todos, não precisa parar até que estejam todos prontos eu aprovo seu loop”. Criadas {", ".join(n["name"] for n in nodes[:3])}; nomes e concepts propostos. Adulto preservado. Chart documental em documentation/creatures/{f["id"]}-chart-v1/. Autorização não é aprovação visual antecipada.\n')
    allcharts.append((f['name'],directory,chart))

tranc=ROOT/'documentation/creatures/trancoura-chart-v1'
allcharts.append(('Trancoura',tranc,json.loads((tranc/'chart.json').read_text(encoding='utf-8'))))
fontfile=Path('C:/Windows/Fonts/arial.ttf')
font=lambda n: ImageFont.truetype(str(fontfile),n)
def sheet(name,directory,chart):
    canvas=Image.new('RGB',(2400,740),'#f3efe6');draw=ImageDraw.Draw(canvas)
    draw.text((35,20),name,fill='#16373a',font=font(40))
    draw.text((35,75),'Papel vivo · maturidade e função · conceitos de família',fill='#486066',font=font(23))
    for i,node in enumerate(chart['nodes']):
        art=(directory/node['art']).resolve()
        with Image.open(art) as source:
            im=ImageOps.contain(source.convert('RGB'),(560,460),Image.Resampling.LANCZOS)
        x=20+i*595;y=140
        draw.rounded_rectangle((x,y,x+575,y+570),radius=15,fill='white')
        canvas.paste(im,(x+(575-im.width)//2,y+(460-im.height)//2))
        draw.text((x+18,y+470),node['name'],fill='#16373a',font=font(29))
        draw.text((x+18,y+512),stages[i],fill='#486066',font=font(23))
        if i<3: draw.text((x+552,y+505),'›',fill='#9e6842',font=font(33))
    output=OUT/f'{chart["family_id"]}-familia.png';canvas.save(output)
    cards=[]
    for node in chart['nodes']:
        src=rel((directory/node['art']).resolve(),OUT)
        brief=rel((directory/node['brief']).resolve(),OUT)
        cards.append(f'<article><a href="{src}"><img src="{src}" alt="{html.escape(node["name"])} — {stages[node["stage"]-1]}"></a><h3>{html.escape(node["name"])}</h3><p>{stages[node["stage"]-1]}</p><p>{html.escape(node["identity"])}</p><p>Estado: {node["decision_status"]}</p><a href="{brief}">Brief</a></article>')
    return f'<section id="{chart["family_id"]}"><h2>{name}</h2><a href="{output.name}"><img class="family" src="{output.name}" alt="Linha completa de {name}"></a><div class="cards">'+''.join(cards)+f'</div><p><a href="{rel(directory/"chart.json",OUT)}">Chart JSON</a> · <a href="{rel(directory/"CHART.md",OUT)}">História da família</a></p></section>'
sections=[sheet(*data) for data in allcharts]
write(OUT/'index.html','''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Pré-evoluções · Soulmonsters</title><style>*{box-sizing:border-box}body{margin:0;background:#102a30;color:#f6f0e1;font:18px/1.55 system-ui,sans-serif}main{max-width:1500px;margin:auto;padding:40px 28px}a{color:#9de4d7}a:focus-visible{outline:3px solid #ffc96c;outline-offset:5px}nav{display:flex;gap:20px;flex-wrap:wrap;margin:30px 0}h1{font-size:clamp(32px,5vw,60px);line-height:1.1}.family{width:100%;height:auto;border-radius:12px}.cards{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:18px;margin:24px 0}article{background:#f4f0e7;color:#18353a;border-radius:12px;padding:18px}article img{width:100%;height:210px;object-fit:contain;background:white}article a{color:#126158}section{padding-top:26px;margin-bottom:70px}p{max-width:100ch}@media(max-width:900px){.cards{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(max-width:500px){.cards{grid-template-columns:1fr}main{padding:24px 16px}}</style><main><h1>Antes do cristal, uma história de crescimento.</h1><p>Oito famílias completas: 21 novas artes e três pré-evoluções aprovadas do Trancoura preservadas. Adultos anteriores mantidos. Cada nome novo, relação e condição de remonta é proposta; nenhuma integração de gameplay.</p><p>Direção: 45% criatura, 45% pipa viva, 10% contorno e 2D mangá. Proposta visual: cristal ancestral apenas no adulto. A rabiola permanece única; não se inventou alma extra.</p><nav>'''+''.join(f'<a href="#{c[2]["family_id"]}">{c[0]}</a>' for c in allcharts)+'</nav>'+''.join(sections)+'<p>Produção com image_gen integrado. Prompts, revisões e metadados ficam junto de cada arte. Fundo branco de concept; recortes, rig, vistas e animação não estão certificados. <a href="producao.json">Registro de produção</a> · <a href="REVISAO.md">Conferência</a></p></main></html>')
overview=Image.new('RGB',(2400,740*len(allcharts)),'#f3efe6')
for i,(_,_,c) in enumerate(allcharts):
    with Image.open(OUT/f'{c["family_id"]}-familia.png') as im: overview.paste(im,(0,i*740))
overview.save(OUT/'todas-familias.png')
overview.crop((0,0,2400,2960)).save(OUT/'familias-parte-1.png')
overview.crop((0,2960,2400,5920)).save(OUT/'familias-parte-2.png')
write(OUT/'REVISAO.md','# Revisão do lote · 2026-11-07\n\n21 novas artes em chamadas individuais com ferramenta image_gen integrada; somente adulto autoral como referência. Quatro correções dirigidas: membro extra em Vespardo; patas extras em Cantilha e Cantivara; linha decorativa excedente em Grifote. Tentativas anteriores preservadas. Trancoura: três concepts anteriores aprovados preservados, sem reabertura de identidade ou redesign silencioso.\n\n## Limites observados\n\nCantim: seis apoios foram pedidos, quatro estão visíveis; conferir contagem/raízes em verso antes de produção. Grifote: asa contralateral oculta nesta pose, conferir em vista posterior. Ofita ganhou cobertura cefálica mais larga; Makarim ganhou tromba mais longa que o brief. Permanecem como propostas de concept; não afirmar fidelidade exata ao prompt. Arte de fundo branco, sem alpha útil certificado, sem grid de pixel art sustentável, rig, recortes ou animações.\n\nCada arte foi aberta e comparada com seu adulto. Charts verificados estruturalmente e links locais conferidos; isso não valida uma interface em navegador nem implementa remonta no jogo. As pré-evoluções antigas do Trancoura conservam seu acabamento histórico; nova revisão de material não foi aplicada silenciosamente às artes aprovadas.\n')
dump(OUT/'catalogo.json',{'date':'2026-11-07','new_art_count':21,'preserved_pre_evolutions':3,'families':[dict(id=c['family_id'],name=name,chart=rel(d/'chart.json',OUT),sheet=f'{c["family_id"]}-familia.png') for name,d,c in allcharts]})
spec=importlib.util.spec_from_file_location('chartvalidator',ROOT/'.agents/skills/soulmonsters-charts/scripts/validar_chart.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
errors=[]
for name,directory,chart in allcharts: errors.extend(f'{name}: {e}' for e in module.validate(chart,directory))
dump(OUT/'validacao.json',{'family_count':8,'node_count':32,'edge_count':24,'errors':errors})
assert not errors, errors
print('21 artes novas, 8 famílias/32 formas, 24 ligações, charts válidos.')
