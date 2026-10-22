// ?rig: full-colour cutout rigs from the Soulgen Studio drawn in battle instead of the painted atlas.
// Gameplay is untouched: the engine still decides every hit. The rig reads the same player state as the
// atlas sprite and, when a cut lands (strikes counter goes up), plays the Golpe from its impact pose.
const soulgenRigs=(()=>{
/* SOULGEN_MODEL */
 const enabled=/[?&]rig\b/.test(location.search),byColor={},images={},strikes={},specialAt={};
 for(const [id,r]of Object.entries(ART_CONFIG.rigs||{}))byColor[r.color]={id,...r};
 function load(r){
  if(images[r.id])return;images[r.id]={};
  for(const [asset,url]of Object.entries(r.urls)){const image=new Image();image.decoding='async';image.onload=()=>{images[r.id][asset]=image;};image.src=url;}
 }
 const ready=r=>Object.keys(r.urls).every(a=>images[r.id]?.[a]);
 function action(r,player,time,victory){
  const clips=r.project.clips,now=time/1000,id=player.id??'demo';
  if(art.reduced&&player.animate!==true)return ['idle',0];
  if(victory)return ['victory',now%(clips.victory.seconds+.8)];
  if(player.hitFlash>0)return ['hurt',.25-player.hitFlash];
  // A landed cut: start the Golpe at its impact and play the recovery twice as fast.
  const seen=strikes[id];if(!seen||player.strikes<seen.n)strikes[id]={n:player.strikes||0,at:-1e9};
  else if((player.strikes||0)>seen.n)strikes[id]={n:player.strikes,at:now};
  const skill=clips.skill,since=now-strikes[id].at,recover=(skill.seconds-skill.hitTime)/2;
  if(skill.hitTime!=null&&since<recover)return ['skill',skill.hitTime+since*2];
  // Special activated: wind up to the impact pose while the skill is fresh.
  if(player.skillCooldown>7-skill.hitTime)return ['skill',7-player.skillCooldown];
  return [Math.hypot(player.input?.x||0,player.input?.y||0)>.1?'flight':'idle',now];
 }
 function draw(ctx,color,time,x,y,size,player={},victory=false){
  if(!enabled)return false;const r=byColor[color];
  if(!r||art.special(player.soul))return false;
  load(r);if(!ready(r))return false;
  const [clip,t]=action(r,player,time,victory),pose=sample(r.project,clip,t),m=matrices(r.project,pose);
  const left=player.facing===-1||(player.facing!==1&&player.input?.x<-.05),s=size/r.project.width*(r.scale||1);
  ctx.save();ctx.imageSmoothingEnabled=true;ctx.imageSmoothingQuality='high';
  ctx.translate(x+size/2,y+size/2+(r.offsetY||0));ctx.scale(s*(left?-1:1),s);ctx.translate(-r.project.width/2,-r.project.height/2);
  for(const p of [...r.project.parts].sort((a,b)=>a.z-b.z)){
   if(p.visible===false)continue;const face=p.faces?.[pose.face],image=images[r.id][face?.asset||p.asset];if(!image)continue;
   ctx.save();ctx.transform(...m[p.id]);ctx.drawImage(image,...(face?.source||p.source),...p.rect);ctx.restore();
  }
  ctx.restore();return true;
 }
 return {enabled,draw};
})();
