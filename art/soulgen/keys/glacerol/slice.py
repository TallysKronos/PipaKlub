"""Extract nine separate source components with original RGBA near the ink."""
from pathlib import Path
import cv2, numpy as np, json
from PIL import Image
root=Path(__file__).resolve().parent/'cutout-rig-v1'
image=np.array(Image.open(root/'source.png').convert('RGBA'))
count,labels,stats,centers=cv2.connectedComponentsWithStats((image[:,:,3]>=160).astype('uint8'),8)
regions=sorted([(i,s) for i,s in enumerate(stats) if i and s[4]>500],key=lambda q:q[1][1])
assert len(regions)==9
regions=[*sorted(regions[:3],key=lambda q:q[1][0]),*sorted(regions[3:6],key=lambda q:q[1][0]),*sorted(regions[6:],key=lambda q:q[1][0])]
ids=['body','head','frontNear','frontFar','hindNear','hindFar','tail','threadNear','threadFar']
report={'sourceSize':[image.shape[1],image.shape[0]],'method':'Nine disjoint alpha ink components; retain original RGBA within four pixels of each part, exclude distant haze.','parts':{}}
for id,(label,s) in zip(ids,regions):
    mask=cv2.dilate((labels==label).astype('uint8'),np.ones((9,9),np.uint8))
    x,y,w,h=map(int,s[:4]);x0=max(0,x-4);y0=max(0,y-4);x1=min(image.shape[1],x+w+4);y1=min(image.shape[0],y+h+4)
    layer=image[y0:y1,x0:x1].copy();layer[:,:,3]*=mask[y0:y1,x0:x1];layer[layer[:,:,3]==0]=0
    Image.fromarray(layer).save(root/(id+'.png'));report['parts'][id]={'crop':[x0,y0,x1-x0,y1-y0],'seed_pixels':int(s[4])}
(root/'slices.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8');print(report)
