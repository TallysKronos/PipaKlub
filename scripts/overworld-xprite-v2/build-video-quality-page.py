from pathlib import Path
from PIL import Image
import json
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'art/creatures/overworld-video-v2/quality-review-v1'
m=json.loads((OUT/'metrics.json').read_text());ids=m['creatures']
# Existing real-map capture: crop only an empty patch, no synthetic game proof.
photo=Image.open(ROOT/'tmp/overworld-animation-playtest/farpim-000.png').convert('RGB')
photo.crop((280,130,420,260)).save(OUT/'fundo-captura.png')
cards=''.join(f'<article data-id="{id}"><h2>{id}</h2><div class="row">'+''.join(f'<figure><canvas width="140" height="130" data-column="{col}"></canvas><figcaption>{label}</figcaption></figure>' for col,label in enumerate(['Arte aprovada','Recortes atuais','Poses do vídeo']))+'</div></article>' for id in ids)
page='''<!doctype html><meta charset="utf-8"><title>Comparar qualidade de movimento</title><style>body{font:16px system-ui;background:#112b34;color:#f6e9ce;margin:24px}header{position:sticky;top:0;background:#112b34;padding:12px;z-index:1}a{color:#7edcd3}select,button{padding:10px}main{display:flex;flex-wrap:wrap;gap:18px}article{padding:12px;background:#263d48}figure{margin:0}figcaption{text-align:center;font-size:14px}.row{display:flex;gap:12px}canvas{image-rendering:pixelated;width:280px;height:260px}body.native canvas{width:140px;height:130px}</style><header><h1>Arte × recortes × vídeo</h1><p>21clipes/7anatomias. Mesma célula e apoio; fundo recortado de uma captura real. Esta comparação não é uma execução do jogo.</p><select id="mode"><option value="walk/sw">Deslocamento · frenteSW</option><option value="walk/nw">Deslocamento · costasNW</option><option value="idle/sw">Idle · frenteSW</option></select><button onclick="document.body.classList.toggle('native')">Alternar1×/2×</button><button id="play">Pausar</button><p><a href="RELATORIO.md">Conclusões por criatura</a> · <a href="index.html">Vídeos e métricas</a></p></header><main>'''+cards+'''</main><script>
const cache=new Map();function img(url){if(!cache.has(url)){const i=new Image();i.src=url;cache.set(url,i)}return cache.get(url)}
let running=true;document.querySelector('#play').onclick=e=>{running=!running;e.target.textContent=running?'Pausar':'Continuar'};
let time=0,last=performance.now();const mode=document.querySelector('#mode');
function draw(now){if(running)time+=now-last;last=now;const [action,view]=mode.value.split('/');const f=Math.floor(time/(2333/8))%8;const row=view==='nw'?1:0;
document.querySelectorAll('article').forEach(card=>{const id=card.dataset.id;card.querySelectorAll('canvas').forEach(canvas=>{const c=canvas.getContext('2d');c.imageSmoothingEnabled=false;const bg=img('fundo-captura.png');if(bg.complete&&bg.naturalWidth)c.drawImage(bg,0,0);else{c.fillStyle='#263d48';c.fillRect(0,0,140,130)}let url,sx,sy;
if(canvas.dataset.column==='0'){url='../../soulmonsters-overworld-v2/'+id+'/duas-vistas.png';sx=row*112;sy=0}
else if(canvas.dataset.column==='1'){url='../../soulmonsters-overworld-v2/'+id+'/animacoes-v1/'+action+'.png';sx=f*112;sy=row*112}
else{url='../review/'+id+'-'+action+'-'+view+'/spritesheet-experimental.png';sx=f*112;sy=0}
const a=img(url);if(a.complete&&a.naturalWidth)c.drawImage(a,sx,sy,112,112,14,12,112,112);
});});requestAnimationFrame(draw)}requestAnimationFrame(draw);
</script>'''
(OUT/'comparar.html').write_text(page,encoding='utf-8')
print('Comparative viewer:7 models,3 modes,native/2x; runtime untouched')
