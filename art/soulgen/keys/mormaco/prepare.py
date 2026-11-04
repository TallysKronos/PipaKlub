"""Extract generated sprite ink components; preserve RGB, no pixel-art filter."""
from pathlib import Path
from PIL import Image,ImageChops
import cv2,numpy as np,json
P=Path(__file__).parent/'cutout-rig-v1'
image=np.array(Image.open(P/'source.png').convert('RGBA'))
n,labels,stats,_=cv2.connectedComponentsWithStats((image[:,:,3]>100).astype('uint8'))
regions=[(i,s) for i,s in enumerate(stats) if i and s[4]>2000]
assert len(regions)==14
regions.sort(key=lambda item:item[1][1])
rows=[sorted(regions[:4],key=lambda item:item[1][0]),sorted(regions[4:8],key=lambda item:item[1][0]),sorted(regions[8:12],key=lambda item:item[1][0]),sorted(regions[12:],key=lambda item:item[1][0])]
ids=['body','head','frontNear','frontFar','rearNear','rearFar','tail','sail','ribbon','geyserNear','geyserFar','fierce','hurt','happy']
boxes={}
for name,(label,s) in zip(ids,sum(rows,[])):
 x,y,w,h=map(int,s[:4]);x0=max(0,x-4);y0=max(0,y-4);x1=min(image.shape[1],x+w+4);y1=min(image.shape[0],y+h+4)
 mask=cv2.dilate((labels==label).astype('uint8'),np.ones((5,5),np.uint8))
 layer=image[y0:y1,x0:x1].copy();layer[:,:,3]*=mask[y0:y1,x0:x1];layer[layer[:,:,3]==0]=0
 Image.fromarray(layer).save(P/(name+'.png'));boxes[name]=[x0,y0,x1,y1]
head=Image.open(P/'head.png')
report={'windows':[[0,0,head.width,head.height]],'method':'Each expression is a complete registered head, including opaque face, neck, spikes, eyes and mouth. Never a mouth-only overlay.','expressions':{}}
normal_bounds=head.getbbox()
for face in ['fierce','hurt','happy']:
 raw=Image.open(P/(face+'.png')).convert('RGBA')
 bounds=raw.getbbox()
 result=Image.new('RGBA',head.size)
 target=(normal_bounds[2]-normal_bounds[0],normal_bounds[3]-normal_bounds[1])
 result.alpha_composite(raw.crop(bounds).resize(target,Image.Resampling.NEAREST),normal_bounds[:2])
 result.save(P/('head-'+face+'.png'))
 normal_count=int((np.array(head)[:,:,3]>100).sum())
 face_count=int((np.array(result)[:,:,3]>100).sum())
 assert face_count>normal_count*.75,(face,face_count,normal_count)
 report['expressions'][face]={'complete_head':True,'opaque_ratio':face_count/normal_count,'canvas_identical':result.size==head.size}
(P/'registration.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(P/'slices.json').write_text(json.dumps({'sourceSize':[image.shape[1],image.shape[0]],'boxes':boxes,'method':'Generated sprite component extraction; no redraw or palette substitution.'},indent=2),encoding='utf-8')
