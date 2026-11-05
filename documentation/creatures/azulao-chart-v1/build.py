"""Empacota dados inline para o chart funcionar também por file://, sem servidor."""
from pathlib import Path
import json

base=Path(__file__).resolve().parent
data=json.loads((base/'chart.json').read_text(encoding='utf-8'))
ids={node['id'] for node in data['nodes']}
assert len(ids)==len(data['nodes'])==11
assert len([node for node in data['nodes'] if node['kind']=='stage'])==8
for edge in data['edges']:
    assert edge['from'] in ids and edge['to'] in ids
    before=next(n for n in data['nodes'] if n['id']==edge['from'])
    after=next(n for n in data['nodes'] if n['id']==edge['to'])
    if edge['kind']=='reweaving':assert after['stage']==before['stage']+1
    else:assert after['stage']==before['stage']
for source in data['sources'].values():assert (base/source).exists(),source
for source in data.get('conceptSheets',{}).values():assert (base/source).exists(),source
for source in data.get('modelSheets',{}).values():assert (base/source).exists(),source
text=(base/'index.template.html').read_text(encoding='utf-8')
text=text.replace('__CHART_DATA__',json.dumps(data,ensure_ascii=False).replace('</','<\/'))
(base/'index.html').write_text(text,encoding='utf-8')
print('Chart: 8 formas, 2 configurações, 1 estado; fontes e conexões válidas.')
