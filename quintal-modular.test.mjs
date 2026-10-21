import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {artConfig} from './scripts/art-build.mjs';
import {createWorldGeometry} from './src/world-map.js';
import {createWorldNavigation} from './src/world-navigation.js';
import {createAssetHandler} from './src/static-assets.js';
import {worldPartnerStart} from './src/world-actors.js';
const config=artConfig(),scene=config.courtyard.world.legacyCourtyard;
test('preserved legacy courtyard is a complete editable modular map with the six existing actions',()=>{
 assert.equal(scene.name,'Quintal do Clube');assert.ok(scene.art);assert.ok(scene.tiled);assert.equal(scene.image,undefined);
 assert.equal(scene.overview,true);
 assert.deepEqual(scene.places.map(p=>p.action).sort(),['city','collection','friends','professor','shop','summon']);
 assert.equal(scene.places.some(p=>p.stage),false);
 const project=JSON.parse(fs.readFileSync('assets/world/quintal-modular-v1/project.json'));
 assert.deepEqual(project.kit,scene.art.kit);assert.equal(project.map.layers.length,6);
 assert.ok(scene.tiled.layers.Foreground.some(o=>o.name==='Telhado do clube'));
});
test('all courtyard destinations are reachable, door posts block feet, and professor stands in a safe area',()=>{
 const nav=createWorldNavigation(scene),geometry=createWorldGeometry(scene.tiled),actor=nav.create();
 const follower=worldPartnerStart(scene,{actor,navigation:nav},{x:actor.x,y:actor.y});assert.ok(geometry.segment(actor,follower));assert.ok(Math.hypot(actor.x-follower.x,actor.y-follower.y)>scene.actorSize*.8);
 for(const place of scene.places){const route=nav.target(actor,nav.nodes[place.node]);assert.ok(route.length,place.action);for(let i=1;i<route.length;i++)assert.ok(geometry.segment(route[i-1],route[i]),place.action);}
 assert.equal(geometry.safe({x:640,y:240}),false);assert.equal(geometry.safe({x:800,y:280}),true);assert.equal(geometry.safe({x:320,y:400}),false);
 assert.equal(geometry.safe({x:720,y:248}),false,'open door leaf has its own footprint');
 const p=scene.tiled.properties;assert.ok(geometry.safe({x:p.professor_x,y:p.professor_y}));assert.ok(geometry.safe({x:p.nozinho_x,y:p.nozinho_y}));
 assert.equal(geometry.safe({x:1024,y:544}),false,'lamp base blocks walking');
});
test('all courtyard pieces preserve proportions, fit their original PNGs and are served and copied to Pages',async()=>{
 const kit=scene.art.kit,serve=createAssetHandler();assert.equal(Object.keys(kit.frames).length,39);
 for(const [id,sheet]of Object.entries(kit.sheets)){
  const png=fs.readFileSync('assets/'+sheet.image);assert.equal(png.readUInt32BE(16),sheet.width);assert.equal(png.readUInt32BE(20),sheet.height);
  const asset=config.courtyard.images['world-kit-'+id],response=await serve(new Request('https://local/'+asset.url,{method:'HEAD'}));assert.equal(response.status,200);assert.match(response.headers.get('cache-control'),/immutable/);assert.ok(fs.existsSync('docs/assets/'+sheet.image));
 }
 for(const entry of scene.art.objects){const s=entry.sprite,sheet=kit.sheets[s.sheet];assert.ok(s.sx>=0&&s.sy>=0&&s.sx+s.sw<=sheet.width&&s.sy+s.sh<=sheet.height);assert.ok(Math.abs(s.w/s.h-s.sw/s.sh)<1e-8);}
 assert.equal((await serve(new Request('https://local/assets/world/quintal-kit-v1/manifest.json'))).status,404);
});
