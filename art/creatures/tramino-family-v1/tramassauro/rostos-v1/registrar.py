from pathlib import Path
import json,shutil,hashlib,os
from html import escape
from PIL import Image,ImageOps,ImageDraw,ImageFont
D=Path(__file__).resolve().parent;R=D.parents[4];G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f');cases=json.loads((D/'propostas.json').read_text(encoding='utf-8'))
sheet=Image.new('RGB',(1800,800),'#faf7f0');draw=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',30);cards=[]
for k,s in enumerate(cases):
 p=D/s['id'];p.mkdir(exist_ok=True)
 if not(p/'concept.png').exists():shutil.copy2(G/s['file'],p/'concept.png')
 (p/'prompt.txt').write_text(s['prompt'],encoding='utf-8')
 (p/'brief.md').write_text('# '+s['name']+'\n\nAutor rejeitou o rosto anterior por genérico e olhos grandes e pediu três propostas. Alternativas de cabeça, sem decidir corpo novo. Objetivo: olhos pequenos e mudança de crânio/focinho/mandíbula, não só sobrancelha. Paleta herdada de Tramino, desenho novo gerado por texto após falhas da ferramenta. Nenhuma imagem externa no input.\n\n'+s['note'],encoding='utf-8')
 (p/'revisao.md').write_text('# Conferência\n\n'+s['note']+'\n\nSó cabeça/pescoço; não valida corpo, rig ou expressões. Sombras têm algumas transições suaves residuais. Fundo branco, concept manga, não grid pixel art validado. Proposta em avaliação, não integrada.',encoding='utf-8')
 with Image.open(p/'concept.png') as im:size=list(im.size);mode=im.mode;t=ImageOps.contain(im.convert('RGB'),(570,650));sheet.paste(t,(k*600+(600-t.width)//2,80+(650-t.height)//2))
 draw.text((k*600+25,20),s['name'],font=font,fill='#282443')
 (p/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen built-in',source=str(G/s['file']),sha256=hashlib.sha256((p/'concept.png').read_bytes()).hexdigest(),dimensions=size,mode=mode,reference_role='Written own-family palette and identity; no image inputs in final calls',external_generation_inputs=False,decision_status='proposed',production_status='head_study',implementation_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
 cards.append('<article><h2>'+escape(s['name'])+'</h2><a href="'+s['id']+'/concept.png"><img src="'+s['id']+'/concept.png" alt="'+escape(s['note'])+'"></a><p>'+escape(s['note'])+'</p></article>')
sheet.save(D/'comparativo.png')
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Tramino · três rostos</title><style>body{max-width:1450px;margin:auto;padding:24px;background:#faf7f0;color:#282443;font:18px/1.6 system-ui}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:24px}article{background:white;padding:24px}img{width:100%;height:420px;object-fit:contain}a:focus-visible{outline:3px solid #b64a2d}@media(max-width:850px){.grid{grid-template-columns:1fr}}</style><h1>Três crânios, olhos menores</h1><p>Estudos de rosto em avaliação, sem escolher corpo ou evolução. B foi desenhada em orientação diferente, mantida sem espelhamento para preservar assimetria. Corpo v4 rejeitado pelo autor.</p><a href="comparativo.png">Comparativo</a><main class="grid">'+''.join(cards)+'</main></html>',encoding='utf-8')
old=D.parent/'concept-v4/manifest.json';m=json.loads(old.read_text(encoding='utf-8'));m.update(decision_status='rejected',decision_note='Autor: não gostei, rosto muito genérico, olhos muito grandes; pediu três propostas.');old.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
C=R/'documentation/creatures/tramino-chart-v1';chart=json.loads((C/'chart.json').read_text(encoding='utf-8'))
for n in chart['nodes']:
 if n['id']=='tramassauro':n.update(decision_status='rejected',review_note='Corpo/rosto v4 rejeitado. Três estudos de cabeça em avaliação, nenhum escolhido.',head_proposals=Path(os.path.relpath(D/'index.html',C)).as_posix())
chart['scope']='Bebê/criança preservadas; jovem e adulto anteriores rejeitados. Três novas propostas de rosto em avaliação, sem integração.'
(C/'chart.json').write_text(json.dumps(chart,ensure_ascii=False,indent=2),encoding='utf-8')
p=C/'index.html';text=p.read_text(encoding='utf-8').replace('v4 em avaliação','v4 rejeitada').replace('Jovem v4 em avaliação.','Jovem v4 rejeitada.')
if 'Três rostos novos' not in text:text=text.replace('<main class="grid">','<p><a href="'+Path(os.path.relpath(D/'index.html',C)).as_posix()+'">Três rostos novos em avaliação</a></p><main class="grid">')
p.write_text(text,encoding='utf-8')
note='\n\n## Três propostas faciais\n\nAutor rejeitou v4 por rosto genérico/olhos grandes. Criadas A Aríete, B Espreita e C Tirante como estudos de cabeça; nenhum corpo aplicado nem escolha presumida. Comparativo em art/creatures/tramino-family-v1/tramassauro/rostos-v1/.\n'
p=C/'CHART.md';text=p.read_text(encoding='utf-8')
if '## Três propostas faciais' not in text:p.write_text(text+note,encoding='utf-8')
print('Três propostas faciais salvas, v4 marcada como rejeitada.')
hook=C/'aplicar_corpo_b_v5.py'
exec(compile(hook.read_text(encoding='utf-8'),str(hook),'exec'),{'__file__':str(hook)})
