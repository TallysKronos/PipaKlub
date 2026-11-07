from pathlib import Path
import json
from PIL import Image,ImageOps,ImageDraw
D=Path(__file__).resolve().parent
R=D.parents[2]
A=R/'art/creatures/gambalhote'
note='Autor: "Aprovadissimo", em 2026-11-04, após conferir o adulto com acabamento 2D manga v2. Aprovação visual do design e acabamento; sem aprovação de nomes, mecânicas ou integração.'
chart=json.loads((D/'chart.json').read_text(encoding='utf-8'))
n=next(n for n in chart['nodes'] if n['id']=='gambalhote-adult')
n.update(decision_status='approved',approval_note=note)
F=(D/n['art']).resolve().parent
m=json.loads((F/'manifest.json').read_text(encoding='utf-8'));m.update(decision_status='approved',approval_note=note)
(F/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
(D/'chart.json').write_text(json.dumps(chart,ensure_ascii=False,indent=2),encoding='utf-8')
for p in [F/'revisao.md',D/'CHART.md',A/'DECISOES.md']:
    s=p.read_text(encoding='utf-8')
    if note not in s:p.write_text(s+'\n\n## Aprovação final visual do adulto\n\n'+note+' A linha visual completa está aprovada; versões anteriores permanecem no histórico.\n',encoding='utf-8')
sheet=Image.new('RGB',(2200,850),'white')
for i,n in enumerate(chart['nodes']):
    thumb=ImageOps.contain(Image.open(D/n['art']).convert('RGB'),(530,760));sheet.paste(thumb,(550*i+(550-thumb.width)//2,60+(760-thumb.height)//2))
    ImageDraw.Draw(sheet).text((550*i+18,20),['Bebe / aprovado','Crianca / aprovada','Jovem / aprovado','Adulto v2 / aprovado'][i],fill='black')
sheet.save(D/'familia.png')
p=D/'index.html';s=p.read_text(encoding='utf-8').replace('Conferir estado no chart; bebê e jovem aprovados, adulto em acabamento v2.','Visual aprovado.').replace('Bebê → criança → jovem → adulto. Nomes dos destinos pendentes.','Linha visual aprovada: bebê → criança → jovem → adulto v2. Nomes e mecânicas pendentes.');p.write_text(s,encoding='utf-8')
print('Linha visual aprovada; adulto v2 registrado.')
