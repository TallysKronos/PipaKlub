"""Registra concepts dos portadores e monta painel sem repintar os originais."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
import json,hashlib,shutil

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[2]
DATA=json.loads((HERE/'portadores-producao.json').read_text(encoding='utf-8'))


def run():
    entries=[]
    for d in DATA['creatures']:
        p=REPO/'art/creatures'/d['id']/'concept-v1';p.mkdir(parents=True,exist_ok=True)
        shutil.copy2(d['source'],p/'concept.png')
        (p/'prompt.txt').write_text(d['prompt']+'\n',encoding='utf-8')
        if d['edit_prompt']:
            shutil.copy2(d['original_source'],p/'tentativa-anatomia.png')
            (p/'prompt-correcao.txt').write_text(d['edit_prompt']+'\n',encoding='utf-8')
        (p/'brief.md').write_text(f'''# {d['name']} — portador proposto

2026-11-06. Design, nome e maturidade adulta/IV Pandorga propostos. Pertencimento ao grupo também proposto, não aprovado automaticamente.

## Anatomia e intenção

{d['architecture']}

Olhos: {d['eyes']}, sem laranja. Verbo: {d['action']}. {d['story']} Limitação proposta: {d['tradeoff']}

## Identidade do grupo

Um Crystal Pipa lilás, núcleo-nó e travessa/espinha menta, montagem de três apoios no eixo frontal da armadura. Topo livre, laterais e ponta inferior seguros. Alinhamento é anatômico, não o centro da página. A proteção envolve o corpo, em vez de receber uma joia solta no flanco.

Uma rabiola específica, uma almática. Cristal como condutor/reserva ancestral sem segunda alma permanece proposta de compatibilidade com a bíblia. Não inventar outra criatura no cristal. Origem, hierarquia, elemento, obtenção e habilidades de jogo estão indefinidos.

## Método

Geração integrada image_gen.imagegen. Referências anexadas: folha autoral do cristal para identidade da peça; Vesperálito concept-v2 para acabamento e densidade, sem copiar arquitetura. Nenhuma imagem externa. Sombras em blocos, contorno 2D mangá e equilíbrio 45/45/10. Artes individuais com fundo branco, sem rig ou integração.
''',encoding='utf-8')
        (p/'revisao.md').write_text(f'''# Revisão — {d['name']}

Imagem final aberta e inspecionada. {d['review']}

Crystal Pipa segue o eixo frontal da proteção e possui apoios laterais/inferior. Terminações dentro da imagem, com margens estreitas em alguns pontos. Material, contorno e sombra mantêm unidade com o grupo; paleta, arquitetura e olhos diferenciam o portador. Mesmo assim, vistas extras serão necessárias para confirmar espessura, juntas e repetibilidade.

Recorte transparente, pixel art técnico, animação e rig não foram produzidos. Correção generativa não garante pixels invariantes fora da região pedida. Selecionado na revisão interna para apresentação; aprovação do autor pendente. Nada integrado.
''',encoding='utf-8')
        with Image.open(p/'concept.png') as im:dims=list(im.size);mode=im.mode
        m=dict(id=d['id'],group_proposed='portadores dos Crystais Pipas',date=DATA['date'],tool='built-in image_gen.imagegen',source=d['source'],dimensions=dims,mode=mode,background='white',sha256=hashlib.sha256((p/'concept.png').read_bytes()).hexdigest(),references=[{'path':'../../../artifacts/crystais-pipas/concept-v1/concept.png','role':'own artifact identity'},{'path':'../../vesperalito/concept-v2/concept.png','role':'own rendering and density'}],external_images_attached=False,prompt='prompt.txt',brief='brief.md',review='revisao.md',correction_prompt='prompt-correcao.txt' if d['edit_prompt'] else None,decision_status='proposed',production_status='concept',implementation_status='not_integrated')
        (p/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        entries.append(dict(id=d['id'],name=d['name'],architecture=d['architecture'],eyes=d['eyes'],action=d['action'],decision_status='proposed',production_status='concept',implementation_status='not_integrated',art=f'../../../art/creatures/{d["id"]}/concept-v1/concept.png',brief=f'../../../art/creatures/{d["id"]}/concept-v1/brief.md'))
    all_entries=[dict(id='vesperalito',name='Vesperálito',architecture='Quadrúpede de ombros em arco e quatro apoios.',eyes='violeta',action='conter',decision_status='proposed',production_status='concept',implementation_status='not_integrated',art='../../../art/creatures/vesperalito/concept-v2/concept.png',brief='../../../art/creatures/vesperalito/concept-v2/brief.md')]+entries
    (HERE/'portadores.json').write_text(json.dumps(dict(scope='Grupo aberto, quatro concepts propostos, sem quantidade final definida.',members=all_entries),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

    board=Image.new('RGB',(2700,850),'#f2eee5');draw=ImageDraw.Draw(board);font='C:/Windows/Fonts/arial.ttf'
    title=ImageFont.truetype(font,48);name=ImageFont.truetype(font,33);small=ImageFont.truetype(font,24)
    draw.text((45,28),'CRYSTAIS PIPAS  /  TRÊS NOVOS PORTADORES',font=title,fill='#162f32')
    draw.text((45,98),'Concepts propostos · anatomias próprias, assinatura compartilhada',font=small,fill='#59696a')
    for i,d in enumerate(DATA['creatures']):
        x=30+i*890;y=160
        draw.rounded_rectangle((x,y,x+860,y+640),radius=8,fill='white')
        im=Image.open(REPO/'art/creatures'/d['id']/'concept-v1/concept.png').convert('RGB')
        thumb=ImageOps.contain(im,(820,545),Image.Resampling.LANCZOS)
        board.paste(thumb,(x+20+(820-thumb.width)//2,y+15+(545-thumb.height)//2))
        draw.text((x+26,y+568),d['name'],font=name,fill='#162f32')
        draw.text((x+26,y+610),d['action'].capitalize()+' · olhos '+d['eyes'],font=small,fill='#59696a')
    board.save(HERE/'novos-portadores.png')
    figures=''.join(f'<article><a href="{d["art"]}"><img src="{d["art"]}" alt="{d["name"]}: {d["architecture"]}"></a><div><h2>{d["name"]}</h2><p>{d["architecture"]}</p><p>Verbo proposto: {d["action"]}. Olhos {d["eyes"]}.</p><a href="{d["brief"]}">Brief</a></div></article>' for d in all_entries)
    page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Crystais Pipas · portadores</title><style>*{box-sizing:border-box}body{margin:0;background:#f2eee5;color:#162f32;font:18px/1.65 system-ui,sans-serif}main{max-width:1500px;margin:auto;padding:36px}h1{font-size:clamp(34px,6vw,62px);line-height:1.1}.all{width:100%;height:auto}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(330px,1fr));gap:24px;margin:30px 0}article{background:white;border:1px solid #d8d1c5}article img{width:100%;height:350px;object-fit:contain}article div{padding:24px}h2{margin:0}a{color:#634185}a:focus-visible{outline:3px solid #9670b4;outline-offset:4px}.artifact{background:white;padding:20px;margin:30px 0}.artifact img{width:100%;height:auto}@media(max-width:500px){main{padding:18px}.grid{grid-template-columns:1fr}}</style><main><h1>Crystais Pipas</h1><p>Quatro portadores propostos, sem fixar o tamanho final do grupo. Cada corpo possui função, anatomia e armadura próprias; cristal e encaixe formam a assinatura ancestral.</p><a href="novos-portadores.png"><img class="all" src="novos-portadores.png" alt="Nimbálio, Ofirante e Canticripta, os três novos portadores"></a><div class="grid">__FIGURES__</div><section class="artifact"><h2>O cristal e seu suporte</h2><a href="../../../art/artifacts/crystais-pipas/concept-v1/concept.png"><img src="../../../art/artifacts/crystais-pipas/concept-v1/concept.png" alt="Três vistas do mesmo Crystal Pipa"></a></section><p><a href="CONCEITO.md">Definido pelo autor e propostas</a> · <a href="PORTADORES.md">Revisão dos novos portadores</a> · <a href="portadores.json">Índice documental</a></p><p>Concepts com fundo branco, sem rig ou integração. Galeria de artes estáticas; não prova de movimento.</p></main></html>'''
    (HERE/'index.html').write_text(page.replace('__FIGURES__',figures),encoding='utf-8')
    print('3 novos concepts registrados; correção anatômica preservada; índice de 4 portadores e prancha montados.')


if __name__=='__main__':run()
