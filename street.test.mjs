import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {artConfig} from './scripts/art-build.mjs';
import {createWorldNavigation} from './src/world-navigation.js';
import {worldRenderQueue,drawWorldObject} from './src/world-map.js';
const config=artConfig(),world=config.courtyard.world;
test('street and all three buildings form a reciprocal, reachable portal graph',()=>{
 const ids=['quintal','kael-home','kael-bedroom','kite-shop','professor-home'];
 for(const id of ids){const scene=world.scenes[id],nav=createWorldNavigation(scene),actor=nav.create();assert.ok(scene.painted,id);for(const place of scene.places){assert.ok(nav.target(actor,nav.nodes[place.node]).length,id+': '+place.name);if(place.action==='street_scene'){assert.ok(ids.includes(place.target));assert.ok(world.scenes[place.target].places.some(p=>p.action==='street_scene'&&p.target===id),id+' return');}}}
});
test('building roofs, beds and shop counters cannot be walked through',()=>{
 for(const [id,points]of Object.entries({quintal:[[240,240],[752,240],[1168,320],[560,400]],'kite-shop':[[752,256],[1360,512]],'professor-home':[[1104,304],[592,256]],'kael-bedroom':[[240,512],[1152,320]]})){const g=createWorldNavigation(world.scenes[id]).geometry;for(const [x,y]of points)assert.equal(g.safe({x,y}),false,id+' '+x+','+y);}
});

test('painted stair planter remains solid without painting a block over the illustration',()=>{
 const scene=world.scenes['kael-home'],nav=createWorldNavigation(scene);
 assert.equal(nav.geometry.safe({x:1328,y:656}),false);
 const entry=worldRenderQueue(scene,[]).find(e=>e.rect?.name==='Vaso ao lado da escada');
 assert.ok(entry);
 const calls=[];
 drawWorldObject(new Proxy({},{get:(_,name)=>(...args)=>calls.push([name,...args])}),entry,new Map());
 assert.deepEqual(calls,[]);
});

test('every street interior destination can be reached from every arrival, with safe movement and a safe follower',()=>{
 for(const id of Object.keys(world.street.scenes)){
  const scene=world.scenes[id],nav=createWorldNavigation(scene);
  for(const from of scene.places)for(const to of scene.places){
   const actor=nav.create();nav.target(actor,nav.nodes[from.node],true);
   assert.ok(nav.target(actor,nav.nodes[to.node]).length,id+': '+from.name+' -> '+to.name);
   let steps=0;
   while(actor.path.length&&steps++<3000){
    nav.step(actor,.1);
    assert.ok(nav.geometry.safe(actor),id+' actor');
    assert.ok(nav.geometry.safe(nav.follower(actor)),id+' follower');
   }
   assert.equal(actor.path.length,0,id+' arrived');
   assert.ok(nav.distance(actor,nav.nodes[to.node])<1,id+' correct destination');
  }
 }
});
test('existing hub services have distinct physical destinations',()=>{
 const street=world.scenes.quintal;assert.equal(street.places.filter(p=>p.action==='street_scene').length,3);
 for(const action of ['friends','trades','collection','city'])assert.ok(street.places.some(p=>p.action===action));
 for(const action of ['professor','school','dex','summon'])assert.ok(world.scenes['professor-home'].places.some(p=>p.action===action));
 assert.ok(world.scenes['kite-shop'].places.some(p=>p.action==='shop'));
 assert.equal(world.actors.characters.mother.frames.length,8);
});
test('street backgrounds are registered, dimensioned and copied into the public build',()=>{
 for(const sheet of Object.values(world.street.sheets)){const bytes=fs.readFileSync('assets/'+sheet.image);assert.equal(bytes.readUInt32BE(16),sheet.width);assert.equal(bytes.readUInt32BE(20),sheet.height);assert.ok(fs.existsSync('docs/assets/'+sheet.image));}
});
