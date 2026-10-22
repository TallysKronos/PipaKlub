import {identity} from './model.mjs';

// Eremor has its own proportions, joints and weight; no Carcará coordinates are reused.
export async function createEremor(sizeFor){
 const spec=await import('../../art/soulgen/keys/eremor/rig-data.mjs');
 const project=JSON.parse(JSON.stringify(spec.project));
 if(sizeFor)for(const a of Object.values(project.assets)){
  const actual=await sizeFor(a.src);
  if(actual.width!==a.width||actual.height!==a.height)throw Error('Dimensões diferentes na fonte do Eremor: '+a.name);
 }
 return project;
}

export function eremorClips(){
 const key=(t,values,ease='smooth')=>({t,ease,values:Object.fromEntries(Object.entries(values).map(([id,v])=>[id,{...identity(),...v}]))});
 const idleSeconds=3.6,flightSeconds=2.8;
 const loop=(seconds,pose)=>Array.from({length:17},(_,i)=>key(seconds*i/16,pose(i===16?0:i/16*Math.PI*2),'spline'));
 const rest={root:{},body:{},head:{},armNear:{},armFar:{},sails:{},tail:{},knot:{}};
 const clips={
  idle:{label:'Repouso ancestral',seconds:idleSeconds,loop:true,hitTime:null,expressions:[],frames:loop(idleSeconds,a=>({root:{y:-.9*Math.sin(a)},body:{rotation:.45*Math.sin(a)},head:{rotation:-.65*Math.sin(a)},sails:{rotation:1.25*Math.sin(a-.25)},tail:{rotation:2.3*Math.sin(a-.5)}}))},
  flight:{label:'Planagem pesada',seconds:flightSeconds,loop:true,hitTime:null,expressions:[],frames:loop(flightSeconds,a=>({root:{y:-7-2.2*Math.sin(a),rotation:-1.2},head:{rotation:1.2*Math.sin(a)},armNear:{rotation:5+2*Math.sin(a)},armFar:{rotation:-3+1.7*Math.sin(a+.3)},sails:{rotation:1.8*Math.sin(a)},tail:{rotation:4*Math.sin(a-.5)}}))},
  skill:{label:'Golpe de fundação',seconds:2.4,loop:false,hitTime:1.05,expressions:[],frames:[key(0,rest),key(.48,{root:{x:4,y:2,rotation:2},head:{rotation:3},armNear:{rotation:18},sails:{rotation:-3}}),key(.85,{root:{x:5,y:-2,rotation:3},head:{rotation:-3},armNear:{rotation:32},armFar:{rotation:8},tail:{rotation:-5}}),key(1.05,{root:{x:-9,y:3,rotation:-4},head:{rotation:-4},armNear:{rotation:-13},armFar:{rotation:-4},sails:{rotation:4},tail:{rotation:7}}),key(1.25,{root:{x:-7,y:2,rotation:-2},armNear:{rotation:-7},sails:{rotation:-2},tail:{rotation:4}}),key(1.8,{root:{x:-2},armNear:{rotation:-2}}),key(2.4,rest)]},
  hurt:{label:'Dano e recomposição',seconds:1.35,loop:false,hitTime:null,expressions:[],frames:[key(0,rest),key(.14,{root:{x:7,y:2,rotation:3},head:{rotation:7},armNear:{rotation:7},sails:{rotation:-4},tail:{rotation:-5}}),key(.31,{root:{x:5,y:1,rotation:1},head:{rotation:3},sails:{rotation:2}}),key(.65,{root:{x:2},head:{rotation:1},tail:{rotation:2}}),key(1.35,rest)]},
  victory:{label:'Elo reerguido',seconds:3,loop:false,hitTime:null,expressions:[],frames:[key(0,rest),key(.65,{root:{y:-2,rotation:1},head:{rotation:7},armNear:{rotation:8},sails:{rotation:-3},tail:{rotation:5}}),key(1.3,{root:{y:-3},head:{rotation:10},armNear:{rotation:12},armFar:{rotation:3},sails:{rotation:3},tail:{rotation:-3}}),key(2.1,{root:{y:-2},head:{rotation:6},sails:{rotation:-1},tail:{rotation:2}}),key(3,rest)]}
 };
 clips.skill.expressions=[{start:.24,end:1.8,face:'fierce'}];
 clips.hurt.expressions=[{start:.03,end:.9,face:'hurt'}];
 clips.victory.expressions=[{start:.35,end:2.7,face:'happy'}];
 // Settle before the final frame so even delayed appendages finish at rest.
 for(const c of Object.values(clips))if(!c.loop)c.frames.splice(-1,0,key(c.seconds-.16,rest));
 return clips;
}
