"""Registra três concepts de lendas e sua pesquisa, preservando portadores anteriores."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
import json,hashlib,shutil,html

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[2]
DATA=json.loads((HERE/'lendas-producao.json').read_text(encoding='utf-8'))


def run():
    members=[];sources=[]
    for d in DATA['creatures']:
        p=REPO/'art/creatures'/d['id']/'concept-v1';p.mkdir(parents=True,exist_ok=True)
        shutil.copy2(d['source'],p/'concept.png')
        (p/'prompt.txt').write_text(d['prompt']+'\n',encoding='utf-8')
        (p/'brief.md').write_text(f'''# {d['name']} — {d['legend']}

2026-11-06. Nome, design e maturidade adulta/IV Pandorga propostos. Pedido do autor: pesquisar três criaturas lendárias e integrar Crystal Pipa ao design/armadura. Grifo e Gévaudan foram citados pelo autor; makara foi selecionado para contrastar arquitetura aquática.

## Fonte e fato

[{d['source_title']}]({d['source_url']}), {d['source_owner']}, consultado em 2026-11-06.

{d['fact']}

## Interpretação autoral

{d['interpretation']}

Verbo proposto: {d['action']}. Olhos: {d['eyes']}. Um Crystal Pipa lilás com núcleo-nó menta, três apoios e montagem na frente da armadura segue o eixo anatômico. Uma rabiola porta a almática; cristal sem alma adicional é proposta de compatibilidade.

## Método e escopo

Fontes históricas/museológicas foram consultadas para informação; nenhuma imagem externa foi anexada à geração. Referências visuais anexadas: folha autoral do Crystal Pipa e Vesperálito concept-v2 autoral para acabamento. A armadura, paleta, rabiola, funções e vínculo com grupo são criações de Soulmonsters, não atributos documentados das lendas.

Uma geração pela ferramenta integrada image_gen.imagegen, uma pose inteira, fundo branco. Sem rig, recortes, animação ou integração. {d['unknown']}
''',encoding='utf-8')
        (p/'revisao.md').write_text(f'''# Revisão — {d['name']}

PNG aberto e inspecionado após geração. {d['review']}

Sombras em blocos, contorno escuro e planos materiais mantêm 2D mangá. Algumas margens são estreitas, mas não houve corte observado. Facetas e montagem do cristal têm interpretação de perspectiva, não cópia técnica exata da folha. {d['unknown']}

Concept selecionado na revisão interna; aprovação do autor pendente. Fundo branco não é alpha de recorte. Ilustração de alta resolução não certifica pixel art em grade. Não integrado.
''',encoding='utf-8')
        with Image.open(p/'concept.png') as im:dims=list(im.size);mode=im.mode
        m=dict(id=d['id'],group_proposed='portadores dos Crystais Pipas',legend_inspiration=d['legend'],date=DATA['date'],tool='built-in image_gen.imagegen',source=d['source'],dimensions=dims,mode=mode,background='white',sha256=hashlib.sha256((p/'concept.png').read_bytes()).hexdigest(),references=[{'path':'../../../artifacts/crystais-pipas/concept-v1/concept.png','role':'own artifact identity'},{'path':'../../vesperalito/concept-v2/concept.png','role':'own rendering and armor density'}],external_images_attached=False,prompt='prompt.txt',brief='brief.md',review='revisao.md',decision_status='proposed',production_status='concept',implementation_status='not_integrated')
        (p/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        members.append(dict(id=d['id'],name=d['name'],legend=d['legend'],action=d['action'],eyes=d['eyes'],decision_status='proposed',production_status='concept',implementation_status='not_integrated',art=f'../../../art/creatures/{d["id"]}/concept-v1/concept.png',brief=f'../../../art/creatures/{d["id"]}/concept-v1/brief.md'))
        sources.append(dict(id=d['id'],url=d['source_url'],title=d['source_title'],responsible=d['source_owner'],consulted=DATA['date'],fact=d['fact'],interpretation=d['interpretation'],use='Conhecimento e direção; imagem externa não anexada à geração.'))
    (HERE/'lendas-fontes.json').write_text(json.dumps(sources,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    # Atualiza índice sem remover os portadores prévios nem presumir suas aprovações.
    index=json.loads((HERE/'portadores.json').read_text(encoding='utf-8'))
    index['members']=[m for m in index['members'] if m['id'] not in {x['id'] for x in members}]+members
    index['scope']='Grupo aberto, sete concepts propostos; sem quantidade final ou hierarquia definida.'
    (HERE/'portadores.json').write_text(json.dumps(index,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

    board=Image.new('RGB',(2700,850),'#f2eee5');draw=ImageDraw.Draw(board);font='C:/Windows/Fonts/arial.ttf'
    title=ImageFont.truetype(font,48);name=ImageFont.truetype(font,33);small=ImageFont.truetype(font,24)
    draw.text((45,28),'CRYSTAIS PIPAS  /  TRÊS LENDAS REIMAGINADAS',font=title,fill='#162f32')
    draw.text((45,98),'Concepts autorais propostos · referências históricas separadas da criação',font=small,fill='#59696a')
    for i,d in enumerate(DATA['creatures']):
        x=30+i*890;y=160
        draw.rounded_rectangle((x,y,x+860,y+640),radius=8,fill='white')
        im=Image.open(REPO/'art/creatures'/d['id']/'concept-v1/concept.png').convert('RGB')
        thumb=ImageOps.contain(im,(820,545),Image.Resampling.LANCZOS)
        board.paste(thumb,(x+20+(820-thumb.width)//2,y+15+(545-thumb.height)//2))
        draw.text((x+26,y+568),d['name'],font=name,fill='#162f32')
        draw.text((x+26,y+610),'Inspiração: '+d['legend'],font=small,fill='#59696a')
    board.save(HERE/'portadores-lendas.png')
    cards=''.join(f'''<article><a href="{m['art']}"><img src="{m['art']}" alt="{m['name']}, Soulmonster inspirado em {m['legend']}"></a><div><h2>{m['name']}</h2><p>Inspiração: {m['legend']}. Olhos {m['eyes']}.</p><p>{d['interpretation']}</p><p><a href="{m['brief']}">Brief e distinção entre fato e proposta</a> · <a href="{d['source_url']}">Fonte institucional ↗</a></p></div></article>''' for m,d in zip(members,DATA['creatures']))
    page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Crystais Pipas · lendas</title><style>*{box-sizing:border-box}body{margin:0;background:#f2eee5;color:#162f32;font:18px/1.65 system-ui,sans-serif}main{max-width:1500px;margin:auto;padding:35px}h1{font-size:clamp(34px,6vw,60px);line-height:1.1}.all{width:100%;height:auto}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(330px,1fr));gap:25px;margin:30px 0}article{background:white;border:1px solid #d6d0c5}article img{width:100%;height:340px;object-fit:contain}article div{padding:24px}h2{margin:0}a{color:#634185}a:focus-visible{outline:3px solid #9670b4;outline-offset:4px}@media(max-width:500px){main{padding:18px}.grid{grid-template-columns:1fr}}</style><main><h1>Três lendas reimaginadas.</h1><p>Grifo, Besta de Gévaudan e makara adaptados ao corpo, à armadura e ao Crystal Pipa. Designs, nomes e capacidades propostos; fontes não tornam nossas invenções fatos sobre as tradições.</p><a href="portadores-lendas.png"><img class="all" src="portadores-lendas.png" alt="Prancha conjunta de Grifarca, Gevoraz e Makaréu"></a><div class="grid">__CARDS__</div><p><a href="LENDAS.md">Pesquisa e revisão</a> · <a href="lendas-fontes.json">Fontes estruturadas</a> · <a href="index.html">Outros portadores</a></p><p>Sem imagens externas anexadas à geração. Produção integrada image_gen.imagegen; prompts e originais individuais preservados. Concepts sem rig ou integração.</p></main></html>'''
    (HERE/'lendas.html').write_text(page.replace('__CARDS__',cards),encoding='utf-8')
    f=HERE/'index.html';text=f.read_text(encoding='utf-8')
    text=text.replace('Quatro portadores propostos, sem fixar o tamanho final do grupo.','Sete portadores propostos, sem fixar o tamanho final do grupo.')
    if '<!-- lendas -->' not in text:
        text=text.replace('<div class="grid">','<!-- lendas --><p><a href="lendas.html">Ver os três portadores inspirados em lendas: Grifarca, Gevoraz e Makaréu</a></p><div class="grid">',1)
    f.write_text(text,encoding='utf-8')
    print('Três concepts e fontes registrados; índice preservado e ampliado; prancha montada.')


if __name__=='__main__':run()
