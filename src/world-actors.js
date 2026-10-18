export function worldPartnerStart(scene,state,follower){
 if(state.actor.history.length>=2)return follower;
 const gap=scene.actorSize*.85,a=state.actor,geometry=state.navigation.geometry;
 const candidates=[{x:a.x+gap,y:a.y+6},{x:a.x-gap,y:a.y+6},{x:a.x,y:a.y+gap},{x:a.x,y:a.y-gap}];
 return candidates.find(p=>geometry?geometry.segment(a,p):p.x>=0&&p.y>=0&&p.x<=scene.width&&p.y<=scene.height)||follower;
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
