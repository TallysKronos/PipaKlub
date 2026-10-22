// Render plans refer to atlas rectangles; they never alter physical map geometry.
export function buildWorldArtPlan(scene,kit,layout,{audit=true}={}){
 function sprite(binding){
  const frame=kit.frames[binding.frame];if(!frame)throw Error('Arte do mapa: peça desconhecida '+binding.frame);
  const sw=binding.sourceWidth??frame.w,sh=binding.sourceHeight??frame.h;
  if(!Number.isInteger(sw)||!Number.isInteger(sh)||sw<1||sh<1||sw>frame.w||sh>frame.h)throw Error('Arte do mapa: recorte de término inválido '+binding.frame);
  const width=binding.width??binding.height*sw/sh,height=binding.height??width*sh/sw;
  if(!Number.isFinite(width)||!Number.isFinite(height)||width<=0||height<=0)throw Error('Arte do mapa: dimensão inválida '+binding.frame);
  return {frame:binding.frame,sheet:frame.sheet,sx:frame.x,sy:frame.y,sw,sh,x:binding.footX-width*(binding.anchorX??frame.anchor.x),y:binding.footY-height*(binding.anchorY??frame.anchor.y),w:width,h:height};
 }
 const objects=[];
 for(const name of ['Solids','Foreground'])for(const rect of scene.tiled.layers[name]){
  const binding=layout.bindings[rect.id];if(!binding)throw Error('Arte do mapa: objeto sem peça '+rect.name);if(binding.hidden)continue;
  const horizontal=binding.repeat==='x',vertical=binding.repeat==='y',length=horizontal?rect.w:vertical?rect.h:1,count=horizontal||vertical?Math.ceil(length/binding.step):1;
  for(let i=0;i<count;i++){
   const footX=binding.footX??(horizontal?rect.x+Math.min(length-binding.step/2,i*binding.step+binding.step/2):rect.x+rect.w/2),footY=binding.footY??(vertical?rect.y+Math.min(length,(i+1)*binding.step):rect.y+rect.h);
   objects.push({kind:name==='Foreground'?'foreground':'solid',rect,level:rect.properties.level,y:rect.properties.sort_y,...binding.occludesActors?{occludesActors:true}:{},sprite:sprite({...binding,footX,footY})});
  }
 }
 for(const b of layout.decorations){if(!Number.isInteger(b.level)||!Number.isFinite(b.sortY))throw Error('Arte do mapa: decoração sem piso/apoio');objects.push({kind:'foreground',level:b.level,y:b.sortY,sprite:sprite(b)});}
 const plan={objects,kit};
 if(audit&&layout.audit?.enforce){const errors=auditWorldStructure(scene,plan);if(errors.length)throw Error('Auditoria estrutural: '+errors.join('; '));}
 return plan;
}

// Runs on build and in the editor, before a project can be exported.
export function auditWorldStructure(scene,plan){
 const errors=[],items=plan.objects,of=id=>items.filter(o=>o.sprite.frame===id),overlap=(a,b)=>a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y;
 for(const crown of of('canopy')){
  const c=crown.sprite,trunk=of('trunk').find(t=>Math.abs(t.sprite.x+t.sprite.w/2-c.x-c.w/2)<3&&Math.abs(t.y-crown.y)<1);
  if(!trunk){errors.push('ARB-01 copa sem tronco no mesmo apoio');continue;}
  const t=trunk.sprite,depth=Math.min(c.y+c.h,t.y+t.h)-Math.max(c.y,t.y);
  if(depth<t.h*.25||c.y+c.h>t.y+t.h-t.h*.25)errors.push('ARB-02 encaixe da copa insuficiente ou tronco encoberto');
 }
 for(const frame of ['wall-horizontal','wall-vertical','wall-south','wall-east']){
  const vertical=frame==='wall-vertical'||frame==='wall-east',groups=new Map();
  for(const o of of(frame)){const s=o.sprite,key=(o.rect?.name||frame)+':'+(vertical?o.rect?.x:o.rect?.y);if(!groups.has(key))groups.set(key,[]);groups.get(key).push(s);}
  for(const run of groups.values()){
   run.sort((a,b)=>vertical?a.y-b.y:a.x-b.x);
   for(let i=1;i<run.length;i++){const a=run[i-1],b=run[i];if((vertical?b.y-a.y-a.h:b.x-a.x-a.w)>1)errors.push('MUR-01 vão entre segmentos de muro');if(Math.abs((vertical?a.w-b.w:a.h-b.h))>1||Math.abs(vertical?a.x-b.x:a.y-b.y)>1)errors.push('MUR-02 escala ou alinhamento irregular no muro');}
  }
 }
 for(const bench of of('bench')){
  const s=bench.sprite,seat={x:s.x+s.w*.2,y:bench.y+8,w:s.w*.6,h:48};
  if(items.some(o=>o!==bench&&(o.kind==='solid'&&o.rect&&overlap(seat,o.rect)||o.sprite.frame==='canopy'&&overlap(s,o.sprite))))errors.push('MOB-01 banco encoberto ou sem acesso frontal');
  const walk=scene.tiled.layers.Walkable;
  if(![seat.x,seat.x+seat.w].every(x=>[seat.y,seat.y+seat.h].every(y=>walk.some(r=>x>=r.x&&x<=r.x+r.w&&y>=r.y&&y<=r.y+r.h))))errors.push('MOB-02 banco sem piso de aproximação');
 }
 if(!(scene.tiled.properties.ground_corner_radius>0))errors.push('PIS-01 configurar quinas arredondadas no terreno');
 return [...new Set(errors)];
}

