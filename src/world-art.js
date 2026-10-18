// Render plans refer to atlas rectangles; they never alter physical map geometry.
export function buildWorldArtPlan(scene,kit,layout){
 function sprite(binding){
  const frame=kit.frames[binding.frame];if(!frame)throw Error('Arte do mapa: peça desconhecida '+binding.frame);
  const width=binding.width??binding.height*frame.w/frame.h,height=binding.height??width*frame.h/frame.w;
  if(!Number.isFinite(width)||!Number.isFinite(height)||width<=0||height<=0)throw Error('Arte do mapa: dimensão inválida '+binding.frame);
  return {sheet:frame.sheet,sx:frame.x,sy:frame.y,sw:frame.w,sh:frame.h,x:binding.footX-width*(binding.anchorX??frame.anchor.x),y:binding.footY-height*(binding.anchorY??frame.anchor.y),w:width,h:height};
 }
 const objects=[];
 for(const name of ['Solids','Foreground'])for(const rect of scene.tiled.layers[name]){
  const binding=layout.bindings[rect.id];if(!binding)throw Error('Arte do mapa: objeto sem peça '+rect.name);if(binding.hidden)continue;
  const horizontal=binding.repeat==='x',vertical=binding.repeat==='y',length=horizontal?rect.w:vertical?rect.h:1,count=horizontal||vertical?Math.ceil(length/binding.step):1;
  for(let i=0;i<count;i++){
   const footX=binding.footX??(horizontal?rect.x+Math.min(length-binding.step/2,i*binding.step+binding.step/2):rect.x+rect.w/2),footY=binding.footY??(vertical?rect.y+Math.min(length,(i+1)*binding.step):rect.y+rect.h);
   objects.push({kind:name==='Foreground'?'foreground':'solid',rect,level:rect.properties.level,y:rect.properties.sort_y,sprite:sprite({...binding,footX,footY})});
  }
 }
 for(const b of layout.decorations){if(!Number.isInteger(b.level)||!Number.isFinite(b.sortY))throw Error('Arte do mapa: decoração sem piso/apoio');objects.push({kind:'foreground',level:b.level,y:b.sortY,sprite:sprite(b)});}
 return {objects,kit};
}

const worldArtGroundCache=new WeakMap();
export function drawWorldArtGround(g,scene,images,uncached=false){
 if(!uncached&&typeof OffscreenCanvas!=='undefined'&&Object.keys(scene.art.kit.sheets).every(id=>images.has('world-kit-'+id))){let canvas=worldArtGroundCache.get(scene.art);if(!canvas){canvas=new OffscreenCanvas(scene.width,scene.height);drawWorldArtGround(canvas.getContext('2d'),scene,images,true);worldArtGroundCache.set(scene.art,canvas);}g.drawImage(canvas,0,0);return;}
 const kit=scene.art.kit;
 function tile(id,x,y,w,h,size=128){const f=kit.frames[id],image=images.get('world-kit-'+f.sheet);if(!image){g.fillStyle=id==='grass'?'#8daa54':'#d7bf8f';g.fillRect(x,y,w,h);return;}g.save();g.beginPath();g.rect(x,y,w,h);g.clip();for(let py=Math.floor(y/size)*size;py<y+h;py+=size)for(let px=Math.floor(x/size)*size;px<x+w;px+=size)g.drawImage(image,f.x,f.y,f.w,f.h,px,py,size,size);g.restore();}
 tile('grass',0,0,scene.width,scene.height);
 for(const r of scene.tiled.layers.Walkable){tile(r.properties.level===1?'sidewalk':'dirt',r.x,r.y,r.w,r.h);if(r.properties.connects_to!==undefined){const f=kit.frames.stairs,image=images.get('world-kit-'+f.sheet);if(image){const sourceW=Math.min(f.w,f.h*r.w/r.h),sourceH=sourceW*r.h/r.w;g.drawImage(image,f.x+(f.w-sourceW)/2,f.y+(f.h-sourceH)/2,sourceW,sourceH,r.x,r.y,r.w,r.h);}}}
 // Stone edging follows only the OUTSIDE of the union, leaving junctions open.
 const walk=scene.tiled.layers.Walkable,inside=(x,y)=>walk.some(r=>x>=r.x&&x<r.x+r.w&&y>=r.y&&y<r.y+r.h);
 for(const r of walk)for(let y=r.y;y<r.y+r.h;y+=32)for(let x=r.x;x<r.x+r.w;x+=32){
  if(!inside(x-1,y+16))tile('cobblestone',x,y,8,32,64);
  if(!inside(x+33,y+16))tile('cobblestone',x+24,y,8,32,64);
  if(!inside(x+16,y-1))tile('cobblestone',x,y,32,8,64);
  if(!inside(x+16,y+33))tile('cobblestone',x,y+24,32,8,64);
 }
}
