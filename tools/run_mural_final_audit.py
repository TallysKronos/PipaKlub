"""Native campaign capture batches. Isolated fixtures; does not play the campaign.

Keep one resolution/family per process to release texture memory predictably.
"""
from pathlib import Path
import json, subprocess, time, re, argparse
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'documentation/hud-v2/pip-139'
EXE=ROOT/'godot/Godot_v4.7.2-stable_win64_console.exe'
GROUPS={
 'world':['bedroom','street','professor','park','trail','clearing','morro','morro-2','morro-3','morro-4','morro-5','morro-dialog'],
 'interface':['menu','slots','settings','controls','map','kronasta','practice','workshop','care','boss','live','impact','paused','victory','victory-unfocused','defeat','team','bag','pause','morro-battle','dex','evolution','emblems','identity','missions']
}
parser=argparse.ArgumentParser();parser.add_argument('--resolution',action='append');parser.add_argument('--scale',action='append',type=int);parser.add_argument('--group',action='append',choices=list(GROUPS));parser.add_argument('--shots');args=parser.parse_args()
sizes=args.resolution or ['1280x720','1920x1080','1024x768','1280x800']
scales=args.scale or [100,150]
OUT.mkdir(parents=True,exist_ok=True);(OUT/'logs').mkdir(exist_ok=True)
report=OUT/'campaign-audit.json'
records=json.loads(report.read_text(encoding='utf-8'))['batches'] if report.exists() else []
for scale in scales:
 for size in sizes:
  for group,shots in GROUPS.items():
   if args.group and group not in args.group:continue
   if args.shots:shots=[s for s in shots if s in args.shots.split(',')]
   if not shots:continue
   batch=f'{size}-{scale}-{group}'
   log=OUT/'logs'/f'{batch}{"-recheck" if args.shots else ""}.log';err=OUT/'logs'/f'{batch}{"-recheck" if args.shots else ""}-stderr.log'
   destination=OUT/'capturas'/str(scale);destination.mkdir(parents=True,exist_ok=True)
   width,height=map(int,size.split('x'))
   command=[str(EXE),'--path',str(ROOT/'godot'),'--script','res://tools/capture_campaign.gd','--rendering-method','gl_compatibility','--','--shots='+','.join(shots),f'--width={width}',f'--height={height}','--audit','--reduced-motion',f'--text-scale={scale/100}','--output='+str(destination)]
   startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
   start=time.monotonic()
   with log.open('w',encoding='utf-8') as stdout,err.open('w',encoding='utf-8') as stderr:
    try:
     result=subprocess.run(command,stdout=stdout,stderr=stderr,startupinfo=startup,timeout=180)
     exit_code=result.returncode
    except subprocess.TimeoutExpired:exit_code='timeout'
   text=log.read_text(encoding='utf-8',errors='replace');errors=err.read_text(encoding='utf-8',errors='replace')
   images=[]
   for shot in shots:
    name=shot+('' if size=='1280x720' else '-'+size)+'.png';path=destination/name
    actual=None
    if path.exists():
     with Image.open(path) as im:actual=im.size
    images.append({'shot':shot,'file':str(path.relative_to(OUT)),'expected':[width,height],'actual':actual,'pass':actual==(width,height)})
   native=[line for line in text.splitlines() if line.startswith('AUDIT {')]
   paper=[json.loads(line.removeprefix('PAPER_DONE ')) for line in text.splitlines() if line.startswith('PAPER_DONE ')]
   findings=[json.loads(line.removeprefix('AUDIT ')) for line in native]
   prior=next((record for record in records if record['batch']==batch),None)
   if args.shots and prior:
    selected=set(shots)|{s+'-'+size for s in shots}
    images=[i for i in prior['images'] if i['shot'] not in shots]+images
    findings=[f for f in prior['nativeFindings'] if f['shot'] not in selected]+findings
    paper=[p for p in prior['paper'] if p['shot'] not in shots]+paper
   records=[record for record in records if record['batch']!=batch]
   records.append({'batch':batch,'exitCode':exit_code,'seconds':round(time.monotonic()-start,1),'images':images,'nativeFindings':findings,'paper':paper,'scriptError':'SCRIPT ERROR:' in errors,'recheckedShots':shots if args.shots else [],'latestLog':str(log.relative_to(OUT))})
   (OUT/'campaign-audit.json').write_text(json.dumps({'batches':records,'fullMatrix':len(records)==16,'expectedImages':296,'physicalController':False,'earnedPlaythrough':False},ensure_ascii=False,indent=2),encoding='utf-8')
   print(f'{batch}: exit={exit_code}; images={sum(i["pass"] for i in images)}/{len(shots)}; native findings={len(native)}; paper faults={sum(p["failures"] for p in paper)}',flush=True)
print('Native capture audit finished.',flush=True)
