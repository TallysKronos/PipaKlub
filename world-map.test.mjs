import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {parseWorldMap,createWorldGeometry,worldRenderQueue} from './src/world-map.js';
import {createWorldNavigation} from './src/world-navigation.js';
const read=()=>JSON.parse(fs.readFileSync('assets/world/morro-pilot/blockout.tmj','utf8'));
test('Tiled pilot retains encounter identities and all destinations are connected',()=>{
 const scene=parseWorldMap(read()),nav=createWorldNavigation(scene);
 assert.deepEqual(scene.places.filter(p=>p.stage).map(p=>p.stage),['morro-1','morro-2']);
 assert.equal(scene.width,1280);assert.equal(scene.actorSize,64);
 for(const p of scene.places)assert.ok(nav.route(nav.nodes[scene.spawn],nav.nodes[p.node]).length);
});
test('different floors connect exclusively through the authored stair',()=>{
 const s=parseWorldMap(read()),levels=s.tiled.levels,stairs=s.tiled.layers.Walkable.find(r=>r.properties.connects_to===1);
 let transitions=0;for(const [a,b]of s.edges)if(levels[a]!==levels[b]){transitions++;assert.ok([s.nodes[a],s.nodes[b]].some(([x,y])=>x>=stairs.x&&x<=stairs.x+stairs.w&&y>=stairs.y&&y<=stairs.y+stairs.h));}
 assert.ok(transitions>0);
});
test('missing layers, unsupported shapes and duplicate ids fail explicitly',()=>{
 const m=read();m.layers=m.layers.filter(l=>l.name!=='Solids');assert.throws(()=>parseWorldMap(m),/Solids/);
 const n=read();n.layers[0].objects[0].rotation=45;assert.throws(()=>parseWorldMap(n),/retângulos/);
 const d=read();d.layers[0].objects[1].id=d.layers[0].objects[0].id;assert.throws(()=>parseWorldMap(d),/duplicado/);
});
test('unreachable encounters prevent a misleading successful build',()=>{
 const m=read();m.layers.find(l=>l.name==='Walkable').objects=m.layers[0].objects.filter(o=>o.name!=='Escada');
 assert.throws(()=>parseWorldMap(m),/inacessível/);
});
test('invalid geometry, floor connector and scale are rejected',()=>{
 const m=read();m.layers[0].objects[0].width=NaN;assert.throws(()=>parseWorldMap(m),/inválido/);
 const n=read();n.layers[0].objects.find(o=>o.name==='Escada').properties.find(p=>p.name==='connects_to').value=99;assert.throws(()=>parseWorldMap(n),/nível/);
 const p=read();p.properties.find(p=>p.name==='foot_radius').value=32;assert.throws(()=>parseWorldMap(p),/raio/);
});
test('unsupported tilemaps fail instead of silently dropping visual layers',()=>{
 const m=read();m.layers.push({id:99,name:'Paint',type:'tilelayer',data:[]});assert.throws(()=>parseWorldMap(m),/Paint/);
});
test('normal build preserves the complete Morro and embeds a separate pilot',async()=>{
 const {artConfig}=await import('./scripts/art-build.mjs');const c=artConfig();
 assert.equal(c.courtyard.world.scenes.morro.places.filter(p=>p.stage).length,5);
 assert.equal(c.courtyard.world.pilot.places.filter(p=>p.stage).length,2);
});
const r=(x,y,w,h,level=0,extra={})=>({x,y,w,h,properties:{level,...extra}});
const geom=(walk,solids=[])=>createWorldGeometry({layers:{Walkable:walk,Solids:solids},properties:{foot_radius:12}});
test('foot clearance respects narrow passages, borders and the union across seams',()=>{
 const g=geom([r(0,0,64,64),r(64,0,64,64)]);
 assert.ok(g.safe({x:64,y:32}));assert.ok(!g.safe({x:11,y:32}));assert.ok(!geom([r(0,0,20,100)]).safe({x:10,y:50}));
 const gap=geom([r(0,0,64,64),r(65,0,64,64)]);assert.ok(!gap.safe({x:64,y:32}));
});
test('swept feet stop at a thin wall between otherwise safe endpoints',()=>{
 const g=geom([r(0,0,160,96)],[r(79.5,0,.2,96)]),a={x:32,y:48},b={x:128,y:48};
 assert.ok(g.safe(a)&&g.safe(b));assert.ok(!g.segment(a,b));
});
test('stairs attach to north/south floor entrances, not to lateral upper floors',()=>{
 const stair=r(64,64,64,64,0,{connects_to:1}),g=geom([r(64,128,64,64),stair,r(64,0,64,64,1),r(128,64,64,64,1)]);
 assert.ok(g.segment({x:96,y:144},{x:96,y:48}));assert.ok(!g.segment({x:96,y:96},{x:160,y:96}));
});
test('blocked clicks preserve the valid route, while injected wall-crossing steps stop',()=>{
 const scene=parseWorldMap(read()),nav=createWorldNavigation(scene),a=nav.create();
 nav.target(a,nav.nodes[scene.places.find(p=>p.stage==='morro-1').node]);const path=structuredClone(a.path);
 assert.deepEqual(nav.target(a,{x:300,y:450}),[]);assert.deepEqual(a.path,path);assert.match(a.navigationMessage,/bloqueada/);
 a.x=528;a.y=400;a.path=[{x:400,y:400}];for(let i=0;i<100;i++)nav.step(a,.1);
 assert.ok(nav.geometry.safe(a));assert.match(a.navigationMessage,/bloqueado/);
});
test('walking and follower stay safe from spawn through stairs and back',()=>{
 const scene=parseWorldMap(read()),nav=createWorldNavigation(scene),a=nav.create();
 for(const dest of [scene.places.find(p=>p.stage==='morro-2').node,scene.spawn]){
  assert.ok(nav.target(a,nav.nodes[dest]).length);let steps=0;
  while(a.path.length&&steps++<2000){nav.step(a,.1);assert.ok(nav.geometry.safe(a));assert.ok(nav.geometry.safe(nav.follower(a)));}
  assert.ok(steps<2000);assert.deepEqual({x:a.x,y:a.y},nav.nodes[dest]);assert.equal(a.level,dest===scene.spawn?0:1);
 }
});
test('overlapping floors are rejected rather than choosing a floor accidentally',()=>{
 const m=read(),patamar=m.layers[0].objects.find(o=>o.name==='Patamar');patamar.height+=64;
 assert.throws(()=>parseWorldMap(m),/sobrepostos/);
});
test('diagonal shortcuts cannot cut across an L-shaped ground corner',()=>{
 const g=geom([r(0,0,128,64),r(64,64,64,64)]);
 assert.ok(g.safe({x:32,y:32}));assert.ok(g.safe({x:96,y:96}));
 assert.ok(!g.segment({x:32,y:32},{x:96,y:96}));
});
test('a disconnected walkable island cannot be reached by projecting to a nearby edge',()=>{
 const scene=parseWorldMap(read());scene.tiled.layers.Walkable.push(r(1100,400,64,64));
 const nav=createWorldNavigation(scene),a=nav.create(),before={x:a.x,y:a.y};
 assert.deepEqual(nav.target(a,{x:1132,y:432}),[]);assert.match(a.navigationMessage,/caminho/);
 nav.step(a,.1);assert.deepEqual({x:a.x,y:a.y},before);
});
test('canopy and wall hide actors behind their foot anchor and stay behind actors in front',()=>{
 const scene=parseWorldMap(read());
 for(const name of ['Copa oeste','Muro da praca']){
  const object=scene.tiled.layers.Foreground.find(r=>r.name===name),y=object.properties.sort_y;
  const q=worldRenderQueue(scene,[{id:'behind',y:y-20,level:0},{id:'front',y:y+20,level:0}]);
  const index=q.findIndex(e=>e.rect?.id===object.id);
  assert.ok(q.findIndex(e=>e.id==='behind')<index);assert.ok(q.findIndex(e=>e.id==='front')>index);
 }
});
test('a lower-floor roof cannot cover higher-floor actors even if its sort Y is larger',()=>{
 const s=parseWorldMap(read()),q=worldRenderQueue(s,[{id:'kael',y:200,level:1},{id:'partner',y:250,level:0},{id:'bia',y:190,level:1}]);
 const roof=q.findIndex(e=>e.rect?.name==='Cobertura da esquina');
 assert.ok(q.findIndex(e=>e.id==='kael')>roof);assert.ok(q.findIndex(e=>e.id==='bia')>roof);
 assert.ok(q.findIndex(e=>e.id==='partner')<roof);
});
test('render ordering is stable at equal feet positions and does not mutate actor input',()=>{
 const s=parseWorldMap(read()),a=[{id:'kael',y:656,level:0},{id:'partner',y:656,level:0}],before=structuredClone(a),q=worldRenderQueue(s,a);
 const wall=q.findIndex(e=>e.rect?.name==='Muro da praca');assert.ok(q.findIndex(e=>e.id==='kael')>wall);
 assert.deepEqual(q.filter(e=>e.kind==='actor').map(e=>e.id),['kael','partner']);assert.deepEqual(a,before);
 const legacy=worldRenderQueue({},[{id:'north',y:10},{id:'south',y:30}]);assert.deepEqual(legacy.map(e=>e.id),['north','south']);
});
test('visual depth metadata rejects impossible floors and invalid anchors',()=>{
 const m=read();m.layers.find(l=>l.name==='Foreground').objects[0].properties.find(p=>p.name==='level').value=5;
 assert.throws(()=>parseWorldMap(m),/piso visual/);
 const n=read();n.layers.find(l=>l.name==='Foreground').objects[0].properties.find(p=>p.name==='sort_y').value=-5;
 assert.throws(()=>parseWorldMap(n),/sort_y/);
});
test('an occluding upper part fades for the player but never for another floor',()=>{
 const scene=parseWorldMap(read()),actor={id:'player',x:160,y:624,level:0},find=q=>q.find(e=>e.rect?.name==='Copa oeste');
 assert.equal(find(worldRenderQueue(scene,[actor])).opacity,.45);
 assert.equal(find(worldRenderQueue(scene,[{...actor,level:1}])).opacity,1);
 assert.equal(find(worldRenderQueue(scene,[{...actor,y:720}])).opacity,1);
});
