"""Coleta finita de páginas e artes oficiais para benchmark atribuído, sem inputs de geração."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from urllib.request import Request,urlopen
from urllib.parse import urljoin,urlparse
from html import unescape
import re,json,hashlib
D=Path(__file__).resolve().parent;O=D/'referencias';O.mkdir(exist_ok=True)
SLUGS='botamon punimon poyomon pitchmon yuramon kuramon koromon tunomon tokomon pukamon tanemon mochimon gigimon chibimon agumon gabumon patamon gomamon palmon tentomon guilmon v-mon terriermon renamon wormmon candmon hagurumon elecmon'.split()
def fetch(url):return urlopen(Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=35).read()
def clean(t):return re.sub(r'\s+',' ',unescape(re.sub('<[^>]+>',' ',t))).strip()
def run(slug):
 u='https://digimon.net/reference_en/detail.php?directory_name='+slug
 try:
  h=fetch(u).decode('utf-8');title=re.search(r'<h3[^>]*>(.*?)</h3>',h,re.S)
  if not title:raise ValueError('Perfil não identificado: sem título h3.')
  name=clean(title.group(1));images=list(dict.fromkeys(re.findall(r'(?:src|href)=[\"\x27]([^\"\x27]*cimages/digimon/[^\"\x27]+)',h)))
  images=[p for p in images if Path(urlparse(p).path).stem==slug]
  if not images:raise ValueError('Nenhuma arte principal correspondente ao slug; conferir manualmente.')
  text=clean(re.sub(r'<script\b.*?</script>','',h,flags=re.S));start=text.rfind(' Profile ');end=text.find('Access Ranking',start);profile=text[start+9:end].strip() if start>=0 else ''
  level=re.search(r'Level\s+(.*?)\s+Type',text);typ=re.search(r'Type\s+(.*?)\s+Attribute',text)
  imurl=urljoin(u,images[0]);blob=fetch(imurl);file='referencias/'+slug+Path(urlparse(imurl).path).suffix
  (D/file).write_bytes(blob)
  return dict(id=slug,name=name,url=u,consulted='2026-11-04',level=level.group(1) if level else None,type=typ.group(1) if typ else None,image=dict(file=file,url=imurl,sha256=hashlib.sha256(blob).hexdigest()),profile=profile)
 except Exception as e:return dict(id=slug,url=u,error=str(e))
with ThreadPoolExecutor(max_workers=4) as p:items=list(p.map(run,SLUGS))
(D/'coleta-trabalho.json').write_text(json.dumps(items,ensure_ascii=False,indent=2),encoding='utf-8')
for i in items:print(json.dumps({k:i.get(k) for k in ['id','name','level','type','error']},ensure_ascii=True))
