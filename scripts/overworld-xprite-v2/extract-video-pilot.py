"""Extract motion poses, key a solid background, keep a fixed source-space transform.
No per-frame bounding-box normalization: it would erase weight and make feet skate.
Draft outputs only; runtime remains unchanged.
"""
from pathlib import Path
from PIL import Image,ImageDraw
import cv2,numpy as np,json,sys
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'art/creatures/overworld-video-v2'
queue=json.loads((OUT/'queue.json').read_text(encoding='utf-8'))
for job in queue['jobs']:
    if job['status']!='completed' or not job.get('outputs'):continue
    if len(sys.argv)>1 and job['id']!=sys.argv[1]:continue
    key=job['id'].replace('/','-');folder=OUT/'review'/key;folder.mkdir(exist_ok=True)
    video=OUT/job['outputs'][0];cap=cv2.VideoCapture(str(video));frames=[]
    while True:
        ok,bgr=cap.read()
        if not ok:break
        frames.append(cv2.cvtColor(bgr,cv2.COLOR_BGR2RGB))
    fps=cap.get(cv2.CAP_PROP_FPS);cap.release()
    if not frames:raise ValueError('Unreadable video '+str(video))
    # Include the terminal guide pose for loop review. Uniform sampling that
    # excludes the end can discard the actual return-to-contact pose.
    indices=[round(f*(len(frames)-1)/7) for f in range(8)]
    spec=dict(job=job['id'],frame_indices=indices,fps=fps,frames=len(frames),native_cell=[112,112],native_anchor=[56,100],poses=[])
    board=Image.new('RGB',(1536,816),'#263d48');draw=ImageDraw.Draw(board)
    for n,index in enumerate(indices):
        rgb=frames[index];bg=np.median(np.concatenate([rgb[:8].reshape(-1,3),rgb[-8:].reshape(-1,3)]),axis=0)
        alpha=np.where(np.sum((rgb.astype(np.float32)-bg)**2,axis=2)>95**2,255,0).astype(np.uint8)
        rgba=Image.fromarray(np.dstack([rgb,alpha]));scale=job['reference_scale'];box=job['source_box'];origin=job['reference_origin']
        x=origin[0]-box[0]*scale;y=origin[1]-box[1]*scale
        crop=rgba.crop((x,y,x+112*scale,y+112*scale))
        raw=folder/f'pose-{n}.rgba';raw.write_bytes(crop.tobytes())
        spec['poses'].append(dict(file=str(raw.relative_to(OUT)),width=crop.width,height=crop.height))
        board.paste(Image.fromarray(rgb),(n%4*384,n//4*408+24));draw.text((n%4*384+4,n//4*408+4),f'pose{n} / frame{index}',fill='white')
    board.save(folder/'poses-video.png');(folder/'extraction.json').write_text(json.dumps(spec,indent=2))
    print(job['id'],len(frames),'frames;8 motion poses prepared')
