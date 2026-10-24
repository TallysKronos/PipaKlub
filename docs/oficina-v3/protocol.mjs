import * as model from './model.mjs';
export const PROTOCOL=3;
export function pack(run){return JSON.parse(JSON.stringify(run,(_key,value)=>value instanceof Set?[...value]:value));}
export function unpack(state){const run=structuredClone(state);if(run.stage===2)run.step.covered=new Set(run.step.covered);return run;}
export function newRun(kind,seed,artesao=false){const run=model.createRun(kind,{seed,artesao});run.variantRoll=1;run.clock=0;return run;}
const finite=(n,a,b)=>Number.isFinite(n)&&n>=a&&n<=b;
export function dispatch(run,event){
 if(!Array.isArray(event)||event.length>4||run.outcome)throw Error('Oficina: comando fora da montagem.');
 const [type,a,b,c]=event;
 if(type==='t'){
  if(event.length!==3||!finite(a,.000001,.05)||!finite(b,-1,1))throw Error('Oficina: relógio inválido.');
  run.clock+=a;model.tickCraft(run,a);
  return run.stage===1?model.tickKnot(run,a):run.stage===3?model.tickFlight(run,a,b):run.stage===4?model.tickSoul(run,a):null;
 }
 if(type==='rod'&&event.length===3&&finite(a,0,960)&&finite(b,0,640))return model.placeRod(run,{x:a,y:b},model.wobbleAt(run.kind,run.clock));
 if(type==='knot'&&event.length===2&&Number.isInteger(a)&&a>=0&&a<6)return model.holdKnot(run,a);
 if(type==='knot-up'&&event.length===1)return model.releaseKnot(run);
 if(type==='cut'&&event.length===4&&finite(a,0,960)&&finite(b,0,640)&&finite(c,0,.1))return model.cutAt(run,{x:a,y:b},c);
 if(type==='soul'&&event.length===1)return model.holdSoul(run);
 if(type==='soul-up'&&event.length===1)return model.releaseSoul(run);
 if(type==='restock'&&event.length===1&&run.blocked){model.restock(run);return null;}
 if(type==='cancel'&&event.length===1){if(run.stage===1)run.step.holding=null;if(run.stage===4)run.step.holding=false;return null;}
 throw Error('Oficina: comando inválido.');
}
export function replay(state,events){
 if(!Array.isArray(events)||events.length>6000)throw Error('Oficina: lote de comandos inválido.');
 const run=unpack(state);let seconds=0;
 for(const event of events){dispatch(run,event);if(event[0]==='t')seconds+=event[1];}
 if(seconds>180)throw Error('Oficina: lote de tempo muito longo.');
 return {run,state:pack(run),seconds};
}
