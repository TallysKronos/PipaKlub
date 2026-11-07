from pathlib import Path
import json
from PIL import Image,ImageOps,ImageDraw
D=Path(__file__).resolve().parent
A=D.parents[2]/'art/creatures/gata-lunar-family-v1'
note='Autor: "Aprovadissimos", em 2026-11-04, após apresentação dos quatro estágios. Aprovação visual da linha completa; nomes finais, mecânicas e integração não incluídos.'
chart=json.loads((D/'chart.json').read_text(encoding='utf-8'))
sheet=Image.new('RGB',(2200,850),'white')
for i,n in enumerate(chart['nodes']):
    n.update(decision_status='approved',approval_note=note)
    F=(D/n['art']).resolve().parent
    m=json.loads((F/'manifest.json').read_text(encoding='utf-8'));m.update(decision_status='approved',approval_note=note)
    (F/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
    p=F/'revisao.md';s=p.read_text(encoding='utf-8')
    if note not in s:p.write_text(s+'\n\n## Aprovação visual posterior\n\n'+note+'\n',encoding='utf-8')
    thumb=ImageOps.contain(Image.open(F/'concept.png').convert('RGB'),(530,760));sheet.paste(thumb,(550*i+(550-thumb.width)//2,60+(760-thumb.height)//2))
    ImageDraw.Draw(sheet).text((550*i+18,20),['Bebe / aprovado','Crianca / aprovada','Jovem / aprovado','Adulta / aprovada'][i],fill='black')
(D/'chart.json').write_text(json.dumps(chart,ensure_ascii=False,indent=2),encoding='utf-8')
sheet.save(D/'familia.png')
for p in [D/'CHART.md',A/'DECISOES.md']:
    s=p.read_text(encoding='utf-8')
    if note not in s:p.write_text(s+'\n\n## Aprovação visual — 2026-11-04\n\n'+note+' As notas anteriores de proposta permanecem como histórico.\n',encoding='utf-8')
p=D/'index.html';p.write_text(p.read_text(encoding='utf-8').replace('Concepts propostos.','Linha visual aprovada em 04/11/2026; nomes e regras pendentes.'),encoding='utf-8')
print('Aprovação visual registrada nos quatro estágios.')
