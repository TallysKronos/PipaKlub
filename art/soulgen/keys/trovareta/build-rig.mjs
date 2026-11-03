import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {identity} from '../../../../tools/soulgen-studio/model.mjs';
import {exportReview} from '../../../../tools/soulgen-studio/export-review.mjs';

const folder=fileURLToPath(new URL('./cutout-rig-v1/',import.meta.url));
// Once the author has edited the project, its saved rig owns geometry and animation.
// Re-export it by default; never silently reset the author's pivots to the initial layout.
if(fs.existsSync(folder+'author-import.json')&&!process.argv.includes('--rebuild-source')){
 await exportReview(JSON.parse(fs.readFileSync(folder+'trovareta.soulgen.json')),folder,{registration:JSON.parse(fs.readFileSync(folder+'registration.json'))});
 process.exit(0);
}
const slices=JSON.parse(fs.readFileSync(folder+'slices.json'));
const project={schema:'soulgen-studio',version:1,name:'Trovareta · guardiã do trovão',creatureId:'trovareta',artRevision:1,rigRevision:1,preserveSourceAspect:true,width:480,height:340,rootPivot:[260,175],brief:{species:'Trovareta · arquitetura A aprovada',personality:'Paciente e temível',view:'Três quartos para a direita',reference:'art/soulgen/campaign-redesigns-v1/contorno-carcara-v1/trovareta.png',kiteAnatomy:'Asas de vareta bifurcada; torso de papel; duas patas e duas rabiolas completas.',notes:'Peças redesenhadas a partir da base aprovada. Oito PNGs separados; expressões registradas numa janela fixa. Ferramenta local, sem integração em batalha.'},assets:{},parts:[],clips:{}};
// Each socket is measured on the painted root; proportions of each source PNG stay unchanged.
const placement={
 body:{scale:.29,xy:[220,130],pivot:[260,175],z:4},
 head:{scale:.3,anchor:[149,231],pivot:[263,141],z:6},
 wingNear:{scale:.38,anchor:[392,321],pivot:[234,158],z:3,lag:.025},
 wingFar:{scale:.38,anchor:[26,262],pivot:[282,158],z:2,lag:.05},
 legNear:{scale:.22,anchor:[188,39],pivot:[251,208],z:3},
 legFar:{scale:.22,anchor:[31,45],pivot:[270,208],z:1},
 tailNear:{scale:.3,anchor:[570,26],pivot:[239,192],z:0,lag:.1},
 tailFar:{scale:.3,anchor:[477,32],pivot:[245,207],z:-1,lag:.14}
};
const names={body:'Torso de papel',head:'Cabeça e expressão',wingNear:'Asa próxima · vareta bifurcada',wingFar:'Asa distante · vareta bifurcada',legNear:'Pata próxima',legFar:'Pata distante',tailNear:'Rabiola próxima · fio e vela',tailFar:'Rabiola distante · fio e vela'};
for(const [id,p]of Object.entries(placement)){
 const [, ,w,h]=slices.parts[id].crop,xy=p.xy||[p.pivot[0]-p.anchor[0]*p.scale,p.pivot[1]-p.anchor[1]*p.scale];
 project.assets[id]={name:names[id],src:`/art/soulgen/keys/trovareta/cutout-rig-v1/${id}.png`,width:w,height:h};
 project.parts.push({id,name:names[id],asset:id,source:[0,0,w,h],rect:[...xy,w*p.scale,h*p.scale],pivot:p.pivot,z:p.z,parent:id==='body'?null:'body',visible:true,lag:p.lag||0});
}
const head=project.parts.find(p=>p.id==='head'),registration=JSON.parse(fs.readFileSync(folder+'registration.json'));
head.faces={};head.faceWindows=registration.windows;
for(const face of ['fierce','hurt','happy']){const a=project.assets.head;project.assets[face]={name:face,src:`/art/soulgen/keys/trovareta/cutout-rig-v1/head-${face}.png`,width:a.width,height:a.height};head.faces[face]={asset:face,source:[0,0,a.width,a.height]};}
const body=project.parts.find(p=>p.id==='body');
project.anatomy={version:1,ratios:[],behind:[{part:'wingFar',other:'body'},{part:'tailNear',other:'body'},{part:'tailFar',other:'body'}],joints:project.parts.filter(p=>p.parent).map(p=>({part:p.id,parent:'body',anchor:[(p.pivot[0]-p.rect[0])/p.rect[2],(p.pivot[1]-p.rect[1])/p.rect[3]],socket:[(p.pivot[0]-body.rect[0])/body.rect[2],(p.pivot[1]-body.rect[1])/body.rect[3]],maxGap:.05}))};
const frame=(t,changes={},ease='smooth')=>({t,ease,values:Object.fromEntries(['root',...project.parts.map(p=>p.id)].map(id=>[id,{...identity(),...changes[id]}]))});
function cycle(id,label,seconds,fn){const frames=Array.from({length:17},(_,i)=>frame(i*seconds/16,fn(i*Math.PI*2/16),'spline'));frames.at(-1).values=structuredClone(frames[0].values);project.clips[id]={label,seconds,loop:true,frames,expressions:[]};}
cycle('idle','Vigília da tempestade',2.8,t=>({root:{y:1.1*Math.sin(t)},head:{rotation:.6*Math.sin(t)},wingNear:{rotation:1.8*Math.sin(t)},wingFar:{rotation:-1.6*Math.sin(t)},tailNear:{rotation:3*Math.sin(t)},tailFar:{rotation:2.5*Math.sin(t+.25)}}));
cycle('flight','Batida de trovão',1.15,t=>({root:{y:3*Math.sin(t)},wingNear:{rotation:13*Math.sin(t)},wingFar:{rotation:-12*Math.sin(t)},head:{rotation:-1*Math.sin(t)},legNear:{rotation:3*Math.sin(t)},legFar:{rotation:2*Math.sin(t)},tailNear:{rotation:6*Math.sin(t)},tailFar:{rotation:5*Math.sin(t+.3)}}));
project.clips.skill={label:'Estalo da vareta',seconds:1.65,loop:false,hitTime:.65,frames:[frame(0),frame(.25,{root:{x:-5,y:2},wingNear:{rotation:9},wingFar:{rotation:-8},head:{rotation:-2}}),frame(.46,{root:{x:-7,y:2},wingNear:{rotation:13},wingFar:{rotation:-12},tailNear:{rotation:-5}}),frame(.65,{root:{x:14,y:-3,rotation:2},wingNear:{rotation:-14},wingFar:{rotation:13},head:{rotation:1},legNear:{rotation:-4},tailNear:{rotation:8},tailFar:{rotation:6}}),frame(.95,{root:{x:5,y:-1},wingNear:{rotation:-4},wingFar:{rotation:4},tailNear:{rotation:4}}),frame(1.35),frame(1.65)],expressions:[{start:.2,end:1.25,face:'fierce'}]};
project.clips.hurt={label:'Recuo na corrente',seconds:.8,loop:false,frames:[frame(0),frame(.12,{root:{x:-8,rotation:-2},head:{rotation:-3},wingNear:{rotation:5},wingFar:{rotation:-5},tailNear:{rotation:-7}}),frame(.3,{root:{x:-3,rotation:1},head:{rotation:1},tailNear:{rotation:3}}),frame(.6),frame(.8)],expressions:[{start:.01,end:.6,face:'hurt'}]};
project.clips.victory={label:'Asas da vitória',seconds:2.2,loop:false,frames:[frame(0),frame(.4,{root:{y:-3},head:{rotation:-3},wingNear:{rotation:6},wingFar:{rotation:-6}}),frame(.8,{root:{y:-6},head:{rotation:-4},wingNear:{rotation:10},wingFar:{rotation:-9},tailNear:{rotation:5},tailFar:{rotation:4}}),frame(1.3,{root:{y:-3},wingNear:{rotation:5},wingFar:{rotation:-5},tailNear:{rotation:-3}}),frame(1.85),frame(2.2)],expressions:[{start:.2,end:1.85,face:'happy'}]};
project.clips.defeat={label:'Vento abatido',seconds:1.1,loop:false,frames:[frame(0),frame(.4,{root:{y:6,rotation:-2},head:{rotation:5},wingNear:{rotation:-8},wingFar:{rotation:8}}),frame(.8,{root:{y:10,rotation:-3},head:{rotation:8},wingNear:{rotation:-13},wingFar:{rotation:12},tailNear:{rotation:-5},tailFar:{rotation:-4}}),frame(1.1,{root:{y:10,rotation:-3},head:{rotation:8},wingNear:{rotation:-13},wingFar:{rotation:12},tailNear:{rotation:-5},tailFar:{rotation:-4}})],expressions:[{start:.1,end:1.1,face:'hurt'}]};
await exportReview(project,folder,{registration});
