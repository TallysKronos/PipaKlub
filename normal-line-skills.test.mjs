import test from 'node:test';
import assert from 'node:assert/strict';
import {createEngine} from './src/engine.js';
import {createNetworkView} from './src/network-view.js';
const e=createEngine();
const command=(id,nonce=1,held=false)=>({lineId:id,lineNonce:nonce,lineHeld:held,lineSide:1});
function duel(){const s=e.create(1000),a=e.player('A',0,'a',1000),b=e.player('B',2,'b',1000);Object.assign(a,{x:700,y:180,anchorX:90});Object.assign(b,{x:300,y:180,anchorX:910});s.players=[a,b];return {s,a,b};}
function run(id,step=20,setup=()=>{}){const d=duel();setup(d);d.a.input=command(id);for(let t=step;t<=1600;t+=step)e.step(d.s,1000+t);return d;}
test('six normal maneuvers validate input and never trust client damage or costs',()=>{
 assert.equal(e.lineSkills.length,6);assert.equal(e.sanitizeInput({...command('hack'),damage:999}).lineId,'');assert.equal(e.sanitizeInput({...command('puxao',Infinity)}).lineNonce,undefined);
 for(const def of e.lineSkills){const {a}=duel();e.move(a,command(def.id,1,true),0);assert.equal(a.energy,100-def.cost);assert.equal(a.lineCooldown,def.cooldown);assert.equal(a.lineMove.phase,'charge');assert.equal(a.lineCount,1);}
});
test('press nonce survives lost press packet, duplicated release and expired cooldown',()=>{
 const {a}=duel();e.move(a,command('folha'),.1);assert.equal(a.lineCount,1);
 for(let n=0;n<60;n++)e.move(a,command('folha'),.1);assert.equal(a.lineCount,1);assert.equal(a.lineMove,null);
 e.move(a,command('folha',2),.1);assert.equal(a.lineCount,2);
});
test('rejected commands are consumed, and charge auto releases after 1.2 seconds',()=>{
 const {a}=duel();a.energy=0;e.move(a,command('puxao',1,true),0);a.energy=100;e.move(a,command('puxao',1,true),.1);assert.equal(a.lineMove,undefined);
 e.move(a,command('puxao',2,true),.1);for(let n=0;n<13;n++)e.move(a,command('puxao',2,true),.1);assert.equal(a.lineMove.phase,'move');
});
test('puxao descends then rises, aligned strikes hit once and miss cannot deal damage',()=>{
 const k={id:'puxao',side:1};assert.ok(e.lineMotion(k,.42).y>e.lineMotion(k,.8).y);
 const d=run('puxao');assert.equal(d.b.hp,68);assert.equal(d.a.crits,1);assert.equal(d.a.hits,1);
 const miss=run('puxao',20,({a,b})=>{a.x=200;b.x=800});assert.equal(miss.b.hp,100);assert.equal(miss.a.crits,undefined);
});
test('damage remains consistent at 30 and 60 simulation ticks per second',()=>{
 for(const skill of e.lineSkills)assert.equal(run(skill.id,1000/30).b.hp,run(skill.id,1000/60).b.hp,skill.id);
});
test('folha deals no damage and remains vulnerable; duplo has exactly two guarded pulses',()=>{
 const f=run('folha');assert.equal(f.b.hp,100);assert.ok(!f.a.evade);assert.equal(f.a.hits,undefined);
 const d=run('duplo',20,({b})=>{b.skillTime=2;b.color=2});assert.equal(d.a.hits,2);assert.ok(Math.abs(d.b.hp-78.8)<1e-8);assert.equal(d.b.skillTime,0);assert.equal(d.b.lastHit.breakGuard,true);
});
test('being hit interrupts laco; misses impose longer chicote recovery',()=>{
 const {s,a,b}=duel();a.input=command('laco',1,true);b.input={cut:true};e.step(s,1020);assert.equal(a.lineMove,null);assert.ok(a.hp<100);
 const p=duel().a;for(let n=0;n<16;n++)e.move(p,command('chicote'),.05);assert.ok(p.attackCooldown>=.8);
});
test('countdown and intermission do not deliver maneuvers or replay a queued press',()=>{
 const {s,a,b}=duel();s.mode='rounds';s.phase='countdown';s.phaseUntil=1200;a.input=command('puxao');e.step(s,1100);e.step(s,1250);assert.equal(a.lineMove,undefined);assert.equal(b.hp,100);
 s.phase='intermission';s.phaseUntil=9000;a.lineStrike={damage:99,slot:0};a.lineMove={id:'puxao'};e.step(s,1300);assert.equal(a.lineMove,null);assert.equal(b.hp,100);
});
test('prediction never mutates authoritative maneuver state or repeats an unacknowledged press',()=>{
 const {s,a}=duel(),v=createNetworkView(e);v.receive(structuredClone(s),'a',0);const input=command('puxao',1,true);let p=v.render(16,input,.016).find(p=>p.id==='a');assert.equal(p.lineCount,1);
 v.receive(structuredClone(s),'a',40);p=v.render(56,input,.016).find(p=>p.id==='a');assert.equal(p.lineCount,1);assert.equal(p.lineSeen,1);
 a.input=input;e.move(a,input,.05);const original=structuredClone(a);v.receive(structuredClone(s),'a',80);v.render(96,command('puxao'),.016);assert.deepEqual(a,original);
});
