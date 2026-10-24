import {streetObjects} from './street-layout.js';
import {paintStreetGround} from './street-ground.js';
import {toIso,fromIso,depthOrder} from './world-isometric.js';
import {BEDROOM_LAYOUT,bedroomObjects} from './bedroom-layout.js';
import {createBedroomIsometricRenderer} from './bedroom-isometric.js';
import {HOME_LAYOUT} from './home-layout.js';
import {serviceLayout} from './service-interiors.js';
import {createServiceIsometricRenderer} from './service-isometric.js';
// Presentation of the opening village. Physics, actions and saves stay in map coordinates.
export const villageSceneIds=['quintal','kael-home','kael-bedroom','professor-home','kite-shop'];
export function villageObjects(id,{opening=false}={}){
 const o=(asset,x,y,w,action=null,extra={})=>({asset,x,y,w,action,...extra});
 if(id==='quintal')return streetObjects();
 if(id==='kael-bedroom')return bedroomObjects();
 if(id==='kael-home')return HOME_LAYOUT.objects.map(p=>({...p,x:p.anchor[0],y:p.anchor[1]}));
 if(serviceLayout(id))return serviceLayout(id).objects.map(p=>({...p,x:p.anchor[0],y:p.anchor[1]}));
 if(id==='professor-home')return [o('workbench',580,370,260,'professor'),o('books',330,420,165,'dex'),o('books',340,580,150,'school'),o('desk',1232,410,250,'summon'),o('window',900,310,175,null,{lift:180}),o('chest',1000,700,110)];
 return [o('counter',784,340,400,'shop'),o('workbench',1180,420,240,'pilot_story'),o('books',250,470,180),o('wardrobe',1360,760,150),o('window',550,260,175,null,{lift:180})];
}
export function createVillageIsometricRenderer(scene,images,pack,model,createCanvas=()=>document.createElement('canvas')){
 if(['kael-bedroom','kael-home'].includes(scene.village))return createBedroomIsometricRenderer(scene,images,pack,model,createCanvas);
 if(serviceLayout(scene.village))return createServiceIsometricRenderer(scene,images,pack,model,createCanvas);
 const id=scene.village,opening=!!scene.opening,street=id==='quintal',bedroom=id==='kael-bedroom',objects=villageObjects(id,{opening}),{sample,render}=model;
 const P=toIso,contains=(p,b)=>p.x>=b.x&&p.x<=b.x+b.w&&p.y>=b.y&&p.y<=b.y+b.h;
 let hits=[],clock=0;const ground=createCanvas();ground.width=street?4352:2700;ground.height=street?2304:1600;const c=ground.getContext('2d'),offset={x:street?1856:1200,y:170};
 function shape(points,fill,stroke='#8c7957',line=2){c.beginPath();points.forEach(([x,y],i)=>{if(i)c.lineTo(x,y);else c.moveTo(x,y);});c.closePath();c.fillStyle=fill;c.fill();if(stroke){c.strokeStyle=stroke;c.lineWidth=line;c.stroke();}}
 c.translate(offset.x,offset.y);c.transform(.82,.41,-.82,.41,0,0);
 if(street){paintStreetGround(c);
 }else{
  const f=bedroom?BEDROOM_LAYOUT.floor:null,x=f?.x??(opening?350:180),y=f?.y??(opening?330:220),w=f?.w??(opening?1050:1300),h=f?.h??(opening?600:740),wall=bedroom?BEDROOM_LAYOUT.wallHeight:180;
  c.fillStyle='#0b1118';c.fillRect(-600,-600,2800,2300);
  shape([[x,y+h],[x+w,y+h],[x+w,y+h+14],[x,y+h+14]],'#987049');
  shape([[x,y],[x+w,y],[x+w,y+h],[x,y+h]],'#d6a365');
  c.save();c.beginPath();c.rect(x,y,w,h);c.clip();c.strokeStyle='#bc8b53';c.lineWidth=1.4;for(let v=y;v<y+h;v+=42){c.beginPath();c.moveTo(x,v);c.lineTo(x+w,v);c.stroke();for(let u=x+(Math.round(v/42)%2)*100;u<x+w;u+=200){c.beginPath();c.moveTo(u,v);c.lineTo(u,v+42);c.stroke();}}c.restore();
  if(bedroom)paintBedroomFloor();
  // Inverse-projected wall tops keep vertical edges vertical on screen.
  shape([[x,y],[x+w,y],[x+w-wall/.82,y-wall/.82],[x-wall/.82,y-wall/.82]],'#f3e2b5','#776a50',3);
  shape([[x,y],[x,y+h],[x-wall/.82,y+h-wall/.82],[x-wall/.82,y-wall/.82]],'#dfc99a','#776a50',3);
  c.strokeStyle='#af8e5e';c.lineWidth=12;c.beginPath();c.moveTo(x,y+h);c.lineTo(x,y);c.lineTo(x+w,y);c.stroke();
 }
 if(bedroom)paintBedroomWalls();
 function screenPaint(fn){c.save();c.setTransform(1,0,0,1,offset.x,offset.y);fn(c);c.restore();}
 function paintBedroomFloor(){
  const r=BEDROOM_LAYOUT.rug;
  c.fillStyle='#356d72';c.fillRect(r.x,r.y,r.w,r.h);c.strokeStyle='#edce8c';c.lineWidth=9;c.strokeRect(r.x+13,r.y+13,r.w-26,r.h-26);
  c.strokeStyle='#83a6a0';c.lineWidth=2;c.strokeRect(r.x+25,r.y+25,r.w-50,r.h-50);
  for(const u of [r.x+110,r.x+r.w-110]){c.fillStyle='#d7ba7c';c.beginPath();c.moveTo(u,r.y+r.h/2-23);c.lineTo(u+23,r.y+r.h/2);c.lineTo(u,r.y+r.h/2+23);c.lineTo(u-23,r.y+r.h/2);c.closePath();c.fill();}
  // Shadows sit on the same physical support rectangles as furniture collision.
  c.fillStyle='#4b382322';for(const o of BEDROOM_LAYOUT.objects){c.beginPath();c.roundRect(...o.footprint,12);c.fill();}
  const s=BEDROOM_LAYOUT.stairwell;
  c.fillStyle='#263d40';c.fillRect(s.x,s.y,s.w,s.h);c.strokeStyle='#9c724a';c.lineWidth=10;c.strokeRect(s.x,s.y,s.w,s.h);
  screenPaint(g=>{
   const project=(x,y,z=0)=>{const p=P({x,y});return {x:p.x,y:p.y-z};},poly=(points,fill)=>{g.beginPath();points.forEach((p,i)=>i?g.lineTo(p.x,p.y):g.moveTo(p.x,p.y));g.closePath();if(fill){g.fillStyle=fill;g.fill();}};
   g.save();poly([project(s.x,s.y),project(s.x+s.w,s.y),project(s.x+s.w,s.y+s.h),project(s.x,s.y+s.h)]);g.clip();
   poly([project(s.x,s.y),project(s.x,s.y+s.h),project(s.x,s.y+s.h,-100),project(s.x,s.y,-100)],'#17373c');
   poly([project(s.x+s.w,s.y),project(s.x+s.w,s.y+s.h),project(s.x+s.w,s.y+s.h,-100),project(s.x+s.w,s.y,-100)],'#52665b');
   for(let i=6;i>=0;i--){const y=s.y+12+i*23,z=-i*12;poly([project(s.x+13,y,z),project(s.x+s.w-13,y,z),project(s.x+s.w-13,y+18,z),project(s.x+13,y+18,z)],['#bc8c56','#ad7d48','#9d703f','#8b6138','#795331','#67472b','#563d26'][i]);poly([project(s.x+13,y+18,z),project(s.x+s.w-13,y+18,z),project(s.x+s.w-13,y+18,z-10),project(s.x+13,y+18,z-10)],'#654b32');}
   g.restore();
   for(const x of [s.x,s.x+s.w]){
    g.strokeStyle='#173f46';g.lineWidth=5;
    for(let i=0;i<4;i++){const p=P({x,y:s.y+i*s.h/3});g.beginPath();g.moveTo(p.x,p.y);g.lineTo(p.x,p.y-52);g.stroke();}
    const a=P({x,y:s.y}),b=P({x,y:s.y+s.h});g.strokeStyle='#347681';g.lineWidth=8;g.beginPath();g.moveTo(a.x,a.y-54);g.lineTo(b.x,b.y-54);g.stroke();
   }
  });
 }
 function wallGeometry(name){
  const a=BEDROOM_LAYOUT.wallArt[name],f=BEDROOM_LAYOUT.floor;
  const left=a.wall==='left',start=left?{x:f.x,y:a.start+a.length}:{x:a.start,y:f.y},p=P(start),dx=a.length*.82,dy=a.length*.41*(left?-1:1);
  return {a,p,dx,dy,points:[{x:p.x,y:p.y-a.bottom-a.height},{x:p.x+dx,y:p.y+dy-a.bottom-a.height},{x:p.x+dx,y:p.y+dy-a.bottom},{x:p.x,y:p.y-a.bottom}]};
 }
 function wallBox(name){const points=wallGeometry(name).points,x=Math.min(...points.map(p=>p.x)),y=Math.min(...points.map(p=>p.y));return {x,y,w:Math.max(...points.map(p=>p.x))-x,h:Math.max(...points.map(p=>p.y))-y};}
 function stairBox(){const s=BEDROOM_LAYOUT.stairwell,points=[[s.x,s.y],[s.x+s.w,s.y],[s.x+s.w,s.y+s.h],[s.x,s.y+s.h]].map(([x,y])=>P({x,y})),x=Math.min(...points.map(p=>p.x)),y=Math.min(...points.map(p=>p.y))-56;return {x,y,w:Math.max(...points.map(p=>p.x))-x,h:Math.max(...points.map(p=>p.y))-y};}
 function paintBedroomWalls(){screenPaint(g=>{
  const w=wallGeometry('window'),im=images.window;
  if(im){g.save();g.transform(w.dx/im.width,w.dy/im.width,0,w.a.height/im.height,w.p.x,w.p.y-w.a.bottom-w.a.height);g.drawImage(im,0,0);g.restore();}
  const d=wallGeometry('drawings');g.save();g.transform(d.dx/190,d.dy/190,0,1,d.p.x,d.p.y-d.a.bottom-d.a.height);
  for(let i=0;i<3;i++){const x=4+i*62;g.fillStyle='#fdf0cb';g.strokeStyle='#a78d62';g.lineWidth=1.5;g.fillRect(x,6,56,86);g.strokeRect(x,6,56,86);g.fillStyle='#d5b784';g.fillRect(x+20,2,15,8);g.strokeStyle=i===1?'#397d84':'#a27b52';g.beginPath();g.moveTo(x+28,25);g.lineTo(x+44,47);g.lineTo(x+28,67);g.lineTo(x+12,47);g.closePath();g.moveTo(x+28,25);g.lineTo(x+28,67);g.moveTo(x+12,47);g.lineTo(x+44,47);g.moveTo(x+28,67);g.quadraticCurveTo(x+44,76,x+26,85);g.stroke();}
  g.restore();
 });}
 function descriptor(o){const key=o.asset.startsWith('park:')?o.asset.slice(5):o.asset,a=pack.images[key]||{},im=images[key],rig=pack.rigs?.[key];return {key,a,im,rig};}
 function box(o){if(o.asset==='stairwell')return stairBox();const p=P(o),{a,im,rig}=descriptor(o),h=rig?rig.height*o.w/rig.width:o.asset==='sketches'?o.w*.72:o.w*(im?.height||a.height)/(im?.width||a.width),pivot=o.pivot||a.pivot||[.5,.98];return {x:p.x-o.w*pivot[0],y:p.y-h*pivot[1]-(o.lift||0),w:o.w,h};}
 function drawObject(g,o,actor){const {key,im,rig}=descriptor(o),p=P(o),b=box(o);g.save();
  if(actor&&p.y>P(actor).y&&contains({x:P(actor).x,y:P(actor).y-25},{x:b.x-8,y:b.y,w:b.w+16,h:b.h+20}))g.globalAlpha=.3;
  if(o.action||o.hotspot)hits.push({...b,action:o.action,target:o.target,hotspot:o.hotspot,depth:p.y});
  if(street&&!['bunting','kite'].includes(key)){g.fillStyle='#34533925';g.beginPath();g.ellipse(p.x+5,p.y-1,o.w*.27,o.w*.065,0,0,Math.PI*2);g.fill();}
  if(rig){const k=o.w/rig.width,pose=sample(rig,'idle',clock);
   if(street&&key==='kite'){const joint=model.point(model.matrices(rig,pose).kite,...rig.rootPivot),x=p.x+(joint.x-rig.rootPivot[0])*k,y=p.y-(o.lift||0)+(joint.y-rig.rootPivot[1])*k;g.strokeStyle='#fff3cf';g.lineWidth=1.2;g.beginPath();g.moveTo(p.x,p.y-28);g.quadraticCurveTo(x-34,y+100,x,y);g.stroke();}
   render(g,rig,images,pose,{clear:false,scale:k,offsetX:p.x-g.canvas.width/2+(rig.width/2-rig.rootPivot[0])*k,offsetY:p.y-g.canvas.height/2+(rig.height/2-rig.rootPivot[1])*k-(o.lift||0)});}
  else if(im)g.drawImage(im,b.x,b.y,b.w,b.h);
  else if(o.asset==='sketches'){
   g.translate(b.x,b.y);g.scale(b.w/155,b.h/112);
   for(let i=0;i<3;i++){g.save();g.translate(i*43,8+i*8);g.rotate((i-1)*.06);g.fillStyle='#fff4cf';g.strokeStyle='#a28b62';g.lineWidth=1.5;g.fillRect(0,0,65,83);g.strokeRect(0,0,65,83);g.fillStyle='#e7c69b';g.fillRect(24,-3,17,8);g.strokeStyle=i===1?'#397c83':'#918566';g.beginPath();g.moveTo(32,18);g.lineTo(49,40);g.lineTo(32,61);g.lineTo(15,40);g.closePath();g.moveTo(32,18);g.lineTo(32,61);g.moveTo(15,40);g.lineTo(49,40);g.moveTo(32,61);g.quadraticCurveTo(50,68,33,76);g.stroke();g.restore();}
  }
  g.restore();
 }
 function feature(name){if(bedroom&&['drawings','window'].includes(name))return wallBox(name==='window'?'window':'drawings');const o=objects.find(o=>o.hotspot===name||o.asset===name);if(!o)return null;const b=box(o);return name==='tv'?{x:b.x+b.w*.27,y:b.y+b.h*.13,w:b.w*.35,h:b.h*.30}:b;}
 function camera(position,width,height){
  if(street){const scale=Math.max(.52,Math.min(.95,width/1280)),p=P(position||{x:480,y:768});return {x:p.x-width/(2*scale),y:p.y-height/(2*scale)-45,scale,isometric:true};}
  const points=(bedroom?[[384,288],[1248,288],[1248,928],[384,928]]:opening?[[350,330],[1400,330],[1400,930],[350,930]]:[[180,220],[1480,220],[1480,960],[180,960]]).map(([x,y])=>P({x,y})),left=Math.min(...points.map(p=>p.x))-75,right=Math.max(...points.map(p=>p.x))+75,top=Math.min(...points.map(p=>p.y))-(bedroom?250:230),bottom=Math.max(...points.map(p=>p.y))+50,scale=Math.min(width/(right-left),height/(bottom-top));
  return {x:(left+right)/2-width/(2*scale),y:(top+bottom)/2-height/(2*scale),scale,isometric:true};
 }
 function draw(g,actor,entries,{dt=0,animate=true,entrances=[],decorations=[]}={}){
  if(animate)clock+=Math.min(dt,.1);hits=[];if(bedroom)hits.push({...wallBox('drawings'),hotspot:'drawings',depth:0});g.drawImage(ground,-offset.x,-offset.y);
  for(const o of depthOrder([...objects,...entries]))if(o.draw){const p=P(o);o.draw(p);if(o.action)hits.push({x:p.x-28,y:p.y-80,w:56,h:80,action:o.action,depth:p.y});}else drawObject(g,o,actor);
  for(const e of entrances){const p=P(e);g.save();g.translate(p.x-e.x,p.y-e.y);e.draw();g.restore();}
  for(const draw of decorations)draw(g);
 }
 function pick(p){
  if(bedroom)for(const [id,label]of Object.entries({tv:'TV',drawings:'Desenhos',desk:'Bancada'})){const b=feature(id),w=label.length*10+24;if(b&&contains(p,{x:b.x+b.w/2-w/2,y:b.y-28,w,h:25}))return {hotspot:id,action:id==='desk'?'pilot_story':null};}
  return hits.filter(b=>contains(p,b)).sort((a,b)=>b.depth-a.depth)[0]||null;
 }
 return {draw,camera,pick,project:P,unproject:fromIso,feature,objects,reset(){}};
}
