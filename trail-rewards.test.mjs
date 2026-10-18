import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {randomUUID} from 'node:crypto';
import {PGlite} from '@electric-sql/pglite';
import {DatabaseSync} from 'node:sqlite';
import {createEngine} from './src/engine.js';
import {createProgression} from './src/progression.js';
import worker from './worker/index.js';
import vm from 'node:vm';
import {parseHTML} from 'linkedom';
import {createTrails} from './src/trails.js';
const a='11111111-1111-4111-8111-111111111111',b='22222222-2222-4222-8222-222222222222';
const setup=async(beforeMigration=null)=>{const db=new PGlite();await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;");for(const f of fs.readdirSync('supabase/migrations').filter(f=>f.endsWith('.sql')).sort()){if(f.startsWith('014')&&beforeMigration)await beforeMigration(db);await db.exec(fs.readFileSync('supabase/migrations/'+f,'utf8'));}for(const id of[a,b])await db.query('insert into auth.users values($1,$2) on conflict do nothing',[id,{nickname:'Teste'}]);return db;};

test('verified trail ledger: no forged client awards, unique boss tail, summon/equip and immutable receipt',async()=>{
 const db=await setup();try{
 const auth=async id=>db.exec("reset role;set role authenticated;set request.jwt.claim.sub='"+id+"'");const server=()=>db.exec("reset role;set role pipa_server;set request.jwt.claim.sub=''");
 const read=async()=>(await db.query('select public.player_trails() r')).rows[0].r;
 const create=async(stage,user=a)=>{await server();const match=randomUUID();await db.query("select public.reserve_player_match($1,$2,'ABCDEF','casual')",[user,match]);try{await db.query('select public.register_trail_run($1,$2,$3)',[user,match,stage]);}catch(e){await db.query('select public.release_player_match($1,$2)',[user,match]);throw e;}return match;};
 const settle=async(match,stage,won=true,lost=0)=>(await db.query('select public.settle_trail_run($1,$2,$3,$4,$5) r',[a,match,stage,won,lost])).rows[0].r;
 const finish=match=>db.query('select public.finish_player_match($1)',[match]);
 await auth(a);const before=await read(),op=randomUUID();const archived=(await db.query("select public.player_trails('import',$1,$2) r",[op,{coins:999999,stars:{'torres-5':3},items:['rabiola-flautrevo']}])).rows[0].r;assert.deepEqual(archived.progress,before.progress);assert.equal(archived.legacyArchived,true);
 await assert.rejects(()=>db.query("select public.apply_trail_progress('import',$1,$2)",[randomUUID(),{coins:999}]),/permission denied/);await assert.rejects(()=>db.query("select public.register_trail_run($1,$2,'morro-1')",[a,randomUUID()]),/permission denied/);await assert.rejects(()=>db.query('select * from public.trail_drop_claims'),/permission denied/);
 await assert.rejects(()=>create('torres-5'),/anterior/);
 let match=await create('morro-1');await auth(a);await db.query("select public.player_trails('result',$1,$2)",[match,{stage:'morro-1',won:true,roundsLost:0}]);assert.equal((await read()).progress.coins,0,'a public result cannot mint currency or poison settlement');await auth(b);await assert.rejects(()=>db.query('select public.get_player_trail_result($1)',[match]),/não encontrada/);
 await server();const once=await Promise.all([settle(match,'morro-1'),settle(match,'morro-1')]);assert.deepEqual(once[0],once[1]);assert.equal(once[0].coins,25);await assert.rejects(()=>settle(match,'morro-1',false),/outros dados/);await finish(match);
 for(const stage of ['morro-2','morro-3','morro-4']){match=await create(stage);await settle(match,stage,true,stage==='morro-3'?2:0);await finish(match);}
 match=await create('morro-5');const reward=await settle(match,'morro-5');assert.equal(reward.drop,'rabiola-raio-de-sol');assert.ok(reward.tailId);await finish(match);
 await auth(a);const snapshot=(await db.query('select public.get_player_trail_result($1) r',[match])).rows[0].r;assert.equal(snapshot.result.tailId,reward.tailId);assert.equal(snapshot.rewards.length,1);assert.equal(snapshot.rewards[0].status,'ready');
 let inventory=(await db.query("select public.player_summon('inventory') r")).rows[0].r;assert.ok(inventory.seen.some(p=>p.modelId==='raio'&&p.availableTailIds.includes(reward.tailId)));
 const session=randomUUID(),ritual=(await db.query("select public.player_summon('start',$1,null,null,null,$2,'raio') r",[reward.tailId,session])).rows[0].r;
 const called=(await db.query("select public.player_summon('attempt',null,$1,$2,$3,$4) r",[ritual.id,ritual.pattern,randomUUID(),session])).rows[0].r;assert.equal(called.status,'succeeded');await db.query('select public.equip_player_kite($1)',[called.kiteId]);
 await server();assert.deepEqual(await settle(match,'morro-5'),reward,'retries cannot resurrect a consumed tail');
 const replay=await create('morro-5');const noDrop=await settle(replay,'morro-5');assert.equal(noDrop.tailId,null);assert.equal(noDrop.drop,null);await finish(replay);
 await auth(a);const final=await read();assert.equal(final.rewards.length,1);assert.equal(final.rewards[0].status,'consumed');
 await db.exec('reset role');assert.equal((await db.query("select count(*)::int n from public.summon_tails where owner_id=$1 and reference='trail-first:morro-5'",[a])).rows[0].n,1);assert.equal((await db.query('select equipped_kite_id from public.player_profiles where id=$1',[a])).rows[0].equipped_kite_id,called.kiteId);
 }finally{await db.close();}
});

test('private trail rooms use the server stage and ignore fabricated client completion',async()=>{
 const db=new DatabaseSync(':memory:'),DB={prepare(sql){let args=[];return{bind(...v){args=v;return this;},async run(){return{meta:{changes:Number(db.prepare(sql).run(...args).changes)}};},async first(){return db.prepare(sql).get(...args);}};}};
 const accounts={enabled:true,preparePlayer:async()=>({accountId:a,name:'Ana',color:2}),registerTrail:async()=>({progress:{mastery:0,stars:{'morro-4':3}},revision:1}),release:async()=>{}};
 const call=async(action,body,auth=accounts)=>{const r=await worker.fetch(new Request('https://game.test/api/'+action,{method:'POST',body:JSON.stringify(body)}),{DB,ACCOUNTS:auth});return{status:r.status,...await r.json()};};
 try{assert.equal((await call('trail',{stage:'morro-1'},null)).status,401);assert.equal((await call('trail',{stage:'bad'})).status,400);const room=await call('trail',{stage:'morro-5',won:true,roundsToWin:1,mastery:999,rules:'capture'});assert.equal(room.status,200);assert.equal(room.state.trail,'morro-5');assert.equal(room.state.roundsToWin,3);assert.equal(room.state.rules,'casual');assert.equal(room.state.players[1].ai.level,4);assert.equal(room.state.trailOwner,undefined);assert.equal((await call('join',{code:room.code})).status,403);
 const reply=await call('sync',{code:room.code,token:room.token,trailResult:{userId:a,won:true},input:{}});assert.equal(reply.state.trailResult,undefined);const stored=JSON.parse(db.prepare('select state from pipa_rooms where code=?').get(room.code).state);assert.equal(stored.trailResult,undefined);assert.equal(stored.players[0].rounds,undefined);
 }finally{db.close();}
});

test('trail clinch is private, recovered after restart and delivered before release',async()=>{
 const e=createEngine(),now=Date.now(),s=e.create(now,{mode:'rounds',roundsToWin:2});s.trail='morro-1';s.trailOwner=a;s.code='ABCDEF';const own=e.player('Ana',0,'own',now),bot=e.player('Rival',1,'bot',now);own.accountId=a;bot.bot=true;e.admit(s,own,now);e.admit(s,bot,now);s.phase='live';s.round=2;own.rounds=1;bot.respawn=now+100000;e.step(s,now+16);assert.equal(s.trailResult.won,true);assert.equal(e.visible(s).trailResult,undefined);
 const db=new DatabaseSync(':memory:');db.exec('create table pipa_rooms(code text,state text)');db.prepare('insert into pipa_rooms values(?,?)').run(s.code,JSON.stringify(s));let fail=true;const calls=[],accounts={enabled:true,settleTrail:async()=>{if(fail)throw Error('offline');calls.push('reward');},release:async()=>calls.push('release'),finish:async()=>calls.push('finish')};let p=createProgression(db,accounts);p.release(a,s.id);await p.flush();assert.deepEqual(calls,[]);p.stop();fail=false;db.exec('update pipa_rewards set retry_at=0');p=createProgression(db,accounts);await p.flush();assert.deepEqual(calls,['reward','release']);p.stop();db.close();
});

test('legacy saves survive migration but only new verified wins deliver tails, including concurrent boss replays',async()=>{
 const old={coins:100,stars:Object.fromEntries(createTrails().stages.map(s=>[s.id,1])),mastery:0,wins:15,losses:0,fails:{},items:['rabiola-raio-de-sol','rabiola-chaspiral','rabiola-flautrevo']};
 const db=await setup(async db=>{await db.query('insert into auth.users values($1,$2)',[a,{nickname:'Antigo'}]);await db.exec("set role authenticated;set request.jwt.claim.sub='"+a+"'");await db.query("select public.player_trails('import',$1,$2)",[randomUUID(),old]);await db.exec('reset role');});
 try{
  await db.exec("set role authenticated;set request.jwt.claim.sub='"+a+"'");let read=(await db.query('select public.player_trails() r')).rows[0].r;assert.deepEqual({...read.progress,items:[...read.progress.items].sort()},{...old,items:[...old.items].sort()});assert.deepEqual(read.rewards,[]);
  await db.exec("reset role;set role pipa_server;set request.jwt.claim.sub=''");
  const create=async(stage)=>{const id=randomUUID();await db.query("select public.reserve_player_match($1,$2,'ABCDEF','casual')",[a,id]);await db.query('select public.register_trail_run($1,$2,$3)',[a,id,stage]);await db.query('select public.finish_player_match($1)',[id]);return id;};
  const settle=async(id,stage,won=true,lost=0)=>(await db.query('select public.settle_trail_run($1,$2,$3,$4,$5) r',[a,id,stage,won,lost])).rows[0].r;
  const first=await create('morro-5'),second=await create('morro-5'),awards=await Promise.all([settle(first,'morro-5'),settle(second,'morro-5')]);assert.equal(awards.filter(r=>r.tailId).length,1,'legacy items do not suppress the first real delivery, concurrent wins cannot duplicate it');
  for(const stage of ['praia-5','torres-5']){const id=await create(stage);assert.ok((await settle(id,stage)).tailId);}
  const lost=await create('morro-1');const loss=await settle(lost,'morro-1',false,2);assert.equal(loss.coins,0);assert.equal(loss.tailId,null);assert.equal(loss.stars,0);
  const invalid=await create('morro-1');await assert.rejects(()=>settle(invalid,'morro-1',true,5),/rodadas/);
  await db.exec("reset role;set role authenticated;set request.jwt.claim.sub='"+a+"'");read=(await db.query('select public.player_trails() r')).rows[0].r;assert.equal(read.rewards.length,3);assert.equal(read.progress.coins,100+45*2+75+120);assert.equal(read.progress.losses,1);
  await db.exec('reset role');const catalogue=(await db.query('select id,position,coins,rounds,drop_id,foe_count from public.trail_stages order by position')).rows;assert.deepEqual(catalogue.map(s=>[s.id,s.coins,s.rounds,s.drop_id,s.foe_count]),createTrails().stages.map(s=>[s.id,s.coins,s.rounds,s.drop||null,s.foes.length]));
 }finally{await db.close();}
});

function trailUI(send){
 const {document}=parseHTML('<html><body><div id="body"></div><button id="dialogAction"></button></body></html>'),timers=[],actions=[],accepted=[];
 const el=(tag,text,cls)=>{const node=document.createElement(tag);if(text!==undefined)node.textContent=text;if(cls)node.className=cls;return node;};
 const ctx=vm.createContext({document,console,$:id=>document.getElementById(id),uiElement:el,trails:createTrails(),trailLeaderMarkup:()=>'',escapeHTML:s=>s,ART_CONFIG:{items:[{id:'rabiola-raio-de-sol',name:'Rabiola de Raio de sol',url:'assets/test.png'}]},accountRequest:send,refreshRewards:()=>{},acceptTrailSnapshot:(d,o)=>accepted.push([d,o]),setTimeout:fn=>timers.push(fn),closeTrails:()=>actions.push('close-trails'),openAccount:async()=>actions.push('account'),navigateClub:p=>actions.push(p),returnToDistrict:(id,won)=>actions.push(['district',id,won]),presentStage:id=>actions.push(['preview',id]),startStage:p=>actions.push(p)});
 ctx.actions=actions;ctx.modal=(title,body)=>document.getElementById('body').innerHTML=body;vm.runInContext(`let state={id:'match',trail:'morro-5'},showResult=true,playerAccount={profile:{id:'${a}'}},mode='online';function closeModal(){mode=null;state=null;actions.push('close-result');}function leave(){actions.push('leave');}`,ctx);
 vm.runInContext(fs.readFileSync('src/trail-rewards-client.js','utf8'),ctx);return {document,timers,actions,accepted,run:code=>vm.runInContext(code,ctx),settle:()=>new Promise(r=>setImmediate(r))};
}
test('results wait for confirmed rewards and the invoker button exits the match before opening the NPC',async()=>{
 let count=0;const calls=[],app=trailUI(async(action,payload)=>{calls.push([action,payload]);return ++count===1?{status:'saving',trails:{result:null}}:{status:'saved',trails:{result:{won:true,stars:3,coins:45,firstClear:false,drop:'rabiola-raio-de-sol',tailId:'tail'}}};});
 app.run("showOnlineTrailResult(state,[],{rounds:3})");await app.settle();assert.equal(app.document.querySelector('#trailGoSummoner'),null);assert.doesNotMatch(app.document.body.textContent,/recebida na conta/);
 app.timers.shift()();await app.settle();assert.match(app.document.body.textContent,/Resultado salvo/);assert.match(app.document.body.textContent,/45 moedas confirmadas/);assert.ok(app.document.querySelector('#trailGoSummoner'));assert.deepEqual(calls.map(c=>[c[0],c[1].matchId]),[['trail-result','match'],['trail-result','match']]);
 await app.document.querySelector('#trailGoSummoner').onclick();assert.deepEqual(app.actions,['close-trails','close-result','account','summon']);
});
test('late trail rewards cannot update a different account or a closed result screen',async()=>{
 let resolve;const app=trailUI(()=>new Promise(r=>resolve=r));app.run("showOnlineTrailResult(state,[],{rounds:3});playerAccount={profile:{id:'other'}}");resolve({status:'saved',trails:{result:{won:true,stars:3,coins:999}}});await app.settle();assert.equal(app.accepted.length,0);assert.doesNotMatch(app.document.body.textContent,/999|Resultado salvo/);
});

test('an abandoned solo trail releases its account after connection expiry without inventing a reward',async()=>{
 const db=new DatabaseSync(':memory:');db.exec('create table pipa_rooms(code text,state text,rev int,updated int)');const state={id:randomUUID(),trail:'morro-1',end:Date.now()+600000,last:Date.now()-20000,players:[{id:'p',accountId:a,seen:Date.now()-20000}],events:[]};db.prepare('insert into pipa_rooms values(?,?,0,?)').run('ABCDEF',JSON.stringify(state),Date.now()-20000);const calls=[],p=createProgression(db,{enabled:true,settleTrail:async()=>calls.push('reward'),finish:async id=>calls.push(id)});try{await p.flush();assert.deepEqual(calls,[state.id]);assert.ok(JSON.parse(db.prepare('select state from pipa_rooms').get().state).end<=Date.now());}finally{p.stop();db.close();}
});

test('confirmed trail wins return to the district map instead of starting a second battle',async()=>{const app=trailUI(async()=>({status:'saved',trails:{result:{won:true,stars:2,coins:45}}}));app.run('showOnlineTrailResult(state,[],{rounds:3})');await app.settle();assert.equal(app.document.querySelector('#rematchButton').textContent,'Ver meu caminho ▶');app.document.querySelector('#rematchButton').onclick();assert.deepEqual(app.actions,[['district','morro-5',true]]);});

test('retrying a confirmed defeat restores the district before opening the encounter presentation',async()=>{const app=trailUI(async()=>({status:'saved',trails:{result:{won:false,stars:0,coins:0}}}));app.run('showOnlineTrailResult(state,[],{rounds:0})');await app.settle();app.document.querySelector('#rematchButton').onclick();assert.deepEqual(app.actions,[['district','morro-5',false],['preview','morro-5']]);});
