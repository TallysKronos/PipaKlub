import {readFile,writeFile} from 'node:fs/promises';
const here=new URL('./',import.meta.url);
const png=await readFile(new URL('../source/layers-generated.png',here));
const rig=await readFile(new URL('./rig.mjs',here),'utf8');
const faces={};
for(const name of ['fierce','hurt','happy'])faces[name]='data:image/png;base64,'+(await readFile(new URL('./body-'+name+'.png',here))).toString('base64');
const html=`<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Carcará · animação da arte original</title>
<style>*{box-sizing:border-box}body{margin:0;background:#18232b;color:#f6ead7;font:16px system-ui}header,main{max-width:1400px;margin:auto;padding:24px}h1{margin:0 0 8px;font-size:30px}p{margin:0;line-height:1.5;max-width:850px;color:#c5cdd0}.controls{display:flex;gap:10px;align-items:center;flex-wrap:wrap;margin-top:22px}button,select,input{font:inherit}button,select{background:#f6ead7;color:#18232b;border:0;border-radius:6px;padding:10px 14px;cursor:pointer}label{display:flex;gap:8px;align-items:center}.gallery{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:18px;padding-top:0}.card{background:#243845;border:1px solid #3c5059;border-radius:12px;overflow:hidden}.card h2{margin:16px 20px 0;font-size:19px}.card p{font-size:13px;margin:3px 20px}.stage{width:100%;aspect-ratio:1;display:block;background:radial-gradient(ellipse at center,#405b66,#243845)}body.light .stage{background:#f6ead7}.card footer{padding:12px 20px;color:#c5cdd0;font-size:13px;border-top:1px solid #3c5059}.hero{grid-column:span 2;grid-row:span 2}.hero .stage{max-height:650px;aspect-ratio:1.1;object-fit:contain}.hero h2{font-size:23px}input{max-width:180px} @media(max-width:850px){.gallery{grid-template-columns:1fr 1fr}.hero{grid-column:span 2;grid-row:auto}}@media(max-width:520px){header,main{padding:16px}.gallery{grid-template-columns:1fr}.hero{grid-column:auto}h1{font-size:24px}}</style>
<header><h1>Carcará · arte original em movimento</h1><p>Cores e detalhes da arte gerada preservados. Asas e rabiola articuladas, com movimento contínuo.</p>
<div class="controls"><label>Animação <select id="clip"><option value="idle">Repouso</option><option value="flight">Voo</option><option value="skill">Golpe</option><option value="hurt">Dano</option><option value="victory">Vitória</option></select></label><button id="pause">Pausar</button><button id="replay">Repetir ação</button><button id="background">Fundo claro</button><label>Velocidade <select id="speed"><option value="1">1×</option><option value="0.5">0,5×</option><option value="0.25">0,25×</option></select></label><label>Quadro <input id="scrub" type="range" min="0" max="1000" value="0" aria-label="Inspecionar instante da animação"></label></div></header>
<main class="gallery"><article class="card hero"><h2 id="hero-title">Repouso</h2><p id="hero-info">Arte colorida · sem troca de paleta</p><canvas id="hero" class="stage" width="640" height="640" aria-label="Carcará animado, arte original"></canvas><footer id="time">Carregando arte…</footer></article>
${['idle','flight','skill','hurt','victory'].map((name,i)=>`<article class="card"><h2>${['Repouso','Voo','Golpe','Dano','Vitória'][i]}</h2><canvas class="stage" data-clip="${name}" width="400" height="400" aria-label="Carcará ${name}"></canvas><footer>${i<2?'Ciclo contínuo':'Ação e recuperação; repete com intervalo para revisão'}</footer></article>`).join('')}</main>
<script type="module">${rig.replaceAll('export ','')}
const image=new Image();image.src='data:image/png;base64,${png.toString('base64')}';await image.decode();
const faceSources=${JSON.stringify(faces)},faceImages={};
await Promise.all(Object.entries(faceSources).map(async([name,src])=>{const img=new Image();img.src=src;await img.decode();faceImages[name]=img;}));
const clip=document.querySelector('#clip'), hero=document.querySelector('#hero'), pause=document.querySelector('#pause'),speed=document.querySelector('#speed'),scrub=document.querySelector('#scrub');
let selected='idle',elapsed=0,paused=false,last=null,galleryTime=0;
function info(){document.querySelector('#hero-title').textContent=clips[selected].label;document.querySelector('#hero-info').textContent=clips[selected].loop?'Ciclo contínuo · arte original':'Ação única · preparação, ação e recuperação';}
clip.onchange=()=>{selected=clip.value;elapsed=0;last=null;info();};
pause.onclick=()=>{paused=!paused;pause.textContent=paused?'Reproduzir':'Pausar';last=null;};
document.querySelector('#replay').onclick=()=>{elapsed=0;paused=false;pause.textContent='Pausar';last=null;};
document.querySelector('#background').onclick=e=>{document.body.classList.toggle('light');e.target.textContent=document.body.classList.contains('light')?'Fundo escuro':'Fundo claro';};
scrub.oninput=()=>{paused=true;pause.textContent='Reproduzir';elapsed=Number(scrub.value)/1000*clips[selected].seconds;};
function tick(ms){
 const dt=last===null?0:Math.min((ms-last)/1000,.05);last=ms;
 if(!paused){elapsed+=dt*Number(speed.value);galleryTime+=dt*Number(speed.value);}
 render(hero.getContext('2d'),image,selected,elapsed,{scale:5,faces:faceImages});
 const c=clips[selected],t=c.loop?elapsed%c.seconds:Math.min(elapsed,c.seconds);
 scrub.value=Math.round(t/c.seconds*1000);document.querySelector('#time').textContent=t.toFixed(2)+' s / '+c.seconds.toFixed(2)+' s · expressão: '+({normal:'neutra',fierce:'golpe',hurt:'dano',happy:'vitória'}[expression(selected,elapsed)])+(!c.loop&&elapsed>=c.seconds?' · ação concluída':'');
 for(const canvas of document.querySelectorAll('[data-clip]')){const n=canvas.dataset.clip,a=clips[n];const t=a.loop?galleryTime:galleryTime%(a.seconds+1);render(canvas.getContext('2d'),image,n,t,{scale:3.4,faces:faceImages});}
 requestAnimationFrame(tick);
}document.addEventListener('visibilitychange',()=>{last=null;});requestAnimationFrame(tick);
</script></html>`;
await writeFile(new URL('./preview.html',here),html);
await writeFile(new URL('../preview.html',here),html);
console.log('Full-colour source rig preview generated; original RGBA image embedded unchanged.');
