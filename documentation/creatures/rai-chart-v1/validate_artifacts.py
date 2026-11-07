"""Verifica arquivos locais, IDs e scripts do documento; não valida render no navegador."""
import json
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote

DOC=Path(__file__).resolve().parent
class Links(HTMLParser):
    def __init__(self):
        super().__init__(); self.links=[]; self.buttons=[]; self.scripts=[]; self.active=False
    def handle_starttag(self,tag,attrs):
        attrs=dict(attrs)
        for name in ['src','href']:
            if name in attrs: self.links.append(attrs[name])
        if tag=='button' and 'data-id' in attrs:self.buttons.append(attrs['data-id'])
        if tag=='script':self.active=True
    def handle_endtag(self,tag):
        if tag=='script':self.active=False
    def handle_data(self,data):
        if self.active:self.scripts.append(data)

page=Links();page.feed((DOC/'index.html').read_text(encoding='utf-8'))
chart=json.loads((DOC/'chart.json').read_text(encoding='utf-8'))
errors=[]
for url in page.links:
    if url.startswith(('https:','http:','#','data:')):continue
    if not (DOC/unquote(url.split('#')[0])).is_file():errors.append(f'Link não encontrado: {url}')
ids=[n['id']for n in chart['nodes']]
if sorted(ids)!=sorted(page.buttons):errors.append('Cards e nós não correspondem.')
fusion=next(n for n in chart['nodes']if n['id']=='entreflor')
parents=[e['from']for e in chart['edges']if e['to']=='entreflor' and e['kind']=='interweaving']
if sorted(parents)!=sorted(fusion['partners']):errors.append('Fusão sem as duas entradas corretas.')
for node in chart['nodes']:
    if node['id'] not in ('rai','arauto-da-tempestade'):
        folder=(DOC/node['art']).parent
        for name in ['concept.png','brief.md','prompt.txt','revisao.md','manifest.json']:
            if not (folder/name).is_file():errors.append(f'{node["id"]}: falta {name}')
(DOC/'viewer-script.js').write_text('\n'.join(page.scripts),encoding='utf-8')
result={'ok':not errors,'errors':errors,'cards':len(page.buttons),'local_links':len(page.links),
        'fusion_inputs':parents,'scope':'Arquivos/IDs e duas entradas do Entrelaço; não é auditoria visual ou teste interativo de navegador.'}
(DOC/'validation.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(result,ensure_ascii=False));raise SystemExit(bool(errors))
