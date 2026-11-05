"""Checks every local href/src, selectable id and generated artifact; not a layout audit."""
import json
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import unquote, urlparse
DOC=Path(__file__).resolve().parent
class Parser(HTMLParser):
 def __init__(self): super().__init__();self.refs=[];self.ids=[];self.select=[]
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  for k in ('href','src'):
   if k in a:self.refs.append(a[k])
  if 'id' in a:self.ids.append(a['id'])
  if 'data-id' in a:self.select.append(a['data-id'])
p=Parser();p.feed((DOC/'index.html').read_text(encoding='utf-8'))
data=json.loads((DOC/'chart.json').read_text(encoding='utf-8'))
errors=[]
for ref in p.refs:
 u=urlparse(ref)
 if u.scheme or u.netloc:continue
 if not u.path:
  if u.fragment and u.fragment not in p.ids+p.select:errors.append('Unknown fragment '+ref)
 elif not (DOC/unquote(u.path)).is_file():errors.append('Missing '+ref)
if len(p.ids)!=len(set(p.ids)):errors.append('Duplicate DOM id')
if set(p.select)!={n['id'] for n in data['nodes']}:errors.append('Selection ids differ from chart')
if len(p.select)!=len(set(p.select)):errors.append('Duplicate selection id')
for n in data['nodes']:
 for k in ('art','brief'):
  if not n.get(k) or not (DOC/n[k]).is_file():errors.append(n['id']+' missing '+k)
result=dict(ok=not errors,local_references=len(p.refs),selection_ids=len(p.select),errors=errors,scope='Local files and focus targets; not rendered layout or interactive browser test.')
(DOC/'validation-links.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(result,ensure_ascii=False,indent=2))
raise SystemExit(bool(errors))
