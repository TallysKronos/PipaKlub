import test from 'node:test';import assert from 'node:assert/strict';import {GROUNDS,groundSample,groundBackground} from './ground-kit.mjs';import {GROUND_PIXELS,tile,MASKS,materialMask} from './autotile.mjs';import {initialLayout,validateLayout} from './model.mjs';import {rasterPlan} from './terrain-raster.mjs';
import {wallSample} from './wall-kit.mjs';
import {reliefRim} from './terrain-raster.mjs';
import {variantFor,pack} from './autotile.mjs';
import {GROUND_COLORS} from './ground-data.mjs';
test('raised paving reaches every exposed edge without sampling the grass below',()=>{
 const a=wallSample(initialLayout()),r=rasterPlan(a);let checked=0;
 for(let sy=0;sy<r.height;sy++)for(let x=0;x<r.width;x++){
  const n=sy*r.width+x,i=r.owner[n];if(i<0||r.kind[n]||r.zmap[n]!==4||a.floors[i]!=='chao-ruinas')continue;
  const y=sy-r.pad+64,k=a.floors[i],rim=reliefRim(r.heights,r.width,r.worldHeight,x,y);
  const expected=rim?pack(GROUND_COLORS[k][rim===1?'dark':'light']):tile(k,255,variantFor(i%a.width,Math.floor(i/a.width)))[y%32*32+x%32];
  assert.equal(r.top[n],expected,`Raised edge at ${x},${y}`);assert.equal(materialMask(a,i),255);checked++;
 }
 assert(checked>10000);
 const i=3*a.width+16;assert.equal(groundBackground(a,i,0,0),a.floors[i]);
});
test('28 generated floors have three variants with shared opposing edges',()=>{assert.equal(GROUNDS.length,28);for(const g of GROUNDS){const pixels=GROUND_PIXELS[g.id];assert.equal(pixels.length,3072);for(let v=0;v<3;v++)for(let n=0;n<32;n++){assert.equal(pixels[v*1024+n*32],pixels[v*1024+n*32+31]);assert.equal(pixels[v*1024+n],pixels[v*1024+31*32+n]);assert.equal(pixels[v*1024+n*32],pixels[n*32]);assert.equal(pixels[v*1024+n],pixels[n]);}}});
test('all 47 connections of every new floor are opaque and bounded',()=>{for(const g of GROUNDS)for(const m of MASKS){const p=tile(g.id,m,0);assert.equal(p.length,1024);assert(p.every(c=>(c>>>24)===255));}});
test('adjacent kit materials transition directly without a false grass strip',()=>{const a=initialLayout();a.objects=[];a.levels.fill(0);a.ramps.fill(null);const left=GROUNDS[9].id,right=GROUNDS[18].id;a.floors.fill(left);for(let y=0;y<a.height;y++)for(let x=12;x<a.width;x++)a.floors[y*a.width+x]=right;const i=5*a.width+12;assert.equal(groundBackground(a,i,0,16),left);assert(materialMask(a,i-1)&2);const r=rasterPlan(a),y=5*32+16;assert.equal(r.top[(y+r.pad)*r.width+383],r.top[(y+r.pad)*r.width+384]);});
test('all new materials and the floor display round trip through validated JSON',()=>{const a=groundSample(initialLayout());assert.deepEqual(validateLayout(a),a);for(const g of GROUNDS)assert(a.floors.includes(g.id));});
