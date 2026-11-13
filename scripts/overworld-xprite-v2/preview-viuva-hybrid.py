from pathlib import Path
from PIL import Image,ImageDraw
import json,cv2,numpy as np,shutil
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'art/creatures/viuva-young-hibrido-v1'
source=Image.open(ROOT/'art/creatures/soulmonsters-overworld-v2/viuva-young/duas-vistas.png').convert('RGBA')
allowed=set(source.getdata());report={};manifest=dict(cell=[112,112],anchor=[56,100],views=['sw','nw'],runtime_replaced=False,method='source core retained; video-guided reconstructed leg poses',animations={})
if (OUT/'manifest.json').exists():
    previous=json.loads((OUT/'manifest.json').read_text())
    for key in ['runtime_replaced','approval_date','status']:
        if key in previous: manifest[key]=previous[key]
for action,count,durations in [('idle',4,[400,150,400,150]),('walk',6,[140,100,120,140,100,120])]:
    sheet=Image.open(OUT/f'{action}.png').convert('RGBA');assert sheet.size==(112*count,224)
    frames=[];stats=[];contact=Image.new('RGB',(count*224,448),'#263d48')
    for frame in range(count):
        pair=Image.new('RGBA',(224,112))
        for view in range(2):
            cell=sheet.crop((frame*112,view*112,(frame+1)*112,(view+1)*112));pair.paste(cell,(112*view,0))
            colors=set(cell.getdata());assert all(c in allowed for c in colors if c[3]),'new palette colour'
            mask=np.array(cell)[:,:,3]>0;n,lab,comp,cen=cv2.connectedComponentsWithStats(mask.astype(np.uint8),connectivity=8)
            stats.append(dict(frame=frame,view=view,bounds=cell.getbbox(),pixels=int(mask.sum()),components=n-1,tiny=sum(int(c[cv2.CC_STAT_AREA]<=2) for c in comp[1:])))
            big=cell.resize((224,224),Image.Resampling.NEAREST);contact.paste(big,(frame*224,view*224),big)
        bg=Image.new('RGBA',(224,112),'#263d48');bg.alpha_composite(pair);frames.append(bg.convert('RGB').resize((672,336),Image.Resampling.NEAREST))
    frames[0].save(OUT/f'{action}.gif',save_all=True,append_images=frames[1:],duration=durations,loop=0,disposal=2)
    contact.save(OUT/f'{action}-poses.png');report[action]=stats
    manifest['animations'][action]=dict(image=action+'.png',frames=count,durations_ms=durations,loop=True)
poses=json.loads((OUT/'poses.json').read_text())
assert all(sum(leg['support'] for leg in p['legs'])==(3 if p['action']=='walk' else 6) for p in poses)
(OUT/'validacao.json').write_text(json.dumps(report,indent=2));(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
shutil.copy2(ROOT/'art/creatures/overworld-video-v2/quality-review-v1/fundo-captura.png',OUT/'fundo-captura.png')
page='''<!doctype html><meta charset="utf-8"><title>Viúva jovem · piloto híbrido</title><style>body{background:#112b34;color:#f6e9ce;font:16px system-ui;margin:24px}a{color:#7edcd3}button,select{padding:10px}main{display:flex;flex-wrap:wrap;gap:16px}figure{margin:0;background:#263d48;padding:12px}canvas{image-rendering:pixelated;width:280px;height:260px}.native canvas{width:140px;height:130px}figcaption{text-align:center;padding:8px}</style><h1>Viúva jovem · piloto híbrido</h1><p>Arte preservada, com patas reconstruídas usando o vídeo como guia. Nenhum pixel gerado pelo vídeo foi incorporado ao híbrido.</p><select id="mode"><option value="walk/sw">Walk · frenteSW</option><option value="walk/nw">Walk · costasNW</option><option value="idle/sw">Idle · frenteSW</option></select><button id="pause">Pausar</button><button onclick="document.body.classList.toggle('native')">1×/2×</button><p>Ciclos sincronizados por fase para comparar. Fundo é uma captura real; este visualizador não é um playtest no Godot.</p><main>'''+''.join(f'<figure><canvas width="140" height="130" data-kind="{i}"></canvas><figcaption>{label}</figcaption></figure>' for i,label in enumerate(['Original aprovado','Recortes anteriores','Vídeo convertido','Híbrido reconstruído']))+'''</main><p><a href="walk.gif">GIF híbrido nas duas vistas</a> · <a href="walk-poses.png">Poses ampliadas</a> · <a href="revisao.md">Revisão e limites</a> · <a href="viuva-young-hibrido.aseprite">Editável Aseprite</a></p><script>
const cache=new Map();function img(p){if(!cache.has(p)){const i=new Image();i.src=p;cache.set(p,i)}return cache.get(p)}let t=0,last=performance.now(),play=true;document.querySelector('#pause').onclick=e=>{play=!play;e.target.textContent=play?'Pausar':'Continuar'};
function tick(now){if(play)t+=now-last;last=now;const [a,v]=document.querySelector('#mode').value.split('/');const phase=(t%1100)/1100;const row=v==='nw'?1:0;
document.querySelectorAll('canvas').forEach(c=>{const x=c.getContext('2d');x.imageSmoothingEnabled=false;const bg=img('fundo-captura.png');x.fillStyle='#263d48';x.fillRect(0,0,140,130);if(bg.complete&&bg.naturalWidth)x.drawImage(bg,0,0);let url,sx,sy;
if(c.dataset.kind==='0'){url='../soulmonsters-overworld-v2/viuva-young/duas-vistas.png';sx=row*112;sy=0}
else if(c.dataset.kind==='1'){url='../soulmonsters-overworld-v2/viuva-young/animacoes-v1/'+a+'.png';sx=Math.floor(phase*8)*112;sy=row*112}
else if(c.dataset.kind==='2'){url='../overworld-video-v2/review/viuva-young-'+a+'-'+v+'/spritesheet-experimental.png';sx=Math.floor(phase*8)*112;sy=0}
else{url=a+'.png';sx=Math.floor(phase*(a==='walk'?6:4))*112;sy=row*112}
const im=img(url);if(im.complete&&im.naturalWidth)x.drawImage(im,sx,sy,112,112,14,12,112,112)
});requestAnimationFrame(tick)}requestAnimationFrame(tick);
</script>'''
(OUT/'index.html').write_text(page,encoding='utf-8')
print(json.dumps({a:dict(frames=len(v),tiny=max(p['tiny'] for p in v),components=max(p['components'] for p in v),bounds=[min(p['bounds'][1] for p in v),max(p['bounds'][3] for p in v)]) for a,v in report.items()}))
