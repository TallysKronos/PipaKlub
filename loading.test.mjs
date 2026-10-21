import test from 'node:test';
import assert from 'node:assert/strict';
import {createLoadingGate} from './src/loading-gate.js';

function fixture(){const frames=[],timers=new Map();let id=0;const gate=createLoadingGate({paint:fn=>frames.push(fn),later:fn=>{timers.set(++id,fn);return id;},cancel:id=>timers.delete(id)});return {gate,frames,timers};}
test('loading waits for every overlapping resource and the rendered frame',async()=>{
 const {gate,frames}=fixture(),entry=gate.start('entry','Conta'),scene=gate.start('scene','Casa');
 scene.update(2,4);assert.equal(gate.snapshot().completed,2);
 const a=entry.done();assert.equal(gate.active,true);frames.shift()();await a;
 const b=scene.done();assert.equal(gate.active,true);frames.shift()();await b;assert.equal(gate.active,false);
});
test('a stale completion or cancellation cannot reveal a newer destination',async()=>{
 const {gate,frames}=fixture(),old=gate.start('scene','Rua'),done=old.done();
 const current=gate.start('scene','Casa');old.cancel();old.fail('old error');frames.shift()();
 assert.equal(await done,false);assert.equal(gate.snapshot().title,'Casa');assert.equal(gate.active,true);current.cancel();assert.equal(gate.active,false);
});
test('timeouts leave a recoverable screen and retry replaces the failed job',()=>{
 const {gate,timers}=fixture();let retried=false;
 gate.start('scene','Rua',{retry:()=>{retried=true;gate.start('scene','Rua');}});
 [...timers.values()][0]();assert.equal(gate.snapshot().failed,true);assert.equal(gate.active,true);
 gate.snapshot().retry();assert.equal(retried,true);assert.equal(gate.snapshot().failed,false);gate.cancel('scene');assert.equal(gate.active,false);
});
