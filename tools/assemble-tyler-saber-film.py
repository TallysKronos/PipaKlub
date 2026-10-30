"""Finish the actual ten generated AV shots as an exact 80-second standalone short."""
import argparse,hashlib,json,re,subprocess,textwrap
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'art/tyler-saber-forest-film-v1'
OUT=ROOT/'documentation/tyler-saber-forest-film-v1'
FF=ROOT/'tmp/video-encoder/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe'
def run(*args):
 subprocess.run([str(FF),'-nostdin','-hide_banner','-loglevel','error','-y','-filter_threads','1',*map(str,args)],check=True)
def probe(path):
 result=subprocess.run([str(FF),'-nostdin','-hide_banner','-i',str(path)],capture_output=True,text=True,encoding='utf-8',errors='replace')
 time=re.search(r'Duration: (\d+):(\d+):(\d+(?:\.\d+)?)',result.stderr)
 dim=re.search(r'Video:.*?\b(\d{2,5})x(\d{2,5})\b',result.stderr)
 return {'seconds':sum(float(v)*w for v,w in zip(time.groups(),[3600,60,1])) if time else None,'dimensions':list(map(int,dim.groups())) if dim else None,'audio':bool(re.search(r'Stream .*Audio:',result.stderr))}
def stamp(seconds,ass=False):
 h=int(seconds//3600);m=int(seconds%3600//60);s=seconds%60
 return f'{h}:{m:02d}:{s:05.2f}' if ass else f'{h:02d}:{m:02d}:{int(s):02d},{round(s%1*1000):03d}'
def subtitles(plan):
 entries=[s for shot in plan['shots']for s in shot['subtitles']]
 (OUT/'legendas.pt-BR.srt').write_text('\n\n'.join(f"{i+1}\n{stamp(s['start'])} --> {stamp(s['end'])}\n{s['text']}"for i,s in enumerate(entries))+'\n',encoding='utf-8')
 header='''[Script Info]
Title: Tyler e Saber — Um fio de coragem
ScriptType: v4.00+
PlayResX: 1280
PlayResY: 720
WrapStyle: 0
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,29,&H00FFFFFF,&H000000FF,&H00201A17,&H70000000,-1,0,0,0,100,100,0,0,1,2,1,2,70,70,40,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
'''
 lines=[]
 for s in entries:
  text='\\N'.join(textwrap.wrap(s['text'],width=62))
  lines.append(f"Dialogue: 0,{stamp(s['start'],True)},{stamp(s['end'],True)},Default,{s['speaker']},0,0,0,,{text}")
 (OUT/'legendas.pt-BR.ass').write_text(header+'\n'.join(lines)+'\n',encoding='utf-8')
def main():
 parser=argparse.ArgumentParser();parser.add_argument('--prepare-only',action='store_true');args=parser.parse_args()
 OUT.mkdir(exist_ok=True);plan=json.loads((ART/'film-plan.json').read_text(encoding='utf-8'));subtitles(plan)
 if args.prepare_only:print('Portuguese subtitle files prepared; no film claimed complete.');return
 jobs=json.loads((ART/'jobs.json').read_text(encoding='utf-8'))
 errors=[j['id']for j in jobs if j.get('status')!='completed']
 if len(jobs)!=10 or errors:raise RuntimeError('Ten successful generated shots are required: '+str(errors))
 edit=ART/'edit';edit.mkdir(exist_ok=True);shots=[];normalized=[]
 for i,shot in enumerate(plan['shots']):
  src=ART/'video-original'/(shot['id']+'.mp4');meta=probe(src)
  if not meta['seconds'] or meta['seconds']<7.9:raise RuntimeError('Short source: '+str(src))
  dst=edit/(shot['id']+'.mp4')
  run('-i',src,'-vf','scale=864:480:force_original_aspect_ratio=decrease,pad=864:480:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=24','-af','aresample=48000,aformat=channel_layouts=stereo,apad,atrim=duration=8,afade=t=in:st=0:d=0.02,afade=t=out:st=7.97:d=0.03','-t','8','-c:v','libx264','-threads','2','-crf','17','-pix_fmt','yuv420p','-c:a','aac','-b:a','192k',dst)
  normalized.append(dst);shots.append({'id':shot['id'],'source':str(src.relative_to(ROOT)),'metadata':meta,'sha256':hashlib.sha256(src.read_bytes()).hexdigest()})
  run('-i',src,'-vf','fps=1,scale=432:-1,tile=4x2','-frames:v','1',OUT/(shot['id']+'-planos.png'))
 concat=edit/'concat.txt';concat.write_text('\n'.join("file '"+p.as_posix()+"'"for p in normalized),encoding='utf-8')
 native=OUT/'master-864x480-sem-legendas.mp4'
 run('-f','concat','-safe','0','-i',concat,'-c','copy','-t','80','-movflags','+faststart',native)
 forest=ROOT/'art/soundtrack-study/previews/02-parque-v2.mp3';battle=ROOT/'art/soundtrack-study/previews/03-batalha-v2.mp3'
 # Actual animated AV footage is preserved. Music is the project's existing local generated score.
 filters=';'.join([
  '[1:a]asplit=2[fa][fb]',
  '[fa]atrim=start=0:duration=34,asetpts=PTS-STARTPTS,aresample=48000,aformat=channel_layouts=stereo,afade=t=in:st=0:d=1.5,afade=t=out:st=32:d=2,volume=0.10[m1]',
  '[2:a]atrim=start=0:duration=42,asetpts=PTS-STARTPTS,aresample=48000,aformat=channel_layouts=stereo,afade=t=in:st=0:d=1.5,afade=t=out:st=40:d=2,volume=0.12,adelay=32000|32000[m2]',
  '[fb]atrim=start=12:duration=8,asetpts=PTS-STARTPTS,aresample=48000,aformat=channel_layouts=stereo,afade=t=in:st=0:d=1,afade=t=out:st=6.7:d=1.3,volume=0.10,adelay=72000|72000[m3]',
  '[m1][m2][m3]amix=inputs=3:duration=longest:normalize=0[music]',
  '[0:a]aresample=48000,aformat=channel_layouts=stereo,asplit=2[dx][key]',
  '[music][key]sidechaincompress=threshold=0.04:ratio=5:attack=10:release=350[duck]',
  '[dx][duck]amix=inputs=2:duration=longest:normalize=0,atrim=duration=80,afade=t=out:st=79.7:d=0.3,alimiter=limit=0.95,loudnorm=I=-16:TP=-1.5:LRA=11,aresample=48000[mix]'])
 final=OUT/'tyler-e-saber-um-fio-de-coragem.mp4'
 ass=(OUT/'legendas.pt-BR.ass').relative_to(ROOT).as_posix()
 run('-i',native,'-stream_loop','-1','-i',forest,'-stream_loop','-1','-i',battle,'-filter_complex_threads','1','-filter_complex',filters,'-map','0:v','-map','[mix]','-vf',f'scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,ass={ass},fade=t=out:st=79.6:d=0.4','-t','80','-r','24','-c:v','libx264','-threads','2','-crf','18','-pix_fmt','yuv420p','-c:a','aac','-b:a','192k','-movflags','+faststart',final)
 run('-ss','35','-i',final,'-frames:v','1',OUT/'poster.png')
 run('-i',final,'-vf','fps=1/4,scale=384:-1,tile=5x4','-frames:v','1',OUT/'planos-geral.png')
 # Decode the delivery completely and count frames, rather than trusting only the container duration.
 check=subprocess.run([str(FF),'-nostdin','-hide_banner','-i',str(final),'-map','0:v:0','-an','-f','null','-'],capture_output=True,text=True,encoding='utf-8',errors='replace')
 frames=re.findall(r'frame=\s*(\d+)',check.stderr)
 meta=probe(final)
 if check.returncode or not frames or int(frames[-1])!=1920 or abs(meta['seconds']-80)>.05:raise RuntimeError('Delivery duration/frame verification failed')
 report={'title':'Tyler e Saber — Um fio de coragem','final':str(final.relative_to(ROOT)),'final_metadata':meta,'decoded_frames':int(frames[-1]),'fps':24,'source_native_dimensions':[864,480],'delivery_resized_dimensions':[1280,720],'shots':shots,'editing':'Ten actual generated 8s AV shots, editorial cuts, Portuguese scripted subtitles, existing project music under generated audio, final 0.4s fade. No still-image duration padding.','music':[str(forest.relative_to(ROOT)),str(battle.relative_to(ROOT))],'subtitles':'Scripted Portuguese lines, not an ASR-certified verbatim transcription. Generated pronunciation/lip sync can vary.','runtime_changed':False,'published':False}
 (OUT/'montagem.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
 for shot in plan['shots']:
  job=next(j for j in jobs if j['id']==shot['id'])
  shot.update(status='completed',prompt_id=job['prompt_id'],revision=job.get('revision',1),source=f"video-original/{shot['id']}.mp4")
 plan.update(status='completed',final=report['final'],decoded_frames=report['decoded_frames'])
 (ART/'film-plan.json').write_text(json.dumps(plan,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps({'file':str(final),'seconds':meta['seconds'],'frames':report['decoded_frames']}),flush=True)
if __name__=='__main__':main()
