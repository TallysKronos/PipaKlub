import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {identity} from '../../../../tools/soulgen-studio/model.mjs';
import {exportReview} from '../../../../tools/soulgen-studio/export-review.mjs';
const dir=fileURLToPath(new URL('./cutout-rig-v1/',import.meta.url));
if(fs.existsSync(dir+'author-import.json')&&!process.argv.includes('--rebuild-source')){
 await exportReview(JSON.parse(fs.readFileSync(dir+'rai.soulgen.json')),dir,{registration:JSON.parse(fs.readFileSync(dir+'registration.json'))});process.exit(0);
}
const boxes=JSON.parse(fs.readFileSync(dir+'slices.json')).boxes;
const project={schema:'soulgen-studio',version:1,name:'Rai · Saber · parceiro do Tyler',creatureId:'rai',artRevision:1,rigRevision:1,preserveSourceAspect:true,width:760,height:620,rootPivot:[350,315],assets:{},parts:[],clips:{},brief:{species:'Tigre dente-de-sabre do Tyler',aliases:['Saber'],view:'Três quartos para a esquerda',reference:'art/tyler-saber-manga-v2/saber-sheet-v2.png',notes:'Rai é o nome da bíblia; Saber é o nome anterior da referência, não uma segunda espécie. Conversão de arte, sem atributos ou mudanças narrativas.'}};
const placement={
 body:{s:.70,anchor:[180,130],pivot:[350,315],z:3},
 head:{s:.68,anchor:[225,200],pivot:[250,280],z:6},
 frontNear:{s:.60,anchor:[65,25],pivot:[275,350],z:5},
 frontFar:{s:.57,anchor:[65,25],pivot:[245,337],z:1},
 rearNear:{s:.60,anchor:[65,25],pivot:[435,350],z:4},
 rearFar:{s:.57,anchor:[65,25],pivot:[470,337],z:0},
 sail:{s:.70,anchor:[125,245],pivot:[365,240],z:2},
 tail:{s:.70,anchor:[15,15],pivot:[440,245],z:-1,lag:.10}
};
for(const [id,p]of Object.entries(placement)){
 const b=boxes[id],w=b[2]-b[0],h=b[3]-b[1];project.assets[id]={name:id,src:`/art/soulgen/keys/rai/cutout-rig-v1/${id}.png`,width:w,height:h};
 project.parts.push({id,name:id,asset:id,source:[0,0,w,h],rect:[p.pivot[0]-p.anchor[0]*p.s,p.pivot[1]-p.anchor[1]*p.s,w*p.s,h*p.s],pivot:p.pivot,z:p.z,parent:id==='body'?null:id==='tail'?'sail':'body',visible:true,lag:p.lag||0});
}
const registration=JSON.parse(fs.readFileSync(dir+'registration.json'));const head=project.parts.find(p=>p.id==='head');head.faces={};head.faceWindows=registration.windows;
for(const face of ['fierce','hurt','happy']){const a=project.assets.head;project.assets[face]={...a,name:face,src:`/art/soulgen/keys/rai/cutout-rig-v1/head-${face}.png`};head.faces[face]={asset:face,source:[0,0,a.width,a.height]};}
project.anatomy={version:1,ratios:[],behind:[{part:'frontFar',other:'body'},{part:'rearFar',other:'body'},{part:'tail',other:'sail'}],joints:project.parts.filter(p=>p.parent).map(p=>{const parent=project.parts.find(x=>x.id===p.parent);return {part:p.id,parent:parent.id,anchor:[(p.pivot[0]-p.rect[0])/p.rect[2],(p.pivot[1]-p.rect[1])/p.rect[3]],socket:[(p.pivot[0]-parent.rect[0])/parent.rect[2],(p.pivot[1]-parent.rect[1])/parent.rect[3]],maxGap:2};})};
const frame=(t,changes={})=>({t,ease:'smooth',values:Object.fromEntries(['root',...project.parts.map(p=>p.id)].map(id=>[id,{...identity(),...changes[id]}]))});
function cycle(id,label,seconds,fn){const frames=Array.from({length:17},(_,i)=>frame(seconds*i/16,fn(Math.PI*2*i/16)));frames.at(-1).values=structuredClone(frames[0].values);project.clips[id]={label,seconds,loop:true,frames,expressions:[]};}
cycle('idle','Vigília das pétalas',3,t=>({root:{y:Math.sin(t)},head:{rotation:.5*Math.sin(t)},sail:{rotation:.7*Math.sin(t)},tail:{rotation:3*Math.sin(t)}}));
cycle('flight','Passo do sabre',1.2,t=>({root:{y:2*Math.sin(2*t)},frontNear:{rotation:6*Math.sin(t)},frontFar:{rotation:-6*Math.sin(t)},rearNear:{rotation:-5*Math.sin(t)},rearFar:{rotation:5*Math.sin(t)},head:{rotation:.8*Math.sin(t)},tail:{rotation:5*Math.sin(t)}}));
function clip(id,label,seconds,hit,keys,face){project.clips[id]={label,seconds,loop:false,...(hit?{hitTime:hit}:{}),frames:keys.map(([t,v])=>frame(t,v)),expressions:[{start:.06,end:seconds-.05,face}]};}
clip('skill','Bote de pétalas',1.7,.62,[[0,{}],[.25,{root:{x:7,y:3},head:{rotation:-3},frontNear:{rotation:-7}}],[.62,{root:{x:-18,y:-3},head:{rotation:3},frontNear:{rotation:12},frontFar:{rotation:7},tail:{rotation:-7}}],[1.05,{root:{x:-5},frontNear:{rotation:3}}],[1.7,{}]],'fierce');
clip('hurt','Recuo do sabre',.85,null,[[0,{}],[.14,{root:{x:8,rotation:1},head:{rotation:-4},tail:{rotation:5}}],[.5,{root:{x:3}}],[.85,{}]],'hurt');
clip('victory','Elo sereno',2.4,null,[[0,{}],[.5,{head:{rotation:-3},root:{y:-2},tail:{rotation:5}}],[1.2,{head:{rotation:-4},tail:{rotation:-3}}],[2.4,{}]],'happy');
clip('defeat','Pétalas recolhidas',1.3,null,[[0,{}],[.6,{root:{y:6},head:{rotation:6},frontNear:{rotation:-5}}],[1.3,{root:{y:9},head:{rotation:8},frontNear:{rotation:-7},rearNear:{rotation:3}}]],'hurt');
await exportReview(project,dir,{registration});
