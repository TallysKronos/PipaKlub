import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {randomUUID} from 'node:crypto';
import {PGlite} from '@electric-sql/pglite';
import {skipLocalOpening} from './scripts/local-skip-opening.mjs';

test('local shortcut completes opening and workshop once, preserves a partial choice and isolates accounts',async()=>{
 const db=new PGlite();
 try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;grant execute on function auth.uid() to authenticated,anon,service_role;");
  for(const f of fs.readdirSync('supabase/migrations').filter(f=>f.endsWith('.sql')).sort())await db.exec(fs.readFileSync('supabase/migrations/'+f,'utf8'));
  const q=async(s,a=[])=>(await db.query(s,a)).rows[0];
  const user=async()=>{const id=randomUUID();await db.query('insert into auth.users values($1,$2)',[id,{nickname:'Atalho'}]);await db.query('select public.ensure_player($1,$2)',[id,'Atalho']);return id;};
  const a=await user(),b=await user();
  const result=await skipLocalOpening(db,a,'azulao');assert.equal(result.modelId,'azulao');
  assert.equal((await q('select step from public.player_openings where owner_id=$1',[a])).step,14);
  assert.equal((await q('select phase from public.player_journeys where owner_id=$1',[a])).phase,'complete');
  const tutorial=await q('select * from public.starter_tutorials where owner_id=$1',[a]);assert.ok(tutorial.completed_at);
  assert.equal((await q('select status from public.summon_tails where id=$1',[tutorial.tail_id])).status,'consumed');
  assert.equal((await q('select equipped_kite_id from public.player_profiles where id=$1',[a])).equipped_kite_id,result.kiteId);
  assert.equal((await q('select autosave_checkpoint from public.player_campaign_saves where owner_id=$1',[a])).autosave_checkpoint.scene,'professor-home');
  const count=await q('select count(*) n from public.player_kites where owner_id=$1',[a]);assert.deepEqual(await skipLocalOpening(db,a,'mata'),{alreadyComplete:true});assert.deepEqual(await q('select count(*) n from public.player_kites where owner_id=$1',[a]),count);
  assert.equal((await q('select count(*) n from public.starter_tutorials where owner_id=$1',[b])).n,0);
  // Simulate a player already choosing a tail and starting its real workshop.
  await db.query("select set_config('request.jwt.claim.sub',$1,false)",[b]);
  await q("select public.player_opening('read',null,null)");
  await db.query("update public.player_openings set step=10,legacy=false,tail_state='attached' where owner_id=$1",[b]);
  await q("select public.player_opening('name',10,'Meu parceiro')");
  await db.query("insert into public.player_journeys(owner_id,phase,lesson,starter_model) values($1,'city',5,'rabbito') on conflict(owner_id) do update set phase='city',lesson=5",[b]);
  const chosen=(await q("select public.player_starter_tutorial('choose','mata') t")).t;
  await q("select public.player_workshop('start',$1,null,'mata',null,null,$2)",[chosen.tailId,randomUUID()]);
  const resumed=await skipLocalOpening(db,b,'basica');assert.equal(resumed.modelId,'mata');assert.equal((await q('select count(*) n from public.workshop_jobs where owner_id=$1',[b])).n,1);
  await assert.rejects(()=>skipLocalOpening(db,a,'lacertubo'),/quatro pipas/);
 }finally{await db.close();}
});
