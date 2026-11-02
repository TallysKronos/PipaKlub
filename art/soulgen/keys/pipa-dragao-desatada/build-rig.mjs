import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {identity} from '../../../../tools/soulgen-studio/model.mjs';
import {exportReview} from '../../../../tools/soulgen-studio/export-review.mjs';
const dir=fileURLToPath(new URL('./cutout-rig-v3/',import.meta.url));
if(fs.existsSync(dir+'author-import.json')&&!process.argv.includes('--rebuild-source')){
 await exportReview(JSON.parse(fs.readFileSync(dir+'pipa-dragao-desatada.soulgen.json')),dir,{registration:JSON.parse(fs.readFileSync(dir+'registration.json'))});
 process.exit(0);
}
const boxes=JSON.parse(fs.readFileSync(dir+'slices.json')).boxes;
const project={schema:'soulgen-studio',version:1,name:'Pipa-Dragão desatada · químico B',creatureId:'pipa-dragao-desatada',artRevision:3,rigRevision:1,preserveSourceAspect:true,width:860,height:600,rootPivot:[390,300],assets:{},parts:[],clips:{},brief:{species:'Pipa-Dragão desatada, identidade químico B existente',view:'Três quartos para a esquerda',notes:'Fonte: origin/feature/retalho-bosque-d, quimico-b-v1/desatada-estudo.png. Peças derivadas e montagem em revisão; não é novo design ou integração.'}};
const placement={
 body:{s:.70,anchor:[265,210],pivot:[390,300],z:3},
 head:{s:.72,anchor:[259,111],pivot:[235,291],z:7},
 frontNear:{s:.64,anchor:[80,60],pivot:[300,322],z:6},
 frontFar:{s:.59,anchor:[78,58],pivot:[245,303],z:1},
 rearNear:{s:.64,anchor:[70,45],pivot:[490,345],z:5},
 rearFar:{s:.59,anchor:[70,45],pivot:[510,325],z:0},
 tail:{s:.57,anchor:[43,60],pivot:[553,333],z:2,lag:.10},
 equipment:{s:.65,anchor:[200,210],pivot:[411,201],z:4,lag:.025}
};
for(const [id,p]of Object.entries(placement)){
 const b=boxes[id],w=b[2]-b[0],h=b[3]-b[1];
 project.assets[id]={name:id,src:`/art/soulgen/keys/pipa-dragao-desatada/cutout-rig-v3/${id}.png`,width:w,height:h};
 project.parts.push({id,name:id,asset:id,source:[0,0,w,h],rect:[p.pivot[0]-p.anchor[0]*p.s,p.pivot[1]-p.anchor[1]*p.s,w*p.s,h*p.s],pivot:p.pivot,z:p.z,parent:id==='body'?null:'body',visible:true,lag:p.lag||0});
}
const registration=JSON.parse(fs.readFileSync(dir+'registration.json'));const head=project.parts.find(p=>p.id==='head');head.faces={};head.faceWindows=registration.windows;
for(const face of ['fierce','hurt','happy']){const a=project.assets.head;project.assets[face]={...a,name:face,src:`/art/soulgen/keys/pipa-dragao-desatada/cutout-rig-v3/head-${face}.png`};head.faces[face]={asset:face,source:[0,0,a.width,a.height]};}
const body=project.parts[0];
project.anatomy={version:1,ratios:[],behind:[{part:'frontFar',other:'body'},{part:'rearFar',other:'body'},{part:'tail',other:'body'}],joints:project.parts.filter(p=>p.parent).map(p=>({part:p.id,parent:'body',anchor:[(p.pivot[0]-p.rect[0])/p.rect[2],(p.pivot[1]-p.rect[1])/p.rect[3]],socket:[(p.pivot[0]-body.rect[0])/body.rect[2],(p.pivot[1]-body.rect[1])/body.rect[3]],maxGap:2}))};
// Equipment socket is above body bounds, not an anatomical bone joint.
project.anatomy.joints=project.anatomy.joints.filter(j=>j.part!=='equipment');
const frame=(t,changes={})=>({t,ease:'smooth',values:Object.fromEntries(['root',...project.parts.map(p=>p.id)].map(id=>[id,{...identity(),...changes[id]}]))});
function cycle(id,label,seconds,fn){const frames=Array.from({length:17},(_,i)=>frame(seconds*i/16,fn(Math.PI*2*i/16)));frames.at(-1).values=structuredClone(frames[0].values);project.clips[id]={label,seconds,loop:true,frames,expressions:[]};}
cycle('idle','Respiração cansada',3.2,t=>({root:{y:1.3*Math.sin(t)},head:{rotation:.7*Math.sin(t)},equipment:{rotation:.5*Math.sin(t)},tail:{rotation:2*Math.sin(t)}}));
cycle('flight','Passo pesado',1.6,t=>({root:{y:2*Math.sin(2*t)},head:{rotation:Math.sin(t)},frontNear:{rotation:5*Math.sin(t)},frontFar:{rotation:-5*Math.sin(t)},rearNear:{rotation:-4*Math.sin(t)},rearFar:{rotation:4*Math.sin(t)},tail:{rotation:3*Math.sin(t)},equipment:{rotation:.8*Math.sin(t)}}));
function clip(id,label,seconds,hit,keys,face){project.clips[id]={label,seconds,loop:false,...(hit?{hitTime:hit}:{}),frames:keys.map(([t,v])=>frame(t,v)),expressions:[{start:.05,end:seconds-.05,face}]};}
clip('skill','Investida desatada',1.9,.8,[[0,{}],[.35,{root:{x:7,y:2},head:{rotation:-3},frontNear:{rotation:-7}}],[.8,{root:{x:-16,rotation:-1},head:{rotation:5},frontNear:{rotation:8},tail:{rotation:-5}}],[1.2,{root:{x:-5},head:{rotation:2}}],[1.9,{}]],'fierce');
clip('hurt','Recuo do colosso',1,null,[[0,{}],[.16,{root:{x:10,rotation:1},head:{rotation:-4},tail:{rotation:4}}],[.5,{root:{x:4}}],[1,{}]],'hurt');
clip('victory','Alívio após a luta',2.5,null,[[0,{}],[.6,{head:{rotation:-3},tail:{rotation:4},root:{y:-2}}],[1.2,{head:{rotation:-4},tail:{rotation:-2}}],[2.5,{}]],'happy');
clip('defeat','Peso no chão',1.4,null,[[0,{}],[.6,{root:{y:8},head:{rotation:-5},frontNear:{rotation:-6}}],[1.4,{root:{y:12},head:{rotation:-7},frontNear:{rotation:-8},rearNear:{rotation:4}}]],'hurt');
await exportReview(project,dir,{registration});
