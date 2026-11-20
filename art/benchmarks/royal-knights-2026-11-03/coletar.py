"""Coleta somente perfis e imagens públicos oficiais para estudo local atribuído."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from urllib.request import Request,urlopen
from urllib.parse import urljoin
from html import unescape
import re,json,hashlib
ROOT=Path(__file__).resolve().parent
OUT=ROOT/'referencias';OUT.mkdir(exist_ok=True)
SLUGS=['omegamon','alphamon','dukemon','magnamon','ulforcevdramon','dynasmon','lordknightmon','craniummon','sleipmon','duftmon','examon','gankoomon','jesmon']
def fetch(url):
 return urlopen(Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=35).read()
def clean(t):return unescape(re.sub('<[^>]+>',' ',t)).strip()
def run(slug):
 url='https://digimon.net/reference_en/detail.php?directory_name='+slug
 try:
  page=fetch(url).decode('utf-8');heading=re.search(r'<h3[^>]*>(.*?)</h3>',page,re.S)
  images=list(dict.fromkeys(re.findall(r'(?:src|href)=[\"\x27]([^\"\x27]*cimages/digimon/[^\"\x27]+)',page)))
  images=[im for im in images if Path(im).stem==slug]
  text=re.sub(r'\s+',' ',clean(re.sub(r'<script\b.*?</script>','',page,flags=re.S)))
  start=text.rfind(' Profile ');end=text.find('See related Digimon',start)
  if end<0:end=text.find('Access Ranking',start)
  profile=text[start:end] if start>=0 else ''
  item={'id':slug,'name':clean(heading.group(1))if heading else slug,'url':url,'consulted':'2026-11-03','profile':profile,'images':[]}
  for i,im in enumerate(images):
   imageurl=urljoin(url,im)
   if not imageurl.startswith('https://'):continue
   blob=fetch(imageurl);ext=Path(imageurl).suffix.lower();filename=f'{slug}'+(''if i==0 else f'-{i+1}')+ext
   (OUT/filename).write_bytes(blob)
   item['images'].append({'url':imageurl,'file':'referencias/'+filename,'sha256':hashlib.sha256(blob).hexdigest()})
  return item
 except Exception as e:return {'id':slug,'url':url,'error':str(e)}
with ThreadPoolExecutor(max_workers=5)as pool:items=list(pool.map(run,SLUGS))
(ROOT/'coleta.json').write_text(json.dumps(items,ensure_ascii=False,indent=2),encoding='utf-8')
for it in items:print(json.dumps({'id':it['id'],'images':len(it.get('images',[])),'error':it.get('error')},ensure_ascii=True))
