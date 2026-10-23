import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {newParkProgress,parkTransition,fiberIds,encodeParkSave,decodeParkSave,nearestParkAction,parkActions,propOccludesActor} from './src/park-exploration.js';
import {createParkIsometricScene} from './src/park-isometric-layout.js';
import {createWorldNavigation} from './src/world-navigation.js';
test('task requires acceptance, unique explicit collections and complete return before one reward',()=>{
 let p=newParkProgress();assert.deepEqual(parkTransition(p,'collect',fiberIds[0]),p);assert.equal(parkTransition(p,'reward').rewarded,false);
 p=parkTransition(p,'accept');for(const id of fiberIds){const before=structuredClone(p);p=parkTransition(p,'collect',id);assert.equal(before.collected.includes(id),false);assert.deepEqual(parkTransition(p,'collect',id),p);}
 assert.equal(p.collected.length,3);assert.equal(p.rewarded,false);p=parkTransition(p,'reward');assert.equal(p.rewarded,true);assert.deepEqual(parkTransition(p,'reward'),p);
});
test('local save validates progression and refuses corrupted or incompatible files',()=>{
 let p=parkTransition(newParkProgress(),'accept');p=parkTransition(p,'collect',fiberIds[0]);const saved=encodeParkSave(p,{x:220,y:465,direction:2});assert.deepEqual(decodeParkSave(saved),{progress:p,position:{x:220,y:465,direction:2}});
 for(const raw of ['broken','null','{}',JSON.stringify({...JSON.parse(saved),version:7}),JSON.stringify({...JSON.parse(saved),progress:{...p,rewarded:true}}),JSON.stringify({...JSON.parse(saved),position:{x:-10,y:12,direction:0}})])assert.equal(decodeParkSave(raw),null);
});
test('full task, benches, map, staircase and exits can be reached without crossing bases',()=>{
 const raw=JSON.parse(fs.readFileSync('assets/world/park-v1/park-trail.tmj')),scene=createParkIsometricScene(raw),nav=createWorldNavigation(scene),actor=nav.create();
 for(const id of ['map','assis',...fiberIds,'assis','rest','rest-east','exit-clearing','exit-street']){const a=parkActions.find(a=>a.id===id),p=a.approach||a,route=nav.target(actor,p);assert.ok(route.length,id);for(let i=1;i<route.length;i++)assert.ok(nav.geometry.segment(route[i-1],route[i]));let guard=0;while(actor.path.length&&guard++<5000){nav.step(actor,.05);assert.ok(nav.geometry.safe(actor),id);assert.notEqual(actor.navigationMessage,'Caminho bloqueado.',id);}assert.ok(Math.hypot(actor.x-p.x,actor.y-p.y)<.1,id);}
 assert.ok(nav.geometry.safe({x:335,y:490}),'illustrated stairs are open');
});
test('context is proximity-based and collected fibers disappear from actions',()=>{
 const a=parkActions.find(a=>a.type==='pickup');assert.equal(nearestParkAction(a,newParkProgress()),null);let p=parkTransition(newParkProgress(),'accept');assert.equal(nearestParkAction(a,p).id,a.id);p=parkTransition(p,'collect',a.id);assert.equal(nearestParkAction(a,p),null);
 assert.equal(propOccludesActor({x:0,y:0,w:80,h:100},{x:40,y:90},110),true);assert.equal(propOccludesActor({x:0,y:0,w:80,h:100},{x:40,y:120},80),false);
});
