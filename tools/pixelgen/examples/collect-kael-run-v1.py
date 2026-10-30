"""Collect only this task's completed local video jobs; never change its queue."""
from pathlib import Path
import json, urllib.request, urllib.parse
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'art/characters/kael-locomotion-v1'
BASE='http://127.0.0.1:8188'
jobs=json.loads((OUT/'jobs.json').read_text())
for job in jobs:
    with urllib.request.urlopen(BASE+'/history/'+job['prompt_id'],timeout=15) as response:
        history=json.load(response).get(job['prompt_id'])
    if not history:print(job['direction'],'pending');continue
    if history['status']['status_str']!='success':
        messages=history['status'].get('messages',[])
        error=next((m[1].get('exception_message','') for m in messages if m[0]=='execution_error'),'unknown')
        job.update(status='error',error=error)
        print(job['direction'],'error:',error.strip());continue
    entry=history['outputs']['18']['images'][0]
    path=OUT/'video-original'/('kael-run-'+job['direction']+'.mp4')
    if not path.exists():
        with urllib.request.urlopen(BASE+'/view?'+urllib.parse.urlencode(entry),timeout=60) as response:
            path.write_bytes(response.read())
    job.update(status='collected',video=str(path.relative_to(OUT)))
    print(job['direction'],path.stat().st_size)
(OUT/'jobs.json').write_text(json.dumps(jobs,indent=2))
