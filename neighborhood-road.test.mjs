import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {createNeighborhoodRoad} from './src/neighborhood-road.js';
import {artConfig} from './scripts/art-build.mjs';
import {createWorldNavigation} from './src/world-navigation.js';
import {createTrailSync} from './src/trail-sync.js';
import {createTrails} from './src/trails.js';
const chapters=()=>artConfig().courtyard.world.morroRoad;
test('five maps preserve the existing five encounters and every forward/back link',()=>{
 const list=chapters(),road=createNeighborhoodRoad(list);assert.equal(list.length,5);
 for(const [i,c]of list.entries()){
  assert.deepEqual(c.scene.places.filter(p=>p.stage).map(p=>p.stage),['morro-'+(i+1)]);
  const forward=c.scene.places.find(p=>p.action==='road_next');assert.equal(forward.requiresStage,c.stage);assert.equal(forward.target,list[i+1]?.id);
  if(i)assert.equal(c.scene.places.find(p=>p.action==='road_back').target,list[i-1].id);
  assert.equal(road.canEnter(c.id,null),i===0);
 }
 const p={stars:{}};for(const [i,c]of list.entries()){assert.equal(road.gate(c.id,p).state,'locked');p.stars[c.stage]=1;assert.equal(road.gate(c.id,p).state,i===4?'complete':'open');if(i<4)assert.ok(road.canEnter(list[i+1].id,p));}
 assert.equal(road.canEnter(list[4].id,{stars:{'morro-4':3}}),false);assert.equal(road.canEnter('unknown',{stars:{}}),false);
});
test('closed physical barriers block every north route; opening restores the walk and return',()=>{
 for(const c of chapters()){
  const s=structuredClone(c.scene),nav=createWorldNavigation(s),actor=nav.create(),barrier=s.tiled.layers.Foreground.find(r=>r.properties.road_gate),exit=s.places.find(p=>p.action==='road_next');
  const near=s.places.find(p=>p.action==='road_gate');s.tiled.layers.Solids.push({...barrier,properties:{hidden:true,level:0}});
  assert.deepEqual(nav.target(actor,nav.nodes[exit.node]),[],c.id+' cannot bypass its fence');assert.ok(nav.target(actor,nav.nodes[near.node]).length,c.id+' has an accessible gate interaction');
  s.tiled.layers.Solids.pop();assert.ok(nav.target(actor,nav.nodes[exit.node]).length);let count=0;while(actor.path.length&&count++<3000){nav.step(actor,.1);assert.ok(nav.geometry.safe(actor));assert.ok(nav.geometry.safe(nav.follower(actor)));}assert.ok(count<3000);
  assert.ok(nav.target(actor,nav.nodes[s.spawn]).length);
 }
});
test('registered map images match native dimensions and ship with no baked NPC identity',()=>{
 const config=artConfig();for(const c of chapters())for(const image of c.scene.tiled.images){const p=config.courtyard.images['world-kit-'+image.sheet],b=fs.readFileSync('assets/'+p.image);assert.equal(b.readUInt32BE(16),image.w);assert.equal(b.readUInt32BE(20),image.h);assert.match(p.url,/\?v=[a-f0-9]{12}$/);}
 assert.equal(config.courtyard.world.scenes.morro.places.filter(p=>p.stage).length,5);
});
test('cached, pending and stale-account results never become a fresh verified victory',async()=>{
 const trails=createTrails(),values=new Map([['pipaTrailAccountV1:a:base',JSON.stringify({revision:99,progress:{stars:{'morro-1':3}}})]]),storage={getItem:k=>values.get(k)||null,setItem:(k,v)=>values.set(k,v),removeItem:k=>values.delete(k),key:i=>[...values.keys()][i],get length(){return values.size;}};
 let fail=true;const sync=createTrailSync({trails,storage,uuid:()=>crypto.randomUUID(),send:async()=>{if(fail)throw Error('offline');return {revision:1,progress:trails.defaults()};}});
 await sync.setUser('a');assert.equal(sync.confirmed(),null);assert.equal(sync.progress().stars['morro-1'],3);
 sync.record({stage:'morro-1',won:true,roundsLost:0});assert.equal(sync.confirmed(),null);
 sync.accept({revision:2,progress:{stars:{'morro-1':1}}},'a');assert.equal(sync.confirmed().stars['morro-1'],1);
 sync.accept({revision:1,progress:{}},'a');assert.equal(sync.confirmed().stars['morro-1'],1);
 await sync.setUser('b');assert.equal(sync.confirmed(),null);sync.accept({revision:4,progress:{stars:{'morro-1':3}}},'a');assert.equal(sync.confirmed(),null);
 await sync.setUser(null);assert.equal(sync.confirmed(),null);
});
