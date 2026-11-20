from pathlib import Path
import json
D=Path(__file__).resolve().parent;R=D.parents[2]
note='Autor: “Aprovados, e ja vamos passar pro próximo”, após bebê e criança v2; aprovação visual restrita a essas duas novas artes.'
p=D/'chart.json';c=json.loads(p.read_text(encoding='utf-8'))
for n in c['nodes']:
 if n['id'] in ['traminho','tramino']:
  n.update(decision_status='approved',approval_note=note)
  mpath=R/'art/creatures/tramino-family-v1'/n['id']/'concept-v2/manifest.json'
  m=json.loads(mpath.read_text(encoding='utf-8'));m.update(decision_status='approved',approval_note=note);mpath.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
c['scope']='Bebê e criança v2 aprovadas; jovem v7 aprovada; adulto v3 permanece em avaliação. Sem integração.'
p.write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf-8')
p=D/'CHART.md';t=p.read_text(encoding='utf-8')
if note not in t:p.write_text(t+'\n\n## Aprovação dos primeiros estágios\n'+note+' Adulto não aprovado por inferência.\n',encoding='utf-8')
p=D/'index.html';t=p.read_text(encoding='utf-8').replace('Bebê/criança v2 em avaliação, jovem aprovada','Bebê/criança v2 aprovadas, jovem aprovada')
for name in ['Traminho','Tramino']:
 start=t.find('<article><h2>'+name+' ·')
 if start>=0:
  end=t.find('</article>',start)
  t=t[:start]+t[start:end].replace('<b>Em avaliação</b>','<b>Aprovado pelo autor</b>')+t[end:]
p.write_text(t,encoding='utf-8')
