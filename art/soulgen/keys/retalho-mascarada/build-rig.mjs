import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {identity} from '../../../../tools/soulgen-studio/model.mjs';
import {exportReview} from '../../../../tools/soulgen-studio/export-review.mjs';
const dir=fileURLToPath(new URL('./cutout-rig-v1/',import.meta.url));
if(fs.existsSync(dir+'author-import.json')&&!process.argv.includes('--rebuild-source')){
 await exportReview(JSON.parse(fs.readFileSync(dir+'retalho-mascarada.soulgen.json')),dir,{registration:JSON.parse(fs.readFileSync(dir+'registration.json'))});process.exit(0);
}
const boxes=JSON.parse(fs.readFileSync(dir+'slices.json')).boxes;
const project={schema:'soulgen-studio',version:1,name:'Retalho mascarada · cicatrizes das Ruínas',creatureId:'retalho-mascarada',artRevision:1,rigRevision:1,preserveSourceAspect:true,width:760,height:800,rootPivot:[380,430],assets:{},parts:[],clips:{},brief:{species:'Retalho mascarada C corcunda, concept aprovado',view:'Três quartos para a direita',notes:'Concept C corcunda aprovado. Partes e animações em revisão; evolução sobrevivente das Ruínas, sem possessão ou integração no jogo.'}};
const placement={
 body:{s:.85,anchor:[150,160],pivot:[380,350],z:3},
 head:{s:.75,anchor:[120,275],pivot:[480,320],z:7},
 armNear:{s:.75,anchor:[80,30],pivot:[435,360],z:6},
 armFar:{s:.70,anchor:[75,30],pivot:[380,335],z:1},
 legNear:{s:.75,anchor:[60,25],pivot:[330,475],z:5},
 legFar:{s:.72,anchor:[70,25],pivot:[275,465],z:2},
 tail:{s:.70,anchor:[255,80],pivot:[290,460],z:0,lag:.12}
};
for(const [id,p] of Object.entries(placement)){
 const b=boxes[id],w=b[2]-b[0],h=b[3]-b[1];
 project.assets[id]={name:id,src:`/art/soulgen/keys/retalho-mascarada/cutout-rig-v1/${id}.png`,width:w,height:h};
 project.parts.push({id,name:id,asset:id,source:[0,0,w,h],rect:[p.pivot[0]-p.anchor[0]*p.s,p.pivot[1]-p.anchor[1]*p.s,w*p.s,h*p.s],pivot:p.pivot,z:p.z,parent:id==='body'?null:'body',visible:true,lag:p.lag||0});
}
const head=project.parts.find(p=>p.id==='head');head.faces={};
const registration=JSON.parse(fs.readFileSync(dir+'registration.json'));head.faceWindows=registration.windows;
for(const face of ['fierce','hurt','happy']){const a=project.assets.head;project.assets[face]={...a,name:face,src:`/art/soulgen/keys/retalho-mascarada/cutout-rig-v1/head-${face}.png`};head.faces[face]={asset:face,source:[0,0,a.width,a.height]};}
const torso=project.parts.find(p=>p.id==='body');
project.anatomy={version:1,ratios:[],behind:[{part:'armFar',other:'body'},{part:'legFar',other:'body'},{part:'tail',other:'body'}],joints:project.parts.filter(p=>p.parent).map(p=>({part:p.id,parent:'body',anchor:[(p.pivot[0]-p.rect[0])/p.rect[2],(p.pivot[1]-p.rect[1])/p.rect[3]],socket:[(p.pivot[0]-torso.rect[0])/torso.rect[2],(p.pivot[1]-torso.rect[1])/torso.rect[3]],maxGap:2}))};
const frame=(time,values={})=>({t:time,ease:'smooth',values:Object.fromEntries(['root',...project.parts.map(p=>p.id)].map(id=>[id,{...identity(),...values[id]}]))});
function cycle(id,label,seconds,fn){const frames=Array.from({length:17},(_,i)=>frame(seconds*i/16,fn(TAU*i/16)));frames.at(-1).values=structuredClone(frames[0].values);project.clips[id]={label,seconds,loop:true,frames,expressions:[]};}
const TAU=Math.PI*2;
cycle('idle','Vigília selvagem',3,t=>({root:{y:1.2*Math.sin(t)},head:{rotation:.5*Math.sin(t)},armNear:{rotation:1.2*Math.sin(t)},tail:{rotation:3*Math.sin(t)}}));
cycle('flight','Passo curvado',1.4,t=>({root:{y:1.5*Math.sin(2*t)},armNear:{rotation:5*Math.sin(t)},armFar:{rotation:-5*Math.sin(t)},legNear:{rotation:4*Math.sin(t)},legFar:{rotation:-4*Math.sin(t)},tail:{rotation:7*Math.sin(t)}}));
function clip(id,label,seconds,hitTime,keys,face){project.clips[id]={label,seconds,loop:false,...(hitTime?{hitTime}:{}),frames:keys.map(([t,v])=>frame(t,v)),expressions:face?[{start:.05,end:seconds-.05,face}]:[]};}
clip('skill','Garra das cicatrizes',1.8,.72,[[0,{}],[.3,{root:{x:-6},armNear:{rotation:16},armFar:{rotation:-6},head:{rotation:-2}}],[.72,{root:{x:14},armNear:{rotation:-20},armFar:{rotation:9},tail:{rotation:8}}],[1.2,{root:{x:4},armNear:{rotation:-8}}],[1.8,{}]],'fierce');
clip('hurt','Recuo das Ruínas',.9,null,[[0,{}],[.15,{root:{x:-10,rotation:-2},head:{rotation:3},armNear:{rotation:7}}],[.5,{root:{x:-3}}],[.9,{}]],'hurt');
clip('victory','Confiança recuperada',2.4,null,[[0,{}],[.5,{head:{rotation:-3},armNear:{rotation:-8},tail:{rotation:6}}],[1.2,{root:{y:-4},head:{rotation:-4},armNear:{rotation:-12}}],[2.4,{}]],'happy');
clip('defeat','Dorso recolhido',1.3,null,[[0,{}],[.7,{root:{y:8,rotation:-2},head:{rotation:7},armNear:{rotation:8}}],[1.3,{root:{y:10,rotation:-2},head:{rotation:10},armNear:{rotation:10}}]],'hurt');
await exportReview(project,dir,{registration});
