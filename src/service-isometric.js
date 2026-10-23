import * as BedroomIso from '../tools/iso-studio/model.mjs';
import {serviceLayout} from './service-interiors.js';
import {bedroomProjectPoint,bedroomUnprojectPoint} from './bedroom-layout.js';

export function createServiceIsometricRenderer(scene,images,pack,model,createCanvas=()=>document.createElement('canvas')){
 const plan=serviceLayout(scene.village),room=plan.room,size=BedroomIso.roomSize(room),P=bedroomProjectPoint,base=P(plan.floor),prefix=plan.prefix;
 const origin={x:base.x-room.origin[0],y:base.y-room.origin[1]},placed=p=>{const q=BedroomIso.placement(room,p);return {x:q.x+origin.x,y:q.y+origin.y,w:q.box.w,h:q.box.h};};
 const contains=(p,b)=>p.x>=b.x&&p.x<=b.x+b.w&&p.y>=b.y&&p.y<=b.y+b.h;
 const action=id=>{const h=plan.hotspots.find(h=>h.id===id);return h?{hotspot:id,action:h.action,target:h.target}:null;};
 let hits=[];
 function draw(g,actor,entries,{entrances=[],decorations=[]}={}){
  hits=[];g.imageSmoothingEnabled=false;const shell=images[prefix+'shell'];if(shell)g.drawImage(shell,origin.x,origin.y);
  const items=plan.pieces.map(p=>({id:p.id,p,rect:BedroomIso.footprintRect(p),layer:p.kind==='flat'?'flat':p.kind.startsWith('wall')?'wall':null}));
  for(const e of entries){const u=(e.x-plan.floor.x)/96,v=(e.y-plan.floor.y)/96;items.push({id:'actor',e,rect:{u0:u-.12,u1:u+.12,v0:v-.12,v1:v+.12}});}
  const ordered=BedroomIso.drawOrder(items),player=ordered.findIndex(i=>i.e&&Math.abs(i.e.x-actor.x)<.01&&Math.abs(i.e.y-actor.y)<.01),point=P(actor);
  for(const [index,item]of ordered.entries()){
   if(item.e){const e=item.e,p=P(e);e.draw(p);if(e.action)hits.push({x:p.x-24,y:p.y-102,w:48,h:102,action:e.action});continue;}
   const p=item.p,b=placed(p),im=images[prefix+p.id];g.save();if(p.kind==='floor'&&index>player&&contains({x:point.x,y:point.y-45},b))g.globalAlpha=.3;if(im)g.drawImage(im,b.x,b.y);g.restore();
   const a=action(p.id);if(a)hits.push({...b,...a});
  }
  for(const e of entrances){const p=P(e);g.save();g.translate(p.x-e.x,p.y-e.y);e.draw();g.restore();}for(const fn of decorations)fn(g);
 }
 function camera(position,width,height){const W=size.w+80,H=size.h+90,scale=Math.min(width/W,height/H);return {x:origin.x-40-(width/scale-W)/2,y:origin.y-35-(height/scale-H)/2,scale,isometric:true};}
 function feature(name){const p=plan.pieces.find(p=>p.id===name);if(p)return placed(p);return null;}
 return {draw,camera,feature,project:P,unproject:bedroomUnprojectPoint,pick:p=>[...hits].reverse().find(b=>contains(p,b))||null,objects:plan.objects,reset(){}};
}
