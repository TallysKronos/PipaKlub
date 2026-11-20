import test from 'node:test';import assert from 'node:assert/strict';
import {geometryEdit} from './geometry-edit.mjs';import {geometryPreview} from './geometry-preview.mjs';import {initialLayout,validateLayout} from './model.mjs';import {rasterPlan} from './terrain-raster.mjs';import {moveOnTerrain,heightAt} from './terrain.mjs';
test('height preview edits preserve wall/floor materials, clamp levels and respect stroke visits',()=>{
 const a=initialLayout(),cell=4*a.width+4,before=JSON.stringify(a);a.cliffs[cell]='face-tijolos';const snapshot=JSON.stringify(a);
 for(const mode of ['raise','lower','set']){const e=geometryEdit(a,{tool:'height',cell,size:3,mode,level:12});assert(e.valid);assert.deepEqual(e.next.cliffs,a.cliffs);assert.deepEqual(e.next.floors,a.floors);assert.deepEqual(validateLayout(e.next),e.next);assert(e.next.levels.every(z=>z>=0&&z<=12));}
 const e=geometryEdit(a,{tool:'height',cell,mode:'raise',visited:new Set([cell])});assert.equal(e.changed,false);assert.equal(JSON.stringify(a),snapshot);assert.notEqual(before,snapshot);
});
test('ramp preview explains invalid supports, creates a traversable ramp and removes it independently',()=>{
 const a=initialLayout();a.objects=[];const cell=7*a.width+5;a.ramps[cell]=null;a.ramps[cell+1]=null;
 const e=geometryEdit(a,{tool:'ramp',cell});assert(e.valid);assert.equal(e.next.ramps[cell],'n');assert.equal(a.ramps[cell],null);assert.deepEqual(e.next.cliffs,a.cliffs);
 const up=moveOnTerrain(e.next,{x:176,y:280},{x:0,y:-50});assert(heightAt(e.next,up.x,up.y)>0);
 const remove=geometryEdit(e.next,{tool:'ramp',cell,remove:true});assert(remove.valid);assert.equal(remove.next.ramps[cell],null);
 const invalid=geometryEdit(a,{tool:'ramp',cell:12*a.width+10});assert.equal(invalid.valid,false);assert.match(invalid.message,/subida/);
 assert.equal(geometryEdit(a,{tool:'ramp',cell:0}).valid,false);
});
test('volume preview covers every changed top, wall and shadow pixel, without changing the document',()=>{
 for(const options of [{tool:'height',cell:6*24+3,size:2,mode:'raise'},{tool:'height',cell:4*24+4,size:3,mode:'lower'},{tool:'height',cell:4*24+4,size:1,mode:'set',level:0},{tool:'ramp',cell:7*24+5,remove:true}]){
  const a=initialLayout(),saved=JSON.stringify(a),edit=geometryEdit(a,options),preview=geometryPreview(a,options);assert(preview.valid);assert.equal(JSON.stringify(a),saved);
  const old=rasterPlan(a),next=rasterPlan(edit.next);let changed=0;
  for(let n=0;n<next.top.length;n++)if(old.top[n]!==next.top[n]||old.faces[n]!==next.faces[n]||old.shadow[n]!==next.shadow[n]){
   assert(preview.data[n],`Missing changed pixel ${n}`);if(!(next.shadow[n]>>>24))assert.equal(preview.data[n],next.faces[n]||next.top[n]||0xff282e27);changed++;
  }
  assert(changed>0);assert(preview.bounds.width>0);assert(preview.bounds.height>0);
 }
});
test('height preview warns before removing supported ramps and does not commit the repair',()=>{
 const a=initialLayout(),cell=6*a.width+5,e=geometryEdit(a,{tool:'height',cell,mode:'set',level:12});assert.match(e.message,/remove.*rampa/);assert(a.ramps.some(Boolean));assert(e.next.ramps.filter(Boolean).length<a.ramps.filter(Boolean).length);
});
