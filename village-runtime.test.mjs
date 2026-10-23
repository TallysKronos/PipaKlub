import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {artConfig} from './scripts/art-build.mjs';
import {createAssetHandler} from './src/static-assets.js';
import {createWorldNavigation} from './src/world-navigation.js';
import {createVillageIsometricRenderer,villageSceneIds} from './src/village-isometric.js';
import {toIso} from './src/world-isometric.js';
import * as model from './tools/soulgen-studio/model.mjs';
const config=artConfig().courtyard;

test('all five opening locations keep reachable actions and return doors',()=>{
 for(const id of villageSceneIds){
  const scene=config.world.scenes[id],nav=createWorldNavigation(scene),actor=nav.create();
  assert.equal(scene.isometric,true);assert.equal(scene.village,id);
  for(const place of scene.places){const [x,y]=scene.nodes[place.node];assert.ok(nav.geometry.safe({x,y}),`${id}: ${place.name}`);assert.ok(nav.target(actor,{x,y}).length,`${id}: ${place.name}`);}
  assert.ok(scene.places.some(p=>p.action==='street_scene'));
 }
});

test('opening room cameras, clickable props and NPCs use the same projection without moving saves',()=>{
 const pack={images:{...config.world.parkIsometric.images,...config.world.villageIsometric.images},rigs:config.world.parkIsometric.rigs},images=Object.fromEntries(Object.entries(pack.images).map(([k,a])=>[k,{width:a.width,height:a.height}]));
 const ctx=new Proxy({canvas:{width:1280,height:720}},{get:(o,k)=>k in o?o[k]:()=>{},set:(o,k,v)=>(o[k]=v,true)}),canvas=()=>({getContext:()=>ctx});
 for(const id of villageSceneIds){for(const opening of [false,true]){
  const r=createVillageIsometricRenderer({village:id,opening},images,pack,model,canvas),actor=id==='kael-home'?{x:1008,y:1056,path:[]}:{x:780,y:620,path:[]},before=JSON.stringify(actor),drawn=[];
  r.draw(ctx,actor,[{...actor,action:'professor',draw:p=>drawn.push(p)}],{dt:.04});
  assert.deepEqual(drawn,[r.project(actor)]);assert.equal(JSON.stringify(actor),before);
  const p=r.project(actor);assert.equal(r.pick({x:p.x,y:p.y-50})?.action,'professor');
  for(const [w,h] of [[1280,720],[390,700]]){const c=r.camera(actor,w,h);assert.ok(Number.isFinite(c.scale)&&c.scale>0);const screen={x:(p.x-c.x)*c.scale,y:(p.y-c.y)*c.scale},world=r.unproject({x:screen.x/c.scale+c.x,y:screen.y/c.scale+c.y});assert.ok(Math.hypot(world.x-actor.x,world.y-actor.y)<1e-8);}
  if(id==='kael-bedroom'){for(const name of ['tv','desk','stairs']){const b=r.feature(name);assert.ok(b.w>0&&b.h>0);const hit=r.pick({x:b.x+b.w/2,y:b.y+b.h/2});assert.equal(hit?.hotspot,name);}}
 }}
});

test('village and polished bedroom sprites have hashed public URLs, matching dimensions and copies',async()=>{
 const serve=createAssetHandler();assert.equal(Object.keys(config.world.villageIsometric.images).length,59);
 for(const [id,a] of Object.entries(config.world.villageIsometric.images)){
  const url=config.images['village-iso-'+id].url;assert.match(url,/\?v=[a-f0-9]{12}$/);
  const response=await serve(new Request('http://localhost/'+url));assert.equal(response.status,200);assert.equal(response.headers.get('content-type'),'image/png');
  const bytes=Buffer.from(await response.arrayBuffer());assert.equal(bytes.readUInt32BE(16),a.width);assert.equal(bytes.readUInt32BE(20),a.height);assert.equal(bytes[25],6,'RGBA');
  assert.deepEqual(fs.readFileSync('docs/assets/'+a.image),bytes);
 }
 assert.equal((await serve(new Request('http://localhost/assets/world/village-isometric-v1/manifest.json'))).status,404);
});
