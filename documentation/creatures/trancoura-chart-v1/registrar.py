"""Registra três pré-evoluções e compara com o adulto preservado."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
import json,hashlib,shutil

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[2]
DATA=json.loads((HERE/'producao.json').read_text(encoding='utf-8'))
APPROVAL='Autor: "Aprovado faça as pré evo". Escopo: concept adulto Trancoura apresentado; não aprova automaticamente novas formas ou regras de evolução.'


def run():
    nodes=[]
    for d in DATA['creatures']:
        p=REPO/'art/creatures/trancoura'/d['id']/'concept-v1';p.mkdir(parents=True,exist_ok=True)
        shutil.copy2(d['source'],p/'concept.png')
        (p/'prompt.txt').write_text(d['prompt']+'\n',encoding='utf-8')
        (p/'brief.md').write_text(f'''# {d['name']} — {d['maturity']}

2026-11-06. Nome e concept propostos para a família do Trancoura adulto aprovado.

## História e corpo

{d['story']}

Identidade: {d['identity']}

Verbo: {d['action']}. Limitação proposta: {d['tradeoff']}

## Direção e continuidade

Tatu-canastra, portão de enrolar e lambe-lambe almático. Manter cobalto, marfim, ameixa, framboesa e menta; olhos azul-gelo, sem laranja. Membranas, varetas e linhas integram corpo e couraça. Uma rabiola específica porta uma almática; fragmentos de papel soltos são efeito visual, não almas novas.

Adulto autoral aprovado anexado como única referência de família e acabamento. Nenhuma imagem externa anexada. Ferramenta integrada image_gen.imagegen, prompt em `prompt.txt`. Benchmark interno Loogamon contribui com construção e contraste de maturidade, sem cópia de peças.

Estágio, nome, narrativa e função permanecem propostas. Sem requisitos de remonta, stats, elemento definitivo, rig ou integração.
''',encoding='utf-8')
        (p/'revisao.md').write_text(f'''# Revisão — {d['name']}

PNG aberto e inspecionado. {d['review']}

Contorno e sombras em blocos, paleta contínua e matéria própria da família. Pontas e rabiola dentro do quadro, com margens de folga variável. Pose única não certifica movimento, fechamento de placas ou rig. Fundo branco intencional, não recorte transparente nem pixel art técnico. Selecionado na revisão interna; aprovação do autor pendente.
''',encoding='utf-8')
        with Image.open(p/'concept.png') as im:dims=list(im.size);mode=im.mode
        m=dict(id=d['id'],family_id='trancoura',date=DATA['date'],tool='built-in image_gen.imagegen',source=d['source'],dimensions=dims,mode=mode,background='white',sha256=hashlib.sha256((p/'concept.png').read_bytes()).hexdigest(),reference='../../concept-v1/concept.png',reference_role='author-owned approved adult identity',external_images_attached=False,prompt='prompt.txt',brief='brief.md',review='revisao.md',decision_status='proposed',production_status='concept',implementation_status='not_integrated')
        (p/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        rel=f'../../../art/creatures/trancoura/{d["id"]}/concept-v1'
        nodes.append(dict(id=d['id'],name=d['name'],kind='stage',stage=d['stage'],maturity=d['maturity'],identity=d['identity'],story=d['story'],action=d['action'],tradeoff=d['tradeoff'],decision_status='proposed',production_status='concept',art=rel+'/concept.png',brief=rel+'/brief.md'))
    adult=REPO/'art/creatures/trancoura/concept-v1'
    m=json.loads((adult/'manifest.json').read_text(encoding='utf-8'));m.update(decision_status='approved',approval_note=APPROVAL)
    (adult/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    f=adult/'revisao.md';t=f.read_text(encoding='utf-8').replace('Design proposto, aguardando avaliação do autor.', 'Concept adulto aprovado visualmente pelo autor. Novos designs e regras permanecem separados.');f.write_text(t,encoding='utf-8')
    nodes.append(dict(id='trancoura',name='Trancoura',kind='stage',stage=4,maturity='Adulto · IV Pandorga',identity='Tatu pesado de quatro apoios, couraça-portão segmentada, rolo dorsal, garras grandes e olhos azul-gelo.',story='Propõe-se que domine a articulação da couraça para bloquear passagem e proteger quem está atrás.',decision_status='approved',approval_note=APPROVAL,production_status='concept',art='../../../art/creatures/trancoura/concept-v1/concept.png',brief='../../../art/creatures/trancoura/concept-v1/brief.md'))
    reasons=['O rolo ganha corpo e quatro apoios; seu papel se abre num abrigo móvel.', 'O abrigo passa a articular placas; o corpo alonga para interceptar e cobrir pontos vulneráveis.', 'O jovem troca parte da mobilidade por apoio e proteção; lâminas múltiplas e garras integram o sistema adulto.']
    edges=[dict(**{'from':nodes[i]['id'],'to':nodes[i+1]['id']},kind='reweaving',reason=reasons[i],decision_status='proposed') for i in range(3)]
    (HERE/'chart.json').write_text(json.dumps(dict(family_id='trancoura',scope='Adulto aprovado e três pré-evoluções propostas; sem integração.',nodes=nodes,edges=edges),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (REPO/'art/creatures/trancoura/DECISOES.md').write_text('# Trancoura — decisões\n\n2026-11-06. '+APPROVAL+'\n\nAdulto preservado sem alteração do PNG. Pré-evoluções propostas: Bobim, Tatimbo e Trancasco. Nomes e relações são propostas, não requisitos de jogo. Todos mantêm olhos azul-gelo conforme direção do autor. Chart: `documentation/creatures/trancoura-chart-v1/`. Sem integração.\n',encoding='utf-8')
    (HERE/'fontes.json').write_text(json.dumps([
        dict(kind='author-decision',source='Conversa 2026-11-06',fact=APPROVAL),
        dict(kind='own-art',source='../../../art/creatures/trancoura/concept-v1/concept.png',role='Única referência anexada'),
        dict(kind='internal-benchmark',source='../../../art/benchmarks/loogamon-line-2026-11-06/ANALISE.md',role='Contraste de maturidade e matéria, sem copiar peças'),
        dict(kind='world-contract',source='../../historia/BIBLIA-DA-HISTORIA.md',role='Rabiola específica porta a almática')
    ],ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

    board=Image.new('RGB',(2400,1700),'#f5f1e8');draw=ImageDraw.Draw(board);font='C:/Windows/Fonts/arial.ttf'
    title=ImageFont.truetype(font,47);label=ImageFont.truetype(font,34);small=ImageFont.truetype(font,24)
    draw.text((50,32),'TRANC OURA  /  DO ABRIGO AO GUARDIÃO',font=title,fill='#162b36')
    draw.text((50,99),'Bebê → criança → jovem → adulto · Nomes inferiores propostos',font=small,fill='#58636b')
    for n,(x,y),box in zip(nodes,[(35,165),(1220,165),(35,915),(1220,915)],[(650,530),(970,580),(1080,590),(1080,590)]):
        draw.rounded_rectangle((x,y,x+1145,y+720),radius=7,fill='white')
        im=Image.open((HERE/n['art']).resolve()).convert('RGB');thumb=ImageOps.contain(im,box,Image.Resampling.LANCZOS)
        board.paste(thumb,(x+(1145-thumb.width)//2,y+24+(590-thumb.height)//2))
        draw.text((x+28,y+628),n['name']+' · '+n['maturity'],font=label,fill='#162b36')
        draw.text((x+28,y+680),'ADULTO APROVADO' if n['id']=='trancoura' else 'NOVO CONCEPT · PROPOSTO',font=small,fill='#58636b')
    board.save(HERE/'familia.png')
    cards=''.join(f'<article><a href="{n["art"]}"><img src="{n["art"]}" alt="{n["name"]}, {n["maturity"]}"></a><div><h2>{n["name"]}</h2><p>{n["maturity"]}</p><p>{n["story"]}</p><p>{n["identity"]}</p><a href="{n["brief"]}">Brief</a></div></article>' for n in nodes)
    page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Trancoura · evolução</title><style>*{box-sizing:border-box}body{background:#f5f1e8;color:#162b36;font:17px/1.6 system-ui,sans-serif;margin:0}main{max-width:1400px;padding:35px;margin:auto}h1{font-size:clamp(32px,5vw,58px);line-height:1.1}.all{width:100%;height:auto}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(330px,1fr));gap:25px;margin-top:30px}article{background:white;border:1px solid #ddd5c9}article img{width:100%;height:330px;object-fit:contain}article div{padding:24px}a{color:#2e508f}a:focus-visible{outline:3px solid #a83f76;outline-offset:4px}h2{margin:0}@media(max-width:480px){main{padding:18px}.grid{grid-template-columns:1fr}}</style><main><h1>Do abrigo ao guardião.</h1><p>Bobim → Tatimbo → Trancasco → Trancoura. Adulto aprovado; pré-evoluções, nomes novos e relações propostas. Todos com olhos azul-gelo. Sem rig ou integração.</p><a href="familia.png"><img class="all" src="familia.png" alt="Quatro estágios da família Trancoura"></a><div class="grid">__CARDS__</div><p><a href="CHART.md">Decisões e revisão</a> · <a href="chart.json">Chart documental</a></p><p>Montagem editorial, sem escala técnica de jogo. Geração integrada image_gen.imagegen; prompts, manifestos e revisões individuais preservados.</p></main></html>'''
    (HERE/'index.html').write_text(page.replace('__CARDS__',cards),encoding='utf-8')
    print('3 concepts registrados; adulto preservado; chart e prancha montados.')


if __name__=='__main__':run()
