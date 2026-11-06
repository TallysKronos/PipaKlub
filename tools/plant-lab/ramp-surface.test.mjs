import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {rampSpan,rampSurface} from './ramp-surface.mjs';
import {samplePlan} from './terrain-raster.mjs';
import {terrainHeight} from './terrain-field.mjs';
import {moveOnTerrain} from './terrain.mjs';
const a=JSON.parse(fs.readFileSync(new URL('../../documentation/plant-lab-v1/cases/ramp-user-2026-11-06.json',import.meta.url)));
test('wide ramp has shoulders only at its outer edges',()=>{
 const i=5*a.width+5;assert.deepEqual(rampSpan(a,i),{left:160,width:64});assert.deepEqual(rampSpan(a,i+1),rampSpan(a,i));
 const c=0xffaabbcc;assert.equal(rampSurface(c,31,16,64),rampSurface(c,32,16,64));assert.notEqual(rampSurface(c,0,16,64),rampSurface(c,31,16,64));
});
test('every ramp pixel in the user map remains exposed walking surface, without a wall crossing',()=>{
 for(let i=0;i<a.ramps.length;i++)if(a.ramps[i]){const x=i%a.width*32,y=Math.floor(i/a.width)*32;
  for(let dx=0;dx<32;dx++)for(let dy=0;dy<32;dy++){const p={x:x+dx+.5,y:y+dy+.5},z=terrainHeight(a,p.x,p.y);assert.equal(samplePlan(a,{x:p.x,y:p.y-z*16}).kind,'top',`${i}:${dx},${dy}`);}
  for(const dx of [4,16,28]){const p={x:x+dx,y:y+47},q=moveOnTerrain(a,p,{x:0,y:-62});assert.equal(q.y,p.y-62);const back=moveOnTerrain(a,q,{x:0,y:62});assert.equal(back.y,p.y);}
 }
});
