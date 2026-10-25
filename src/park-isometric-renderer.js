import {createVeredasRegionRenderer} from './veredas-region-renderer.js';
import {toIso,fromIso,depthOrder} from './world-isometric.js';
import {worldTerrainContours} from './world-art.js';
import {parkFixtures,parkFenceRuns} from './park-isometric-layout.js';
import {createTallGrass} from './world-tall-grass.js';
import {drawTallGrass,drawTallGrassParticles} from './world-tall-grass-renderer.js';
// The approved park illustration, rendered over the canonical orthogonal physics.
export function createParkIsometricRenderer(scene,images,pack,model,createCanvas=()=>document.createElement('canvas')){
 if(scene.tiled.properties.veredas_region)return createVeredasRegionRenderer(scene,images,pack,model,createCanvas);
 const {sample,render,matrices,point}=model,rigs=pack.rigs;
 let g,actor,ground,board,props,grass,wind=0,paused=false,hitAreas=[];
 const hitsBox=(p,b)=>p.x>=b.x&&p.x<=b.x+b.w&&p.y>=b.y&&p.y<=b.y+b.h;
 const propOccludesActor=(b,p,d)=>d>p.y&&hitsBox({x:p.x,y:p.y-30},{x:b.x-8,y:b.y,w:b.w+16,h:b.h+20});
 function plane(ctx){ctx.transform(.82,.41,-.82,.41,0,0);}
function groundPaint(){
 ground=createCanvas();ground.width=2300;ground.height=1250;const c=ground.getContext('2d');
 c.translate(930,20);plane(c);c.fillStyle='#7ba45b';c.fillRect(-400,-400,2400,1900);
 c.fillStyle='#a8c66e';c.strokeStyle='#658b4e';c.lineWidth=4;c.beginPath();c.roundRect(80,192,1376,752,48);c.fill();c.stroke();
 // Soft grouped vegetation, not checkerboard tile stamps. Seeded, stable across frames.
 let seed=157;const rand=()=>{seed=(seed*1664525+1013904223)>>>0;return seed/4294967296;};
 for(let i=0;i<170;i++){const x=100+rand()*1336,y=210+rand()*710;c.fillStyle=i%3?'#96b65f':'#b7cf7d';c.beginPath();c.moveTo(x-5,y);c.lineTo(x-8,y-7);c.lineTo(x,y-3);c.lineTo(x+3,y-12);c.lineTo(x+5,y-2);c.lineTo(x+10,y-6);c.lineTo(x+8,y+2);c.closePath();c.fill();}
 function path(contours,radius){c.beginPath();for(const points of contours){for(let i=0;i<points.length;i++){const p=points[i],a=points[(i+points.length-1)%points.length],b=points[(i+1)%points.length],la=Math.hypot(p.x-a.x,p.y-a.y),lb=Math.hypot(p.x-b.x,p.y-b.y),r=Math.min(radius,la/2,lb/2),x=p.x+(a.x-p.x)*r/la,y=p.y+(a.y-p.y)*r/la;if(!i)c.moveTo(x,y);else c.lineTo(x,y);c.quadraticCurveTo(p.x,p.y,p.x+(b.x-p.x)*r/lb,p.y+(b.y-p.y)*r/lb);}c.closePath();}}
 const walk=scene.tiled.layers.Walkable;
 for(const [material,color,edge]of [['dirt','#e4bd77','#bd9a60'],['sidewalk','#eee0b7','#b9ad87']]){
  const rects=walk.filter(r=>r.properties.ground_frame===material);if(!rects.length)continue;
  path(worldTerrainContours(rects),38);c.fillStyle=color;c.fill();c.strokeStyle=edge;c.lineWidth=3;c.stroke();c.save();c.clip();
  if(material==='sidewalk'){c.strokeStyle='#d4c6a1';c.lineWidth=1.5;for(let x=0;x<1600;x+=48){c.beginPath();c.moveTo(x,0);c.lineTo(x,1100);c.stroke();}for(let y=0;y<1100;y+=48){c.beginPath();c.moveTo(0,y);c.lineTo(1600,y);c.stroke();}}
  else for(let i=0;i<220;i++){c.fillStyle='#d6ac68';c.fillRect(rand()*1536,rand()*1024,3,2);}
  c.restore();
 }
 // Habitat contours follow the authored search patches, including redesigned routes.
 const habitats=walk.filter(r=>r.properties.encounter_zone);path(worldTerrainContours(habitats),28);c.fillStyle='#6e984e';c.fill();c.save();c.clip();
 c.restore();
 grass=createTallGrass(habitats);
}
function buildProps(){
 const layout=scene.art.objects.filter(o=>o.kind==='solid'||!o.rect),seen=new Set(),out=[];
 for(const o of layout){const s=o.sprite;if(!s)continue;const b=o.rect?{x:o.rect.x+o.rect.w/2,y:o.rect.y+o.rect.h}:{x:s.x+s.w/2,y:o.y};const key=Math.round(b.x)+','+Math.round(b.y);if(seen.has(key))continue;seen.add(key);
  const frame=s.frame;if(frame==='flowerpot')continue;let type=frame.includes('tree')?'tree':frame==='park-gazebo'?'coreto':frame==='bench'?'bench':frame==='lamp'?'windsock':frame.includes('shrub')?'shrub':frame.includes('flower')?'flowers':null;
  if(!type)continue;if(type==='bench'&&Math.abs(b.x-408)<2){b.x=420;b.y=690;}
  out.push({...b,type,action:type==='sign'?'map':type==='coreto'?'assis':type==='bench'?(b.x<800?'rest':'rest-east'):null,rig:frame==='park-tree'?'treeLandmark':type,w:type==='tree'?Math.max(205,s.w):type==='coreto'?260:type==='bench'?126:type==='windsock'?215:Math.min(95,s.w),level:o.level||0});
 }
 if(!scene.tiled.properties.boss_maze){
  for(const p of parkFixtures)out.push({...p,action:p.type==='sign'?'map':null,level:0});
  out.push({x:1220,y:626,type:'kite',rig:'kite',w:130,lift:325,level:0});
 }else{
  // Dense illustrated hedge runs: same footprint as the blocking rectangles.
  for(const r of scene.tiled.layers.Solids.filter(r=>r.name.startsWith('maze-hedge'))){const n=Math.ceil(r.w/64),m=Math.ceil(r.h/52);for(let i=0;i<n;i++)for(let j=0;j<m;j++)out.push({x:r.x+(i+.5)*r.w/n,y:r.y+(j+1)*r.h/m,type:'shrub',w:88,level:0});}
  out.push({x:336,y:812,type:'sign',action:'map',w:100,level:0},{x:1120,y:260,type:'windsock',rig:'windsock',w:180,level:0},{x:1104,y:320,type:'bench',action:'rest',w:126,level:0});
  for(const [a,b]of [[{x:496,y:730},{x:1080,y:730}],[{x:1100,y:228},{x:1392,y:228}]])out.push({type:'pipe',a,b,x:(a.x+b.x)/2,y:(a.y+b.y)/2,w:100,level:0});
  out.push({x:312,y:680,type:'kite',rig:'kite',w:62,lift:20,action:'veredasTrace',level:0});
  for(const [a,b]of [[{x:712,y:480},{x:760,y:480}],[{x:1072,y:368},{x:1072,y:416}]])out.push({type:'pipe',a,b,x:(a.x+b.x)/2,y:(a.y+b.y)/2,w:100,level:0});
 }
 // Planting beds follow the border and group around existing trees, leaving paths clear.
 for(let x=140;x<1440;x+=150)out.push({x,y:190,type:'shrub',w:94,level:0});
 for(let x=360;x<1390;x+=170)out.push({x,y:954,type:'shrub',w:90,level:0});
 for(let y=340;y<920;y+=155){out.push({x:62,y,type:'shrub',w:84,level:0},{x:1470,y,type:'shrub',w:88,level:0});}
 // Beyond the fence, overlapping groves frame the playable clearing.
 for(let x=-40;x<1600;x+=165)out.push({x,y:95,type:'tree',rig:'tree',w:255+(x%3)*8,scenery:true,level:0});
 for(let y=230;y<1090;y+=165)out.push({x:-64,y,type:'tree',rig:'tree',w:250,scenery:true,level:0},{x:1592,y:y-70,type:'tree',rig:'tree',w:265,scenery:true,level:0});
 for(let x=420;x<1560;x+=170)out.push({x,y:1080,type:'tree',rig:'tree',w:250,scenery:true,level:0});
 for(const [i,run]of parkFenceRuns.entries()){const [a,b]=run,n=Math.ceil(Math.hypot(b[0]-a[0],b[1]-a[1])/112);for(let j=0;j<n;j++){const t=j/n,u=(j+1)/n;out.push({type:'fence',x:(a[0]+(b[0]-a[0])*(t+u)/2),y:(a[1]+(b[1]-a[1])*(t+u)/2),a:{x:a[0]+(b[0]-a[0])*t,y:a[1]+(b[1]-a[1])*t},b:{x:a[0]+(b[0]-a[0])*u,y:a[1]+(b[1]-a[1])*u},last:j===n-1,w:100,level:0});}}
 return out;
}
function drawFence(o){
 const a=toIso(o.a),b=toIso(o.b);g.lineJoin='round';
 for(const h of [14,32]){g.beginPath();g.moveTo(a.x,a.y-h);g.lineTo(b.x,b.y-h);g.lineTo(b.x,b.y-h+7);g.lineTo(a.x,a.y-h+7);g.closePath();g.fillStyle='#bd854b';g.strokeStyle='#664d33';g.lineWidth=2;g.fill();g.stroke();g.strokeStyle='#e6b568';g.lineWidth=1;g.beginPath();g.moveTo(a.x,a.y-h+1);g.lineTo(b.x,b.y-h+1);g.stroke();}
 for(const p of o.last?[a,b]:[a]){g.fillStyle='#9b663e';g.strokeStyle='#584a34';g.lineWidth=2;g.beginPath();g.roundRect(p.x-5,p.y-44,10,45,2);g.fill();g.stroke();g.fillStyle='#dba35c';g.fillRect(p.x-6,p.y-46,12,5);g.fillStyle='#24605c';g.fillRect(p.x-5,p.y-4,10,5);}
}
function shadow(p,w){g.fillStyle='#244b3c2b';g.beginPath();g.ellipse(p.x+10,p.y-1,w*.32,w*.085,-.12,0,Math.PI*2);g.fill();}
function buildBoard(){
 board=createCanvas();board.width=146;board.height=94;const c=board.getContext('2d');c.fillStyle='#97b96b';c.fillRect(0,0,146,94);c.scale(146/1536,94/1024);
 for(const r of scene.tiled.layers.Walkable.filter(r=>['dirt','sidewalk'].includes(r.properties.ground_frame))){c.fillStyle=r.properties.ground_frame==='dirt'?'#f6dca2':'#f7edcf';c.fillRect(r.x,r.y,r.w,r.h);}
 for(const o of props.filter(o=>o.type==='tree'&&!o.scenery)){c.fillStyle='#326b52';c.beginPath();c.ellipse(o.x,o.y,39,42,0,0,Math.PI*2);c.fill();}
 if(scene.tiled.properties.boss_maze){for(const r of scene.tiled.layers.Solids){c.fillStyle='#326b52';c.fillRect(r.x,r.y,r.w,r.h);}c.fillStyle='#c86a37';c.beginPath();c.arc(1264,288,48,0,Math.PI*2);c.fill();}
 else{c.fillStyle='#df8759';c.beginPath();c.moveTo(414,423);c.lineTo(490,488);c.lineTo(414,553);c.lineTo(338,488);c.closePath();c.fill();}
 c.fillStyle='#205e62';c.beginPath();c.arc(224,816,25,0,Math.PI*2);c.fill();
}
function propBox(o){const p=toIso(o),rig=rigs[o.rig||o.type],im=images[o.type];if(rig){const k=o.w/rig.width;return {x:p.x-rig.rootPivot[0]*k,y:p.y-rig.rootPivot[1]*k-(o.lift||0),w:o.w,h:rig.height*k};}return {x:p.x-o.w/2,y:p.y-o.w*im.height/im.width,w:o.w,h:o.w*im.height/im.width};}
function coretoCutaway(o){if(o.type!=='coreto')return false;const b=propBox(o);return hitsBox(toIso(actor),{x:b.x+10,y:b.y+o.w*.48,w:b.w-20,h:b.h-o.w*.48+15});}
function drawProp(o){
 if(o.type==='fence'){g.save();drawFence(o);g.restore();return;}
 if(o.type==='pipe'){const a=toIso(o.a),b=toIso(o.b);g.save();g.lineCap='round';g.lineWidth=14;g.strokeStyle='#35534d';g.beginPath();g.moveTo(a.x,a.y-16);g.lineTo(b.x,b.y-16);g.stroke();g.lineWidth=10;g.strokeStyle='#e9dcb4';g.stroke();g.lineWidth=3;g.strokeStyle='#fff0ca';g.beginPath();g.moveTo(a.x,a.y-19);g.lineTo(b.x,b.y-19);g.stroke();const n=Math.ceil(Math.hypot(b.x-a.x,b.y-a.y)/90);for(let i=0;i<=n;i++){const t=i/n,x=a.x+(b.x-a.x)*t,y=a.y+(b.y-a.y)*t-16;g.strokeStyle='#c4773e';g.lineWidth=3;g.beginPath();g.moveTo(x-2,y-7);g.lineTo(x+2,y+7);g.stroke();}g.restore();return;}
 const p=toIso(o),rig=rigs[o.rig||o.type];g.save();
 const player=toIso(actor),box=propBox(o);
 if(o.type!=='coreto'&&propOccludesActor(box,player,p.y))g.globalAlpha=.3;
 if(o.action)hitAreas.push({...box,id:o.action,depth:p.y});
 if(!['bunting','kite'].includes(o.type))shadow(p,o.w);
 if(rig){const k=o.w/rig.width,pose=sample(rig,'idle',wind);
  if(o.type==='tree'){const v=(Math.abs(Math.round(o.x*7+o.y))%3)-1;pose.values.canopy.scaleX*=1+v*.035;pose.values.canopy.rotation+=v*.65;}
  if(o.type==='kite'){const joint=point(matrices(rig,pose).kite,...rig.rootPivot),x=p.x+(joint.x-rig.rootPivot[0])*k,y=p.y-o.lift+(joint.y-rig.rootPivot[1])*k;g.strokeStyle='#f6edc4';g.lineWidth=1.1;g.beginPath();g.moveTo(p.x,p.y-130);g.quadraticCurveTo(x-36,y+110,x,y);g.stroke();}
  render(g,rig,images,pose,{clear:false,scale:k,offsetX:p.x-g.canvas.width/2+(rig.width/2-rig.rootPivot[0])*k,offsetY:p.y-g.canvas.height/2+(rig.height/2-rig.rootPivot[1])*k-(o.lift||0)});}
 else {const im=images[o.type],h=o.w*im.height/im.width;
  if(coretoCutaway(o)){const split=125,k=o.w/im.width;g.drawImage(im,0,split,im.width,im.height-split,p.x-o.w/2,p.y-h+split*k,o.w,(im.height-split)*k);g.save();g.globalAlpha*=.22;g.drawImage(im,0,0,im.width,split,p.x-o.w/2,p.y-h,o.w,split*k);g.restore();}
  else g.drawImage(im,p.x-o.w/2,p.y-h,o.w,h);
  if(o.type==='sign'){g.save();g.translate(p.x-o.w/2,p.y-h);g.scale(o.w/im.width,o.w/im.width);g.transform(1,.12,0,1,46,64);g.drawImage(board,0,0);g.restore();}
  if(o.type==='coreto'){const flags=rigs.bunting,k=.45;render(g,flags,images,sample(flags,'idle',wind),{clear:false,scale:k,offsetX:p.x-g.canvas.width/2,offsetY:p.y-g.canvas.height/2+(flags.height/2-flags.rootPivot[1])*k-95});}
 }
 g.restore();
}

 props=buildProps();groundPaint();buildBoard();
 function camera(position,width,height){const scale=Math.max(.58,Math.min(1.15,width/1100)),p=toIso(position);return {x:p.x-width/(2*scale),y:p.y-height/(2*scale)-45,scale,isometric:true};}
 function draw(ctx,position,entries,{time=0,dt=0,animate=true,active=true,partner=null,entrances=[]}={}){
  g=ctx;actor=position;paused=!animate;if(active){grass.update(dt,actor,partner,{reduced:!animate});if(animate)wind+=Math.min(dt,.1);}
  g.drawImage(ground,-930,-20);hitAreas=[];
  if(actor.path?.length){g.save();plane(g);g.strokeStyle='#fff5ce99';g.lineWidth=3;g.setLineDash([5,10]);g.beginPath();g.moveTo(actor.x,actor.y);for(const p of actor.path)g.lineTo(p.x,p.y);g.stroke();g.restore();}
  const queue=depthOrder([...props,...grass.tufts,...entries.filter(e=>!e.overlay)]);const playerDepth=toIso(actor).y;
  queue.sort((a,b)=>(coretoCutaway(a)?playerDepth-1:a.depth)-(coretoCutaway(b)?playerDepth-1:b.depth));
  for(const o of queue){if(o.draw){const p=toIso(o);o.draw(p);if(o.action){const w=o.type==='guardian'?140:56,h=o.type==='guardian'?150:90;hitAreas.push({x:p.x-w/2,y:p.y-h,w,h,id:o.action,action:o.action,depth:p.y+1});}}else if(o.type==='grass')drawTallGrass(g,o,{project:toIso,wind,paused});else drawProp(o);}
  for(const o of entries.filter(e=>e.overlay)){const p=toIso(o);o.draw(p);if(o.type==='npc')hitAreas.push({x:p.x-25,y:p.y-80,w:50,h:80,id:'assis',depth:p.y+1});}
  for(const e of entrances){const p=toIso(e);g.save();g.translate(p.x-e.x,p.y-e.y);e.draw();g.restore();
   // Markers sit above the floor anchor. A click on the blue arrow must target
   // the authored portal, not an unprojected point a few pixels short of it.
   hitAreas.push({x:p.x-28,y:p.y-42,w:56,h:60,id:e.id,action:e.action,target:e.target,depth:p.y+10000});
  }
  drawTallGrassParticles(g,grass.particles);
 }
 function pick(p){const hit=hitAreas.filter(a=>hitsBox(p,a)).sort((a,b)=>b.depth-a.depth)[0];return hit?.action?{id:hit.id,action:hit.action,target:hit.target}:hit?.id||null;}
 function reset(){grass.reset();}
 return {draw,camera,pick,reset,props,grass,mapImage:board,project:toIso,unproject:fromIso};
}
