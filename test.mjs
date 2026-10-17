import test from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import worker from './worker/index.js';
import {createEngine} from './src/engine.js';
const sqlite=new DatabaseSync(':memory:');
const DB={prepare(sql){let v=[];return {bind(...a){v=a;return this;},async run(){const r=sqlite.prepare(sql).run(...v);return {meta:{changes:Number(r.changes)}};},async first(){return sqlite.prepare(sql).get(...v);}};}};
async function call(action,data){const r=await worker.fetch(new Request('https://game.test/api/'+action,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)}),{DB});return {status:r.status,...await r.json()};}
test('two players share a room, inputs are authoritative, credentials are private, leave removes a player',async()=>{
 const a=await call('create',{name:'Ana',color:0});assert.equal(a.status,200);assert.equal(a.state.players.length,1);assert.notEqual(a.me,a.token);assert.ok(!JSON.stringify(a.state).includes(a.token));
 const b=await call('join',{code:a.code,name:'Beto',color:2});assert.equal(b.state.players.length,2);assert.ok(!JSON.stringify(b.state).includes(a.token));
 const sync=await call('sync',{code:a.code,token:a.token,input:{x:999,y:0,cut:true}});assert.equal(sync.state.players.length,2);assert.equal(sync.state.players.find(p=>p.id===a.me).input.x,1);
 const bad=await call('sync',{code:a.code,token:b.me,input:{x:1}});assert.equal(bad.status,401);
 const left=await call('leave',{code:a.code,token:b.token});assert.equal(left.state.players.length,1);
 assert.equal((await call('join',{code:'ZZZZZZ'})).status,400);
});
test('room limit is eight, ended matches reject join',async()=>{
 const a=await call('create',{name:'Host'});for(let i=0;i<7;i++)assert.equal((await call('join',{code:a.code,name:'Guest'+i})).status,200);
 assert.equal((await call('join',{code:a.code,name:'Extra'})).status,409);
 const s=JSON.parse(sqlite.prepare('SELECT state FROM pipa_rooms WHERE code=?').get(a.code).state);s.end=Date.now()-1;s.players=s.players.slice(0,1);sqlite.prepare('UPDATE pipa_rooms SET state=? WHERE code=?').run(JSON.stringify(s),a.code);
 assert.equal((await call('join',{code:a.code})).status,409);
});
test('combat consumes energy, awards one cut, respawns and ends without further damage',()=>{
 const e=createEngine(),s=e.create(1000),a=e.player('A',0,'a',1000),b=e.player('B',1,'b',1000);a.x=700;b.x=300;a.y=b.y=180;a.input={cut:true};b.hp=1;s.players=[a,b];e.step(s,1100);assert.equal(a.score,100);assert.equal(a.cuts,1);assert.ok(b.respawn);assert.ok(a.energy<100);e.step(s,1200);assert.equal(a.score,100);a.input={};e.step(s,4200);assert.equal(b.hp,100);assert.equal(b.respawn,0);a.input={};let en=a.energy;e.step(s,4300);assert.ok(a.energy>en);s.end=4300;let x=a.x;a.input={x:1};e.step(s,4400);assert.equal(a.x,x);
});

test('a slow account check does not lose the join race against the realtime tick',async()=>{
 const a=await call('create',{name:'Host'});let calls=0,released=0;
 const tick=setInterval(()=>sqlite.prepare('UPDATE pipa_rooms SET rev=rev+1 WHERE code=?').run(a.code),10);
 const ACCOUNTS={enabled:true,async preparePlayer(){calls++;await new Promise(r=>setTimeout(r,40));return {accountId:'u1',name:'Logada'};},async release(){released++;}};
 try{
  const r=await worker.fetch(new Request('https://game.test/api/join',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({code:a.code,name:'Guest'})}),{DB,ACCOUNTS});const b=await r.json();
  assert.equal(r.status,200,b.error);assert.equal(b.state.players.length,2);assert.equal(calls,1);assert.equal(released,0);
 }finally{clearInterval(tick);}
});
test('rooms start in the chosen format; rematch creates one new room and points everyone else to it',async()=>{
 const a=await call('create',{name:'Ana',mode:'rounds'});assert.equal(a.state.mode,'rounds');assert.equal(a.state.phase,'waiting');assert.equal(a.state.players[0].slot,0);
 const b=await call('join',{code:a.code,name:'Beto'});assert.equal(b.state.players.find(p=>p.id===b.me).slot,1);assert.equal((await call('sync',{code:a.code,token:b.token,input:{}})).state.phase,'countdown');
 assert.equal((await call('rematch',{code:a.code,token:a.token})).code,a.code,'no rematch while the match is running');
 const s=JSON.parse(sqlite.prepare('SELECT state FROM pipa_rooms WHERE code=?').get(a.code).state);s.end=Date.now()-1;sqlite.prepare('UPDATE pipa_rooms SET state=? WHERE code=?').run(JSON.stringify(s),a.code);
 const first=await call('rematch',{code:a.code,token:a.token});assert.equal(first.status,200);assert.notEqual(first.code,a.code);assert.equal(first.state.mode,'rounds');assert.ok(first.token);
 const second=await call('rematch',{code:a.code,token:b.token});assert.equal(second.next,first.code);
 const old=await call('inspect',{code:a.code});assert.equal(old.status,409);assert.equal(old.next,first.code);
 const joined=await call('join',{code:first.code,name:'Beto'});assert.equal(joined.status,200);assert.equal(joined.state.players.length,2);
 assert.equal((await call('create',{name:'T',mode:'time'})).state.mode,'time');
});
