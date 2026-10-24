export function createArtAssets(config){
 const images=new Map(),loading=new Map(),atlases=config.atlases;
 const creatureNames=['carcara','mata-verde','azulao','raio-de-sol'];
 const specials=config.dex.entries.filter(e=>['event','story'].includes(e.group)&&atlases[e.atlas]).map(e=>({id:e.id,name:e.name,color:e.color,legend:e.title,collection:e.collection,rarity:e.rarity||'especial'}));
 if(atlases.lacertubo)specials.push({id:'lacertubo',name:'Lacertubo',color:2,legend:'Guardião dos canos',rarity:'boss'});
 const special=id=>specials.find(s=>s.id===id);
 const reduced=typeof matchMedia==='function'&&matchMedia('(prefers-reduced-motion:reduce)').matches;
 function load(name,retry=false){
  if(!atlases[name])return Promise.resolve(false);
  if(images.has(name))return Promise.resolve(true);
  if(loading.has(name)&&!retry)return loading.get(name);
  if(typeof Image==='undefined')return Promise.resolve(false);
  const pending=new Promise(resolve=>{const image=new Image();image.decoding='async';image.onload=()=>{images.set(name,image);resolve(true);};image.onerror=()=>resolve(false);image.src=atlases[name].meta.url;});loading.set(name,pending);return pending;
 }
 function draw(context,name,frame,x,y,width,height,fit=false){
  const image=images.get(name),def=atlases[name]?.frames[frame];if(!image||!def)return false;
  const f=def.frame,b=fit?def.contentBounds:atlases[name].meta.viewport,r=b?{x:f.x+b.x,y:f.y+b.y,w:b.w,h:b.h}:f;
  const scale=Math.min(width/r.w,height/r.h),w=r.w*scale,h=r.h*scale;
  // Sheets with indivisible dimensions may have cells one pixel smaller than the common viewport.
  // Keep one scale/pivot, but never sample beyond this frame into its neighbour.
  const sx=Math.max(0,r.x-f.x),sy=Math.max(0,r.y-f.y),sw=Math.min(r.w,f.w-sx),sh=Math.min(r.h,f.h-sy);
  if(sw<=0||sh<=0)return false;
  const smoothing=context.imageSmoothingEnabled;context.imageSmoothingEnabled=false;
  context.drawImage(image,f.x+sx,f.y+sy,sw,sh,x+(width-w)/2,y+(height-h)/2,sw*scale,sh*scale);context.imageSmoothingEnabled=smoothing;return true;
 }
 function creature(context,color,time,x=-56,y=-44,size=112,player={},victory=false){
  if(player.soul==='nozinho'){
   if(!images.has('nozinho'))load('nozinho');
   const seq=atlases.nozinho.animations[victory?'happy':player.hitFlash>0?'hurt':player.skillCooldown>6.37?'skill':'idle'];
   return draw(context,'nozinho',seq[reduced?0:Math.floor(time/170)%seq.length],x,y,size,size,true);
  }
  const left=player.facing===-1||(player.facing!==1&&player.input?.x<-.05);
  if(!left)return drawCreature(context,color,time,x,y,size,player,victory);
  context.save();
  try{context.translate(2*x+size,0);context.scale(-1,1);return drawCreature(context,color,time,x,y,size,player,victory);}
  finally{context.restore();}
 }
 function drawCreature(context,color,time,x=-56,y=-44,size=112,player={},victory=false){
  if(player.soul==='rabbito'&&player.classRank>0&&['velocista','condutor'].includes(player.pipamonClass)){context.save();context.globalAlpha=.65;context.strokeStyle=player.pipamonClass==='velocista'?'#75e2ed':'#f7d175';context.lineWidth=Math.max(2,size*.025);const phase=reduced?0:time/700;for(let i=0;i<player.classRank+1;i++){context.beginPath();if(player.pipamonClass==='velocista'){const yy=y+size*(.35+i*.16);context.moveTo(x-size*.12,yy);context.quadraticCurveTo(x+size*.2,yy+Math.sin(phase+i)*size*.08,x+size*.4,yy);}else context.ellipse(x+size*.5,y+size*.6,size*(.42+i*.08),size*.16,Math.sin(phase)*.15,0,Math.PI*2);context.stroke();}context.restore();}
  const frozen=reduced&&player.animate!==true;
  const asset=special(player.soul)?player.soul:config.designs?.basics?.[color];
  if(asset&&atlases[asset]){
   const a=atlases[asset];if(!images.has(asset))load(asset);
   const hurt=player.hitFlash>0,skill=player.skillCooldown>6.37;
   const intro=asset==='lacertubo'&&player.bossIntroTime!=null,roar=asset==='lacertubo'&&player.bossRoar>0,windup=asset==='lacertubo'&&player.bossTelegraph>0,impact=asset==='lacertubo'&&player.flash>0;
   const resultState=player.resultPose==='defeat'?(a.animations.defeat?'defeat':'hurt'):player.resultPose==='victory'?'victory':null;
   const state=resultState||(intro||roar?'intro':victory?'victory':hurt?'hurt':windup||impact||skill?'skill':Math.hypot(player.input?.x||0,player.input?.y||0)>.1?'flight':'idle');
   const elapsed=resultState?player.resultTime||0:intro?player.bossIntroTime:roar?1100+(1.8-player.bossRoar)*700:windup?player.bossTelegraph*650:impact?750+(.16-player.flash)*2000:victory?time:hurt?250-player.hitFlash*1000:skill?7000-player.skillCooldown*1000:time;
   const seq=a.animations[state],durations=a.playback[state].durations,total=durations.reduce((sum,d)=>sum+d,0);
   let at=a.playback[state].loop?Math.max(0,elapsed)%total:Math.min(total-1,Math.max(0,elapsed)),index=0;
   while(index<seq.length-1&&at>=durations[index])at-=durations[index++];
   const padding=special(player.soul)?8:0;
   if(draw(context,asset,seq[frozen?0:index],x-padding,y-padding,size+padding*2,size+padding*2))return true;
  }
  const name=creatureNames[color]||creatureNames[0],seq=atlases['pipas-almaticas'].animations[name];
  return draw(context,'pipas-almaticas',seq[frozen?0:Math.floor(time/190)%seq.length],x,y,size,size);
 }
 function frameMarkup(name,frame='0',className=''){
  const a=atlases[name],r=a?.frames[frame]?.frame;if(!a||!r)return '';
  const sw=a.meta.size.w,sh=a.meta.size.h,px=sw===r.w?0:r.x/(sw-r.w)*100,py=sh===r.h?0:r.y/(sh-r.h)*100;
  return '<span aria-hidden="true" class="design-sprite '+className+'" style="background-image:url('+a.meta.url+');background-size:'+sw/r.w*100+'% '+sh/r.h*100+'%;background-position:'+px+'% '+py+'%"></span>';
 }
 const icon=(id,className='')=>frameMarkup(config.designs?.icons,id,'design-icon '+className);
 function background(context,id,x,y,w,h){const image=images.get(id);if(!image)return false;const a=atlases[id],scale=Math.max(w/a.meta.size.w,h/a.meta.size.h),sw=w/scale,sh=h/scale;context.drawImage(image,(a.meta.size.w-sw)/2,(a.meta.size.h-sh)/2,sw,sh,x,y,w,h);return true;}
 function markup(color,soul){if(special(soul)){
  const a=atlases[soul],v=a.meta.viewport;
  const framing=v?'background-size:'+a.meta.size.w/v.w*100+'% '+a.meta.size.h/v.h*100+'%;background-position:'+v.x/(a.meta.size.w-v.w)*100+'% '+v.y/(a.meta.size.h-v.h)*100+'%':'background-size:400% 400%;background-position:0 0';
  return '<span class="almatic-icon special-icon" aria-hidden="true" style="background-image:url('+a.meta.url+');'+framing+'"></span>';
 }color=Number.isInteger(color)&&color>=0&&color<4?color:0;
 if(config.designs?.basics?.[color])return frameMarkup(config.designs.basics[color],'0','almatic-icon');
 return '<span class="almatic-icon" aria-hidden="true" style="background-image:url('+atlases['pipas-almaticas'].meta.url+');background-position:0 '+(color*100/3)+'%"></span>';}
 load('pipas-almaticas');
 return {load,draw,creature,markup,frameMarkup,icon,background,basic:color=>config.designs?.basics?.[color],atlases,reduced,specials,special};
}
