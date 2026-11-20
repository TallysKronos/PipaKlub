import {terrainHeight} from './terrain-field.mjs';
export function cellOnLevel(a,i,level){return i>=0&&i<a.levels.length&&(a.levels[i]===level||!!a.ramps[i]&&a.levels[i]+1===level);}
export function pointOnLevel(a,p,level){
 if(p.x<0||p.y<0||p.x>=a.width*32||p.y>=a.height*32)return false;
 const i=Math.floor(p.y/32)*a.width+Math.floor(p.x/32);
 return a.ramps[i]?cellOnLevel(a,i,level):Math.abs(terrainHeight(a,p.x,p.y)-level)<.001;
}
export const focusLocked=f=>!!f?.enabled&&!!f?.locked;
export const focusAllows=(a,i,f)=>!focusLocked(f)||cellOnLevel(a,i,f.level);
export function protectedChange(a,next,f){
 if(!focusLocked(f))return null;
 for(let i=0;i<a.levels.length;i++)if(!cellOnLevel(a,i,f.level)&&['levels','floors','cliffs','ramps'].some(k=>a[k][i]!==next[k][i]))return 'Alteração alcançaria o andar '+a.levels[i]+'. Destrave o foco ou escolha esse andar.';
 return null;
}
