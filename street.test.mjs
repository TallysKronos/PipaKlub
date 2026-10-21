import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {artConfig} from './scripts/art-build.mjs';
import {createWorldNavigation} from './src/world-navigation.js';
const config=artConfig(),world=config.courtyard.world;
test('street and all three buildings form a reciprocal, reachable portal graph',()=>{
 const ids=['quintal','kael-home','kael-bedroom','kite-shop','professor-home'];
 for(const id of ids){const scene=world.scenes[id],nav=createWorldNavigation(scene),actor=nav.create();assert.ok(scene.painted,id);for(const place of scene.places){assert.ok(nav.target(actor,nav.nodes[place.node]).length,id+': '+place.name);if(place.action==='street_scene'){assert.ok(ids.includes(place.target));assert.ok(world.scenes[place.target].places.some(p=>p.action==='street_scene'&&p.target===id),id+' return');}}}
});
test('building roofs, beds and shop counters cannot be walked through',()=>{
 for(const [id,points]of Object.entries({quintal:[[240,240],[752,240],[1168,320],[560,400]],'kite-shop':[[752,256],[1360,512]],'professor-home':[[1104,304],[592,256]],'kael-bedroom':[[240,512],[1152,320]]})){const g=createWorldNavigation(world.scenes[id]).geometry;for(const [x,y]of points)assert.equal(g.safe({x,y}),false,id+' '+x+','+y);}
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
