from pathlib import Path
from PIL import Image
import numpy as np,json
OUT=Path(__file__).parent
SOURCE=OUT.parent/'battle-pixel-v1/pose-gerada.png'
a=np.asarray(Image.open(SOURCE).convert('RGBA'),dtype=np.float64)
rgb=a[:,:,:3];alpha=a[:,:,3]/255
# Ignore the translucent generated glow; retain material edges inside the subject.
valid=alpha>.85
dx=np.sqrt(np.sum(np.diff(rgb,axis=1)**2,axis=2))
dy=np.sqrt(np.sum(np.diff(rgb,axis=0)**2,axis=2))
dx*=valid[:,1:]&valid[:,:-1]
dy*=valid[1:,:]&valid[:-1,:]
# Suppress tiny textured noise; strong transitions keep their original magnitudes.
dx=np.maximum(dx-14,0);dy=np.maximum(dy-14,0)
ex=np.r_[0,dx.sum(axis=0)];ey=np.r_[0,dy.sum(axis=1)]
np.savez(OUT/'signals.npz',x=ex,y=ey)
report={}
for axis,e in [('x',ex),('y',ey)]:
 n=len(e);frequencies=np.linspace(1/18,1/3,16000)
 x=np.arange(n);weights=e/e.sum()
 amplitudes=np.abs(np.exp(-2j*np.pi*frequencies[:,None]*x).dot(weights))
 peaks=[i for i in range(1,len(amplitudes)-1) if amplitudes[i]>amplitudes[i-1] and amplitudes[i]>=amplitudes[i+1]]
 peaks=sorted(peaks,key=lambda i:amplitudes[i],reverse=True)
 chosen=[]
 for idx in peaks:
  p=1/frequencies[idx]
  if all(abs(p-c['period'])>.13 for c in chosen):
   coefficient=np.exp(-2j*np.pi*frequencies[idx]*x).dot(weights)
   phase=(-np.angle(coefficient)/(2*np.pi)*p)%p
   chosen.append({'period':float(p),'edge_phase':float(phase),'coherence':float(amplitudes[idx])})
  if len(chosen)==12:break
 report[axis]=chosen
print(json.dumps(report,indent=2))
(OUT/'frequency-candidates.json').write_text(json.dumps(report,indent=2))

