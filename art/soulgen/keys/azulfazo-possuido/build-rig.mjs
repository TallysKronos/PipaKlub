import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {identity} from '../../../../tools/soulgen-studio/model.mjs';
import {exportReview} from '../../../../tools/soulgen-studio/export-review.mjs';
const dir=fileURLToPath(new URL('./cutout-rig-v1/',import.meta.url));
if(fs.existsSync(dir+'author-import.json')&&!process.argv.includes('--rebuild-source')){
 await exportReview(JSON.parse(fs.readFileSync(dir+'azulfazo-possuido.soulgen.json')),dir,{registration:JSON.parse(fs.readFileSync(dir+'registration.json'))});process.exit(0);
}
const boxes=JSON.parse(fs.readFileSync(dir+'slices.json')).boxes;
const project={schema:'soulgen-studio',version:1,name:'Azulfazo possuído · parceiro do Gollia',creatureId:'azulfazo-possuido',artRevision:1,rigRevision:1,preserveSourceAspect:true,width:1000,height:850,rootPivot:[500,420],assets:{},parts:[],clips:{},brief:{species:'Azulfazo A, evolução de Ataque do Azulão, em estado possuído',view:'Frontal em três quartos para a esquerda',notes:'Identidade e paleta aprovadas; montagem para revisão. Forma temporária, sem integração ou atributos novos.'}};
const placement={
 body:{s:.85,anchor:[160,150],pivot:[500,400],z:4},
 head:{s:.70,anchor:[170,260],pivot:[490,340],z:7},
 wingLeft:{s:.85,anchor:[300,200],pivot:[405,300],z:2},
 wingRight:{s:.85,anchor:[50,200],pivot:[555,300],z:3},
 legLeft:{s:.60,anchor:[80,30],pivot:[445,490],z:5},
 legRight:{s:.60,anchor:[80,30],pivot:[545,490],z:6},
 tail:{s:.55,anchor:[250,30],pivot:[540,500],z:1,lag:.10}
};
for(const [id,p]of Object.entries(placement)){
 const b=boxes[id],w=b[2]-b[0],h=b[3]-b[1];project.assets[id]={name:id,src:`/art/soulgen/keys/azulfazo-possuido/cutout-rig-v1/${id}.png`,width:w,height:h};
 project.parts.push({id,name:id,asset:id,source:[0,0,w,h],rect:[p.pivot[0]-p.anchor[0]*p.s,p.pivot[1]-p.anchor[1]*p.s,w*p.s,h*p.s],pivot:p.pivot,z:p.z,parent:id==='body'?null:'body',visible:true,lag:p.lag||0});
}
const registration=JSON.parse(fs.readFileSync(dir+'registration.json')),head=project.parts.find(p=>p.id==='head');head.faces={};head.faceWindows=registration.windows;
for(const face of ['fierce','hurt','happy']){const a=project.assets.head;project.assets[face]={...a,name:face,src:`/art/soulgen/keys/azulfazo-possuido/cutout-rig-v1/head-${face}.png`};head.faces[face]={asset:face,source:[0,0,a.width,a.height]};}
const torso=project.parts[0];
project.anatomy={version:1,ratios:[],behind:[{part:'wingLeft',other:'body'},{part:'wingRight',other:'body'},{part:'tail',other:'body'}],joints:project.parts.filter(p=>p.parent).map(p=>({part:p.id,parent:'body',anchor:[(p.pivot[0]-p.rect[0])/p.rect[2],(p.pivot[1]-p.rect[1])/p.rect[3]],socket:[(p.pivot[0]-torso.rect[0])/torso.rect[2],(p.pivot[1]-torso.rect[1])/torso.rect[3]],maxGap:2}))};
const frame=(t,changes={})=>({t,ease:'smooth',values:Object.fromEntries(['root',...project.parts.map(p=>p.id)].map(id=>[id,{...identity(),...changes[id]}]))});
function cycle(id,label,seconds,fn){const frames=Array.from({length:17},(_,i)=>frame(seconds*i/16,fn(Math.PI*2*i/16)));frames.at(-1).values=structuredClone(frames[0].values);project.clips[id]={label,seconds,loop:true,frames,expressions:[]};}
cycle('idle','Asas sob tensão',2.8,t=>({root:{y:1.2*Math.sin(t)},head:{rotation:.5*Math.sin(t)},wingLeft:{rotation:1.5*Math.sin(t)},wingRight:{rotation:-1.5*Math.sin(t)},tail:{rotation:3*Math.sin(t)}}));
cycle('flight','Batida contida',1.4,t=>({root:{y:3*Math.sin(t)},wingLeft:{rotation:7*Math.sin(t)},wingRight:{rotation:-7*Math.sin(t)},legLeft:{rotation:2*Math.sin(t)},legRight:{rotation:-2*Math.sin(t)},tail:{rotation:5*Math.sin(t)}}));
function clip(id,label,seconds,hit,keys,face){project.clips[id]={label,seconds,loop:false,...(hit?{hitTime:hit}:{}),frames:keys.map(([t,v])=>frame(t,v)),expressions:[{start:.06,end:seconds-.05,face}]};}
clip('skill','Investida do Azulfazo',1.8,.72,[[0,{}],[.3,{root:{x:6,y:2},head:{rotation:2},wingLeft:{rotation:-6},wingRight:{rotation:6}}],[.72,{root:{x:-17,y:-3},head:{rotation:-3},wingLeft:{rotation:9},wingRight:{rotation:-9},tail:{rotation:7}}],[1.15,{root:{x:-4},wingLeft:{rotation:3},wingRight:{rotation:-3}}],[1.8,{}]],'fierce');
clip('hurt','Recuo da amarra',.9,null,[[0,{}],[.15,{root:{x:9,rotation:1},head:{rotation:3},wingLeft:{rotation:-4},wingRight:{rotation:4}}],[.5,{root:{x:3}}],[.9,{}]],'hurt');
clip('victory','Postura dominante',2.3,null,[[0,{}],[.5,{root:{y:-3},head:{rotation:-2},wingLeft:{rotation:-3},wingRight:{rotation:3}}],[1.2,{head:{rotation:-3},tail:{rotation:4}}],[2.3,{}]],'happy');
clip('defeat','Asas cedem',1.3,null,[[0,{}],[.6,{root:{y:7},head:{rotation:5},wingLeft:{rotation:6},wingRight:{rotation:-6}}],[1.3,{root:{y:10},head:{rotation:7},wingLeft:{rotation:9},wingRight:{rotation:-9}}]],'hurt');
await exportReview(project,dir,{registration});
