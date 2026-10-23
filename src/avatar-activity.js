// In-place drawings; only this controller moves the foot through the scene.
export function createAvatarActivity({kind,start,dir,seat,onComplete}){
 const state={kind,elapsed:0,done:false};
 function tick(seconds){if(state.done)return;state.elapsed+=Math.min(.1,Math.max(0,seconds||0))*1000;if(kind==='stairs'&&state.elapsed>=3520){state.done=true;onComplete?.();}}
 function pose(){if(kind==='seat')return {x:seat.x,y:seat.y,lift:seat.lift||0,dir,action:state.elapsed<480?'sentar':'sentado',time:state.elapsed<480?state.elapsed:state.elapsed-480};
  const progress=Math.min(8,state.elapsed/440),step=Math.floor(progress),t=progress-step,ease=t*t*(3-2*t),n=Math.min(8,step+ease),up=dir==='ne'||dir==='nw';
  return {x:start.x,y:start.y+(up?-1:1)*36*n,lift:(up?1:-1)*16*n,dir,action:up?'subir':'descer',time:state.elapsed};}
 return {state,tick,pose};
}
