"""Collect only the approved Alvacordo job, preserving raw video/poses for review."""
from pathlib import Path
from urllib.request import urlopen
from urllib.parse import urlencode
from PIL import Image, ImageDraw
import json,subprocess,time,argparse
ROOT=Path(r'C:/Users/user/produto/pipa-club-integracao-atualizada')
OUT=Path(__file__).parent
BASE='http://127.0.0.1:8188'
JOB='f7a0ee9c-bdbe-416b-b015-c354c9a84f34'
FFMPEG=next((p for p in [ROOT/'tmp/video-encoder/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe',Path(r'C:/Users/user/produto/pipa-club-pip88/tmp/video-encoder/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe')] if p.exists()),None)
PHASES=[(0.0,'ready'),(0.5,'anticipation-start'),(1.0,'anticipation'),(1.3,'strike-start'),(1.6,'strike-1'),(1.9,'strike-1-end'),(2.2,'counter-start'),(2.5,'counter'),(2.8,'follow-through'),(3.2,'follow-through-end'),(3.7,'recovery'),(4.2,'recovery-end'),(4.7,'ready-return'),(5.0,'ready-hold')]
def api(path):
 with urlopen(BASE+path,timeout=25) as r:return json.load(r)
def write_status(data):
 data.update(prompt_id=JOB,workflow='workflows/attack-local.json')
 (OUT/'status.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps(data,ensure_ascii=False),flush=True)
def collect():
 entry=api('/history/'+JOB).get(JOB)
 if not entry:
  q=api('/queue');running={x[1] for x in q.get('queue_running',[])};pending={x[1] for x in q.get('queue_pending',[])}
  write_status({'status':'running' if JOB in running else 'queued' if JOB in pending else 'not_in_queue','running_count':len(running),'pending_count':len(pending)})
  return False
 status=entry.get('status',{})
 if status.get('status_str')!='success':
  write_status({'status':'error','details':status})
  return True
 items=[]
 for node in entry.get('outputs',{}).values():
  for values in node.values():
   if isinstance(values,list):
    for v in values:
     if isinstance(v,dict) and v.get('filename','').lower().endswith(('.mp4','.webm','.mkv','.mov')):items.append(v)
 if not items:
  write_status({'status':'completed_no_video','outputs':entry.get('outputs',{})});return True
 item=items[0];suffix=Path(item['filename']).suffix
 video=OUT/'video-original'/('alvacordo-attack'+suffix)
 if not video.exists():
  with urlopen(BASE+'/view?'+urlencode({k:item.get(k,'') for k in ['filename','subfolder','type']}),timeout=120) as r:video.write_bytes(r.read())
 if FFMPEG is None:raise RuntimeError('FFmpeg local não encontrado; vídeo foi preservado para extração posterior.')
 poses=[]
 for i,(t,label) in enumerate(PHASES):
  filename=OUT/'poses'/f'{i:02d}-{label}.png'
  subprocess.run([str(FFMPEG),'-hide_banner','-loglevel','error','-y','-ss',str(t),'-i',str(video),'-frames:v','1',str(filename)],check=True,timeout=120)
  if filename.exists():poses.append({'file':str(filename.relative_to(OUT)).replace('\\','/'),'time':t,'phase':label})
 # Contact sheet is diagnostic only. Extracted PNGs remain full-resolution.
 cell=256;gap=12;label_h=28;columns=4;rows=(len(poses)+columns-1)//columns
 sheet=Image.new('RGB',(gap+(cell+gap)*columns,gap+(cell+label_h+gap)*rows),'#d9dedd');draw=ImageDraw.Draw(sheet)
 for i,p in enumerate(poses):
  im=Image.open(OUT/p['file']).convert('RGB');im.thumbnail((cell,cell),Image.Resampling.NEAREST)
  x=gap+(i%columns)*(cell+gap);y=gap+(i//columns)*(cell+label_h+gap)
  sheet.paste(im,(x,y));draw.text((x,y+cell+5),f"{i+1:02d}  {p['time']:.1f}s  {p['phase']}",fill='#142a30')
 sheet.save(OUT/'poses/contact-sheet.png')
 (OUT/'poses/selection.json').write_text(json.dumps(poses,indent=2),encoding='utf-8')
 write_status({'status':'extracted_for_review','video':str(video.relative_to(OUT)).replace('\\','/'),'video_bytes':video.stat().st_size,'poses':len(poses),'contact_sheet':'poses/contact-sheet.png','note':'Raw generated motion reference, not a cleaned pixel spritesheet; review anatomy and identity before use.'})
 return True
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--watch',action='store_true');args=p.parse_args()
 start=time.monotonic()
 while True:
  try:
   if collect() or not args.watch:break
  except Exception as e:
   write_status({'status':'collector_error','error':str(e)})
   if not args.watch:raise
  if time.monotonic()-start>10800:
   write_status({'status':'collector_timeout','note':'Job not cancelled; rerun collector after completion.'});break
  time.sleep(20)

