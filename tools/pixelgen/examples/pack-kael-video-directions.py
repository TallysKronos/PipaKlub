"""Inspect/select per-direction cycles and assemble a shared-scale/palette draft.

Cycle matching is a candidate selector, never a visual/anatomy approval. Sources,
timestamps and scores are preserved for review and manual adjustment.
"""
import argparse
import importlib.util
import json
from pathlib import Path
import subprocess
from PIL import Image,ImageChops,ImageStat,ImageDraw

ROOT=Path(__file__).resolve().parents[3];OUT=ROOT/'art/characters/kael-video-eight-directions-v1'
spec=importlib.util.spec_from_file_location('video_sheet',ROOT/'tools/pixelgen/video-to-sheet.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
DIRS=['S','SO','O','NO','N','NE','E','SE'];W,H=64,96

def border_foreground(keyed):
 a=keyed.getchannel('A');w,h=a.size
 strips=[a.crop((0,0,w,4)),a.crop((0,h-4,w,h)),a.crop((0,4,4,h-4)),a.crop((w-4,4,w,h-4))]
 return sum(ImageStat.Stat(s).sum[0] for s in strips)/sum(s.width*s.height*255 for s in strips)

def candidate_cycle(features,valid=None):
 def difference(i,j):return sum(ImageStat.Stat(ImageChops.difference(features[i],features[j])).mean)/3
 best=None
 for start in range(6,len(features)-36,2):
  for length in range(22,35):
   end=start+length
   if valid is not None and not all(valid[start-1:end+2]):continue
   # Neighbours catch matching positions with opposing velocities; half-cycle
   # activity prevents an almost-still stretch winning just by being unchanged.
   score=sum(difference(start+k,end+k) for k in [-1,0,1])/3
   activity=difference(start,start+length//4)+difference(start,start+length//2)
   if activity<2:continue
   score+=abs(length-28)*.025
   if best is None or score<best[0]:best=(score,start,length)
 if best is None:raise ValueError('Sem ciclo com movimento suficiente e fundo limpo para selecionar.')
 score,start,length=best
 selected=[start+round(i*length/8) for i in range(8)]
 return {'startFrame':start,'endFrame':start+length,'frames':selected,'timestamps':[i/24 for i in selected],'duration':length/24,'matchingScore':round(score,3),'status':'candidato: conferir emenda, contatos e identidade visualmente'}

def select(job,force=False):
 direction=job['direction'];folder=OUT/'selecoes'/direction;folder.mkdir(parents=True,exist_ok=True)
 record=folder/'selecao.json'
 if record.exists() and not force:return json.loads(record.read_text(encoding='utf-8'))
 video=(OUT/job['video']).resolve();raw=ROOT/'tmp/kael-video-frames'/direction/(job.get('prompt_id') or 'reused');raw.mkdir(parents=True,exist_ok=True)
 subprocess.run([str(module.FFMPEG),'-hide_banner','-loglevel','error','-y','-i',str(video),'-vf','fps=24','-frames:v','124',str(raw/'%03d.png')],check=True)
 files=sorted(raw.glob('*.png'));features=[];valid=[]
 if len(files)<80:raise ValueError(f'{direction}: clipe curto demais ({len(files)}).')
 for file in files:
  with Image.open(file) as im:
   keyed=module.key_image(im);valid.append(border_foreground(keyed)<.005);bg=Image.new('RGB',keyed.size);bg.paste(keyed,mask=keyed.getchannel('A'))
   features.append(bg.crop((112,212,400,472)).resize((36,32),Image.Resampling.BOX))
 chosen=candidate_cycle(features,valid);chosen.update(direction=direction,video=str(video),invalidBackgroundFrames=[i for i,v in enumerate(valid) if not v])
 for i,index in enumerate(chosen['frames']):
  with Image.open(files[index]) as im:im.save(folder/f'{i:02d}.png')
 record.write_text(json.dumps(chosen,ensure_ascii=False,indent=2),encoding='utf-8')
 # Broad source filmstrip remains independent of the picked cycle.
 subprocess.run([str(module.FFMPEG),'-hide_banner','-loglevel','error','-y','-i',str(video),'-vf','fps=2.4,scale=192:192,tile=4x3','-frames:v','1',str(folder/'video-contato.png')],check=True)
 print(direction,chosen['timestamps'],'score',chosen['matchingScore'],flush=True)
 return chosen

def assemble(jobs):
 selections=[];images=[]
 for d in DIRS:
  job=next(j for j in jobs if j['direction']==d);selection=select(job);selections.append(selection)
  for i in range(8):
   with Image.open(OUT/'selecoes'/d/f'{i:02d}.png') as im:
    keyed=module.key_image(im)
    if border_foreground(keyed)>=.005:raise ValueError(f'{d}/{i}: fundo contaminado ou figura cortada; refazer seleção.')
    images.append(keyed)
 natives,indices,palette,alignment=module.pack(images,W,H,32)
 target=OUT/'pacote';target.mkdir(exist_ok=True)
 sheet=Image.new('RGBA',(W*8,H*8));frames=[];sequences=[]
 for row,d in enumerate(DIRS):
  selection=selections[row];timestamps=selection['timestamps'];times=timestamps+[selection['endFrame']/24]
  for col in range(8):
   index=row*8+col;sheet.paste(natives[index],(col*W,row*H))
   frames.append({'name':f'walk-{d}-{col+1}','duration':round((times[col+1]-times[col])*1000),'indices':indices[index],'cels':[indices[index]]})
  sequences.append({'name':f'walk-{d}','start':row*8,'end':row*8+7,'loop':True,'direction':'forward'})
 sheet.save(target/'kael-walk-eight.png')
 project={'kind':'pixelgen','version':2,'name':'Kael · vídeo · oito direções','width':W,'height':H,'cols':8,'rows':8,'palette':palette,
  'settings':{'width':W,'height':H,'cols':8,'rows':8,'colors':32,'margin':2},'layers':[{'name':'Arte do vídeo','visible':True,'locked':False}],
  'sheet':{'nome':'Kael','notas':'Extração de vídeos MiniMax locais. Paleta/escala comuns; sem aprovação artística automática.'},'frames':frames,'sequences':sequences}
 (target/'kael-eight.pixelgen.json').write_text(json.dumps(project,ensure_ascii=False),encoding='utf-8')
 for row,d in enumerate(DIRS):
  single={**project,'rows':1,'frames':frames[row*8:row*8+8],'sequences':[{**sequences[row],'start':0,'end':7}]}
  (target/f'walk-{d}.pixelgen.json').write_text(json.dumps(single,ensure_ascii=False),encoding='utf-8')
  sheet.crop((0,row*H,W*8,(row+1)*H)).save(target/f'walk-{d}.png')
 # At 1x and 2x; native sheet is always untouched and transparent.
 contact=Image.new('RGB',(W*8*2+80,(H*2+24)*8),'#e9e4d8');draw=ImageDraw.Draw(contact)
 for row,d in enumerate(DIRS):
  y=row*(H*2+24);draw.text((4,y+8),d,fill='#172237')
  for col in range(8):
   im=natives[row*8+col].resize((W*2,H*2),Image.Resampling.NEAREST);contact.paste(im,(80+col*W*2,y),im)
   draw.text((80+col*W*2,y+H*2+4),f'{col+1} / {selections[row]["timestamps"][col]:.3f}s',fill='#172237')
 contact.save(target/'revisao-oito-direcoes.png')
 board=Image.new('RGB',(W*4*4,H*4*2+44),'#e9e4d8');draw=ImageDraw.Draw(board)
 for i,d in enumerate(DIRS):
  x=i%4*W*4;y=i//4*(H*4+22);im=natives[i*8].resize((W*4,H*4),Image.Resampling.NEAREST);board.paste(im,(x,y),im);draw.text((x+8,y+H*4+3),d,fill='#172237')
 board.save(target/'direcoes.png')
 # Index-synchronised comparison GIF, not aligned gait phases or engine timing.
 views=[]
 for phase in range(8):
  canvas=Image.new('RGB',(W*2*4,H*2*2+36),'#e9e4d8');draw=ImageDraw.Draw(canvas)
  for row,d in enumerate(DIRS):
   x=row%4*W*2;y=row//4*(H*2+18);im=natives[row*8+phase].resize((W*2,H*2),Image.Resampling.NEAREST);canvas.paste(im,(x,y),im);draw.text((x+4,y+H*2+1),d,fill='#172237')
  views.append(canvas)
 views[0].save(target/'comparacao.gif',save_all=True,append_images=views[1:],loop=0,duration=150,disposal=2)
 manifest={'cell':[W,H],'frames':64,'directions':DIRS,'palette':palette,'alignment':alignment,'selections':selections,'status':'rascunho: revisar variação de volume, pixels soltos e loops; não integrado ao jogo'}
 (target/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
 print('PACK',target,flush=True)

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--assemble',action='store_true');args=parser.parse_args()
 jobs=json.loads((OUT/'jobs.json').read_text(encoding='utf-8'))
 for j in jobs:
  if j['status'] in ['completed','reused']:select(j)
 if args.assemble:
  if not all(j['status'] in ['completed','reused']for j in jobs):raise RuntimeError('Ainda há vídeos pendentes; não montar biblioteca incompleta.')
  assemble(jobs)

if __name__=='__main__':main()
