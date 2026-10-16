import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {PGlite} from '@electric-sql/pglite';
import {createAccounts} from './src/accounts.js';
import {createEngine} from './src/engine.js';
import {createProgression} from './src/progression.js';
import {DatabaseSync} from 'node:sqlite';
import {createGameDatabase} from './src/game-database.js';

const userA='11111111-1111-4111-8111-111111111111',userB='22222222-2222-4222-8222-222222222222',match='33333333-3333-4333-8333-333333333333';
test('real PostgreSQL schema: signup grants one inventory, ownership is protected, cuts transfer once and casual preserves items',async()=>{
 const db=new PGlite();try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;grant execute on function auth.uid() to authenticated,anon,service_role;");
  await db.exec(fs.readFileSync('supabase/migrations/001_accounts_inventory.sql','utf8'));
  await db.exec(fs.readFileSync('supabase/migrations/002_restricted_server.sql','utf8'));
  await db.exec(fs.readFileSync('supabase/migrations/003_results_and_kite_history.sql','utf8'));
  await db.exec('set role pipa_server');
  await assert.rejects(()=>db.query('select * from auth.users'));
  await assert.rejects(()=>db.query('select * from public.player_profiles'));
  await assert.rejects(()=>db.query('update public.player_profiles set xp=9999'));
  await assert.rejects(()=>db.query("select public.ensure_player($1,'Fake')",[userA]));
  assert.equal((await db.query("select pg_has_role('pipa_server','service_role','MEMBER') as elevated")).rows[0].elevated,false);
  const role=(await db.query("select rolcanlogin,rolsuper,rolcreaterole,rolcreatedb,rolbypassrls from pg_roles where rolname='pipa_server'")).rows[0];
  assert.ok(Object.values(role).every(v=>v===false));
  await db.exec('reset role');
  await db.query('insert into auth.users values($1,$2),($3,$4)',[userA,{nickname:'Ana'},userB,{nickname:'Beto'}]);
  assert.equal((await db.query('select count(*)::int as n from public.player_kites where owner_id=$1',[userA])).rows[0].n,4);
  await db.query('select public.ensure_player($1,$2)',[userA,'Ana']);assert.equal((await db.query('select count(*)::int as n from public.player_kites where owner_id=$1',[userA])).rows[0].n,4);
  await db.exec("set role authenticated;set request.jwt.claim.sub='"+userA+"'");
  assert.equal((await db.query('select count(*)::int as n from public.player_profiles')).rows[0].n,1);
  await assert.rejects(()=>db.query('update public.player_profiles set xp=9999'));
  await assert.rejects(()=>db.query('select public.settle_player_cut($1,$2,$3,$4,null)',['forged',match,userA,userB]));
  const kiteB=(await db.query('select id from public.player_kites where owner_id=$1 and model_id=$2',[userB,'mata'])).rows[0];assert.equal(kiteB,undefined,'RLS must hide another inventory');
  await db.exec('reset role');
  const a=(await db.query("select id from public.player_kites where owner_id=$1 and model_id='mata'",[userA])).rows[0].id;
  const b=(await db.query("select id from public.player_kites where owner_id=$1 and model_id='azulao'",[userB])).rows[0].id;
  await db.query('update public.player_profiles set equipped_kite_id=$1 where id=$2',[a,userA]);await db.query('update public.player_profiles set equipped_kite_id=$1 where id=$2',[b,userB]);
  await db.exec('set role pipa_server');
  await db.query('select public.reserve_player_match($1,$2,$3,$4)',[userA,match,'ABCDEF','capture']);await db.query('select public.reserve_player_match($1,$2,$3,$4)',[userB,match,'ABCDEF','capture']);
  const cut=await db.query('select public.settle_player_cut($1,$2,$3,$4,$5) as r',[match+':1',match,userA,userB,b]);assert.equal(cut.rows[0].r.captured,true);assert.equal(cut.rows[0].r.xp,25);
  const again=await db.query('select public.settle_player_cut($1,$2,$3,$4,$5) as r',[match+':1',match,userA,userB,b]);assert.equal(again.rows[0].r.duplicate,true);
  await db.exec('reset role');
  assert.equal((await db.query('select xp::int from public.player_profiles where id=$1',[userA])).rows[0].xp,25);
  assert.equal((await db.query('select owner_id from public.player_kites where id=$1',[b])).rows[0].owner_id,userA);
  assert.equal((await db.query('select k.permanent from public.player_profiles p join public.player_kites k on k.id=p.equipped_kite_id where p.id=$1',[userB])).rows[0].permanent,true);
  for(let i=2;i<=7;i++)await db.query('select public.settle_player_cut($1,$2,$3,$4,null)',[match+':'+i,match,userA,userB]);
  assert.equal((await db.query('select xp::int from public.player_profiles where id=$1',[userA])).rows[0].xp,125);
  await db.query('select public.finish_player_match($1)',[match]);
  assert.equal((await db.query('select active_match from public.player_profiles where id=$1',[userB])).rows[0].active_match,null);
  const casual='44444444-4444-4444-8444-444444444444';
  await db.query('select public.reserve_player_match($1,$2,$3,$4)',[userA,casual,'AABBCC','casual']);await db.query('select public.reserve_player_match($1,$2,$3,$4)',[userB,casual,'AABBCC','casual']);
  assert.equal((await db.query('select public.settle_player_cut($1,$2,$3,$4,$5) as r',[casual+':1',casual,userB,userA,a])).rows[0].r.captured,false);
  assert.equal((await db.query('select owner_id from public.player_kites where id=$1',[a])).rows[0].owner_id,userA);
  await db.exec('set role pipa_server');
  class RealPostgresPool{on(){}query(sql,values){return db.query(sql,values);}}
  await createGameDatabase({PIPA_DB_HOST:'test',PIPA_DB_USER:'pipa_server',PIPA_DB_PASSWORD:'test-only'},{Pool:RealPostgresPool}).verify();
  await db.exec('reset role');
  await db.query('update public.player_profiles set nickname=$1 where id=$2',['Novo apelido',userB]);
  await db.exec("set role authenticated;set request.jwt.claim.sub='"+userA+"'");
  const result=(await db.query('select public.get_player_match_result($1) as r',[match])).rows[0].r;
  assert.equal(result.totals.xp,125);assert.equal(result.totals.cuts,7);assert.equal(result.totals.captured,1);assert.equal(result.totals.lost,0);
  assert.equal(result.events.find(e=>e.captured).opponent,'Beto','past events preserve the name used in the duel');
  assert.ok(!JSON.stringify(result).includes(userB),'results do not reveal other account identifiers');
  const story=(await db.query('select public.get_kite_history($1) as r',[b])).rows[0].r;
  assert.equal(story.captureCount,1);assert.equal(story.captures[0].from,'Beto');assert.equal(story.captures[0].to,'Ana');
  assert.equal((await db.query('select public.get_player_recent_matches() as r')).rows[0].r.length,2);
  await db.exec("set request.jwt.claim.sub='"+userB+"'");
  await assert.rejects(()=>db.query('select public.get_kite_history($1)',[b]),/coleção/);
  const loser=(await db.query('select public.get_player_match_result($1) as r',[match])).rows[0].r;assert.equal(loser.totals.lost,1);assert.equal(loser.totals.xp,0);
  await db.exec("set request.jwt.claim.sub='55555555-5555-4555-8555-555555555555'");
  await assert.rejects(()=>db.query('select public.get_player_match_result($1)',[match]),/histórico/);
  assert.deepEqual((await db.query('select public.get_player_recent_matches() as r')).rows[0].r,[]);
  await db.exec('reset role');
 }finally{await db.close();}
});

