from pathlib import Path
from PIL import Image, ImageChops
from collections import Counter
import json
root=Path(__file__).parent.parent
definitions=[
('farpim','Bebê','farpim/overworld-anim-64-v1/farpim-left-atlas','farpim/overworld-anim-64-v1/farpim-right-atlas'),
('papisco','Criança','papisco/overworld-anim-64-v2/papisco-left','papisco/overworld-anim-64-v2/papisco-right'),
('velcao','Jovem','velcao/overworld-anim-64-v1/velcao-left','velcao/overworld-anim-64-v1/velcao-right'),
('alvacordo','Adulto','alvacordo/overworld-anim-64-v2/alvacordo-64',None)]
results=[]; configs=[]
for name,stage,left,right in definitions:
 j=json.loads((root/(left+'.json')).read_text(encoding='utf-8'))
 im=Image.open(root/(left+'.png')).convert('RGBA')
 fs=j['frames'];fs=list(fs.values()) if isinstance(fs,dict) else fs
 assert len(fs)==32,(name,len(fs))
 rim=Image.open(root/(right+'.png')).convert('RGBA') if right else None
 cells=[];mismatch=0
 for i,f in enumerate(fs):
  r=f['frame'];assert r['w']==64 and r['h']==64
  cell=im.crop((r['x'],r['y'],r['x']+64,r['y']+64))
  c=Counter(cell.get_flattened_data())
  assert not any(0<color[3]<255 for color in c),(name,i,'alpha')
  if rim:
   rc=rim.crop((i*64,0,i*64+64,64))
   mismatch+=sum(a!=b for a,b in zip(cell.transpose(Image.Transpose.FLIP_LEFT_RIGHT).get_flattened_data(),rc.get_flattened_data()))
  cells.append({'frame':i+1,'bounds':cell.getbbox(),'opaque_pixels':sum(n for c,n in c.items() if c[3]),'colors':sum(1 for c in c if c[3]),'duration_ms':f['duration']})
 assert mismatch==0,(name,mismatch)
 results.append({'id':name,'stage':stage,'canvas':[64,64],'mirror_mismatch':mismatch if rim else None,'frames':cells,'tags':j['meta']['frameTags']})
 configs.append({'id':name,'stage':stage,'left':'../'+left+'.png','right':'../'+right+'.png' if right else None,'durations':[f['duration'] for f in fs],'tags':j['meta']['frameTags']})
p=Path(__file__).parent
(p/'validacao.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
(p/'config.json').write_text(json.dumps(configs,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps([{'id':r['id'],'neutral_bounds':r['frames'][0]['bounds'],'mirror_mismatch':r['mirror_mismatch']} for r in results]))

