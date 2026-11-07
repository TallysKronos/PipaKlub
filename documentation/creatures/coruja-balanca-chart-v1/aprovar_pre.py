from pathlib import Path
import json
D=Path(__file__).resolve().parent
note='2026-11-04 — autor: “ok aprovado”, após a apresentação das três pré-evoluções. Escopo: bebê, criança e jovem visuais. Mecânicas e nomes continuam propostos.'
p=D/'chart.json';v=json.loads(p.read_text(encoding='utf-8'));v['scope']='Quatro designs visuais aprovados; regras propostas; sem integração.'
for n in v['nodes']:
    if n['stage']==4:continue
    n['decision_status']='approved';n['approval_note']=note
    F=(D/n['art']).resolve().parent;m=F/'manifest.json';q=json.loads(m.read_text(encoding='utf-8'));q['decision_status']='approved';q['approval_note']=note;m.write_text(json.dumps(q,ensure_ascii=False,indent=2),encoding='utf-8')
    p2=F/'revisao.md';s=p2.read_text(encoding='utf-8').replace('Concept proposto; sem aprovação destas três novas formas.','Concept visual aprovado pelo autor.')
    if note not in s:p2.write_text(s+'\n'+note+'\n',encoding='utf-8')
p.write_text(json.dumps(v,ensure_ascii=False,indent=2),encoding='utf-8')
p=D/'index.html';p.write_text(p.read_text(encoding='utf-8').replace('Adulto aprovado, três pré-evoluções propostas.','Quatro designs visuais aprovados; regras propostas.').replace('<p>proposed</p>','<p>approved</p>'),encoding='utf-8')
for p in [D/'CHART.md',D.parents[2]/'art/creatures/coruja-balanca/DECISOES.md']:
    s=p.read_text(encoding='utf-8')
    if note not in s:p.write_text(s+'\n## Aprovação atual\n'+note+'\n',encoding='utf-8')
