"""Extract seven generated alpha islands; preserve RGB and original edge alpha.

No anatomy is painted. Two pixels around each alpha>=32 island retain its original
antialias. This excludes neighbouring parts whose bounding rectangles overlap.
"""
from pathlib import Path
from collections import deque
from PIL import Image, ImageFilter, ImageChops
import hashlib,json

root=Path(__file__).resolve().parent
source=root/'source/parts-clean.png'
im=Image.open(source).convert('RGBA');w,h=im.size
a=im.getchannel('A');alpha=a.tobytes();seen=bytearray(w*h);regions=[]
for i in range(w*h):
    if seen[i] or alpha[i]<32:continue
    q=deque([i]);seen[i]=1;pixels=[]
    while q:
        at=q.popleft();pixels.append(at);x=at%w;y=at//w
        for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            p=ny*w+nx
            if 0<=nx<w and 0<=ny<h and not seen[p] and alpha[p]>=32:seen[p]=1;q.append(p)
    if len(pixels)>10000:regions.append(pixels)
assert len(regions)==7, f'Expected seven anatomy islands, found {len(regions)}'
names=['body','head','armNear','armFar','sails','tail','knot']
centers=[(300,200),(800,200),(1300,200),(200,600),(750,560),(1350,630),(250,890)]
out=root/'parts';out.mkdir(exist_ok=True)
report={'source':'source/parts-clean.png','sourceSHA256':hashlib.sha256(source.read_bytes()).hexdigest(),'sourceSize':[w,h],'method':'alpha>=32 connected islands + 2px original antialias; RGB unchanged','parts':{}}
assigned=set()
for name,(cx,cy) in zip(names,centers):
    pixels=min((p for j,p in enumerate(regions) if j not in assigned),key=lambda p:min((at%w-cx)**2+(at//w-cy)**2 for at in p))
    assigned.add(next(j for j,p in enumerate(regions) if p is pixels))
    raw=bytearray(w*h)
    for at in pixels:raw[at]=255
    mask=Image.frombytes('L',(w,h),bytes(raw)).filter(ImageFilter.MaxFilter(5))
    isolated=im.copy();isolated.putalpha(ImageChops.darker(a,mask))
    bbox=isolated.getbbox();pad=3
    box=(max(0,bbox[0]-pad),max(0,bbox[1]-pad),min(w,bbox[2]+pad),min(h,bbox[3]+pad))
    cut=isolated.crop(box);file=out/(name+'.png');cut.save(file)
    report['parts'][name]={'sourceBounds':list(box),'size':list(cut.size),'alpha':list(cut.getchannel('A').getextrema()),'sha256':hashlib.sha256(file.read_bytes()).hexdigest()}
(root/'parts-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps(report,indent=2))
