import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import {randomUUID} from 'node:crypto';
import {PGlite} from '@electric-sql/pglite';
import {parseHTML} from 'linkedom';
import {createAccounts} from './src/accounts.js';
import {createAssetHandler} from './src/static-assets.js';
import {artConfig} from './scripts/art-build.mjs';
import {workshopInput,workshopPayload,workshopReady,workshopPose} from './src/workshop-model.js';
const a='11111111-1111-4111-8111-111111111111',b='22222222-2222-4222-8222-222222222222';
const steps=[{joints:[0,1,2,3]},{tension:65},{cuts:[0,1,2,3]},{balance:50},{wind:50,tension:50}];
test('workshop migration resumes reservations, validates ordered stages and awards exactly once without modifying existing collection',async()=>{
 const db=new PGlite();
 try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;");
  for(const f of fs.readdirSync('supabase/migrations').filter(f=>f.endsWith('.sql')&&f<'024').sort())await db.exec(fs.readFileSync('supabase/migrations/'+f,'utf8'));
  for(const id of[a,b])await db.query('insert into auth.users values($1,$2)',[id,{nickname:'Teste'}]);
  const grant=async(model,ref)=>(await db.query("select public.grant_summon_tail($1,$2,'event',$3) id",[a,model,ref])).rows[0].id;
  const old=await grant('mata','legacy-interrupted'),damaged=await grant('azulao','old-damage');
  await db.query("insert into public.player_pipamon_sightings values($1,'rabbito',now()),($1,'mata',now()),($1,'azulao',now()) on conflict do nothing",[a]);
  const original=(await db.query('select id,model_id from public.player_kites where owner_id=$1 order by id',[a])).rows;
  await db.query("update public.summon_tails set status='damaged' where id=$1",[damaged]);
  await db.exec("set role authenticated;set request.jwt.claim.sub='"+a+"'");
  await db.query("select public.player_summon('start',$1,null,null,null,$2)",[old,randomUUID()]);
  await db.exec('reset role');await db.exec(fs.readFileSync('supabase/migrations/024_soul_workshop.sql','utf8'));
  const tail=await grant('rabbito','workshop-test');
  assert.equal((await db.query('select status from public.summon_tails where id=$1',[old])).rows[0].status,'ready');
  const auth=async id=>db.exec("reset role;set role authenticated;set request.jwt.claim.sub='"+id+"'");
  const call=async(action,{tailId=null,jobId=null,target=null,stage=null,payload=null,requestId=null}={})=>(await db.query('select public.player_workshop($1,$2,$3,$4,$5,$6,$7) r',[action,tailId,jobId,target,stage,payload,requestId])).rows[0].r;
  await db.exec('set role anon');await assert.rejects(()=>call('inventory'),/permission denied/);
  await auth(a);await assert.rejects(()=>db.query('select * from public.workshop_jobs'),/permission denied/);await assert.rejects(()=>db.query("select public.player_summon('inventory')"),/permission denied/);
  const inv=await call('inventory');assert.equal(JSON.stringify(inv).includes('pattern'),false);assert.equal(inv.version,1);
  await call('restore',{tailId:damaged});
  const job=await call('start',{tailId:tail,target:'rabbito'});assert.equal(job.stage,0);
  assert.equal((await call('start',{tailId:tail,target:'rabbito'})).id,job.id);
  await assert.rejects(()=>call('start',{tailId:old,target:'mata'}),/retome/);
  await auth(b);await assert.rejects(()=>call('advance',{jobId:job.id,stage:0,payload:steps[0],requestId:randomUUID()}),/pertence/);
  await assert.rejects(()=>call('start',{tailId:tail}),/não encontrada/);await auth(a);
  await assert.rejects(()=>call('advance',{jobId:job.id,stage:4,payload:steps[4],requestId:randomUUID()}),/atualizada/);
  await assert.rejects(()=>call('advance',{jobId:job.id,stage:0,payload:{joints:[0,2,1,3]},requestId:randomUUID()}),/ordem/);
  let result;for(let stage=0;stage<5;stage++){
   const args={jobId:job.id,stage,payload:steps[stage],requestId:randomUUID()};result=await call('advance',args);
   assert.deepEqual(await call('advance',args),result,'same request replays its committed result');
   await assert.rejects(()=>call('advance',{...args,payload:{forged:true}}),/já utilizada/);
   if(stage<4){const resumed=await call('inventory');assert.equal(resumed.active.stage,stage+1);assert.equal(resumed.active.id,job.id);}
  }
  assert.equal(result.status,'completed');assert.equal(result.quality,100);assert.ok(result.kiteId);
  assert.equal((await call('advance',{jobId:job.id,stage:4,payload:steps[4],requestId:randomUUID()})).kiteId,result.kiteId);
  assert.equal((await call('inventory')).active,null);
  await db.exec('reset role');const after=(await db.query('select id,model_id from public.player_kites where owner_id=$1 order by id',[a])).rows;
  assert.equal(after.length,original.length+1);for(const k of original)assert.ok(after.some(x=>x.id===k.id&&x.model_id===k.model_id));
  assert.equal((await db.query('select status from public.summon_tails where id=$1',[tail])).rows[0].status,'consumed');
  // Reservation has no expiry: reopening from a new browser/session resumes it.
  await auth(a);const next=await call('start',{tailId:old,target:'mata'});await db.exec('reset role');await db.query("update public.workshop_jobs set updated_at=now()-interval '3 days' where id=$1",[next.id]);await auth(a);assert.equal((await call('inventory')).active.id,next.id);
 }finally{await db.close();}
});
test('workshop HTTP enforces authentication and rejects malformed stages before RPC',async()=>{
 let calls=0;const accounts=createAccounts({SUPABASE_URL:'https://db.test',SUPABASE_PUBLISHABLE_KEY:'key'},{gameDatabase:{},fetcher:async url=>{if(url.endsWith('/user'))return new Response(JSON.stringify({id:a}));calls++;return new Response('{}');}});
 const req=(body,cookie='pipa_access=local')=>new Request('http://localhost/account/workshop',{method:'POST',headers:{'Content-Type':'application/json',cookie},body:JSON.stringify(body)});
 assert.equal((await accounts.handle(req({action:'inventory'},''))).status,401);
 for(const stage of[-1,5,1.5,null])assert.equal((await accounts.handle(req({action:'advance',jobId:a,requestId:b,stage,payload:{}}))).status,400);
 for(const [stage,payload] of [[1,{tension:35.5}],[1,{tension:-1}],[4,{wind:50,tension:101}],[2,{cuts:[0,2,1,3]}]])assert.equal((await accounts.handle(req({action:'advance',jobId:a,requestId:b,stage,payload}))).status,400);
 assert.equal(calls,0);assert.equal((await accounts.handle(req({action:'inventory'}))).status,200);
});
function ui(request){
 const {document,window}=parseHTML('<html><body><div id="accountCollection"><div id="collectionMain"><div id="inventoryList"></div></div></div></body></html>');window.HTMLElement.prototype.focus=function(){};
 const context=vm.createContext({document,crypto,console,playerAccount:{profile:{id:a}},mode:null,keys:{},requestAnimationFrame:()=>1,cancelAnimationFrame(){},refreshAccount(){},ART_CONFIG:{dex:{entries:[]}},accountRequest:async(action,body)=>{assert.equal(action,'workshop');return {workshop:await request(body)};},$:id=>document.getElementById(id),uiElement(tag,text,className){const e=document.createElement(tag);if(text)e.textContent=text;if(className)e.className=className;return e;},art:{markup:()=>'<span></span>',load:async()=>true}});
 vm.runInContext(fs.readFileSync('src/workshop-model.js','utf8').replace(/^export /gm,'')+'\n'+fs.readFileSync('src/summon-client.js','utf8'),context);return {document,run:code=>vm.runInContext(code,context)};
}
const inventory={tails:[{id:a,modelId:'rabbito',name:'Rabbito',status:'ready'}],seen:[{modelId:'rabbito',name:'Rabbito',availableTailIds:[a]}]};
test('construction UI preserves lost confirmations and leaving does not damage a reserved tail',async()=>{
 const calls=[];let lost=true;const app=ui(async body=>{calls.push(body);if(body.action==='inventory')return inventory;if(body.action==='start')return {id:b,stage:0,status:'building',modelId:'rabbito'};if(body.action==='advance'){if(lost){lost=false;throw Error('offline');}return {id:b,stage:1,status:'building',modelId:'rabbito'};}});
 await app.run('openSummoner()');app.document.getElementById('summonInvoke').onclick();app.document.querySelector('#summonSeenGrid button').onclick();app.document.querySelector('#summonTailList button').onclick();await app.document.getElementById('summonStart').onclick();
 for(let i=0;i<4;i++)app.document.querySelectorAll('#workshopInputs button')[i].onclick();
 await app.document.getElementById('workshopConfirm').onclick();assert.equal(app.run('!!workshopPending'),true);assert.equal(app.document.getElementById('workshopRedo').disabled,true);
 await app.document.getElementById('workshopConfirm').onclick();const sent=calls.filter(c=>c.action==='advance');assert.equal(sent[0].requestId,sent[1].requestId);assert.equal(app.run('summonRitual.stage'),1);
 const count=calls.length;app.run('leaveSummoner()');assert.equal(calls.length,count,'no abandon beacon, heartbeat or item destruction');
});
test('late workshop responses cannot reopen a closed screen and inputs remain accessible without tracing',async()=>{
 let resolve;const app=ui(async b=>b.action==='inventory'?inventory:new Promise(r=>resolve=r));await app.run('openSummoner()');app.document.querySelector('#summonSeenGrid button').onclick();app.document.querySelector('#summonTailList button').onclick();const pending=app.document.getElementById('summonStart').onclick();app.run('leaveSummoner()');resolve({id:b,stage:0,status:'building'});await pending;assert.equal(app.run('summonRitual'),null);assert.equal(app.document.getElementById('summonRoom').hidden,true);
 const input=workshopInput();assert.equal(workshopReady(0,input),false);input.joints=[0,1,2,3];assert.deepEqual(workshopPayload(0,input),steps[0]);for(const value of Object.values(workshopPose(5,input,100,true)))assert.equal(Number.isFinite(value),true);
});
test('workshop art crops fit original sources and both web builds serve identical versioned images',async()=>{
 const config=artConfig().workshop,handler=createAssetHandler();
 for(const [id,def]of Object.entries(config.images)){
  const original=fs.readFileSync('assets/'+def.image),response=await handler(new Request('http://localhost/'+def.url));
  assert.equal(response.status,200);assert.deepEqual(Buffer.from(await response.arrayBuffer()),original);assert.match(response.headers.get('Cache-Control'),/immutable/);
  assert.deepEqual(fs.readFileSync('docs/assets/'+def.image),original);
  if(id==='parts'){const w=original.readUInt32BE(16),h=original.readUInt32BE(20);for(const r of Object.values(config.rects))assert.ok(r.length===4&&r.every(Number.isFinite)&&r[0]>=0&&r[1]>=0&&r[2]>0&&r[3]>0&&r[0]+r[2]<=w&&r[1]+r[3]<=h);}
 }
});
