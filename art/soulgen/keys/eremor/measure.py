"""Measure connected alpha islands without drawing or repainting the generated art."""
from PIL import Image
from pathlib import Path
from collections import deque
import json
import sys

root=Path(__file__).resolve().parent
im=Image.open(root/'source/parts-clean.png').convert('RGBA')
w,h=im.size
alpha=im.getchannel('A').tobytes()
threshold=int(sys.argv[1]) if len(sys.argv)>1 else 32
seen=bytearray(w*h)
regions=[]
for i in range(w*h):
    if seen[i] or alpha[i]<threshold: continue
    todo=deque([i]);seen[i]=1;pixels=[];left=w;top=h;right=0;bottom=0
    while todo:
        at=todo.popleft();x=at%w;y=at//w;pixels.append(at)
        left=min(left,x);right=max(right,x);top=min(top,y);bottom=max(bottom,y)
        for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            if 0<=nx<w and 0<=ny<h:
                p=ny*w+nx
                if not seen[p] and alpha[p]>=threshold:seen[p]=1;todo.append(p)
    if len(pixels)>200:regions.append({'count':len(pixels),'bounds':[left,top,right+1,bottom+1]})
print(json.dumps({'size':[w,h],'alpha':im.getchannel('A').getextrema(),'regions':sorted(regions,key=lambda r:-r['count'])},indent=2))
