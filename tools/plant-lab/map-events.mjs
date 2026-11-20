export const EVENT_TYPES=['spawn','exit','npc','encounter','trigger','item'];
export function validateEvents(events,width,height){
 if(!Array.isArray(events)||events.length>500)throw Error('Máximo de 500 eventos.');const seen=new Set();
 return events.map(e=>{if(!e||typeof e.id!=='string'||!/^[a-zA-Z0-9_-]{1,80}$/.test(e.id)||seen.has(e.id)||!EVENT_TYPES.includes(e.type)||!Number.isFinite(e.x)||!Number.isFinite(e.y)||e.x<0||e.y<0||e.x>=width*32||e.y>=height*32)throw Error('Evento inválido ou ID repetido.');seen.add(e.id);const text=k=>String(e[k]??'').slice(0,2000);return {id:e.id,type:e.type,x:Math.round(e.x),y:Math.round(e.y),label:text('label'),text:text('text'),targetMap:text('targetMap'),targetEvent:text('targetEvent'),condition:text('condition'),setsFlag:text('setsFlag'),once:!!e.once,route:Array.isArray(e.route)?e.route.slice(0,100).map(p=>{if(!Number.isFinite(p.x)||!Number.isFinite(p.y)||p.x<0||p.y<0||p.x>=width*32||p.y>=height*32)throw Error('Ponto de rota inválido.');return {x:Math.round(p.x),y:Math.round(p.y)};}):[]};});
}
export function eventAvailable(e,state){return (!e.condition||!!state.flags[e.condition])&&(!e.once||!state.used.includes(e.id));}
export function activateEvent(e,state){if(!eventAvailable(e,state))return {active:false,state};const next={flags:{...state.flags},used:[...state.used],items:[...state.items]};if(e.setsFlag)next.flags[e.setsFlag]=true;if(e.once)next.used.push(e.id);if(e.type==='item')next.items.push(e.label||e.id);return {active:true,state:next,message:e.text||e.label||e.type,targetEvent:e.type==='exit'?e.targetEvent:null,targetMap:e.type==='exit'?e.targetMap:null};}

// Loop a patrol through the explicit waypoints; keep authoring coordinates immutable.
export function eventAtTime(e,seconds){
 if(e.type!=='npc'||!e.route?.length)return e;
 const points=[e,...e.route,e],lengths=points.slice(1).map((p,i)=>Math.hypot(p.x-points[i].x,p.y-points[i].y)),total=lengths.reduce((a,b)=>a+b,0);if(!total)return e;
 let distance=Math.max(0,seconds)*24%total;for(let i=0;i<lengths.length;i++){if(distance<=lengths[i]&&lengths[i]>0){const t=distance/lengths[i];return {...e,x:points[i].x+(points[i+1].x-points[i].x)*t,y:points[i].y+(points[i+1].y-points[i].y)*t};}distance-=lengths[i];}return e;
}
