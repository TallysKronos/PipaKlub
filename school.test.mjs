import test from 'node:test';
import assert from 'node:assert/strict';
import {createEngine} from './src/engine.js';
import {createSchool} from './src/school.js';
const engine=createEngine(),school=createSchool(engine);
const clamp=v=>Math.max(-1,Math.min(1,v));
function practice(index){
 const run=school.create(index,1000);let elapsed=0;
 while(!run.complete&&elapsed<40000){
  elapsed+=1000/60;const p=run.state.players[0],distance=Math.hypot(run.target.x-p.x,run.target.y-p.y);
  const input=index>=4?{}:{x:clamp((run.target.x-p.x)/40),y:clamp((run.target.y-p.y)/40),cut:distance<20};
  if(index===3&&distance<20){input.x=.8;input.y=-.6;input.cut=true;}
  if(index===4){const phase=((run.elapsed||0)*1000)%4000;input.dodge=phase>=2100&&phase<2120;}
  school.tick(run,input,1000+elapsed);
 }
 return run;
}
test('all six school exercises can be completed with ordinary controls and real combat',()=>{
 for(let i=0;i<school.lessons.length;i++){
  const run=practice(i);assert.equal(run.complete,true,school.lessons[i].name);
  assert.equal(run.state.rules,'casual');assert.equal(run.state.players[0].cuts,0);
  assert.equal(run.state.players[0].score,0);assert.equal(run.state.players[0].respawn,0);
  const copy=structuredClone(run.state);school.tick(run,{cut:true},run.last+1000);assert.deepEqual(run.state,copy,'completed exercise freezes');
 }
});
test('time and missed pulls cannot pass combat lessons; ordinary evasion cannot pass perfect dodge',()=>{
 for(let i=0;i<5;i++){
  const run=school.create(i,1000);
  for(let j=1;j<=300;j++)school.tick(run,{cut:i!==4,dodge:i===4&&j===1},1000+j*1000/60);
  assert.equal(run.complete,false,school.lessons[i].name);
 }
 assert.throws(()=>school.create(-1,0),/inválida/);assert.throws(()=>school.create(6,0),/inválida/);
});
test('golden centre and safe tip require their specific geometry',()=>{
 const golden=school.create(2,1000);Object.assign(golden.state.players[0],{x:435,y:195});
 school.tick(golden,{cut:true},1016);assert.ok(golden.state.players[0].hits);assert.equal(golden.complete,false);
 const tip=school.create(1,1000);Object.assign(tip.state.players[0],{x:700,y:180});
 school.tick(tip,{cut:true},1016);assert.ok(tip.state.players[0].hits);assert.equal(tip.complete,false);
});