// Trace the UNION of terrain rectangles. Shared edges disappear; holes remain holes.
export function worldTerrainContours(rects){
 if(!rects.length)return [];
 const xs=[...new Set(rects.flatMap(r=>[r.x,r.x+r.w]))].sort((a,b)=>a-b),ys=[...new Set(rects.flatMap(r=>[r.y,r.y+r.h]))].sort((a,b)=>a-b),filled=new Set(),key=(x,y)=>x+','+y;
 for(let y=0;y<ys.length-1;y++)for(let x=0;x<xs.length-1;x++)if(rects.some(r=>(xs[x]+xs[x+1])/2>r.x&&(xs[x]+xs[x+1])/2<r.x+r.w&&(ys[y]+ys[y+1])/2>r.y&&(ys[y]+ys[y+1])/2<r.y+r.h))filled.add(key(x,y));
 const edges=[],starts=new Map();
 function edge(x,y,ex,ey,d){const e={a:{x,y},b:{x:ex,y:ey},d,used:false};edges.push(e);const k=key(x,y);if(!starts.has(k))starts.set(k,[]);starts.get(k).push(e);}
 for(let y=0;y<ys.length-1;y++)for(let x=0;x<xs.length-1;x++)if(filled.has(key(x,y))){
  if(!filled.has(key(x,y-1)))edge(xs[x],ys[y],xs[x+1],ys[y],0);
  if(!filled.has(key(x+1,y)))edge(xs[x+1],ys[y],xs[x+1],ys[y+1],1);
  if(!filled.has(key(x,y+1)))edge(xs[x+1],ys[y+1],xs[x],ys[y+1],2);
  if(!filled.has(key(x-1,y)))edge(xs[x],ys[y+1],xs[x],ys[y],3);
 }
 const contours=[];
 for(const first of edges){if(first.used)continue;let e=first;const points=[];
  while(e&&!e.used){e.used=true;points.push(e.a);const candidates=(starts.get(key(e.b.x,e.b.y))||[]).filter(n=>!n.used);const rank=d=>({1:0,0:1,3:2,2:3})[d];candidates.sort((a,b)=>rank((a.d-e.d+4)%4)-rank((b.d-e.d+4)%4));e=candidates[0];}
  contours.push(points.filter((p,i)=>{const a=points[(i+points.length-1)%points.length],b=points[(i+1)%points.length];return (p.x-a.x)*(b.y-p.y)!==(p.y-a.y)*(b.x-p.x);}));
 }
 return contours;
}

function worldRoundedTerrainPath(g,contours,radius){
 g.beginPath();
 for(const points of contours){if(points.length<3)continue;
  for(let i=0;i<points.length;i++){
   const p=points[i],a=points[(i+points.length-1)%points.length],b=points[(i+1)%points.length],la=Math.hypot(p.x-a.x,p.y-a.y),lb=Math.hypot(b.x-p.x,b.y-p.y),r=Math.min(radius,la/2,lb/2),before={x:p.x+(a.x-p.x)*r/la,y:p.y+(a.y-p.y)*r/la},after={x:p.x+(b.x-p.x)*r/lb,y:p.y+(b.y-p.y)*r/lb};
   if(i===0)g.moveTo(before.x,before.y);else g.lineTo(before.x,before.y);
   g.quadraticCurveTo(p.x,p.y,after.x,after.y);
  }g.closePath();
 }
}

