from pathlib import Path
from PIL import Image
from collections import Counter
import numpy as np,json,math
OUT=Path(__file__).parent
source=Image.open(OUT.parent/'battle-pixel-v1/pose-gerada.png').convert('RGBA')
a=np.asarray(source);h,w=a.shape[:2]
candidates=json.loads((OUT/'local-grid-report.json').read_text())
period=candidates['joint_candidates'][0]['period']
signals=np.load(OUT/'signals.npz')
phases={}
for axis in ['x','y']:
 e=signals[axis];q=np.exp(-2j*np.pi*np.arange(len(e))/period).dot(e/e.sum())
 phases[axis]=float((-np.angle(q)*period/(2*np.pi))%period)
nx,ny=round(w/period),round(h/period)
pal=['#090b13','#20232e','#353640','#51515d','#76717a','#aaa1a0','#d1c6be','#eee2d3','#fff5df','#ffffff','#032d32','#06464e','#09616d','#15858b','#51a7a6','#593515','#966119','#ce9629','#f5c655','#ffe599','#65150e','#b62b19','#f14a28','#ff8858']
rgb=np.array([[int(c[i:i+2],16) for i in [1,3,5]] for c in pal],dtype=float)
symbols='ABCDEFGHIJKLMNOPQRSTUVWX';legend=dict(zip(symbols,pal))
def quant(c):
 if c[3]<128:return '.'
 dist=((rgb-np.array(c[:3]))**2*np.array([2,3,2])).sum(axis=1)
 return symbols[int(dist.argmin())]
cache={}
def q(c):
 c=tuple(int(v) for v in c)
 if c not in cache:cache[c]=quant(c)
 return cache[c]
control=[];recovered=[];samples=[]
for iy in range(ny):
 cr='';rr=''
 for ix in range(nx):
  xx=min(w-1,int((ix+.5)*w/nx));yy=min(h-1,int((iy+.5)*h/ny))
  cr+=q(a[yy,xx])
  cx=phases['x']+(ix+.5)*period;cy=phases['y']+(iy+.5)*period
  radius=period*.22
  x0=max(0,int(math.ceil(cx-radius)));x1=min(w,int(math.floor(cx+radius))+1)
  y0=max(0,int(math.ceil(cy-radius)));y1=min(h,int(math.floor(cy+radius))+1)
  if x0>=x1 or y0>=y1:rr+='.';samples.append([0,0,0,0]);continue
  crop=a[y0:y1,x0:x1].reshape(-1,4)
  if np.count_nonzero(crop[:,3]>=128)<len(crop)/2:
   rr+='.';samples.append([0,0,0,0]);continue
  opaque=crop[crop[:,3]>=128]
  # Select an existing source RGBA; ties favor the source pixel nearest the cell center.
  count=Counter(tuple(int(t) for t in v) for v in opaque)
  maxcount=max(count.values());tied={c for c,n in count.items() if n==maxcount}
  best=None;bestd=1e30
  for sy in range(y0,y1):
   for sx in range(x0,x1):
    c=tuple(int(t) for t in a[sy,sx])
    d=(sx-cx)**2+(sy-cy)**2
    if c in tied and d<bestd:bestd=d;best=c
  rr+=q(best);samples.append(list(best))
 control.append(cr);recovered.append(rr)
# Positive control: a synthetic regularly spaced block pattern with a known fractional period.
rng=np.random.default_rng(19);known=9.31
labels=rng.integers(0,8,size=(60,60));scol=np.array([[20,20,20],[240,220,180],[3,80,90],[120,90,40],[200,30,20],[40,45,55],[0,0,0],[255,255,255]],float)
coords=np.floor((np.arange(512)+.5-2.4)/known).astype(int)+2
test=scol[labels[coords[:,None],coords[None,:]]]
positive={}
for axis in [1,0]:
 e=np.linalg.norm(np.diff(test,axis=axis),axis=2).sum(axis=0 if axis==1 else 1)
 freqs=np.linspace(1/18,1/3,10000);score=np.abs(np.exp(-2j*np.pi*freqs[:,None]*np.arange(len(e))).dot(e/e.sum()))
 i=int(score.argmax());positive['x' if axis==1 else 'y']={'known':known,'detected':float(1/freqs[i]),'coherence':float(score[i])}
result={'source_size':[w,h],'period_candidate':period,'phase_estimates':phases,'output_size':[nx,ny],'sampling':'mode of central44percent; ties nearest center; alpha majority128; same24color palette after sampling','square_grid_assumption':True,'confidence_note':'Ambiguous: top two joint peaks are close and local regions disagree; this is an experimental candidate, not a proven unique original grid.','joint_candidates':candidates['joint_candidates'][:3],'positive_control':positive}
(OUT/'measurement.json').write_text(json.dumps(result,indent=2))
(OUT/'sampled-source-rgba.json').write_text(json.dumps(samples))
(OUT/'grids.json').write_text(json.dumps({'legend':legend,'width':nx,'height':ny,'control':control,'recovered':recovered}))
print(json.dumps(result,indent=2))

