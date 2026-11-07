from pathlib import Path
import json
D=Path(__file__).resolve().parent
R=D.parents[2]
note='2026-11-04: autor disse “Aprovados!” ao solicitar em seguida a linha da anaconda. Escopo: quatro designs visuais do mico; nomes e regras continuam propostos.'
p=D/'chart.json'; chart=json.loads(p.read_text(encoding='utf-8'))
chart['scope']='Quatro concepts visuais aprovados; nomes e mecânicas propostos; sem integração.'
for n in chart['nodes']:
    n['decision_status']='approved'; n['approval_note']=note
    f=(D/n['art']).resolve().parent
    m=f/'manifest.json'; data=json.loads(m.read_text(encoding='utf-8')); data['decision_status']='approved'; data['approval_note']=note
    m.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
    review=f/'revisao.md'; s=review.read_text(encoding='utf-8').replace('Concept proposto; sem aprovação.','Concept visual aprovado pelo autor; regras e nome propostos.')
    if note not in s: review.write_text(s+'\n'+note+'\n',encoding='utf-8')
p.write_text(json.dumps(chart,ensure_ascii=False,indent=2),encoding='utf-8')
for p in [D/'CHART.md',R/'art/creatures/mico-samurai-family-v1/DECISOES.md']:
    s=p.read_text(encoding='utf-8')
    if note not in s: p.write_text(s+'\n## Aprovação atual\n'+note+'\n',encoding='utf-8')
p=D/'index.html'; s=p.read_text(encoding='utf-8').replace('Concepts propostos.','Quatro concepts visuais aprovados; nomes e mecânicas propostos.')
p.write_text(s,encoding='utf-8')
