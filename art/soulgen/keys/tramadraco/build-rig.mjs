import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {identity} from '../../../../tools/soulgen-studio/model.mjs';
import {exportReview} from '../../../../tools/soulgen-studio/export-review.mjs';
const dir=fileURLToPath(new URL('./cutout-rig-v1/',import.meta.url));
if(fs.existsSync(dir+'author-import.json'))throw Error('Preserve author edits');
const slices=JSON.parse(fs.readFileSync(dir+'slices.json')),registration=JSON.parse(fs.readFileSync(dir+'registration.json'));
const p={schema:'soulgen-studio',version:1,name:'Tramadraco · cavaleiro adulto',creatureId:'tramadraco',artRevision:1,rigRevision:1,preserveSourceAspect:true,width:1000,height:1000,rootPivot:[500,530],assets:{},parts:[],clips:{},brief:{view:'Três quartos à direita',notes:'Anatomia contínua sob placas sólidas, sem buracos de encaixe. Capa, espada e rabiola completas e separadas. Viseira fechada em todas as expressões. Conversão para revisão, sem integração.'}};
// scale, source anchor x/y, stage pivot x/y, z, parent, readable name
const layout={
 body:[.90,114,150,500,430,3,null,'Torso e bacia'],
 head:[.55,125,250,515,331,7,'body','Elmo e pescoço'],
 upperNear:[.65,175,92,408,350,5,'body','Braço próximo e ombreira'],
 upperFar:[.65,70,80,591,350,1,'body','Braço distante e ombreira'],
 foreNear:[.60,95,20,424,472,6,'upperNear','Antebraço próximo e mão'],
 foreFar:[.60,90,24,605,454,2,'upperFar','Antebraço distante e mão'],
 thighNear:[.57,80,30,452,535,4,'body','Coxa próxima'],
 thighFar:[.56,90,30,565,535,1,'body','Coxa distante'],
 shinNear:[.64,90,30,463,634,5,'thighNear','Canela próxima e bota'],
 shinFar:[.62,70,30,560,630,2,'thighFar','Canela distante e bota'],
 cape:[1.55,245,10,445,330,0,'body','Capa rasgada inteira'],
 sword:[1,43,42,440,610,5.5,'foreNear','Espada inteira'],
 tail:[.55,260,17,487,643,5.6,'sword','Rabiola · fio, nó e duas abas']
};
for(const [id,[s,ax,ay,x,y,z,parent,name]]of Object.entries(layout)){
 const b=slices.boxes[id],w=b[2]-b[0],h=b[3]-b[1];p.assets[id]={name,src:`/art/soulgen/keys/tramadraco/cutout-rig-v1/${id}.png`,width:w,height:h};
 p.parts.push({id,name,asset:id,source:[0,0,w,h],rect:[x-ax*s,y-ay*s,w*s,h*s],pivot:[x,y],z,parent,visible:true,lag:0});
}
const head=p.parts.find(x=>x.id==='head');head.faces={};head.faceWindows=registration.windows;
for(const face of ['fierce','hurt','happy']){const a=p.assets.head;p.assets[face]={...a,name:face,src:`/art/soulgen/keys/tramadraco/cutout-rig-v1/head-${face}.png`};head.faces[face]={asset:face,source:[0,0,a.width,a.height]};}
p.anatomy={version:1,ratios:[],behind:[{part:'cape',other:'body'},{part:'upperFar',other:'body'},{part:'thighFar',other:'body'},{part:'sword',other:'foreNear'}],joints:p.parts.filter(x=>x.parent).map(x=>{const parent=p.parts.find(y=>y.id===x.parent);return {part:x.id,parent:x.parent,anchor:[(x.pivot[0]-x.rect[0])/x.rect[2],(x.pivot[1]-x.rect[1])/x.rect[3]],socket:[(x.pivot[0]-parent.rect[0])/parent.rect[2],(x.pivot[1]-parent.rect[1])/parent.rect[3]],maxGap:2};})};
const frame=(t,changes={})=>({t,ease:'smooth',values:Object.fromEntries(['root',...p.parts.map(x=>x.id)].map(id=>[id,{...identity(),...changes[id]}]))});
function cycle(id,label,seconds,fn){const frames=Array.from({length:17},(_,i)=>frame(seconds*i/16,fn(Math.PI*2*i/16)));frames.at(-1).values=structuredClone(frames[0].values);p.clips[id]={label,seconds,loop:true,frames,expressions:[]};}
cycle('idle','Guarda vigilante',2.8,t=>({head:{rotation:.45*Math.sin(t)},cape:{rotation:.7*Math.sin(t)},foreNear:{rotation:.45*Math.sin(t)},tail:{rotation:2*Math.sin(t)}}));
cycle('flight','Marcha do cavaleiro',1.3,t=>({root:{y:1.2*Math.sin(2*t)},thighNear:{rotation:4*Math.sin(t)},thighFar:{rotation:-4*Math.sin(t)},shinNear:{rotation:-2*Math.sin(t)},shinFar:{rotation:2*Math.sin(t)},upperNear:{rotation:-1.5*Math.sin(t)},upperFar:{rotation:2*Math.sin(t)},cape:{rotation:1.3*Math.sin(t)},tail:{rotation:3*Math.sin(t)}}));
function action(id,label,seconds,hit,keys,face){p.clips[id]={label,seconds,loop:false,...(hit?{hitTime:hit}:{}),frames:keys.map(([t,v])=>frame(t,v)),expressions:[{start:.04,end:seconds-.04,face}]};}
action('skill','Corte da pandorga',1.65,.62,[[0,{}],[.27,{root:{x:-4},upperNear:{rotation:7},foreNear:{rotation:12},cape:{rotation:1}}],[.62,{root:{x:12},upperNear:{rotation:-12},foreNear:{rotation:-24},sword:{rotation:-7},tail:{rotation:8},head:{rotation:-2}}],[1.05,{root:{x:4},foreNear:{rotation:-8}}],[1.65,{}]],'fierce');
action('hurt','Impacto na guarda',.85,null,[[0,{}],[.14,{root:{x:-7,rotation:-.8},head:{rotation:3},upperNear:{rotation:4},foreNear:{rotation:6},cape:{rotation:-1.5}}],[.5,{root:{x:-2}}],[.85,{}]],'hurt');
action('victory','Voto renovado',2.2,null,[[0,{}],[.5,{head:{rotation:-2},upperNear:{rotation:-3},foreNear:{rotation:-8},tail:{rotation:4}}],[1.3,{head:{rotation:-1},cape:{rotation:-1},foreNear:{rotation:-5}}],[2.2,{}]],'happy');
action('defeat','Guarda abatida',1.4,null,[[0,{}],[.5,{root:{y:5},head:{rotation:5},upperFar:{rotation:3}}],[1.4,{root:{y:9},head:{rotation:7},upperNear:{rotation:3},foreNear:{rotation:4},cape:{rotation:1}}]],'hurt');
await exportReview(p,dir,{registration});
