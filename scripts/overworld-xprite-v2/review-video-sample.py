"""Review a fixed sample without writing to the active generation queue."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,subprocess,sys,numpy as np,cv2,html
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'art/creatures/overworld-video-v2';REVIEW=OUT/'quality-review-v1';REVIEW.mkdir(exist_ok=True)
ids=json.loads((ROOT/'tmp/overworld-anim/quality-sample.json').read_text())
snapshot=json.loads((OUT/'queue.json').read_text(encoding='utf-8'));jobs={j['id']:j for j in snapshot['jobs']}
results=[];cards=[]
def run(args):
    r=subprocess.run(args,cwd=ROOT,capture_output=True,text=True)
    if r.returncode:raise RuntimeError(r.stderr[-1800:])
for key in ids:
    folder=OUT/'review'/key.replace('/','-')
    if '--metrics-only' not in sys.argv:
        run([sys.executable,'scripts/overworld-xprite-v2/extract-video-pilot.py',key])
        run(['node','scripts/overworld-xprite-v2/restore-video-pilot.mjs',key])
        run([sys.executable,'-W','ignore','scripts/overworld-xprite-v2/preview-video-pilot.py',key])
    job=jobs[key];sheet=Image.open(folder/'spritesheet-experimental.png').convert('RGBA');a=np.array(sheet)
    cells=[a[:,i*112:(i+1)*112] for i in range(8)];masks=[c[:,:,3]>0 for c in cells];boxes=[Image.fromarray(c).getbbox() for c in cells]
    areas=[int(m.sum()) for m in masks];first,last=masks[0],masks[-1];union=np.logical_or(first,last).sum()
    iou=float(np.logical_and(first,last).sum()/union) if union else 0
    overlap=np.logical_and(first,last)
    color_change=float(np.logical_and(np.any(cells[0][:,:,:3]!=cells[-1][:,:,:3],axis=2),overlap).sum()/max(1,overlap.sum()))
    tiny=[]
    for mask in masks:
        n,labels,stats,centers=cv2.connectedComponentsWithStats(mask.astype(np.uint8),connectivity=8)
        tiny.append(int(sum(s[cv2.CC_STAT_AREA]<=2 for s in stats[1:])))
    # Measure source-video content lost by the fixed native-cell crop, separately
    # from normal occlusion/foreshortening or a flyer's silhouette changes.
    cap=cv2.VideoCapture(str(OUT/job['outputs'][0]));outside=[]
    s=job['reference_scale'];b=job['source_box'];o=job['reference_origin'];x=o[0]-b[0]*s;y=o[1]-b[1]*s
    timing=json.loads((folder/'extraction.json').read_text())
    for frame in timing['frame_indices']:
        cap.set(cv2.CAP_PROP_POS_FRAMES,frame);ok,bgr=cap.read()
        if not ok:continue
        rgb=cv2.cvtColor(bgr,cv2.COLOR_BGR2RGB).astype(np.float32);bg=np.median(np.concatenate([rgb[:8].reshape(-1,3),rgb[-8:].reshape(-1,3)]),axis=0)
        mask=(np.sum((rgb-bg)**2,axis=2)>95**2);inside=mask[max(0,y):min(384,y+112*s),max(0,x):min(384,x+112*s)].sum()
        outside.append(float((mask.sum()-inside)/max(1,mask.sum())))
    cap.release()
    r=dict(id=key,anatomy=job['anatomy'],areas=areas,bounds=boxes,area_range_percent=round(100*(max(areas)-min(areas))/max(areas),1),endpoint_mask_iou=round(iou,3),endpoint_color_difference=round(color_change,3),tiny_islands=tiny,max_native_crop_loss=round(max(outside,default=0),4),height_range=[min(bb[3]-bb[1] for bb in boxes),max(bb[3]-bb[1] for bb in boxes)],bottom_range=[min(bb[3] for bb in boxes),max(bb[3] for bb in boxes)])
    results.append(r)
    video='../'+job['outputs'][0];gif='../review/'+key.replace('/','-')+'/preview.gif'
    cards.append(f'<article><h3>{html.escape(key)}</h3><p>Área:{r["area_range_percent"]}% · sobreposição início/fim:{r["endpoint_mask_iou"]} · pixels recortados:{r["max_native_crop_loss"]:.1%}</p><video controls loop muted preload="none" src="{video}"></video><img loading="lazy" src="{gif}"><p><a href="../review/{key.replace("/","-")}/poses-video.png">Poses do vídeo</a> · <a href="../review/{key.replace("/","-")}/spritesheet-experimental.png">Folha112px</a></p></article>')
creatures=list(dict.fromkeys(key.split('/')[0] for key in ids));board=Image.new('RGB',(1120,len(creatures)*142),'#263d48');draw=ImageDraw.Draw(board)
for row,id in enumerate(creatures):
    draw.text((4,row*142+3),id,fill='white');source=Image.open(ROOT/'art/creatures/soulmonsters-overworld-v2'/id/'duas-vistas.png').convert('RGBA')
    for view,offset in [('sw',0),('nw',5)]:
        base=source.crop((0 if view=='sw' else 112,0,112 if view=='sw' else 224,112));board.paste(base,(offset*112,row*142+22),base)
        strip=Image.open(OUT/'review'/f'{id}-walk-{view}'/'spritesheet-experimental.png').convert('RGBA')
        for col,f in enumerate([0,2,4,7]):
            cell=strip.crop((f*112,0,(f+1)*112,112));board.paste(cell,((offset+col+1)*112,row*142+22),cell)
board.save(REVIEW/'comparacao.png')
(REVIEW/'metrics.json').write_text(json.dumps(dict(sample=len(ids),creatures=creatures,method='Fixed21clip sample;diagnostics are not automatic anatomy pass/fail thresholds',results=results),indent=2))
(REVIEW/'index.html').write_text('''<!doctype html><meta charset="utf-8"><title>Revisão de qualidade dos vídeos</title><style>body{font:16px system-ui;background:#112b34;color:#f6e9ce;margin:24px}a{color:#7edcd3}main{display:flex;flex-wrap:wrap;gap:16px}article{padding:16px;background:#263d48;max-width:680px}video{width:320px}img{width:224px;image-rendering:pixelated}</style><h1>Revisão por anatomia ·21clipes</h1><p>Original e extração comparáveis, sem alteração do jogo. Área e altura podem variar legitimamente por pose, asas e perspectiva; os números abaixo são sinais para inspeção, não reprovação automática.</p><p><a href="comparacao.png">Prancha comparativa</a> · <a href="RELATORIO.md">Conclusões</a></p><main>'''+''.join(cards)+'</main>',encoding='utf-8')
for r in results:print(json.dumps({k:v for k,v in r.items() if k not in ['areas','bounds','tiny_islands']},ensure_ascii=False))
