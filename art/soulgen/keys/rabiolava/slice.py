"""Extract six disjoint generated parts; preserve source RGBA near each part's ink."""
from pathlib import Path
import json
import cv2
import numpy as np
from PIL import Image

root=Path(__file__).resolve().parent/'cutout-rig-v1'
image=np.array(Image.open(root/'source.png').convert('RGBA'))
count,labels,stats,centers=cv2.connectedComponentsWithStats((image[:,:,3]>=160).astype('uint8'),8)
regions=sorted([(i,s) for i,s in enumerate(stats) if i and s[4]>1000],key=lambda item:item[1][1])
assert len(regions)==6, 'Expected six separate parts'
ids=['finNear','body','head','finFar','tailNear','tailFar']
report={'sourceSize':[image.shape[1],image.shape[0]],'method':'Six disjoint alpha ink components; original RGBA retained within four pixels of each component; distant generated haze excluded.','parts':{}}
for id,(label,stat) in zip(ids,regions):
    mask=cv2.dilate((labels==label).astype('uint8'),np.ones((9,9),np.uint8))
    x,y,w,h=map(int,stat[:4]);x0=max(0,x-4);y0=max(0,y-4);x1=min(image.shape[1],x+w+4);y1=min(image.shape[0],y+h+4)
    layer=image[y0:y1,x0:x1].copy()
    layer[:,:,3]*=mask[y0:y1,x0:x1]
    layer[layer[:,:,3]==0]=0
    Image.fromarray(layer).save(root/(id+'.png'))
    report['parts'][id]={'crop':[x0,y0,x1-x0,y1-y0],'seed_pixels':int(stat[4])}
(root/'slices.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(report)
