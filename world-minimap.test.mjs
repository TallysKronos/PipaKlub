import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorldMinimap} from './src/world-minimap.js';
import {toIso} from './src/world-isometric.js';

const scene={width:1600,height:1200,places:[{id:'bench',node:0},{id:'boss',node:1}],edges:[[0,1]]};
test('exploration reveals only local terrain, retains visited cells and discovers places only at interaction range',()=>{
 const map=createWorldMinimap(scene);
 assert.deepEqual(map.snapshot(),{cells:[],places:[]});
 assert.equal(map.reveal({x:200,y:200},null),true);
 const first=map.snapshot();assert.ok(first.cells.length>0&&first.cells.length<200);assert.deepEqual(first.places,[]);
 assert.equal(map.reveal({x:200,y:200},null),false);
 map.reveal({x:200,y:200},scene.places[0]);assert.deepEqual(map.snapshot().places,['bench']);
 map.reveal({x:1300,y:1000},null);const explored=map.snapshot();assert.ok(first.cells.every(n=>explored.cells.includes(n)));assert.deepEqual(explored.places,['bench']);
 const restored=createWorldMinimap(scene,JSON.parse(JSON.stringify(explored)));assert.deepEqual(restored.snapshot(),explored);
 assert.deepEqual(createWorldMinimap(scene).snapshot(),{cells:[],places:[]},'another account or scene starts undiscovered');
});
test('invalid stored exploration cannot add unknown places or out-of-bounds cells',()=>{
 assert.deepEqual(createWorldMinimap(scene,{cells:[-1,1600,'7',7],places:['boss','unknown']}).snapshot(),{cells:[7],places:['boss']});
 assert.deepEqual(createWorldMinimap(scene,{cells:'bad',places:5}).snapshot(),{cells:[],places:[]});
});
test('isometric map follows screen directions and rebuilds its soft fog only when exploration changes',()=>{
 let gradients=0;
 const context=new Proxy({createRadialGradient(){gradients++;return {addColorStop(){}};}},{get:(o,k)=>k in o?o[k]:()=>{}});
 const map=createWorldMinimap({...scene,isometric:true},{},()=>({getContext:()=>context}));
 assert.deepEqual(map.project({x:80,y:40}),toIso({x:80,y:40}));
 assert.ok(map.project({x:1,y:-1}).x>0);assert.equal(map.project({x:1,y:-1}).y,0,'screen-right movement stays right on the minimap');
 const points=[{x:200,y:200},{x:1300,y:1000}],actor={x:200,y:200};
 map.reveal(actor,null);map.draw(context,actor,points);const first=gradients;
 map.draw(context,actor,points);assert.equal(gradients,first+1,'only the viewport background gradient changes while stationary');
 map.reveal({x:1300,y:1000},null);map.draw(context,{x:1300,y:1000},points);assert.ok(gradients>first+2,'new discoveries rebuild the feathered fog');
});
