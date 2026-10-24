import {BASIC_CREATURES,createBasic} from './basics.mjs';
import {createCarcara} from './carcara.mjs';
import {sample,render} from './model.mjs';
const $=id=>document.getElementById(id);let playing=true,elapsed=0,last=0,action='idle';const rigs=[];
const image=src=>new Promise((resolve,reject)=>{const im=new Image();im.onload=()=>resolve(im);im.onerror=()=>reject(Error(src));im.src=src;});
try{
 for(const [id,name]of Object.entries({carcara:'Carcará · referência',...BASIC_CREATURES})){
  const project=id==='carcara'?await createCarcara(async src=>{const im=await image(src);return {width:im.naturalWidth,height:im.naturalHeight};}):await createBasic(id),images={};await Promise.all(Object.entries(project.assets).map(async([key,a])=>images[key]=await image(a.src)));
  const card=document.createElement('article'),title=document.createElement('h2'),canvas=document.createElement('canvas'),note=document.createElement('p'),link=document.createElement('a');
  title.textContent=name;canvas.width=canvas.height=640;canvas.setAttribute('aria-label',name+' animado');link.href=id==='carcara'?'/':'/?preset='+id;link.textContent=id==='carcara'?'Referência aprovada':'Editar peças e pivôs →';note.append(link);card.append(title,canvas,note);$('grid').append(card);
  const left=Math.min(...project.parts.map(p=>p.rect[0])),top=Math.min(...project.parts.map(p=>p.rect[1])),right=Math.max(...project.parts.map(p=>p.rect[0]+p.rect[2])),bottom=Math.max(...project.parts.map(p=>p.rect[1]+p.rect[3]));
  const scale=Math.min(640/(right-left),640/(bottom-top))*.76,framing={scale,offsetX:(project.width/2-(left+right)/2)*scale,offsetY:(project.height/2-(top+bottom)/2)*scale};
  rigs.push({project,images,ctx:canvas.getContext('2d'),framing});
 }
 $('status').textContent='Carcará de referência + quatro novos rigs · cinco ações · fontes preservadas';
 $('action').onchange=()=>{action=$('action').value;elapsed=0;last=0;};$('pause').onclick=()=>{playing=!playing;$('pause').textContent=playing?'Pausar':'Reproduzir';last=0;};$('restart').onclick=()=>{elapsed=0;last=0;};
 $('background').onclick=()=>{document.body.classList.toggle('dark');$('background').textContent=document.body.classList.contains('dark')?'Fundo claro':'Fundo escuro';};
 $('time').oninput=()=>{playing=false;$('pause').textContent='Reproduzir';elapsed=Number($('time').value);};
 function draw(now){if(playing&&last)elapsed+=(now-last)/1000/rigs[0].project.clips[action].seconds;last=now;const first=rigs[0].project.clips[action];let phase=first.loop?elapsed%1:Math.min(elapsed,1);$('time').value=phase;
  for(const {project,images,ctx,framing}of rigs){const c=project.clips[action];render(ctx,project,images,sample(project,action,phase*c.seconds),framing);}requestAnimationFrame(draw);
 }document.addEventListener('visibilitychange',()=>last=0);requestAnimationFrame(draw);
}catch(e){$('status').textContent='Falha: '+e.message;throw e;}
