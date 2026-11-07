"""Preserva o adulto aprovado, registra três concepts e monta o chart documental."""
from pathlib import Path
import json, hashlib, shutil, html
from PIL import Image,ImageDraw,ImageFont,ImageOps

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[2]
DATA=json.loads((HERE/'producao.json').read_text(encoding='utf-8'))
APPROVAL='Autor: "Gostei mas acho que os próximos podem ser mais criativos e caracteristicos, esse aprovado, crie a evolution line dele esse é adulto precisa dos inferiores". Escopo: arte adulta concept-v2 e posição de adulto; nomes, regras e formas inferiores não aprovados automaticamente.'


def run():
    nodes=[]
    for d in DATA['creatures']:
        p=REPO/'art/creatures/ressonhiena'/d['id']/'concept-v1'
        p.mkdir(parents=True,exist_ok=True)
        shutil.copy2(d['source'],p/'concept.png')
        (p/'prompt.txt').write_text(d['prompt']+'\n',encoding='utf-8')
        (p/'brief.md').write_text(f'''# {d['name']} — {d['maturity']}

Nome e design propostos, 2026-11-06. Forma inferior do adulto Ressonhiena concept-v2 aprovado pelo autor. A aprovação do adulto não aprova esta nova forma.

## História e função propostas

{d['story']}

Identidade: {d['identity']}

Verbo: {d['action']}. Limitação proposta: {d['tradeoff']}

## Continuidade

Conservar ameixa, preto, ocre, creme e acento verde-água, focinho e orelhas de hiena, riso e membrana de saco almático com cordão. Material do corpo cresce de invólucro flexível para proteção; não acrescentar lixo literal ou vários instrumentos. Uma rabiola específica porta uma almática; múltiplos terminais não significam múltiplas almas.

## Produção

Geração pela ferramenta integrada image_gen.imagegen. Única referência anexada: arte autoral adulta `../../concept-v2/concept.png`. Não foram anexadas imagens externas. Estilo 45% criatura, 45% pipa viva, 10% pixel/2D mangá; contorno e sombra limpos. Prompt em `prompt.txt`.

Sem requisitos de remonta, nível, stats, elemento definitivo ou papel canônico. Um concept, sem rig ou integração.
''',encoding='utf-8')
        (p/'revisao.md').write_text(f'''# Revisão — {d['name']}

Imagem gerada aberta e inspecionada antes da entrega.

{d['review']}

Paleta e construção material mantêm parentesco; o corpo e a capacidade mudam entre idades. Terminações completas no quadro, embora a folga varie. Arte com fundo branco e sombra ilustrativa, sem alpha. Não certifica pixel art técnico, ação em movimento ou rig. Revisão interna selecionou o concept para apresentação; aprovação do autor pendente.
''',encoding='utf-8')
        with Image.open(p/'concept.png') as im: dims=list(im.size); mode=im.mode
        manifest=dict(id=d['id'],family_id='ressonhiena',date=DATA['date'],tool='built-in image_gen.imagegen',
            source=d['source'],dimensions=dims,mode=mode,background='white',sha256=hashlib.sha256((p/'concept.png').read_bytes()).hexdigest(),
            reference='../../concept-v2/concept.png',reference_role='author-owned approved adult identity',external_images_attached=False,
            prompt='prompt.txt',brief='brief.md',review='revisao.md',decision_status='proposed',production_status='concept',implementation_status='not_integrated')
        (p/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        rel=f'../../../art/creatures/ressonhiena/{d["id"]}/concept-v1'
        nodes.append(dict(id=d['id'],name=d['name'],kind='stage',stage=d['stage'],maturity=d['maturity'],identity=d['identity'],story=d['story'],
            action=d['action'],tradeoff=d['tradeoff'],decision_status='proposed',production_status='concept',art=rel+'/concept.png',brief=rel+'/brief.md'))

    adult=REPO/'art/creatures/ressonhiena/concept-v2'
    manifest=json.loads((adult/'manifest.json').read_text(encoding='utf-8'))
    manifest['decision_status']='approved';manifest['approval_note']=APPROVAL
    (adult/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    review=(adult/'revisao.md').read_text(encoding='utf-8')
    review=review.replace('Concept-v2 proposto, ainda sem aprovação final do autor.', 'Concept-v2 aprovado visualmente pelo autor, como forma adulta. Novas formas e regras de jogo têm aprovação separada.')
    (adult/'revisao.md').write_text(review,encoding='utf-8')
    decisions=REPO/'art/creatures/ressonhiena/DECISOES.md'
    content=decisions.read_text(encoding='utf-8')
    content=content.replace('Estado atual: concept-v2 apresentado, aguardando avaliação do autor; não integrado.', 'Estado dessa entrega antes da resposta seguinte: concept-v2 apresentado, ainda sem aprovação; não integrado.')
    if '## Aprovação do adulto e criação da linha' not in content:
        content+='\n## Aprovação do adulto e criação da linha\n\n'+APPROVAL+'\n\nLinha inferior proposta: Risaco (bebê), Rasquim (criança), Rasgargal (jovem). Artes em subpastas próprias; adulto preservado sem regeneração. Chart documental em `documentation/creatures/ressonhiena-chart-v1/`. Ainda não integrado.\n'
    decisions.write_text(content,encoding='utf-8')
    nodes.append(dict(id='ressonhiena',name='Ressonhiena',kind='stage',stage=4,maturity='Adulto · IV Pandorga',
        identity='Hiena de ombros altos e quatro patas; armadura completa de sacos almáticos atados, couraça e grevas; chamas nos rasgos.',
        story='Propõe-se que aprenda a distribuir pressão entre proteções e projetar o riso sem romper a estrutura.',
        decision_status='approved',approval_note=APPROVAL,production_status='concept',
        art='../../../art/creatures/ressonhiena/concept-v2/concept.png',brief='../../../art/creatures/ressonhiena/concept-v2/brief.md'))
    reasons=[
        'O saquinho desenvolve apoios e corpo; a membrana antes envolvente torna-se gola protetora.',
        'A criança aprende a comprimir matéria; o corpo alonga e surge a primeira proteção que acumula pressão.',
        'O jovem distribui a pressão antes concentrada num ombro; couraça, ombreiras e grevas integram o sistema adulto.'
    ]
    edges=[dict(**{'from':nodes[i]['id'],'to':nodes[i+1]['id']},kind='reweaving',reason=reasons[i],decision_status='proposed') for i in range(3)]
    chart=dict(family_id='ressonhiena',scope='Família conceitual de quatro estágios; adulto visualmente aprovado; inferiores propostos, sem integração.',nodes=nodes,edges=edges)
    (HERE/'chart.json').write_text(json.dumps(chart,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (HERE/'fontes.json').write_text(json.dumps([
        dict(kind='author-decision',source='Conversa 2026-11-06',fact=APPROVAL),
        dict(kind='own-art',source='../../../art/creatures/ressonhiena/concept-v2/concept.png',role='Única referência anexada às três gerações'),
        dict(kind='internal-benchmark',source='../../../art/benchmarks/loogamon-line-2026-11-06/ANALISE.md',role='Maturidade, construção e função; nenhuma imagem externa anexada'),
        dict(kind='world-contract',source='../../historia/BIBLIA-DA-HISTORIA.md',role='Uma rabiola específica porta a almática; não criar almas extras')
    ],ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

    # Comparação editorial, sem alterar os originais ou representar escala do jogo.
    board=Image.new('RGB',(2400,1700),'#f5f1e8');draw=ImageDraw.Draw(board)
    font='C:/Windows/Fonts/arial.ttf';title=ImageFont.truetype(font,46);label=ImageFont.truetype(font,34);small=ImageFont.truetype(font,24)
    draw.text((50,32),'RESSONHIENA  /  DA MEMBRANA À ARMADURA',font=title,fill='#162b36')
    draw.text((50,99),'Bebê → criança → jovem → adulto · Nomes inferiores propostos',font=small,fill='#58636b')
    positions=[(35,165),(1220,165),(35,915),(1220,915)]
    boxes=[(650,530),(960,570),(1080,590),(1080,590)]
    for n,(x,y),size in zip(nodes,positions,boxes):
        draw.rounded_rectangle((x,y,x+1145,y+720),radius=7,fill='white')
        im=Image.open((HERE/n['art']).resolve()).convert('RGB')
        thumb=ImageOps.contain(im,size,Image.Resampling.LANCZOS)
        board.paste(thumb,(x+(1145-thumb.width)//2,y+24+(590-thumb.height)//2))
        draw.text((x+28,y+628),n['name']+' · '+n['maturity'],font=label,fill='#162b36')
        draw.text((x+28,y+680),'ADULTO APROVADO' if n['id']=='ressonhiena' else 'NOVO CONCEPT · PROPOSTO',font=small,fill='#58636b')
    board.save(HERE/'familia.png')
    cards=''.join(f'<article><a href="{n["art"]}"><img src="{n["art"]}" alt="{n["name"]}, {n["maturity"]}"></a><div><h2>{n["name"]}</h2><p>{n["maturity"]} · '+('Adulto aprovado' if n['id']=='ressonhiena' else 'Proposto')+f'</p><p>{n["story"]}</p><p>{n["identity"]}</p><a href="{n["brief"]}">Brief</a></div></article>' for n in nodes)
    page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Ressonhiena · linha evolutiva</title><style>*{box-sizing:border-box}body{background:#f5f1e8;color:#162b36;font:17px/1.6 system-ui,sans-serif;margin:0}main{max-width:1400px;padding:35px;margin:auto}h1{font-size:clamp(32px,5vw,58px);line-height:1.1}.all{width:100%;height:auto}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(330px,1fr));gap:25px;margin-top:30px}article{background:white;border:1px solid #ddd5c9}article img{width:100%;height:330px;object-fit:contain}article div{padding:24px}a{color:#9b3b26}a:focus-visible{outline:3px solid #bd6936;outline-offset:4px}h2{margin:0}small{color:#58636b}@media(max-width:480px){main{padding:18px}.grid{grid-template-columns:1fr}}</style><main><small>SOULMONSTERS · 06.11.2026</small><h1>Da membrana à armadura.</h1><p>Risaco → Rasquim → Rasgargal → Ressonhiena. Adulto visualmente aprovado; formas inferiores, nomes e relações de amadurecimento propostos. Sem rig ou integração.</p><a href="familia.png"><img class="all" src="familia.png" alt="Quatro estágios da família Ressonhiena"></a><div class="grid">__CARDS__</div><p><a href="CHART.md">História, decisões e revisão</a> · <a href="chart.json">Chart documental</a></p><p>Composição editorial sem escala técnica de jogo. Novos concepts produzidos com image_gen.imagegen; prompts e revisões nas pastas individuais.</p></main></html>'''
    (HERE/'index.html').write_text(page.replace('__CARDS__',cards),encoding='utf-8')
    print('3 formas registradas; adulto aprovado preservado; chart e prancha de 4 estágios montados.')


if __name__=='__main__':run()
