import test from 'node:test';import assert from 'node:assert/strict';
import {materialPreview} from './brush-preview.mjs';import {initialLayout} from './model.mjs';import {wallSample,paintFaces} from './wall-kit.mjs';import {rasterPlan} from './terrain-raster.mjs';import {floorBrushCells,fillFloor} from './studio.mjs';
test('material previews match committed pixels including rounded edges, ramps and neighboring transitions',()=>{
 for(const a of [initialLayout(),wallSample(initialLayout())])for(const cell of [a.ramps.findIndex(Boolean),5*a.width+2,4*a.width+5].filter(i=>i>=0))for(const tool of ['floor','fill','face']){
  const before=JSON.stringify(a),material=tool==='face'?'face-tijolos':'chao-calcamento',preview=materialPreview(a,{tool,cell,size:3,material,kind:tool==='face'?'face':'top'});
  assert.equal(JSON.stringify(a),before);if(!preview.valid)continue;
  const next=structuredClone(a);if(tool==='face')paintFaces(next,cell,3,material);else if(tool==='fill')fillFloor(next,cell,material);else for(const i of floorBrushCells(next,cell,3))next.floors[i]=material;
  const old=rasterPlan(a),committed=rasterPlan(next);
  for(let n=0;n<preview.data.length;n++){
   const expected=committed.kind[n]?committed.faces[n]:committed.top[n],original=old.kind[n]?old.faces[n]:old.top[n];
   if(expected!==original)assert.equal(preview.data[n],expected,`Missing preview pixel ${tool}/${cell}/${n}`);
   if(preview.data[n])assert.equal(preview.data[n],expected);
  }
 }
});
test('invalid previews explain face targeting and protected storeys without modifying history or layout',()=>{
 const a=initialLayout(),before=JSON.stringify(a);
 assert.equal(materialPreview(a,{tool:'face',cell:0,material:'earth',kind:'top'}).valid,false);
 assert.match(materialPreview(a,{tool:'floor',cell:0,material:'dirt',level:5}).message,/cota 5/);
 assert.equal(materialPreview(a,{tool:'floor',cell:-1,material:'dirt'}).valid,false);assert.equal(JSON.stringify(a),before);
});
