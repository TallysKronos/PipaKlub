import {seedCollection} from './test-support/collection-fixture.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {DatabaseSync} from 'node:sqlite';
import {PGlite} from '@electric-sql/pglite';
import {createEngine} from './src/engine.js';
import {createNetworkView} from './src/network-view.js';
import {createProgression} from './src/progression.js';
import {createAccounts} from './src/accounts.js';
import worker from './worker/index.js';
const uid='11111111-1111-4111-8111-111111111111',other='22222222-2222-4222-8222-222222222222';

test('daily calendar changes only at UTC midnight; weather affects both pilots and prediction',()=>{
 const e=createEngine(),before=Date.parse('2026-10-17T23:59:59.999Z'),after=before+1;
 assert.equal(e.daily(before).date,'2026-10-17');assert.equal(e.daily(after).date,'2026-10-18');assert.notEqual(e.daily(before).weather,e.daily(after).weather);
 assert.equal(new Set(Array.from({length:4},(_,i)=>e.daily(after+i*86400000).weather)).size,4);
 const p=e.player('A',0,'you',1000);Object.assign(p,{energy:30,x:300,y:200,anchorX:90});
 const dry=structuredClone(p),wet=structuredClone(p);e.move(dry,{},.1);e.move(wet,{},.1,0,'rain');assert.ok(wet.energy<dry.energy);
 const s=e.create(1000,{mode:'rounds'});s.phase='live';s.phaseUntil=60000;s.daily={...e.daily(1000),weather:'rain'};s.players=[p];
 const view=createNetworkView(e);view.receive(e.visible(s),'you',1000);const predicted=view.render(1100,{},.1)[0];assert.equal(predicted.energy,wet.energy);
 s.daily.weather='wind';e.step(s,1100);assert.equal(s.wind,Math.sin(1100/9000)*36);assert.equal(s.daily.weather,'wind');
 // A clinching round freezes the winner; public snapshots never leak its account id.
 const win=e.create(1000,{mode:'rounds',roundsToWin:2}),human=e.player('A',0,'a',1000),bot=e.player('B',0,'b',1000);
 Object.assign(human,{rounds:1,accountId:uid});Object.assign(bot,{bot:true,respawn:900});win.daily=e.daily(1000);win.players=[human,bot];win.phase='live';win.phaseUntil=60000;e.step(win,1100);
 assert.equal(win.dailyResult.accountId,uid);assert.equal(e.visible(win).dailyResult,undefined);
});

test('daily bonus is server-only, atomic, once per account/day across matches and retries',async()=>{
 const db=new PGlite();try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;grant execute on function auth.uid() to authenticated,anon,service_role;");
  for(const f of fs.readdirSync('supabase/migrations').filter(f=>f.endsWith('.sql')).sort())await db.exec(fs.readFileSync('supabase/migrations/'+f,'utf8'));
  for(const id of [uid,other])await db.query('insert into auth.users values($1,$2)',[id,{nickname:'Teste'}]);
await seedCollection(db,[uid,other]);
  const today=(await db.query("select to_char(now() at time zone 'UTC','YYYY-MM-DD') d")).rows[0].d,match=crypto.randomUUID(),second=crypto.randomUUID();
  const reward=(user=uid,m=match,day=today)=>db.query('select public.settle_daily_challenge($1,$2,$3) r',[user,m,day]);
  await db.exec('set role anon');await assert.rejects(()=>db.query('select public.player_daily()'),/permission denied/);
  await db.exec("reset role;set role authenticated;set request.jwt.claim.sub='"+uid+"'");
  await assert.rejects(()=>reward(),/permission denied/);await assert.rejects(()=>db.query('insert into public.daily_challenge_rewards values($1,$2,$3,25,now())',[uid,today,match]),/permission denied/);
  const initial=(await db.query('select public.player_daily() d')).rows[0].d;assert.equal(initial.claimed,false);assert.equal(initial.weather,createEngine().daily(Date.parse(today+'T12:00Z')).weather);
  await db.exec('reset role;set role pipa_server');
  await db.query("select public.reserve_player_match($1,$2,'DA1A00','casual')",[uid,match]);
  await assert.rejects(()=>reward(other),/inválido/);await assert.rejects(()=>reward(uid,match,'1999-01-01'),/inválido/);
  const results=await Promise.all([reward(),reward()]);assert.equal(results.filter(r=>r.rows[0].r.credited).length,1);
  await db.query('select public.finish_player_match($1)',[match]);await db.query("select public.reserve_player_match($1,$2,'DA1A01','casual')",[uid,second]);
  assert.equal((await reward(uid,second)).rows[0].r.credited,false);
  await db.exec("reset role;set role authenticated;set request.jwt.claim.sub='"+uid+"'");
  const current=(await db.query('select public.player_daily() d')).rows[0].d;assert.equal(current.claimed,true);assert.equal(current.progress.coins,25);assert.equal(current.revision,1);
  // Purchases debit the same locked wallet, and a reward replay cannot refund the purchase.
  // Trusted fixture; unverified imports are now archived without minting currency.
  await db.exec('reset role');await db.query("update public.player_trails set progress=jsonb_set(progress,'{coins}',to_jsonb((progress->>'coins')::int+10)),revision=revision+1 where owner_id=$1",[uid]);await db.exec("set role authenticated;set request.jwt.claim.sub='"+uid+"'");await db.query("select public.player_lines('buy','azul',$1)",[crypto.randomUUID()]);
  await db.exec('reset role;set role pipa_server');await reward();
  await db.exec("reset role;set role authenticated;set request.jwt.claim.sub='"+uid+"'");assert.equal((await db.query('select public.player_daily() d')).rows[0].d.progress.coins,5);
  await db.exec("reset role;set role authenticated;set request.jwt.claim.sub='"+other+"'");assert.equal((await db.query('select public.player_daily() d')).rows[0].d.claimed,false);
 }finally{await db.close();}
});

