import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {identity} from '../../../../tools/soulgen-studio/model.mjs';
import {exportReview} from '../../../../tools/soulgen-studio/export-review.mjs';
const dir=fileURLToPath(new URL('./cutout-rig-v1/',import.meta.url));
if(fs.existsSync(dir+'author-import.json')&&!process.argv.includes('--rebuild-source')){
 await exportReview(JSON.parse(fs.readFileSync(dir+'platyx.soulgen.json')),dir,{registration:JSON.parse(fs.readFileSync(dir+'registration.json'))});process.exit(0);
}
const boxes=JSON.parse(fs.readFileSync(dir+'slices.json')).boxes;
const project={schema:'soulgen-studio',version:1,name:'Platyx · ornitorrinco tímido',creatureId:'platyx',artRevision:1,rigRevision:1,preserveSourceAspect:true,width:540,height:500,rootPivot:[300,280],assets:{},parts:[],clips:{},brief:{species:'Platyx C aprovado, parceiro do Grampo',view:'Três quartos para a direita',personality:'Tímido e medroso, coragem retraída',reference:'art/soulgen/campaign-redesigns-v1/references/platyx-git/design-c.png',notes:'Conversão spritelizada da identidade C existente, sem alterar espécie ou narrativa; rig em revisão.'}};
const placement={
 body:{s:.85,anchor:[118,110],pivot:[300,280],z:3},
 head:{s:.65,anchor:[210,214],pivot:[300,210],z:5},
 armNear:{s:.60,anchor:[45,170],pivot:[270,280],z:6},
 armFar:{s:.65,anchor:[20,25],pivot:[350,260],z:4},
 footNear:{s:.55,anchor:[100,22],pivot:[275,365],z:2},
 footFar:{s:.55,anchor:[80,22],pivot:[340,357],z:1},
 tail:{s:.65,anchor:[289,140],pivot:[214,320],z:0,lag:.08}
};
for(const [id,p]of Object.entries(placement)){
 const b=boxes[id],w=b[2]-b[0],h=b[3]-b[1];project.assets[id]={name:id,src:`/art/soulgen/keys/platyx/cutout-rig-v1/${id}.png`,width:w,height:h};
 project.parts.push({id,name:id,asset:id,source:[0,0,w,h],rect:[p.pivot[0]-p.anchor[0]*p.s,p.pivot[1]-p.anchor[1]*p.s,w*p.s,h*p.s],pivot:p.pivot,z:p.z,parent:id==='body'?null:'body',visible:true,lag:p.lag||0});
}
const registration=JSON.parse(fs.readFileSync(dir+'registration.json'));const head=project.parts.find(p=>p.id==='head');head.faces={};head.faceWindows=registration.windows;
for(const face of ['fierce','hurt','happy']){const a=project.assets.head;project.assets[face]={...a,name:face,src:`/art/soulgen/keys/platyx/cutout-rig-v1/head-${face}.png`};head.faces[face]={asset:face,source:[0,0,a.width,a.height]};}
const body=project.parts[0];project.anatomy={version:1,ratios:[],behind:[{part:'tail',other:'body'},{part:'footFar',other:'body'}],joints:project.parts.filter(p=>p.parent).map(p=>({part:p.id,parent:'body',anchor:[(p.pivot[0]-p.rect[0])/p.rect[2],(p.pivot[1]-p.rect[1])/p.rect[3]],socket:[(p.pivot[0]-body.rect[0])/body.rect[2],(p.pivot[1]-body.rect[1])/body.rect[3]],maxGap:2}))};
const frame=(t,changes={})=>({t,ease:'smooth',values:Object.fromEntries(['root',...project.parts.map(p=>p.id)].map(id=>[id,{...identity(),...changes[id]}]))});
function cycle(id,label,seconds,fn){const frames=Array.from({length:17},(_,i)=>frame(seconds*i/16,fn(Math.PI*2*i/16)));frames.at(-1).values=structuredClone(frames[0].values);project.clips[id]={label,seconds,loop:true,frames,expressions:[]};}
cycle('idle','Respiro tímido',3,t=>({root:{y:Math.sin(t)},head:{rotation:.6*Math.sin(t)},armNear:{rotation:1.6*Math.sin(t)},tail:{rotation:2*Math.sin(t)}}));
cycle('flight','Passinho cauteloso',1.4,t=>({root:{y:2*Math.sin(2*t)},footNear:{rotation:5*Math.sin(t)},footFar:{rotation:-5*Math.sin(t)},head:{rotation:Math.sin(t)},tail:{rotation:3*Math.sin(t)}}));
function clip(id,label,seconds,hit,keys,face){project.clips[id]={label,seconds,loop:false,...(hit?{hitTime:hit}:{}),frames:keys.map(([t,v])=>frame(t,v)),expressions:[{start:.06,end:seconds-.05,face}]};}
clip('skill','Coragem de bico',1.65,.68,[[0,{}],[.25,{root:{x:-5,y:2},head:{rotation:-3},armNear:{rotation:-7}}],[.68,{root:{x:12,y:-2},head:{rotation:3},armNear:{rotation:14},tail:{rotation:5}}],[1.1,{root:{x:3},armNear:{rotation:4}}],[1.65,{}]],'fierce');
clip('hurt','Esconde o rosto',.95,null,[[0,{}],[.16,{root:{x:-7,y:3},head:{rotation:3},armNear:{rotation:-14},armFar:{rotation:10}}],[.5,{root:{x:-2},armNear:{rotation:-7}}],[.95,{}]],'hurt');
clip('victory','Alívio discreto',2.3,null,[[0,{}],[.5,{root:{y:-3},head:{rotation:-2},armNear:{rotation:5},tail:{rotation:4}}],[1.1,{root:{y:-6},footNear:{rotation:3},footFar:{rotation:-3}}],[1.7,{root:{y:-2}}],[2.3,{}]],'happy');
clip('defeat','Dobra recolhida',1.3,null,[[0,{}],[.6,{root:{y:7,rotation:-2},head:{rotation:6},armNear:{rotation:-9}}],[1.3,{root:{y:9,rotation:-2},head:{rotation:8},armNear:{rotation:-12},armFar:{rotation:6}}]],'hurt');
await exportReview(project,dir,{registration});
