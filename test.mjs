import test from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import worker from './worker/index.js';
import {createEngine} from './src/engine.js';
import {createTrails} from './src/trails.js';
import {createRoomSessions} from './src/room-session.js';
const sqlite=new DatabaseSync(':memory:');
const DB={prepare(sql){let v=[];return {bind(...a){v=a;return this;},async run(){const r=sqlite.prepare(sql).run(...v);return {meta:{changes:Number(r.changes)}};},async first(){return sqlite.prepare(sql).get(...v);}};}};
async function call(action,data,extra={}){const r=await worker.fetch(new Request('https://game.test/api/'+action,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)}),{DB,...extra});return {status:r.status,...await r.json()};}

test('demo preserves legacy progression but never unlocks future content or sends players there',()=>{
 const all=createTrails(),demo=createTrails({demo:true}),progress=all.defaults();for(const st of all.stages)progress.stars[st.id]=3;
 assert.equal(all.unlocked(progress,'praia-1'),true);assert.equal(demo.unlocked(progress,'praia-1'),false);assert.equal(demo.unlocked(progress,'torres-5'),false);assert.equal(demo.unlocked(progress,'morro-5'),true);assert.equal(demo.nextStage('morro-5'),null);assert.equal(demo.completed(progress),true);assert.equal(demo.sanitize(progress).stars['praia-1'],3,'do not erase existing saves');assert.doesNotMatch(JSON.stringify(demo.story('morro-5')),/Beira-Mar/);
});

test('room credentials survive a reload in the same tab, are scoped to account and are forgotten on leave',()=>{
 const values=new Map(),storage={getItem:k=>values.get(k),setItem:(k,v)=>values.set(k,v),removeItem:k=>values.delete(k)};
 createRoomSessions(storage).save('ABCDEF','private-seat-credential','account-a');const reloaded=createRoomSessions(storage);
 assert.equal(reloaded.read('ABCDEF','account-a').token,'private-seat-credential');assert.equal(reloaded.read('ABCDEF','account-b'),null);assert.equal(reloaded.read('ABCDEF'),null);reloaded.remove('ABCDEF');assert.equal(reloaded.read('ABCDEF','account-a'),null);
 const broken=createRoomSessions({getItem(){throw Error('blocked')},setItem(){throw Error('blocked')}});assert.equal(broken.read('ABCDEF'),null);assert.doesNotThrow(()=>broken.save('ABCDEF','token'));
});

test('HTTP fallback accepts normal rebicadas from the joining player and acknowledges one press only',async()=>{
 const a=await call('create',{name:'Host'}),b=await call('join',{code:a.code,name:'Guest'});
 const s=JSON.parse(sqlite.prepare('select state from pipa_rooms where code=?').get(a.code).state);s.phase='live';s.phaseUntil=Date.now()+60000;s.last=Date.now()-50;sqlite.prepare('update pipa_rooms set state=? where code=?').run(JSON.stringify(s),a.code);
 const input={lineNonce:1,lineId:'folha',lineHeld:true,lineSide:-1,damage:999};
 await call('sync',{code:a.code,token:b.token,input});const first=await call('sync',{code:a.code,token:b.token,input});const p=first.state.players.find(p=>p.id===b.me);assert.equal(p.lineMove.id,'folha');assert.equal(p.lineMove.side,-1);assert.equal(p.lineCount,1);assert.ok(p.energy<85);
 const second=await call('sync',{code:a.code,token:b.token,input:{...input,lineHeld:false}});assert.equal(second.state.players.find(p=>p.id===b.me).lineCount,1);assert.equal(second.state.players.find(p=>p.id===a.me).hp,100);
});
test('two players share a room, inputs are authoritative, credentials are private, leave removes a player',async()=>{
 const a=await call('create',{name:'Ana',color:0});assert.equal(a.status,200);assert.equal(a.state.players.length,1);assert.notEqual(a.me,a.token);assert.ok(!JSON.stringify(a.state).includes(a.token));
 const b=await call('join',{code:a.code,name:'Beto',color:2});assert.equal(b.state.players.length,2);assert.ok(!JSON.stringify(b.state).includes(a.token));
 const sync=await call('sync',{code:a.code,token:a.token,input:{x:999,y:0,cut:true}});assert.equal(sync.state.players.length,2);assert.equal(sync.state.players.find(p=>p.id===a.me).input.x,1);
 const bad=await call('sync',{code:a.code,token:b.me,input:{x:1}});assert.equal(bad.status,401);
 const left=await call('leave',{code:a.code,token:b.token});assert.equal(left.state.players.length,1);
 assert.equal((await call('join',{code:'ZZZZZZ'})).status,400);
});

