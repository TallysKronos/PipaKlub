import test from 'node:test';
import assert from 'node:assert/strict';
import {createTallGrass} from './src/world-tall-grass.js';
import {drawTallGrass,drawTallGrassParticles} from './src/world-tall-grass-renderer.js';
import {worldRenderQueue} from './src/world-map.js';
const patch={x:0,y:0,w:220,h:160};
test('game coordinates anchor grass and leaves to the real feet, with depth around the player',()=>{
 const grass=createTallGrass([patch],{project:p=>p});
 for(let x=10;x<90;x+=5)grass.update(.04,{x,y:60});
 assert.ok(grass.particles.every(p=>p.x>=-10&&p.x<=110&&p.y<60&&p.y>35));
 const tuft=grass.tufts.find(t=>t.x>20&&t.y>20),calls=[];
 const g=new Proxy({}, {get:(_,key)=>(...args)=>calls.push([key,...args]),set:()=>true});
 drawTallGrass(g,tuft,{project:p=>p,wind:1});drawTallGrassParticles(g,grass.particles);
 assert.ok(calls.some(c=>c[0]==='translate'&&c[1]===tuft.x&&c[2]===tuft.y));
 const queue=worldRenderQueue({},[{id:'behind',y:40},{id:'player',x:50,y:60},{id:'front',y:80}]);
 assert.deepEqual(queue.map(p=>p.id),['behind','player','front']);
});
test('habitat overlaps do not duplicate tufts or particle emission',()=>{
 const a=createTallGrass([patch]),b=createTallGrass([patch,patch]);
 assert.deepEqual(a.tufts,b.tufts);
 for(let x=10;x<140;x+=5){a.update(.04,{x,y:60});b.update(.04,{x,y:60});}
 assert.ok(a.particles.length>0);assert.deepEqual(a.particles,b.particles);
 assert.ok(a.tufts.every(t=>a.contains(t)&&t.h>=29&&t.h<=44));
});
test('walking sheds leaves, standing expires them and outside grass never emits',()=>{
 const a=createTallGrass([patch]);
 for(let x=10;x<90;x+=5)a.update(.04,{x,y:60});
 assert.ok(a.particles.length>0);assert.ok(a.tufts.some(t=>Math.abs(t.bend)>.1));
 for(let i=0;i<20;i++)a.update(.1,{x:85,y:60});
 assert.equal(a.particles.length,0);
 for(let x=10;x<90;x+=5)a.update(.04,{x,y:190});
 assert.equal(a.particles.length,0);
 for(let i=0;i<20;i++)a.update(.1,{x:90,y:190});
 assert.ok(a.tufts.every(t=>Math.abs(t.bend)<.001));
});
test('pool cap, teleport, reset and reduced motion are safe',()=>{
 const a=createTallGrass([patch],{maxParticles:6});
 for(let i=0;i<30;i++)a.update(.001,{x:10+i%15*5,y:60});
 assert.equal(a.particles.length,6);
 a.reset();a.update(.04,{x:10,y:60});a.update(.04,{x:150,y:60});assert.equal(a.particles.length,0);
 for(let x=150;x<200;x+=5)a.update(.04,{x,y:60});assert.ok(a.particles.length);
 a.update(.04,{x:200,y:60},{x:180,y:60},{reduced:true});assert.equal(a.particles.length,0);
 a.reset();assert.ok(a.tufts.every(t=>t.bend===0));assert.equal(a.particles.length,0);
});
