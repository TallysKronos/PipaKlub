"""Extract generated sprite ink components; preserve RGB, no pixel-art filter."""
from pathlib import Path
from PIL import Image,ImageChops
import cv2,numpy as np,json
P=Path(__file__).parent/'cutout-rig-v2'
image=np.array(Image.open(P/'source.png').convert('RGBA'))
n,labels,stats,_=cv2.connectedComponentsWithStats((image[:,:,3]>100).astype('uint8'))
regions=[(i,s) for i,s in enumerate(stats) if i and s[4]>2000]
assert len(regions)==11
regions.sort(key=lambda item:item[1][1])
rows=[sorted(regions[:4],key=lambda item:item[1][0]),sorted(regions[4:8],key=lambda item:item[1][0]),sorted(regions[8:],key=lambda item:item[1][0])]
ids=['body','head','frontNear','frontFar','rearNear','rearFar','tail','equipment','fierce','hurt','happy']
boxes={}
for name,(label,s) in zip(ids,sum(rows,[])):
 x,y,w,h=map(int,s[:4]);x0=max(0,x-4);y0=max(0,y-4);x1=min(image.shape[1],x+w+4);y1=min(image.shape[0],y+h+4)
 mask=cv2.dilate((labels==label).astype('uint8'),np.ones((5,5),np.uint8))
 layer=image[y0:y1,x0:x1].copy();layer[:,:,3]*=mask[y0:y1,x0:x1];layer[layer[:,:,3]==0]=0
 Image.fromarray(layer).save(P/(name+'.png'));boxes[name]=[x0,y0,x1,y1]
head=Image.open(P/'head.png');windows=[(35,147,105,190),(0,178,166,258)]
report={'windows':[[a,b,c-a,d-b] for a,b,c,d in windows],'method':'Generated sprite heads aligned; eye/mouth windows replaced including jaw alpha to avoid a duplicate closed jaw beneath the open mouth. Outside-window RGBA unchanged.','expressions':{}}
for face in ['fierce','hurt','happy']:
 raw=Image.open(P/(face+'.png'));raw=raw.crop(raw.getbbox()).resize((327,250),Image.Resampling.NEAREST)
 aligned=Image.new('RGBA',head.size);aligned.alpha_composite(raw,(4,4))
 result=head.copy()
 for box in windows:result.paste(aligned.crop(box),box[:2])
 result.save(P/('head-'+face+'.png'))
 diff=ImageChops.difference(head,result)
 for box in windows:diff.paste((0,0,0,0),box)
 assert not diff.convert('RGB').getbbox()
 report['expressions'][face]={'outside_window_identical':True,'mouth_alpha_can_change':True}
(P/'registration.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(P/'slices.json').write_text(json.dumps({'sourceSize':[image.shape[1],image.shape[0]],'boxes':boxes,'method':'Generated sprite component extraction; no redraw or palette substitution.'},indent=2),encoding='utf-8')
