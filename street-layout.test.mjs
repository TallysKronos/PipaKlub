import test from 'node:test';
import assert from 'node:assert/strict';
import {STREET_LAYOUT as plan,streetMap,streetObjects} from './src/street-layout.js';
import {parseWorldMap} from './src/world-map.js';
import {createWorldNavigation} from './src/world-navigation.js';
import {createVillageIsometricRenderer} from './src/village-isometric.js';
import * as model from './tools/soulgen-studio/model.mjs';

const scene=parseWorldMap(streetMap());
test('the broader street has continuous lanes, separated porches and room to cross with a partner',()=>{
 const nav=createWorldNavigation(scene),r=plan.road;
 assert.equal(scene.actorSize,100);assert.ok(r.h>=3*scene.actorSize);
 for(let x=r.x+16;x<r.x+r.w-16;x+=32)for(let y=r.y+16;y<r.y+r.h-16;y+=32)assert.ok(nav.geometry.safe({x,y}));
 for(let i=1;i<plan.houses.length;i++)assert.ok(plan.houses[i].x-plan.houses[i-1].x>800);
 for(const h of plan.houses){const door=scene.places.find(p=>p.target===h.target),point=nav.nodes[door.node];assert.ok(Math.abs(point.x-h.x)<=16);assert.ok(Math.abs(point.y-h.y-48)<=16);assert.ok(nav.geometry.segment(point,{x:point.x,y:plan.road.y+32}));}
});
test('every service and return portal remains reachable with a safe follower throughout the route',()=>{
 const nav=createWorldNavigation(scene);
 for(const from of scene.places)for(const to of scene.places){const a=nav.create();nav.target(a,nav.nodes[from.node],true);assert.ok(nav.target(a,nav.nodes[to.node]).length);
  for(let steps=0;a.path.length&&steps<4000;steps++){nav.step(a,.1);assert.ok(nav.geometry.safe(a));assert.ok(nav.geometry.safe(nav.follower(a,74)));}
  assert.equal(a.path.length,0);assert.ok(nav.distance(a,nav.nodes[to.node])<1);
 }
});
test('street fixtures have physical support; destinations stay outside benches and tables',()=>{
 const nav=createWorldNavigation(scene);
 for(const s of scene.tiled.layers.Solids)assert.equal(nav.geometry.safe({x:s.x+s.w/2,y:s.y+s.h/2}),false);
 for(const p of scene.places)assert.ok(nav.geometry.safe(nav.nodes[p.node]));
 assert.deepEqual(scene.places.map(p=>p.id),['tiled-11','tiled-12','tiled-13','tiled-14','tiled-15','tiled-16','tiled-17','tiled-150']);
 const props=streetObjects();for(const h of plan.houses)assert.ok(props.some(o=>o.target===h.target&&o.x===h.x&&o.y===h.y));
});
test('street camera follows the player instead of shrinking the whole expanded neighborhood',()=>{
 const ctx=new Proxy({canvas:{width:1280,height:720}},{get:(o,k)=>k in o?o[k]:()=>{}}),canvas=()=>({getContext:()=>ctx});
 const r=createVillageIsometricRenderer({...scene,village:'quintal'},{},{images:{},rigs:{}},model,canvas);
 for(const [w,h]of [[1280,720],[825,885],[390,700]]){const a=r.camera({x:480,y:768},w,h),b=r.camera({x:2240,y:768},w,h);assert.equal(a.scale,b.scale);assert.ok(a.scale>=.52);assert.ok(b.x>a.x+1000);
  const p=r.project({x:2240,y:768}),back=r.unproject(p);assert.ok(Math.hypot(back.x-2240,back.y-768)<1e-7);assert.ok((p.x-b.x)*b.scale>0&&(p.x-b.x)*b.scale<w);assert.ok((p.y-b.y)*b.scale>0&&(p.y-b.y)*b.scale<h);
 }
});
