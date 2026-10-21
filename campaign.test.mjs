import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {PGlite} from '@electric-sql/pglite';
import {createAccounts} from './src/accounts.js';
import {createWorldNavigation} from './src/world-navigation.js';
import {artConfig} from './scripts/art-build.mjs';

test('campaign saves isolate accounts, enforce 30 + 20 capacities, reset safely and birth a new Rabbito',async()=>{
 const db=new PGlite(),a='11111111-1111-4111-8111-111111111111',b='22222222-2222-4222-8222-222222222222';
 try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;grant execute on function auth.uid() to authenticated,anon,service_role;");
  for(const f of fs.readdirSync('supabase/migrations').filter(f=>f.endsWith('.sql')).sort())await db.exec(fs.readFileSync('supabase/migrations/'+f,'utf8'));
  for(const id of [a,b]){await db.query('insert into auth.users values($1,$2)',[id,{nickname:'Tester'}]);await db.query('select public.ensure_player($1,$2)',[id,'Tester']);}
  const auth=async id=>db.exec("reset role;set role authenticated;set request.jwt.claim.sub='"+id+"'");
  const call=async(action='read',revision=null,keep=null,seen=null,confirmation=null,checkpoint=null)=>(await db.query('select public.player_campaign($1,$2,$3,$4,$5,$6) r',[action,revision,checkpoint,keep,seen,confirmation])).rows[0].r;
  const owned=async()=>(await db.query('select id from public.player_kites where owner_id=$1 order by id',[a])).rows.map(k=>k.id);
  await auth(a);let save=await call();assert.equal(save.capacity,20);assert.equal(save.saveCapacity,30);
  save=await call('save',save.revision,null,null,null,{scene:'quintal',x:240,y:520,direction:3});assert.equal(save.checkpoint.x,240);
  assert.equal(save.autosave_enabled,true);
  save=await call('autosave',save.revision,null,null,null,{scene:'quintal',x:280,y:530,direction:1});
  assert.equal(save.autosave_checkpoint.x,280);assert.equal(save.checkpoint.x,240,'slot 0 preserves manual slot 1');assert.ok(save.autosave_at);
  save=await call('settings',save.revision,null,null,null,{enabled:false});
  await assert.rejects(()=>call('autosave',save.revision,null,null,null,{scene:'quintal',x:300,y:530,direction:1}),/desligado/);
  await assert.rejects(()=>call('settings',save.revision,null,null,null,{enabled:'yes'}),/configuração inválida/);
  await assert.rejects(()=>db.query('select public.player_campaign_base()'),/permission denied/);
  save=await call('settings',save.revision,null,null,null,{enabled:true});
  await assert.rejects(()=>call('save',0,null,null,null,{scene:'quintal',x:0,y:0,direction:0}),/outra aba/);
  await assert.rejects(()=>call('save',save.revision,null,null,null,{scene:'morro-area-5',x:0,y:0,direction:0}),/primeiro voo/);
  await auth(b);assert.equal((await call()).checkpoint,null);await assert.rejects(()=>db.query('select * from public.player_campaign_saves'),/permission denied/);
  await db.exec('reset role');
  await db.query("insert into public.player_kites(owner_id,model_id) select $1,'basica' from generate_series(1,30)",[a]);
  await assert.rejects(()=>db.query("insert into public.player_kites(owner_id,model_id) values($1,'basica')",[a]),/save cheio/);
  let ids=await owned();await auth(a);save=await call('protect',save.revision,ids.slice(0,20),ids);assert.equal(save.storage.length,20);
  await assert.rejects(()=>call('protect',save.revision,ids.slice(0,21),ids),/até 20/);
  await assert.rejects(()=>call('protect',save.revision,ids.slice(0,20),[]),/coleção mudou/);
  await db.exec('reset role');await db.query("insert into public.player_kites(owner_id,model_id) select $1,'basica' from generate_series(1,20)",[a]);ids=await owned();
  await assert.rejects(()=>db.query("insert into public.player_kites(owner_id,model_id) values($1,'basica')",[a]),/save cheio/);
  await auth(a);await assert.rejects(()=>call('protect',save.revision,ids.slice(0,19),ids),/30 espaços/);
  await db.exec('reset role');
  await db.query("insert into public.player_trails(owner_id,progress) values($1,public.normalize_trails($2))",[a,{coins:100,stars:{'morro-1':3}}]);
  const abandoned='33333333-3333-4333-8333-333333333333';
  await db.query("insert into public.game_matches(id,room_code,mode) values($1,'ABCDEF','casual')",[abandoned]);
  await db.query("insert into public.trail_runs(match_id,owner_id,stage_id) values($1,$2,'morro-1')",[abandoned,a]);
  await db.query("update public.player_profiles set active_match=$2,active_until=now()+interval '1 minute' where id=$1",[a,abandoned]);
  await auth(a);await assert.rejects(()=>call('reset',save.revision,ids.slice(0,20),ids,'EXCLUIR SAVE'),/Saia da partida/);
  await db.exec('reset role');await db.query('update public.player_profiles set active_match=null,active_until=null where id=$1',[a]);await auth(a);
  await assert.rejects(()=>call('reset',save.revision,ids.slice(0,20),ids,'wrong'),/EXCLUIR SAVE/);
  const globals=save.storage.map(s=>s.kiteId);
  save=await call('reset',save.revision,globals,ids,'EXCLUIR SAVE');assert.equal(save.generation,1);assert.equal(save.checkpoint,null);assert.equal(save.storage.length,20);assert.equal(save.autosave_checkpoint,null);assert.equal(save.autosave_at,null);assert.equal(save.autosave_enabled,true);
  await db.exec('reset role');assert.equal((await owned()).length,20);
  assert.equal((await db.query("select progress->>'coins' coins from public.player_trails where owner_id=$1",[a])).rows[0].coins,'100');
  await db.exec('set role pipa_server');assert.equal((await db.query("select public.settle_trail_run($1,$2,'morro-1',true,0) r",[a,abandoned])).rows[0].r.cancelled,true);
  await db.exec('reset role');await auth(a);await db.exec('reset role');
  const rewarded=(await db.query("select public.apply_trail_progress('result',gen_random_uuid(),$1) r",[{stage:'morro-1',won:true,roundsLost:0}])).rows[0].r;
  assert.equal(rewarded.progress.coins,115,'a reset never repeats the 10-coin first-clear bonus');
  const birth=async()=>{
   await auth(a);for(let step=0;step<10;step++)await db.query("select public.player_opening('advance',$1,null)",[step]);
   const o=(await db.query("select public.player_opening('name',10,'Rabbito') r")).rows[0].r;
   assert.equal((await db.query("select public.player_opening('name',10,'Rabbito') r")).rows[0].r.partner_id,o.partner_id);return o.partner_id;
  };
  const first=await birth();await db.exec('reset role');ids=await owned();await auth(a);
  const keep=[first,...globals.slice(1)];save=await call('reset',save.revision,keep,ids,'EXCLUIR SAVE');
  const second=await birth();assert.notEqual(second,first);await db.exec('reset role');
  assert.equal((await db.query("select count(*)::int n from public.player_kites where owner_id=$1 and model_id='rabbito'",[a])).rows[0].n,2);
  ids=await owned();await auth(a);save=await call('discard',save.revision,[first],ids,'EXCLUIR PIPAMON');assert.equal(save.storage.length,19);
  await db.exec('reset role');assert.equal((await db.query('select owner_id from public.player_kites where id=$1',[first])).rows[0].owner_id,null);
  await db.exec('set role anon');await assert.rejects(()=>call(),/permission denied/);
 }finally{await db.close();}
});

