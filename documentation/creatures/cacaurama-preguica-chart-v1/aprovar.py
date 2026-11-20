from pathlib import Path
import json
from PIL import Image,ImageOps,ImageDraw
D=Path(__file__).resolve().parent
note='Autor: "aprovado", em 2026-11-04, após apresentação da linha completa. Aprovação visual dos quatro estágios; nomes, mecânicas e integração não incluídos.'
chart=json.loads((D/'chart.json').read_text(encoding='utf-8'))
sheet=Image.new('RGB',(2000,650),'white')
for i,n in enumerate(chart['nodes']):
    n['decision_status']='approved'
    n['approval_note']=note
    art=(D/n['art']).resolve()
    manifest=art.parent/'manifest.json'
    m=json.loads(manifest.read_text(encoding='utf-8'))
    m.update(decision_status='approved',approval_note=note)
    manifest.write_text(json.dumps(m,indent=2,ensure_ascii=False),encoding='utf-8')
    thumb=ImageOps.contain(Image.open(art).convert('RGB'),(480,570))
    sheet.paste(thumb,(500*i+(500-thumb.width)//2,50+(570-thumb.height)//2))
    label=['Bebe compartilhado','Crianca','Jovem','Adulto'][i]+' / aprovado'
    ImageDraw.Draw(sheet).text((500*i+20,20),label,fill='black')
    review=art.parent/'revisao.md'
    content=review.read_text(encoding='utf-8')
    if note not in content: review.write_text(content+'\n\n## Aprovação visual posterior\n\n'+note+'\n',encoding='utf-8')
(D/'chart.json').write_text(json.dumps(chart,indent=2,ensure_ascii=False),encoding='utf-8')
sheet.save(D/'familia.png')
for path in [D/'CHART.md',D.parents[2]/'art/creatures/cacaurama-family-v1/DECISOES.md']:
    content=path.read_text(encoding='utf-8')
    if note not in content: path.write_text(content+'\n\n## Aprovação do ramo preguiça — 2026-11-04\n\n'+note+' A rota vegetal anterior não foi aprovada por esta decisão.\n',encoding='utf-8')
p=D/'index.html'
p.write_text(p.read_text(encoding='utf-8').replace('Concepts propostos; nomes pendentes.','Linha visual aprovada em 04/11/2026; nomes e regras pendentes.'),encoding='utf-8')
print('Aprovação visual registrada nos quatro nós, manifestos, revisões e apresentação.')
