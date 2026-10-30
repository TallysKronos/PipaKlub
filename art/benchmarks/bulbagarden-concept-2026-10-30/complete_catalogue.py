import html
import json
import urllib.parse
from collect_index import ROOT, BASE, fetch, links

d=json.loads((ROOT/'catalogue.json').read_text(encoding='utf-8'))
d['parent_files']=list(d['files'])
all_files={f['title']:f for f in d['files']}
for c in d['subcategories']:
    url=c['url']
    pages=[]
    category_files={}
    while url and url not in pages:
        markup=fetch(url)
        pages.append(url)
        for a,label in links(markup):
            title=html.unescape(a.get('title',''))
            href=html.unescape(a.get('href',''))
            if title.startswith('File:') and '/wiki/File' in href:
                category_files[title]={'title':title,'name':title[5:],'url':urllib.parse.urljoin(BASE,href)}
        next_links=[html.unescape(a.get('href','')) for a,label in links(markup) if label=='next page']
        url=urllib.parse.urljoin(BASE,next_links[0]) if next_links else None
    c['indexed_files']=sorted(category_files)
    c['pages']=pages
    c['file_count']=len(category_files)
    all_files.update(category_files)
d['files']=sorted(all_files.values(),key=lambda x:x['name'].lower())
d['scope']='All parent pagination plus all file-list pagination of its 15 direct subcategories. Metadata catalogue; visual analysis is separately identified.'
(ROOT/'catalogue.json').write_text(json.dumps(d,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'parent_files':len(d['parent_files']),'unique_files_including_subcategories':len(d['files']),'subcategories':len(d['subcategories'])}))
