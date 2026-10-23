// Presentation transform only. Tiled physics and save coordinates remain orthogonal.
export const toIso = ({x,y}) => ({x:(x-y)*.82,y:(x+y)*.41});
export const fromIso = ({x,y}) => ({x:x/1.64+y/.82,y:y/.82-x/1.64});
export function screenToWorld(point,camera,viewport,zoom=1){
 return fromIso({x:(point.x-viewport.width/2)/zoom+camera.x,y:(point.y-viewport.height/2)/zoom+camera.y});
}
export function depthOrder(entries){
 return entries.map((entry,index)=>({...entry,depth:toIso(entry).y,index}))
  .sort((a,b)=>(a.level??0)-(b.level??0)||a.depth-b.depth||a.index-b.index);
}
export function screenDirection(dx,dy){return Math.abs(dx)>Math.abs(dy)?dx<0?1:2:dy<0?3:0;}
