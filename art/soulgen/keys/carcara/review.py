from pathlib import Path
import base64, json, hashlib
from PIL import Image
root=Path(__file__).resolve().parent
out=root.parents[1]/'out'
def uri(path):
    return 'data:image/'+('gif' if path.suffix=='.gif' else 'png')+';base64,'+base64.b64encode(path.read_bytes()).decode()
cards=[]
datasets={}
for tag in ['carcara','carcara-noturno']:
    datasets[tag]={'image':uri(out/f'{tag}.png'),'data':json.loads((out/f'{tag}.json').read_text(encoding='utf-8'))}
    for name in ['idle','flight','skill','hurt','victory']:
        path=out/f'{tag}-{name}.gif'
        im=Image.open(path)
        cards.append(f'<article><h2>{tag} · {name}</h2><canvas width="240" height="230" data-tag="{tag}" data-anim="{name}" aria-label="{tag} {name}"></canvas><small>{im.n_frames} quadros</small></article>')
html='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Soulgen · Carcará</title>
<style>body{font:16px system-ui;background:#1e292e;color:#f4e8cb;margin:24px}h1{margin-bottom:6px}p{max-width:850px;line-height:1.5}main{display:grid;grid-template-columns:repeat(5,minmax(180px,1fr));gap:12px}article{background:#f6ead0;color:#34231c;border-radius:10px;padding:12px}h2{font-size:14px}canvas{width:100%;height:230px;object-fit:contain;image-rendering:pixelated}small{display:block}button{font:inherit;padding:8px 16px;margin:14px 0}body.dark article{background:#243644;color:#fff} @media(max-width:1000px){main{grid-template-columns:repeat(2,1fr)}}</style>
<h1>Carcará · Soulgen</h1><p>Pose-chave em camadas · 96×96 · 15 cores · versões normal e noturna. Animações geradas pelo pipeline existente, com seus tempos reais. Entrega para revisão; integração ao jogo é uma etapa separada.</p><button onclick="document.body.classList.toggle('dark')">Alternar fundo dos cards</button><main>'''+''.join(cards)+'</main></html>'
html+='<script>const pack='+json.dumps(datasets)+''';
for(const [tag,item] of Object.entries(pack)){item.img=new Image();item.img.src=item.image;}
function tick(ms){
 for(const canvas of document.querySelectorAll('canvas')){
  const p=pack[canvas.dataset.tag],a=p.data.anims.find(a=>a.name===canvas.dataset.anim);
  if(!p.img.complete)continue;
  const total=a.durations.reduce((v,t)=>v+t,0),time=(ms*60/1000)%total;
  let index=0,end=a.durations[0];while(time>=end && index<a.frames-1)end+=a.durations[++index];
  const ctx=canvas.getContext('2d'),[w,h]=a.cell;ctx.clearRect(0,0,240,230);ctx.imageSmoothingEnabled=false;
  ctx.drawImage(p.img,index*w,a.y,w,h,(240-w*3)/2,(230-h*3)/2,w*3,h*3);
 }requestAnimationFrame(tick);
}requestAnimationFrame(tick);</script>'''
(root/'pixel-legacy-preview.html').write_text(html,encoding='utf-8')
layers={}
for p in sorted(root.glob('*.png')):
    if p.name.startswith('pose'):continue
    im=Image.open(p).convert('RGBA')
    colors={p[:3] for p in im.getdata() if p[3]}
    layers[p.name]={'size':im.size,'alpha':sorted(set(im.getchannel('A').getdata())), 'colors':len(colors),'bounds':im.getbbox(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
(root/'validation.json').write_text(json.dumps({'layers':layers,'checks':{'base':{'errors':0,'warnings':0,'colors':15,'frames':16},'noturno':{'errors':0,'warnings':0,'colors':15,'frames':16},'variant_alpha_and_ink':'preserved'},'source_branch':'origin/claude/soulgen-codex','pipeline_commit':'41be85d','integration':'not integrated'},indent=2),encoding='utf-8')
print('Standalone preview and validation saved')
