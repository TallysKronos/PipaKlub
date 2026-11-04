import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {identity} from '../../../../tools/soulgen-studio/model.mjs';
import {exportReview} from '../../../../tools/soulgen-studio/export-review.mjs';
const dir=fileURLToPath(new URL('./cutout-rig-v1/',import.meta.url));
if(fs.existsSync(dir+'author-import.json')&&!process.argv.includes('--rebuild-source')){
 await exportReview(JSON.parse(fs.readFileSync(dir+'riscaz.soulgen.json')),dir,{registration:JSON.parse(fs.readFileSync(dir+'registration.json'))});process.exit(0);
}
const boxes=JSON.parse(fs.readFileSync(dir+'slices.json')).boxes;
const project={schema:'soulgen-studio',version:1,name:'Riscaz · direção A',creatureId:'riscaz',artRevision:1,rigRevision:1,preserveSourceAspect:true,width:800,height:650,rootPivot:[430,360],assets:{},parts:[],clips:{},brief:{species:'Roedor de dobra, direção A escolhida pelo autor',view:'Três quartos para a esquerda',notes:'Identidade recuperada de codex/concepts-personagens. Conversão para revisão, sem atributos, poderes ou integração de campanha.'}};
const placement={
 body:{s:.75,anchor:[190,110],pivot:[440,355],z:3},
 head:{s:.65,anchor:[270,300],pivot:[330,370],z:7},
 frontNear:{s:.60,anchor:[90,20],pivot:[320,350],z:3.5},
 frontFar:{s:.57,anchor:[90,20],pivot:[300,338],z:1},
 rearNear:{s:.55,anchor:[70,20],pivot:[550,360],z:3.5},
 rearFar:{s:.53,anchor:[70,20],pivot:[570,345],z:0},
 sail:{s:.80,anchor:[190,30],pivot:[431,288],z:4,lag:.03},
 tail:{s:.65,anchor:[32,250],pivot:[560,350],z:2,lag:.10}
};
for(const [id,p]of Object.entries(placement)){
 const b=boxes[id],w=b[2]-b[0],h=b[3]-b[1];project.assets[id]={name:id,src:`/art/soulgen/keys/riscaz/cutout-rig-v1/${id}.png`,width:w,height:h};
 project.parts.push({id,name:id,asset:id,source:[0,0,w,h],rect:[p.pivot[0]-p.anchor[0]*p.s,p.pivot[1]-p.anchor[1]*p.s,w*p.s,h*p.s],pivot:p.pivot,z:p.z,parent:id==='body'?null:'body',visible:true,lag:p.lag||0});
}
const registration=JSON.parse(fs.readFileSync(dir+'registration.json')),head=project.parts.find(p=>p.id==='head');head.faces={};head.faceWindows=registration.windows;
for(const face of ['fierce','hurt','happy']){const a=project.assets.head;project.assets[face]={...a,name:face,src:`/art/soulgen/keys/riscaz/cutout-rig-v1/head-${face}.png`};head.faces[face]={asset:face,source:[0,0,a.width,a.height]};}
const body=project.parts[0];
project.anatomy={version:1,ratios:[],behind:[{part:'frontFar',other:'body'},{part:'rearFar',other:'body'},{part:'tail',other:'body'}],joints:project.parts.filter(p=>p.parent).map(p=>({part:p.id,parent:'body',anchor:[(p.pivot[0]-p.rect[0])/p.rect[2],(p.pivot[1]-p.rect[1])/p.rect[3]],socket:[(p.pivot[0]-body.rect[0])/body.rect[2],(p.pivot[1]-body.rect[1])/body.rect[3]],maxGap:2}))};
const frame=(t,changes={})=>({t,ease:'smooth',values:Object.fromEntries(['root',...project.parts.map(p=>p.id)].map(id=>[id,{...identity(),...changes[id]}]))});
function cycle(id,label,seconds,fn){const frames=Array.from({length:17},(_,i)=>frame(seconds*i/16,fn(Math.PI*2*i/16)));frames.at(-1).values=structuredClone(frames[0].values);project.clips[id]={label,seconds,loop:true,frames,expressions:[]};}
cycle('idle','Escuta desconfiada',2.8,t=>({body:{y:.7*Math.sin(t)},head:{rotation:.5*Math.sin(t)},sail:{rotation:.6*Math.sin(t)},tail:{rotation:2.5*Math.sin(t)}}));
cycle('flight','Passo rasteiro',1.2,t=>({root:{y:1.5*Math.sin(2*t)},frontNear:{rotation:5*Math.sin(t)},frontFar:{rotation:-5*Math.sin(t)},rearNear:{rotation:-4*Math.sin(t)},rearFar:{rotation:4*Math.sin(t)},tail:{rotation:4*Math.sin(t)}}));
function clip(id,label,seconds,hit,keys,face){project.clips[id]={label,seconds,loop:false,...(hit?{hitTime:hit}:{}),frames:keys.map(([t,v])=>frame(t,v)),expressions:[{start:.06,end:seconds-.05,face}]};}
clip('skill','Avanço de dobra',1.6,.6,[[0,{}],[.25,{root:{x:5,y:2},head:{rotation:-2},sail:{rotation:2}}],[.6,{root:{x:-16,y:1},head:{rotation:2},frontNear:{rotation:9},frontFar:{rotation:5},tail:{rotation:-5}}],[1.05,{root:{x:-4},frontNear:{rotation:2}}],[1.6,{}]],'fierce');
clip('hurt','Recuo atento',.85,null,[[0,{}],[.14,{root:{x:7,rotation:1},head:{rotation:-3},sail:{rotation:-2}}],[.5,{root:{x:2}}],[.85,{}]],'hurt');
clip('victory','Confiança discreta',2.2,null,[[0,{}],[.45,{head:{rotation:-2},sail:{rotation:-1},tail:{rotation:4}}],[1.15,{root:{y:-2},head:{rotation:-3},tail:{rotation:-2}}],[2.2,{}]],'happy');
clip('defeat','Vela baixa',1.3,null,[[0,{}],[.6,{root:{y:6},head:{rotation:4},frontNear:{rotation:-5}}],[1.3,{root:{y:8},head:{rotation:6},sail:{rotation:2},frontNear:{rotation:-6}}]],'hurt');
await exportReview(project,dir,{registration});
