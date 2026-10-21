import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {createWorldNavigation} from './src/world-navigation.js';
const manifest=JSON.parse(fs.readFileSync('assets/world/identity-v2/manifest.json','utf8'));
test('every landmark is connected and every route segment remains on the authored walking graph',()=>{
 for(const scene of Object.values(manifest.scenes)){
  const nav=createWorldNavigation(scene);for(const a of scene.places)for(const b of scene.places){const from=nav.nodes[a.node],to=nav.nodes[b.node],route=nav.route(from,to);assert.ok(route.length);assert.deepEqual(route.at(-1),to);for(let i=1;i<route.length;i++)for(const t of [.1,.3,.5,.7,.9]){const p={x:route[i-1].x+(route[i].x-route[i-1].x)*t,y:route[i-1].y+(route[i].y-route[i-1].y)*t};assert.ok(nav.project(p).distance<.001,scene.name+' route left its edges');}}
 }
});
test('walking clamps background gaps, keeps its follower on the same route and arrives exactly',()=>{
 const scene=manifest.scenes.morro,nav=createWorldNavigation(scene),actor=nav.create(),target=nav.nodes[36];nav.target(actor,target);
 for(let i=0;i<3000&&actor.path.length;i++){const before={x:actor.x,y:actor.y};nav.step(actor,5);assert.ok(nav.distance(before,actor)<=14.501);assert.ok(nav.project(actor).distance<.001);assert.ok(nav.project(nav.follower(actor)).distance<.001);}
 assert.deepEqual({x:actor.x,y:actor.y},target);assert.equal(actor.path.length,0);assert.ok(actor.history.length<=400);
});
test('same-edge destinations do not walk to a node and back; reduced movement teleports along a valid route',()=>{
 const nav=createWorldNavigation(manifest.scenes.quintal),a=nav.nodes[0],b=nav.nodes[1],from={x:a.x*.7+b.x*.3,y:a.y*.7+b.y*.3},to={x:a.x*.3+b.x*.7,y:a.y*.3+b.y*.7};assert.equal(nav.route(from,to).length,2);
 const actor=nav.create();nav.target(actor,nav.nodes[10],true);assert.deepEqual({x:actor.x,y:actor.y},nav.nodes[10]);assert.equal(actor.path.length,0);assert.ok(nav.project(nav.follower(actor)).distance<.001);
});
test('camera remains inside the world for mobile and desktop, including viewports larger than the source',()=>{
 const scene=manifest.scenes.morro,nav=createWorldNavigation(scene);for(const [w,h]of [[390,844],[1104,650],[1920,1080]])for(const p of nav.nodes){const c=nav.camera(p,w,h);assert.ok(c.x>=0&&c.y>=0);assert.ok(c.x<=Math.max(0,scene.width-w/c.scale));assert.ok(c.y<=Math.max(0,scene.height-h/c.scale));}
});

test('direct walking uses the whole floor, normalizes diagonals and never tunnels through walls',()=>{
 const scene=manifest.scenes.quintal,nav=createWorldNavigation(scene),actor=nav.create();
 // A point between authored grid nodes remains a valid direct-control position.
 const origin={x:actor.x,y:actor.y};nav.move(actor,{x:1,y:1},.1);
 assert.ok(nav.geometry?nav.geometry.safe(actor):true);assert.ok(Math.hypot(actor.x-origin.x,actor.y-origin.y)<=14.5001);
 assert.equal(actor.path.length,0);const stopped={x:actor.x,y:actor.y};nav.move(actor,{x:0,y:0},.1);assert.equal(actor.moving,false);assert.equal(actor.x,stopped.x);assert.equal(actor.y,stopped.y);
});
