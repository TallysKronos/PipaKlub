"""Read only this film's local ComfyUI jobs and preserve completed original outputs."""
import argparse,json,time,subprocess,sys
from pathlib import Path
from urllib.request import urlopen
from urllib.parse import urlencode
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'art/tyler-saber-forest-film-v1'
BASE='http://127.0.0.1:8188'
def collect():
 jobs=json.loads((ART/'jobs.json').read_text(encoding='utf-8'))
 q=json.load(urlopen(BASE+'/queue',timeout=20))
 running={j[1] for j in q['queue_running']};pending={j[1] for j in q['queue_pending']}
 for j in jobs:
  entry=json.load(urlopen(BASE+'/history/'+j['prompt_id'],timeout=30)).get(j['prompt_id'])
  if entry:
   status=entry.get('status',{})
   j['status']='completed' if status.get('status_str')=='success' else 'error'
   if j['status']=='error':j['error']=status
   j['outputs']=[]
   for node in entry.get('outputs',{}).values():
    for values in node.values():
     if not isinstance(values,list):continue
     for value in values:
      if not isinstance(value,dict) or not value.get('filename','').endswith(('.mp4','.webm','.mkv')):continue
      path=ART/'video-original'/(j['id']+'.mp4')
      if not path.exists():
       path.write_bytes(urlopen(BASE+'/view?'+urlencode({k:value.get(k,'') for k in ['filename','subfolder','type']}),timeout=180).read())
       ff=ROOT/'tmp/video-encoder/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe'
       preview=ROOT/'documentation/tyler-saber-forest-film-v1'/(j['id']+'-planos.png')
       subprocess.run([str(ff),'-nostdin','-hide_banner','-loglevel','error','-y','-i',str(path),'-vf','fps=1,scale=432:-1,tile=4x2','-frames:v','1',str(preview)],check=True)
      j['outputs'].append(str(path.relative_to(ROOT)))
   times=dict((m[0],m[1].get('timestamp'))for m in status.get('messages',[])if m[0] in ['execution_start','execution_success'])
   if times.get('execution_start') and times.get('execution_success'):j['render_seconds']=round((times['execution_success']-times['execution_start'])/1000,2)
  else:j['status']='running' if j['prompt_id'] in running else 'queued' if j['prompt_id'] in pending else 'unknown'
 (ART/'jobs.json').write_text(json.dumps(jobs,ensure_ascii=False,indent=2),encoding='utf-8')
 summary={'completed':sum(j['status']=='completed'for j in jobs),'total':len(jobs),'running':[j['id']for j in jobs if j['status']=='running'],'errors':[j['id']for j in jobs if j['status']=='error']}
 (ART/'progress.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
 print(json.dumps(summary),flush=True)
 return jobs
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--watch',action='store_true');parser.add_argument('--finish',action='store_true');args=parser.parse_args()
 while True:
  jobs=collect()
  if not args.watch or all(j['status'] in ['completed','error']for j in jobs):break
  time.sleep(45)
 if args.finish and len(jobs)==10 and all(j['status']=='completed'for j in jobs):
  subprocess.run([sys.executable,str(ROOT/'tools/assemble-tyler-saber-film.py')],cwd=ROOT,check=True)
