import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {randomUUID} from 'node:crypto';
import {PGlite} from '@electric-sql/pglite';
import {workshopV3} from './src/workshop-v3-service.js';
import {newRun,dispatch,pack,unpack,replay} from './tools/oficina-v3/protocol.mjs';
import {geometry,knotWindow,SOUL_ZONES} from './tools/oficina-v3/model.mjs';
import {createEngine} from './src/engine.js';
import {serveWorkshopV3} from './src/workshop-v3-assets.js';
const owner='11111111-1111-4111-8111-111111111111',other='22222222-2222-4222-8222-222222222222';
function playStage(run){
 const stage=run.stage,events=[],send=e=>{events.push(e);return dispatch(run,e);},tick=(control=0)=>send(['t',1/120,control]);
 if(stage===0)for(const rod of geometry(run.kind).rods){for(let i=0;i<120;i++)tick();send(['rod',rod.mid.x,rod.mid.y]);}
 if(stage===1)for(let i=0;i<geometry(run.kind).points.length;i++){send(['knot',i]);const [a,b]=knotWindow(run,i);while(run.step.fill<(a+b)/2)tick();send(['knot-up']);}
 if(stage===2)for(const p of geometry(run.kind).samples){tick();send(['cut',p.x,p.y,1/120]);if(run.stage!==2)break;}
 if(stage===3){let attempts=0;while(run.stage===3&&attempts++<3000)tick(Math.max(-1,Math.min(1,-.03*run.step.theta-.02*run.step.omega)));assert.equal(run.stage,4);}
 if(stage===4){send(['soul']);while(run.step.fill<(SOUL_ZONES.safe+SOUL_ZONES.shine)/2)tick();send(['soul-up']);}
 return events;
}

test('authenticated v3 persists replayed stages, confirms one reward, hides variant and protects legacy builds',async()=>{
 const db=new PGlite();
 try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;");
  for(const file of fs.readdirSync('supabase/migrations').filter(f=>f.endsWith('.sql')).sort())await db.exec(fs.readFileSync('supabase/migrations/'+file,'utf8'));
  for(const id of [owner,other])await db.query('insert into auth.users values($1,$2)',[id,{nickname:'Oficina Teste'}]);
  await db.query("insert into public.player_pipamon_sightings values($1,'mata',now()) on conflict do nothing",[owner]);
  const tail=(await db.query("select public.grant_summon_tail($1,'mata','event','workshop-v3-test') id",[owner])).rows[0].id;
  const rpc=async args=>db.transaction(async tx=>{
   await tx.exec('set local role pipa_server');
   return (await tx.query('select public.server_workshop_v3($1,$2,$3,$4,$5,$6,$7,$8,$9) r', ['p_user','p_action','p_job','p_tail','p_target','p_revision','p_request','p_state','p_result'].map(k=>args[k]??null))).rows[0].r;
  });
  let job=await workshopV3(owner,{action:'start',tailId:tail,targetModelId:'mata'},rpc);
  assert.equal(job.modelId,undefined);assert.equal(job.name,undefined);assert.equal(job.kind,'comum');assert.equal(job.state,null);
  await assert.rejects(()=>workshopV3(other,{action:'read',jobId:job.id},rpc),/não pertence/);
  await db.exec("set role authenticated;set request.jwt.claim.sub='"+owner+"'");
  await assert.rejects(()=>db.query('select variant from public.workshop_v3_runs'),/permission denied/);
  await assert.rejects(()=>db.query("select public.player_workshop('advance',null,$1,null,0,$2,$3)",[job.id,{joints:[0,1,2,3]},randomUUID()]),/recarregue/);
  await assert.rejects(()=>db.query("select public.server_workshop_v3($1,'read',$2)",[owner,job.id]),/permission denied/);
  await db.exec('reset role');
  let run=newRun(job.kind,Number(job.seed)),lastRequest,lastReply;
  for(let stage=0;stage<5;stage++){
   const events=playStage(run);
   // Make elapsed server time explicit without waiting through a test fixture.
   await db.query("update public.workshop_v3_runs set updated_at=clock_timestamp()-interval '90 seconds' where job_id=$1",[job.id]);
   lastRequest={action:'save',jobId:job.id,revision:Number(job.revision),requestId:randomUUID(),events};
   job=await workshopV3(owner,lastRequest,rpc);lastReply=job;
   assert.equal(job.stage,stage+1);assert.equal(job.state.stage,stage+1);
   if(stage<4){assert.equal(job.name,undefined);run=unpack(job.state);}
  }
  assert.equal(job.status,'completed');assert.ok(job.kiteId);assert.equal(job.name,'Mata verde');assert.equal(job.state.outcome.confirmed,true);
  assert.ok(job.state.outcome.craftBonus.totalPercent>4);
  const born=(await db.query('select craft_bonus,soul_variant from public.player_kites where id=$1',[job.kiteId])).rows[0];
  assert.equal(Number(born.craft_bonus),job.state.outcome.craftBonus.totalPercent);assert.equal(born.soul_variant,job.state.outcome.variant);
  const retry=await workshopV3(owner,lastRequest,rpc);assert.deepEqual(retry,lastReply);
  await assert.rejects(()=>workshopV3(owner,{...lastRequest,events:[['soul']]},rpc),/confirmação já utilizada/);
  assert.equal((await db.query("select count(*)::integer n from public.player_kites where id=$1",[job.kiteId])).rows[0].n,1);
  const inv=(await db.query('select public.workshop_result($1) r',[job.id])).rows[0].r;assert.equal(inv.v3,true);
  await db.exec("set role authenticated;set request.jwt.claim.sub='"+owner+"'");
  await db.query('select public.equip_player_kite($1)',[job.kiteId]);await db.exec('reset role');
  const reservation=await db.transaction(async tx=>{await tx.exec('set local role pipa_server');return (await tx.query("select public.reserve_player_match($1,$2,'V3TEST','casual') r",[owner,randomUUID()])).rows[0].r;});
  assert.equal(Number(reservation.craftBonus),Number(born.craft_bonus));assert.equal(reservation.soulVariant,born.soul_variant);
 }finally{await db.close();}
});