test('auth returns HttpOnly cookies, never exposes keys, and rejects foreign origins',async()=>{
 const env={SUPABASE_URL:'https://project.supabase.co',SUPABASE_PUBLISHABLE_KEY:'public-key'};
 const calls=[],session={access_token:'access-secret',refresh_token:'refresh-secret',expires_in:3600,user:{id:userA}};
 const fetcher=async(url,options)=>{calls.push({url,options});return new Response(JSON.stringify(url.includes('/token')?session:url.endsWith('/auth/v1/user')?session.user:{profile:{id:userA,nickname:'Ana',xp:0,cuts:0},inventory:[]}));};
 const databaseCalls=[],gameDatabase={async rpc(name,body){databaseCalls.push({name,body});return {accountId:userA};}};
 const accounts=createAccounts(env,{fetcher,gameDatabase});
 const config=await accounts.handle(new Request('https://game.test/account/config'));assert.deepEqual(await config.json(),{enabled:true,features:{inventory:true,xp:true,capture:true}});
 const login=await accounts.handle(new Request('https://game.test/account/login',{method:'POST',headers:{'Content-Type':'application/json',Origin:'https://game.test'},body:JSON.stringify({email:'ana@example.com',password:'safe-password'})}));
 assert.equal(login.status,200);const cookies=login.headers.getSetCookie();assert.equal(cookies.length,2);assert.ok(cookies.every(c=>c.includes('HttpOnly')&&c.includes('Secure')&&c.includes('__Host-')));
 const body=await login.text();assert.ok(!body.includes('access-secret'));assert.ok(!body.includes('private-secret'));
 await accounts.preparePlayer(new Request('https://game.test/api/create',{headers:{cookie:'__Host-pipa_access=access-secret'}}),{id:match,code:'ABCDEF',rules:'casual',players:[]});
 assert.equal(databaseCalls[0].name,'reserve_player_match');
 assert.equal(databaseCalls[0].body.p_user,userA);
 assert.ok(calls.every(c=>c.options.headers.apikey==='public-key'));
 const foreign=await accounts.handle(new Request('https://game.test/account/login',{method:'POST',headers:{Origin:'https://evil.test','Content-Type':'application/json'},body:'{}'}));assert.equal(foreign.status,403);
});

