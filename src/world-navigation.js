import {createWorldGeometry} from './world-map.js';
// Local presentation only. Walking never changes encounter unlocks or account data.
export function createWorldNavigation(scene){
 const geometry=scene.tiled?createWorldGeometry(scene.tiled):null;
 const nodes=scene.nodes.map(([x,y])=>({x,y})),distance=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
 function project(p){
  if(!Number.isFinite(p?.x)||!Number.isFinite(p?.y))p=nodes[scene.spawn];
  let best=null;
  for(const [a,b]of scene.edges){const s=nodes[a],e=nodes[b],dx=e.x-s.x,dy=e.y-s.y,t=Math.max(0,Math.min(1,((p.x-s.x)*dx+(p.y-s.y)*dy)/(dx*dx+dy*dy))),point={x:s.x+t*dx,y:s.y+t*dy},d=distance(p,point);if(!best||d<best.distance)best={point,edge:[a,b],distance:d};}
  return best;
 }
 function shortest(start,end){
  const costs=nodes.map(()=>Infinity),previous=[],pending=new Set(nodes.map((_,i)=>i));costs[start]=0;
  while(pending.size){const a=[...pending].sort((a,b)=>costs[a]-costs[b])[0];if(!Number.isFinite(costs[a]))return null;pending.delete(a);if(a===end)break;
   for(const [u,v]of scene.edges){const b=u===a?v:v===a?u:null;if(b===null||!pending.has(b))continue;const d=costs[a]+distance(nodes[a],nodes[b]);if(d<costs[b]){costs[b]=d;previous[b]=a;}}
  }
  const path=[end];while(path[0]!==start){const p=previous[path[0]];if(p===undefined)return null;path.unshift(p);}return {cost:costs[end],points:path.map(i=>nodes[i])};
 }
 function route(from,to){
  const a=project(from),b=project(to);if(!a||!b)return [];
  if(a.edge[0]===b.edge[0]&&a.edge[1]===b.edge[1])return [a.point,b.point];
  let best=null;for(const start of a.edge)for(const end of b.edge){const path=shortest(start,end);if(!path)continue;const cost=distance(a.point,nodes[start])+path.cost+distance(nodes[end],b.point);if(!best||cost<best.cost)best={cost,points:[a.point,...path.points,b.point]};}
  return (best?.points||[]).filter((p,i,all)=>!i||distance(p,all[i-1])>.01).map(p=>({...p}));
 }
 function create(){const p=nodes[scene.spawn];return {...p,level:geometry?.level(p)??0,direction:0,path:[],history:[{...p}],moving:false};}
 function target(actor,p,immediate=false){
  actor.navigationMessage='';
  if(geometry&&!geometry.safe(p)){actor.navigationMessage='Área bloqueada. Escolha um caminho livre.';return [];}
  const path=route(actor,p);
  if(geometry&&path.length){if(!geometry.segment(path.at(-1),p)){actor.navigationMessage='Não há caminho até esse destino.';return [];}if(distance(path.at(-1),p)>.01)path.push({x:p.x,y:p.y});}
  if(geometry&&(!path.length||!geometry.segment(actor,path[0]))){actor.navigationMessage='Não há caminho até esse destino.';return [];}
  if(geometry&&path.some((point,i)=>i&&!geometry.segment(path[i-1],point))){actor.navigationMessage='Não há caminho até esse destino.';return [];}
  actor.path=path;actor.moving=false;if(immediate&&path.length){Object.assign(actor,path.at(-1));actor.level=geometry?.level(actor)??0;actor.history=path.map(p=>({...p}));actor.path=[];}return path;
 }
 function step(actor,seconds){
  let budget=Math.max(0,Math.min(.1,seconds||0))*145;actor.moving=false;
  while(actor.path.length&&budget>0){const p=actor.path[0],dx=p.x-actor.x,dy=p.y-actor.y,d=Math.hypot(dx,dy);if(d<.01){actor.path.shift();continue;}const move=Math.min(d,budget),next={x:actor.x+dx/d*move,y:actor.y+dy/d*move};if(geometry&&!geometry.segment(actor,next)){actor.path=[];actor.navigationMessage='Caminho bloqueado.';break;}Object.assign(actor,next);actor.level=geometry?.level(actor)??0;actor.direction=Math.abs(dx)>Math.abs(dy)?dx<0?1:2:dy<0?3:0;actor.moving=true;budget-=move;if(distance(actor,actor.history.at(-1))>=3||move===d)actor.history.push({x:actor.x,y:actor.y});if(move===d)actor.path.shift();}
  if(actor.history.length>400)actor.history.splice(0,actor.history.length-400);
 }
 function follower(actor,gap=48){
  const history=[...actor.history,{x:actor.x,y:actor.y}];for(let i=history.length-1;i>0;i--){const a=history[i],b=history[i-1],d=distance(a,b);if(d>=gap&&d>0)return {x:a.x+(b.x-a.x)*gap/d,y:a.y+(b.y-a.y)*gap/d};gap-=d;}return {...history[0]};
 }
 function camera(actor,width,height){const floor=scene.overview&&width>=701?0:width<701?.9:1,scale=Math.max(floor,width/scene.width,height/scene.height),x=Math.max(0,Math.min(scene.width-width/scale,actor.x-width/scale*.5)),y=Math.max(0,Math.min(scene.height-height/scale,actor.y-height/scale*.57));return {x,y,scale};}
 return {nodes,project,route,create,target,step,follower,camera,distance,geometry};
}
