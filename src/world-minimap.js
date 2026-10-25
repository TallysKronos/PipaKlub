// Presentation-only exploration memory. Never unlocks a route or an encounter.
export function createWorldMinimap(scene, saved = {}, canvasFactory = null) {
 const size=40,width=scene.width,height=scene.height;
 const seen=new Set((Array.isArray(saved.cells)?saved.cells:[]).filter(n=>Number.isInteger(n)&&n>=0&&n<size*size));
 const places=new Set((Array.isArray(saved.places)?saved.places:[]).filter(id=>scene.places.some(p=>p.id===id)));
 const cell=(x,y)=>Math.floor(y/height*size)*size+Math.floor(x/width*size);
 const project=p=>scene.isometric?{x:(p.x-p.y)*.82,y:(p.x+p.y)*.41}:{x:p.x,y:p.y};
 let previous=null,heading=0,revision=0,maskRevision=-1,layer=null,mask=null;
 function surfaces(){if(layer||!canvasFactory)return;layer=canvasFactory();layer.width=layer.height=240;mask=canvasFactory();mask.width=512;mask.height=Math.max(1,Math.round(512*height/width));}
 function rebuildFog(){
  const m=mask.getContext('2d'),sx=mask.width/width,sy=mask.height/height;m.clearRect(0,0,mask.width,mask.height);
  // Overlapping soft circles remove cell seams without revealing new landmarks.
  const radius=Math.max(width/size,height/size)*1.15;
  for(const n of seen){const x=(n%size+.5)*width/size,y=(Math.floor(n/size)+.5)*height/size;
   m.save();m.scale(sx,sy);const fog=m.createRadialGradient(x,y,radius*.2,x,y,radius);fog.addColorStop(0,'#fff');fog.addColorStop(.55,'#fffffff0');fog.addColorStop(1,'#ffffff00');m.fillStyle=fog;m.fillRect(x-radius,y-radius,radius*2,radius*2);m.restore();
  }maskRevision=revision;
 }
 function reveal(actor,near){
  if(!Number.isFinite(actor?.x)||!Number.isFinite(actor?.y))return false;
  if(previous&&Math.hypot(actor.x-previous.x,actor.y-previous.y)>1) {const delta=project({x:actor.x-previous.x,y:actor.y-previous.y});heading=Math.atan2(delta.y,delta.x)+Math.PI/2;}
  previous={x:actor.x,y:actor.y};const before=seen.size+places.size,radius=Math.max(110,Math.min(240,Math.min(width,height)*.23));
  for(let y=Math.max(0,Math.floor((actor.y-radius)/height*size));y<Math.min(size,Math.ceil((actor.y+radius)/height*size));y++)for(let x=Math.max(0,Math.floor((actor.x-radius)/width*size));x<Math.min(size,Math.ceil((actor.x+radius)/width*size));x++)if(Math.hypot((x+.5)*width/size-actor.x,(y+.5)*height/size-actor.y)<=radius)seen.add(y*size+x);
  if(near&&scene.places.some(p=>p.id===near.id))places.add(near.id);
  if(before!==seen.size+places.size){revision++;return true;}return false;
 }
 function draw(g,actor,points){
  surfaces();if(!layer||!mask)return;
  if(maskRevision!==revision)rebuildFog();
  const span=Math.min(800,Math.max(440,Math.min(width,height)*.8)),scale=240/span,center=project(actor),c=layer.getContext('2d');
  const transform=ctx=>{ctx.translate(120-center.x*scale,120-center.y*scale);ctx.scale(scale,scale);if(scene.isometric)ctx.transform(.82,.41,-.82,.41,0,0);};
  const rounded=(r,color)=>{c.fillStyle=color;c.beginPath();c.roundRect(r.x,r.y,r.w,r.h,Math.min(20,r.w/4,r.h/4));c.fill();};
  c.clearRect(0,0,240,240);c.save();transform(c);c.fillStyle='#688a59';c.fillRect(0,0,width,height);
  if(scene.tiled){
   for(const r of scene.tiled.layers.Walkable||[]){const frame=r.properties?.ground_frame;rounded(r,frame==='grass'?'#8bac6d':frame==='water'?'#5796a5':frame==='sidewalk'?'#e5dbaf':'#d6bc83');}
   for(const r of scene.tiled.layers.Solids||[]){
    if(/tree|shrub|planter/.test(r.name||'')){const x=r.x+r.w/2,y=r.y+r.h/2,radius=/tree/.test(r.name)?48:Math.max(15,r.w*.5);c.fillStyle='#365e49';c.beginPath();c.ellipse(x+5,y+9,radius,radius*.8,0,0,Math.PI*2);c.fill();c.fillStyle='#547f50';c.beginPath();c.ellipse(x,y,radius*.9,radius*.72,0,0,Math.PI*2);c.fill();}
    else{rounded({...r,x:r.x+4,y:r.y+6},'#395b4544');rounded(r,/hedge|fence/.test(r.name||'')?'#3c6950':'#a48361');}
   }
  }else{c.strokeStyle='#d6bc83';c.lineWidth=22;c.lineCap='round';c.lineJoin='round';for(const [a,b]of scene.edges){c.beginPath();c.moveTo(points[a].x,points[a].y);c.lineTo(points[b].x,points[b].y);c.stroke();}}
  c.restore();c.save();c.globalCompositeOperation='destination-in';transform(c);c.drawImage(mask,0,0,width,height);c.restore();
  g.clearRect(0,0,240,240);g.save();g.beginPath();g.arc(120,120,116,0,Math.PI*2);g.clip();
  const mist=g.createRadialGradient(100,80,10,120,120,150);mist.addColorStop(0,'#26484b');mist.addColorStop(1,'#102e35');g.fillStyle=mist;g.fillRect(0,0,240,240);g.drawImage(layer,0,0);
  for(const place of scene.places){const p=points[place.node];if(!places.has(place.id)||!p||!seen.has(cell(p.x,p.y)))continue;const q=project(p),x=120+(q.x-center.x)*scale,y=120+(q.y-center.y)*scale;g.fillStyle='#f1cd76';g.strokeStyle='#244744';g.lineWidth=2;g.beginPath();g.arc(x,y,4,0,Math.PI*2);g.fill();g.stroke();}
  g.translate(120,120);g.rotate(heading);g.beginPath();g.moveTo(0,-8);g.lineTo(6,6);g.lineTo(0,3);g.lineTo(-6,6);g.closePath();g.fillStyle='#4ad7ed';g.strokeStyle='#fff5dc';g.lineWidth=2;g.fill();g.stroke();g.restore();
 }

 return {reveal,draw,project,get revision(){return revision;},snapshot:()=>({cells:[...seen],places:[...places]})};
}
