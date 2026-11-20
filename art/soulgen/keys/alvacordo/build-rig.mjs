import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {identity} from '../../../../tools/soulgen-studio/model.mjs';
import {exportReview} from '../../../../tools/soulgen-studio/export-review.mjs';
const dir=fileURLToPath(new URL('./cutout-rig-v1/',import.meta.url));
if(fs.existsSync(dir+'author-import.json'))throw Error('Preserve author edits');
const slices=JSON.parse(fs.readFileSync(dir+'slices.json')),registration=JSON.parse(fs.readFileSync(dir+'registration.json'));
const p={schema:'soulgen-studio',version:1,name:'Alvacordo · arcos de papel',creatureId:'alvacordo',artRevision:1,rigRevision:1,preserveSourceAspect:true,width:1000,height:1000,rootPivot:[516,510],assets:{},parts:[],clips:{},brief:{view:'Três quartos à esquerda',notes:'Adulto v4 aprovado convertido para revisão. Anatomia sólida sem encaixes aparentes; arcos completos filhos dos antebraços; rabiola inteira. Sem integração.'}};
// Scale, source anchor, assembly pivot, depth, parent, readable name.
const layout={
 body:[.90,107,150,516,435,3,null,'Torso e bacia'],
 head:[.65,133,250,530,320,8,'body','Cabeça e gola de papel'],
 upperNear:[.70,200,48,430,332,4,'body','Braço erguido · ombreira e fitas'],
 upperFar:[.70,45,50,605,332,4,'body','Braço baixo · ombreira e fitas'],
 foreNear:[.65,40,270,307,403,6,'upperNear','Antebraço erguido e mão'],
 foreFar:[.65,50,20,684,461,6,'upperFar','Antebraço baixo e mão'],
 thighNear:[.62,100,50,450,552,2,'body','Coxa próxima e placa de quadril'],
 thighFar:[.61,100,50,580,552,1,'body','Coxa distante e placa de quadril'],
 shinNear:[.75,110,35,445,675,5,'thighNear','Canela próxima · joelheira e pé'],
 shinFar:[.75,45,35,585,675,5,'thighFar','Canela distante · joelheira e pé'],
 bowRaised:[.90,117,233,302,362,5,'foreNear','Arco erguido · linha e suportes'],
 bowLowered:[.80,60,168,745,540,5,'foreFar','Arco baixo · linha e suportes'],
 tail:[.85,15,170,590,565,0,'body','Rabiola · cauda, fio, nó e abas']
};
for(const [id,[s,ax,ay,x,y,z,parent,name]]of Object.entries(layout)){
 const b=slices.boxes[id],w=b[2]-b[0],h=b[3]-b[1];p.assets[id]={name,src:`/art/soulgen/keys/alvacordo/cutout-rig-v1/${id}.png`,width:w,height:h};
 p.parts.push({id,name,asset:id,source:[0,0,w,h],rect:[x-ax*s,y-ay*s,w*s,h*s],pivot:[x,y],z,parent,visible:true,lag:0});
}
const head=p.parts.find(x=>x.id==='head');head.faces={};head.faceWindows=registration.windows;
for(const face of ['fierce','hurt','happy']){const a=p.assets.head;p.assets[face]={...a,name:face,src:`/art/soulgen/keys/alvacordo/cutout-rig-v1/head-${face}.png`};head.faces[face]={asset:face,source:[0,0,a.width,a.height]};}
p.anatomy={version:1,ratios:[],behind:[{part:'tail',other:'body'},{part:'thighFar',other:'body'},{part:'bowRaised',other:'foreNear'},{part:'bowLowered',other:'foreFar'}],joints:p.parts.filter(x=>x.parent).map(x=>{const parent=p.parts.find(y=>y.id===x.parent);return {part:x.id,parent:x.parent,anchor:[(x.pivot[0]-x.rect[0])/x.rect[2],(x.pivot[1]-x.rect[1])/x.rect[3]],socket:[(x.pivot[0]-parent.rect[0])/parent.rect[2],(x.pivot[1]-parent.rect[1])/parent.rect[3]],maxGap:2};})};
const frame=(t,changes={})=>({t,ease:'smooth',values:Object.fromEntries(['root',...p.parts.map(x=>x.id)].map(id=>[id,{...identity(),...changes[id]}]))});
function cycle(id,label,seconds,fn){const frames=Array.from({length:17},(_,i)=>frame(seconds*i/16,fn(Math.PI*2*i/16)));frames.at(-1).values=structuredClone(frames[0].values);p.clips[id]={label,seconds,loop:true,frames,expressions:[]};}
cycle('idle','Guarda dos arcos',2.8,t=>({head:{rotation:.5*Math.sin(t)},upperNear:{rotation:.4*Math.sin(t)},foreFar:{rotation:.5*Math.sin(t)},tail:{rotation:2*Math.sin(t)}}));
cycle('flight','Passo vigilante',1.3,t=>({root:{y:1.2*Math.sin(2*t)},thighNear:{rotation:3*Math.sin(t)},thighFar:{rotation:-3*Math.sin(t)},shinNear:{rotation:-1.5*Math.sin(t)},shinFar:{rotation:1.5*Math.sin(t)},upperNear:{rotation:-1*Math.sin(t)},upperFar:{rotation:1.5*Math.sin(t)},tail:{rotation:3*Math.sin(t)}}));
function action(id,label,seconds,hit,keys,face){p.clips[id]={label,seconds,loop:false,...(hit?{hitTime:hit}:{}),frames:keys.map(([t,v])=>frame(t,v)),expressions:[{start:.04,end:seconds-.04,face}]};}
action('skill','Tensão cruzada',1.65,.62,[[0,{}],[.28,{root:{x:4},upperNear:{rotation:3},foreNear:{rotation:5},foreFar:{rotation:-3}}],[.62,{root:{x:-10},upperNear:{rotation:-4},foreNear:{rotation:-12},upperFar:{rotation:3},foreFar:{rotation:8},head:{rotation:-1},tail:{rotation:4}}],[1.05,{root:{x:-3},foreNear:{rotation:-4}}],[1.65,{}]],'fierce');
action('hurt','Impacto na guarda',.85,null,[[0,{}],[.14,{root:{x:6,rotation:.7},head:{rotation:2},foreNear:{rotation:6},foreFar:{rotation:-5}}],[.5,{root:{x:2}}],[.85,{}]],'hurt');
action('victory','Confiança serena',2.2,null,[[0,{}],[.5,{head:{rotation:-2},foreNear:{rotation:-4},foreFar:{rotation:4},tail:{rotation:5}}],[1.3,{head:{rotation:-1},tail:{rotation:-3}}],[2.2,{}]],'happy');
action('defeat','Arcos em repouso',1.4,null,[[0,{}],[.5,{root:{y:4},head:{rotation:3},upperNear:{rotation:-3}}],[1.4,{root:{y:8},head:{rotation:5},upperNear:{rotation:-6},foreNear:{rotation:-6},foreFar:{rotation:3}}]],'hurt');
await exportReview(p,dir,{registration});
