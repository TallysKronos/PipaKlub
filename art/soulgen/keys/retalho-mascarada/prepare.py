"""Mechanical extraction of spritelized design-C parts and complete expression heads."""
from pathlib import Path
from PIL import Image
import cv2,numpy as np,json
P=Path(__file__).parent/'cutout-rig-v1'
image=np.array(Image.open(P/'source.png').convert('RGBA'))
n,labels,stats,_=cv2.connectedComponentsWithStats((image[:,:,3]>100).astype('uint8'))
regions=[(i,s) for i,s in enumerate(stats) if i and s[4]>1000];assert len(regions)==10
regions.sort(key=lambda item:item[1][1]);rows=[sorted(regions[:3],key=lambda a:a[1][0]),sorted(regions[3:6],key=lambda a:a[1][0]),sorted(regions[6:9],key=lambda a:a[1][0]),regions[9:]]
ids=['body','head','armNear','armFar','legNear','legFar','tail','fierce','hurt','happy'];boxes={}
for name,(label,s) in zip(ids,sum(rows,[])):
 x,y,w,h=map(int,s[:4]);box=[max(0,x-4),max(0,y-4),min(image.shape[1],x+w+4),min(image.shape[0],y+h+4)]
 x0,y0,x1,y1=box;mask=cv2.dilate((labels==label).astype('uint8'),np.ones((5,5),np.uint8))
 part=image[y0:y1,x0:x1].copy();part[:,:,3]*=mask[y0:y1,x0:x1];part[part[:,:,3]==0]=0
 Image.fromarray(part).save(P/(name+'.png'));boxes[name]=box
head=Image.open(P/'head.png');bounds=head.getbbox();report={'windows':[[0,0,head.width,head.height]],'method':'Complete expression heads, aligned to canonical canvas; never mouth-only overlays.','expressions':{}}
for face in ['fierce','hurt','happy']:
 raw=Image.open(P/(face+'.png')).convert('RGBA');result=Image.new('RGBA',head.size)
 result.alpha_composite(raw.crop(raw.getbbox()).resize((bounds[2]-bounds[0],bounds[3]-bounds[1]),Image.Resampling.NEAREST),bounds[:2]);result.save(P/('head-'+face+'.png'))
 ratio=int((np.array(result)[:,:,3]>100).sum())/int((np.array(head)[:,:,3]>100).sum());assert ratio>.75
 report['expressions'][face]={'complete_head':True,'opaque_ratio':ratio,'canvas_identical':True}
(P/'registration.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(P/'slices.json').write_text(json.dumps({'sourceSize':[image.shape[1],image.shape[0]],'boxes':boxes},indent=2),encoding='utf-8')
