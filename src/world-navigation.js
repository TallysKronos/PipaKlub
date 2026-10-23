import {createWorldGeometry} from './world-map.js';
// Local presentation only. Walking never changes encounter unlocks or account data.
export function createWorldNavigation(scene){
 const speed=Number.isFinite(scene.walkSpeed)&&scene.walkSpeed>0?scene.walkSpeed:240;
 const geometry=scene.tiled?createWorldGeometry(scene.tiled):null;
 const nodes=scene.nodes.map(([x,y])=>({x,y})),distance=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
 const adjacency=nodes.map(()=>[]);for(const [a,b]of scene.edges){const cost=distance(nodes[a],nodes[b]);adjacency[a].push([b,cost]);adjacency[b].push([a,cost]);}
 function project(p){
  if(!Number.isFinite(p?.x)||!Number.isFinite(p?.y))p=nodes[scene.spawn];
  let best=null;
  for(const [a,b]of scene.edges){const s=nodes[a],e=nodes[b],dx=e.x-s.x,dy=e.y-s.y,t=Math.max(0,Math.min(1,((p.x-s.x)*dx+(p.y-s.y)*dy)/(dx*dx+dy*dy))),point={x:s.x+t*dx,y:s.y+t*dy},d=distance(p,point);if(!best||d<best.distance)best={point,edge:[a,b],distance:d};}
  return best;
 }
 function shortest(start,end){
  const costs=nodes.map(()=>Infinity),previous=[],heap=[];costs[start]=0;
  function push(id,cost){const entry={id,cost};heap.push(entry);let i=heap.length-1;while(i){const p=(i-1)>>1;if(heap[p].cost<=cost)break;heap[i]=heap[p];i=p;}heap[i]=entry;}
  function pop(){const first=heap[0],last=heap.pop();if(heap.length){let i=0;while(i*2+1<heap.length){let c=i*2+1;if(c+1<heap.length&&heap[c+1].cost<heap[c].cost)c++;if(last.cost<=heap[c].cost)break;heap[i]=heap[c];i=c;}heap[i]=last;}return first;}
  push(start,0);while(heap.length){const {id:a,cost}=pop();if(cost!==costs[a])continue;if(a===end)break;for(const [b,weight]of adjacency[a]){const d=cost+weight;if(d<costs[b]){costs[b]=d;previous[b]=a;push(b,d);}}}
  if(!Number.isFinite(costs[end]))return null;
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
 // Direct control walks the authored floor, not just graph edges. Small swept
 // steps prevent tunnelling; independent axes let the actor slide along walls.
 function move(actor,input,seconds){
  let x=Number(input?.x)||0,y=Number(input?.y)||0;const magnitude=Math.hypot(x,y);actor.path=[];actor.moving=false;
  if(magnitude<.08)return false;x/=Math.max(1,magnitude);y/=Math.max(1,magnitude);
  actor.direction=Math.abs(x)>Math.abs(y)?x<0?1:2:y<0?3:0;
  const amount=Math.max(0,Math.min(.1,seconds||0))*speed,steps=Math.max(1,Math.ceil(amount/4));
  const allowed=p=>geometry?geometry.segment(actor,p):p.x>=0&&p.y>=0&&p.x<=scene.width&&p.y<=scene.height;
  for(let i=0;i<steps;i++){const dx=x*amount/steps,dy=y*amount/steps,p={x:actor.x+dx,y:actor.y+dy};let changed=false;
   if(allowed(p)){Object.assign(actor,p);changed=true;}else{const px={x:actor.x+dx,y:actor.y};if(dx&&allowed(px)){Object.assign(actor,px);changed=true;}const py={x:actor.x,y:actor.y+dy};if(dy&&allowed(py)){Object.assign(actor,py);changed=true;}}
   if(changed){actor.level=geometry?.level(actor)??0;actor.moving=true;if(distance(actor,actor.history.at(-1))>=3)actor.history.push({x:actor.x,y:actor.y});}
  }
  if(actor.history.length>400)actor.history.splice(0,actor.history.length-400);return actor.moving;
 }
 function step(actor,seconds){
  let budget=Math.max(0,Math.min(.1,seconds||0))*speed;actor.moving=false;
  while(actor.path.length&&budget>0){const p=actor.path[0],dx=p.x-actor.x,dy=p.y-actor.y,d=Math.hypot(dx,dy);if(d<.01){actor.path.shift();continue;}const move=Math.min(d,budget),next={x:actor.x+dx/d*move,y:actor.y+dy/d*move};if(geometry&&!geometry.segment(actor,next)){actor.path=[];actor.navigationMessage='Caminho bloqueado.';break;}Object.assign(actor,next);actor.level=geometry?.level(actor)??0;actor.direction=Math.abs(dx)>Math.abs(dy)?dx<0?1:2:dy<0?3:0;actor.moving=true;budget-=move;if(distance(actor,actor.history.at(-1))>=3||move===d)actor.history.push({x:actor.x,y:actor.y});if(move===d)actor.path.shift();}
  if(actor.history.length>400)actor.history.splice(0,actor.history.length-400);
 }
 function follower(actor,gap=48){
  const history=[...actor.history,{x:actor.x,y:actor.y}];for(let i=history.length-1;i>0;i--){const a=history[i],b=history[i-1],d=distance(a,b);if(d>=gap&&d>0)return {x:a.x+(b.x-a.x)*gap/d,y:a.y+(b.y-a.y)*gap/d};gap-=d;}return {...history[0]};
 }
 function camera(actor,width,height){const floor=scene.overview&&width>=701?0:width<701?.9:1,scale=Math.max(floor,width/scene.width,height/scene.height),x=Math.max(0,Math.min(scene.width-width/scale,actor.x-width/scale*.5)),y=Math.max(0,Math.min(scene.height-height/scale,actor.y-height/scale*.57));return {x,y,scale};}
 return {nodes,project,route,create,target,move,step,follower,camera,distance,geometry};
}
