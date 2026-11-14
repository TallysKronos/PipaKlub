from pathlib import Path
import json
D=Path(__file__).resolve().parent
note='2026-11-04 — autor: “ótimo estão todos aprovados”, antes de pedir o guerreiro coruja. Aprovação dos quatro designs; funções propostas do retrato e regras não se tornam cânone por esta aprovação visual.'
p=D/'chart.json'; data=json.loads(p.read_text(encoding='utf-8')); data['scope']='Quatro concepts visuais aprovados; mecânicas propostas; sem integração.'
for n in data['nodes']:
    n['decision_status']='approved'; n['approval_note']=note
    f=(D/n['art']).resolve().parent
    m=f/'manifest.json'; v=json.loads(m.read_text(encoding='utf-8'));v['decision_status']='approved';v['approval_note']=note;m.write_text(json.dumps(v,ensure_ascii=False,indent=2),encoding='utf-8')
    r=f/'revisao.md';s=r.read_text(encoding='utf-8').replace('Estado: proposto.','Estado visual: aprovado pelo autor.')
    if note not in s:r.write_text(s+'\n'+note+'\n',encoding='utf-8')
p.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
for p in [D/'CHART.md',D.parents[2]/'art/creatures/anaconda-retrato-family-v1/DECISOES.md']:
    s=p.read_text(encoding='utf-8')
    if note not in s:p.write_text(s+'\n## Aprovação atual\n'+note+'\n',encoding='utf-8')
p=D/'index.html';p.write_text(p.read_text(encoding='utf-8').replace('Quatro concepts propostos.','Quatro concepts visuais aprovados; regras propostas.'),encoding='utf-8')
