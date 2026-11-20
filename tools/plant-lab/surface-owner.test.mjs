import test from 'node:test';
import assert from 'node:assert/strict';
import {initialLayout} from './model.mjs';
import {rasterPlan,reliefRim} from './terrain-raster.mjs';
import {tile,variantFor,pack} from './autotile.mjs';
import {GROUND_COLORS} from './ground-data.mjs';

export function cornerFixture(){
 const a=initialLayout();a.objects=[];a.levels.fill(0);a.ramps.fill(null);a.floors.fill('grass');
 for(let y=4;y<=11;y++)for(let x=5;x<=16;x++)if((y>=7&&y<=8)||(x>=10&&x<=11))a.levels[y*a.width+x]=3;
 return a;
}
test('rounded convex and concave tops paint fully without changing any visible lower floor',()=>{
 const a=cornerFixture(),before=rasterPlan(a),b=structuredClone(a),material='chao-calcamento';
 b.floors=b.floors.map((k,i)=>b.levels[i]===3?material:k);const after=rasterPlan(b);let expanded=0,clipped=0,high=0;
 for(let n=0;n<after.top.length;n++){
  if(after.owner[n]<0||after.kind[n])continue;
  const x=n%after.width,sy=Math.floor(n/after.width)-after.pad,z=after.zmap[n],y=sy+z*16;
  const raw=Math.floor(y/32)*a.width+Math.floor(x/32);
  if(z===0){assert.equal(after.top[n],before.top[n],`Lower floor leaked at ${x},${sy}`);if(a.levels[raw]>0)clipped++;}
  if(z===3){
   assert.equal(b.levels[after.owner[n]],3,'Picking must select the elevated donor');
   if(a.levels[raw]===0)expanded++;
   const rim=reliefRim(after.heights,after.width,after.worldHeight,x,y),i=after.owner[n];
   const color=rim?pack(GROUND_COLORS[material][rim===1?'dark':'light']):tile(material,255,variantFor(i%a.width,Math.floor(i/a.width)))[y%32*32+x%32];
   assert.equal(after.top[n],color,`Upper corner unpainted at ${x},${y}`);high++;
  }
 }
 assert(expanded>0);assert(clipped>0);assert(high>1000);
});
