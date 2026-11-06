import test from 'node:test';import assert from 'node:assert/strict';
import {cellOnLevel,pointOnLevel,focusAllows,protectedChange} from './level-focus.mjs';
import {initialLayout,validateLayout} from './model.mjs';import {geometryEdit} from './geometry-edit.mjs';import {materialPreview} from './brush-preview.mjs';import {paintFaces} from './wall-kit.mjs';import {paintTrees} from './trees.mjs';
const focus=level=>({enabled:true,locked:true,level});
test('focus allows ramp endpoints, while disabled or unlocked focus remains unrestricted',()=>{
 const a=initialLayout(),i=7*a.width+5;assert(cellOnLevel(a,i,0));assert(cellOnLevel(a,i,1));assert(!cellOnLevel(a,i,2));assert(pointOnLevel(a,{x:176,y:240},0));assert(pointOnLevel(a,{x:176,y:240},1));
 assert(!focusAllows(a,0,focus(2)));assert(focusAllows(a,0,{enabled:false,locked:true,level:2}));assert(focusAllows(a,0,{enabled:true,locked:false,level:2}));
});
test('large wall and forest brushes cannot edit protected storeys',()=>{
 const a=initialLayout();a.objects=[];const i=6*a.width+3,old=structuredClone(a);paintFaces(a,i,4,'face-tijolos',1);
 for(let j=0;j<a.cliffs.length;j++)if(a.cliffs[j]!==old.cliffs[j])assert(cellOnLevel(old,j,1));
 paintTrees(a,i,4,false,'arvore-kronasta',1);assert(a.objects.length>0);for(const o of a.objects)assert(pointOnLevel(a,o,1));
 assert.equal(protectedChange(old,a,focus(1)),null);
});
test('height edits clip their footprint and reject targets on another protected storey',()=>{
 const a=initialLayout(),i=6*a.width+3,e=geometryEdit(a,{tool:'height',cell:i,size:4,mode:'raise',focus:focus(1)});
 assert(e.valid);for(let j=0;j<a.levels.length;j++)if(e.next.levels[j]!==a.levels[j])assert(cellOnLevel(a,j,1));
 const b=initialLayout(),cell=4*b.width+5,blocked=geometryEdit(b,{tool:'height',cell,level:12,focus:focus(0)});assert(!blocked.valid);assert.match(blocked.message,/andar/);assert.deepEqual(b,initialLayout());
});
test('ramp creation under focus preserves the protected upper landing material',()=>{
 const a=initialLayout(),cell=7*a.width+5;a.ramps[cell]=null;a.ramps[cell+1]=null;a.floors[cell-a.width]='grass';
 const e=geometryEdit(a,{tool:'ramp',cell,focus:focus(0)});assert(e.valid);assert.equal(e.next.floors[cell-a.width],'grass');assert.equal(e.next.ramps[cell],'n');assert.deepEqual(validateLayout(e.next),e.next);assert.equal(protectedChange(a,e.next,focus(0)),null);
});
test('material preview rejects protected targets and clips wall footprints exactly like painting',()=>{
 const a=initialLayout(),saved=JSON.stringify(a);assert.equal(materialPreview(a,{tool:'floor',cell:0,material:'dirt',focus:focus(2)}).valid,false);
 const p=materialPreview(a,{tool:'face',kind:'face',cell:6*a.width+3,size:4,material:'face-tijolos',focus:focus(1)});assert(p.valid);assert(p.cells.every(i=>cellOnLevel(a,i,1)));assert.equal(JSON.stringify(a),saved);
});
