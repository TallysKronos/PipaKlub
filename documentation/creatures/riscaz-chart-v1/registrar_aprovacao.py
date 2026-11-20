from pathlib import Path
import json
D=Path(__file__).resolve().parent;R=D.parents[2]
NOTE='2026-11-04: autor respondeu “aprovados” após revisão ratazanosa do jovem. Aprovação visual do bebê concept-v1 e jovem concept-v2; receitas e integração não incluídas.'
chart=D/'chart.json';c=json.loads(chart.read_text(encoding='utf-8'))
for n in c['nodes']:
 if n['id'] in ('riscotim','riscavela'):
  n.update(decision_status='approved',approval_note=NOTE)
  folder=(D/n['art']).resolve().parent
  mf=folder/'manifest.json';m=json.loads(mf.read_text(encoding='utf-8'));m.update(decision_status='approved',approval_note=NOTE)
  if n['id']=='riscavela':m['references']=['art/soulgen/keys/riscaz/cutout-rig-v1/preview.png','art/creatures/riscaz-family-v1/riscavela/concept-v1/concept.png']
  mf.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
  review=folder/'revisao.md';s=review.read_text(encoding='utf-8').replace('Novas artes aguardam avaliação do autor.','Aprovação visual registrada em 2026-11-04.').replace('Aguardando aprovação visual.','Aprovação visual registrada em 2026-11-04.')
  review.write_text(s,encoding='utf-8')
  brief=folder/'brief.md';s=brief.read_text(encoding='utf-8').replace('Arte nova em avaliação.','Arte visualmente aprovada em 2026-11-04.')
  if NOTE not in s:s+='\n## Aprovação\n'+NOTE+'\n'
  brief.write_text(s,encoding='utf-8')
chart.write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf-8')
for path,a,b in [(D/'index.html','Novos bebê e jovem em avaliação; criança autoral preservada e adulto aprovado.','Bebê e jovem revisado aprovados visualmente; criança autoral preservada e adulto aprovado.'),(D/'CHART.md','As duas novas artes e nomes são propostas.','As duas novas artes foram aprovadas visualmente em 2026-11-04. Nomes e relações mecânicas permanecem propostas.')]:
 path.write_text(path.read_text(encoding='utf-8').replace(a,b),encoding='utf-8')
dec=R/'art/creatures/riscaz-family-v1/DECISOES.md';s=dec.read_text(encoding='utf-8').replace('Revisão concept-v2 é candidata atual, em avaliação.','Revisão concept-v2 é a versão atual aprovada.')
if NOTE not in s:s+='\n'+NOTE+'\n'
dec.write_text(s,encoding='utf-8')
print('Aprovação visual registrada para Riscotim v1 e Riscavela v2.')
