from pathlib import Path
from PIL import Image
import json,hashlib
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/creatures/azulfazo-hibrido-v1'
source=Image.open(ROOT/'art/creatures/soulmonsters-overworld-v2/azulfazo/duas-vistas.png').convert('RGBA')
allowed={c for c in source.getdata() if c[3]}
manifest=dict(cell=[112,112],anchor=[56,100],views=['sw','nw'],runtime_replaced=False,method='Source face/body/tail retained; video-guided native wing and talon drawings',animations={})
if (OUT/'manifest.json').exists():
 previous=json.loads((OUT/'manifest.json').read_text())
 for key in ['runtime_replaced','approval_date','status','review_score','blocking_findings']:
  if key in previous: manifest[key]=previous[key]
results={}
for action,count,durations in [('idle',4,[400,150,400,150]),('walk',6,[140,100,120,140,100,120])]:
 sheet=Image.open(OUT/f'{action}.png').convert('RGBA')
 assert sheet.size==(112*count,224)
 frames=[];stats=[];contact=Image.new('RGB',(count*224,448),'#263d48')
 for f in range(count):
  pair=Image.new('RGBA',(224,112))
  for v in range(2):
   im=sheet.crop((f*112,v*112,(f+1)*112,(v+1)*112));pair.paste(im,(v*112,0))
   colors={c for c in im.getdata() if c[3]}
   extra=colors-allowed
   assert not extra,extra
   assert all(c[3] in (0,255) for c in im.getdata())
   bounds=im.getbbox()
   assert bounds and bounds[0]>0 and bounds[1]>0 and bounds[2]<112 and bounds[3]<112
   stats.append(dict(frame=f,view=['sw','nw'][v],bounds=bounds,opaque=sum(c[3]>0 for c in im.getdata()),colors=len(colors),hash=hashlib.sha256(im.tobytes()).hexdigest()))
   big=im.resize((224,224),Image.Resampling.NEAREST);contact.paste(big,(f*224,v*224),big)
  bg=Image.new('RGBA',(224,112),'#263d48');bg.alpha_composite(pair)
  frames.append(bg.convert('RGB').resize((672,336),Image.Resampling.NEAREST))
 frames[0].save(OUT/f'{action}.gif',save_all=True,append_images=frames[1:],duration=durations,loop=0,disposal=2)
 contact.save(OUT/f'{action}-poses.png')
 results[action]=stats
 manifest['animations'][action]=dict(image=action+'.png',frames=count,durations_ms=durations,loop=True)
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(OUT/'validacao.json').write_text(json.dumps(results,indent=2)+'\n')
print('validated 20 native frames, exact source palette and binary alpha')