test('restricted DB adapter verifies TLS, binds values and refuses arbitrary operations or admin logins',async()=>{
 let configuration;const queries=[];
 class Pool{constructor(config){configuration=config;}on(){}async query(sql,values){queries.push({sql,values});return {rows:[sql.startsWith('SELECT current_user')?{role:'pipa_server',restricted:true,safe_schema:true,protected_tables:true,game_functions:true}:{result:{captured:true}}]};}async end(){}}
 const env={PIPA_DB_HOST:'pooler.example.test',PIPA_DB_USER:'pipa_server.project',PIPA_DB_PASSWORD:'private-password'};
 const db=createGameDatabase(env,{Pool});
 assert.equal(configuration.ssl.rejectUnauthorized,true);assert.equal(configuration.max,2);
 const event="event'); DROP TABLE users;--";
 assert.deepEqual(await db.rpc('settle_player_cut',{p_event:event,p_match:match,p_winner:userA,p_loser:userB,p_kite:null}),{captured:true});
 assert.ok(!queries[0].sql.includes(event));assert.equal(queries[0].values[0],event);
 await assert.rejects(()=>db.rpc('ensure_player',{}));await assert.rejects(()=>db.rpc('constructor',{}));
 assert.throws(()=>createGameDatabase({...env,PIPA_DB_USER:'postgres.project'},{Pool}),/restricted/);
 assert.equal(createGameDatabase({}),null);
 await db.verify();
});
test('a capture switches the loser to a permanent kite and keeps reward metadata private',()=>{
 const e=createEngine(),s=e.create(1000);s.rules='capture';const a=e.player('A',0,'a',1000),b=e.player('B',1,'b',1000);Object.assign(a,{accountId:userA,key:'secretA'});Object.assign(b,{accountId:userB,kiteId:'collectible',basicKiteId:'basic',kitePermanent:false,key:'secretB'});a.x=b.x=400;a.y=b.y=200;a.input={cut:true};b.hp=1;s.players=[a,b];e.step(s,1100);assert.equal(b.kiteId,'basic');assert.equal(s.events[0].kiteId,'collectible');const publicState=JSON.stringify(e.visible(s));assert.ok(!publicState.includes(userA));assert.ok(!publicState.includes('secretA'));assert.ok(!publicState.includes('collectible'));
});
test('every simultaneous cut is queued, and leaving waits for pending captures to settle',async()=>{
 const db=new DatabaseSync(':memory:'),calls=[];let fail=true;
 const accounts={enabled:true,async settle(e){calls.push(e.id);if(fail)throw Error('offline');},async release(){calls.push('release');},async finish(){calls.push('finish');}};
 const rewards=createProgression(db,accounts);
 try{
  const cuts=Array.from({length:6},(_,i)=>({id:match+':'+i,matchId:match,winnerAccountId:userA,loserAccountId:userB}));
  rewards.observe({id:match,code:'ABCDEF',last:1000,end:2000,events:cuts.slice(0,4),_pendingCuts:cuts});rewards.release(userB,match);
  assert.equal(db.prepare('SELECT count(*) AS n FROM pipa_rewards').get().n,7);
  await rewards.flush();assert.ok(!calls.includes('release'));
  fail=false;db.prepare('UPDATE pipa_rewards SET retry_at=0').run();await rewards.flush();assert.equal(calls.at(-1),'release');assert.equal(db.prepare('SELECT count(*) AS n FROM pipa_rewards').get().n,0);
 }finally{rewards.stop();db.close();}
});

