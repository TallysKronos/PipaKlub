// Local authoring artifacts only. Never writes game atlases or production assets.
import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {validate,sample,render,exportPlan} from './model.mjs';
import {anatomyReport} from './workflow.mjs';
export async function exportReview(project,directory,{registration}={}){
 const write=(file,data)=>fs.writeFileSync(path.join(directory,file),JSON.stringify(data,null,2)+'\n');
 const check=validate(project),anatomy=anatomyReport(project);
 if(!check.ok||check.warnings.length||anatomy.warnings.length)throw Error(JSON.stringify({check,anatomy}));
 write(project.creatureId+'.soulgen.json',project);
 const portable=structuredClone(project);
 for(const a of Object.values(portable.assets))a.src='data:image/png;base64,'+fs.readFileSync(path.join(directory,path.basename(a.src))).toString('base64');
 write(project.creatureId+'.portable.soulgen.json',portable);
 const require=createRequire(import.meta.url),{createCanvas,loadImage}=require(process.env.SOULGEN_CANVAS_MODULE||'@napi-rs/canvas');
 const images={};for(const [id,a]of Object.entries(project.assets))images[id]=await loadImage(path.join(directory,path.basename(a.src)));
 const preview=createCanvas(project.width*3,project.height*3);render(preview.getContext('2d'),project,images,sample(project,'idle',0),{scale:3});
 fs.writeFileSync(path.join(directory,'preview.png'),preview.toBuffer('image/png'));
 const selected=[['idle',0],['flight',project.clips.flight.seconds*.25],['skill',project.clips.skill.hitTime||.5],['hurt',.15],['victory',.8]],review=createCanvas(1400,660),g=review.getContext('2d');
 for(let row=0;row<2;row++)for(let i=0;i<selected.length;i++){
  const [id,time]=selected[i],tile=createCanvas(280,300);render(tile.getContext('2d'),project,images,sample(project,id,time),{scale:Math.min(252/project.width,270/project.height)});
  g.fillStyle=row?'#182c3b':'#f3ead6';g.fillRect(i*280,row*330,280,330);g.drawImage(tile,i*280,row*330);g.fillStyle=row?'#f3ead6':'#182c3b';g.font='16px sans-serif';g.fillText(project.clips[id].label||id,i*280+12,row*330+320);
 }fs.writeFileSync(path.join(directory,'review.png'),review.toBuffer('image/png'));
 const plan=exportPlan(project,{fps:12,cell:256,columns:8}),atlas=createCanvas(plan.width,plan.height),ctx=atlas.getContext('2d'),tile=createCanvas(256,256);
 const all=createCanvas(1280,Math.ceil(plan.frames.length/10)*148),ag=all.getContext('2d');ag.fillStyle='#203847';ag.fillRect(0,0,all.width,all.height);
 let clippedPixels=0;
 for(const [i,f]of plan.frames.entries()){
  render(tile.getContext('2d'),project,images,sample(project,f.clip,f.time),{scale:plan.renderScale});ctx.drawImage(tile,f.x,f.y);
  ag.drawImage(tile,i%10*128,Math.floor(i/10)*148,128,128);ag.fillStyle='#f3ead6';ag.font='10px sans-serif';ag.fillText(f.name,i%10*128+4,Math.floor(i/10)*148+141);
  const a=tile.getContext('2d').getImageData(0,0,256,256).data;for(let x=0;x<256;x++)for(const y of [0,255])clippedPixels+=a[(y*256+x)*4+3]>0;for(let y=0;y<256;y++)for(const x of [0,255])clippedPixels+=a[(y*256+x)*4+3]>0;
 }
 if(clippedPixels)throw Error('Atlas touches cell borders: '+clippedPixels);
 fs.writeFileSync(path.join(directory,'study-atlas.png'),atlas.toBuffer('image/png'));write('export.json',plan);fs.writeFileSync(path.join(directory,'review-full.png'),all.toBuffer('image/png'));
 write('validation.json',{structure:check,anatomy,expressions:registration?.expressions,atlas:{frames:plan.frames.length,size:[plan.width,plan.height],fps:12,borderPixels:clippedPixels},note:'Technical validation and rendered pose review; not author approval or game integration.'});
 const code=fs.readFileSync(fileURLToPath(new URL('./model.mjs',import.meta.url)),'utf8').replaceAll('export ','');
 const payload=JSON.stringify(portable).replaceAll('<','\\u003c');
 const title=project.name.replace(/[<>&]/g,'');
 fs.writeFileSync(path.join(directory,'preview.html'),`<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${title}</title><style>body{font:16px system-ui;background:#182c3b;color:#f3ead6;margin:24px}button,select,input{font:inherit;padding:8px;margin:5px}main{display:flex;align-items:end;gap:20px;flex-wrap:wrap}canvas{background:#293f4d;max-width:90vw;max-height:72vh;border-radius:12px}body.light canvas{background:#f3ead6}#small{width:128px;height:128px}</style><h1>${title}</h1><p>Rig para revisão. A arte do jogo não é alterada por esta prévia.</p><select id="action"></select><button id="pause">Pausar</button><button id="restart">Reiniciar</button><button id="bg">Fundo claro/escuro</button><select id="speed" aria-label="Velocidade"><option value=".25">¼×</option><option value=".5">½×</option><option value="1" selected>1×</option></select><input type="range" id="time" min="0" step=".001" value="0"><span id="info"></span><main><canvas id="view" width="800" height="800"></canvas><canvas id="small" width="128" height="128"></canvas></main><script type="module">${code}
const project=${payload},images={};await Promise.all(Object.entries(project.assets).map(async([id,a])=>{const im=new Image();im.src=a.src;await im.decode();images[id]=im;}));const action=document.querySelector('#action'),slider=document.querySelector('#time');for(const [id,c]of Object.entries(project.clips)){const o=document.createElement('option');o.value=id;o.textContent=c.label;action.append(o)}let elapsed=0,paused=false,last=0;action.onchange=()=>{elapsed=0;paused=false};slider.oninput=()=>{paused=true;elapsed=+slider.value};document.querySelector('#pause').onclick=()=>paused=!paused;document.querySelector('#restart').onclick=()=>{elapsed=0;paused=false};document.querySelector('#bg').onclick=()=>document.body.classList.toggle('light');document.addEventListener('visibilitychange',()=>last=0);function tick(ms){if(last&&!paused)elapsed+=Math.min(.05,(ms-last)/1000)*Number(document.querySelector('#speed').value);last=ms;const c=project.clips[action.value],pose=sample(project,action.value,elapsed);render(document.querySelector('#view').getContext('2d'),project,images,pose,{scale:720/Math.max(project.width,project.height)});render(document.querySelector('#small').getContext('2d'),project,images,pose,{scale:116/Math.max(project.width,project.height)});slider.max=c.seconds;slider.value=pose.t;document.querySelector('#info').textContent=pose.t.toFixed(2)+' s · '+pose.face;requestAnimationFrame(tick)}requestAnimationFrame(tick);</script></html>`);
 console.log(project.creatureId+': '+project.parts.length+' parts, '+plan.frames.length+' frames, no clipped border pixels.');
 return plan;
}
