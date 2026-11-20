"""Mechanical alpha component extraction only; does not paint/redesign creature pixels."""
from pathlib import Path
from PIL import Image,ImageFilter
import numpy as np,json,shutil,hashlib
def largest_component(mask):
    parents=[];runs=[];previous=[]
    def root(i):
        while parents[i]!=i:parents[i]=parents[parents[i]];i=parents[i]
        return i
    for y,row in enumerate(mask):
        d=np.diff(np.pad(row.astype('int8'),(1,1)));starts=np.where(d==1)[0];ends=np.where(d==-1)[0];current=[]
        for left,right in zip(starts,ends):
            i=len(parents);parents.append(i);runs.append((y,int(left),int(right),i));current.append((int(left),int(right),i))
            for a,b,j in previous:
                if b<left:continue
                if a>right:break
                parents[root(i)]=root(j)
        previous=current
    totals={}
    for y,a,b,i in runs:rr=root(i);totals[rr]=totals.get(rr,0)+b-a
    best=max(totals,key=totals.get);out=np.zeros(mask.shape,dtype='uint8')
    for y,a,b,i in runs:
        if root(i)==best:out[y,a:b]=255
    return out,totals[best]
A=Path(__file__).resolve().parent;K=A.parent
G=Path('C:/Users/user/.codex/generated_images/01a1a972-7528-7260-bf24-42de22483cbf')
configs=json.loads((A/'family-config.json').read_text(encoding='utf-8'))
for c in configs:
    F=K/c['id']/'cutout-rig-v1';F.mkdir(parents=True,exist_ok=True)
    shutil.copy2(G/c['source'],F/'source.png');(F/'prompt.txt').write_text(c['prompt'],encoding='utf-8')
    arr=np.array(Image.open(F/'source.png').convert('RGBA'));H,W=arr.shape[:2];boxes={};stats_out={}
    assert arr[:,:,3].min()==0,'Source must contain real transparent alpha'
    for i,name in enumerate(c['parts']):
        col,row=i%4,i//4;x0=round(col*W/4);x1=round((col+1)*W/4);y0=round(row*H/c['rows']);y1=round((row+1)*H/c['rows'])
        cell=arr[y0:y1,x0:x1].copy();mask,area=largest_component(cell[:,:,3]>160)
        # Keep antialiased pixels adjacent to the connected silhouette; remove detached source speckles.
        keep=np.array(Image.fromarray(mask).filter(ImageFilter.MaxFilter(5)));cell[:,:,3]=np.where(keep,cell[:,:,3],0);cell[cell[:,:,3]==0]=0
        im=Image.fromarray(cell);bounds=im.getbbox();assert bounds and area>600,(c['id'],name,'empty/too small')
        pad=4;bx0=max(0,bounds[0]-pad);by0=max(0,bounds[1]-pad);bx1=min(cell.shape[1],bounds[2]+pad);by1=min(cell.shape[0],bounds[3]+pad)
        piece=im.crop((bx0,by0,bx1,by1));piece.save(F/(name+'.png'));boxes[name]=[x0+bx0,y0+by0,x0+bx1,y0+by1]
        stats_out[name]={'size':list(piece.size),'opaque_pixels':int((np.array(piece)[:,:,3]>160).sum()),'cell':[x0,y0,x1,y1],'sha256':hashlib.sha256((F/(name+'.png')).read_bytes()).hexdigest()}
    head_id='body' if c['rows']==2 else 'head';head=Image.open(F/(head_id+'.png')).convert('RGBA');normal_box=head.getbbox();registration={}
    for face in ['fierce','hurt','happy']:
        im=Image.open(F/(face+'.png')).convert('RGBA');b=im.getbbox();out=Image.new('RGBA',head.size)
        out.alpha_composite(im.crop(b).resize((normal_box[2]-normal_box[0],normal_box[3]-normal_box[1]),Image.Resampling.LANCZOS),normal_box[:2]);out.save(F/('head-'+face+'.png'))
        ratio=int((np.array(out)[:,:,3]>160).sum())/int((np.array(head)[:,:,3]>160).sum());assert .72<ratio<1.35,(c['id'],face,ratio)
        registration[face]={'complete_head':True,'canvas_identical':out.size==head.size,'opaque_ratio':ratio}
    (F/'registration.json').write_text(json.dumps({'headPart':head_id,'windows':[[0,0,head.width,head.height]],'expressions':registration,'method':'Whole head replaces whole head on equal canvas; opaque region retained, no mouth-only overlay.'},indent=2),encoding='utf-8')
    (F/'slices.json').write_text(json.dumps({'sourceSize':[W,H],'boxes':boxes,'parts':stats_out,'method':'Regular cell extraction, connected alpha silhouette plus 2px antialias border; RGB preserved.'},indent=2),encoding='utf-8')
    print(c['id'],{k:v['size'] for k,v in stats_out.items()})
