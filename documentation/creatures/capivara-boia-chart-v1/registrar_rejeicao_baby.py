from pathlib import Path
import json
D=Path(__file__).resolve().parent
note='2026-11-04: autor disse que o bebê ainda não ficou bom e pediu benchmark aprofundado de Digimon Baby/Rookie antes de nova criação. Gotim concept-v3 rejeitado; não houve aprovação da revisão child-manga-v2.'
p=D/'chart.json';c=json.loads(p.read_text(encoding='utf-8'))
for n in c['nodes']:
 if n['id']=='gotim':
  n.update(decision_status='rejected',decision_note=note);folder=(D/n['art']).resolve().parent;mf=folder/'manifest.json';m=json.loads(mf.read_text(encoding='utf-8'));m.update(decision_status='rejected',decision_note=note);mf.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
  f=folder/'revisao.md';s=f.read_text(encoding='utf-8')
  if note not in s:s+='\n'+note+'\n'
  f.write_text(s,encoding='utf-8')
p.write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf-8')
for p in [D/'CHART.md',D.parents[2]/'art/creatures/capivara-boia-family-v1/DECISOES.md']:
 s=p.read_text(encoding='utf-8')
 if note not in s:s+='\n'+note+'\n'
 p.write_text(s,encoding='utf-8')
p=D/'index.html';s=p.read_text(encoding='utf-8');notice='<p><strong>Bebê concept-v3 rejeitado pelo autor em 04/11/2026.</strong> Próxima criação depende do estudo Baby/Rookie; demais formas não receberam aprovação automática.</p>'
if notice not in s:s=s.replace('<main class="grid">',notice+'<main class="grid">')
p.write_text(s,encoding='utf-8')
print('Rejeição atual registrada, versões preservadas.')
