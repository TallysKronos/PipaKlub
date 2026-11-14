from pathlib import Path
import json
D=Path(__file__).resolve().parent;R=D.parents[2];A=R/'art/creatures/hipolanterna-family-v1'
note='Autor: “aprovados! agora inicie uma line pra um bicho preguiça + cacau”, após a conclusão do bebê. Aprovação visual das quatro formas: Pevidim, Cavalume, Hipomoranga e Hipolanterna. Sem aprovação técnica ou integração.'
p=D/'chart.json';c=json.loads(p.read_text(encoding='utf-8'))
for n in c['nodes']:
 n.update(decision_status='approved',approval_note=note)
 mp=(D/n['art']).parent/'manifest.json';m=json.loads(mp.read_text(encoding='utf-8'));m.update(decision_status='approved',approval_note=note);mp.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
c['scope']='Quatro concepts aprovados visualmente; nomes e mecânicas propostos, sem integração.';p.write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf-8')
for p in [D/'CHART.md',A/'DECISOES.md']:
 t=p.read_text(encoding='utf-8')
 if note not in t:p.write_text(t+'\n\n## Aprovação visual\n'+note+'\n',encoding='utf-8')
p=D/'index.html';t=p.read_text(encoding='utf-8').replace('Quatro concepts em avaliação. Sem integração.','Quatro concepts aprovados visualmente. Nomes e mecânicas propostos; sem integração.')
for n in c['nodes']:t=t.replace(n['name']+' · '+n['maturity']+'</h2>',n['name']+' · '+n['maturity']+' — Aprovado</h2>')
p.write_text(t,encoding='utf-8')
