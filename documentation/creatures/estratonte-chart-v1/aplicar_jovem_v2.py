from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageFont
import json,hashlib,shutil,os
D=Path(__file__).resolve().parent;R=D.parents[2];A=R/'art/creatures/estratonte-family-v1';P=A/'brontela/concept-v2'
source=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-79b18d69-836a-4619-ad2a-ba61cb3d868d.png')
shutil.copy2(source,P/'concept.png')
anatomy='Quadrúpede esguio de quatro pernas longas, pescoço projetado à frente, tórax aberto de costelas-varetas e estreita quilha de papel ventral; sem painéis de abrigo.'
story='Aprende a alcançar e puxar linhas com o pescoço e o corpo tensionados antes de sustentar uma cobertura adulta.'
(P/'brief.md').write_text('# Brontela — jovem v2\n\n## Pedido do autor\nAlterar o jovem porque ficou muito parecido com o adulto. Preservar demais artes.\n\n## Proposta\n'+anatomy+' Ação: alcançar e tracionar. '+story+' Custo: armação leve precisa manter alinhamento e oferece pouca proteção. Vãos abertos, dois tirantes de cobre, pernas delgadas e pescoço baixo substituem ventre volumoso, apoios pesados e pequenos escudos. Cores lavanda/marfim/índigo/verde-água, olho verde e rabiola bipartida mantêm o parentesco. Nome, mecânicas e vínculo narrativo seguem propostos.\n',encoding='utf-8')
(P/'revisao.md').write_text('# Conferência visual\n\nQuatro pernas visíveis com raízes distintas; uma dianteira em passada, outras três apoiadas. Pescoço deitado em diagonal, tórax aberto, sem ventre inflado nem escudos dos ombros. Costelas e tirantes conectados ao esqueleto; faixa estreita de papel no ventre e sob o pescoço. Cauda completa termina em fio e duas flâmulas. Crânio conserva fenestra e olho verde. Adulto permanece no arquivo original, sem edição.\n\nSilhueta agora contrasta com adulta larga de cobertura. A quantidade de papel visível é menor; avaliar se a quilha precisa ganhar área sem recriar a barriga ou cobertura. Função de tração ainda não testada em ação. Sombreamento suave residual. Concept em avaliação, não rig ou pixel art técnico.\n',encoding='utf-8')
with Image.open(P/'concept.png') as im:size=list(im.size);mode=im.mode
(P/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen built-in',source=str(source),sha256=hashlib.sha256((P/'concept.png').read_bytes()).hexdigest(),dimensions=size,mode=mode,alpha=False,prompt='prompt.txt',reference_role='Own adolescent v1 redesign; adult inspected for contrast, not edited',external_generation_inputs=False,decision_status='proposed',production_status='concept',implementation_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
p=A/'brontela/concept-v1/manifest.json';m=json.loads(p.read_text(encoding='utf-8'));m.update(decision_status='superseded',decision_note='Autor pediu mudança: jovem muito parecido com adulto. Original preservado.');p.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
p=D/'chart.json';c=json.loads(p.read_text(encoding='utf-8'))
for n in c['nodes']:
 if n['id']=='brontela':n.update(art=Path(os.path.relpath(P/'concept.png',D)).as_posix(),brief=Path(os.path.relpath(P/'brief.md',D)).as_posix(),identity=anatomy,story=story,action='Alcançar e tracionar',tradeoff='Pouca proteção; precisa alinhar pescoço e corpo sob tensão.',decision_status='proposed',revision='concept-v2')
for e in c['edges']:
 if e['to']=='brontela':e['reason']='Apoios crescem e estrutura leve aprende a alcançar e tracionar linhas.'
 if e['from']=='brontela':e['reason']='Controle de tensão amadurece: corpo se reforça para sustentar cobertura e abrigar.'
p.write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf-8')
p=D/'index.html';t=p.read_text(encoding='utf-8').replace('brontela/concept-v1/','brontela/concept-v2/').replace('Brontela · Jovem</h2>','Brontela · Jovem v2</h2>').replace('Aprende a repartir a tensão entre patas, costelas e membranas.',story).replace('Amparar','Alcançar e tracionar').replace('Precisa recolher os painéis em corredores estreitos.','Pouca proteção; precisa alinhar pescoço e corpo sob tensão.');p.write_text(t,encoding='utf-8')
note='\n\n## Jovem v2 — revisão solicitada\nAutor pediu mudar a jovem pela semelhança com adulta. Nova estrutura esguia de tração, sem ventre volumoso nem escudos, pescoço à frente, pernas longas e vãos nas costelas. Adulta, bebê e criança preservados. Nova arte em avaliação.\n'
for p in [D/'CHART.md',A/'DECISOES.md']:
 t=p.read_text(encoding='utf-8')
 if '## Jovem v2' not in t:p.write_text(t+note,encoding='utf-8')
sheet=Image.new('RGB',(1800,1450),'#f3f5f0');dr=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',28)
for i,n in enumerate(c['nodes']):
 x=i%2*900;y=i//2*725
 with Image.open(D/n['art']) as im:tile=ImageOps.contain(im.convert('RGB'),(850,610));sheet.paste(tile,(x+(900-tile.width)//2,y+80+(610-tile.height)//2))
 dr.text((x+24,y+24),n['name']+' · '+n['maturity']+(' v2' if n['id']=='brontela' else '')+' (proposta)',font=font,fill='#383456')
sheet.save(D/'familia.png')
print('Jovem v2 salvo e chart atualizado; outras três artes preservadas.')
if (D/'aplicar_jovem_v3.py').exists():
 import runpy
 runpy.run_path(str(D/'aplicar_jovem_v3.py'))
