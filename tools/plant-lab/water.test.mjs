import test from 'node:test';
import assert from 'node:assert/strict';
import {initialLayout,validateLayout} from './model.mjs';
import {waterSample,waterAt,ripplePoints} from './water.mjs';
import {moveOnTerrain} from './terrain.mjs';
import {MASKS,atlas,tile} from './autotile.mjs';
test('water and sand round trip with props; sample supports all map dimensions',()=>{
 const original=initialLayout();for(const [w,h]of [[24,16],[8,8],[40,32]]){const base={...original,width:w,height:h,floors:Array(w*h).fill('grass'),levels:Array(w*h).fill(0),ramps:Array(w*h).fill(null),cliffs:Array(w*h).fill('earth')},a=waterSample(base);assert.deepEqual(validateLayout(a),a);assert(a.floors.includes('water'));assert(a.floors.includes('sand'));}assert(!original.floors.includes('water'));
});
test('shore blocks walking into actual water, permits leaving an accidentally submerged spawn',()=>{
 const a=waterSample(initialLayout()),p=moveOnTerrain(a,a.player,{x:0,y:-350});assert(!waterAt(a,p.x,p.y));assert(p.y>200);const q=moveOnTerrain(a,{x:400,y:250},{x:0,y:250});assert(!waterAt(a,q.x,q.y));
});
test('ripples animate inside water only, and both new terrain atlases cover all 47 masks',()=>{
 const a=waterSample(initialLayout()),p0=ripplePoints(a,0),p1=ripplePoints(a,1);assert.notDeepEqual(p0,p1);assert(p0.length>100);for(const p of p0)assert(waterAt(a,p.x,p.y));for(const k of ['water','sand']){assert.equal(atlas(k).width,256);for(const mask of MASKS)assert(tile(k,mask).every(c=>(c>>>24)===255));}
});
