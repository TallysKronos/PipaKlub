import {clone,identity,sample,trackAt,CHANNELS} from './model.mjs';

// Editor operations stay separate from the exported animation runtime.
export function adjacentKey(clip,time,direction){
 const times=clip.frames.map(f=>f.t).sort((a,b)=>a-b);
 return direction<0?[...times].reverse().find(t=>t<time-.001)??0:times.find(t=>t>time+.001)??clip.seconds;
}
export function nudgePart(project,id,dx,dy){
 const p=project.parts.find(p=>p.id===id);
 if(!p||p.locked)throw Error('Desbloqueie e selecione uma peça para mover.');
 p.rect[0]+=dx;p.rect[1]+=dy;p.pivot[0]+=dx;p.pivot[1]+=dy;
}
export function copiedPose(project,clipId,time,track,draft){
 return clone((draft||sample(project,clipId,time)).values[track]||identity());
}
export function pastedPose(project,clipId,time,track,values,draft){
 const pose=clone(draft||sample(project,clipId,time));
 pose.values[track]=clone(values);return pose;
}
export function timelineMarks(clip){
 return clip.frames.map(f=>({time:f.t,percent:100*f.t/clip.seconds}));
}
export function visibleProject(project,solo){
 if(!solo)return project;
 return {...project,parts:project.parts.map(p=>({...p,visible:p.id===solo&&p.visible!==false}))};
}
export function opaqueBounds(data,width,height){
 let left=width,top=height,right=-1,bottom=-1;
 for(let y=0;y<height;y++)for(let x=0;x<width;x++)if(data[(y*width+x)*4+3]>0){left=Math.min(left,x);top=Math.min(top,y);right=Math.max(right,x);bottom=Math.max(bottom,y);}
 return right<0?null:[left,top,right-left+1,bottom-top+1];
}
export function trimPart(part,bounds){
 if(part.locked)throw Error('Desbloqueie a peça antes de recortar.');
 if(Object.keys(part.faces||{}).length)throw Error('Peças com expressões registradas precisam manter o recorte canônico.');
 if(!bounds)throw Error('O recorte não contém pixels visíveis.');
 const [x,y,w,h]=bounds,[sx,sy,sw,sh]=part.source,[dx,dy,dw,dh]=part.rect;
 if(x<0||y<0||w<1||h<1||x+w>sw||y+h>sh)throw Error('Limites de recorte inválidos.');
 part.source=[sx+x,sy+y,w,h];part.rect=[dx+x/sw*dw,dy+y/sh*dh,w/sw*dw,h/sh*dh];
}

// Fewest keys that keep every track within tolerance of the current curve (positions in units, rotation in
// degrees, scales as factors). Keys are spline keys; the start, the end and the impact are always kept.
export const SIMPLIFY_TOLERANCE={position:.04,rotation:.15,scale:.004};
export function simplifyClip(project,clipId,tolerance=SIMPLIFY_TOLERANCE){
 const c=project.clips[clipId];if(!c)throw Error('Animação inexistente.');
 // Simplifying again would measure against an already simplified curve and let the error pile up.
 if(c.simplified)return {before:c.frames.length,after:c.frames.length,changed:false};
 const ids=['root',...project.parts.map(p=>p.id)],step=1/120,times=[];for(let t=0;t<c.seconds;t+=step)times.push(Math.round(t*1e6)/1e6);times.push(c.seconds);
 const scaleOf=k=>k==='rotation'?tolerance.rotation:k.startsWith('scale')?tolerance.scale:tolerance.position;
 const target=times.map(t=>Object.fromEntries(ids.map(id=>[id,trackAt(c,id,t)])));
 const fixed=new Set([0,c.seconds]);if(c.hitTime!=null)fixed.add(Math.round(c.hitTime*1000)/1000);const before=c.frames.length;
 const worst=candidate=>{let best=null;times.forEach((t,i)=>{for(const id of ids){const v=trackAt(candidate,id,t);for(const k of CHANNELS){const e=Math.abs(v[k]-target[i][id][k])/scaleOf(k);if(!best||e>best.e)best={e,t};}}});return best;};
 // Try keys that pass through (spline) and keys that settle (smooth); keep whichever needs fewer poses.
 const fit=ease=>{const keyAt=t=>({t,ease,values:Object.fromEntries(ids.map(id=>[id,trackAt(c,id,t)]))});let keys=[...fixed].sort((a,b)=>a-b).map(keyAt);
  for(let guard=0;guard<before;guard++){const w=worst({...c,frames:keys});if(!w||w.e<=1)return keys;const t=Math.round(w.t*1000)/1000;if(keys.some(k=>Math.abs(k.t-t)<.0005))return null;keys=[...keys,keyAt(t)].sort((a,b)=>a.t-b.t);}
  return null;};
 const keys=['spline','smooth'].map(fit).filter(Boolean).sort((a,b)=>a.length-b.length)[0];
 if(!keys||keys.length>=before)return {before,after:before,changed:false};
 c.frames=keys.map(k=>({...k,values:clone(k.values)}));c.simplified=true;return {before,after:keys.length,changed:true};
}
