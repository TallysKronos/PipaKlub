import test from 'node:test';
import assert from 'node:assert/strict';
import {initialLayout} from './model.mjs';
import {forestSample} from './forest-sample.mjs';
import {rasterPlan,reliefRim,samplePlan} from './terrain-raster.mjs';
import {terrainHeight} from './terrain-field.mjs';
test('exposed high edges have an outline and inner lip, including north and both sides',()=>{
 const w=10,h=10,a=new Float32Array(w*h);for(let y=2;y<=7;y++)for(let x=2;x<=7;x++)a[y*w+x]=2;
 for(const p of [[4,2],[2,4],[7,4],[4,7]])assert.equal(reliefRim(a,w,h,...p),1);
 for(const p of [[4,3],[3,4],[6,4],[4,6]])assert.equal(reliefRim(a,w,h,...p),2);
 assert.equal(reliefRim(a,w,h,4,4),0);assert.equal(reliefRim(a,w,h,1,4),0);
 // A continuous slope and its landings must not acquire a transverse rim.
 for(let y=0;y<h;y++)for(let x=0;x<w;x++)a[y*w+x]=Math.max(0,Math.min(1,1-(y-2)/4));
 assert.equal(reliefRim(a,w,h,4,5),1); // deliberate coarse discontinuity, > .22 per sample
 for(let y=0;y<h;y++)for(let x=0;x<w;x++)a[y*w+x]=1-y/32;
 for(let y=0;y<h;y++)assert.equal(reliefRim(a,w,h,4,y),0);
});
test('ramp mouths remain unlined and the visual border does not change support or picking',()=>{
 const a=forestSample(initialLayout()),r=rasterPlan(a);
 for(let i=0;i<a.ramps.length;i++)if(a.ramps[i])for(const dy of [.5,16.5,31.5]){
  const x=i%a.width*32+16.5,y=Math.floor(i/a.width)*32+dy,z=terrainHeight(a,x,y);
  assert.equal(reliefRim(r.heights,r.width,r.worldHeight,Math.floor(x),Math.floor(y)),0);
  const hit=samplePlan(a,{x,y:y-z*16});assert.equal(hit.kind,'top');
 }
});