test('result status never confirms saving while rewards remain pending and authorizes before local finalization',async()=>{
 const env={SUPABASE_URL:'https://project.test',SUPABASE_PUBLISHABLE_KEY:'public'};
 let progressCalls=0,progress={found:true,finished:true,pending:true},endedAt=new Date().toISOString(),deny=false;
 const fetcher=async url=>url.endsWith('/auth/v1/user')?new Response(JSON.stringify({id:userA})):deny?new Response(JSON.stringify({message:'Esta partida não está no seu histórico.'}),{status:400}):new Response(JSON.stringify({match:{endedAt},totals:{},events:[]}));
 const accounts=createAccounts(env,{fetcher,gameDatabase:{},matchProgress(){progressCalls++;return progress;}});
 const req=()=>new Request('https://game.test/account/match-result',{method:'POST',headers:{'Content-Type':'application/json',cookie:'__Host-pipa_access=valid'},body:JSON.stringify({matchId:match})});
 assert.equal((await (await accounts.handle(req())).json()).status,'saving');
 progress.pending=false;assert.equal((await (await accounts.handle(req())).json()).status,'saved');
 endedAt=null;progress.finished=false;assert.equal((await (await accounts.handle(req())).json()).status,'playing');
 progress.found=false;assert.equal((await (await accounts.handle(req())).json()).status,'unconfirmed');
 const before=progressCalls;deny=true;assert.equal((await accounts.handle(req())).status,400);assert.equal(progressCalls,before);
});

test('reading an ended HTTP-only match queues its finalization and waits for cuts',async()=>{
 const db=new DatabaseSync(':memory:');db.exec('CREATE TABLE pipa_rooms(code TEXT,state TEXT)');
 db.prepare('INSERT INTO pipa_rooms VALUES(?,?)').run('ABCDEF',JSON.stringify({id:match,end:Date.now()-1}));
 let fail=true;const calls=[];
 const rewards=createProgression(db,{enabled:true,async settle(){if(fail)throw Error('offline');},async finish(){calls.push('finished');}});
 try{
  rewards.observe({id:match,code:'ABCDEF',last:0,end:Date.now()+1000,events:[{id:match+':1',matchId:match,winnerAccountId:userA,loserAccountId:userB}]});
  assert.equal(rewards.status(match).pending,true);await rewards.flush();assert.deepEqual(calls,[]);
  fail=false;db.exec('UPDATE pipa_rewards SET retry_at=0');await rewards.flush();
  assert.deepEqual(calls,['finished']);assert.deepEqual(rewards.status(match),{found:true,finished:true,pending:false});
 }finally{rewards.stop();db.close();}
});
