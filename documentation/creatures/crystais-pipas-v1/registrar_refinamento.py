"""Registra revisões não destrutivas e reconstrói galerias pelos caminhos atuais."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
import json,hashlib,shutil

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[2]
DATA=json.loads((HERE/'refinamento-producao.json').read_text(encoding='utf-8'))
APPROVAL='Autor em 2026-11-07: "Aprovado, agora faça isso com todos os outros que você criou também". Aprovação visual do Grifarca concept-v2 e autorização de revisão dos demais; não é aprovação antecipada de novas artes.'


def image_panel(items,path,title,subtitle,mode='three'):
    if mode=='seven':
        board=Image.new('RGB',(3200,1450),'#f2eee5');positions=[(25+i*795,160) for i in range(4)]+[(422+i*795,800) for i in range(3)]
        width,height,box=760,590,(720,480)
    else:
        board=Image.new('RGB',(2700,850),'#f2eee5');positions=[(30+i*890,160) for i in range(3)];width,height,box=860,640,(820,545)
    draw=ImageDraw.Draw(board);font='C:/Windows/Fonts/arial.ttf'
    tf=ImageFont.truetype(font,47);nf=ImageFont.truetype(font,32);sf=ImageFont.truetype(font,23)
    draw.text((45,28),title,font=tf,fill='#162f32');draw.text((45,98),subtitle,font=sf,fill='#59696a')
    for d,(x,y) in zip(items,positions):
        draw.rounded_rectangle((x,y,x+width,y+height),radius=8,fill='white')
        im=Image.open((HERE/d['art']).resolve()).convert('RGB');thumb=ImageOps.contain(im,box,Image.Resampling.LANCZOS)
        board.paste(thumb,(x+(width-thumb.width)//2,y+14+(box[1]-thumb.height)//2))
        draw.text((x+25,y+height-72),d['name'],font=nf,fill='#162f32')
        draw.text((x+25,y+height-30),d.get('tag','Nova versão · em avaliação'),font=sf,fill='#59696a')
    board.save(path)


def run():
    new=[]
    for d in DATA['creatures']:
        p=REPO/'art/creatures'/d['id']/f'concept-v{d["version"]}';p.mkdir(parents=True,exist_ok=True)
        shutil.copy2(d['source'],p/'concept.png');(p/'prompt.txt').write_text(d['prompt']+'\n',encoding='utf-8')
        if d['edit_prompt']:
            shutil.copy2(d['intermediate'],p/'intermediario-sem-grevas.png')
            (p/'prompt-correcao.txt').write_text(d['edit_prompt']+'\n',encoding='utf-8')
        (p/'brief.md').write_text(f'''# {d['name']} — pipa viva / versão {d['version']}

2026-11-07. Revisão autorizada pelo autor após aprovar o Grifarca redesenhado. Para Trancoura, Gevoraz e Makaréu, houve pedido explícito para remover aparência de pele/músculo retorcido sob casco e armadura.

## Mudança proposta

{d['change']}

Preservar anatomia, identidade, cor de olhos e presença adulta. Membranas tensionadas e dobras de compressão grandes substituem fibras e estrias; não transformar o corpo inteiro em malha de triângulos. Armadura, juntas e raízes continuam legíveis. {'Um Crystal Pipa permanece no eixo frontal anatômico, três apoios, núcleo-nó e canais de condução.' if d['group'] else 'Trancoura não foi transformado em portador de cristal; nenhum cristal adicionado.'}

Uma rabiola completa porta a almática. Cristal, quando presente, não recebe alma adicional; essa compatibilidade permanece proposta do documento do grupo.

## Método

Fonte de identidade: concept-v{d['previous']} do próprio mon. Guia de acabamento e construção: Grifarca concept-v2 aprovado. Somente artes autorais anexadas à ferramenta integrada image_gen.imagegen; nenhuma imagem externa. A aprovação do guia não aprova automaticamente esta revisão. Originais preservados, sem rig, pré-evoluções ou código alterados.
''',encoding='utf-8')
        (p/'revisao.md').write_text(f'''# Revisão visual — {d['name']}

PNG final aberto e inspecionado, 2026-11-07. {d['review']}

Mudança conferida: {d['change']}

No Trancoura, uma segunda edição restaurou as grevas dianteiras que a primeira geração havia retirado. No restante, não houve pedido de nova anatomia ou remoção de armaduras. Algumas dobras pequenas permanecem em juntas e dedos como indicação de compressão; não são fibras repetitivas sobre toda a superfície.

Limites: margens estreitas em algumas terminações, sem corte observado. A montagem e o núcleo do cristal variam com a interpretação de perspectiva, exigindo unificação técnica futura. Uma pose não valida articulação, ação, rig ou movimento. Edição generativa não preserva pixels externos exatamente. Fundo branco, não alpha; ilustração não certifica pixel art técnico.

Selecionado na revisão interna, aprovação do autor pendente. Originais e aprovações anteriores preservados como histórico; nova versão não integrada.
''',encoding='utf-8')
        with Image.open(p/'concept.png') as im:dims=list(im.size);mode=im.mode
        m=dict(id=d['id'],version=d['version'],date=DATA['date'],tool='built-in image_gen.imagegen',source=d['source'],dimensions=dims,mode=mode,background='white',sha256=hashlib.sha256((p/'concept.png').read_bytes()).hexdigest(),references=[{'path':f'../concept-v{d["previous"]}/concept.png','role':'author-owned identity/edit target'},{'path':'../../grifarca/concept-v2/concept.png','role':'approved own living-kite construction guide, not ancestry'}],external_images_attached=False,prompt='prompt.txt',brief='brief.md',review='revisao.md',correction_prompt='prompt-correcao.txt' if d['edit_prompt'] else None,decision_status='proposed',production_status='concept',implementation_status='not_integrated')
        if d['edit_prompt']:m['correction_reference']='intermediario-sem-grevas.png'
        (p/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        dec=REPO/'art/creatures'/d['id']/'DECISOES.md';old=dec.read_text(encoding='utf-8') if dec.exists() else f'# {d["name"]} — decisões\n'
        section=f'\n## 2026-11-07 · revisão de pipa viva\n\nVersão proposta atual: `concept-v{d["version"]}/`. {d["change"]} Originais preservados. Nova versão em avaliação; não integrada.\n'
        if section not in old:dec.write_text(old+section,encoding='utf-8')
        new.append(dict(id=d['id'],name=d['name'],art=f'../../../art/creatures/{d["id"]}/concept-v{d["version"]}/concept.png',brief=f'../../../art/creatures/{d["id"]}/concept-v{d["version"]}/brief.md',change=d['change'],group=d['group'],decision_status='proposed',tag='Membranas e dobras · v'+str(d['version'])))

    gp=REPO/'art/creatures/grifarca/concept-v2';m=json.loads((gp/'manifest.json').read_text(encoding='utf-8'));m.update(decision_status='approved',approval_note=APPROVAL);(gp/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    f=gp/'revisao.md';t=f.read_text(encoding='utf-8').replace('aprovação do autor pendente.','aprovado visualmente pelo autor na resposta seguinte; regras e integração separadas.');f.write_text(t,encoding='utf-8')
    f=gp.parent/'DECISOES.md';t=f.read_text(encoding='utf-8')
    if APPROVAL not in t:f.write_text(t+'\n## Aprovação do v2\n\n'+APPROVAL+'\n',encoding='utf-8')
    f=HERE/'portadores.json';idx=json.loads(f.read_text(encoding='utf-8'))
    by={d['id']:d for d in new}
    for n in idx['members']:
        if n['id'] in by:n.update(art=by[n['id']]['art'],brief=by[n['id']]['brief'],decision_status='proposed',revision_note='2026-11-07: construção de pipa viva, aguardando avaliação.')
        if n['id']=='grifarca':n.update(decision_status='approved',approval_note=APPROVAL)
    (HERE/'portadores.json').write_text(json.dumps(idx,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    # Trancoura: novo adulto em apresentação, mantendo aprovação e PNG anteriores.
    cp=REPO/'documentation/creatures/trancoura-chart-v1';c=json.loads((cp/'chart.json').read_text(encoding='utf-8'))
    for n in c['nodes']:
        if n['id']=='trancoura':
            n['prior_approved_art']=n['art'];n['art']=by['trancoura']['art'];n['brief']=by['trancoura']['brief'];n['decision_status']='proposed';n['approval_note']='Adulto v1 aprovado; revisão de matéria v2 autorizada, aguardando avaliação.'
    (cp/'chart.json').write_text(json.dumps(c,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    f=cp/'index.html';t=f.read_text(encoding='utf-8').replace('art/creatures/trancoura/concept-v1/','art/creatures/trancoura/concept-v2/');t=t.replace('Quatro concepts aprovados visualmente; nomes novos e relações continuam propostas.','Pré-evoluções e adulto v1 aprovados; nova matéria do adulto v2 em avaliação.');f.write_text(t,encoding='utf-8')

    image_panel(new,HERE/'revisoes-pipa-viva.png','SOULMONSTERS  /  REVISÕES DE PIPA VIVA','Sete revisões propostas · corpo, rosto e matéria · 07.11.2026','seven')
    focus=[by[x] for x in ['trancoura','gevoraz','makareu']]
    image_panel(focus,HERE/'membranas-sem-estrias.png','CORPO DE PIPA  /  SOB A ARMADURA','Trancoura, Gevoraz e Makaréu · revisões propostas de matéria')
    members=idx['members']
    for key,filename,title,subtitle in [('normal','novos-portadores.png','CRYSTAIS PIPAS  /  PORTADORES REVISADOS','Nimbálio, Ofirante e Canticripta · pipa viva'),('lendas','portadores-lendas.png','CRYSTAIS PIPAS  /  LENDAS REIMAGINADAS','Grifarca aprovado · Gevoraz e Makaréu revisados')]:
        ids=['nimbalio','ofirante','canticripta'] if key=='normal' else ['grifarca','gevoraz','makareu']
        rows=[next(m for m in members if m['id']==x) for x in ids];image_panel(rows,HERE/filename,title,subtitle)

    cards=''.join(f'<article><a href="{d["art"]}"><img src="{d["art"]}" alt="{d["name"]}, revisão de pipa viva"></a><div><h2>{d["name"]}</h2><p>{d["change"]}</p><a href="{d["brief"]}">Brief</a></div></article>' for d in new)
    style='''<style>*{box-sizing:border-box}body{margin:0;background:#f2eee5;color:#162f32;font:18px/1.65 system-ui,sans-serif}main{max-width:1500px;margin:auto;padding:36px}h1{font-size:clamp(34px,6vw,60px);line-height:1.1}.all{width:100%;height:auto}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(330px,1fr));gap:24px;margin:30px 0}article{background:white;border:1px solid #d8d1c5}article img{width:100%;height:340px;object-fit:contain}article div{padding:24px}h2{margin:0}a{color:#634185}a:focus-visible{outline:3px solid #9670b4;outline-offset:4px}@media(max-width:500px){main{padding:18px}.grid{grid-template-columns:1fr}}</style>'''
    page='<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Pipa viva · revisão</title>'+style+'<main><h1>Corpo de pipa, presença adulta.</h1><p>Sete revisões propostas após aprovação do Grifarca v2. Membranas largas e dobras escolhidas substituem aspecto de músculo retorcido; anatomias, armaduras e cores próprias preservadas.</p><a href="membranas-sem-estrias.png"><img class="all" src="membranas-sem-estrias.png" alt="Trancoura, Gevoraz e Makaréu com membranas sem estrias"></a><a href="revisoes-pipa-viva.png"><img class="all" src="revisoes-pipa-viva.png" alt="Sete criaturas revisadas"></a><div class="grid">'+cards+'</div><p><a href="REFINAMENTO.md">Revisão e limites</a> · <a href="index.html">Portadores</a> · <a href="lendas.html">Fontes das lendas</a></p><p>Originais preservados. Trancoura não recebeu cristal; segue fora do grupo de portadores. Sem rig, animação ou integração.</p></main></html>'
    (HERE/'refinamento.html').write_text(page,encoding='utf-8')
    # Atualiza os links das galerias anteriores sem reexecutar scripts que restaurariam versões antigas.
    for filename in ['index.html','lendas.html']:
        f=HERE/filename;t=f.read_text(encoding='utf-8')
        for d in DATA['creatures']:
            t=t.replace(f'art/creatures/{d["id"]}/concept-v{d["previous"]}/',f'art/creatures/{d["id"]}/concept-v{d["version"]}/')
        if '<!-- refinamento -->' not in t:t=t.replace('<main>','<main><!-- refinamento --><p><a href="refinamento.html">Revisões de pipa viva de 07.11.2026 — incluindo Trancoura</a></p>',1)
        f.write_text(t,encoding='utf-8')
    print('Sete revisões salvas, Grifarca aprovado registrado, índices e três pranchas atualizados; originais preservados.')


if __name__=='__main__':run()
