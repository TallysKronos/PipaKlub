import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {PGlite} from '@electric-sql/pglite';
import './prepare-demo-opening-migration.mjs';
test('opening production package preserves legacy collections, grants one story partner and refuses reapplication',async()=>{
 const db=new PGlite();try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;grant execute on function auth.uid() to authenticated,anon,service_role;");
  for(const name of fs.readdirSync('supabase/migrations').filter(n=>n.endsWith('.sql')&&Number(n.slice(0,3))<=16).sort())await db.exec(fs.readFileSync('supabase/migrations/'+name,'utf8'));
  const legacy='77777777-7777-4777-8777-777777777777',fresh='88888888-8888-4888-8888-888888888888';
  await db.query('insert into auth.users values($1,$2)',[legacy,{nickname:'Legacy QA'}]);const before=(await db.query('select id,model_id,permanent from public.player_kites where owner_id=$1 order by id',[legacy])).rows;
  const sql=fs.readFileSync('output/sql/instalar-abertura-demo-017-018.sql','utf8');await db.exec(sql);
  assert.deepEqual((await db.query('select id,model_id,permanent from public.player_kites where owner_id=$1 order by id',[legacy])).rows,before);assert.deepEqual((await db.query('select step,legacy from public.player_openings where owner_id=$1',[legacy])).rows,[{step:14,legacy:true}]);
  await db.query('insert into auth.users values($1,$2)',[fresh,{nickname:'New QA'}]);assert.equal((await db.query('select count(*)::int n from public.player_kites where owner_id=$1',[fresh])).rows[0].n,0);
  async function opening(action,step=null){return db.transaction(async tx=>{await tx.exec('set local role authenticated');await tx.query("select set_config('request.jwt.claim.sub',$1,true)",[fresh]);return (await tx.query('select public.player_opening($1,$2,$3) o',[action,step,action==='name'?'Rabbito QA':null])).rows[0].o;});}
  let o=await opening('read');while(o.step<14)o=await opening(o.step===10?'name':'advance',o.step);assert.ok(o.partner_id);assert.equal((await opening('read')).partner_id,o.partner_id);assert.equal((await db.query("select count(*)::int n from public.player_kites where owner_id=$1 and model_id='rabbito'",[fresh])).rows[0].n,1);
  await assert.rejects(db.exec(sql),/não reaplicar/);await db.exec('rollback');assert.equal((await opening('read')).partner_id,o.partner_id);
 }finally{await db.close();}
});
