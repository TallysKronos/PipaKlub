import * as BedroomIso from '../tools/iso-studio/model.mjs';
import {BEDROOM_LAYOUT,bedroomProject,bedroomProjectPoint,bedroomUnprojectPoint} from './bedroom-layout.js';
import {HOME_LAYOUT,homeProject} from './home-layout.js';
// Native pixels of the Iso Studio grid. The old park projection is independent.
export function createBedroomIsometricRenderer(scene,images,pack,model,createCanvas=()=>document.createElement('canvas')){
 const home=scene.village==='kael-home',layout=home?HOME_LAYOUT:BEDROOM_LAYOUT,project=home?homeProject:bedroomProject,room=project.room,P=bedroomProjectPoint,pieces=project.pieces,prefix=home?'home-':'bedroom-',size=BedroomIso.roomSize(room);
 const base=P({x:layout.floor.x,y:layout.floor.y});
 const placed=p=>{const q=BedroomIso.placement(room,p);return {x:q.x+base.x-room.origin[0],y:q.y+base.y-room.origin[1],w:q.box.w,h:q.box.h};};
 const ground=createCanvas();ground.width=size.w+64;ground.height=size.h+72;const c=ground.getContext('2d');
 const origin={x:32,y:12},poly=(pts,fill,stroke='#53635a')=>{c.beginPath();pts.forEach(([x,y],i)=>i?c.lineTo(x,y):c.moveTo(x,y));c.closePath();c.fillStyle=fill;c.fill();if(stroke){c.strokeStyle=stroke;c.lineWidth=1;c.stroke();}};
 const Q=(u,v,h=0)=>{const p=BedroomIso.screen(room,u,v,h);return [p.x+origin.x,p.y+origin.y];};
 const [U,V]=room.cells;
 // One shell, with the stair opening removed from the floor itself.
 poly([Q(0,0),Q(U,0),Q(U,V),Q(0,V)],'#d9ab71');
 c.save();c.beginPath();[Q(0,0),Q(U,0),Q(U,V),Q(0,V)].forEach(([x,y],i)=>i?c.lineTo(x,y):c.moveTo(x,y));c.closePath();c.clip();
 for(let v=0;v<=V;v+=.5){c.strokeStyle='#ba8b58';c.beginPath();c.moveTo(...Q(0,v));c.lineTo(...Q(U,v));c.stroke();for(let u=(Math.round(v*2)%2)*.5;u<U;u+=2){c.beginPath();c.moveTo(...Q(u,v));c.lineTo(...Q(u,v+.5));c.stroke();}}
 c.restore();
 poly([Q(0,V),Q(U,V),Q(U,V,-.18),Q(0,V,-.18)],'#9c6c48');poly([Q(U,0),Q(U,V),Q(U,V,-.18),Q(U,0,-.18)],'#79583e');
 poly([Q(0,0),Q(U,0),Q(U,0,5),Q(0,0,5)],'#f5e8c7');poly([Q(0,0),Q(0,V),Q(0,V,5),Q(0,0,5)],'#dfd7b6');
 for(const z of [.12,.24,4.88]){c.strokeStyle=z>4?'#fff2d6':'#ab8357';c.lineWidth=z>4?3:2;c.beginPath();c.moveTo(...Q(0,V,z));c.lineTo(...Q(0,0,z));c.lineTo(...Q(U,0,z));c.stroke();}
 // Render the editable Iso Studio shell directly: shared geometry and flat tones,
 // without the old painted shell's grain competing with the cel-shaded furniture.
 if(home){
  // A handmade kite on the back wall, following its actual isometric plane.
  const k=(u,z)=>Q(8.8+u,0,3.2+z),center=k(0,0),top=k(0,.75),right=k(.55,0),bottom=k(0,-.75),left=k(-.55,0);
  poly([top,right,center],'#e4b35b','#294b53');poly([right,bottom,center],'#347e85','#294b53');poly([bottom,left,center],'#f0d79a','#294b53');poly([left,top,center],'#c86744','#294b53');
  c.strokeStyle='#294b53';c.lineWidth=1;c.beginPath();c.moveTo(...bottom);for(let i=1;i<=8;i++)c.lineTo(...k(Math.sin(i*.8)*.09,-.75-i*.09));c.stroke();
 }
 for(const p of pieces.filter(p=>p.kind==='floor'&&!p.elevation)){
  const r=BedroomIso.footprintRect(p),points=[[r.u0,r.v0],[r.u1,r.v0],[r.u1,r.v1],[r.u0,r.v1]].map(([u,v])=>{const q=Q(u,v);return [q[0]+1,q[1]+3];});poly(points,'#533e2625',null);
 }
 const gx=base.x-room.origin[0]-origin.x,gy=base.y-room.origin[1]-origin.y;
 // Erase this exact footprint: transparent hole, then dark descending steps.
 if(!home){c.save();c.globalCompositeOperation='destination-out';poly([Q(0,6),Q(3,6),Q(3,8),Q(0,8)],'#000',null);c.restore();}
 let hits=[];
 const mapId=home?{porta:'exit',escada:'upstairs',sofa:'seat'}:{mesa:'desk',tv:'tv',quadros:'drawings','abertura-escada':'stairs'};
 const actionFor=id=>home?{hotspot:id,action:id==='seat'?'avatarSeat':id==='mother'?'pilot_story':'street_scene',target:id==='exit'?'quintal':id==='upstairs'?'kael-bedroom':undefined}:{hotspot:id,action:id==='desk'?'pilot_story':id==='stairs'?'street_scene':null,target:id==='stairs'?'kael-home':null};
 const labels=home?{mother:'Mãe',exit:'Saída',seat:'Sentar'}:{tv:'TV',drawings:'Desenhos',desk:'Bancada'};
 const feature=name=>{if(home&&name==='mother'){const [x,y]=layout.blocking.mother,s=P({x,y});return {x:s.x-24,y:s.y-104,w:48,h:104};}const p=pieces.find(p=>mapId[p.id]===name);if(!p)return null;const b=placed(p);return name==='tv'?{x:b.x+7,y:b.y+23,w:33,h:30}:b;};
 const contains=(p,b)=>p.x>=b.x&&p.x<=b.x+b.w&&p.y>=b.y&&p.y<=b.y+b.h;
 function draw(g,actor,entries,{entrances=[],decorations=[]}={}){
  hits=[];g.imageSmoothingEnabled=false;g.drawImage(ground,gx,gy);
  const items=pieces.map(p=>({id:p.id,p,layer:p.kind==='flat'?'flat':p.kind.startsWith('wall')?'wall':null,rect:BedroomIso.footprintRect(p)}));
  for(const e of entries){const u=(e.x-layout.floor.x)/96,v=(e.y-layout.floor.y)/96;items.push({id:'actor',e,rect:{u0:u-.12,u1:u+.12,v0:v-.12,v1:v+.12}});}
  const ordered=BedroomIso.drawOrder(items);
  // A seated/climbing actor is supported by this prop, so it must draw over it.
  for(const item of [...ordered])if(item.e?.avatarPose?.support){const support=ordered.find(q=>q.p?.id===item.e.avatarPose.support);if(support){ordered.splice(ordered.indexOf(item),1);ordered.splice(ordered.indexOf(support)+1,0,item);}}
  const playerIndex=ordered.findIndex(item=>item.e&&(item.e.type==='player'||Math.abs(item.e.x-actor.x)<.01&&Math.abs(item.e.y-actor.y)<.01)),playerPoint=P(actor);
  for(const [drawIndex,item] of ordered.entries()){
   if(item.e){const e=item.e,s=P(e),pose=e.avatarPose;g.save();
    if(pose?.clip==='stairwell'&&!home){const hole=layout.stairwell,left=P({x:hole.x,y:hole.y+hole.h}),right=P({x:hole.x+hole.w,y:hole.y}),front=P({x:hole.x+hole.w,y:hole.y+hole.h});g.beginPath();g.moveTo(left.x,-2048);g.lineTo(right.x,-2048);g.lineTo(right.x,right.y);g.lineTo(front.x,front.y);g.lineTo(left.x,left.y);g.closePath();g.clip();}
    if(pose?.support==='sofa'&&pose.seatAmount>0){g.fillStyle='#102e3d40';g.beginPath();g.ellipse(s.x,s.y-(pose.lift||0)-27,11*pose.seatAmount,3*pose.seatAmount,0,0,Math.PI*2);g.fill();}
    if(!pose?.support){g.fillStyle='#253e4930';g.beginPath();g.ellipse(s.x,s.y,11,4,0,0,Math.PI*2);g.fill();}e.draw(s);g.restore();if(e.action)hits.push({x:s.x-24,y:s.y-95,w:48,h:95,action:e.action});continue;}
   const p=item.p,b=placed(p),im=images[prefix+p.id],occludes=p.kind==='floor'&&playerIndex>=0&&drawIndex>playerIndex&&!ordered[playerIndex].e.avatarPose?.clip&&ordered[playerIndex].e.avatarPose?.support!==p.id&&contains({x:playerPoint.x,y:playerPoint.y-50},b);if(im){g.save();if(occludes)g.globalAlpha=.3;g.drawImage(im,b.x,b.y);g.restore();}
   const hotspot=mapId[p.id];if(hotspot)hits.push({...b,...actionFor(hotspot)});
  }
  // Guardrail is a separate foreground support, on the opening's exposed edge.
  if(!home){g.strokeStyle='#245765';g.lineWidth=2;const rail=(u,v)=>P({x:layout.floor.x+u*96,y:layout.floor.y+v*96});
  const a=rail(3,6.1),b=rail(3,7.95);g.beginPath();g.moveTo(a.x,a.y-24);g.lineTo(b.x,b.y-24);g.stroke();for(const v of [6.1,7,7.95]){const p=rail(3,v);g.beginPath();g.moveTo(p.x,p.y);g.lineTo(p.x,p.y-24);g.stroke();}
  }
  for(const e of entrances){const p=P(home?e:{x:e.x,y:layout.stairwell.y+48});g.save();g.translate(p.x-e.x,p.y-e.y);e.draw();g.restore();}for(const fn of decorations)fn(g);
 }
 function camera(position,width,height){const W=size.w+80,H=size.h+80,scale=Math.min(width/W,height/H);return {x:gx-8-(width/scale-W)/2,y:gy-4-(height/scale-H)/2,scale,isometric:true};}
 function pick(point){for(const [id,label]of Object.entries(labels)){const b=feature(id),w=label.length*10+24;if(b&&contains(point,{x:b.x+b.w/2-w/2,y:b.y-28,w,h:25}))return actionFor(id);}return [...hits].reverse().find(b=>contains(point,b))||null;}
 return {draw,camera,pick,project:P,unproject:bedroomUnprojectPoint,feature,objects:layout.objects,reset(){}};
}
