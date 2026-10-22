import {clone,identity,sample} from './model.mjs';

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
