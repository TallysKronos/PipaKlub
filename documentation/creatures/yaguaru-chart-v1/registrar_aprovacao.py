from pathlib import Path
import json
D=Path(__file__).resolve().parent;R=D.parents[2]
note='2026-11-04: autor respondeu aprovadissimos à entrega do bebê Yaguim concept-v1 e jovem Yaguarda concept-v1. Aprovação visual; requisitos e integração não incluídos.'
p=D/'chart.json';c=json.loads(p.read_text(encoding='utf-8'))
for n in c['nodes']:
 if n['id'] in ('yaguim','yaguarda'):
  n.update(decision_status='approved',approval_note=note)
  folder=(D/n['art']).resolve().parent;mf=folder/'manifest.json';m=json.loads(mf.read_text(encoding='utf-8'));m.update(decision_status='approved',approval_note=note);mf.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
  for filename in ['brief.md','revisao.md']:
   f=folder/filename;s=f.read_text(encoding='utf-8').replace('Aguardando aprovação do autor.','Aprovação visual registrada em 2026-11-04.').replace('Concept em avaliação','Concept visualmente aprovado')
   if note not in s:s+='\n'+note+'\n'
   f.write_text(s,encoding='utf-8')
p.write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf-8')
for filename,a,b in [('index.html','Bebê e jovem em avaliação; criança autoral e adulto aprovado preservados.','Bebê e jovem aprovados visualmente; criança autoral e adulto aprovado preservados.'),('CHART.md','Bebê e jovem são novos concepts em avaliação.','Bebê e jovem aprovados visualmente em 2026-11-04.')]:
 f=D/filename;f.write_text(f.read_text(encoding='utf-8').replace(a,b),encoding='utf-8')
dec=R/'art/creatures/yaguaru-family-v1/DECISOES.md';dec.write_text('# Aprovação da família\n\n'+note+'\nBase Yaguarú e Yaguarion concept-v2 mantêm suas aprovações anteriores.\n',encoding='utf-8')
print('Aprovação visual registrada para Yaguim e Yaguarda.')
