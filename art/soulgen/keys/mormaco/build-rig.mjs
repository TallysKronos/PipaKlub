import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {identity} from '../../../../tools/soulgen-studio/model.mjs';
import {exportReview} from '../../../../tools/soulgen-studio/export-review.mjs';
const dir=fileURLToPath(new URL('./cutout-rig-v1/',import.meta.url));
if(fs.existsSync(dir+'author-import.json')&&!process.argv.includes('--rebuild-source')){
 await exportReview(JSON.parse(fs.readFileSync(dir+'mormaco.soulgen.json')),dir,{registration:JSON.parse(fs.readFileSync(dir+'registration.json'))});
 process.exit(0);
}
const boxes=JSON.parse(fs.readFileSync(dir+'slices.json')).boxes;
const project={schema:'soulgen-studio',version:1,name:'Mormaço · forma livre',creatureId:'mormaco',artRevision:1,rigRevision:1,preserveSourceAspect:true,width:1000,height:800,rootPivot:[450,440],assets:{},parts:[],clips:{},brief:{species:'Mormaço C aprovado, tatu/pangolim com gêiseres',view:'Três quartos para a esquerda',notes:'Fonte Mormaço C livre recuperada do Git. Peças e animações para revisão. Sem integração de jogo.'}};
const placement={
 body:{s:.90,anchor:[180,160],pivot:[450,420],z:4},
 head:{s:.70,anchor:[210,110],pivot:[330,420],z:8},
 frontNear:{s:.65,anchor:[65,25],pivot:[355,480],z:7},
 frontFar:{s:.60,anchor:[65,25],pivot:[320,465],z:1},
 rearNear:{s:.60,anchor:[60,25],pivot:[540,495],z:6},
 rearFar:{s:.56,anchor:[60,25],pivot:[570,475],z:0},
 tail:{s:.65,anchor:[30,30],pivot:[580,470],z:2,lag:.1},
 sail:{s:.65,anchor:[90,160],pivot:[600,410],z:5.5},
 ribbon:{s:.60,anchor:[20,15],pivot:[660,410],z:5,lag:.1},
 geyserNear:{s:.65,anchor:[100,260],pivot:[420,305],z:10,lag:.03},
 geyserFar:{s:.60,anchor:[100,260],pivot:[510,300],z:9,lag:.05}
};
for(const [id,p]of Object.entries(placement)){
 const b=boxes[id],w=b[2]-b[0],h=b[3]-b[1];
 project.assets[id]={name:id,src:`/art/soulgen/keys/mormaco/cutout-rig-v1/${id}.png`,width:w,height:h};
 project.parts.push({id,name:id,asset:id,source:[0,0,w,h],rect:[p.pivot[0]-p.anchor[0]*p.s,p.pivot[1]-p.anchor[1]*p.s,w*p.s,h*p.s],pivot:p.pivot,z:p.z,parent:id==='body'?null:id==='ribbon'?'sail':'body',visible:true,lag:p.lag||0});
}
const registration=JSON.parse(fs.readFileSync(dir+'registration.json'));const head=project.parts.find(p=>p.id==='head');head.faces={};head.faceWindows=registration.windows;
for(const face of ['fierce','hurt','happy']){const a=project.assets.head;project.assets[face]={...a,name:face,src:`/art/soulgen/keys/mormaco/cutout-rig-v1/head-${face}.png`};head.faces[face]={asset:face,source:[0,0,a.width,a.height]};}
const body=project.parts[0];
project.anatomy={version:1,ratios:[],behind:[{part:'frontFar',other:'body'},{part:'rearFar',other:'body'},{part:'tail',other:'body'}],joints:project.parts.filter(p=>['head','frontNear','frontFar','rearNear','rearFar','tail'].includes(p.id)).map(p=>({part:p.id,parent:'body',anchor:[(p.pivot[0]-p.rect[0])/p.rect[2],(p.pivot[1]-p.rect[1])/p.rect[3]],socket:[(p.pivot[0]-body.rect[0])/body.rect[2],(p.pivot[1]-body.rect[1])/body.rect[3]],maxGap:2}))};
const frame=(t,changes={})=>({t,ease:'smooth',values:Object.fromEntries(['root',...project.parts.map(p=>p.id)].map(id=>[id,{...identity(),...changes[id]}]))});
function cycle(id,label,seconds,fn){const frames=Array.from({length:17},(_,i)=>frame(seconds*i/16,fn(Math.PI*2*i/16)));frames.at(-1).values=structuredClone(frames[0].values);project.clips[id]={label,seconds,loop:true,frames,expressions:[]};}
cycle('idle','Calor tranquilo',3.2,t=>({root:{y:1.3*Math.sin(t)},head:{rotation:.7*Math.sin(t)},sail:{rotation:.5*Math.sin(t)},geyserNear:{scaleY:1+.035*Math.sin(t)},geyserFar:{scaleY:1+.03*Math.sin(t)},tail:{rotation:2*Math.sin(t)}}));
cycle('flight','Passo das dunas',1.6,t=>({root:{y:2*Math.sin(2*t)},head:{rotation:Math.sin(t)},frontNear:{rotation:5*Math.sin(t)},frontFar:{rotation:-5*Math.sin(t)},rearNear:{rotation:-4*Math.sin(t)},rearFar:{rotation:4*Math.sin(t)},tail:{rotation:3*Math.sin(t)},sail:{rotation:.8*Math.sin(t)}}));
function clip(id,label,seconds,hit,keys,face){project.clips[id]={label,seconds,loop:false,...(hit?{hitTime:hit}:{}),frames:keys.map(([t,v])=>frame(t,v)),expressions:[{start:.05,end:seconds-.05,face}]};}
clip('skill','Jato do Mormaço',1.9,.8,[[0,{}],[.35,{root:{x:7,y:2},head:{rotation:-3},frontNear:{rotation:-7}}],[.8,{root:{x:-8,rotation:-1},geyserNear:{scaleY:1.15},geyserFar:{scaleY:1.12},head:{rotation:5},frontNear:{rotation:8},tail:{rotation:-5}}],[1.2,{root:{x:-5},head:{rotation:2}}],[1.9,{}]],'fierce');
clip('hurt','Casco recolhido',1,null,[[0,{}],[.16,{root:{x:10,rotation:1},head:{rotation:-4},tail:{rotation:4}}],[.5,{root:{x:4}}],[1,{}]],'hurt');
clip('victory','Sossego de parceiro',2.5,null,[[0,{}],[.6,{head:{rotation:-3},tail:{rotation:4},root:{y:-2}}],[1.2,{head:{rotation:-4},tail:{rotation:-2}}],[2.5,{}]],'happy');
clip('defeat','Peso no chão',1.4,null,[[0,{}],[.6,{root:{y:8},head:{rotation:-5},frontNear:{rotation:-6}}],[1.4,{root:{y:12},head:{rotation:-7},frontNear:{rotation:-8},rearNear:{rotation:4}}]],'hurt');
await exportReview(project,dir,{registration});
