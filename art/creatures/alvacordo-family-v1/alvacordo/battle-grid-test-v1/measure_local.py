from pathlib import Path
from PIL import Image
import numpy as np,json
OUT=Path(__file__).parent
a=np.asarray(Image.open(OUT.parent/'battle-pixel-v1/pose-gerada.png').convert('RGBA'),float);rgb=a[:,:,:3];valid=a[:,:,3]>216
regions={'head':[360,130,680,420],'chest':[270,400,730,750],'near_bow':[20,90,350,570],'far_bow':[710,520,1015,970],'legs':[190,820,750,1450]}
freq=np.linspace(1/18,1/3,12000)
reports={}
global_sigs=np.load(OUT/'signals.npz')
def score(e):
 x=np.arange(len(e));e=e/(e.sum()+1e-9);return np.abs(np.exp(-2j*np.pi*freq[:,None]*x).dot(e))
sx=score(global_sigs['x']);sy=score(global_sigs['y']);joint=np.sqrt(sx*sy)
peaks=[i for i in range(1,len(freq)-1) if joint[i]>joint[i-1] and joint[i]>=joint[i+1]]
chosen=[]
for i in sorted(peaks,key=lambda i:joint[i],reverse=True):
 p=1/freq[i]
 if all(abs(p-v['period'])>.12 for v in chosen):chosen.append({'period':float(p),'x':float(sx[i]),'y':float(sy[i]),'joint':float(joint[i])})
 if len(chosen)==10:break
for name,(x0,y0,x1,y1) in regions.items():
 r=rgb[y0:y1,x0:x1];v=valid[y0:y1,x0:x1]
 dx=np.maximum(np.sqrt(np.sum(np.diff(r,axis=1)**2,axis=2))-14,0)*(v[:,1:]&v[:,:-1])
 dy=np.maximum(np.sqrt(np.sum(np.diff(r,axis=0)**2,axis=2))-14,0)*(v[1:,:]&v[:-1,:])
 row={}
 for axis,e in [('x',np.r_[0,dx.sum(axis=0)]),('y',np.r_[0,dy.sum(axis=1)])]:
  s=score(e);is_=sorted([i for i in range(1,len(s)-1) if s[i]>s[i-1] and s[i]>=s[i+1]],key=lambda i:s[i],reverse=True)[:3]
  row[axis]=[{'period':float(1/freq[i]),'coherence':float(s[i])} for i in is_]
 reports[name]=row
res={'joint_candidates':chosen,'regions':reports}
(OUT/'local-grid-report.json').write_text(json.dumps(res,indent=2))
print(json.dumps(res,indent=2))

