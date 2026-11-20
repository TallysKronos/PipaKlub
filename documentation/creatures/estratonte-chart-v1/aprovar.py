from pathlib import Path
import json
D=Path(__file__).resolve().parent;R=D.parents[2];A=R/'art/creatures/estratonte-family-v1'
note='Autor: “Aprovados”, após revisão da jovem v3 como transição entre criança e adulta. Aprovação visual da família atual: Seixim v1, Vertim v1, Brontela v3 e Estratonte v1. Não aprova rigs, mecânicas ou integração.'
p=D/'chart.json';c=json.loads(p.read_text(encoding='utf-8'))
for n in c['nodes']:
 n.update(decision_status='approved',approval_note=note)
 mp=(D/n['art']).parent/'manifest.json';m=json.loads(mp.read_text(encoding='utf-8'));m.update(decision_status='approved',approval_note=note);mp.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
c['scope']='Quatro concepts aprovados visualmente, jovem atual v3. Nomes e mecânicas propostos; sem integração.';p.write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf-8')
for p in [D/'CHART.md',A/'DECISOES.md']:
 t=p.read_text(encoding='utf-8')
 if note not in t:p.write_text(t+'\n\n## Aprovação da família\n'+note+'\n',encoding='utf-8')
p=D/'index.html';t=p.read_text(encoding='utf-8').replace('Quatro conceitos propostos. Sem integração.','Quatro concepts aprovados visualmente. Jovem atual v3; nomes e mecânicas propostos; sem integração.')
for n in c['nodes']:
 label=n['name']+' · '+n['maturity']+(' v3' if n['id']=='brontela' else '')
 t=t.replace(label+'</h2>',label+' — Aprovado</h2>')
p.write_text(t,encoding='utf-8')
print('Aprovação visual da família atual registrada.')
