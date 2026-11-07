"""Organiza os PNGs originais e a galeria de concepts; não modifica pixels."""
from pathlib import Path
from PIL import Image
import hashlib
import html
import json
import shutil

BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[2]
GENERATED=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f')
entries=[
 ('azulim','Azulim','I · Cafifa · proposta','exec-87589598-f8da-4b2c-b676-e57139714581.png'),
 ('azulineo','Azulíneo','III · Arraia B · arquitetura preservada','exec-9c39a9d9-cd1e-45f4-9dae-b7faf312e3a9.png'),
 ('azulume','Azulume','III · Arraia C · arquitetura preservada','exec-1961b737-5013-475f-a385-902ec9b3a3b8.png'),
 ('azultor','Azultor A','IV · Pandorga A · hipogrifo escolhido','exec-92efc635-8541-4106-a2eb-9e51ec92a4a1.png'),
 ('azuligero','Azulígero','IV · Pandorga B · proposta estrutural','exec-c9172959-b2d4-4c15-a93d-b0916ea6770a.png'),
 ('azulaculo','Azuláculo','IV · Pandorga C · proposta estrutural','exec-4dc6304d-26d3-47e8-9297-96f5a5529df8.png'),
 ('azulao-moncao','Vela de Monção','II · Pipa · configuração especial proposta','exec-4ae97880-9741-4e94-8c3e-d4694a6d9451.png'),
 ('azulao-alisio','Vela de Alísio','II · Pipa · configuração especial proposta','exec-3cc2b312-dec7-4bc1-ac5d-87ab1947f3cf.png'),
]
manifest=[];sections=[]
review=(BASE/'REVISAO-PRANCHAS-MANGA.md').read_text(encoding='utf-8')
for ident,name,label,original in entries:
 folder=BASE/ident/'prancha-manga-v1'
 target=folder/'prancha.png';source=GENERATED/original
 assert target.exists() and source.exists()
 digest=hashlib.sha256(target.read_bytes()).hexdigest()
 assert digest==hashlib.sha256(source.read_bytes()).hexdigest()
 with Image.open(target) as im:
  im.verify()
 with Image.open(target) as im:
  size=list(im.size)
 status='estrutura_A_escolhida_acabamento_em_revisao' if ident=='azultor' else 'prancha_em_revisao'
 prompt_file='prompt-retry.txt' if ident=='azulim' else 'prompt-correcao-leque.txt' if ident=='azulaculo' else 'prompt.txt'
 manifest.append({'id':ident,'name':name,'label':label,'file':f'{ident}/prancha-manga-v1/prancha.png','source':str(source),'sha256':digest,'size':size,'tool':'image_gen integrada','status':status,'prompt_final':f'{ident}/prancha-manga-v1/{prompt_file}','original_pixels_preserved':True})
 (folder/'revisao.md').write_text(f'# {name} — revisão\n\nEstado: {status}.\n\nPNG original preservado; fonte e hash no manifesto.\n\n[Conferência específica e limites desta prancha](../../REVISAO-PRANCHAS-MANGA.md).\n\nProdução de concept não valida rig, animação, escala de combate ou aprovação final.\n',encoding='utf-8')
 rel=f'{ident}/prancha-manga-v1'
 sections.append(f'<section id="{ident}"><p class="eyebrow">{html.escape(label)}</p><h2>{html.escape(name)}</h2><img loading="lazy" src="{rel}/prancha.png" alt="Prancha individual de {html.escape(name)} com três vistas e expressões"><p><a href="{rel}/prancha.png">Abrir PNG original</a> · <a href="{rel}/brief.md">Brief</a> · <a href="{rel}/revisao.md">Revisão</a> · <a href="{rel}/prompt.txt">Prompt</a></p></section>')
