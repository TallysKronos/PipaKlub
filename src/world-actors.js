export function worldPartnerStart(scene,state,follower){
 if(state.actor.history.length>=2)return follower;
 const gap=scene.actorSize*.85,a=state.actor,geometry=state.navigation.geometry;
 const candidates=[{x:a.x+gap,y:a.y+6},{x:a.x-gap,y:a.y+6},{x:a.x,y:a.y+gap},{x:a.x,y:a.y-gap}];
 return candidates.find(p=>geometry?geometry.segment(a,p):p.x>=0&&p.y>=0&&p.x<=scene.width&&p.y<=scene.height)||follower;
}
export function worldPrimeCompanionTrail(scene,state){
 const actor=state.actor;if(actor.history.some(p=>Math.hypot(p.x-actor.x,p.y-actor.y)>.01))return;actor.history=[{x:actor.x,y:actor.y}];
 const resident=worldPartnerStart(scene,state,actor.history[0]);
 if(Math.hypot(resident.x-actor.x,resident.y-actor.y)>.01)actor.history.unshift({x:resident.x,y:resident.y});
}
// Overworld sheets use measured cells, fixed species scale and a foot anchor.
// Dialog portraits and encounter rewards remain independent from map appearance.
export function createWorldActors(config={}){
 const actors=config.characters||{},byName=new Map(Object.entries(actors).map(([id,a])=>[a.name,{id,...a}]));
 function get(name){return byName.get(name);}
 function facing(x,y,target){const dx=(target?.x??x)-x,dy=(target?.y??y+1)-y;return Math.abs(dx)>Math.abs(dy)?dx<0?1:2:dy<0?3:0;}
 function frame(name,direction=0,moving=false,time=0){
  const actor=get(name);if(!actor)return null;
  const d=Number.isInteger(direction)&&direction>=0&&direction<4?direction:0;
  const index=d+(moving&&Math.floor(Math.max(0,time)/170)%2?4:0),f=actor.frames[index];
  return f?{actor,frame:f,index}:null;
 }
 function draw(g,images,name,x,y,height,{direction=0,moving=false,time=0}={}){
  const selected=frame(name,direction,moving,time);if(!selected)return false;
  const {actor,frame:f}=selected,image=images.get('world-npc-'+actor.id);if(!image)return false;
  const b=f.bounds,anchor=f.footAnchor||{x:b.x+b.w/2,y:b.y+b.h},scale=height/actor.referenceHeight;
  g.save();g.imageSmoothingEnabled=false;
  g.drawImage(image,f.x,f.y,f.w,f.h,x-anchor.x*scale,y-anchor.y*scale,f.w*scale,f.h*scale);
  g.restore();return true;
 }
 return {get,facing,frame,draw};
}

// Companion direction follows its own travelled segment, including corners.
// It must not turn early just because the protagonist already turned ahead.
export function worldCompanionMotion(previous,point,fallbackDirection=0){
 const dx=previous?point.x-previous.x:0,dy=previous?point.y-previous.y:0,moving=Math.hypot(dx,dy)>.01;
 const direction=moving?(Math.abs(dx)>Math.abs(dy)?dx<0?1:2:dy<0?3:0):(previous?.direction??fallbackDirection);
 return {x:point.x,y:point.y,direction,moving};
}

export function createWorldCompanions(config={}){
 const species=config.species||{},basics=config.basics||[];
 function get(model={}){return species[model.soul||basics[model.color]]||null;}
 function frame(model,direction=0,moving=false,time=0){
  const actor=get(model);if(!actor)return null;
  const d=Number.isInteger(direction)&&direction>=0&&direction<4?direction:0;
  const sequence=actor.animations[moving?'move':'idle'][d],index=sequence[Math.floor(Math.max(0,time)/(actor.frameMs||180))%sequence.length];
  return {actor,frame:actor.frames[index],index};
 }
 function draw(g,images,model,x,y,height,options={}){
  const selected=frame(model,options.direction,options.moving,options.time);if(!selected)return false;
  const {actor,frame:f}=selected,image=images.get('world-companion-'+actor.id);if(!image)return false;
  const scale=height*(actor.scale||1)/actor.referenceHeight;
  g.save();try{g.imageSmoothingEnabled=false;g.drawImage(image,f.x,f.y,f.w,f.h,x-f.footAnchor.x*scale,y-f.footAnchor.y*scale,f.w*scale,f.h*scale);}finally{g.restore();}
  return true;
 }
 return {get,frame,draw};
}
