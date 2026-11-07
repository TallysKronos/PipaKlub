from pathlib import Path
import json,hashlib,shutil,os
from html import escape
from PIL import Image,ImageOps,ImageDraw,ImageFont
D=Path(__file__).resolve().parent;R=D.parents[2];A=R/'art/creatures/tramino-family-v1';G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f');chart=json.loads((D/'chart.json').read_text(encoding='utf-8'))
for s in json.loads((D/'primeiros-estagios-v2.json').read_text(encoding='utf-8')):
 P=A/s['id']/'concept-v2';P.mkdir(parents=True,exist_ok=True)
 if not(P/'concept.png').exists():shutil.copy2(G/s['file'],P/'concept.png')
 (P/'prompt.txt').write_text(s['prompt'],encoding='utf-8')
 (P/'brief.md').write_text('# '+s['id']+' — redesign dos primeiros estágios\n\nAutor pediu refazer bebê e criança após a construção da jovem índigo/marfim e cavaleiro. Manter IDs e novas artes em avaliação. Paleta atual, cunha facial, nó e abas de rabiola substituem a antiga direção alaranjada como candidata atual. Não altera jovem ou adulto.\n\n'+('Bebê de corpo único e estabilizadores, uma etiqueta.' if s['id']=='traminho' else 'Criança bípede expressiva de quatro membros, rosto vivo e proteção leve sem armadura.')+'\n\nAs formas pequenas não carregam cristal, espada, capa rasgada ou viseira metálica da adulta. Papel em grandes superfícies tensionadas, volumes simples sem empapelar. Nomes provisórios e requisitos não definidos.',encoding='utf-8')
 (P/'revisao.md').write_text('# Conferência\n\n'+s['review']+'\n\nConcept 2D de fundo branco, leves transições suaves residuais, não pixel art de grade validada. Em avaliação, sem rig/animação/integração. Primeira geração bebê bloqueada pela ferramenta; final bebê gerado por texto. Criança final usou apenas jovem autoral como input.',encoding='utf-8')
 with Image.open(P/'concept.png') as im:size=list(im.size);mode=im.mode
 (P/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen built-in',source=str(G/s['file']),sha256=hashlib.sha256((P/'concept.png').read_bytes()).hexdigest(),dimensions=size,mode=mode,reference_role='Written own-family palette and face' if s['id']=='traminho' else 'Own young Tramassauro concept-v7 ancestry',external_generation_inputs=False,decision_status='proposed',production_status='concept',implementation_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
 old=A/s['id']/'concept-v1/manifest.json';m=json.loads(old.read_text(encoding='utf-8'));m.update(decision_status='historical_candidate',decision_note='Autor pediu nova bebê/criança após evolução da direção facial e de paleta; original preservado.');old.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
 for n in chart['nodes']:
  if n['id']==s['id']:
   n.update(art=Path(os.path.relpath(P/'concept.png',D)).as_posix(),brief=Path(os.path.relpath(P/'brief.md',D)).as_posix(),decision_status='proposed',revision='concept-v2',identity=('Corpo único índigo/marfim com focinho coral e uma aba de rabiola.' if s['id']=='traminho' else 'Pequeno réptil bípede índigo/coral com rosto em cunha marfim, olhos contidos e duas abas.'),review_note='Nova proposta para alinhar com jovem v7; sem aprovação automática.')
chart['scope']='Bebê/criança v2 redesenhadas em avaliação; jovem v7 aprovada; cavaleiro adulto v3 em avaliação. Sem integração.'
(D/'chart.json').write_text(json.dumps(chart,ensure_ascii=False,indent=2),encoding='utf-8')
cards=[];sheet=Image.new('RGB',(1800,1400),'#faf7f0');draw=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24)
for k,n in enumerate(chart['nodes']):
 status='Jovem aprovada' if n['id']=='tramassauro' else 'Em avaliação'
 with Image.open(D/n['art']) as im:t=ImageOps.contain(im.convert('RGB'),(850,590));x=k%2*900;y=k//2*700;sheet.paste(t,(x+(900-t.width)//2,y+75+(590-t.height)//2))
 draw.text((x+20,y+15),n['name']+' · '+status,font=font,fill='#282443')
 cards.append('<article><h2>'+escape(n['name'])+' · '+escape(n['age'])+'</h2><b>'+status+'</b><a href="'+n['art']+'"><img src="'+n['art']+'" alt="'+escape(n['identity'])+'"></a><p>'+escape(n['story'])+'</p><a href="'+n['brief']+'">Brief</a></article>')
sheet.save(D/'familia.png')
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Tramino · família índigo</title><style>body{max-width:1250px;margin:auto;padding:24px;background:#faf5e9;color:#282443;font:18px/1.6 system-ui}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}article{padding:24px;background:white}img{width:100%;height:430px;object-fit:contain}a:focus-visible{outline:3px solid #cf4c2e}@media(max-width:700px){.grid{grid-template-columns:1fr}}</style><h1>Tramino · a família índigo e marfim</h1><p>Bebê/criança v2 em avaliação, jovem aprovada, cavaleiro adulto com elmo dracônico em avaliação. Sem integração.</p><a href="CHART.md">Decisões</a> · <a href="familia.png">Comparativo</a><main class="grid">'+''.join(cards)+'</main></html>',encoding='utf-8')
note='\n\n## Bebê e criança refeitas — v2\n\nAutor pediu novas baby e child após o cavaleiro. Criadas duas candidatas em índigo/marfim/coral com parentesco da jovem v7. Bebê de corpo único e uma aba; criança bípede sem armadura adulta e duas abas. Novas artes em avaliação. Versões alaranjadas preservadas como histórico.\n'
p=D/'CHART.md';text=p.read_text(encoding='utf-8')
if '## Bebê e criança refeitas' not in text:p.write_text(text+note,encoding='utf-8')
print('Bebê e criança v2 salvas, jovem/adulto preservados e comparativo atualizado.')
import runpy
runpy.run_path(str(D/'registrar_aprovacao_primeiros_v2.py'))
