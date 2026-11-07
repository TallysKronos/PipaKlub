from pathlib import Path
import json
D=Path(__file__).resolve().parent
note='2026-11-04 — autor: “Aprovado”, após apresentação da linha completa do javali e antes de pedir o estudo de quadrúpedes. Escopo: quatro designs visuais, sem aprovar regras.'
p=D/'chart.json';v=json.loads(p.read_text(encoding='utf-8'));v['scope']='Quatro designs visuais aprovados; regras propostas; sem integração.'
for n in v['nodes']:
    n['decision_status']='approved';n['approval_note']=note
    F=(D/n['art']).resolve().parent;m=F/'manifest.json';q=json.loads(m.read_text(encoding='utf-8'));q['decision_status']='approved';q['approval_note']=note;m.write_text(json.dumps(q,ensure_ascii=False,indent=2),encoding='utf-8')
    p2=F/'revisao.md';s=p2.read_text(encoding='utf-8')
    if note not in s:p2.write_text(s+'\n## Estado atual\n'+note+'\n',encoding='utf-8')
p.write_text(json.dumps(v,ensure_ascii=False,indent=2),encoding='utf-8')
for p in [D/'CHART.md',D.parents[2]/'art/creatures/javali-guerreiro/DECISOES.md']:
    s=p.read_text(encoding='utf-8')
    if note not in s:p.write_text(s+'\n## Aprovação atual\n'+note+'\n',encoding='utf-8')
p=D/'index.html';p.write_text(p.read_text(encoding='utf-8').replace('Quatro concepts propostos.','Quatro designs visuais aprovados; regras propostas.'),encoding='utf-8')
