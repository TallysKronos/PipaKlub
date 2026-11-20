from pathlib import Path
import json,hashlib,shutil,os
from PIL import Image,ImageOps,ImageDraw,ImageFont
D=Path(__file__).resolve().parent;R=D.parents[2];folder=R/'art/creatures/capivara-boia/child-manga-v3'
src=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-0298d825-ffc0-4b62-ae85-4eac10d01fc6.png');shutil.copy2(src,folder/'concept.png')
with Image.open(folder/'concept.png') as im:m=dict(id='capivara-boia',name='Capiboia',stage=2,tool='image_gen.imagegen',source=str(src),width=im.width,height=im.height,mode=im.mode,sha256=hashlib.sha256((folder/'concept.png').read_bytes()).hexdigest(),references=[dict(path='art/creatures/capivara-boia-family-v1/gotim/concept-v4/concept.png',role='construção de bebê e parentesco'),dict(path='art/creatures/capivara-boia/child-manga-v2/concept.png',role='identidade anterior da criança')],decision_status='proposed',production_status='concept',implementation='não integrado',external_images_used_for_generation=False,technical_pixel_art=False,prompt='prompt.txt',brief='brief.md',review='revisao.md',limitation='Miniaturas simplificaram rabiola de três para duas abas; não são frames técnicos.')
(folder/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
p=D/'chart.json';c=json.loads(p.read_text(encoding='utf-8'));page=(D/'index.html').read_text(encoding='utf-8');rel=lambda p:os.path.relpath(p,D).replace('\\','/')
for n in c['nodes']:
 if n['id']=='capivara-boia':
  oldart=n['art'];oldbrief=n['brief'];n.update(art=rel(folder/'concept.png'),brief=rel(folder/'brief.md'),decision_status='proposed',identity='Corpo baixo de papel aquático com dobra de flutuação integrada, quatro apoios palmados, uma quilha-vela e três abas na rabiola principal.',story='Aprende a sustentar-se em terra e dirigir o primeiro impulso na água com o próprio corpo.');page=page.replace(oldart,n['art']).replace(oldbrief,n['brief'])
p.write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf-8');(D/'index.html').write_text(page,encoding='utf-8')
sheet=Image.new('RGB',(1600,1400),'white');draw=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',25)
for i,n in enumerate(c['nodes']):
 with Image.open(D/n['art']) as im:t=ImageOps.contain(im.convert('RGB'),(750,600),Image.Resampling.LANCZOS)
 t.save(D/'miniaturas'/(n['id']+'.png'));x=i%2*800;y=i//2*700;sheet.paste(t,(x+(800-t.width)//2,y+(610-t.height)//2));draw.text((x+24,y+632),n['name']+' · '+n['age'],font=font,fill='#164b43')
sheet.save(D/'familia.png')
note='2026-11-04: usuário pediu nova criança após bebê de corpo tensionado. Candidato atual: child-manga-v3, com flutuação integrada e quilha dorsal. Concept em avaliação, sem alteração de jovem/adulto ou integração. Miniaturas não são frames técnicos.'
for p in [D/'CHART.md',R/'art/creatures/capivara-boia-family-v1/DECISOES.md']:
 s=p.read_text(encoding='utf-8')
 if note not in s:s+='\n'+note+'\n'
 p.write_text(s,encoding='utf-8')
print('Criança v3 salva e chart atualizado.')
