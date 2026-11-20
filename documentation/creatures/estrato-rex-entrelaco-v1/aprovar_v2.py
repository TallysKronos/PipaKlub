from pathlib import Path
import json
D=Path(__file__).resolve().parent;R=D.parents[2];P=R/'art/creatures/paleorix/concept-v2'
note='Autor: “Aprovado”, após a apresentação da v2 esguia com máscara angular fechada. Aprovação visual do Paleórix v2; não aprova requisitos, duração, efeitos, rig ou integração.'
p=D/'chart.json';c=json.loads(p.read_text(encoding='utf-8'))
for n in c['nodes']:
 if n['id']=='paleorix':n.update(decision_status='approved',approval_note=note)
c['scope']='Parceiros e concept Paleórix v2 aprovados visualmente. Condições do Entrelaço e mecânicas indefinidas; sem integração.';p.write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf-8')
p=P/'manifest.json';m=json.loads(p.read_text(encoding='utf-8'));m.update(decision_status='approved',approval_note=note);p.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
for p in [D/'CHART.md',P/'revisao.md']:
 t=p.read_text(encoding='utf-8')
 if note not in t:p.write_text(t+'\n\n## Aprovação visual v2\n'+note+'\n',encoding='utf-8')
p=D/'index.html';t=p.read_text(encoding='utf-8').replace('Segunda direção esguia em avaliação; requisitos e mecânicas indefinidos.','Paleórix v2 esguio aprovado visualmente; requisitos e mecânicas indefinidos.').replace('<h2>Paleórix (proposto)</h2><p>Em avaliação</p>','<h2>Paleórix · v2 aprovada</h2><p>Aprovado visualmente</p>');p.write_text(t,encoding='utf-8')
print('Aprovação visual do Paleórix v2 registrada.')
