import {rampValid,rampPoint} from './ramp-rules.mjs';
import {surfaceSupport} from './terrain-field.mjs';
import {isTree} from './nature-kit.mjs';
import {supportHeight} from './autotile.mjs';
import {rasterPlan,samplePlan,occlusionRects,RASTER_PAD} from './terrain-raster.mjs';
import {TILE,floorCell,MAX_LEVEL} from './model.mjs';
import {waterAt} from './water.mjs';
export {MAX_LEVEL};
export const RISE=16,PAD=RASTER_PAD;
export const heightAt=supportHeight;
export function project(a,p){return {x:p.x,y:p.y-heightAt(a,p.x,p.y)*RISE};}
export function topRect(a,i){const y=Math.floor(i/a.width),d=a.ramps[i],h=a.levels[i];return {x:i%a.width*TILE,y:y*TILE-(h+Number(!!d&&d!=='s'))*RISE,w:TILE,h:d==='s'?16:d?48:32};}
export function faceRect(a,i){const row=Math.floor(i/a.width),front=(row+1)*TILE,high=a.levels[i],j=i+a.width,low=j<a.levels.length?a.levels[j]+Number(!!a.ramps[j]):0;if(high<=low)return null;return {x:i%a.width*TILE,y:front-high*RISE,w:TILE,h:(high-low)*RISE,high,low,depth:front,material:a.cliffs[i],i};}
export const contains=(r,p)=>p.x>=r.x&&p.y>=r.y&&p.x<r.x+r.w&&p.y<r.y+r.h;
export function pickTerrain(a,p){const hit=samplePlan(a,p);if(!hit)return null;const row=Math.floor(hit.cell/a.width),r=topRect(a,hit.cell);let y;if(hit.kind==='face')y=hit.depth-.01;else if(a.ramps[hit.cell])y=rampPoint(a,hit.cell,p).y;else y=p.y+hit.z*RISE;return {...hit,point:{x:p.x,y}};}
export function pickSupport(a,p,level){const candidates=[],flat={x:p.x,y:p.y+level*RISE},i=floorCell(a,flat.x,flat.y);if(i>=0&&!a.ramps[i]&&Math.abs(heightAt(a,flat.x,flat.y)-level)<.001)candidates.push({kind:'top',cell:surfaceSupport(a,flat.x,flat.y,level),point:flat});for(let j=0;j<a.ramps.length;j++)if(a.ramps[j]&&a.levels[j]===level){const r=topRect(a,j);if(contains(r,p))candidates.push({kind:'top',cell:j,point:rampPoint(a,j,p)});}return candidates.sort((a,b)=>b.point.y-a.point.y)[0]??null;}
export const validRamp=rampValid;
export function cleanRamps(a){for(let i=0;i<a.ramps.length;i++)if(a.ramps[i]&&!validRamp(a,i))a.ramps[i]=null;}
export function moveOnTerrain(a,p,delta){let out={...p};const steps=Math.max(1,Math.ceil(Math.hypot(delta.x,delta.y)/2)),dx=delta.x/steps,dy=delta.y/steps;
  const next=(x,y)=>({x:Math.max(1,Math.min(a.width*TILE-1,x)),y:Math.max(1,Math.min(a.height*TILE-1,y))});
  const allowed=(from,to)=>Math.abs(heightAt(a,from.x,from.y)-heightAt(a,to.x,to.y))<.22&&(!waterAt(a,to.x,to.y)||waterAt(a,from.x,from.y));
  for(let i=0;i<steps;i++){let q=next(out.x+dx,out.y+dy);if(allowed(out,q))out=q;else{q=next(out.x+dx,out.y);if(allowed(out,q))out=q;q=next(out.x,out.y+dy);if(allowed(out,q))out=q;}}return out;
}
const OCCLUSION_CACHE=new WeakMap();
export function occluders(a,o){const raster=rasterPlan(a);let cache=OCCLUSION_CACHE.get(raster);if(!cache){cache=new Map();OCCLUSION_CACHE.set(raster,cache);}const key=[o.asset,o.x,o.y].join('/');if(cache.has(key))return cache.get(key);const p=project(a,o),kael=o.asset==='kael',custom=a.customAssets?.find(n=>n.id===o.asset);const result=occlusionRects(a,o,{x:p.x-(custom?custom.anchor[0]:kael?40:32),y:p.y-(custom?custom.anchor[1]:kael?65:isTree(o.asset)?80:52),w:custom?.frameWidth??(kael?80:64),h:custom?.frameHeight??(kael?80:isTree(o.asset)?96:68)});if(cache.size>2048)cache.clear();cache.set(key,result);return result;}
export function isOccluded(a,o,p){const hit=samplePlan(a,p);return !!hit&&hit.depth>o.y+.01&&hit.z>heightAt(a,o.x,o.y)+.001;}
export function hash(x,y){let n=(x*374761393+y*668265263)|0;n=(n^(n>>>13))*1274126177;return (n^(n>>>16))>>>0;}
const LAYER_CANVAS=new Map();
export function paintTerrain(c,a,{floors=true,relief=true}={}){const r=rasterPlan(a,true);c.canvas.width=r.width;c.canvas.height=r.height;c.imageSmoothingEnabled=false;for(const [id,data,enabled]of [['top',r.top,floors],['faces',r.faces,relief],['shadow',r.shadow,relief]]){if(!enabled)continue;let canvas=LAYER_CANVAS.get(id);if(!canvas){canvas=document.createElement('canvas');LAYER_CANVAS.set(id,canvas);}canvas.width=r.width;canvas.height=r.height;const g=canvas.getContext('2d'),im=g.createImageData(r.width,r.height);im.data.set(new Uint8Array(data.buffer));g.putImageData(im,0,0);c.drawImage(canvas,0,0);}}