test('resume restores the same private seat without reserving or admitting again, even in a full room',async()=>{
 let reservations=0;const ACCOUNTS={enabled:true,preparePlayer:async()=>{reservations++;return {accountId:'resume-user',name:'Owner'};}};
 const a=await call('create',{}, {ACCOUNTS});for(let i=0;i<7;i++)await call('join',{code:a.code,name:'Guest'+i});
 const first=await call('resume',{code:a.code,token:a.token},{ACCOUNTS}),second=await call('resume',{code:a.code,token:a.token},{ACCOUNTS});
 assert.equal(first.status,200);assert.equal(first.me,a.me);assert.equal(second.me,a.me);assert.equal(first.state.id,a.state.id);assert.equal(first.state.players.length,8);assert.equal(reservations,1);
 assert.ok(!JSON.stringify(first.state).includes(a.token));assert.equal((await call('resume',{code:a.code})).status,401);assert.equal((await call('resume',{code:a.code,token:a.me})).status,401);
 await call('leave',{code:a.code,token:a.token});assert.equal((await call('resume',{code:a.code,token:a.token})).status,401);
});

test('disconnected seats stop acting and can resume during grace; expired seats cannot be resurrected',async()=>{
 const a=await call('create',{}),b=await call('join',{code:a.code,name:'Peer'}),now=Date.now();
 let s=JSON.parse(sqlite.prepare('select state from pipa_rooms where code=?').get(a.code).state),p=s.players.find(p=>p.id===a.me);s.phase='live';s.phaseUntil=now+60000;p.seen=now-30000;p.input={cut:true,x:1};const x=p.x;s.last=now-100;sqlite.prepare('update pipa_rooms set state=? where code=?').run(JSON.stringify(s),a.code);
 const peer=await call('sync',{code:a.code,token:b.token,input:{}});assert.equal(peer.state.players.length,2);const inactive=peer.state.players.find(p=>p.id===a.me);assert.ok(Math.abs(inactive.x-x)<2,'only ambient wind may move the disconnected kite');assert.equal(inactive.input.cut,false);assert.equal(inactive.input.x,0);
 assert.equal((await call('resume',{code:a.code,token:a.token})).me,a.me);
 s=JSON.parse(sqlite.prepare('select state from pipa_rooms where code=?').get(a.code).state);s.players.find(p=>p.id===a.me).seen=Date.now()-61000;sqlite.prepare('update pipa_rooms set state=? where code=?').run(JSON.stringify(s),a.code);assert.equal((await call('resume',{code:a.code,token:a.token})).status,401);
});

