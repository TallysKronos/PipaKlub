from pathlib import Path
from PIL import Image,ImageSequence
from collections import Counter
import json
root=Path(__file__).parent.parent
master=Image.open(root/'battle-pixel-v1/alvacordo-battle-192.png').convert('RGBA')
report=[];cfg=[]
for name,folder,tag in [('attack','battle-attack-v1','attack'),('damage','battle-damage-v1','damage')]:
 p=root/folder
 left=Image.open(p/(name+'-left.png')).convert('RGBA');right=Image.open(p/(name+'-right.png')).convert('RGBA')
 data=json.loads((p/(name+'-left.json')).read_text(encoding='utf-8'));fs=data['frames'];fs=list(fs.values()) if isinstance(fs,dict) else fs
 rows=[];mirror_diff=0;firstlast=[]
 for i,f in enumerate(fs):
  r=f['frame'];assert r['w']==r['h']==192
  c=left.crop((r['x'],r['y'],r['x']+192,r['y']+192));rc=right.crop((i*192,0,(i+1)*192,192))
  cs=Counter(c.get_flattened_data());partial=sum(n for color,n in cs.items() if 0<color[3]<255);assert partial==0
  mirror_diff+=sum(a!=b for a,b in zip(c.transpose(Image.Transpose.FLIP_LEFT_RIGHT).get_flattened_data(),rc.get_flattened_data()))
  if i in [0,len(fs)-1]:firstlast.append(sum(a!=b for a,b in zip(c.get_flattened_data(),master.get_flattened_data())))
  rows.append({'frame':i+1,'duration_ms':f['duration'],'bbox':c.getbbox(),'visible_colors':sum(1 for color in cs if color[3]),'partial_alpha':partial})
 assert mirror_diff==0 and firstlast==[0,0],(name,mirror_diff,firstlast)
 g=Image.open(p/(name+'-left-2x.gif'))
 item={'animation':name,'frames':len(fs),'duration_ms':sum(f['duration'] for f in fs),'mirror_diff':mirror_diff,'first_last_master_diff':firstlast,'gif_size':g.size,'gif_encoded_frames':g.n_frames,'cells':rows}
 report.append(item)
 cfg.append({'id':name,'name':'Ataque' if name=='attack' else 'Dano','left':'../'+folder+'/'+name+'-left.png','right':'../'+folder+'/'+name+'-right.png','durations':[f['duration'] for f in fs]})
out=Path(__file__).parent
(out/'validacao.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(out/'config.json').write_text(json.dumps(cfg,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps([{k:v for k,v in row.items() if k!='cells'} for row in report]))

