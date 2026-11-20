import json
from pathlib import Path
from html.parser import HTMLParser
DOC=Path(__file__).resolve().parent
class Page(HTMLParser):
 def __init__(self):super().__init__();self.links=[];self.ids=[]
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  for key in ['src','href']:
   if key in a:self.links.append(a[key])
  if tag=='button'and'data-id'in a:self.ids.append(a['data-id'])
p=Page();p.feed((DOC/'index.html').read_text(encoding='utf-8'))
data=json.loads((DOC/'chart.json').read_text(encoding='utf-8'));errors=[]
for url in p.links:
 if url.startswith(('https:','http:','#','data:')):continue
 if not(DOC/url).is_file():errors.append(url)
if sorted(p.ids)!=sorted(n['id']for n in data['nodes']):errors.append('IDs/cards divergentes')
for n in data['nodes']:
 for filename in ['concept.png','prompt.txt','brief.md','revisao.md','manifest.json']:
  if not((DOC/n['art']).parent/filename).is_file():errors.append(n['id']+'/'+filename)
result={'ok':not errors,'errors':errors,'cards':len(p.ids),'scope':'Arquivos e IDs; não certifica layout, rig ou gameplay.'}
(DOC/'validation.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(result));raise SystemExit(bool(errors))
