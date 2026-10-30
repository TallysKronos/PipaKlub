"""Collect only this batch's Comfy jobs; downloads only their completed video outputs."""
import json
from pathlib import Path
from urllib.request import urlopen
from urllib.parse import urlencode

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'art/characters/kael-video-eight-directions-v1'
BASE='http://127.0.0.1:8188'

def main():
 jobs=json.loads((OUT/'jobs.json').read_text(encoding='utf-8'))
 queue=json.load(urlopen(BASE+'/queue',timeout=10))
 running={j[1] for j in queue['queue_running']};pending={j[1] for j in queue['queue_pending']}
 for j in jobs:
  if not j.get('prompt_id'):continue
  entry=json.load(urlopen(BASE+'/history/'+j['prompt_id'],timeout=20)).get(j['prompt_id'])
  if not entry:
   j['status']='running' if j['prompt_id'] in running else 'queued' if j['prompt_id'] in pending else 'unknown';continue
  status=entry.get('status',{});j['status']='completed' if status.get('status_str')=='success' else 'error'
  if j['status']=='error':j['error']=status;continue
  for node in entry.get('outputs',{}).values():
   for values in node.values():
    if not isinstance(values,list):continue
    for v in values:
     if not isinstance(v,dict) or not v.get('filename','').endswith(('.mp4','.webm','.mkv')):continue
     path=OUT/'video-original'/f"walk-{j['direction']}.mp4"
     if not path.exists():path.write_bytes(urlopen(BASE+'/view?'+urlencode({k:v.get(k,'')for k in ['filename','subfolder','type']}),timeout=120).read())
     j['video']=str(path.relative_to(OUT));j['bytes']=path.stat().st_size
 (OUT/'jobs.json').write_text(json.dumps(jobs,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps([{k:j[k] for k in ['direction','status','video','bytes'] if k in j} for j in jobs],ensure_ascii=False))

if __name__=='__main__':main()
