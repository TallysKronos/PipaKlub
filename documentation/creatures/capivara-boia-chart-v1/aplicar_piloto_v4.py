from pathlib import Path
import json,hashlib,shutil,os
from PIL import Image,ImageOps,ImageDraw,ImageFont
D=Path(__file__).resolve().parent;R=D.parents[2];folder=R/'art/creatures/capivara-boia-family-v1/gotim/concept-v4'
src=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-595a072e-f4f0-4c68-9e07-04020f967a1a.png');shutil.copy2(src,folder/'concept.png')
with Image.open(folder/'concept.png') as im:m=dict(id='gotim',tool='image_gen.imagegen',source=str(src),width=im.width,height=im.height,mode=im.mode,alpha='A'in im.getbands(),sha256=hashlib.sha256((folder/'concept.png').read_bytes()).hexdigest(),references=[dict(path='art/creatures/capivara-boia/child-manga-v2/concept.png',role='identidade e acabamento próprios')],decision_status='proposed',production_status='concept',implementation='não integrado',external_images_used_for_generation=False,technical_pixel_art=False,prompt='prompt.txt',brief='brief.md',review='revisao.md',sheet='Uma vista principal e dois estudos de gesto; não são frames de animação.')
(folder/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
p=D/'chart.json';c=json.loads(p.read_text(encoding='utf-8'));page=(D/'index.html').read_text(encoding='utf-8');rel=lambda p:os.path.relpath(p,D).replace('\\','/')
for n in c['nodes']:
 if n['id']=='gotim':
  oldart=n['art'];oldbrief=n['brief'];n.update(art=rel(folder/'concept.png'),brief=rel(folder/'brief.md'),decision_status='proposed',identity='Pequeno corpo de papel tensionado em gota assimétrica, base flexível em crescente e rabiola com uma aba.',story='Aprende a recuperar equilíbrio pela dobra do próprio corpo.');n.pop('decision_note',None);page=page.replace(oldart,n['art']).replace(oldbrief,n['brief'])
p.write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf-8')
old='<p><strong>Bebê concept-v3 rejeitado pelo autor em 04/11/2026.</strong> Próxima criação depende do estudo Baby/Rookie; demais formas não receberam aprovação automática.</p>'
page=page.replace(old,'<p><strong>Novo piloto Gotim concept-v4 em avaliação.</strong> Corpo tensionado e estudos de equilíbrio, após benchmark Baby/Rookie. A versão v3 permanece rejeitada e preservada.</p>');(D/'index.html').write_text(page,encoding='utf-8')
sheet=Image.new('RGB',(1600,1400),'white');draw=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',25)
for i,n in enumerate(c['nodes']):
 with Image.open(D/n['art']) as im:t=ImageOps.contain(im.convert('RGB'),(750,600),Image.Resampling.LANCZOS)
 t.save(D/'miniaturas'/(n['id']+'.png'));x=i%2*800;y=i//2*700;sheet.paste(t,(x+(800-t.width)//2,y+(610-t.height)//2));draw.text((x+24,y+632),n['name']+' · '+n['age'],font=font,fill='#164b43')
sheet.save(D/'familia.png')
note='2026-11-04: nova geração autorizada após estudo Baby/Rookie. Piloto atual Gotim concept-v4: corpo tensionado assimétrico e dois estudos de gesto; em avaliação. concept-v3 continua rejeitado. Criança, jovem e adulto não alterados nesta etapa.'
for p in [D/'CHART.md',R/'art/creatures/capivara-boia-family-v1/DECISOES.md']:
 s=p.read_text(encoding='utf-8')
 if note not in s:s+='\n'+note+'\n'
 p.write_text(s,encoding='utf-8')
print('Piloto v4 salvo e chart atualizado; originais preservados.')
