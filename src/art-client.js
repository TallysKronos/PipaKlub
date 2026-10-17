export function createArtAssets(config){
 const images=new Map(),loading=new Map(),atlases=config.atlases;
 const creatureNames=['carcara','mata-verde','azulao','raio-de-sol'];
 const specials=config.dex.entries.filter(e=>e.group==='event'&&atlases[e.atlas]).map(e=>({id:e.id,name:e.name,color:e.color,legend:e.title,collection:e.collection,rarity:e.rarity||'especial'}));
 const special=id=>specials.find(s=>s.id===id);
 const reduced=typeof matchMedia==='function'&&matchMedia('(prefers-reduced-motion:reduce)').matches;
 function load(name,retry=false){
  if(images.has(name))return Promise.resolve(true);
  if(loading.has(name)&&!retry)return loading.get(name);
  if(typeof Image==='undefined')return Promise.resolve(false);
  const pending=new Promise(resolve=>{const image=new Image();image.decoding='async';image.onload=()=>{images.set(name,image);resolve(true);};image.onerror=()=>resolve(false);image.src=atlases[name].meta.url;});loading.set(name,pending);return pending;
 }
 function draw(context,name,frame,x,y,width,height,fit=false){
  const image=images.get(name),def=atlases[name]?.frames[frame];if(!image||!def)return false;
  const f=def.frame,b=fit?def.contentBounds:atlases[name].meta.viewport,r=b?{x:f.x+b.x,y:f.y+b.y,w:b.w,h:b.h}:f;
  const scale=Math.min(width/r.w,height/r.h),w=r.w*scale,h=r.h*scale;
  const smoothing=context.imageSmoothingEnabled;context.imageSmoothingEnabled=false;
  context.drawImage(image,r.x,r.y,r.w,r.h,x+(width-w)/2,y+(height-h)/2,w,h);context.imageSmoothingEnabled=smoothing;return true;
 }
 function creature(context,color,time,x=-56,y=-44,size=112,player={},victory=false){
  const left=player.facing===-1||(player.facing!==1&&player.input?.x<-.05);
  if(!left)return drawCreature(context,color,time,x,y,size,player,victory);
  context.save();
  try{context.translate(2*x+size,0);context.scale(-1,1);return drawCreature(context,color,time,x,y,size,player,victory);}
  finally{context.restore();}
 }
 function drawCreature(context,color,time,x=-56,y=-44,size=112,player={},victory=false){
  const frozen=reduced&&player.animate!==true;
  if(special(player.soul)){
   const a=atlases[player.soul];if(!images.has(player.soul))load(player.soul);
   const hurt=player.hitFlash>0,skill=player.skillCooldown>6.37;
   const state=victory?'victory':hurt?'hurt':skill?'skill':Math.hypot(player.input?.x||0,player.input?.y||0)>.1?'flight':'idle';
   const elapsed=victory?time:hurt?250-player.hitFlash*1000:skill?7000-player.skillCooldown*1000:time;
   const seq=a.animations[state],durations=a.playback[state].durations,total=durations.reduce((sum,d)=>sum+d,0);
   let at=a.playback[state].loop?Math.max(0,elapsed)%total:Math.min(total-1,Math.max(0,elapsed)),index=0;
   while(index<seq.length-1&&at>=durations[index])at-=durations[index++];
   if(draw(context,player.soul,seq[frozen?0:index],x-8,y-8,size+16,size+16))return true;
  }
  const name=creatureNames[color]||creatureNames[0],seq=atlases['pipas-almaticas'].animations[name];
  return draw(context,'pipas-almaticas',seq[frozen?0:Math.floor(time/190)%seq.length],x,y,size,size);
 }
 function markup(color,soul){if(special(soul)){
  const a=atlases[soul],v=a.meta.viewport;
  const framing=v?'background-size:'+a.meta.size.w/v.w*100+'% '+a.meta.size.h/v.h*100+'%;background-position:'+v.x/(a.meta.size.w-v.w)*100+'% '+v.y/(a.meta.size.h-v.h)*100+'%':'background-size:400% 400%;background-position:0 0';
  return '<span class="almatic-icon special-icon" aria-hidden="true" style="background-image:url('+a.meta.url+');'+framing+'"></span>';
 }color=Number.isInteger(color)&&color>=0&&color<4?color:0;return '<span class="almatic-icon" aria-hidden="true" style="background-image:url('+atlases['pipas-almaticas'].meta.url+');background-position:0 '+(color*100/3)+'%"></span>';}
 load('pipas-almaticas');
 return {load,draw,creature,markup,atlases,reduced,specials,special};
}
