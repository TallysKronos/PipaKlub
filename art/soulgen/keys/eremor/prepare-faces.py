"""Register AI-painted expressions inside fixed canonical head windows.

Only crop, align, resample and composite painted facial regions. No facial features
are drawn by code. Alpha and every pixel outside the windows remain canonical.
"""
from pathlib import Path
from collections import deque
from PIL import Image,ImageDraw,ImageFilter
import json,hashlib

root=Path(__file__).resolve().parent
original=Image.open(root/'parts/head.png').convert('RGBA')
sheet=Image.open(root/'source/expressions-generated.png').convert('RGBA')
w,h=sheet.size;alpha=sheet.getchannel('A').tobytes();seen=bytearray(w*h);regions=[]
for i in range(w*h):
    if seen[i] or alpha[i]<32:continue
    queue=deque([i]);seen[i]=1;left=w;right=0;top=h;bottom=0;count=0
    while queue:
        at=queue.popleft();x=at%w;y=at//w;count+=1
        left=min(left,x);right=max(right,x);top=min(top,y);bottom=max(bottom,y)
        for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            if 0<=nx<w and 0<=ny<h:
                p=ny*w+nx
                if not seen[p] and alpha[p]>=32:seen[p]=1;queue.append(p)
    if count>50000:regions.append((left,top,right+1,bottom+1))
assert len(regions)==4,regions
regions=sorted(regions,key=lambda b:(b[1]//(h//2),b[0]))
canonical=original.getchannel('A').point(lambda v:255 if v>=32 else 0).getbbox()
# Preserve muzzle and jaw completely. The entire eye/brow region is replaced at
# once so remnants of the neutral eyelid cannot become a second eye/brow.
windows=[(52,50,144,130)]
mask=Image.new('L',original.size)
for x,y,rw,rh in windows:
    local=Image.new('L',(rw,rh));d=ImageDraw.Draw(local)
    # Follow the painted eye region, excluding the unrelated forehead marking.
    polygon=[(54,132),(90,103),(107,70),(178,68),(190,126),(151,161),(105,155),(54,146)]
    d.polygon([(px-x,py-y) for px,py in polygon],fill=255)
    local=local.filter(ImageFilter.GaussianBlur(1.2));mask.paste(local,(x,y))
mask.save(root/'source/face-registration-mask.png')
report={'windows':windows,'canonicalSize':list(original.size),'alphaIdentical':True,'variants':{}}
comparison=Image.new('RGBA',(original.width*4,original.height+28),'#263c48')
comparison.alpha_composite(original,(0,28));draw=ImageDraw.Draw(comparison)
draw.text((8,7),'Neutra',fill='white')
for index,(name,label,region) in enumerate(zip(['headFierce','headHurt','headHappy'],['Golpe','Dano','Vitoria'],regions[1:]),1):
    painted=sheet.crop(region).resize((canonical[2]-canonical[0],canonical[3]-canonical[1]),Image.Resampling.LANCZOS)
    # Match the eye to the canonical face, not the generated sheet's outer bbox.
    aligned=original.copy();aligned.paste(painted,(canonical[0]-8,canonical[1]-9))
    aligned.save(root/'source'/(name+'-aligned.png'))
    result=Image.composite(aligned,original,mask);result.putalpha(original.getchannel('A'))
    changed=outside=0
    for a,b,m in zip(original.get_flattened_data(),result.get_flattened_data(),mask.get_flattened_data()):
        assert a[3]==b[3]
        if a!=b:
            changed+=1
            if not m:outside+=1
    assert changed>1000 and outside==0
    file=root/'parts'/(name+'.png');result.save(file)
    report['variants'][name]={'sourceBounds':region,'changedPixels':changed,'outsideWindowChanges':outside,'alphaIdentical':True,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()}
    comparison.alpha_composite(result,(original.width*index,28));draw.text((original.width*index+8,7),label,fill='white')
comparison.save(root/'review-faces-v3.png')
(root/'face-validation-v3.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps(report,indent=2))
