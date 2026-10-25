import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {randomUUID} from 'node:crypto';
import {PGlite} from '@electric-sql/pglite';

test('Veredas chests and guardian tail are private, persistent and granted at most once',async()=>{
 const db=new PGlite(),a=randomUUID(),b=randomUUID();
 try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;grant execute on function auth.uid() to authenticated,anon,service_role;");
  for(const f of fs.readdirSync('supabase/migrations').filter(f=>f.endsWith('.sql')).sort())await db.exec(fs.readFileSync('supabase/migrations/'+f,'utf8'));
  const q=async(sql,args=[])=>(await db.query(sql,args)).rows[0];
  const auth=async id=>db.exec("reset role;set role authenticated;set request.jwt.claim.sub='"+id+"'");
  for(const id of [a,b]){await db.query('insert into auth.users values($1,$2)',[id,{nickname:'Expedition'}]);await db.query('select public.ensure_player($1,$2)',[id,'Expedition']);await db.query("insert into public.player_journeys(owner_id,phase) values($1,'complete') on conflict(owner_id) do update set phase='complete'",[id]);}
  await auth(a);await assert.rejects(()=>q("select public.player_veredas('unknown')"),/baú inválido/);
  let r=(await q("select public.player_veredas('woodland') r")).r;assert.equal(r.reward.amount,25);
  r=(await q("select public.player_veredas('woodland') r")).r;assert.equal(r.reward.alreadyOpened,true);assert.deepEqual(r.opened,['woodland']);
  r=(await q("select public.player_veredas('lookout') r")).r;const tail=r.reward.tailId;assert.equal((await q("select public.player_veredas('lookout') r")).r.reward.tailId,tail);
  await assert.rejects(()=>q("select public.player_veredas('courtyard')"),/guardião/);
  await auth(b);assert.deepEqual((await q('select public.player_veredas() r')).r.opened,[]);
  await assert.rejects(()=>db.query('select * from public.veredas_chest_claims'),/permission denied/);
  await auth(a);for(let n=0;n<10;n++)await q("select public.player_opening('advance',$1,null)",[n]);await q("select public.player_opening('name',10,'Vento')");
  await db.exec('reset role');await db.query("update public.player_journeys set phase='complete' where owner_id=$1",[a]);
  const grassMatch=randomUUID();await db.exec('set role pipa_server');await q("select public.reserve_player_match($1,$2,'GRASS1','casual')",[a,grassMatch]);
  const wild=(await q("select public.register_wild_run($1,$2,'park-veredas-wild') r",[a,grassMatch])).r;assert.ok(wild.level>=5&&wild.level<=9);assert.equal(wild.boss,undefined);assert.notEqual(wild.soul,'lacertubo');
  await q("select public.settle_wild_run($1,$2,'fled')",[a,grassMatch]);await q('select public.release_player_match($1,$2)',[a,grassMatch]);
  await db.exec('reset role');await db.query("update public.wild_runs set created_at=now()-interval '30 seconds' where match_id=$1",[grassMatch]);const match=randomUUID();await db.exec('set role pipa_server');
  await q("select public.reserve_player_match($1,$2,'VEREDA','casual')",[a,match]);
  const encounter=(await q("select public.register_wild_run($1,$2,'park-veredas') r",[a,match])).r;assert.equal(encounter.boss,true);
  const result=(await q("select public.settle_wild_run($1,$2,'won') r",[a,match])).r;assert.equal(result.modelId,'lacertubo');assert.ok(result.tailId);
  assert.equal((await q("select public.settle_wild_run($1,$2,'won') r",[a,match])).r.tailId,result.tailId);
  await q('select public.release_player_match($1,$2)',[a,match]);
  await auth(a);assert.equal((await q("select public.player_veredas('courtyard') r")).r.reward.amount,60);
  await db.exec('reset role');assert.equal(Number((await q("select count(*) n from public.summon_tails where owner_id=$1 and model_id='lacertubo'",[a])).n),1);
  assert.equal(Number((await q("select (progress->>'coins')::int n from public.player_trails where owner_id=$1",[a])).n),85);
  await db.exec('set role pipa_server');await assert.rejects(()=>q("select public.register_wild_run($1,$2,'park-veredas')",[a,randomUUID()]),/não está mais/);
 }finally{await db.close();}
});
