from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageFont
import json,hashlib,shutil,os
D=Path(__file__).resolve().parent;R=D.parents[2];A=R/'art/creatures/estratonte-family-v1';P=A/'brontela/concept-v3'
source=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-d84e3b02-34ed-4119-8c73-87f1c3b241e1.png');shutil.copy2(source,P/'concept.png')
identity='Quadrúpede intermediário de ventre arredondado, pescoço de quatro grandes segmentos, três costelas e pequena cobertura dorsal em formação.'
story='Começa a sustentar um pequeno painel dorsal com as costelas; esse painel se amplia no abrigo adulto.'
(P/'brief.md').write_text('# Brontela v3 — transição de maturidade\n\nAutor rejeitou a jovem esguia e pediu um meio-termo entre criança e adulta. '+identity+' '+story+' Preservar ventre e gentileza da criança; alongar moderadamente pescoço/patas, reduzir proporcionalmente cabeça/olhos. Cobertura estreita e parcial, sem as grandes abas da adulta. Função volta a sustentar/proteger em aprendizado. Nomes e mecânicas propostos.\n',encoding='utf-8')
(P/'revisao.md').write_text('# Conferência\n\nQuatro patas conectadas, uma dianteira levantada e três apoios. Ventre de papel volta, pescoço tem quatro segmentos grandes, cabeça proporcionalmente menor. Três costelas sustentam painel dorsal estreito com três nós; vão sob painel visível. Não há escudos largos ou cobertura adulta completa. Rabiola permanece com fio e duas flâmulas. Criança, bebê e adulta não editados.\n\nNova proposta responde ao pedido de transição, em avaliação. Suaves sombras residuais; não é rig, pixel art técnico ou integração. V2 preservada como direção rejeitada.\n',encoding='utf-8')
with Image.open(P/'concept.png') as im:size=list(im.size);mode=im.mode
(P/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen built-in',source=str(source),sha256=hashlib.sha256((P/'concept.png').read_bytes()).hexdigest(),dimensions=size,mode=mode,alpha=False,prompt='prompt.txt',reference_role='Own child and adult as endpoints; no external images',external_generation_inputs=False,decision_status='proposed',production_status='concept',implementation_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
p=A/'brontela/concept-v2/manifest.json';m=json.loads(p.read_text(encoding='utf-8'));m.update(decision_status='rejected',decision_note='Autor: “não gostei ainda”, pediu meio-termo entre criança e adulta.');p.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
p=D/'chart.json';c=json.loads(p.read_text(encoding='utf-8'))
for n in c['nodes']:
 if n['id']=='brontela':n.update(art=Path(os.path.relpath(P/'concept.png',D)).as_posix(),brief=Path(os.path.relpath(P/'brief.md',D)).as_posix(),identity=identity,story=story,action='Aprender a sustentar',tradeoff='Painel parcial protege pouca área e ainda exige equilíbrio.',decision_status='proposed',revision='concept-v3')
for e in c['edges']:
 if e['to']=='brontela':e['reason']='Corpo amadurece moderadamente e costelas começam a sustentar pequeno painel dorsal.'
 if e['from']=='brontela':e['reason']='Painel parcial se amplia em cobertura; torso e apoios se reforçam para abrigar.'
p.write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf-8')
p=D/'index.html';t=p.read_text(encoding='utf-8').replace('brontela/concept-v2/','brontela/concept-v3/').replace('Jovem v2','Jovem v3').replace('Aprende a alcançar e puxar linhas com o pescoço e o corpo tensionados antes de sustentar uma cobertura adulta.',story).replace('Alcançar e tracionar','Aprender a sustentar').replace('Pouca proteção; precisa alinhar pescoço e corpo sob tensão.','Painel parcial protege pouca área e ainda exige equilíbrio.');p.write_text(t,encoding='utf-8')
note='\n\n## Jovem v3 — meio-termo solicitado\nAutor rejeitou v2 e pediu transição entre criança e adulta. Nova jovem mantém ventre arredondado, alonga moderadamente pescoço e patas e inicia pequeno painel dorsal, sem a cobertura completa. Demais formas preservadas. V3 em avaliação.\n'
for p in [D/'CHART.md',A/'DECISOES.md']:
 t=p.read_text(encoding='utf-8')
 if '## Jovem v3' not in t:p.write_text(t+note,encoding='utf-8')
sheet=Image.new('RGB',(1800,1450),'#f3f5f0');dr=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',28)
for i,n in enumerate(c['nodes']):
 x=i%2*900;y=i//2*725
 with Image.open(D/n['art']) as im:tile=ImageOps.contain(im.convert('RGB'),(850,610));sheet.paste(tile,(x+(900-tile.width)//2,y+80+(610-tile.height)//2))
 dr.text((x+24,y+24),n['name']+' · '+n['maturity']+(' v3' if n['id']=='brontela' else '')+' (proposta)',font=font,fill='#383456')
sheet.save(D/'familia.png')
print('Jovem v3 salva e comparativo atualizado.')
if (D/'aprovar.py').exists():
 import runpy
 runpy.run_path(str(D/'aprovar.py'))
