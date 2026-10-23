// Contacts measured on the Iso Studio grid: 96 logical units = 64×32 native pixels.
export const AVATAR_HOME_CONTACTS={
 seat:{x:526,y:788,lift:10,approach:{x:656,y:912}},
 stairs:{up:{entry:{x:1440,y:1056},end:{x:1440,y:768},rise:128,support:'escada',dir:'ne'},down:{entry:{x:528,y:864},end:{x:528,y:1008},rise:-128,support:'abertura-escada',dir:'sw'}}
};
// Safe landing outside the stair opening/footprints, shared by preview and game.
export function homeStairLanding(sceneId){return sceneId==='kael-home'?{x:1424,y:1104,avatarDir:'sw'}:sceneId==='kael-bedroom'?{x:600,y:824,avatarDir:'se'}:null;}
export function createHomeStairActivity(sceneId,start,onComplete){const up=sceneId==='kael-home';return createAvatarActivity({kind:'stairs',start,dir:up?'ne':'sw',stairs:AVATAR_HOME_CONTACTS.stairs[up?'up':'down'],onComplete});}
export function createHomeSeatActivity(start,onComplete){return createAvatarActivity({kind:'seat',start,dir:'se',seat:AVATAR_HOME_CONTACTS.seat,onComplete});}
// Distance, rather than wall-clock time, drives footfalls (including click routes).
export function advanceAvatarWalk(actor,dx,dy,stride=160){const distance=Math.hypot(dx,dy);if(distance>.001)actor.avatarWalkTime=(actor.avatarWalkTime||0)+distance/stride*800;return actor.avatarWalkTime||0;}
export function createAvatarActivity({kind,start,dir,seat,stairs,onComplete}){
 const origin={x:start.x,y:start.y},state={kind,elapsed:0,done:false,phase:'approach',leaving:false},approachMs=280,sitMs=480,stairMs=3520;
 const clamp=v=>Math.max(0,Math.min(1,v)),ease=v=>{v=clamp(v);return v*v*(3-2*v);},mix=(a,b,t)=>({x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t});
 const up=dir==='ne'||dir==='nw',path=stairs||AVATAR_HOME_CONTACTS.stairs[up?'up':'down'],landing=seat?.approach||origin;
 let departure=null,departureAt=0,riseMs=sitMs,after=null;
 function pose(){
  if(kind==='seat'){
   if(state.leaving){const t=clamp((state.elapsed-departureAt)/riseMs),q=mix(departure,landing,ease(t));return {...q,lift:departure.lift*(1-ease(t)),dir,action:'sentar',time:departure.seatAmount*sitMs*(1-t),support:'sofa',seatAmount:departure.seatAmount*(1-t)};}
   if(state.elapsed<approachMs){const q=mix(origin,landing,ease(state.elapsed/approachMs));return {...q,lift:0,dir,action:Math.hypot(origin.x-landing.x,origin.y-landing.y)>3?'andar':'parado',time:state.elapsed,seatAmount:0};}
   const t=clamp((state.elapsed-approachMs)/sitMs),q=mix(landing,seat,ease(t));return {...q,lift:(seat.lift||0)*ease(t),dir,action:t<1?'sentar':'sentado',time:t<1?t*sitMs:state.elapsed-approachMs-sitMs,support:'sofa',seatAmount:t};
  }
  if(state.elapsed<approachMs)return {...mix(origin,path.entry,ease(state.elapsed/approachMs)),lift:0,dir,action:'andar',time:state.elapsed};
  const t=clamp((state.elapsed-approachMs)/stairMs),steps=t*8,n=Math.floor(steps)+ease(steps%1),q=mix(path.entry,path.end,n/8);
  return {...q,lift:path.rise*n/8,dir,action:up?'subir':'descer',time:state.elapsed-approachMs,support:path.support,clip:up?null:'stairwell',progress:t};
 }
 function leave(next){if(kind!=='seat'||state.done)return false;if(next)after=next;if(state.leaving)return true;departure=pose();departureAt=state.elapsed;riseMs=Math.max(180,sitMs*departure.seatAmount);state.leaving=true;state.phase='rising';return true;}
 function tick(seconds){
  if(state.done)return;state.elapsed+=Math.min(.1,Math.max(0,seconds||0))*1000;
  if(kind==='seat'){if(state.leaving&&state.elapsed-departureAt>=riseMs){state.done=true;onComplete?.({...landing});after?.();}else if(!state.leaving)state.phase=state.elapsed<approachMs?'approach':state.elapsed<approachMs+sitMs?'lowering':'seated';}
  else if(state.elapsed>=approachMs+stairMs){state.done=true;onComplete?.();}
 }
 return {state,tick,pose,leave};
}
