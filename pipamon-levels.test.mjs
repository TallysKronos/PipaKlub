import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import {PGlite} from '@electric-sql/pglite';
import {createEngine} from './src/engine.js';
const engine=createEngine(),levels=engine.pipamons;
test('individual XP curve caps at 50, has exact thresholds and five cosmetic milestones',()=>{
 assert.equal(levels.maxXp,25970);
 for(let l=1;l<=50;l++){assert.equal(levels.progress(levels.xpForLevel(l)).level,l);if(l>1)assert.equal(levels.progress(levels.xpForLevel(l)-1).level,l-1);}
 for(const xp of [NaN,Infinity,-100,null,'forged'])assert.equal(levels.progress(xp).level,1);
 assert.equal(levels.progress(999999999).level,50);assert.equal(levels.progress(999999999).next,null);
 for(const [level,tier]of [[19,null],[20,'silver'],[29,'silver'],[30,'gold'],[40,'platinum'],[45,'diamond'],[50,'aura']])assert.equal(levels.tier(level)?.id||null,tier);
 assert.deepEqual(levels.stats(1),{line:100,energy:100,attack:1,defense:1,speed:165,regen:18});
 assert.equal(levels.stats(50).line,120);assert.equal(levels.stats(50).energy,115);
 assert.ok(levels.stats(50).attack<=1.12&&levels.stats(50).defense<=1.10);
});
test('server levels affect movement, round capacities and regeneration; input cannot forge levels',()=>{
 const s=engine.create(0,{mode:'rounds'}),p=engine.player('A',0,'a',0),q=engine.player('B',1,'b',0);p.pipamonLevel=50;
 engine.admit(s,p,0);engine.admit(s,q,0);assert.equal(p.hp,120);assert.equal(p.energy,115);assert.equal(q.hp,100);
 assert.equal(engine.sanitizeInput({pipamonLevel:50,pipamon_xp:25970}).pipamonLevel,undefined);
 p.x=300;q.x=300;p.y=q.y=200;engine.move(p,{x:1},.1);engine.move(q,{x:1},.1);assert.ok(p.x>q.x);
 p.energy=114.9;engine.move(p,{},.1);assert.equal(p.energy,115);
 engine.step(s,1);assert.equal(p.hp,120,'countdown reset respects the individual maximum');
 const visible=engine.visible(s);assert.equal(visible.players[0].pipamonLevel,50);
});
test('glow is absent before 20, bounded in light mode, still under reduced motion and restores canvas state',()=>{
 const ctx={save(){this.saved=(this.saved||0)+1;},restore(){this.saved--;},beginPath(){},moveTo(){},lineTo(){},stroke(){this.strokes=(this.strokes||0)+1;},ellipse(){}};
 const c=vm.createContext({eng:engine,Math});vm.runInContext(fs.readFileSync('src/pipamon-level-client.js','utf8'),c);
 c.ctx=ctx;vm.runInContext('drawPipamonGlow(ctx,19,1000,0,0)',c);assert.equal(ctx.strokes,undefined);
 vm.runInContext('drawPipamonGlow(ctx,50,1000,0,0,48,true,false)',c);assert.equal(ctx.strokes,5);assert.equal(ctx.saved,0);
 ctx.strokes=0;vm.runInContext('drawPipamonGlow(ctx,20,99999,0,0,48,false,true)',c);assert.equal(ctx.strokes,3);assert.equal(ctx.saved,0);
});
test('PostgreSQL grants instance XP only on verified receipts, protects updates, preserves captured XP and caps replay',async()=>{
 const db=new PGlite(),a='11111111-1111-4111-8111-111111111111',b='22222222-2222-4222-8222-222222222222',match='33333333-3333-4333-8333-333333333333';
 try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;grant execute on function auth.uid() to authenticated,anon,service_role;");
  for(const file of fs.readdirSync('supabase/migrations').filter(f=>f.endsWith('.sql')&&Number(f.slice(0,3))<=16).sort())await db.exec(fs.readFileSync('supabase/migrations/'+file,'utf8'));
  await db.query('insert into auth.users values($1,$2),($3,$4)',[a,{nickname:'Ana'},b,{nickname:'Beto'}]);
  const query=async(sql,values=[])=> (await db.query(sql,values)).rows[0];
  const ka=(await query('select equipped_kite_id id from public.player_profiles where id=$1',[a])).id;
  const kb=(await query("insert into public.player_kites(owner_id,model_id,pipamon_xp) values($1,'mata',$2) returning id",[b,levels.xpForLevel(45)])).id;
  await db.query('update public.player_profiles set equipped_kite_id=$1 where id=$2',[kb,b]);
  await db.exec('set role pipa_server');
  const pa=(await query("select public.reserve_player_match($1,$2,'ABCDEF','capture') r",[b,match])).r;assert.equal(pa.pipamonLevel,45);
  // A uses a collectible for this capture match.
  await db.exec('reset role');const collectible=(await query("insert into public.player_kites(owner_id,model_id) values($1,'azulao') returning id",[a])).id;
  await db.query('update public.player_profiles set equipped_kite_id=$1 where id=$2',[collectible,a]);
  await db.exec('set role pipa_server');await query("select public.reserve_player_match($1,$2,'ABCDEF','capture') r",[a,match]);
  await query('select public.settle_player_cut($1,$2,$3,$4,$5)',['verified-cut',match,a,b,kb]);
  await query('select public.settle_player_cut($1,$2,$3,$4,$5)',['verified-cut',match,a,b,kb]);
  await db.exec('reset role');assert.equal((await query('select pipamon_xp xp from public.player_kites where id=$1',[collectible])).xp,25);
  const captured=await query('select owner_id,pipamon_xp from public.player_kites where id=$1',[kb]);assert.equal(captured.owner_id,a);assert.equal(captured.pipamon_xp,levels.xpForLevel(45));
  await db.exec("set role authenticated;set request.jwt.claim.sub='"+a+"'");
  await assert.rejects(()=>db.query('update public.player_kites set pipamon_xp=25970 where id=$1',[collectible]));
  await assert.rejects(()=>db.query('select public.award_pipamon_xp($1,$2,$3,$4,120)',['forged',a,match,'trail']));
  await assert.rejects(()=>db.query('select * from public.pipamon_xp_events'));
  await db.exec('reset role');await query('select public.finish_player_match($1)',[match]);
  const trail='44444444-4444-4444-8444-444444444444';
  await query("select public.reserve_player_match($1,$2,'AABBCC','casual')",[a,trail]);
  await query("select public.register_trail_run($1,$2,'morro-1')",[a,trail]);
  await query("select public.settle_trail_run($1,$2,'morro-1',true,0)",[a,trail]);
  await query("select public.settle_trail_run($1,$2,'morro-1',true,0)",[a,trail]);
  assert.equal((await query('select pipamon_xp xp from public.player_kites where id=$1',[collectible])).xp,145);
  await db.query("select set_config('request.jwt.claim.sub',$1,false)",[a]);
  assert.equal((await query('select public.get_player_trail_result($1) r',[trail])).r.result.pipamonXp,120);
  await query('select public.finish_player_match($1)',[trail]);
  const daily='55555555-5555-4555-8555-555555555555';await query("select public.reserve_player_match($1,$2,'CCDDFF','casual')",[a,daily]);
  await query("select public.settle_daily_challenge($1,$2,(now() at time zone 'UTC')::date)",[a,daily]);await query("select public.settle_daily_challenge($1,$2,(now() at time zone 'UTC')::date)",[a,daily]);
  assert.equal((await query('select pipamon_xp xp from public.player_kites where id=$1',[collectible])).xp,245);
  for(let i=0;i<20;i++)await query("select public.award_pipamon_xp($1,$2,$3,'trail',120)",['budget-'+i,a,daily]);
  assert.equal((await query('select sum(xp)::int xp from public.pipamon_xp_events where owner_id=$1',[a])).xp,2000);
  await db.query("update public.pipamon_xp_events set created_at=now()-interval '2 days' where owner_id=$1",[a]);
  await db.query('update public.player_kites set pipamon_xp=25960 where id=$1',[collectible]);
  assert.equal((await query("select public.award_pipamon_xp('last-level',$1,$2,'cut',25) xp",[a,daily])).xp,10);
  assert.equal((await query("select public.award_pipamon_xp('last-level',$1,$2,'cut',25) xp",[a,daily])).xp,0);
  assert.equal((await query('select pipamon_xp xp from public.player_kites where id=$1',[collectible])).xp,25970);
  for(let level=1;level<=50;level++)assert.equal((await query('select public.pipamon_level($1) level',[levels.xpForLevel(level)])).level,level);
  assert.equal((await query('select pipamon_xp xp from public.player_kites where id=$1',[ka])).xp,0,'unequipped instance never earns XP');
 }finally{await db.close();}
});
