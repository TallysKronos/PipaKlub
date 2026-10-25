// Build only the editable Soulgen delivery and its review artifacts; no game export.
import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {identity,validate,sample,render,exportPlan,matrices,point} from '../../../../tools/soulgen-studio/model.mjs';
import {anatomyReport} from '../../../../tools/soulgen-studio/workflow.mjs';
const directory=fileURLToPath(new URL('./color-rig-v2/',import.meta.url));
const write=(name,data)=>fs.writeFileSync(path.join(directory,name),JSON.stringify(data,null,2)+'\n');
const registration=JSON.parse(fs.readFileSync(path.join(directory,'registration.json')));
const project={schema:'soulgen-studio',version:1,name:'Nozinho · papel artesanal · três quartos',creatureId:'nozinho',artRevision:2,rigRevision:1,width:168,height:176,rootPivot:[87,82],
 brief:{species:'Nozinho',personality:'Gentil, prestativo e curioso; parceiro do Sr. Assis',kiteAnatomy:'Nó de linha de pipa, laços superiores, braços de corda e pernas com pontas desfiadas',view:'Três quartos para a direita; face distante menor, membros assimétricos',reference:'assets/creatures/nozinho/sprites.png',notes:'Referência de acabamento: Carcará aprovado. Rascunho conceitual tinha olhos claros maiores; a folha de peças corrige para olhos escuros. Sem asas, cauda extra ou bico. Revisão visual do autor pendente; atlas do jogo preservado.'},assets:{},parts:[],clips:{}};
for(const id of ['body','armNear','armFar','legNear','legFar','fierce','hurt','happy']){
 const filename=id==='fierce'||id==='hurt'||id==='happy'?'body-'+id+'.png':id+'.png';
 const bytes=fs.readFileSync(path.join(directory,filename));
 project.assets[id]={src:'/art/soulgen/keys/nozinho/color-rig-v2/'+filename,width:bytes.readUInt32BE(16),height:bytes.readUInt32BE(20),name:id};
}
const body={id:'body',name:'Nó central e rosto',asset:'body',source:[0,0,382,382],rect:[40,25,94,94],pivot:[87,82],z:2,parent:null,visible:true,faceWindows:registration.windows,
 faces:Object.fromEntries(['fierce','hurt','happy'].map(face=>[face,{asset:face,source:[0,0,382,382]}]))};