(BASE/'manifest-pranchas-manga.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
old=BASE/'index-silhuetas-v1.html'
if not old.exists():shutil.copy2(BASE/'index.html',old)
nav=''.join(f'<a href="#{ident}">{html.escape(name)}</a>' for ident,name,_,_ in entries)
page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Azulão · Pranchas em 2D mangá</title><style>*{box-sizing:border-box}body{font:16px/1.65 system-ui;background:#f5f1e7;color:#173749;margin:0}main{max-width:1440px;margin:auto;padding:36px 24px}h1{font-size:clamp(30px,5vw,54px);line-height:1.15;max-width:900px}h2{font-size:30px;margin:8px 0 18px}.eyebrow{font-size:12px;letter-spacing:.08em;font-weight:700}section{margin:48px 0;border-top:2px solid #b2c4c8;padding-top:24px}img{display:block;width:100%;height:auto;background:white;border:1px solid #d6dedb}a{color:#175b85}.note{background:#e7ece4;padding:20px;border-left:4px solid #b8893b;max-width:1100px}nav{display:flex;flex-wrap:wrap;gap:10px;margin:24px 0}nav a{padding:8px 14px;border:1px solid #bdcdce;border-radius:20px;text-decoration:none;background:#fffdf7}footer{font-size:13px;border-top:1px solid #bdcdce;padding:20px 0}a:focus-visible{outline:3px solid #18677a;outline-offset:4px}</style><main><p class="eyebrow">SOULMONSTERS · FAMÍLIA DO AZULÃO · 2D MANGÁ</p><h1>Pranchas individuais com o traço mais limpo.</h1><p class="note"><b>Azultor A escolhido.</b> Estrutura de hipogrifo preservada, acabamento corrigido para linhas finas, cores chapadas e sombras simples. As demais formas novas são propostas em revisão; produzir a prancha não as aprova nem integra ao jogo.</p><p>Oito folhas: vista principal, perfil, costas e expressões. Sem recortes de rig ou animações nesta etapa.</p><p><a href="../../../documentation/creatures/azulao-chart-v1/index.html">Chart interativo</a> · <a href="REVISAO-PRANCHAS-MANGA.md">Revisão das oito folhas</a> · <a href="index-silhuetas-v1.html">Histórico de silhuetas</a></p><nav>'''+nav+'</nav>'+''.join(sections)+'''<footer>Image_gen integrada · arquivos originais preservados · prompts e procedência junto às pranchas. Novas silhuetas das Pandorgas B/C e configurações especiais aguardam revisão do autor. Nenhuma modificação de jogo ou push.</footer></main></html>'''
(BASE/'index.html').write_text(page,encoding='utf-8')
(BASE/'README.md').write_text('''# Família do Azulão — pranchas 2D mangá

[Abrir as oito pranchas](index.html) · [Revisão específica](REVISAO-PRANCHAS-MANGA.md) · [Decisões do autor](DECISOES.md) · [Histórico de silhuetas](index-silhuetas-v1.html).

Azultor **A da folha de hipogrifos** escolhido. Esta etapa corrige o acabamento e desenvolve as demais formas do chart. Oito folhas individuais com vista principal, perfil, costas e expressões. Silhuetas e rascunhos anteriores preservados.

Os PNGs são concepts, sem promessa de encaixe de rig. Arquiteturas B/C de Arraia já existiam; novos nomes, Pandorgas B/C e Velas Especiais permanecem propostas. Nenhuma integração ao jogo.

`manifest-pranchas-manga.json` registra fonte, hash, dimensões, ferramenta e estado de cada folha; `manifest.json` conserva o registro do lote de silhuetas. Cada pasta tem prompt, brief e revisão.
''',encoding='utf-8')
chart_file=ROOT/'documentation/creatures/azulao-chart-v1/chart.json'
chart=json.loads(chart_file.read_text(encoding='utf-8'))
chart['modelSheets']={r['id']:'../../../art/creatures/azulao-family-v1/'+r['file'] for r in manifest}
for node in chart['nodes']:
 if node['id'] in chart['modelSheets']:
  node['mechanicStatus']='Prancha individual 2D mangá com três vistas e expressões, em revisão. Sem rig ou integração; requisitos e estágio continuam propostas.'
 if node['id']=='azultor':
  node['selectedSilhouette']='A — silhuetas-v2-hipogrifo'
  node['architecturalDirectionStatus']='A escolhida pelo autor; acabamento corrigido para 2D mangá, nova prancha aguardando revisão.'
  node['brief']='Preservar o hipogrifo A compacto e protetor. Não C. Quatro patas e duas asas; conferir proporção das pernas e encaixes em vistas de construção. Prancha refinada com traço fino, cores chapadas e sombra simples.'
 if node['id']=='azuligero':
  node['identity']='Nova proposta de ave serpentina de voo horizontal, duas asas junto ao peito e duas patas traseiras junto à bacia. Sem patas dianteiras; crista dupla, bico fino e duas fitas com nuvem mantêm a família.'
  node['change']='Em vez de apenas alongar a ave alta da Arraia B, propõe-se um novo tronco aviano serpentino e deslocamento sustentado no ar. Anatomia nova em revisão, não aprovada automaticamente.'
 if node['id']=='azulaculo':
  node['identity']='Nova proposta de planador aviano de torso raso e largo, duas asas em manto, dois pés pequenos e um único leque-rabiola de três painéis atrás do dorso.'
  node['change']='A massa compacta da Arraia C se abre numa grande superfície de planar, com rosto baixo exposto e três planos sensoriais. Anatomia nova em revisão; não apenas ampliar a coruja.'
chart_file.write_text(json.dumps(chart,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'pranchas':len(manifest),'fontes_verificadas':True,'azultor':'A escolhido; acabamento em revisão'},ensure_ascii=False))
