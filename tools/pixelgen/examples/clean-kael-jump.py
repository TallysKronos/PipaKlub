"""Plan targeted Aseprite pixel fixes. Never writes the working sprite document.

Only detached 1/2-pixel islands, the outside ink contour and the labelled pants
material change. Pose, grid, palette, scale, anchors and frame timing stay fixed.
"""
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'tmp/kael-jump-clean-plan'
SOURCE=ROOT/'art/characters/kael-video-jump-v1/cleanup/before.pixelgen.json'
W,H=96,112
REGIONS=[
 [35,80,55,98],[36,81,57,100],[35,87,60,99],[35,88,60,100],
 [35,88,60,100],[33,80,59,99],[31,83,64,101],[31,84,65,102],
 [30,84,65,102],[30,84,65,102],[34,81,61,99],[35,85,59,99],
 [35,88,60,99],[35,88,60,99],[35,88,60,99],[35,80,57,98],
 [36,80,56,98],[35,81,57,99],[36,92,60,102],[36,93,59,103],
 [34,86,60,101],[33,79,58,99],[28,80,60,100],[30,82,63,100],
 [28,83,63,101],[28,83,63,101],[28,83,63,101],[28,83,63,101],
 [32,85,61,101],[35,85,61,99],[35,87,61,100],[36,80,56,98]]

def clean(indices,region,width=W,height=H):

    W,H=width,height
    out=indices.copy();visited=set();removed=0
    for start,v in enumerate(indices):
        if not v or start in visited:continue
        component=[];stack=[start];visited.add(start)
        while stack:
            at=stack.pop();component.append(at);x,y=at%W,at//W
            for dy in [-1,0,1]:
                for dx in [-1,0,1]:
                    xx,yy=x+dx,y+dy
                    if not (0<=xx<W and 0<=yy<H):continue
                    to=yy*W+xx
                    if indices[to] and to not in visited:visited.add(to);stack.append(to)
        if len(component)<=2:
            for at in component:out[at]=0;removed+=1
    # Annotated material region, not a whole-frame hue/brightness operation.
    l,t,r,b=region;pants=0
    mapping={6:6,7:6,8:6,9:6,21:19,25:19,26:19}
    for y in range(t,b):
        for x in range(l,r):
            at=y*W+x;v=out[at]
            if v in mapping and v!=mapping[v]:out[at]=mapping[v];pants+=1
    ink=31;edge=0;body=out.copy()
    # One native-pixel contour, without growing or eroding the silhouette.
    for at,v in enumerate(body):
        if not v:continue
        x,y=at%W,at//W
        boundary=any(xx<0 or xx>=W or yy<0 or yy>=H or not body[yy*W+xx]
                     for xx,yy in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)])
        if boundary and out[at]!=ink:out[at]=ink;edge+=1
    return out,{'islandPixelsRemoved':removed,'pantsRemapped':pants,'contourRemapped':edge}

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    p=json.loads(SOURCE.read_text());pal=p['palette']
    glyphs='.'+'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    legend={glyphs[i]:'#'+''.join(f'{c:02x}' for c in color) for i,color in enumerate(pal)}
    reports=[];before=[];after=[]
    for i,f in enumerate(p['frames']):
        source=f['indices'];fixed,report=clean(source,REGIONS[i])
        changed=[j for j,(a,b) in enumerate(zip(source,fixed)) if a!=b]
        count=sum(bool(v) for v in source)
        report.update(frame=i+1,changedPixels=len(changed),opaquePixels=count,changedFraction=len(changed)/count,region=REGIONS[i])
        reports.append(report)
        x0=min(j%W for j in changed);x1=max(j%W for j in changed)+1
        y0=min(j//W for j in changed);y1=max(j//W for j in changed)+1
        rows=[''.join(glyphs[fixed[y*W+x]] for x in range(x0,x1)) for y in range(y0,y1)]
        plan={'sprite':'#794','frame':i+1,'paletteLock':True,'label':'Limpar contorno e fixar tons da calça',
              'ops':[{'kind':'grid','x':x0,'y':y0,'rows':rows,'legend':legend}]}
        (OUT/f'frame-{i:02d}.json').write_text(json.dumps(plan),encoding='utf8')
        for dest,values in [(before,source),(after,fixed)]:
            im=Image.new('RGBA',(W,H));im.putdata([tuple(pal[v]) for v in values]);dest.append(im)
    # Diagnostic only: compare targeted proposals over light/dark backgrounds.
    board=Image.new('RGB',(W*4*8,H*4*2+60),'#e5dfd3');draw=ImageDraw.Draw(board)
    for col,idx in enumerate([0,3,6,9,16,19,23,29]):
        for row,images in enumerate([before,after]):
            im=images[idx].resize((W*4,H*4),Image.Resampling.NEAREST)
            pos=(col*W*4,row*(H*4+30)+30);board.paste(im,pos,im)
            draw.text((pos[0]+4,pos[1]-20),f'{"A" if row==0 else "B"} / {idx+1}',fill='#172338')
    board.save(OUT/'comparison.png')
    (OUT/'report.json').write_text(json.dumps(reports,indent=2))
    policy={'pants':{'baseIndex':6,'shadowIndex':19,'sourceIndices':list([6,7,8,9,21,25,26]),'regions':REGIONS},'outlineIndex':31,'removeDetachedMaxPixels':2}
    (OUT/'policy.json').write_text(json.dumps(policy,indent=2))
    print(json.dumps({'frames':32,'changedPixels':sum(r['changedPixels'] for r in reports),'maxFraction':max(r['changedFraction'] for r in reports),'plan':str(OUT)}))

if __name__=='__main__':main()
