from pathlib import Path
import json
D=Path(__file__).resolve().parent;R=D.parents[2];A=R/'art/creatures/alvacordo-family-v1'
note='Autor: “Aprovado!”, após apresentação da armadura v4 e correção do braço esquerdo. Aprovação visual do adulto v4; não inclui rig ou integração.'
for p in [D/'chart.json',A/'alvacordo/concept-v4/manifest.json']:
 data=json.loads(p.read_text(encoding='utf-8'))
 if 'nodes' in data:
  for n in data['nodes']:
   if n['id']=='alvacordo':n.update(decision_status='approved',approval_note=note)
  data['scope']='Adulto Alvacordo v4 aprovado visualmente; demais estados preservados. Sem integração.'
 else:data.update(decision_status='approved',approval_note=note)
 p.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
for p in [D/'CHART.md',A/'DECISOES.md',A/'alvacordo/concept-v4/revisao.md']:
 text=p.read_text(encoding='utf-8')
 if note not in text:p.write_text(text+'\n\n## Aprovação do adulto v4\n'+note+'\n',encoding='utf-8')
p=D/'index.html';text=p.read_text(encoding='utf-8').replace('Todos em avaliação. Nomes e funções propostos; sem integração.','Adulto Alvacordo v4 aprovado visualmente. Nomes e funções propostos; sem integração.').replace('Adulto — armadura v4</h2>','Adulto — armadura v4 · Aprovado</h2>');p.write_text(text,encoding='utf-8')
print('Aprovação visual do Alvacordo v4 registrada.')
