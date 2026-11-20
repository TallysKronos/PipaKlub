from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import json
from coletar import run
D=Path(__file__).resolve().parent
mapping={'metalgreymon_vaccine':'metalgreymon-v','weregarurumon':'weregarurumon','lilymon':'lilimon','marinedevimon':'marinedevimon','ophanimon':'ofanimon','pinocchimon':'pinochimon','imperialdramon':'imperialdramon-dm'}
# Conferir alternativas não significa presumir que existam.
alternatives=['metalgreymon-v','weregarurumon','lilimon','ofanimon','pinochimon','imperialdramon-dm','mammon','vadermon','bancholeomon','ebemon']
with ThreadPoolExecutor(max_workers=4)as pool:results=list(pool.map(run,alternatives))
items=json.loads((D/'coleta-trabalho.json').read_text(encoding='utf-8'));by={i['id']:i for i in results}
for i in items:
 if 'error'in i:
  alt=mapping.get(i['id']);r=by.get(alt,{})
  if 'image'in r:i.clear();i.update(r)
for i in results:print(json.dumps({k:i.get(k)for k in ['id','name','level','error']},ensure_ascii=True))
for level,alts in [('Ultimate',['mammon','vadermon']),('Mega',['bancholeomon','ebemon'])]:
 for r in [by[a]for a in alts]:
  if sum(i.get('level')==level for i in items)>=20:break
  if r.get('level')==level:
   for n,i in enumerate(items):
    if 'error'in i and n//20==(0 if level=='Ultimate' else 1):items[n]=r;break
(D/'coleta-trabalho.json').write_text(json.dumps(items,ensure_ascii=False,indent=2),encoding='utf-8')
(D/'tentativas-alias.json').write_text(json.dumps([{k:v for k,v in i.items()if k!='profile'}for i in results],ensure_ascii=False,indent=2),encoding='utf-8')