project.parts.push(body);
const specs=[
 ['armFar','Braço distante',[128,89],[.12,.16],[28,28],0,.025],
 ['legFar','Ponta de linha distante',[111,113],[.14,.10],[24,39],-2,.055],
 ['legNear','Ponta de linha próxima',[80,113],[.86,.11],[30,40],-1,.045],
 ['armNear','Braço próximo',[52,89],[.91,.386],[42,35],1,.02]
];
const joints=[];
for(const [id,name,pivot,anchor,size,z,lag]of specs){
 const a=project.assets[id],rect=[pivot[0]-anchor[0]*size[0],pivot[1]-anchor[1]*size[1],...size];
 project.parts.push({id,name,asset:id,source:[0,0,a.width,a.height],rect,pivot,z,parent:'body',visible:true,lag});
 joints.push({part:id,parent:'body',anchor,socket:[(pivot[0]-body.rect[0])/body.rect[2],(pivot[1]-body.rect[1])/body.rect[3]],maxGap:.05});
}
project.anatomy={version:1,ratios:specs.map(([id,,,,size])=>({part:id,relativeTo:'body',min:size[0]/94-.01,max:size[0]/94+.01,label:id+' / nó central'})),behind:[{part:'armNear',other:'body'},{part:'armFar',other:'body'},{part:'legFar',other:'body'},{part:'legNear',other:'body'}],joints};
const frame=(t,changes={},ease='smooth')=>({t,ease,values:Object.fromEntries(['root',...project.parts.map(p=>p.id)].map(id=>[id,{...identity(),...changes[id]}]))});
function cycle(id,label,seconds,fn){const frames=Array.from({length:13},(_,i)=>frame(i*seconds/12,fn(TAU*i/12),'spline'));frames.at(-1).values=structuredClone(frames[0].values);project.clips[id]={label,seconds,loop:true,frames,expressions:[]};}
const TAU=Math.PI*2;
cycle('idle','Repouso',2.4,t=>({root:{y:-1.4*Math.sin(t),rotation:1.2*Math.sin(t)},armNear:{rotation:2*Math.sin(t)},armFar:{rotation:-1.4*Math.sin(t)},legNear:{rotation:3*Math.sin(t)},legFar:{rotation:-2*Math.sin(t)}}));
cycle('flight','Flutuação',1.2,t=>({root:{y:-2.6*Math.sin(t),rotation:2*Math.sin(t)},armNear:{rotation:10*Math.sin(t)},armFar:{rotation:-7*Math.sin(t)},legNear:{rotation:7*Math.sin(t)},legFar:{rotation:-5*Math.sin(t)}}));
project.clips.skill={label:'Movimento de treino',seconds:1.6,loop:false,hitTime:.62,frames:[frame(0),frame(.25,{root:{x:-4,rotation:-6},armNear:{rotation:-16},armFar:{rotation:8}}),frame(.48,{root:{x:-6,y:1,rotation:-8},armNear:{rotation:-20},legNear:{rotation:5}}),frame(.62,{root:{x:8,y:-2,rotation:9},armNear:{rotation:22},armFar:{rotation:-8},legNear:{rotation:-5}}),frame(.85,{root:{x:3,rotation:3},armNear:{rotation:8}}),frame(1.1),frame(1.35),frame(1.6)],expressions:[{start:.2,end:1.02,face:'fierce'}]};
project.clips.hurt={label:'Susto / dano',seconds:1.1,loop:false,frames:[frame(0),frame(.10,{root:{x:-6,y:1,rotation:-10},armNear:{rotation:-12},armFar:{rotation:10},legNear:{rotation:7}}),frame(.30,{root:{x:-2,rotation:4},armNear:{rotation:5}}),frame(.60),frame(.85),frame(1.1)],expressions:[{start:.03,end:.62,face:'hurt'}]};
project.clips.victory={label:'Alegria',seconds:2.6,loop:false,frames:[frame(0),frame(.3,{root:{y:-6},armNear:{rotation:30},armFar:{rotation:-18},legNear:{rotation:-4},legFar:{rotation:6}}),frame(.75,{root:{y:-10,rotation:4},armNear:{rotation:44},armFar:{rotation:-28},legNear:{rotation:-7},legFar:{rotation:8}}),frame(1.2,{root:{y:-3,rotation:-4},armNear:{rotation:26},armFar:{rotation:-20}}),frame(1.8,{root:{y:-4},armNear:{rotation:15},armFar:{rotation:-10}}),frame(2.3),frame(2.6)],expressions:[{start:.25,end:2.15,face:'happy'}]};
const report=validate(project);if(!report.ok||report.warnings.length)throw Error(JSON.stringify(report));
const anatomy=anatomyReport(project);if(anatomy.warnings.length)throw Error(JSON.stringify(anatomy));
write('nozinho.soulgen.json',project);
const portable=structuredClone(project);
for(const asset of Object.values(portable.assets))asset.src='data:image/png;base64,'+fs.readFileSync(path.join(directory,path.basename(asset.src))).toString('base64');
write('nozinho.portable.soulgen.json',portable);
const require=createRequire(import.meta.url),{createCanvas,loadImage}=require(process.env.SOULGEN_CANVAS_MODULE||'@napi-rs/canvas');
const images={};for(const [id,a]of Object.entries(project.assets))images[id]=await loadImage(path.join(directory,path.basename(a.src)));
const preview=createCanvas(672,704);render(preview.getContext('2d'),project,images,sample(project,'idle',0),{scale:4});fs.writeFileSync(path.join(directory,'preview.png'),preview.toBuffer('image/png'));
const states=[['idle',0],['flight',.3],['skill',.62],['hurt',.15],['victory',.8]];
const review=createCanvas(1400,660),ctx=review.getContext('2d');
for(let row=0;row<2;row++)for(let i=0;i<states.length;i++){
 const [clip,time]=states[i],tile=createCanvas(280,300);render(tile.getContext('2d'),project,images,sample(project,clip,time),{scale:1.55});
 ctx.fillStyle=row?'#182c3b':'#f3ead6';ctx.fillRect(i*280,row*330,280,330);ctx.drawImage(tile,i*280,row*330);ctx.fillStyle=row?'#f3ead6':'#182c3b';ctx.font='16px sans-serif';ctx.fillText(project.clips[clip].label,i*280+12,row*330+320);
}fs.writeFileSync(path.join(directory,'review.png'),review.toBuffer('image/png'));
const plan=exportPlan(project,{fps:12,cell:256,columns:8}),sheet=createCanvas(plan.width,plan.height),g=sheet.getContext('2d'),tile=createCanvas(256,256);
for(const f of plan.frames){render(tile.getContext('2d'),project,images,sample(project,f.clip,f.time),{scale:plan.renderScale});g.drawImage(tile,f.x,f.y);}
fs.writeFileSync(path.join(directory,'study-atlas.png'),sheet.toBuffer('image/png'));write('export.json',plan);
let clippedPixels=0;
for(const f of plan.frames){const a=g.getImageData(f.x,f.y,256,256).data;for(let x=0;x<256;x++)for(const y of [0,255])clippedPixels+=a[(y*256+x)*4+3]>0;for(let y=0;y<256;y++)for(const x of [0,255])clippedPixels+=a[(y*256+x)*4+3]>0;}
if(clippedPixels)throw Error('Atlas clipping: '+clippedPixels);
write('validation.json',{structure:report,anatomy,alpha:registration.expressions,atlas:{frames:plan.frames.length,size:[plan.width,plan.height],fps:12,borderPixels:clippedPixels},note:'Structural checks and selected rendered poses do not equal author approval or gameplay integration.'});
const code=fs.readFileSync(fileURLToPath(new URL('../../../../tools/soulgen-studio/model.mjs',import.meta.url)),'utf8').replaceAll('export ','');
const payload=JSON.stringify(portable).replaceAll('<','\\u003c');
const html=`<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Nozinho · revisão Soulgen</title><style>body{background:#182c3b;color:#f6ebd5;font:16px system-ui;margin:24px}main{display:flex;gap:20px;align-items:end;flex-wrap:wrap}canvas{max-width:85vw;max-height:72vh;background:#2b4350;border-radius:12px}body.light canvas{background:#f3ead6}button,select,input{font:inherit;padding:8px;margin:6px}#small{width:128px;height:128px}p{max-width:900px;line-height:1.5}</style><h1>Nozinho · três quartos</h1><p>Rig de revisão: nó central e quatro membros, sem substituir o atlas do jogo. A pose inicial de conceito tinha olhos claros maiores; esta é a montagem final com olhos escuros.</p><select id="action"></select><button id="pause">Pausar</button><button id="restart">Reiniciar</button><button id="bg">Fundo claro/escuro</button><label>Velocidade <select id="speed"><option value=".25">¼×</option><option value=".5">½×</option><option value="1" selected>1×</option></select></label><input id="time" type="range" min="0" step=".001" value="0"><span id="info"></span><main><canvas id="view" width="672" height="704"></canvas><canvas id="small" width="128" height="128"></canvas></main><script type="module">${code}
const project=${payload},images={};await Promise.all(Object.entries(project.assets).map(async([id,a])=>{const im=new Image();im.src=a.src;await im.decode();images[id]=im;}));const action=document.querySelector('#action'),slider=document.querySelector('#time');for(const [id,c]of Object.entries(project.clips)){const o=document.createElement('option');o.value=id;o.textContent=c.label;action.append(o)}let elapsed=0,paused=false,last=0;action.onchange=()=>{elapsed=0;paused=false};slider.oninput=()=>{paused=true;elapsed=+slider.value};document.querySelector('#pause').onclick=()=>paused=!paused;document.querySelector('#restart').onclick=()=>{elapsed=0;paused=false};document.querySelector('#bg').onclick=()=>document.body.classList.toggle('light');document.addEventListener('visibilitychange',()=>last=0);function tick(ms){if(last&&!paused)elapsed+=Math.min(.05,(ms-last)/1000)*Number(document.querySelector('#speed').value);last=ms;const c=project.clips[action.value],pose=sample(project,action.value,elapsed);render(document.querySelector('#view').getContext('2d'),project,images,pose,{scale:3.5});render(document.querySelector('#small').getContext('2d'),project,images,pose,{scale:.68});slider.max=c.seconds;slider.value=pose.t;document.querySelector('#info').textContent=pose.t.toFixed(2)+' s · '+pose.face;requestAnimationFrame(tick)}requestAnimationFrame(tick);</script></html>`;
fs.writeFileSync(path.join(directory,'preview.html'),html);
console.log('Nozinho: 5 articulated parts, 5 actions, '+plan.frames.length+' atlas frames, no clipped border pixels.');
