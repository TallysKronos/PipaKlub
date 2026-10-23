import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {artConfig} from './scripts/art-build.mjs';
import {createAssetHandler} from './src/static-assets.js';
import {createWorldNavigation} from './src/world-navigation.js';
import {createParkIsometricRenderer} from './src/park-isometric-renderer.js';
import {toIso,isometricInput} from './src/world-isometric.js';
import * as model from './tools/soulgen-studio/model.mjs';
const config=artConfig().courtyard;
test('screen controls preserve direction and constant walking speed, including analog input',()=>{
 for(const p of [{x:1,y:0},{x:0,y:1},{x:-1,y:-1},{x:.5,y:0}]){
  const v=isometricInput(p),screen=toIso(v);assert.ok(Math.abs(Math.hypot(v.x,v.y)-Math.min(1,Math.hypot(p.x,p.y)))<1e-9);
  assert.ok(Math.abs(screen.x*p.y-screen.y*p.x)<1e-9);
 }
 assert.deepEqual(isometricInput({x:0,y:0}),{x:0,y:0});
});
test('both production parks keep authenticated encounter identities, safe destinations and exits',()=>{
 for(const id of ['park-trail','park-clearing']){
  const scene=config.world.scenes[id],nav=createWorldNavigation(scene),actor=nav.create();assert.equal(scene.isometric,true);
  const before=JSON.parse(fs.readFileSync('assets/world/park-v1/'+id+'.tmj')).layers.find(l=>l.name==='Walkable').objects;
  assert.equal(scene.tiled.layers.Walkable.filter(r=>r.properties.encounter_zone===id).length,before.filter(r=>r.properties?.some(p=>p.name==='encounter_zone'&&p.value===id)).length);
  for(const place of scene.places){const [x,y]=scene.nodes[place.node];assert.ok(nav.geometry.safe({x,y}),place.name);assert.ok(nav.target(actor,{x,y}).length,place.name);}
  assert.ok(scene.places.some(p=>p.action==='street_scene'&&p.target===(id==='park-trail'?'quintal':'park-trail')));
  assert.ok(scene.places.some(p=>p.action==='wildGuide'));assert.ok(scene.places.some(p=>p.action==='wildRest'));assert.ok(scene.places.some(p=>p.action==='parkMap'));
 }
});
test('runtime renderer projects actors once, sorts depth, maps clicks and does not mutate saved positions',()=>{
 const scene=config.world.scenes['park-trail'],pack=config.world.parkIsometric,images=Object.fromEntries(Object.entries(pack.images).map(([id,a])=>[id,{width:a.width,height:a.height}]));
 const calls=[],ctx=new Proxy({canvas:{width:1280,height:720},globalAlpha:1},{get:(o,k)=>k in o?o[k]:k==='measureText'?()=>({width:20}):(...args)=>calls.push([k,...args]),set:(o,k,v)=>(o[k]=v,true)}),createCanvas=()=>({width:1,height:1,getContext:()=>ctx});
 const renderer=createParkIsometricRenderer(scene,images,pack,model,createCanvas),actor={x:224,y:816,path:[],direction:0},before=JSON.stringify(actor),drawn=[];
 renderer.draw(ctx,actor,[{x:actor.x,y:actor.y,type:'player',draw:p=>drawn.push(p)}],{dt:.04});
 assert.deepEqual(drawn,[toIso(actor)]);assert.equal(JSON.stringify(actor),before);
 for(const [width,height]of [[1280,720],[390,700]]){const camera=renderer.camera(actor,width,height),p=toIso(actor),screen={x:(p.x-camera.x)*camera.scale,y:(p.y-camera.y)*camera.scale};/* camera origin is top-left in the game */
  const actual=renderer.unproject({x:screen.x/camera.scale+camera.x,y:screen.y/camera.scale+camera.y});assert.ok(Math.hypot(actual.x-actor.x,actual.y-actor.y)<1e-8);assert.ok(screen.y>0&&screen.y<height);
 }
 const p=toIso({x:320,y:738});assert.equal(renderer.pick({x:p.x,y:p.y-60}),'map');
 assert.ok(calls.some(c=>c[0]==='drawImage'));
});
test('all park PNGs use registered hashed URLs and are served by the real asset handler',async()=>{
 const serve=createAssetHandler();for(const id of Object.keys(config.world.parkIsometric.images)){
  const a=config.images['park-iso-'+id];assert.match(a.url,/\?v=[a-f0-9]{12}$/);const response=await serve(new Request('http://localhost/'+a.url));assert.equal(response.status,200);assert.equal(response.headers.get('content-type'),'image/png');
 }
 assert.equal((await serve(new Request('http://localhost/assets/world/park-isometric-v1/manifest.json'))).status,404);
});
