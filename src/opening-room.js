// Local room interaction only. No account, inventory or reward writes.
export function createOpeningRoom(room){
 const radius=14,rects=room.walkable,blocked=room.blocked||[],speed=360;
 const inside=(x,y)=>rects.some(([rx,ry,w,h])=>x>=rx&&x<=rx+w&&y>=ry&&y<=ry+h);
 const safe=p=>Number.isFinite(p?.x)&&Number.isFinite(p?.y)&&[-radius,0,radius].every(dx=>[-radius,0,radius].every(dy=>inside(p.x+dx,p.y+dy)))&&!blocked.some(([x,y,w,h])=>p.x+radius>x&&p.x-radius<x+w&&p.y+radius>y&&p.y-radius<y+h);
 const distance=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
 function clear(a,b){const steps=Math.ceil(distance(a,b));for(let i=0;i<=steps;i++){const t=steps?i/steps:0;if(!safe({x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t}))return false;}return true;}
 function route(from,to){
  if(!safe(from)||!safe(to))return [];if(clear(from,to))return [{...to}];
  const corners=blocked.flatMap(([x,y,w,h])=>[[x-radius-2,y-radius-2],[x+w+radius+2,y-radius-2],[x-radius-2,y+h+radius+2],[x+w+radius+2,y+h+radius+2]].map(([x,y])=>({x,y})));
  const nodes=[{...from},{...to},...corners,...rects.flatMap(([x,y,w,h])=>[[x+radius+2,y+radius+2],[x+w-radius-2,y+radius+2],[x+radius+2,y+h-radius-2],[x+w-radius-2,y+h-radius-2],[x+w/2,y+h/2]].map(([x,y])=>({x,y})))].filter(safe);
  const costs=nodes.map(()=>Infinity),prev=[],done=new Set();costs[0]=0;
  while(done.size<nodes.length){let at=-1;for(let i=0;i<nodes.length;i++)if(!done.has(i)&&(at<0||costs[i]<costs[at]))at=i;if(at<0||!Number.isFinite(costs[at]))break;if(at===1){const path=[];for(let j=1;j!==0;j=prev[j])path.unshift(nodes[j]);return path;}done.add(at);for(let j=0;j<nodes.length;j++)if(!done.has(j)&&clear(nodes[at],nodes[j])){const cost=costs[at]+distance(nodes[at],nodes[j]);if(cost<costs[j]){costs[j]=cost;prev[j]=at;}}}
  return [];
 }
 function move(actor,dx,dy){
  const d=Math.hypot(dx,dy),n=Math.max(1,Math.ceil(d/4));let changed=false;
  for(let i=0;i<n;i++){const p={x:actor.x+dx/n,y:actor.y+dy/n};if(!safe(p))break;actor.x=p.x;actor.y=p.y;changed=true;}
  if(changed&&d>.01)actor.direction=Math.abs(dx)>Math.abs(dy)?dx>0?2:1:dy>0?0:3;
  return changed;
 }
 function tick(actor,input,dt){
  actor.moving=false;dt=Math.max(0,Math.min(.05,dt));if(!safe(actor))return;
  const magnitude=Math.hypot(input.x||0,input.y||0);
  if(magnitude>.1){actor.path=[];const x=(input.x||0)/Math.max(1,magnitude)*speed*dt,y=(input.y||0)/Math.max(1,magnitude)*speed*dt;actor.moving=move(actor,x,y)||move(actor,x,0)||move(actor,0,y);return;}
  const target=actor.path?.[0];if(!target)return;const d=distance(actor,target);if(d<1){actor.path.shift();return;}const step=Math.min(d,speed*dt);actor.moving=move(actor,(target.x-actor.x)/d*step,(target.y-actor.y)/d*step);if(!actor.moving&&step>0)actor.path=[];
 }
 const hotspots=room.hotspots||[{id:'tv',name:'Televisão',x:540,y:510,hit:[420,130,210,260]},{id:'drawings',name:'Desenhos anteriores',x:860,y:510,hit:[1010,110,360,110]},{id:'desk',name:'Projeto do Rabbito',x:1050,y:510,hit:[960,220,390,230]}];
 const near=(actor,id)=>{const spot=hotspots.find(p=>p.id===id);return !!spot&&distance(actor,spot)<=110;};
 function canvasPoint(rect,width,height,clientX,clientY){const scale=Math.min(rect.width/width,rect.height/height),x=(clientX-rect.left-(rect.width-width*scale)/2)/scale,y=(clientY-rect.top-(rect.height-height*scale)/2)/scale;return x>=0&&x<=width&&y>=0&&y<=height?{x,y}:null;}
 return {safe,clear,route,tick,near,hotspots,canvasPoint};
}
