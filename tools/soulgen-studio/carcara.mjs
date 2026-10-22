import {parts,clips,pose} from '../../art/soulgen/keys/carcara/color-rig/rig.mjs';
import {identity} from './model.mjs';
export function blankProject(){return {schema:'soulgen-studio',version:1,name:'Nova criatura',width:96,height:96,rootPivot:[48,42],brief:{species:'',personality:'',kiteAnatomy:'',view:'três quartos',reference:'',notes:''},assets:{},parts:[],clips:Object.fromEntries(Object.entries(clips).map(([id,c])=>[id,{...c,frames:[{t:0,ease:'smooth',values:{root:identity()}},{t:c.seconds,ease:'smooth',values:{root:identity()}}],expressions:[]}]))};}
export async function createCarcara(sizeFor){
 const project=blankProject();project.name='Carcará · rig colorido';project.brief={species:'Carcará',personality:'Orgulhoso e ágil',kiteAnatomy:'Corpo de papel, asas articuladas e rabiola presa ao laço',view:'Três quartos · preservar vista aprovada',reference:'art/soulgen/keys/carcara/source/layers-generated.png',notes:'Derivado do rig aprovado. Preservar cores, detalhes e registro facial.'};
 const sources={original:'/art/soulgen/keys/carcara/source/layers-generated.png',fierce:'/art/soulgen/keys/carcara/color-rig/body-fierce.png',hurt:'/art/soulgen/keys/carcara/color-rig/body-hurt.png',happy:'/art/soulgen/keys/carcara/color-rig/body-happy.png'};
 for(const [id,src]of Object.entries(sources)){const {width,height}=await sizeFor(src);project.assets[id]={src,width,height,name:id};}
 const names={body:'Corpo e expressão',wingFar:'Asa distante',wingNear:'Asa próxima',tail:'Rabiola'};
 for(const [i,id]of ['tail','wingFar','body','wingNear'].entries()){const p=parts[id];project.parts.push({id,name:names[id],asset:'original',source:[...p.source],rect:[...p.rect],pivot:p.pivot?[...p.pivot]:[48,42],z:i,parent:null,visible:true,...{tail:{lag:.1},wingFar:{lag:.04}}[id],...id==='body'?{faces:Object.fromEntries(['fierce','hurt','happy'].map(face=>[face,{asset:face,source:[0,0,280,361]}])),faceWindows:[[14,143,48,57],[90,155,55,64]]}:{}});}
 // Keys taken from the approved rig itself: its one-shot clips are smoothstep timelines (exact with 'smooth'
 // keys), its loops are sines (12 spline keys per cycle stay well inside the edit tolerance).
 const keyTimes={skill:[0,.4,.74,1.1,1.65,2],hurt:[0,.1,.23,.4,.72,1.1],victory:[0,.55,1.05,1.55,2.4]};
 for(const [id,c]of Object.entries(clips)){
  const times=keyTimes[id]||Array.from({length:13},(_,i)=>Math.round(i*c.seconds/12*1e6)/1e6),ease=keyTimes[id]?'smooth':'spline';
  project.clips[id]={...c,frames:times.map(t=>{const p=pose(id,t);return {t,ease,values:{root:{...identity(),x:p.x,y:p.y,rotation:p.lean},wingNear:{...identity(),rotation:p.near},wingFar:{...identity(),rotation:p.far},tail:{...identity(),rotation:p.tail}}};}),expressions:id==='skill'?[{start:.22,end:1.65,face:'fierce'}]:id==='hurt'?[{start:.03,end:.72,face:'hurt'}]:id==='victory'?[{start:.25,end:2.08,face:'happy'}]:[]};
 }
 // Follow-through approved on 2026-10-22: the rabiola trails the body by 0.10 s, the far wing by 0.04 s.
 return project;
}
