from pathlib import Path
import json, shutil, hashlib, os, html, importlib.util
from PIL import Image, ImageOps, ImageDraw, ImageFont

D=Path(__file__).resolve().parent
R=D.parents[2]
data=json.loads((D/'producao.json').read_text(encoding='utf-8'))
def write(p,t):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(t,encoding='utf-8')
def dump(p,v): write(p,json.dumps(v,ensure_ascii=False,indent=2)+'\n')
def rel(p,b): return os.path.relpath(p,b).replace('\\','/')
stages=['Bebê','Criança','Jovem','Adulto']
notes={
'marulhim':'Cabeça e corpo fundidos num losango; duas abas laterais pequenas e rabiola de leque. Silhueta simples sem os guias cefálicos adultos.',
'raivela':'Corpo arredondado separado das duas velas; pequenos brotos cefálicos ainda retos, expressão curiosa e apoios leves.',
'alvorvela':'Corpo central estreito, velas alongadas, guias parcialmente enrolados e pequenas proteções nas pontas. Postura de manobra, sem o volume adulto.',
'bolhim':'Corpo-bolha simples, duas nadadeiras pequenas, cauda com dois lobos e pequena aba dorsal enrolada; olhos menta gentis.',
'corolho':'Corpo curto, duas nadadeiras e cauda horizontal. Aba dorsal aberta apoiada por vareta: ainda não é a câmara espiral fechada.',
'coromar':'Corpo comprido e leve, nadadeiras alongadas e câmara dorsal aberta em C. Adulto continua mais profundo e compacto.',
'vortim':'Correção dirigida acrescentou dois braços posteriores: oito pontas legíveis, manto fundido ao corpo e rabiola única no alto.',
'vortelo':'Oito braços distintos; quatro amplos à frente e quatro elevados atrás. Dois pequenos vincos de crista, sifão lateral e primeiros discos-nó.',
'vortespira':'Oito braços de alcances diferentes; dois recebem braceletes leves, seis ficam livres. Manto estreito, dois grandes planos superiores e sifão frontal.',
'recim':'Uma placa de abrigo, dois brotos de pinça e dois apoios curtos. Pedúnculos rosa e rabiola escalonada. Pernas completas se desenvolvem na criança.',
'recipinca':'Uma placa, duas pinças pequenas e uma vane dorsal. Quatro pés visíveis; os dois posteriores do lado distante não estão certificados nesta vista. Exigir vista adicional antes de rig; não duplicar pés para compensar oclusão.',
'reciforte':'Seis pés visíveis e dois braços de pinça separados. Duas placas, duas vanes e pernas longas; pinça-escudo menor que a do adulto.'
}
font=lambda n:ImageFont.truetype('C:/Windows/Fonts/arial.ttf',n)
panels=[];sections=[];report=[]
spec=importlib.util.spec_from_file_location('chart_validator',R/'.agents/skills/soulmonsters-charts/scripts/validar_chart.py')
validator=importlib.util.module_from_spec(spec);spec.loader.exec_module(validator)
for f in data['families']:
    chartdir=R/'documentation/creatures'/f'{f["id"]}-chart-v1'
    path=chartdir/'chart.json'
    chart=json.loads(path.read_text(encoding='utf-8-sig'))
    if not (chartdir/'chart-before-pre-evolucoes.json').exists(): shutil.copy2(path,chartdir/'chart-before-pre-evolucoes.json')
    adult=next(n for n in chart['nodes'] if n['id']==f['id'])
    nodes=[]
    for j,form in enumerate(f['forms']):
        ident,name,design=form
        row=next(v for v in data['rows'] if v['form'][0]==ident)
        p=R/'art/creatures'/f['id']/ident/'concept-v1'
        p.mkdir(parents=True,exist_ok=True)
        shutil.copy2(row['source'],p/'concept.png')
        write(p/'prompt.txt',row['prompt']+'\n')
        if row['correction']:write(p/'prompt-correcao.txt',row['correction']+'\n')
        brief=f'# {name} — {stages[j]} da família {f["name"]}\n\n## Escopo\n\nPré-evolução solicitada pelo autor. Nome individual, relação e capacidades são propostas. Adulto preservado. Concept, sem integração no jogo.\n\n## História de amadurecimento\n\n{f["story"]}\n\n## Construção proposta\n\n{design}\n\n## Direção\n\n45% criatura viva, 45% construção funcional de pipa, 10% contorno seletivo e 2D mangá. Uma rabiola completa, sem cristal ancestral automático. Cores chapadas, poucos planos e sombras cel; não uma miniatura do adulto.\n\n## Conferência visual\n\n{notes[ident]}\n\n[Adulto de referência]({rel(R/"art/creatures"/f["id"]/"concept-v1/concept.png",p)}). [Lore do grupo]({rel(R/"documentation/creatures/quatro-mares-v1/LORE.md",p)}).\n'
        write(p/'brief.md',brief)
        write(p/'revisao.md',f'# Revisão — {name}\n\n{notes[ident]}\n\nImagem inspecionada individualmente e reunida à família para comparar maturidade, silhueta e construção. Apenas arte autoral como input. A vista não certifica anatomia oculta, escala de gameplay, recorte, rig ou animações. Contorno ilustrado não equivale a pixel art técnica em grade. Fundo branco preservado. Novos nomes e concepts propostos, aguardando avaliação do autor.\n')
        with Image.open(p/'concept.png') as im:meta={'width':im.width,'height':im.height,'mode':im.mode}
        digest=hashlib.sha256((p/'concept.png').read_bytes()).hexdigest()
        dump(p/'manifest.json',dict(id=ident,name=name,family_id=f['id'],group='Quatro Marés',stage=j+1,date='2026-11-07',decision_status='proposed',production_status='concept',implementation_status='not_integrated',source=row['source'],reference=rel(R/'art/creatures'/f['id']/'concept-v1/concept.png',p),sha256=digest,prompt='prompt.txt',correction='prompt-correcao.txt' if row['correction'] else None,**meta))
        nodes.append(dict(id=ident,name=name,kind='stage',stage=j+1,maturity=stages[j],identity=notes[ident],story=f['story'],decision_status='proposed',production_status='concept',art=rel(p/'concept.png',chartdir),brief=rel(p/'brief.md',chartdir)))
    nodes.append(adult)
    chart.update(scope='Linha documental bebê → criança → jovem → adulto. Pré-evoluções e vínculos propostos; adulto anterior preservado.',nodes=nodes,edges=[{'from':nodes[k]['id'],'to':nodes[k+1]['id'],'kind':'reweaving','reason':f['story'],'decision_status':'proposed'} for k in range(3)])
    dump(path,chart)
    errors=validator.validate(chart,chartdir)
    report.append(dict(family=f['id'],nodes=len(nodes),edges=len(chart['edges']),errors=errors))
    assert not errors,errors
    write(chartdir/'CHART.md',f'# {f["name"]} — Quatro Marés\n\n'+ ' → '.join(n['name'] for n in nodes)+'\n\n'+f['story']+'\n\n'+ '\n'.join(f'- {stages[i]}: [{n["name"]}]({n["art"]}) · [brief]({n["brief"]}).' for i,n in enumerate(nodes))+'\n\nNovos nomes, estágios e vínculos são propostas documentais, sem condições de obtenção, níveis ou integração definidos. [Prancha comparativa](../quatro-mares-pre-evolucoes-v1/index.html).\n')
    board=Image.new('RGB',(2400,760),'#f2eee6');dr=ImageDraw.Draw(board)
    dr.text((28,16),f['name'].upper(),font=font(37),fill='#143d43')
    cards=[]
    for j,n in enumerate(nodes):
        p=(chartdir/n['art']).resolve()
        x=15+j*600
        dr.rectangle((x,80,x+570,645),fill='white')
        with Image.open(p) as im: thumb=ImageOps.contain(im.convert('RGB'),(550,545),Image.Resampling.LANCZOS)
        board.paste(thumb,(x+(570-thumb.width)//2,85+(545-thumb.height)//2))
        dr.text((x+15,658),n['name'],font=font(31),fill='#143d43')
        dr.text((x+15,705),stages[j],font=font(24),fill='#587077')
        cards.append(f'<article><a href="{rel(p,D)}"><img src="{rel(p,D)}" alt="{html.escape(n["name"])}"></a><h3>{html.escape(n["name"])}</h3><p>{stages[j]}</p><a href="{rel((chartdir/n["brief"]).resolve(),D)}">Brief</a></article>')
    board.save(D/f'{f["id"]}-linha.png');panels.append(board)
    sections.append(f'<section><h2>{f["name"]}</h2><p>{f["story"]}</p><div class="cards">'+''.join(cards)+f'</div><p><a href="../{f["id"]}-chart-v1/CHART.md">Chart e relações</a></p></section>')
overview=Image.new('RGB',(2400,760*4),'white')
for i,p in enumerate(panels):overview.paste(p,(0,i*760))
overview.save(D/'quatro-mares-linhas.png')
css='*{box-sizing:border-box}body{margin:0;background:#0c2834;color:#f2efdf;font:18px/1.6 system-ui}main{max-width:1600px;margin:auto;padding:35px 24px}a{color:#9ae4de}a:focus-visible{outline:3px solid #ffd57c;outline-offset:5px}.cards{display:grid;grid-template-columns:repeat(4,1fr);gap:16px}article{background:#f2eee6;color:#143d43;padding:16px;border-radius:12px}article a{color:#116b76}article img{width:100%;height:280px;object-fit:contain;background:white}section{margin:50px 0}.overview{max-width:100%;height:auto}@media(max-width:850px){.cards{grid-template-columns:repeat(2,1fr)}}@media(max-width:480px){.cards{grid-template-columns:1fr}}'
write(D/'index.html','<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Quatro Marés — linhas completas</title><style>'+css+'</style><main><h1>Quatro Marés · pré-evoluções</h1><p>12 concepts novos: bebê, criança e jovem para cada um dos quatro adultos. Arte autoral 2D mangá, com corpo e construção de pipa amadurecendo juntos.</p><p>Novos nomes e vínculos são propostas. Artes de conceito; sem rig ou integração. A prancha compara desenho, não escala no jogo.</p><p><a href="../quatro-mares-v1/LORE.md">Lore do grupo</a> · <a href="REVISAO.md">Conferência e limites</a> · <a href="quatro-mares-linhas.png">Prancha completa</a></p>'+''.join(sections)+'</main></html>')
write(D/'REVISAO.md','# Conferência das quatro linhas\n\n12 imagens novas abertas individualmente; quatro adultos preservados. Vortim recebeu correção para oito braços legíveis. Vortelo e Vortespira mostram oito pontas distintas da rabiola. Reciforte mostra seis pés e dois braços de pinça. Recipinça tem quatro pés visíveis e oclusão dos posteriores: a vista não certifica os dois ocultos; pedir verso antes de rig.\n\nNomes individuais e conexões são propostas. Não foram definidos níveis, itens, encontros ou integração. Fundo branco e contorno ilustrado; não são sprites recortados nem pixel art em grade sustentável.\n\nA validação estrutural verifica quatro charts, 16 nós e 12 conexões, arquivos e hashes; não certifica qualidade visual ou mecânicas.\n')
dump(D/'validacao.json',dict(charts=report,new_concepts=12,preserved_adults=4,structural_ok=all(not c['errors'] for c in report)))
group=R/'documentation/creatures/quatro-mares-v1/index.html'
txt=group.read_text(encoding='utf-8')
link='<p><a href="../quatro-mares-pre-evolucoes-v1/index.html">Ver as quatro linhas com bebê, criança, jovem e adulto</a></p>'
if link not in txt:write(group,txt.replace('</main>',link+'</main>'))
print('12 concepts registrados; 4 charts válidos, 16 nós e 12 conexões; galeria e pranchas prontas.')
