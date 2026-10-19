import {seedCollection} from './test-support/collection-fixture.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {randomUUID} from 'node:crypto';
import {PGlite} from '@electric-sql/pglite';
import {extendSummonPath} from './src/summon-pattern.js';

test('Javali own-tail spiral: immediate use, three failures, damage/discard, expiry and one committed reward',async()=>{
 const db=new PGlite(),user='33333333-3333-4333-8333-333333333333',other='44444444-4444-4444-8444-444444444444',model='javali-biscoito',session=randomUUID(),pattern=[7,4,1,2,3,6,9,8,5];
 try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;");
  for(const f of fs.readdirSync('supabase/migrations').filter(f=>f.endsWith('.sql')).sort())await db.exec(fs.readFileSync('supabase/migrations/'+f,'utf8'));
  await db.exec(fs.readFileSync('supabase/migrations/013_javali_summoning.sql','utf8'));
  assert.deepEqual((await db.query('select pattern from public.summon_spells where model_id=$1',[model])).rows[0].pattern,pattern);
  assert.deepEqual(pattern.reduce(extendSummonPath,[]),pattern,'drawing does not auto-insert unexpected nodes');
  assert.equal((await db.query('select count(*)::int n from public.summon_recipes')).rows[0].n,0,'no foreign-tail recipe');
  for(const id of [user,other])await db.query('insert into auth.users values($1,$2)',[id,{nickname:'Teste'}]);
await seedCollection(db,[user,other]);
  assert.equal((await db.query('select count(*)::int n from public.player_kites where model_id=$1',[model])).rows[0].n,0,'migration never grants the model');
  const grant=async ref=>(await db.query("select public.grant_summon_tail($1,$2,'event',$3) id",[user,model,ref])).rows[0].id;
  const tails=[];for(let i=0;i<5;i++)tails.push(await grant('javali-'+i));assert.equal(await grant('javali-0'),tails[0]);
  const auth=async id=>db.exec("reset role;set role authenticated;set request.jwt.claim.sub='"+id+"'");
  const call=async(action,{tail=null,ritual=null,path=null,request=null,target=null,sid=session}={})=>(await db.query('select public.player_summon($1,$2,$3,$4,$5,$6,$7) r',[action,tail,ritual,path,request,sid,target])).rows[0].r;
  await auth(user);await assert.rejects(()=>grant('forged'),/permission denied/);
  await assert.rejects(()=>call('start',{tail:tails[0],target:model}),/ainda não viu/);await db.query('select public.record_player_sighting($1)',[model]);
  const entry=(await call('inventory')).seen.find(p=>p.modelId===model);assert.equal(entry.availableTailIds.length,5);
  await db.query("select public.record_player_sighting('mata')");await assert.rejects(()=>call('start',{tail:tails[0],target:'mata'}),/não aceita/);
  let r=await call('start',{tail:tails[0],target:model});assert.deepEqual(r.pattern,pattern);assert.equal(r.remaining,3);assert.ok(!(await call('inventory')).tails.some(t=>t.id===tails[0]),'tail stops being usable immediately');
  await auth(other);await assert.rejects(()=>call('attempt',{ritual:r.id,path:pattern,request:randomUUID()}),/sessão/);await auth(user);
  for(let i=0;i<3;i++)r=await call('attempt',{ritual:r.id,path:[1],request:randomUUID()});assert.equal(r.status,'failed');assert.equal(r.remaining,0);assert.equal((await call('attempt',{ritual:r.id,path:pattern,request:randomUUID()})).status,'failed');
  r=await call('start',{tail:tails[1],target:model});await call('abandon',{ritual:r.id});assert.equal((await call('inventory')).tails.find(t=>t.id===tails[1]).status,'damaged');await assert.rejects(()=>call('start',{tail:tails[1],target:model,sid:randomUUID()}),/utilizada/);await call('discard',{tail:tails[1]});assert.ok(!(await call('inventory')).tails.some(t=>t.id===tails[1]));
  r=await call('start',{tail:tails[2],target:model});await db.exec('reset role');await db.query("update public.summon_rituals set expires_at=now()-interval '1 second' where id=$1",[r.id]);await auth(user);assert.equal((await call('attempt',{ritual:r.id,path:pattern,request:randomUUID()})).status,'abandoned');assert.equal((await call('inventory')).tails.find(t=>t.id===tails[2]).status,'damaged');
  r=await call('start',{tail:tails[3],target:model});const request=randomUUID(),done=await call('attempt',{ritual:r.id,path:pattern,request});assert.equal(done.status,'succeeded');assert.ok(done.kiteId);assert.equal((await call('attempt',{ritual:r.id,path:pattern,request})).kiteId,done.kiteId);
  await assert.rejects(()=>call('start',{tail:tails[4],target:model}),/já possui/);assert.equal((await call('inventory')).tails.find(t=>t.id===tails[4]).status,'ready','duplicate prevention never consumes the spare tail');
  await db.exec('reset role');assert.equal((await db.query('select count(*)::int n from public.player_kites where owner_id=$1 and model_id=$2',[user,model])).rows[0].n,1);assert.equal((await db.query('select permanent from public.player_kites where id=$1',[done.kiteId])).rows[0].permanent,true);
  const statuses=(await db.query('select id,status from public.summon_tails where id=any($1::uuid[])',[tails])).rows;assert.deepEqual(tails.map(id=>statuses.find(t=>t.id===id).status),['consumed','discarded','damaged','consumed','ready']);
 }finally{await db.close();}
});
