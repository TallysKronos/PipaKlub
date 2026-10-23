import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {toIso,fromIso,screenToWorld,depthOrder,screenDirection} from './src/world-isometric.js';
import {parseWorldMap} from './src/world-map.js';
import {createWorldNavigation} from './src/world-navigation.js';
import {validate,sample,matrices,point} from './tools/soulgen-studio/model.mjs';
import {createParkIsometricScene,parkFixtures,parkFenceRuns} from './src/park-isometric-layout.js';
const read=file=>JSON.parse(fs.readFileSync(file,'utf8'));
const close=(a,b)=>assert.ok(Math.abs(a-b)<1e-7,`${a} ≠ ${b}`);
const scene=parseWorldMap(read('assets/world/park-v1/park-trail.tmj'));
test('dimetric projection and clicks invert at multiple cameras and zooms',()=>{
 for(const [x,y]of [[0,0],[1536,1024],[224,816],[414,488],[-50,200]]){
  const p={x,y},iso=toIso(p),back=fromIso(iso);close(back.x,x);close(back.y,y);
  for(const zoom of [.56,.95,1.4]){const camera={x:-145,y:444},v={width:1280,height:720},screen={x:(iso.x-camera.x)*zoom+640,y:(iso.y-camera.y)*zoom+360},result=screenToWorld(screen,camera,v,zoom);close(result.x,x);close(result.y,y);}
 }
});
test('depth sorting uses projected feet, stable ties and floors',()=>{
 assert.deepEqual(depthOrder([{id:'A',x:800,y:50},{id:'B',x:50,y:400},{id:'C',x:50,y:400},{id:'upper',x:0,y:0,level:1}]).map(o=>o.id),['B','C','A','upper']);
 assert.equal(screenDirection(5,1),2);assert.equal(screenDirection(-5,1),1);assert.equal(screenDirection(0,5),0);assert.equal(screenDirection(0,-5),3);
});
test('projected destinations preserve real park routes and solid collisions',()=>{
 const nav=createWorldNavigation(scene);
 for(const place of scene.places){const actor=nav.create(),[x,y]=scene.nodes[place.node],target=fromIso(toIso({x,y}));assert.ok(nav.target(actor,target).length,place.name);let steps=0;while(actor.path.length&&steps++<5000){const previous={x:actor.x,y:actor.y};nav.step(actor,.05);assert.ok(nav.geometry.segment(previous,actor));}assert.ok(Math.hypot(actor.x-x,actor.y-y)<.1);}
 const solid=scene.tiled.layers.Solids[0],actor=nav.create();assert.deepEqual(nav.target(actor,{x:solid.x+solid.w/2,y:solid.y+solid.h/2}),[]);
});
test('environment Soulgen rigs close the loop, keep fixed supports and fit logical canvas',()=>{
 for(const family of ['park-wind-v1','park-wind-v2']){
 for(const id of family==='park-wind-v2'?['tree','treeLandmark','windsock','bunting','kite']:['tree','treeLandmark','windsock','bunting']){
  const project=read(`art/soulgen/keys/${family}/${id}.json`);assert.equal(validate(project).ok,true);
  const first=sample(project,'idle',0),end=sample(project,'idle',6);assert.deepEqual(first,end);
  for(let f=0;f<180;f++){
   const pose=sample(project,'idle',f/30),m=matrices(project,pose);
   for(const p of project.parts){const [x,y,w,h]=p.rect;for(const [px,py]of [[x,y],[x+w,y],[x,y+h],[x+w,y+h]]){const q=point(m[p.id],px,py);assert.ok(q.x>=0&&q.x<=project.width&&q.y>=0&&q.y<=project.height,`${id}/${p.id} clipped at ${f}`);}}
   const fixed=id.startsWith('tree')?'trunk':id==='windsock'?'pole':null;
   if(fixed)m[fixed].forEach((n,i)=>close(n,[1,0,0,1,0,0][i]));
  }
  const portable=read(`art/soulgen/keys/${family}/${id}.soulgen.json`);assert.equal(validate(portable).ok,true);for(const a of Object.values(portable.assets))assert.ok(a.src.startsWith('data:image/png;base64,'));
 }
 }
});
test('finished fixtures share visible foot positions and collision bases without cutting park routes',()=>{
 const raw=read('assets/world/park-v1/park-trail.tmj'),before=JSON.stringify(raw),draft=createParkIsometricScene(raw),nav=createWorldNavigation(draft);
 assert.equal(JSON.stringify(raw),before,'production map must remain intact');
 for(const p of parkFixtures){const solid=draft.tiled.layers.Solids.find(s=>s.name===p.id);close(solid.x+solid.w/2,p.x);close(solid.y+solid.h,p.y);assert.equal(nav.geometry.safe({x:p.x,y:p.y-p.base[1]/2}),false);}
 for(const place of draft.places){const actor=nav.create(),[x,y]=draft.nodes[place.node],route=nav.target(actor,{x,y});assert.ok(route.length,place.name);for(let i=1;i<route.length;i++)assert.ok(nav.geometry.segment(route[i-1],route[i]));let steps=0;while(actor.path.length&&steps++<5000){nav.step(actor,.05);assert.ok(nav.geometry.safe(actor));assert.notEqual(actor.navigationMessage,'Caminho bloqueado.');}assert.ok(Math.hypot(actor.x-x,actor.y-y)<.1);}
 for(const [a,b] of parkFenceRuns)for(let i=0;i<=20;i++)assert.equal(nav.geometry.safe({x:a[0]+(b[0]-a[0])*i/20,y:a[1]+(b[1]-a[1])*i/20}),false,'fence stays beyond traversable border');
});
