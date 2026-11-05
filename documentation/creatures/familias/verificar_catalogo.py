from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import unquote
import json,re
D=Path(__file__).resolve().parent
class Links(HTMLParser):
    def __init__(self):super().__init__();self.paths=[];self.sections=0;self.images=0
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if tag=='section':self.sections+=1
        if tag=='img':self.images+=1
        for k in ('href','src'):
            if k in a:self.paths.append(a[k])
p=Links();p.feed((D/'index.html').read_text(encoding='utf-8'))
missing=[]
for url in p.paths:
    if url.startswith(('http:','https:','#','data:')):continue
    path=(D/unquote(url.split('#')[0])).resolve()
    if not path.exists():missing.append(url)
data=json.loads((D/'catalogo.json').read_text(encoding='utf-8'));audit=json.loads((D/'auditoria.json').read_text(encoding='utf-8'))
assert not missing,missing
assert not audit['missing_references'],audit['missing_references']
assert not audit['dex_not_covered'],audit['dex_not_covered']
assert not audit['creature_keys_not_covered'],audit['creature_keys_not_covered']
assert p.sections==len(data['families'])
assert len({f['id'] for f in data['families']})==len(data['families'])
doc=(D/'FAMILIAS.md').read_text(encoding='utf-8')
for anchor in re.findall(r'\]\(#([^)]*)\)',doc):assert 'id="'+anchor+'"' in doc,anchor
result=dict(ok=True,html_links=len(p.paths),html_images=p.images,sections=p.sections,missing_links=missing,coverage='36 entradas Dex e todas as chaves de criaturas cobertas',browser_visual_review='Não realizada: navegador local desativado nas configurações. Verificação estática de estrutura e arquivos apenas.')
(D/'validacao.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(result,ensure_ascii=False,indent=2))