test('demo rejects later districts before reserving any account or creating a match',async()=>{
 let calls=0;const ACCOUNTS={enabled:true,preparePlayer:async()=>{calls++;return {accountId:'demo-user',name:'Demo'};},registerTrail:async()=>({progress:{}})};
 for(const stage of ['praia-1','praia-5','torres-1']){const r=await call('trail',{stage},{ACCOUNTS});assert.equal(r.status,403);assert.match(r.error,/demo inclui o Morro/);}
 assert.equal(calls,0);assert.equal((await call('trail',{stage:'morro-1'},{ACCOUNTS})).status,200);
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
 const timed=await call('create',{name:'T',mode:'time'},{ACCOUNTS:{preparePlayer:async()=>({accountId:'registered',name:'Time',color:0})}});assert.equal(timed.state.mode,'time');assert.equal((await call('join',{code:timed.code,name:'Visitante'})).status,401);assert.equal((await call('create',{name:'Visitante',mode:'time'})).status,401);
});
test('quick match seats waiting players together and fills the room with bots after the wait',async()=>{
 const signed=name=>({ACCOUNTS:{enabled:true,preparePlayer:async()=>({accountId:name,name})}});
 assert.equal((await call('quick',{})).status,401);
 const a=await call('quick',{name:'Ana',color:0},signed('Ana'));assert.equal(a.status,200);assert.ok(a.state.quick);assert.equal(a.state.phase,'waiting');
 const b=await call('quick',{name:'Beto',color:1},signed('Beto'));assert.equal(b.status,200);assert.equal(b.code,a.code,'second player joins the open quick room');
 assert.equal((await call('join',{code:a.code})).status,401);
 const row=sqlite.prepare('SELECT state FROM pipa_rooms WHERE code = ?').get(a.code),s=JSON.parse(row.state);
 s.quick.fillAt=Date.now()-1;sqlite.prepare('UPDATE pipa_rooms SET state = ? WHERE code = ?').run(JSON.stringify(s),a.code);
 const sync=await call('sync',{code:a.code,token:a.token,input:{}});
 assert.equal(sync.state.players.length,4);assert.equal(sync.state.players.filter(p=>p.bot).length,2);assert.notEqual(sync.state.phase,'waiting');
 const c=await call('quick',{name:'Caio',color:2},signed('Caio'));assert.equal(c.status,200);
 if(c.code===a.code){assert.equal(c.state.players.length,4);assert.equal(c.state.players.filter(p=>p.bot).length,1,'a bot gives up its seat');}
 else assert.equal(c.state.players.length,1,'a live room is not interrupted: a new quick room opens');
});
test('engine: a quick room with no people left closes',()=>{
 const e=createEngine(),now=Date.now(),s=e.create(now,{mode:'rounds',quick:true}),p=e.player('Ana',0,'a',now);e.admit(s,p,now);
 e.step(s,now+11000);assert.equal(s.players.length,4);p.seen=now-60000;e.step(s,now+30000);assert.ok(s.end<=now+30000);
});

test('the server assigns Morro rival styles from the stage rather than the client request',async()=>{
 const profiles={'morro-1':['patient'],'morro-2':['mobile'],'morro-3':['patient','mobile'],'morro-4':['guard'],'morro-5':['reader']};
 const accounts={enabled:true,preparePlayer:async()=>({accountId:'story-player',name:'Pipeiro',color:0}),registerTrail:async()=>({progress:{}})};
 for(const [stage,styles]of Object.entries(profiles)){
  const room=await call('trail',{stage,aiStyle:'untrusted-client',name:'Pipeiro'},{ACCOUNTS:accounts});assert.equal(room.status,200,stage);
  const saved=JSON.parse(sqlite.prepare('select state from pipa_rooms where code=?').get(room.code).state);
  assert.deepEqual(saved.players.filter(p=>p.bot).map(p=>p.ai.style),styles);
 }
});


test('solo pause endpoint rejects multiplayer, invalid sessions and malformed intent',async()=>{
 const accounts={enabled:true,preparePlayer:async()=>({accountId:'pause-owner',name:'Owner',color:0}),registerTrail:async()=>({progress:{}})};
 const a=await call('trail',{stage:'morro-1'},{ACCOUNTS:accounts});assert.equal(a.status,200);
 assert.equal((await call('pause',{code:a.code,token:'forged',paused:true})).status,401);
 assert.equal((await call('pause',{code:a.code,token:a.token,paused:'yes'})).status,403);
 const paused=await call('pause',{code:a.code,token:a.token,paused:true});assert.equal(paused.state.soloPaused,true);assert.equal(paused.state.trailOwner,undefined);
 assert.equal((await call('pause',{code:a.code,token:a.token,paused:false})).state.soloPaused,false);
 const multi=await call('create',{name:'Host'});assert.equal((await call('pause',{code:multi.code,token:multi.token,paused:true})).status,403);
});