test('direct input covers floor between graph nodes and collides without tunnelling or diagonal speed gain',()=>{
 const scene=artConfig().courtyard.world.scenes.quintal,nav=createWorldNavigation(scene),actor=nav.create(),before={...actor};
 nav.move(actor,{x:1,y:1},.1);assert.ok(nav.geometry.safe(actor));assert.ok(Math.hypot(actor.x-before.x,actor.y-before.y)<=14.501);
 Object.assign(actor,{x:500,y:560});for(let i=0;i<200;i++)nav.move(actor,{x:0,y:-1},.1);assert.ok(nav.geometry.safe(actor));assert.ok(actor.y>=490&&actor.y<560,'garden wall blocks direct north movement');
 nav.move(actor,{x:0,y:0},.1);assert.equal(actor.moving,false);
});

test('save endpoint requires auth and rejects forged bank lists and reset confirmation',async()=>{
 const calls=[],accounts=createAccounts({SUPABASE_URL:'https://test.invalid',SUPABASE_PUBLISHABLE_KEY:'test'},{gameDatabase:{rpc(){}},fetcher:async(url,opts)=>{calls.push(url);return new Response(JSON.stringify(url.endsWith('/auth/v1/user')?{id:'11111111-1111-4111-8111-111111111111'}:{}));}});
 const request=(body,cookie=true)=>new Request('http://localhost/account/campaign',{method:'POST',headers:{'Content-Type':'application/json',...(cookie?{Cookie:'pipa_access=local'}:{})},body:JSON.stringify(body)});
 assert.equal((await accounts.handle(request({action:'read'},false))).status,401);
 assert.equal((await accounts.handle(request({action:'protect',revision:0,keep:['bad'],seen:[]}))).status,400);
 assert.equal((await accounts.handle(request({action:'reset',revision:0,keep:[],seen:[],confirmation:'wrong'}))).status,400);
 assert.equal(calls.some(url=>url.includes('/rpc/player_campaign')),false);
});