const worldArtGroundCache=new WeakMap();
// Tiled image layers are authored at native size; physics remains in object layers.
export function drawWorldPaintedGround(g,scene,images){
 g.fillStyle='#b4b58a';g.fillRect(0,0,scene.width,scene.height);
 for(const r of scene.tiled.images.filter(i=>i.render==='ground')){const image=images.get('world-kit-'+r.sheet);if(image){g.save();g.globalAlpha*=r.opacity;g.drawImage(image,r.x,r.y,r.w,r.h);g.restore();}}
}
export function validateWorldPaintedImages(scene,sheets){
 if(!scene.tiled.images.some(i=>i.render==='ground'))throw Error('Arte Tiled: camada base ausente');
 for(const r of scene.tiled.images){const s=sheets[r.sheet];if(!s||s.image.split('/').at(-1)!==r.image||s.width!==r.w||s.height!==r.h)throw Error('Arte Tiled: imagem não registrada ou dimensões divergentes: '+r.name);}
 for(const r of scene.tiled.layers.Foreground)if(r.properties.image_sheet){const s=sheets[r.properties.image_sheet];if(!s||r.x+r.w>s.width||r.y+r.h>s.height)throw Error('Arte Tiled: recorte de primeiro plano inválido: '+r.name);}
 return scene;
}
export function drawWorldArtGround(g,scene,images,uncached=false){
 if(!uncached&&typeof OffscreenCanvas!=='undefined'&&Object.keys(scene.art.kit.sheets).every(id=>images.has('world-kit-'+id))){let canvas=worldArtGroundCache.get(scene.art);if(!canvas){canvas=new OffscreenCanvas(scene.width,scene.height);drawWorldArtGround(canvas.getContext('2d'),scene,images,true);worldArtGroundCache.set(scene.art,canvas);}g.drawImage(canvas,0,0);return;}
 const kit=scene.art.kit;
 function tile(id,x,y,w,h,size=scene.tiled.properties.terrain_tile_size||128,target=g){
  const f=kit.frames[id],image=images.get('world-kit-'+f.sheet);if(!image){target.fillStyle=id==='grass'?'#8daa54':'#d7bf8f';target.fillRect(x,y,w,h);return;}
  const mirror=scene.tiled.properties.terrain_repeat==='mirror',tileH=mirror?Math.max(1,Math.round(size*f.h/f.w)):size;
  target.save();if(mirror)target.imageSmoothingEnabled=false;target.beginPath();target.rect(x,y,w,h);target.clip();
  for(let py=Math.floor(y/tileH)*tileH;py<y+h;py+=tileH)for(let px=Math.floor(x/size)*size;px<x+w;px+=size){
   if(mirror){const flipX=((px/size)%2+2)%2===1,flipY=id!=='park-tall-grass'&&((py/tileH)%2+2)%2===1;target.save();target.translate(px+(flipX?size:0),py+(flipY?tileH:0));target.scale(flipX?-1:1,flipY?-1:1);target.drawImage(image,f.x,f.y,f.w,f.h,0,0,size,tileH);target.restore();}
   else target.drawImage(image,f.x,f.y,f.w,f.h,px,py,size,size);
  }target.restore();
 }
 tile('grass',0,0,scene.width,scene.height);
 const radius=scene.tiled.properties.ground_corner_radius||0,groups=new Map();
 for(const r of scene.tiled.layers.Walkable){const id=r.properties.ground_frame||(r.properties.level===1?'sidewalk':'dirt'),key=id+':'+r.properties.level;if(!groups.has(key))groups.set(key,{id,rects:[]});groups.get(key).rects.push(r);}
 for(const {id,rects} of groups.values()){
  if(radius&&id!=='grass'){
   const contours=worldTerrainContours(rects),feather=scene.tiled.properties.terrain_feather||0;
   if(feather>0&&typeof OffscreenCanvas!=='undefined'){
    // Blend the material mask once in the ground cache, not each walking frame.
    const material=new OffscreenCanvas(scene.width,scene.height),mask=new OffscreenCanvas(scene.width,scene.height),mg=material.getContext('2d'),ag=mask.getContext('2d');
    tile(id,0,0,scene.width,scene.height,scene.tiled.properties.terrain_tile_size,mg);
    ag.filter='blur('+Math.min(12,feather)+'px)';worldRoundedTerrainPath(ag,contours,radius);ag.fillStyle='#fff';ag.fill('evenodd');
    mg.globalCompositeOperation='destination-in';mg.drawImage(mask,0,0);g.drawImage(material,0,0);
   }else{g.save();worldRoundedTerrainPath(g,contours,radius);g.clip('evenodd');tile(id,0,0,scene.width,scene.height);g.restore();}
  }
  else for(const r of rects)tile(id,r.x,r.y,r.w,r.h);
 }
 for(const r of scene.tiled.layers.Walkable)if(r.properties.connects_to!==undefined){const f=kit.frames.stairs,image=images.get('world-kit-'+f.sheet);if(image){const sourceW=Math.min(f.w,f.h*r.w/r.h),sourceH=sourceW*r.h/r.w;g.drawImage(image,f.x+(f.w-sourceW)/2,f.y+(f.h-sourceH)/2,sourceW,sourceH,r.x,r.y,r.w,r.h);}}
 // Stone edging follows only the OUTSIDE of the union, leaving junctions open.
 if(scene.tiled.properties.terrain_edge_mode==='none')return;
 const walk=scene.tiled.layers.Walkable,inside=(x,y)=>walk.some(r=>x>=r.x&&x<r.x+r.w&&y>=r.y&&y<r.y+r.h);
 for(const r of walk)for(let y=r.y;y<r.y+r.h;y+=32)for(let x=r.x;x<r.x+r.w;x+=32){
  if(!inside(x-1,y+16))tile('cobblestone',x,y,8,32,64);
  if(!inside(x+33,y+16))tile('cobblestone',x+24,y,8,32,64);
  if(!inside(x+16,y-1))tile('cobblestone',x,y,32,8,64);
  if(!inside(x+16,y+33))tile('cobblestone',x,y+24,32,8,64);
 }
}