test('a daily win survives disconnect, failed saving and server restart; loss grants no bonus',async()=>{
 const db=new DatabaseSync(':memory:');db.exec('CREATE TABLE pipa_rooms(code TEXT,state TEXT)');
 let reject=true;const rewards=[],finished=[],accounts={enabled:true,settleDaily:async e=>{if(reject)throw Error('offline');rewards.push(e);},finish:async id=>finished.push(id)};
 let progress=createProgression(db,accounts);const s={id:crypto.randomUUID(),code:'DA1A00',events:[],players:[],daily:{date:'2026-10-17'},dailyResult:{accountId:uid},last:1000,end:2000};
 db.prepare('INSERT INTO pipa_rooms VALUES(?,?)').run(s.code,JSON.stringify(s));progress.observe(s);await progress.flush();assert.equal(rewards.length,0);assert.equal(finished.length,0);progress.stop();
 reject=false;db.prepare('UPDATE pipa_rewards SET retry_at=0').run();progress=createProgression(db,accounts);assert.equal(progress.status(s.id).pending,true);await progress.flush();assert.equal(rewards.length,1);assert.equal(finished.length,1);assert.equal(progress.status(s.id).pending,false);
 const loss={...s,id:crypto.randomUUID(),dailyResult:{accountId:null},last:2000};progress.observe(loss);await progress.flush();assert.equal(rewards.length,1);progress.stop();db.close();
});

test('daily rooms require login, ignore client modifiers/results, reject guests and other joiners',async()=>{
 const db=new DatabaseSync(':memory:'),DB={prepare(sql){let values=[];return {bind(...v){values=v;return this;},async run(){return {meta:{changes:Number(db.prepare(sql).run(...values).changes)}};},async first(){return db.prepare(sql).get(...values);}};}};
 const call=async(action,body,accounts)=>{const response=await worker.fetch(new Request('https://game.test/api/'+action,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)}),{DB,ACCOUNTS:accounts});return {status:response.status,...await response.json()};};
 try{
  assert.equal((await call('daily',{})).status,401);
  const accounts={enabled:true,preparePlayer:async()=>({accountId:uid,name:'Ana'}),release:async()=>{}};
  const room=await call('daily',{daily:{date:'1999-01-01',weather:'forged'},roundsToWin:1,won:true},accounts);
  assert.equal(room.status,200);assert.equal(room.state.daily.date,createEngine().daily().date);assert.equal(room.state.roundsToWin,2);assert.equal(room.state.players.length,2);assert.equal(room.state.players.filter(p=>p.bot).length,1);
  assert.equal((await call('join',{code:room.code},accounts)).status,403);assert.equal((await call('join',{code:room.code})).status,403);
  const normal=await call('create',{daily:true,mode:'rounds'});assert.equal(normal.state.daily,undefined);
  const sync=await call('sync',{code:room.code,token:room.token,input:{x:0},won:true,dailyResult:{accountId:uid},rounds:2},accounts);assert.equal(sync.state.players[0].rounds,undefined);
 }finally{db.close();}
});

test('daily account endpoint is read-only and never accepts a client reward claim',async()=>{
 const calls=[],api=createAccounts({SUPABASE_URL:'https://supabase.test',SUPABASE_ANON_KEY:'public'},{gameDatabase:{},fetcher:async(url,options)=>{if(url.endsWith('/auth/v1/user'))return new Response(JSON.stringify({id:uid}));calls.push({url,body:JSON.parse(options.body)});return new Response(JSON.stringify({claimed:false}));}});
 const call=headers=>api.handle(new Request('https://game.test/account/daily',{method:'POST',headers:{'Content-Type':'application/json',...headers},body:JSON.stringify({won:true,reward:999,userId:other})}));
 assert.equal((await call({})).status,401);assert.equal((await call({cookie:'__Host-pipa_access=test',origin:'https://foreign.test'})).status,403);assert.equal((await call({cookie:'__Host-pipa_access=test'})).status,200);assert.ok(calls[0].url.endsWith('/player_daily'));assert.deepEqual(calls[0].body,{});
});
