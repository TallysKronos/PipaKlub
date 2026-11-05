from pathlib import Path
import json,hashlib,shutil,os
from html import escape
from PIL import Image,ImageOps,ImageDraw,ImageFont
D=Path(__file__).resolve().parent;R=D.parents[2];A=R/'art/creatures/tramino-family-v1';P=A/'tramassauro/concept-v2'
S=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-d3f9e57a-9d88-450e-b889-6f4f33f5cf4f.png')
if not(P/'concept.png').exists():shutil.copy2(S,P/'concept.png')
with Image.open(P/'concept.png') as im:dimensions=list(im.size);mode=im.mode
(P/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen built-in',source=str(S),sha256=hashlib.sha256((P/'concept.png').read_bytes()).hexdigest(),dimensions=dimensions,mode=mode,reference_role='Own child Tramino identity',external_generation_inputs=False,decision_status='proposed',production_status='concept',implementation_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
for id in ['tramassauro','tramadraco']:
 p=A/id/'concept-v1/manifest.json';m=json.loads(p.read_text(encoding='utf-8'));m.update(decision_status='rejected',decision_note='Autor rejeitou formas acima da criança por genéricas.');p.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
chart=json.loads((D/'chart.json').read_text(encoding='utf-8'))
for n in chart['nodes']:
 if n['id']=='tramassauro':n.update(art=Path(os.path.relpath(P/'concept.png',D)).as_posix(),brief=Path(os.path.relpath(P/'brief.md',D)).as_posix(),identity='Bípede assimétrico de antebraço-aríete em sanfona e vela curta de contrapeso.',story='Aprende a recolher e liberar tensão em um gesto controlado, em vez de apenas correr.',revision='concept-v2',decision_status='proposed')
 elif n['id']=='tramadraco':n.update(decision_status='rejected',review_note='Direção genérica rejeitada; adulto a ser reconstruído após revisar a nova jovem.')
 else:n['author_feedback']='Até a child achei legal; manter estas formas.'
for e in chart['edges']:
 if e['to']=='tramadraco':e['decision_status']='rejected'
chart['scope']='Bebê/criança preservadas e elogiadas; jovem v2 em avaliação; adulta v1 rejeitada e pendente de reconstrução.'
(D/'chart.json').write_text(json.dumps(chart,ensure_ascii=False,indent=2),encoding='utf-8')
cards=[];sheet=Image.new('RGB',(1800,1400),'#faf7f0');draw=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24)
for k,n in enumerate(chart['nodes']):
 status='Histórico REJEITADO' if n['decision_status']=='rejected' else 'Preservado' if n['stage']<3 else 'Novo piloto em avaliação'
 with Image.open(D/n['art']) as im:t=ImageOps.contain(im.convert('RGB'),(850,590));x=k%2*900;y=k//2*700;sheet.paste(t,(x+(900-t.width)//2,y+75+(590-t.height)//2))
 draw.text((x+20,y+15),n['name']+' · '+status,font=font,fill='#69382f' if n['decision_status']=='rejected' else '#282443')
 cards.append('<article><h2>'+escape(n['name'])+'</h2><b>'+status+'</b><a href="'+n['art']+'"><img src="'+n['art']+'" alt="'+escape(n['identity'])+'"></a><p>'+escape(n['story'])+'</p></article>')
sheet.save(D/'familia.png')
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Tramino · revisão estrutural</title><style>body{max-width:1250px;margin:auto;padding:24px;background:#faf5e9;color:#282443;font:18px/1.6 system-ui}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}article{padding:24px;background:white}img{width:100%;height:430px;object-fit:contain}a:focus-visible{outline:3px solid #cf4c2e}@media(max-width:700px){.grid{grid-template-columns:1fr}}</style><h1>Tramino · especialidade antes de tamanho</h1><p>Bebê/criança preservadas. Jovem v2 em avaliação. Adulta anterior rejeitada: exibida apenas como histórico, não como destino atual.</p><a href="revisao-estrutural-v2/ESTUDO.md">Estudo e fontes</a> · <a href="chart.json">Chart</a><main class="grid">'+''.join(cards)+'</main></html>',encoding='utf-8')
note='\n\n## Revisão estrutural v2\n\nAutor rejeitou jovem/adulto por genéricos e elogiou até a criança. Estudados MetalGreymon, WarGrowlmon e ExVeemon. Novo piloto jovem bípede assimétrico com braço-aríete de papel. Adulto anterior rejeitado e preservado como histórico; próximo adulto depende da direção deste piloto.\n'
p=D/'CHART.md';text=p.read_text(encoding='utf-8')
if '## Revisão estrutural v2' not in text:p.write_text(text+note,encoding='utf-8')
print('Jovem v2 registrada; direções rejeitadas preservadas e rotuladas.')
exec(compile((D/'aplicar_limpeza_v4.py').read_text(encoding='utf-8'),str(D/'aplicar_limpeza_v4.py'),'exec'),{'__file__':str(D/'aplicar_limpeza_v4.py')})
