"""Non-destructive source crops and generated expression-window registration."""
from pathlib import Path
from PIL import Image,ImageChops
import json
import cv2,numpy as np
P=Path(__file__).parent/'cutout-rig-v1'
source=Image.open(P/'source.png').convert('RGBA')
boxes={'body':(33,37,575,435),'head':(581,132,908,380),'frontNear':(871,51,1164,468),'frontFar':(1198,51,1475,428),'rearNear':(55,432,295,749),'rearFar':(351,434,612,747),'tail':(581,434,1213,762),'equipment':(1143,418,1532,746),'fierce':(54,749,422,995),'hurt':(448,748,792,994),'happy':(816,748,1176,992)}
# Adjacent rear leg/tail overlap bounding rectangles, not painted silhouettes.
for name,box in boxes.items():
 part=source.crop(box)
 if name=='rearFar':
  # Remove only neighboring tail pixels inside rectangle at x>=589,y<530.
  alpha=part.getchannel('A'); from PIL import ImageDraw
  ImageDraw.Draw(alpha).rectangle((238,0,261,95),fill=0);part.putalpha(alpha)
 if name=='tail':
  alpha=part.getchannel('A'); from PIL import ImageDraw
  ImageDraw.Draw(alpha).polygon([(0,100),(35,128),(35,328),(0,328)],fill=0);part.putalpha(alpha)
 part.save(P/(name+'.png'))
 # Keep only the anatomical component named by this crop. Overlapping bounding
 # boxes must not bring floating pixels from the adjacent sail, foot or tail.
 pixels=np.array(part);n,labels,stats,_=cv2.connectedComponentsWithStats((pixels[:,:,3]>8).astype('uint8'))
 keep=1+int(np.argmax(stats[1:,4]));pixels[:,:,3][labels!=keep]=0
 Image.fromarray(pixels).save(P/(name+'.png'))
head=Image.open(P/'head.png');windows=[(26,138,95,178),(10,176,145,236)]
report={'windows':[[a,b,c-a,d-b] for a,b,c,d in windows],'method':'Generated eyes/mouth aligned within canonical head; alpha and pixels outside face windows unchanged.','expressions':{}}
for face in ['fierce','hurt','happy']:
 raw=Image.open(P/(face+'.png'));raw=raw.crop(raw.getbbox()).resize((311,232),Image.Resampling.NEAREST)
 aligned=Image.new('RGBA',head.size);aligned.alpha_composite(raw,(8,8))
 result=head.copy()
 for box in windows:result.alpha_composite(aligned.crop(box),box[:2])
 result.putalpha(head.getchannel('A'));result.save(P/('head-'+face+'.png'))
 diff=ImageChops.difference(head,result)
 for box in windows:diff.paste((0,0,0,0),box)
 assert not diff.convert('RGB').getbbox()
 report['expressions'][face]={'outside_window_identical':True,'alpha_identical':True}
(P/'registration.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(P/'slices.json').write_text(json.dumps({'sourceSize':source.size,'boxes':boxes},indent=2),encoding='utf-8')
