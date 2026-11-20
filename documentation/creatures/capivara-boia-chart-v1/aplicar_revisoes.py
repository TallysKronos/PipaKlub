from pathlib import Path
import json,os,shutil,hashlib
from PIL import Image,ImageOps,ImageDraw,ImageFont
D=Path(__file__).resolve().parent;R=D.parents[2];G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f');prompts=json.loads((D/'prompts-revisoes.json').read_text(encoding='utf-8'))
items=[('gotim','art/creatures/capivara-boia-family-v1/gotim/concept-v1','art/creatures/capivara-boia-family-v1/gotim/concept-v2','exec-fcc7678a-78a0-4cf2-bc4b-eb92c3612226.png','gotim2','Expressão mais gentil, olhos abertos e pequeno sorriso. Geometria anterior de cabeça preservada; histórico superado pela revisão 3.'),('gotim','art/creatures/capivara-boia-family-v1/gotim/concept-v2','art/creatures/capivara-boia-family-v1/gotim/concept-v3','exec-eff6b2f0-57bb-4648-a11d-086ff7fdf55b.png','gotim3','Losango vertical plano com quatro pontas, vareta em cruz, pequenas orelhas laterais e rosto simples simpático impresso no papel. Sem focinho volumétrico. Uma aba conectada ao nó inferior.'),('capivara-boia','art/creatures/capivara-boia/child-manga-v1','art/creatures/capivara-boia/child-manga-v2','exec-9bc1cc31-37c5-41fa-b4e8-9020692969e1.png','child2','Expressão amigável: olho aberto, sobrancelha relaxada e sorriso discreto. Quatro patas, vela e três abas da rabiola preservadas em leitura visual.')]
p=D/'chart.json';c=json.loads(p.read_text(encoding='utf-8'));page=(D/'index.html').read_text(encoding='utf-8')
for id,oldpath,newpath,src,key,review in items:
 old=R/oldpath;new=R/newpath;new.mkdir(parents=True,exist_ok=True);shutil.copy2(G/src,new/'concept.png');(new/'prompt.txt').write_text(prompts[key],encoding='utf-8')
 (new/'brief.md').write_text((old/'brief.md').read_text(encoding='utf-8')+'\n## Revisão solicitada pelo autor\n'+review+'\nVersão nova em avaliação; não integrada.\n',encoding='utf-8')
 (new/'revisao.md').write_text('# Conferência da revisão\n\n'+review+'\nEdição generativa: não promete preservação pixel a pixel. Contorno e cores da família mantidos. Não é rig ou pixel art técnico. Em avaliação visual.\n',encoding='utf-8')
 m=json.loads((old/'manifest.json').read_text(encoding='utf-8'));m.update(source=str(G/src),references=[oldpath+'/concept.png'],sha256=hashlib.sha256((new/'concept.png').read_bytes()).hexdigest(),decision_status='superseded' if key=='gotim2' else 'proposed',revision_reason=review)
 with Image.open(new/'concept.png') as im:m.update(width=im.width,height=im.height,mode=im.mode)
 (new/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
 oldmf=old/'manifest.json';om=json.loads(oldmf.read_text(encoding='utf-8'));om.update(decision_status='superseded',decision_note='Revisão posterior solicitada pelo autor; não registrar como aprovação.');oldmf.write_text(json.dumps(om,ensure_ascii=False,indent=2),encoding='utf-8')
 rel=lambda v:os.path.relpath(v,D).replace('\\','/')
 for n in c['nodes']:
  if n['id']==id:
   oldart=n['art'];oldbrief=n['brief'];n.update(art=rel(new/'concept.png'),brief=rel(new/'brief.md'),decision_status='proposed');page=page.replace(oldart,n['art']).replace(oldbrief,n['brief'])
   if key=='gotim3':n['identity']='Pipa viva em losango plano, quatro pontas e varetas cruzadas; pequenos sinais de capivara no rosto, duas orelhas e uma aba na rabiola.'
   elif key=='child2':n['identity']='Capivara de papel menta e creme com expressão acolhedora, quatro pés escuros, crescente de flutuação, vela curva e três abas na rabiola.'
 p.write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf-8')
(D/'index.html').write_text(page,encoding='utf-8')
sheet=Image.new('RGB',(1600,1400),'white');draw=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',25)
for i,n in enumerate(c['nodes']):
 with Image.open(D/n['art']) as im:t=ImageOps.contain(im.convert('RGB'),(750,600),Image.Resampling.LANCZOS)
 t.save(D/'miniaturas'/(n['id']+'.png'));x=i%2*800;y=i//2*700;sheet.paste(t,(x+(800-t.width)//2,y+(610-t.height)//2));draw.text((x+24,y+632),n['name']+' · '+n['age'],font=font,fill='#164b43')
sheet.save(D/'familia.png')
note='2026-11-04: bebê e criança receberam expressões mais gentis. Depois o autor pediu bebê com formato de pipa mais claro: Gotim concept-v3 é o candidato atual, Capiboia child-manga-v2 é a criança atual. Jovem e adulto não alterados. Sem aprovação das revisões ainda.'
for path in [D/'CHART.md',R/'art/creatures/capivara-boia-family-v1/DECISOES.md']:
 s=path.read_text(encoding='utf-8')
 if note not in s:s+='\n'+note+'\n'
 path.write_text(s,encoding='utf-8')
print('Atualizados bebê v3, criança v2 e comparação da família; histórico preservado.')
exec(compile((D/'registrar_rejeicao_baby.py').read_text(encoding='utf-8'),str(D/'registrar_rejeicao_baby.py'),'exec'),{'__file__':str(D/'registrar_rejeicao_baby.py')})
