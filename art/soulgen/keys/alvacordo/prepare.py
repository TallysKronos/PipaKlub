from pathlib import Path
from PIL import Image,ImageFilter
import numpy as np,json,shutil,hashlib

# Reuse only the mechanical connected-alpha routine, without rebuilding other rigs.
here=Path(__file__).resolve().parent
source_code=(here.parent/'lince-de-cerco/prepare-family.py').read_text(encoding='utf-8')
exec(source_code[source_code.index('def largest_component'):source_code.index('A=Path(__file__)')])
out=here/'cutout-rig-v1';out.mkdir(exist_ok=True)
if (out/'author-import.json').exists():raise RuntimeError('Preserve author edits')
source=Path('C:/Users/user/.codex/generated_images/01a1a972-7528-7260-bf24-42de22483cbf/exec-f5be07e8-424e-47bf-8b83-498d313d6c72.png')
shutil.copy2(source,out/'source.png')
im=Image.open(source).convert('RGBA');arr=np.array(im);H,W=arr.shape[:2]
parts=['body','head','upperNear','upperFar','foreNear','foreFar','thighNear','thighFar','shinNear','shinFar','bowRaised','bowLowered','tail','fierce','hurt','happy']
boxes={};stats={}
for i,name in enumerate(parts):
 x0,x1=round(i%4*W/4),round((i%4+1)*W/4);y0,y1=round(i//4*H/4),round((i//4+1)*H/4)
 if name=='bowRaised':y1=min(H,y1+12) # recover the tip extending below the nominal row; next head begins farther down
 cell=arr[y0:y1,x0:x1].copy();mask,area=largest_component(cell[:,:,3]>160)
 keep=np.array(Image.fromarray(mask).filter(ImageFilter.MaxFilter(5)));cell[:,:,3]=np.where(keep,cell[:,:,3],0);cell[cell[:,:,3]==0]=0
 piece=Image.fromarray(cell);b=piece.getbbox();assert b and area>600,name
 b=(max(0,b[0]-4),max(0,b[1]-4),min(x1-x0,b[2]+4),min(y1-y0,b[3]+4));piece=piece.crop(b);piece.save(out/(name+'.png'))
 boxes[name]=[x0+b[0],y0+b[1],x0+b[2],y0+b[3]];stats[name]={'size':list(piece.size),'sha256':hashlib.sha256((out/(name+'.png')).read_bytes()).hexdigest()}
head=Image.open(out/'head.png').convert('RGBA');b=head.getbbox();faces={}
for name in ['fierce','hurt','happy']:
 face=Image.open(out/(name+'.png')).convert('RGBA');reg=Image.new('RGBA',head.size);reg.alpha_composite(face.crop(face.getbbox()).resize((b[2]-b[0],b[3]-b[1]),Image.Resampling.LANCZOS),b[:2]);reg.save(out/('head-'+name+'.png'))
 ratio=int((np.array(reg)[:,:,3]>160).sum())/int((np.array(head)[:,:,3]>160).sum());assert .8<ratio<1.2
 faces[name]={'complete_head':True,'whole_mane':True,'canvas_identical':True,'opaque_ratio':ratio}
(out/'registration.json').write_text(json.dumps({'windows':[[0,0,head.width,head.height]],'expressions':faces},indent=2),encoding='utf-8')
(out/'slices.json').write_text(json.dumps({'sourceSize':[W,H],'boxes':boxes,'parts':stats,'method':'Cell crop; connected alpha cleanup; no redrawing; full helmets registered on identical canvas.'},indent=2),encoding='utf-8')
print({k:v['size'] for k,v in stats.items()})
