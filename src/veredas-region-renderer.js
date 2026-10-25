import {toIso,fromIso} from './world-isometric.js';
import {createTallGrass} from './world-tall-grass.js';
import {drawTallGrass,drawTallGrassParticles} from './world-tall-grass-renderer.js';
import {worldTerrainContours} from './world-art.js';
// Shared visual joints derived from the authored floors, not independent decals.
export function veredasTerrainPlan(scene){
 const walk=scene.tiled.layers.Walkable,ramps=walk.filter(r=>r.properties.rise_to),paths=walk.filter(r=>['dirt','sidewalk'].includes(r.properties.ground_frame)).map(r=>({...r,elevation:r.properties.elevation||0}));
 const bridges=walk.filter(r=>r.properties.ground_frame==='bridge').map(r=>{const water=scene.veredas.water.find(w=>r.x<w.x+w.w&&r.x+r.w>w.x&&r.y<w.y+w.h&&r.y+r.h>w.y);const x=water?water.x-24:r.x,w=water?water.w+48:r.w;paths.push({x:r.x,y:r.y,w:x-r.x,h:r.h,elevation:0},{x:x+w,y:r.y,w:r.x+r.w-x-w,h:r.h,elevation:0});return {...r,x,w};});
 for(const r of ramps){paths.push({x:r.x,y:r.y-128,w:r.w,h:128,elevation:r.properties.rise_to},{x:r.x,y:r.y+r.h,w:r.w,h:64,elevation:0});}
 const cliffs=[],floors=walk.filter(r=>!r.properties.rise_to&&r.properties.ground_frame!=='bridge'),inside=(r,p)=>p.x>r.x&&p.x<r.x+r.w&&p.y>r.y&&p.y<r.y+r.h;
 // Material-independent union: surface overlays cannot create internal walls.
 for(const elevation of [...new Set(floors.map(r=>r.properties.elevation||0))].filter(h=>h>0)){
  for(const contour of worldTerrainContours(floors.filter(r=>(r.properties.elevation||0)===elevation)))for(let i=0;i<contour.length;i++){
   const a=contour[i],b=contour[(i+1)%contour.length],axis=a.y===b.y?'x':'y';
   // Only the south/east-facing walls are visible in this isometric view.
   if(axis==='x'?b.x>=a.x:b.y<=a.y)continue;
   const start=axis==='x'?b.x:a.y,end=axis==='x'?a.x:b.y,fixed=axis==='x'?a.y:a.x;
   const breaks=[...new Set([start,end,...walk.flatMap(r=>axis==='x'?[r.x,r.x+r.w]:[r.y,r.y+r.h]).filter(v=>v>start&&v<end)])].sort((a,b)=>a-b);
   for(let j=0;j<breaks.length-1;j++){const lo=breaks[j],hi=breaks[j+1],mid=(lo+hi)/2,out=axis==='x'?{x:mid,y:fixed+.01}:{x:fixed+.01,y:mid},at=axis==='x'?{x:mid,y:fixed-.01}:{x:fixed-.01,y:mid};
    if(ramps.some(r=>axis==='x'&&r.y===fixed&&mid>r.x&&mid<r.x+r.w&&r.properties.rise_to===elevation))continue;
    const lower=Math.max(0,...floors.filter(r=>inside(r,out)).map(r=>r.properties.elevation||0));if(lower>=elevation)continue;
    const grass=floors.some(r=>r.properties.ground_frame==='grass'&&(r.properties.elevation||0)===elevation&&inside(r,at));
    const last=cliffs[cliffs.length-1],x=axis==='x'?lo:fixed,y=axis==='x'?fixed:lo;
    if(last&&last.axis===axis&&last.elevation===elevation&&last.h===elevation-lower&&last.grass===grass&&(axis==='x'?last.y===y&&last.x+last.w===x:last.x===x&&last.y+last.w===y))last.w+=hi-lo;
    else cliffs.push({x,y,w:hi-lo,h:elevation-lower,elevation,axis,grass});
   }
  }
 }
 return {ramps,bridges,paths:paths.filter(r=>r.w>0&&r.h>0),cliffs};
}
// Dedicated renderer for the expanded region. The same authored surfaces drive
// collision, height, stair interpolation, clicking and the cached terrain.
export function createVeredasRegionRenderer(scene,images,pack,model,createCanvas=()=>document.createElement('canvas')){
 const walk=scene.tiled.layers.Walkable,solids=scene.tiled.layers.Solids,rigs=pack.rigs,terrain=veredasTerrainPlan(scene);
 const contains=(r,p)=>p.x>=r.x&&p.x<=r.x+r.w&&p.y>=r.y&&p.y<=r.y+r.h;
 const height=p=>{const r=walk.find(r=>contains(r,p));return r?.properties.rise_to?(r.y+r.h-p.y)/r.h*r.properties.rise_to:r?.properties.elevation||0;};
 const project=p=>{const q=toIso(p);return {x:q.x,y:q.y-height(p)};};
 const safe=p=>walk.some(r=>contains(r,p))&&!solids.some(r=>contains(r,p));
 function unproject(p){for(const h of [96,0]){let q=fromIso({x:p.x,y:p.y+h});for(let i=0;i<8;i++)q=fromIso({x:p.x,y:p.y+height(q)});const d=project(q);if(safe(q)&&Math.hypot(d.x-p.x,d.y-p.y)<2)return q;}return fromIso(p);}
 const origin={x:scene.height*.82+240,y:220},ground=createCanvas();ground.width=Math.ceil((scene.width+scene.height)*.82+480);ground.height=Math.ceil((scene.width+scene.height)*.41+440);const c=ground.getContext('2d');c.translate(origin.x,origin.y);
 function polygon(ctx,points,fill,stroke=null){ctx.beginPath();points.forEach((p,i)=>i?ctx.lineTo(p.x,p.y):ctx.moveTo(p.x,p.y));ctx.closePath();if(fill){ctx.fillStyle=fill;ctx.fill();}if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=2;ctx.stroke();}}
 const corners=(r,h=0)=>[{x:r.x,y:r.y},{x:r.x+r.w,y:r.y},{x:r.x+r.w,y:r.y+r.h},{x:r.x,y:r.y+r.h}].map(p=>{const q=toIso(p);q.y-=h;return q;});
 // Four illustrated material cells. Mirror repeats meet at identical texels;
 // each surface maps them in its own plane rather than stretching a screenshot.
 const materials={};
 if(images.terrain){for(const [id,col,row,size]of [['water',0,0,256],['rock',1,0,144],['grass',0,1,320],['dirt',1,1,256]]){const tile=createCanvas();tile.width=tile.height=size*2;const tc=tile.getContext('2d'),im=images.terrain,sw=im.width/2,sh=im.height/2;for(let y=0;y<2;y++)for(let x=0;x<2;x++){tc.save();tc.translate(x?size*2:0,y?size*2:0);tc.scale(x?-1:1,y?-1:1);tc.drawImage(im,col*sw,row*sh,sw,sh,0,0,size,size);tc.restore();}materials[id]=c.createPattern(tile,'repeat');}}
 function texture(points,id,w,h,shade=null,ox=0,oy=0){const pattern=materials[id];if(pattern){c.save();const [a,b,,d]=points;c.transform((b.x-a.x)/w,(b.y-a.y)/w,(d.x-a.x)/h,(d.y-a.y)/h,a.x,a.y);c.translate(-ox,-oy);c.fillStyle=pattern;c.fillRect(ox,oy,w,h);c.restore();}if(shade)polygon(c,points,shade);}
 function line(points,color,width){c.beginPath();points.forEach((p,i)=>i?c.lineTo(p.x,p.y):c.moveTo(p.x,p.y));c.strokeStyle=color;c.lineWidth=width;c.lineJoin='round';c.stroke();}
 // Cached forest surrounds the playable shelves. Its darker value keeps the
 // traversable meadow readable, without suggesting extra paths in empty space.
 const surround={x:-768,y:-768,w:scene.width+1536,h:scene.height+1536};polygon(c,corners(surround),'#57774a');texture(corners(surround),'grass',surround.w,surround.h,'#254a3655',surround.x,surround.y);
 if(images.canopy)for(let y=-448;y<scene.height+448;y+=160)for(let x=-448;x<scene.width+448;x+=192){const p={x:x+(Math.floor(y/160)%2)*74,y};if(walk.some(r=>contains({x:r.x-80,y:r.y-80,w:r.w+160,h:r.h+160},p))||scene.veredas.water.some(r=>contains({x:r.x-48,y:r.y-48,w:r.w+96,h:r.h+96},p)))continue;const q=toIso(p);c.save();c.globalAlpha=.45;const size=176+((x+y)%3+3)%3*12;c.drawImage(images.canopy,q.x-size/2,q.y-size*.66,size,size*.76);c.restore();}
 // Water is non-walkable. Shadows and irregular stone banks anchor it to land.
 for(const r of scene.veredas.water){const p=corners(r);polygon(c,p,'#348c9b');texture(p,'water',r.w,r.h,null,r.x,r.y);line([p[0],p[3]],'#22545188',12);line([p[1],p[2]],'#c4d89a99',7);for(const x of [r.x,r.x+r.w])for(let y=r.y+18;y<r.y+r.h;y+=38){const q=toIso({x,y}),k=7+(y%5);polygon(c,[{x:q.x-k,y:q.y-3},{x:q.x-2,y:q.y-8},{x:q.x+k,y:q.y-2},{x:q.x+k-2,y:q.y+5},{x:q.x-4,y:q.y+6}],'#a59b6f','#677856');line([{x:q.x-k+2,y:q.y-3},{x:q.x-2,y:q.y-7},{x:q.x+k-2,y:q.y-2}],'#dfd2a0',2);}}
 const base=walk.filter(r=>r.properties.ground_frame==='grass');
 // Cliff faces stop at ramp mouths. The grass cap, face and foot use one edge.
 for(const edge of terrain.cliffs){const a={x:edge.x,y:edge.y},b=edge.axis==='x'?{x:edge.x+edge.w,y:edge.y}:{x:edge.x,y:edge.y+edge.w},qa=toIso(a),qb=toIso(b);qa.y-=edge.elevation-edge.h;qb.y-=edge.elevation-edge.h;const p=[{x:qa.x,y:qa.y-edge.h},{x:qb.x,y:qb.y-edge.h},qb,qa];polygon(c,p,'#a57b4c');texture(p,'rock',edge.w,edge.h,edge.axis==='y'?'#263e4428':null,edge.axis==='x'?edge.x:edge.y,0);line([qa,qb],'#284a3440',9);}
 for(const r of walk.filter(r=>r.properties.ground_frame==='grass'||r.properties.ground_frame==='sidewalk'&&r.properties.elevation)){const h=r.properties.elevation||0,p=corners(r,h),grass=r.properties.ground_frame==='grass';polygon(c,p,grass?'#a9c574':'#dfbd7d');texture(p,grass?'grass':'dirt',r.w,r.h,grass?'#a9c57422':null,r.x,r.y);}
 // Trace each connected path once: no internal rectangle seams or pointed joins.
 function roundedPath(contours,radius){c.beginPath();for(const points of contours){for(let i=0;i<points.length;i++){const p=points[i],a=points[(i+points.length-1)%points.length],b=points[(i+1)%points.length],la=Math.hypot(p.x-a.x,p.y-a.y),lb=Math.hypot(b.x-p.x,b.y-p.y),r=Math.min(radius,la/2,lb/2),before={x:p.x+(a.x-p.x)*r/la,y:p.y+(a.y-p.y)*r/la},after={x:p.x+(b.x-p.x)*r/lb,y:p.y+(b.y-p.y)*r/lb};if(i)c.lineTo(before.x,before.y);else c.moveTo(before.x,before.y);c.quadraticCurveTo(p.x,p.y,after.x,after.y);}c.closePath();}}
 for(const elevation of [...new Set(terrain.paths.map(r=>r.elevation))]){const rects=terrain.paths.filter(r=>r.elevation===elevation),contours=worldTerrainContours(rects);c.save();c.transform(.82,.41,-.82,.41,0,-elevation);roundedPath(contours,28);c.strokeStyle='#7c945566';c.lineWidth=12;c.stroke();c.fillStyle='#dfbd7d';c.fill();c.save();c.clip();c.fillStyle=materials.dirt||'#dfbd7d';c.fillRect(0,0,scene.width,scene.height);c.restore();c.restore();}
 for(const r of walk.filter(r=>r.properties.ground_frame==='park-tall-grass')){const p=corners(r,r.properties.elevation||0);polygon(c,p,'#719c52');texture(p,'grass',r.w,r.h,'#36613235',r.x,r.y);}
 // Ramp side wedges share endpoints with the cut cliff; no painted wall behind it.
 for(const r of terrain.ramps){const p=[{x:r.x,y:r.y},{x:r.x+r.w,y:r.y},{x:r.x+r.w,y:r.y+r.h},{x:r.x,y:r.y+r.h}].map(project),flat=corners(r);
  for(const [a,b,d]of [[p[0],p[3],flat[0]],[p[1],p[2],flat[1]]]){c.save();polygon(c,[a,b,d],'#987346');c.clip();texture([a,b,{x:b.x,y:b.y+r.properties.rise_to},{x:a.x,y:a.y+r.properties.rise_to}],'rock',r.h,r.properties.rise_to,'#465b3522');c.restore();}
  polygon(c,p,'#d5b57a');texture(p,'dirt',r.w,r.h,null,r.x,r.y);line([p[0],p[3]],'#80925b88',5);line([p[1],p[2]],'#80925b88',5);
 }
 // A continuous grass lip follows the exposed cliff segments, never a ramp mouth.
 for(const edge of terrain.cliffs){const end=edge.axis==='x'?{x:edge.x+edge.w,y:edge.y}:{x:edge.x,y:edge.y+edge.w},a=toIso(edge),b=toIso(end);a.y-=edge.elevation;b.y-=edge.elevation;line([a,b],edge.grass?'#547640':'#9a794b',5);line([a,b],edge.grass?'#b4c57b':'#e0bd7a',1.5);for(let t=12;edge.grass&&t<edge.w;t+=25){const q={x:a.x+(b.x-a.x)*t/edge.w,y:a.y+(b.y-a.y)*t/edge.w},drop=4+t%11;polygon(c,[{x:q.x-5,y:q.y-1},{x:q.x+5,y:q.y-1},{x:q.x+2,y:q.y+drop},{x:q.x-2,y:q.y+drop*.6}],'#779652');}}
 // Bridge decks are drawn after ALL earth surfaces, with abutments on both banks.
 for(const r of terrain.bridges){const p=corners(r),bottom=p.map(q=>({x:q.x,y:q.y+9}));polygon(c,p.map(q=>({x:q.x+5,y:q.y+13})),'#173b4266');
  for(const x of [r.x-9,r.x+r.w-9]){const foot={x,y:r.y-8,w:18,h:r.h+16},top=corners(foot),low=top.map(q=>({x:q.x,y:q.y+12}));polygon(c,[top[3],top[2],low[2],low[3]],'#7c7855');texture(top,'rock',18,r.h+16,null,x,r.y);}
  polygon(c,[p[3],p[2],bottom[2],bottom[3]],'#695039','#4c4834');polygon(c,[p[1],p[2],bottom[2],bottom[1]],'#594833');polygon(c,p,'#b88a50','#705238');
  for(let x=r.x;x<r.x+r.w;x+=16){const w=Math.min(16,r.x+r.w-x),plank=corners({x,y:r.y,w,h:r.h});polygon(c,plank,(Math.floor(x/16)%3)?'#bd9259':'#c79d62','#80603c');const a=toIso({x:x+5,y:r.y+8}),b=toIso({x:x+5,y:r.y+r.h-8});line([a,b],'#e1bc7d',1.3);}
  for(const y of [r.y+6,r.y+r.h-6]){const a=toIso({x:r.x-4,y}),b=toIso({x:r.x+r.w+4,y});line([a,b],'#755336',7);line([{x:a.x,y:a.y-2},{x:b.x,y:b.y-2}],'#d1ad6d',2);}
 }
 const grass=createTallGrass(walk.filter(r=>r.properties.ground_frame==='park-tall-grass'),{project});
 const props=solids.filter(r=>r.properties.world_prop==='tree').map((r,i)=>({x:r.x+r.w/2,y:r.y+r.h,type:'tree',w:200+i%3*18}));
 // Borders and landmarks use approved whole-tree, flower and windsock art.
 for(const r of base){for(let x=r.x+60;x<r.x+r.w;x+=224){const y=r.y+32;if(!props.some(p=>Math.hypot(p.x-x,p.y-y)<136))props.push({x,y,type:'tree',w:190,scenery:true});}}
 props.push({x:384,y:784,type:'sign',action:'parkMap',w:100},{x:1480,y:960,type:'windsock',w:190},{x:2800,y:232,type:'windsock',w:170},{x:2800,y:256,type:'bench',action:'wildRest',w:126},{x:576,y:1216,type:'kite',action:'veredasTrace',w:74,lift:32});
 for(const [x,y]of [[256,448],[608,448],[1056,1216],[1312,1440],[1888,480],[2528,480],[2656,1600]])props.push({x,y,type:'flowers',w:58});
 for(const chest of scene.veredas.chests)props.push({...chest,type:'chest',action:'veredasChest',target:chest.id,w:90});
 const board=createCanvas();board.width=146;board.height=94;const bc=board.getContext('2d');bc.fillStyle='#365e50';bc.fillRect(0,0,146,94);for(const r of walk){bc.fillStyle=r.properties.ground_frame==='park-tall-grass'?'#548252':r.properties.level?'#e0cb8e':'#b0c77e';bc.fillRect(r.x/scene.width*146,r.y/scene.height*94,r.w/scene.width*146,r.h/scene.height*94);}
 let g,actor,hitAreas=[],wind=0;
 function propBox(o){const p=project(o),rig=rigs[o.type],im=images[o.type],h=rig?rig.height*o.w/rig.width:im?o.w*im.height/im.width:o.w;return {x:p.x-o.w/2,y:p.y-h-(o.lift||0),w:o.w,h};}
 function drawProp(o,opened){const p=project(o),box=propBox(o),rig=rigs[o.type],im=images[o.type];g.save();if(o.type==='tree'){const a=project(actor);if(a.x>box.x&&a.x<box.x+box.w&&a.y>box.y&&a.y<p.y+6)g.globalAlpha=.25;}
  if(o.type==='chest'&&opened.includes(o.id))g.globalAlpha=.45;
  g.fillStyle='#254c3428';g.beginPath();g.ellipse(p.x+5,p.y-1,o.w*.28,o.w*.07,0,0,Math.PI*2);g.fill();
  if(rig){const k=o.w/rig.width;model.render(g,rig,images,model.sample(rig,'idle',wind),{clear:false,scale:k,offsetX:p.x-g.canvas.width/2+(rig.width/2-rig.rootPivot[0])*k,offsetY:p.y-g.canvas.height/2+(rig.height/2-rig.rootPivot[1])*k-(o.lift||0)});}else if(im)g.drawImage(im,box.x,box.y,box.w,box.h);
  if(o.type==='sign')g.drawImage(board,p.x-31,p.y-67,62,40);
  if(o.type==='chest'&&opened.includes(o.id)){g.globalAlpha=1;g.fillStyle='#fff3bf';g.font='bold 20px sans-serif';g.textAlign='center';g.fillText('✓',p.x,p.y-28);}
  g.restore();if(o.action)hitAreas.push({...box,action:o.action,target:o.target,id:o.action,depth:p.y});
 }
 function draw(ctx,position,entries,{time=0,dt=0,animate=true,active=true,partner=null,entrances=[],opened=[]}={}){g=ctx;actor=position;g.drawImage(ground,-origin.x,-origin.y);hitAreas=[];if(active)grass.update(dt,actor,partner,{reduced:!animate});if(animate)wind+=Math.min(dt,.1);
  if(actor.path?.length){g.strokeStyle='#fff1bc99';g.lineWidth=2;g.setLineDash([5,9]);g.beginPath();const start=project(actor);g.moveTo(start.x,start.y);for(const n of actor.path){const p=project(n);g.lineTo(p.x,p.y);}g.stroke();g.setLineDash([]);}
  const queue=[...props,...grass.tufts,...entries].sort((a,b)=>(a.x+a.y)-(b.x+b.y));for(const o of queue){if(o.draw){const p=project(o);o.draw(p);if(o.action)hitAreas.push({x:p.x-45,y:p.y-100,w:90,h:100,action:o.action,target:o.target,id:o.action,depth:p.y+1});}else if(o.type==='grass')drawTallGrass(g,o,{project,wind,paused:!animate});else drawProp(o,opened);}
  for(const e of entrances){const p=project(e);g.save();g.translate(p.x-e.x,p.y-e.y);e.draw();g.restore();hitAreas.push({x:p.x-28,y:p.y-42,w:56,h:60,id:e.id,action:e.action,target:e.target,depth:p.y+10000});}drawTallGrassParticles(g,grass.particles);
 }
 return {draw,project,unproject,props,grass,mapImage:board,reset:()=>grass.reset(),camera:(p,w,h)=>{const q=project(p),scale=Math.max(.65,Math.min(1.15,w/1100));return {x:q.x-w/scale/2,y:q.y-h/scale/2-45,scale,isometric:true};},pick:p=>{const a=hitAreas.filter(a=>p.x>=a.x&&p.x<=a.x+a.w&&p.y>=a.y&&p.y<=a.y+a.h).sort((a,b)=>b.depth-a.depth)[0];return a?{id:a.id,action:a.action,target:a.target}:null;}};
}
