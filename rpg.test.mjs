import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {randomUUID} from 'node:crypto';
import {PGlite} from '@electric-sql/pglite';
import {createEngine} from './src/engine.js';
import {artConfig} from './scripts/art-build.mjs';
import {createWorldNavigation} from './src/world-navigation.js';
import {createAssetHandler} from './src/static-assets.js';
const engine=createEngine();

test('park landscaping keeps whole trees, accessible habitats, safe paths and the shipped alpha atlas',async()=>{
 const config=artConfig(),asset=createAssetHandler();
 for(const id of ['park-trail','park-clearing']){
  const scene=config.courtyard.world.scenes[id],nav=createWorldNavigation(scene),actor=nav.create();
  assert.ok(scene.art.objects.some(o=>o.sprite.frame==='park-tree'));
  assert.ok(!scene.art.objects.some(o=>['trunk','canopy'].includes(o.sprite.frame)),'trees must use one complete silhouette');
  for(const place of scene.places){const [x,y]=scene.nodes[place.node];assert.ok(nav.target(actor,{x,y}).length,place.name);}
  for(const patch of scene.tiled.layers.Walkable.filter(r=>r.properties.encounter_zone)){
   const p={x:patch.x+patch.w/2,y:patch.y+patch.h/2};assert.ok(nav.geometry.safe(p));assert.ok(nav.target(actor,p).length,'habitat reachable');
   assert.ok(!scene.tiled.layers.Walkable.some(r=>r.properties.safe_area&&p.x>=r.x&&p.x<=r.x+r.w&&p.y>=r.y&&p.y<=r.y+r.h));
  }
 }
 const entry=config.courtyard.images['world-kit-park-nature-v2'];
 const response=await asset(new Request('http://localhost/'+entry.url));assert.equal(response.status,200);
 const bytes=Buffer.from(await response.arrayBuffer());assert.equal(bytes[25],6,'RGBA PNG');assert.equal(bytes.readUInt32BE(16),1536);
 assert.equal((await asset(new Request('http://localhost/assets/world/park-kit-v2/concept-v2.png'))).status,404,'concept is not a runtime download');
});

test('tamer and partner curves have distinct caps and class tradeoffs remain bounded',()=>{
 for(let level=1;level<=100;level++){
  const xp=engine.tamers.xpForLevel(level);assert.equal(engine.tamers.progress(xp).level,level);
  if(level>1)assert.equal(engine.tamers.progress(xp-1).level,level-1);
 }
 assert.equal(engine.tamers.progress(1e9).level,100);assert.equal(engine.tamers.progress(1e9).next,null);
 assert.equal(engine.pipamons.progress(1e9).level,50);
 const base=engine.pipamons.stats(35),fast=engine.pipamons.stats(35,'velocista',2),control=engine.pipamons.stats(35,'condutor',2);
 assert.ok(fast.speed>base.speed&&fast.line<base.line);
 assert.ok(control.regen>base.regen&&control.speed<base.speed);
 assert.deepEqual(engine.pipamons.stats(35,'forged',100),base);
 const s=engine.create(0);s.wild={zone:'park-trail'};s.wildOwner='private';s.wildResult={outcome:'won'};
 assert.equal(engine.visible(s).wildOwner,undefined);assert.equal(engine.visible(s).wildResult,undefined);
 assert.equal(engine.sanitizeInput({classRank:2,pipamonClass:'condutor',wildResult:{outcome:'won'}}).classRank,undefined);
});

