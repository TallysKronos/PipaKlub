import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {PGlite} from '@electric-sql/pglite';
import {createAccounts} from './src/accounts.js';
import {createEngine} from './src/engine.js';
import {createProgression} from './src/progression.js';
import {DatabaseSync} from 'node:sqlite';

const userA='11111111-1111-4111-8111-111111111111',userB='22222222-2222-4222-8222-222222222222',match='33333333-3333-4333-8333-333333333333';
test('real PostgreSQL schema: signup grants one inventory, ownership is protected, cuts transfer once and casual preserves items',async()=>{
 const db=new PGlite();try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;grant execute on function auth.uid() to authenticated,anon,service_role;");
  await db.exec(fs.readFileSync('supabase/migrations/001_accounts_inventory.sql','utf8'));
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
  await db.query('select public.reserve_player_match($1,$2,$3,$4)',[userA,match,'ABCDEF','capture']);await db.query('select public.reserve_player_match($1,$2,$3,$4)',[userB,match,'ABCDEF','capture']);
  const cut=await db.query('select public.settle_player_cut($1,$2,$3,$4,$5) as r',[match+':1',match,userA,userB,b]);assert.equal(cut.rows[0].r.captured,true);assert.equal(cut.rows[0].r.xp,25);
  const again=await db.query('select public.settle_player_cut($1,$2,$3,$4,$5) as r',[match+':1',match,userA,userB,b]);assert.equal(again.rows[0].r.duplicate,true);
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
 }finally{await db.close();}
});

test('auth returns HttpOnly cookies, never exposes keys, and rejects foreign origins',async()=>{
 const env={SUPABASE_URL:'https://project.supabase.co',SUPABASE_PUBLISHABLE_KEY:'public-key',SUPABASE_SECRET_KEY:'private-secret'};
 const calls=[],session={access_token:'access-secret',refresh_token:'refresh-secret',expires_in:3600,user:{id:userA}};
 const fetcher=async(url,options)=>{calls.push({url,options});return new Response(JSON.stringify(url.includes('/token')?session:{profile:{id:userA,nickname:'Ana',xp:0,cuts:0},inventory:[]}));};
 const accounts=createAccounts(env,{fetcher});
 const config=await accounts.handle(new Request('https://game.test/account/config'));assert.deepEqual(await config.json(),{enabled:true,features:{inventory:true,xp:true,capture:true}});
 const login=await accounts.handle(new Request('https://game.test/account/login',{method:'POST',headers:{'Content-Type':'application/json',Origin:'https://game.test'},body:JSON.stringify({email:'ana@example.com',password:'safe-password'})}));
 assert.equal(login.status,200);const cookies=login.headers.getSetCookie();assert.equal(cookies.length,2);assert.ok(cookies.every(c=>c.includes('HttpOnly')&&c.includes('Secure')&&c.includes('__Host-')));
 const body=await login.text();assert.ok(!body.includes('access-secret'));assert.ok(!body.includes('private-secret'));
 const foreign=await accounts.handle(new Request('https://game.test/account/login',{method:'POST',headers:{Origin:'https://evil.test','Content-Type':'application/json'},body:'{}'}));assert.equal(foreign.status,403);
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