test('replay rejects declared scores and preserves deterministic checkpoints',()=>{
 const run=newRun('comum',12),initial=pack(run),events=playStage(run),replayed=replay(initial,events);
 assert.deepEqual(replayed.state,pack(run));
 assert.throws(()=>replay(initial,[['bonus',12]]),/comando inválido/);
 assert.throws(()=>replay(initial,[['t',5,0]]),/relógio inválido/);
 assert.throws(()=>replay(initial,[['rod',Infinity,0]]),/comando inválido/);
});

test('workshop stat bonus is applied in authoritative combat and capped at 12%',()=>{
 const eng=createEngine(),base=eng.pipamons.stats(1),buff=eng.pipamons.stats(1,null,0,12);
 assert.ok(Math.abs(buff.line-base.line*1.12)<1e-9);assert.ok(Math.abs(buff.attack-base.attack*1.12)<1e-9);
 assert.deepEqual(eng.pipamons.stats(1,null,0,500),buff);assert.deepEqual(eng.pipamons.stats(1,null,0,-1),base);
 const state=eng.create(0),p=eng.player('Oficina',0,'test',0);p.craftBonus=12;eng.admit(state,p,0);assert.equal(p.hp,buff.line);assert.equal(p.energy,buff.energy);
});

test('production serves executable modules, never sources or credentials outside its allowlist',async()=>{
 for(const path of ['','game.mjs','protocol.mjs','live-client.mjs','hand.mjs','hud.css','hud.json']){const r=await serveWorkshopV3(new Request('https://example.test/oficina-v3/'+path));assert.equal(r.status,200,path);assert.match(r.headers.get('Content-Type'),/html|javascript|css|json/);}
 assert.equal((await serveWorkshopV3(new Request('https://example.test/oficina-v3/.env'))).status,404);
 assert.equal((await serveWorkshopV3(new Request('https://example.test/oficina-v3/server.mjs'))).status,404);
});

test('026 preserves existing partners and lets a legacy in-progress workshop finish',async()=>{
 const db=new PGlite();
 try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;");
  for(const file of fs.readdirSync('supabase/migrations').filter(f=>f.endsWith('.sql')&&f<'026').sort())await db.exec(fs.readFileSync('supabase/migrations/'+file,'utf8'));
  await db.query('insert into auth.users values($1,$2)',[owner,{nickname:'Legado'}]);
  await db.query("insert into public.player_pipamon_sightings values($1,'mata',now()) on conflict do nothing",[owner]);
  const tail=(await db.query("select public.grant_summon_tail($1,'mata','event','legacy-v3-migration') id",[owner])).rows[0].id;
  const count=(await db.query('select count(*)::integer n from public.player_kites')).rows[0].n;
  const legacy=await db.transaction(async tx=>{await tx.exec("set local role authenticated;set local request.jwt.claim.sub='"+owner+"'");return (await tx.query("select public.player_workshop('start',$1) r",[tail])).rows[0].r;});
  await db.exec(fs.readFileSync('supabase/migrations/026_workshop_v3.sql','utf8'));
  assert.equal((await db.query('select count(*)::integer n from public.player_kites')).rows[0].n,count);
  assert.equal((await db.query('select count(*)::integer n from public.player_kites where craft_bonus<>0 or soul_variant')).rows[0].n,0);
  await db.transaction(async tx=>{
   await tx.exec("set local role authenticated;set local request.jwt.claim.sub='"+owner+"'");
   await assert.rejects(()=>tx.query('update public.player_kites set craft_bonus=12'),/permission denied/);
  }).catch(error=>{if(!/aborted/.test(error.message))throw error;});
  const payloads=[{joints:[0,1,2,3]},{tension:65},{cuts:[0,1,2,3]},{balance:50},{wind:50,tension:50}];let final;
  for(let i=0;i<5;i++)final=await db.transaction(async tx=>{await tx.exec("set local role authenticated;set local request.jwt.claim.sub='"+owner+"'");return (await tx.query("select public.player_workshop('advance',null,$1,null,$2,$3,$4) r",[legacy.id,i,payloads[i],randomUUID()])).rows[0].r;});
  assert.equal(final.status,'completed');assert.equal(final.v3,false);
 }finally{await db.close();}
});