test('verified wild rewards, pity, resets and class changes are private, atomic and replay safe',async()=>{
 const db=new PGlite(),a=randomUUID(),b=randomUUID();
 try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;grant execute on function auth.uid() to authenticated,anon,service_role;");
  for(const f of fs.readdirSync('supabase/migrations').filter(f=>f.endsWith('.sql')).sort())await db.exec(fs.readFileSync('supabase/migrations/'+f,'utf8'));
  const q=async(sql,args=[])=>(await db.query(sql,args)).rows[0];
  const auth=async id=>db.exec("reset role;set role authenticated;set request.jwt.claim.sub='"+id+"'");
  for(const id of [a,b]){await db.query('insert into auth.users values($1,$2)',[id,{nickname:'RPG Tester'}]);await db.query('select public.ensure_player($1,$2)',[id,'RPG Tester']);}
  await auth(a);for(let n=0;n<10;n++)await q("select public.player_opening('advance',$1,null)",[n]);
  const kite=(await q("select public.player_opening('name',10,'Vento') r")).r.partner_id;
  await assert.rejects(()=>q("select public.player_classes($1,'velocista-1',0)",[kite]),/nível 15/);
  await db.exec('reset role');await db.query('update public.player_kites set pipamon_xp=$1 where id=$2',[engine.pipamons.xpForLevel(15),kite]);
  await auth(a);let k=(await q("select public.player_classes($1,'velocista-1',0) r",[kite])).r.kite;
  assert.equal(k.class_rank,1);assert.equal(k.personal_name,'Vento');
  await assert.rejects(()=>q("select public.player_classes($1,'condutor-1',0)",[kite]),/alterado/);
  await assert.rejects(()=>q("select public.player_classes($1,'velocista-2',1)",[kite]),/nível 35/);
  await auth(b);await assert.rejects(()=>q("select public.player_classes($1,'condutor-1',1)",[kite]),/sua coleção/);
  await db.exec('reset role');await db.query('update public.player_kites set pipamon_xp=$1 where id=$2',[engine.pipamons.xpForLevel(35),kite]);
  await auth(a);k=(await q("select public.player_classes($1,'velocista-2',1) r",[kite])).r.kite;assert.equal(k.class_rank,2);
  const xp=k.pipamon_xp;k=(await q("select public.player_classes($1,'condutor-1',2) r",[kite])).r.kite;assert.equal(k.class_rank,1);assert.equal(k.pipamon_xp,xp);assert.equal(k.personal_name,'Vento');
  await assert.rejects(()=>q("select public.award_tamer_xp($1,'forge',100)",[a]),/permission denied/);
  await assert.rejects(()=>q("select public.settle_wild_run($1,$2,'won')",[a,randomUUID()]),/permission denied/);
  await assert.rejects(()=>q('select * from public.wild_runs'),/permission denied/);
  await db.exec('reset role');await db.query("insert into public.player_journeys(owner_id,phase) values($1,'city') on conflict(owner_id) do update set phase='city'",[a]);
  const start=async(zone='park-trail')=>{
   await db.exec('reset role');await db.query("update public.wild_runs set created_at=now()-interval '30 seconds' where owner_id=$1",[a]);
   const id=randomUUID();await db.exec('set role pipa_server');
   const snapshot=(await q("select public.reserve_player_match($1,$2,'ABCDEF','casual') r",[a,id])).r;
   assert.equal(snapshot.pipamonClass,'condutor');assert.equal(snapshot.classRank,1);
   const encounter=(await q('select public.register_wild_run($1,$2,$3) r',[a,id,zone])).r;
   assert.equal(encounter.drop_roll,undefined);assert.deepEqual((await q('select public.register_wild_run($1,$2,$3) r',[a,id,zone])).r,encounter);
   return {id,encounter};
  };
  const finish=async(id,outcome)=>{
   await db.exec('reset role;set role pipa_server');const result=(await q('select public.settle_wild_run($1,$2,$3) r',[a,id,outcome])).r;
   await q('select public.finish_player_match($1)',[id]);return result;
  };
  let run=await start();await auth(a);await assert.rejects(()=>q("select public.player_classes($1,'velocista-1',3)",[kite]),/saia da partida/);
  await auth(b);await assert.rejects(()=>q('select public.player_wild($1)',[run.id]),/inexistente/);
  const first=await finish(run.id,'won');assert.ok(first.tailId);assert.equal(first.firstTail,true);assert.equal(first.pipamonXp,20);assert.equal(first.tamerXp,4);
  assert.deepEqual(await finish(run.id,'won'),first,'retry returns immutable receipt');
  for(const outcome of ['lost','fled','abandoned']){run=await start();const result=await finish(run.id,outcome);assert.equal(result.tailId,null);assert.equal(result.pipamonXp,0);assert.equal(result.tamerXp,0);}
  run=await start('park-clearing');await db.exec('reset role');await db.query('update public.wild_drop_state set misses=7 where owner_id=$1',[a]);await db.query('update public.wild_runs set drop_roll=.99 where match_id=$1',[run.id]);
  const pity=await finish(run.id,'won');assert.ok(pity.tailId);assert.equal(pity.pipamonXp,30);assert.equal(pity.tamerXp,6);
  run=await start();await db.exec('reset role');await db.query('update public.player_kites set pipamon_xp=25970 where id=$1',[kite]);
  const capped=await finish(run.id,'won');assert.equal(capped.pipamonXp,0);assert.equal(capped.tamerXp,0);
  run=await start();await db.exec('reset role');await db.query('update public.player_profiles set active_match=null,active_until=null where id=$1',[a]);
  const ids=(await db.query('select id from public.player_kites where owner_id=$1',[a])).rows.map(k=>k.id);
  await auth(a);const save=(await q('select public.player_campaign() r')).r;
  await q("select public.player_campaign('reset',$1,null,$2,$3,'EXCLUIR SAVE')",[save.revision,[kite],ids]);
  assert.equal((await finish(run.id,'won')).status,'abandoned','old result cannot reward a reset save');
 }finally{await db.close();}
});

