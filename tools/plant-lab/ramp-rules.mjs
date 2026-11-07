export const RAMP_DIRS={n:[0,-1],s:[0,1],e:[1,0],w:[-1,0]};
export function rampNeighbors(a,i,direction=a.ramps[i]??'n'){const [dx,dy]=RAMP_DIRS[direction]??RAMP_DIRS.n,x=i%a.width,y=Math.floor(i/a.width),index=(xx,yy)=>xx>=0&&yy>=0&&xx<a.width&&yy<a.height?yy*a.width+xx:-1;return {high:index(x+dx,y+dy),low:index(x-dx,y-dy)};}
export function rampValid(a,i,direction=a.ramps[i]??'n'){if(i<0||i>=a.levels.length)return false;const {high,low}=rampNeighbors(a,i,direction);return high>=0&&low>=0&&a.levels[high]===a.levels[i]+1&&a.levels[low]===a.levels[i]&&!a.ramps[high]&&!a.ramps[low];}
export function rampRise(direction,x,y){const xx=x%32/32,yy=y%32/32;return direction==='s'?yy:direction==='e'?xx:direction==='w'?1-xx:1-yy;}
export function rampPoint(a,i,p){const row=Math.floor(i/a.width)*32,h=a.levels[i],d=a.ramps[i];if(d==='e'||d==='w')return {x:p.x,y:p.y+(h+rampRise(d,p.x,0))*16};return {x:p.x,y:row+(p.y-row+h*16+(d==='n'?16:0))/(d==='n'?1.5:.5)};}
