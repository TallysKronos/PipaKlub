import test from 'node:test';
import assert from 'node:assert/strict';
import {initialLayout} from './model.mjs';
import {floorBrushCells,fillFloor} from './studio.mjs';
import {materialMask,shape,tile,cliffPixel,pack} from './autotile.mjs';
import {rasterPlan} from './terrain-raster.mjs';

test('floor brush stays on its initial storey across large footprints and drag anchors',()=>{
 const a=initialLayout();a.levels.fill(0);a.ramps.fill(null);
 const high=5*a.width+5;a.levels[high]=3;a.levels[high+1]=3;
 for(const size of [1,2,4]){
  assert(floorBrushCells(a,high,size,3).every(i=>a.levels[i]===3));
  assert.deepEqual(floorBrushCells(a,high+a.width,size,3),[]);
  assert(floorBrushCells(a,high+a.width,size,0).length>0);
 }
 assert.deepEqual(floorBrushCells(a,high,4),[high,high+1]);
});
test('ramp painting and fill stop at the ramp edge with brushes from 1 to 4',()=>{
 const a=initialLayout(),i=7*a.width+5;a.floors.fill('grass');
 for(const size of [1,2,3,4]){assert.deepEqual(floorBrushCells(a,i,size),size===1?[i]:[i,i+1]);assert.deepEqual(floorBrushCells(a,i+1,size),[i+1]);}
 assert.equal(fillFloor(a,i,'dirt'),2);assert.equal(a.floors[i-1],'grass');assert.equal(a.floors[i+a.width],'grass');
});
test('grass beside a painted ramp stays grass to its physical edge; normal paths retain organic transitions',()=>{
 const a=initialLayout();a.floors.fill('grass');const i=7*a.width+5;a.floors[i]='dirt';a.floors[i+1]='dirt';
 const left=i-1,right=i+2;
 assert(shape(materialMask(a,left))[16*32+31]);assert(shape(materialMask(a,right))[16*32]);
 assert.equal(tile('grass',materialMask(a,left))[16*32+31],tile('grass',255)[16*32+31]);
 a.ramps[i]=null;a.ramps[i+1]=null;assert.equal(shape(materialMask(a,left))[16*32+31],0);
});
test('a tall earth wall has no repeated storey stripe or internal grass lip',()=>{
 const a=initialLayout();a.levels.fill(0);a.ramps.fill(null);a.floors.fill('grass');
 for(let y=3;y<=7;y++)for(let x=3;x<=8;x++)a.levels[y*a.width+x]=3;
 const r=rasterPlan(a),x=176,faces=[];for(let y=0;y<r.height;y++)if(r.faces[y*r.width+x])faces.push(r.faces[y*r.width+x]);
 assert.equal(faces.length,48);assert.equal(faces.filter(c=>c===pack('496c35')).length,1);
 for(const z of [16,32,48]){const row=Array.from({length:64},(_,x)=>cliffPixel('earth',x,z));assert(row.includes(pack('977248')));assert(!row.includes(pack('765738')));assert(!row.includes(pack('b38d58')));}
});
