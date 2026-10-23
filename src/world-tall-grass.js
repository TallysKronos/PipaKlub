

// Cosmetic only: habitat rectangles and navigation remain owned by the map.
export function createTallGrass(regions,{seed=157,maxParticles=72,project=({x,y})=>({x:(x-y)*.82,y:(x+y)*.41})}={}){
 let state=seed>>>0,previous=null,distance=0;
 const random=()=>((state=(state*1664525+1013904223)>>>0)/4294967296);
 const contains=p=>regions.some(r=>p.x>=r.x&&p.x<r.x+r.w&&p.y>=r.y&&p.y<r.y+r.h);
 const cells=new Map(),seen=new Set(),particles=[];
 for(const r of regions)for(let y=Math.ceil(r.y/22)*22;y<r.y+r.h;y+=22)for(let x=Math.ceil(r.x/22)*22;x<r.x+r.w;x+=22){
  const key=x+','+y;if(seen.has(key))continue;seen.add(key);
  const p={x:x+(random()-.5)*10,y:y+(random()-.5)*10};
  if(contains(p))cells.set(key,{...p,type:'grass',h:29+random()*15,tint:Math.floor(random()*3),phase:random()*6.28,bend:0});
 }
 const tufts=[...cells.values()];
 function reset(){previous=null;distance=0;particles.length=0;for(const b of tufts)b.bend=0;}
 function update(dt,actor,companion=null,{reduced=false}={}){
  dt=Math.max(0,Math.min(dt,.1));
  if(reduced)particles.length=0;
  for(let i=particles.length-1;i>=0;i--){const p=particles[i];p.age+=dt;if(p.age>=p.life){particles.splice(i,1);continue;}p.x+=p.vx*dt;p.y+=p.vy*dt;p.vy+=64*dt;p.rotation+=p.spin*dt;}
  for(const b of tufts){const p=project(b);let target=0;
   for(const a of [actor,companion])if(a){const q=project(a),dx=p.x-q.x,dy=p.y-q.y,d=Math.hypot(dx,dy*1.6);if(d<32){const bend=(dx<0?-1:1)*(1-d/32);if(Math.abs(bend)>Math.abs(target))target=bend;}}
   b.bend=reduced?target:b.bend+(target-b.bend)*(1-Math.exp(-dt*(target?18:5)));
  }
  if(previous){const travel=Math.hypot(actor.x-previous.x,actor.y-previous.y);
   // Sample the walked segment, avoiding bursts on loads/teleports and patch seams.
   if(travel>0&&travel<48&&!reduced){const steps=Math.ceil(travel/4);for(let i=1;i<=steps;i++){
    const p={x:previous.x+(actor.x-previous.x)*i/steps,y:previous.y+(actor.y-previous.y)*i/steps};
    if(!contains(p)){distance=0;continue;}distance+=travel/steps;
    if(distance<13)continue;distance%=13;const q=project(p);
    for(let n=0;n<3&&particles.length<maxParticles;n++)particles.push({x:q.x+(random()-.5)*18,y:q.y-6,age:0,life:.65+random()*.4,vx:(random()-.5)*48,vy:-34-random()*27,rotation:random()*6.28,spin:(random()-.5)*8,size:3+random()*2,tint:Math.floor(random()*3)});
   }}else if(travel>=48)distance=0;
  }
  previous={x:actor.x,y:actor.y};
 }
 return {tufts,particles,contains,update,reset};
}
