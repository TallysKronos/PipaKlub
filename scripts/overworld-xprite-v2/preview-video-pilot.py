from pathlib import Path
from PIL import Image,ImageDraw
import json,numpy as np,sys
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'art/creatures/overworld-video-v2'
key=sys.argv[1];id,action,view=key.split('/');folder=OUT/'review'/key.replace('/','-')
source=Image.open(ROOT/'art/creatures/soulmonsters-overworld-v2'/id/'duas-vistas.png').convert('RGBA')
palette=np.array(sorted(set(c[:3] for c in source.getdata() if c[3])),dtype=np.float32)
sheet=Image.new('RGBA',(896,112));frames=[];stats=[]
for n in range(8):
    a=np.frombuffer((folder/f'pose-{n}-native.rgba').read_bytes(),dtype=np.uint8).reshape(112,112,4).copy()
    colors=a[:,:,:3].astype(np.float32);nearest=np.sum((colors[:,:,None,:]-palette[None,None,:,:])**2,axis=3).argmin(axis=2)
    a[:,:,:3]=palette[nearest].astype(np.uint8);a[:,:,3]=np.where(a[:,:,3]>=128,255,0)
    im=Image.fromarray(a);sheet.paste(im,(n*112,0));bg=Image.new('RGBA',(112,112),'#263d48');bg.alpha_composite(im);frames.append(bg.convert('RGB').resize((448,448),Image.Resampling.NEAREST));stats.append(dict(frame=n,bbox=im.getbbox(),opaque_pixels=int((a[:,:,3]>0).sum())))
sheet.save(folder/'spritesheet-experimental.png')
timing=json.loads((folder/'extraction.json').read_text())
frames[0].save(folder/'preview.gif',save_all=True,append_images=frames[1:],duration=round(1000*timing['frames']/timing['fps']/8),loop=0,disposal=2)
(folder/'pixel-report.json').write_text(json.dumps(dict(status='draft: needs pose/face/pixel review before integration',cell=[112,112],pivot=[56,100],colors=len(palette),poses=stats),indent=2))
print(key,'draft PNG/GIF ready; runtime not changed')