test('constellation consumes items once, gates parents and base stats, preserves unlocks and allows multiple Rabbitknights',async()=>{
 const db=new PGlite(),owner=randomUUID();
 try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;grant execute on function auth.uid() to authenticated,anon,service_role;");
  for(const f of fs.readdirSync('supabase/migrations').filter(f=>f.endsWith('.sql')).sort())await db.exec(fs.readFileSync('supabase/migrations/'+f,'utf8'));
  const q=async(sql,args=[])=>(await db.query(sql,args)).rows[0];
  await db.query('insert into auth.users values($1,$2)',[owner,{nickname:'Classes'}]);
  const auth=()=>db.exec("reset role;set role authenticated;set request.jwt.claim.sub='"+owner+"'");
  const birth=async()=>{await auth();for(let i=0;i<10;i++)await q("select public.player_opening('advance',$1,null)",[i]);return (await q("select public.player_opening('name',10,'Estrela') r")).r.partner_id;};
  const first=await birth();await db.exec('reset role');await db.query('update public.player_kites set pipamon_xp=$1 where id=$2',[engine.pipamons.xpForLevel(45),first]);await auth();
  let view=(await q('select public.player_classes($1) r',[first])).r;assert.equal(view.nodes.length,7);assert.equal(view.nodes.filter(n=>n.branch==='rabbitknight').length,1);assert.ok(view.nodes.every(n=>!n.unlocked));
  const choose=async(id,node,version)=>(await q('select public.player_classes($1,$2,$3) r',[id,node,version])).r;
  await assert.rejects(()=>choose(first,'velocista-3',0),/anterior/);
  await assert.rejects(()=>choose(first,'rabbitknight',0),/item especial/);
  await assert.rejects(()=>q("select public.player_specialization($1,'velocista',true,0)",[first]),/aba Classes/);
  await db.exec('reset role');await db.query("insert into public.player_class_items values($1,'mascara-do-guerreiro',2),($1,'pluma-dos-ventos',1)",[owner]);
  // A trusted test catalog modification proves status requirements aren't checked only in the UI.
  await db.query("update public.pipamon_class_nodes set threshold=999 where id='velocista-1'");await auth();await assert.rejects(()=>choose(first,'velocista-1',0),/atributo base/);
  await db.exec("reset role;update public.pipamon_class_nodes set threshold=168 where id='velocista-1'");await auth();
  view=await choose(first,'velocista-1',0);view=await choose(first,'velocista-2',view.version);view=await choose(first,'velocista-3',view.version);
  assert.equal(view.kite.class_rank,3);assert.equal(view.items['pluma-dos-ventos'],0);assert.equal(view.kite.personal_name,'Estrela');
  view=await choose(first,'base',view.version);view=await choose(first,'velocista-3',view.version);assert.equal(view.items['pluma-dos-ventos'],0,'reselection consumes nothing');
  const old=view.version;view=await choose(first,'rabbitknight',old);assert.equal(view.items['mascara-do-guerreiro'],1);assert.equal(view.current,'rabbitknight');
  await assert.rejects(()=>choose(first,'rabbitknight',old),/alterado/);
  const xp=view.kite.pipamon_xp;view=await choose(first,'base',view.version);view=await choose(first,'rabbitknight',view.version);assert.equal(view.items['mascara-do-guerreiro'],1);assert.equal(view.kite.pipamon_xp,xp);
  const save=(await q('select public.player_campaign() r')).r;const ids=(await db.query('select id from public.player_kites where owner_id=$1',[owner])).rows.map(k=>k.id);
  await q("select public.player_campaign('reset',$1,null,$2,$3,'EXCLUIR SAVE')",[save.revision,[first],ids]);const second=await birth();
  await db.exec('reset role');await db.query('update public.player_kites set pipamon_xp=$1 where id=$2',[engine.pipamons.xpForLevel(25),second]);await auth();
  view=await choose(second,'rabbitknight',0);assert.equal(view.items['mascara-do-guerreiro'],0);assert.equal((await q('select public.player_classes($1) r',[first])).r.current,'rabbitknight');
  assert.equal(view.kite.personal_name,'Estrela');await assert.rejects(()=>q('select * from public.player_class_items'),/permission denied/);
  const stats=engine.pipamons.stats(25,'rabbitknight',1),base=engine.pipamons.stats(25);assert.ok(stats.attack>base.attack&&stats.defense>base.defense&&stats.speed<base.speed);
  await assert.rejects(()=>q('select public.grant_class_milestones($1)',[owner]),/permission denied/);
  await db.exec('reset role');
  await db.query("with m as(insert into public.game_matches(id,room_code,mode) select gen_random_uuid(),'AA0000','casual' from generate_series(1,30) returning id) insert into public.wild_runs(match_id,owner_id,kite_id,zone,model_id,enemy_level,drop_roll,status,result) select id,$1,$2,'park-trail','basica',1,.5,'won','{}'::jsonb from m",[owner,second]);
  const awards=(await q('select public.grant_class_milestones($1) r',[owner])).r;assert.equal(awards.length,6);assert.equal(awards.filter(i=>i==='mascara-do-guerreiro').length,2,'special class items remain obtainable for additional partners');
  assert.deepEqual((await q('select public.grant_class_milestones($1) r',[owner])).r,[],'milestone replay cannot mint extra items');
  await auth();assert.equal((await q('select public.player_classes($1) r',[second])).r.items['mascara-do-guerreiro'],2);
 }finally{await db.close();}
});
