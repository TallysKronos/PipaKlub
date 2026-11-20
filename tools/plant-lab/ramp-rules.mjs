export const RAMP_DIRS={n:[0,-1],s:[0,1],e:[1,0],w:[-1,0]};
export function rampNeighbors(a,i,direction=a.ramps[i]??'n'){const [dx,dy]=RAMP_DIRS[direction]??RAMP_DIRS.n,x=i%a.width,y=Math.floor(i/a.width),index=(xx,yy)=>xx>=0&&yy>=0&&xx<a.width&&yy<a.height?yy*a.width+xx:-1;return {high:index(x+dx,y+dy),low:index(x-dx,y-dy)};}
export function rampValid(a,i,direction=a.ramps[i]??'n'){
 if(i<0||i>=a.levels.length)return false;
 const {high,low}=rampNeighbors(a,i,direction);
 if(high<0||low<0)return false;
 const profile=a.ramps[i]===direction?a.rampProfiles?.[i]:null;
 if(!profile)return a.levels[high]===a.levels[i]+1&&a.levels[low]===a.levels[i]&&!a.ramps[high]&&!a.ramps[low];
 const edge=(neighbor,end)=>{
  if(!a.ramps[neighbor])return a.levels[neighbor];
  if(a.ramps[neighbor]!==direction)return NaN;
  return a.levels[neighbor]+(a.rampProfiles?.[neighbor]??[0,1])[end];
 };
 return Math.abs(edge(low,1)-a.levels[i]-profile[0])<.001
  &&Math.abs(edge(high,0)-a.levels[i]-profile[1])<.001;
}
export function rampRise(direction,x,y){const xx=x%32/32,yy=y%32/32;return direction==='s'?yy:direction==='e'?xx:direction==='w'?1-xx:1-yy;}
export function rampOffset(a,i,x,y){
 const [from,to]=a.rampProfiles?.[i]??[0,1];
 return from+(to-from)*rampRise(a.ramps[i],x,y);
}
export function rampPoint(a,i,p){
 const row=Math.floor(i/a.width)*32,h=a.levels[i],d=a.ramps[i];
 if(d==='e'||d==='w')return {x:p.x,y:p.y+(h+rampOffset(a,i,p.x,0))*16};
 const [from,to]=a.rampProfiles?.[i]??[0,1],rise=to-from;
 return {x:p.x,y:row+(p.y-row+(h+(d==='n'?to:from))*16)/(1+(d==='n'?rise:-rise)*.5)};
}
