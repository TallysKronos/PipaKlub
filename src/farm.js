// Decorative, account-local wandering. Never changes ownership, equipment or rewards.
export function createFarm({random=Math.random}={}){
 const limit=12,bounds={left:65,right:895,top:310,bottom:495};
 let residents=[],page=0;
 const between=(a,b)=>a+(b-a)*Math.max(0,Math.min(.999999,random()));
 function destination(p){p.tx=between(bounds.left,bounds.right);p.ty=between(bounds.top,bounds.bottom);}
 function setCollection(inventory=[]){
  const groups=new Map();
  for(const kite of inventory){if(!kite?.model||!kite.model_id)continue;const id=kite.model_id;
   if(groups.has(id)){groups.get(id).count++;continue;}
   groups.set(id,{id,name:kite.model.name||'Pipamon',color:kite.model.color,soul:kite.model.soul||null,count:1});
  }
  const previous=new Map(residents.map(p=>[p.id,p]));
  residents=[...groups.values()].sort((a,b)=>a.id.localeCompare(b.id)).map(info=>{
   const old=previous.get(info.id);if(old)return Object.assign(old,info);
   const p={...info,x:between(bounds.left,bounds.right),y:between(bounds.top,bounds.bottom),facing:random()<.5?-1:1,speed:between(20,34),wait:between(.2,2.5),moving:false,phase:between(0,6000)};destination(p);return p;
  });
  page=Math.min(page,Math.max(0,Math.ceil(residents.length/limit)-1));return visible();
 }
 function visible(){return residents.slice(page*limit,(page+1)*limit);}
 function step(seconds){
  const dt=Math.max(0,Math.min(Number(seconds)||0,.1));
  for(const p of visible()){
   p.moving=false;if(p.wait>0){p.wait=Math.max(0,p.wait-dt);continue;}
   const dx=p.tx-p.x,dy=p.ty-p.y,d=Math.hypot(dx,dy),travel=p.speed*dt;
   if(d<=Math.max(2,travel)){p.x=p.tx;p.y=p.ty;p.wait=between(1.2,4);destination(p);continue;}
   p.x+=dx/d*travel;p.y+=dy/d*travel;p.moving=dt>0;if(Math.abs(dx)>.2)p.facing=dx<0?-1:1;
  }
  return visible();
 }
 function turn(delta){page=Math.max(0,Math.min(Math.ceil(residents.length/limit)-1,page+delta));page=Math.max(0,page);return visible();}
 return {setCollection,step,visible,turn,get page(){return page;},get pages(){return Math.max(1,Math.ceil(residents.length/limit));},get residents(){return residents;},bounds};
}
