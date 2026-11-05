from pathlib import Path
import json
F=Path(__file__).resolve().parent
note='2026-11-04 — autor: “Aprovado, quais outras ideias você tem para quadrupedes?”. Escopo: concept visual do lince; funções e nomes permanecem propostos.'
p=F/'manifest.json';v=json.loads(p.read_text(encoding='utf-8'));v['decision_status']='approved';v['approval_note']=note;p.write_text(json.dumps(v,ensure_ascii=False,indent=2),encoding='utf-8')
for p in [F/'brief.md',F/'revisao.md']:
    s=p.read_text(encoding='utf-8')
    if note not in s:p.write_text(s+'\n## Aprovação atual\n'+note+'\n',encoding='utf-8')
