from pathlib import Path
import json
from PIL import Image,ImageOps,ImageDraw
D=Path(__file__).resolve().parent;A=D.parents[2]/'art/creatures/urso-polar-family-v1'
note='Autor: "Aprovadissimo", em 2026-11-04, após a revisão da cabeça. Aprovação visual do adulto Borealvo concept-v2; não estendida às outras formas, nomes ou mecânicas.'
chart=json.loads((D/'chart.json').read_text(encoding='utf-8'))
n=next(n for n in chart['nodes'] if n['id']=='borealvo');n.update(decision_status='approved',approval_note=note)
F=(D/n['art']).resolve().parent
m=json.loads((F/'manifest.json').read_text(encoding='utf-8'));m.update(decision_status='approved',approval_note=note)
(F/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
(D/'chart.json').write_text(json.dumps(chart,ensure_ascii=False,indent=2),encoding='utf-8')
for p in [F/'revisao.md',D/'CHART.md',A/'DECISOES.md']:
    s=p.read_text(encoding='utf-8')
    if note not in s:p.write_text(s+'\n\n## Aprovação visual posterior\n\n'+note+'\n',encoding='utf-8')
sheet=Image.new('RGB',(2200,850),'white')
for i,n in enumerate(chart['nodes']):
    thumb=ImageOps.contain(Image.open(D/n['art']).convert('RGB'),(530,760));sheet.paste(thumb,(550*i+(550-thumb.width)//2,60+(760-thumb.height)//2))
    ImageDraw.Draw(sheet).text((550*i+18,20),['Bebe / proposta','Crianca / proposta','Jovem / proposta','Adulto v2 / aprovado'][i],fill='black')
sheet.save(D/'familia.png')
p=D/'index.html';p.write_text(p.read_text(encoding='utf-8').replace('Concepts propostos.','Adulto v2 aprovado; demais formas em proposta.'),encoding='utf-8')
print('Aprovação visual do adulto v2 registrada.')
