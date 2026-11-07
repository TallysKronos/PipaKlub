"""Registra conceitos gerados e monta prancha comparativa, sem repintar a arte."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps
import hashlib
import html
import json
import shutil

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
DATA = json.loads((HERE/'producao.json').read_text(encoding='utf-8'))
REVIEWS = {
 'ressonhiena': ('Quatro patas e mandíbula aberta legíveis; garganta pregueada integrada ao peito; dorso desce aos quadris; uma rabiola com duas lâminas terminais. Face e tórax recebem o foco.', 'Enquadramento original tem pouca folga em pontos periféricos. Ainda falta demonstrar ressonância em ação; não é habilidade implementada.'),
 'antamarra': ('Quatro membros separados, pés largos, focinho curto preênsil e orelhas arredondadas. Volume do torso e compressão da gola contrastam com a membrana tensionada.', 'Arte mostra bracejamento, não valida natação ou resgate. Três nervuras visíveis no desenho expandiram a proposta inicial de duas; montagem aceita nesta revisão visual, não rig.'),
 'mangufio': ('Quatro patas com raízes e espaços negativos; tronco flexível, focinho fino, pequena orelha redonda e longa rabiola contínua. Varetas terminam no mesmo nó da gola; não são membros.', 'Pose sugere deslocamento lateral, mas não demonstra o ciclo de esquiva. Gola tem grande participação na silhueta; conferir alcance e recuperação numa fase futura.'),
 'ouricorda': ('Quatro patas visíveis, uma distante parcialmente ocluída pelo ventre. Três feixes dorsais largos com raízes e varetas; uma rabiola completa. Correção diminuiu olhos, alongou maxila e retirou bochechas infladas e bigodes.', 'Não há garantia de preservação pixel a pixel fora da face: comparação visual manteve composição e apêndices. Manto é interpretação de espinhos de papel, não anatomia zoológica literal; falta vista de retração.'),
 'bufarol': ('Quatro pernas com cascos fendidos, dois chifres enraizados no crânio, focinho bovino e cabeça baixa. Pescoço em camadas e peito largo sustentam presença adulta; rabiola ligada ao quadril.', 'Peitoral e chifres ainda precisam de vista lateral e ação de avanço para provar transmissão de força. Contact shadow é ilustrativa, não geometria de colisão.'),
}


def run():
    cards=[]
    for d in DATA['creatures']:
        dest=REPO/'art/creatures'/d['id']/'concept-v1'
        dest.mkdir(parents=True,exist_ok=True)
        source=Path(d['source'])
        shutil.copy2(source,dest/'concept.png')
        (dest/'prompt.txt').write_text(d['prompt']+'\n',encoding='utf-8')
        if d['edit_prompt']:
            shutil.copy2(d['original_source'],dest/'concept-inicial.png')
            (dest/'prompt-correcao.txt').write_text(d['edit_prompt']+'\n',encoding='utf-8')
        brief=f'''# {d['name']} — brief proposto

2026-11-06. Concept inédito autorizado no lote de cinco, sem exigência de confirmação intermediária.

## Definido pelo autor

Cinco Soulmonsters de espécies distintas, mais vivos e construídos após o benchmark Loogamon. Direção: 45% criatura, 45% pipa viva, 10% acabamento pixel/2D mangá. A rabiola específica porta a alma; linhas de suporte não são almas adicionais.

## Proposta desta criação

- Espécie de inspiração: {d['species']}.
- Nome: {d['name']}, ainda não canônico.
- Maturidade: adulto / Pandorga IV, proposta visual; sem pré-evoluções definidas.
- Intenção: {d['attitude']}.
- Verbo principal: {d['verb']}.
- Construção: {d['body']}
- Paleta: {d['palette']}.
- Limitação narrativa proposta: {d['tradeoff']}

## Fontes e método

Aplicação do estudo autoral em `art/benchmarks/loogamon-line-2026-11-06/ANALISE.md`: face articulada, agrupamentos médios, materiais em estados diferentes, massa corporal antes do equipamento. Nenhuma ilustração externa foi anexada ao gerador. Os concepts próprios de Velcão e Lince de cerco foram abertos para calibrar o acabamento, sem anexação. A espécie é uma inspiração artística, não uma alegação biológica ou estudo zoológico documentado.

## Desconhecido / fora do escopo

Família anterior, elemento definitivo, obtenção, habitat canônico, stats, skills e papel na campanha. Sem rig, recortes, animação, montaria ou integração. Não escrever essas propostas na bíblia como decisões aprovadas.
'''
        (dest/'brief.md').write_text(brief,encoding='utf-8')
        ok,limit=REVIEWS[d['id']]
        (dest/'revisao.md').write_text(f'''# Revisão — {d['name']}

## Inspeção realizada

{ok}

Corpos inteiros e terminações dentro da imagem. Sombra agrupada e contorno escuro, com grandes planos tranquilos e camadas de papel/pelo em pontos focais. Conferido também na prancha conjunta.

## Limites observados

{limit}

As cinco formas usam membranas, linhas e nós como vocabulário comum. Não confundir unidade de universo com prova de diversidade infinita: futuros lotes devem explorar outras construções além de nervuras laterais. Concept de alta resolução não certifica pixel art técnico. Fundo branco intencional, sem alpha de recorte.

## Estados

- Revisão interna: selecionado para apresentação; não possui erro estrutural evidente que impeça avaliar o concept.
- Aprovação do autor: pendente; autorização para criar não é aprovação do resultado.
- Produção visual: concept, uma pose.
- Implementação: não integrado.
''',encoding='utf-8')
        with Image.open(dest/'concept.png') as im:
            dims=list(im.size); mode=im.mode; alpha='A' in im.getbands() and im.getchannel('A').getextrema()[0]<255
        manifest=dict(id=d['id'],name=d['name'],date=DATA['date'],decision_status='proposed',
            production_status='concept',implementation_status='not_integrated',maturity_proposed='adult / Pandorga IV',
            tool='built-in image_gen.imagegen',source=d['source'],dimensions=dims,mode=mode,
            transparent_pixels=alpha,background='white',sha256=hashlib.sha256((dest/'concept.png').read_bytes()).hexdigest(),
            prompt='prompt.txt',references_attached=[],edit_reference='concept-inicial.png' if d['edit_prompt'] else None,
            correction_prompt='prompt-correcao.txt' if d['edit_prompt'] else None,
            review='revisao.md',brief='brief.md')
        (dest/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        cards.append(d)

    # Apenas apresentação: cópias redimensionadas com espaço de respiro, sem redesenhar.
    board=Image.new('RGB',(2700,1540),'#f5f1e8')
    draw=ImageDraw.Draw(board)
    fontpath='C:/Windows/Fonts/arial.ttf'
    title=ImageFont.truetype(fontpath,47)
    namefont=ImageFont.truetype(fontpath,31)
    sub=ImageFont.truetype(fontpath,23)
    draw.text((48,28),'SOULMONSTERS  /  QUADRÚPEDES VIVOS',font=title,fill='#152b36')
    draw.text((48,92),'Cinco espécies · cinco funções · concepts propostos — 06.11.2026',font=sub,fill='#59636a')
    positions=[(30,160),(920,160),(1810,160),(475,845),(1365,845)]
    for d,(x,y) in zip(cards,positions):
        draw.rounded_rectangle((x,y,x+860,y+640),radius=8,fill='white')
        src=Image.open(REPO/'art/creatures'/d['id']/'concept-v1/concept.png').convert('RGB')
        thumb=ImageOps.contain(src,(820,547),Image.Resampling.LANCZOS)
        board.paste(thumb,(x+20+(820-thumb.width)//2,y+14+(547-thumb.height)//2))
        draw.text((x+26,y+566),d['name'],font=namefont,fill='#152b36')
        draw.text((x+26,y+608),d['species'].capitalize()+' · '+d['verb'],font=sub,fill='#59636a')
    board.save(HERE/'cinco-soulmonsters.png')
    figures=''.join(f'''<article><a href="../../../art/creatures/{d['id']}/concept-v1/concept.png"><img src="../../../art/creatures/{d['id']}/concept-v1/concept.png" alt="{html.escape(d['name'])}, Soulmonster inspirado em {d['species']}"></a><div><h2>{d['name']}</h2><p>{d['species'].capitalize()} · {d['verb']}.</p><p>{d['body']}</p><p><b>Limitação proposta:</b> {d['tradeoff']}</p><p><a href="../../../art/creatures/{d['id']}/concept-v1/brief.md">Brief</a> · <a href="../../../art/creatures/{d['id']}/concept-v1/revisao.md">Revisão</a> · <a href="../../../art/creatures/{d['id']}/concept-v1/prompt.txt">Prompt</a></p></div></article>''' for d in cards)
    page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Cinco Soulmonsters · Quadrúpedes vivos</title><style>*{box-sizing:border-box}body{margin:0;background:#f5f1e8;color:#152b36;font:17px/1.6 system-ui,sans-serif}main{max-width:1450px;margin:auto;padding:40px}h1{font-size:clamp(34px,5vw,60px);line-height:1.1}a{color:#943c26;text-underline-offset:4px}a:focus-visible{outline:3px solid #b45b29;outline-offset:4px}.all{width:100%;height:auto}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(340px,1fr));gap:25px;margin-top:35px}article{background:white;border:1px solid #d7d1c7;min-width:0}article img{display:block;width:100%;height:auto}article div{padding:25px}h2{margin:0 0 12px}small{color:#59636a}@media(max-width:500px){main{padding:20px}.grid{grid-template-columns:1fr}}</style><main><small>SOULMONSTERS · 06.11.2026</small><h1>Corpo, matéria e intenção.</h1><p>Cinco espécies distintas aplicando o benchmark Loogamon. Nomes, maturidade e capacidades são propostas. Concepts selecionados na revisão interna, aguardando avaliação do autor. Sem rig ou integração.</p><a href="cinco-soulmonsters.png"><img class="all" src="cinco-soulmonsters.png" alt="Prancha conjunta de Ressonhiena, Antamarra, Mangufio, Ouriçorda e Bufarol"></a><div class="grid">__FIGURES__</div><p><a href="../../../art/benchmarks/loogamon-line-2026-11-06/ANALISE.md">Benchmark aplicado</a> · <a href="REVISAO-DO-LOTE.md">Revisão do lote</a></p></main></html>'''
    (HERE/'index.html').write_text(page.replace('__FIGURES__',figures),encoding='utf-8')
    print('5 concepts registrados; 1 correção dirigida preservada; prancha conjunta e galeria montadas.')


if __name__=='__main__':
    run()
