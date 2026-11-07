from pathlib import Path
import json,shutil,hashlib,os
from html import escape
from PIL import Image,ImageOps,ImageDraw,ImageFont
D=Path(__file__).resolve().parent;R=D.parents[2];F=R/'art/creatures/tramino-family-v1/tramassauro';P=F/'concept-v5'
S=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-9ee044b4-50fa-4f5d-a9db-5f54d8c8bce4.png')
if not(P/'concept.png').exists():shutil.copy2(S,P/'concept.png')
with Image.open(P/'concept.png') as im:size=list(im.size);mode=im.mode
(P/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen built-in',source=str(S),sha256=hashlib.sha256((P/'concept.png').read_bytes()).hexdigest(),dimensions=size,mode=mode,reference_role='Own selected head B, rostos-v1/b-espreita/concept.png',external_generation_inputs=False,decision_status='proposed',head_direction='B selected by author',production_status='concept',implementation_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
head=F/'rostos-v1/b-espreita/manifest.json';m=json.loads(head.read_text(encoding='utf-8'));m.update(decision_status='selected_by_author',selection_note='B foi a que ficou melhor, mas precisa de uma estrutura corporal que faça sentido também.',selection_scope='Direção facial B; corpo novo não aprovado.');head.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
chart=json.loads((D/'chart.json').read_text(encoding='utf-8'))
for n in chart['nodes']:
 if n['id']=='tramassauro':n.update(art=Path(os.path.relpath(P/'concept.png',D)).as_posix(),brief=Path(os.path.relpath(P/'brief.md',D)).as_posix(),identity='Réptil semiereto de focinho B longo, tronco inclinado, quadril forte e cauda de contrapeso; membrana afilada no antebraço.',story='Aprende a antecipar a passagem e interceptar com apoio, direção e tensão controlados.',decision_status='proposed',revision='concept-v5',head_direction='B selected',review_note='Direção facial B escolhida; corpo v5 em avaliação.')
chart['scope']='Bebê/criança preservadas; rosto B escolhido; corpo jovem v5 em avaliação. Adulto anterior rejeitado e pendente de reconstrução.'
(D/'chart.json').write_text(json.dumps(chart,ensure_ascii=False,indent=2),encoding='utf-8')
cards=[];sheet=Image.new('RGB',(1800,1400),'#faf7f0');draw=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24)
for k,n in enumerate(chart['nodes']):
 status='Histórico REJEITADO' if n['decision_status']=='rejected' else 'Preservado' if n['stage']<3 else 'Rosto B / corpo v5 em avaliação'
 with Image.open(D/n['art']) as im:t=ImageOps.contain(im.convert('RGB'),(850,590));x=k%2*900;y=k//2*700;sheet.paste(t,(x+(900-t.width)//2,y+75+(590-t.height)//2))
 draw.text((x+20,y+15),n['name']+' · '+status,font=font,fill='#282443')
 cards.append('<article><h2>'+escape(n['name'])+'</h2><b>'+status+'</b><a href="'+n['art']+'"><img src="'+n['art']+'" alt="'+escape(n['identity'])+'"></a><p>'+escape(n['story'])+'</p><a href="'+n['brief']+'">Brief</a></article>')
sheet.save(D/'familia.png')
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Tramino · cabeça B e corpo</title><style>body{max-width:1250px;margin:auto;padding:24px;background:#faf5e9;color:#282443;font:18px/1.6 system-ui}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}article{padding:24px;background:white}img{width:100%;height:430px;object-fit:contain}a:focus-visible{outline:3px solid #cf4c2e}@media(max-width:700px){.grid{grid-template-columns:1fr}}</style><h1>Tramino · uma anatomia para a cabeça B</h1><p>Direção facial B escolhida. Corpo v5 em avaliação; adulto anterior só como histórico rejeitado. Sem integração.</p><a href="CHART.md">Decisões</a><main class="grid">'+''.join(cards)+'</main></html>',encoding='utf-8')
note='\n\n## Cabeça B e corpo v5\n\nAutor escolheu B e pediu estrutura corporal coerente. Criado corpo semiereto inclinado, base do pescoço larga, quadril forte e cauda de contrapeso. Face escolhida não aprova automaticamente corpo v5. Em avaliação; sem integração.\n'
p=D/'CHART.md';text=p.read_text(encoding='utf-8')
if '## Cabeça B e corpo v5' not in text:p.write_text(text+note,encoding='utf-8')
print('Corpo v5 salvo; cabeça B registrada como direção selecionada.')
exec(compile((D/'aplicar_cabeca_c_v7.py').read_text(encoding='utf-8'),str(D/'aplicar_cabeca_c_v7.py'),'exec'),{'__file__':str(D/'aplicar_cabeca_c_v7.py')})
