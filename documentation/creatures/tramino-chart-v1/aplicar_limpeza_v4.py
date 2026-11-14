from pathlib import Path
import json,shutil,hashlib,os
from html import escape
from PIL import Image,ImageOps,ImageDraw,ImageFont
D=Path(__file__).resolve().parent;R=D.parents[2];F=R/'art/creatures/tramino-family-v1/tramassauro';G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f')
for s in json.loads((D/'revisoes-limpeza.json').read_text(encoding='utf-8')):
 p=F/s['id'];p.mkdir(parents=True,exist_ok=True)
 if not(p/'concept.png').exists():shutil.copy2(G/s['source'],p/'concept.png')
 (p/'prompt.txt').write_text(s['prompt'],encoding='utf-8')
 (p/'brief.md').write_text('# Tramassauro — limpeza de volumes\n\nAutor: “Ficou muito amassado e empapelado”, depois “Sim encontre um meio termo, precisa ficar melhor trabalhado mas não exagerar no empapelar”.\n\nProposta: volumes contínuos no corpo e rosto, anatomia clara, assimetria de antebraço como especialidade, pipa concentrada em membrana tensionada, arco de vareta, vela dorsal e rabiola. Evitar toda superfície em origami e também o mascote delicado demais do estudo v3. Bebê e criança preservados. Sem integração ou novas regras de jogo.',encoding='utf-8')
 (p/'revisao.md').write_text('# Conferência\n\n'+s['review']+'\n\nPNG RGB de fundo branco. Concept 2D, não pixel art de grid validado, rig ou animação. Nova v4 em avaliação, sem aprovação presumida.',encoding='utf-8')
 with Image.open(p/'concept.png') as im:size=list(im.size);mode=im.mode
 m=dict(tool='image_gen.imagegen built-in',source=str(G/s['source']),sha256=hashlib.sha256((p/'concept.png').read_bytes()).hexdigest(),dimensions=size,mode=mode,reference_role='Written brief, own family palette and structure; final generation without image inputs after tool errors',external_generation_inputs=False,decision_status='proposed' if s['id']=='concept-v4' else 'study_not_selected',production_status='concept',implementation_status='not_integrated')
 (p/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
old=F/'concept-v2/manifest.json';m=json.loads(old.read_text(encoding='utf-8'));m.update(decision_status='rejected',decision_note='Autor: Ficou muito amassado e empapelado');old.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
chart=json.loads((D/'chart.json').read_text(encoding='utf-8'));P=F/'concept-v4'
for n in chart['nodes']:
 if n['id']=='tramassauro':n.update(art=Path(os.path.relpath(P/'concept.png',D)).as_posix(),brief=Path(os.path.relpath(P/'brief.md',D)).as_posix(),identity='Bípede de volumes contínuos e antebraço assimétrico de membrana tensionada, uma vela dorsal e duas abas.',story='Aprende a controlar a tensão do antebraço mantendo base e gesto claros.',revision='concept-v4',decision_status='proposed')
chart['scope']='Bebê e criança preservadas; jovem v4 em avaliação após rejeição do excesso de origami; adulto anterior rejeitado.'
(D/'chart.json').write_text(json.dumps(chart,ensure_ascii=False,indent=2),encoding='utf-8')
cards=[];sheet=Image.new('RGB',(1800,1400),'#faf7f0');draw=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24)
for k,n in enumerate(chart['nodes']):
 status='Histórico REJEITADO' if n['decision_status']=='rejected' else 'Preservado' if n['stage']<3 else 'v4 em avaliação'
 with Image.open(D/n['art']) as im:t=ImageOps.contain(im.convert('RGB'),(850,590));x=k%2*900;y=k//2*700;sheet.paste(t,(x+(900-t.width)//2,y+75+(590-t.height)//2))
 draw.text((x+20,y+15),n['name']+' · '+status,font=font,fill='#282443')
 cards.append('<article><h2>'+escape(n['name'])+'</h2><b>'+status+'</b><a href="'+n['art']+'"><img src="'+n['art']+'" alt="'+escape(n['identity'])+'"></a><p>'+escape(n['story'])+'</p></article>')
sheet.save(D/'familia.png')
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Tramino · equilíbrio de matéria</title><style>body{max-width:1250px;margin:auto;padding:24px;background:#faf5e9;color:#282443;font:18px/1.6 system-ui}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}article{padding:24px;background:white}img{width:100%;height:430px;object-fit:contain}a:focus-visible{outline:3px solid #cf4c2e}@media(max-width:700px){.grid{grid-template-columns:1fr}}</style><h1>Tramino · criatura e pipa em equilíbrio</h1><p>Jovem v4 em avaliação. Versão amassada rejeitada; bebê/criança preservadas. Adulto anterior exibido somente como histórico rejeitado.</p><a href="CHART.md">Decisões</a><main class="grid">'+''.join(cards)+'</main></html>',encoding='utf-8')
note='\n\n## Limpeza v4 — meio-termo\n\nAutor rejeitou aparência amassada/empapelada da jovem v2. V3 simplificou demais; nova candidata v4 combina volume contínuo de criatura e um conjunto focal de tensão no antebraço. Em avaliação. Geração textual final após bloqueios automáticos da ferramenta; sem alegação de preservação exata da criança.\n'
p=D/'CHART.md';t=p.read_text(encoding='utf-8')
if '## Limpeza v4' not in t:p.write_text(t+note,encoding='utf-8')
print('Jovem v4 registrada; versões anteriores preservadas.')
hook=R/'art/creatures/tramino-family-v1/tramassauro/rostos-v1/registrar.py'
exec(compile(hook.read_text(encoding='utf-8'),str(hook),'exec'),{'__file__':str(hook)})
