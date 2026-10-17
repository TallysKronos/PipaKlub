import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {randomUUID} from 'node:crypto';
import {PGlite} from '@electric-sql/pglite';
import {extendSummonPath,sampleSummonSegment} from './src/summon-pattern.js';
import {createAccounts} from './src/accounts.js';
import vm from 'node:vm';
import {parseHTML} from 'linkedom';
const a='11111111-1111-4111-8111-111111111111',b='22222222-2222-4222-8222-222222222222';
test('summoning consumes immediately, grants exactly once, enforces three attempts and damages interrupted sessions',async()=>{
 const db=new PGlite();
 try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;");
  for(const f of fs.readdirSync('supabase/migrations').sort())await db.exec(fs.readFileSync('supabase/migrations/'+f,'utf8'));
  for(const id of [a,b])await db.query('insert into auth.users values($1,$2)',[id,{nickname:'Pipeiro'}]);
  const grant=async(model,ref,source='drop')=>(await db.query('select public.grant_summon_tail($1,$2,$3,$4) id',[a,model,source,ref])).rows[0].id;
  const tail=await grant('mata','first'),tail2=await grant('azulao','second','purchase'),tail3=await grant('marulume','third','event'),tail4=await grant('raio','fourth');
  assert.equal(await grant('mata','first'),tail,'verified delivery retries do not duplicate items');
  await assert.rejects(()=>grant('raio','first'),/referência/);
  const session=randomUUID();
  const auth=async id=>db.exec("reset role;set role authenticated;set request.jwt.claim.sub='"+id+"'");
  const call=async(action,{tailId=null,ritualId=null,path=null,requestId=null,sessionId=session}={})=>(await db.query('select public.player_summon($1,$2,$3,$4,$5,$6) r',[action,tailId,ritualId,path,requestId,sessionId])).rows[0].r;
  await db.exec('set role anon');await assert.rejects(()=>call('inventory'),/permission denied/);
  await auth(a);await assert.rejects(()=>db.query('select * from public.summon_tails'),/permission denied/);await assert.rejects(()=>grant('mata','forged'),/permission denied/);
  const inventory=await call('inventory');assert.equal(inventory.tails.length,4);assert.equal(new Set(inventory.tails.map(t=>t.pattern.join(','))).size,4);
  let r=await call('start',{tailId:tail});assert.equal(r.remaining,3);
  await assert.rejects(()=>call('start',{tailId:tail2}),/já está/);
  await assert.rejects(()=>call('start',{tailId:tail,sessionId:randomUUID()}),/utilizada/);
  await db.exec('reset role');assert.equal((await db.query('select status from public.summon_tails where id=$1',[tail])).rows[0].status,'used');
  await auth(b);await assert.rejects(()=>call('attempt',{ritualId:r.id,path:r.pattern,requestId:randomUUID()}),/sessão/);
  await auth(a);await assert.rejects(()=>call('attempt',{ritualId:r.id,path:r.pattern,requestId:randomUUID(),sessionId:randomUUID()}),/sessão/);
  const wrongId=randomUUID();const wrong=await call('attempt',{ritualId:r.id,path:[1],requestId:wrongId});assert.equal(wrong.remaining,2);
  assert.equal((await call('attempt',{ritualId:r.id,path:[1],requestId:wrongId})).remaining,2,'network retry is the same attempt');
  await assert.rejects(()=>call('attempt',{ritualId:r.id,path:r.pattern,requestId:wrongId}),/já utilizada/);
  const requestId=randomUUID();const done=await call('attempt',{ritualId:r.id,path:r.pattern,requestId});assert.equal(done.status,'succeeded');assert.ok(done.kiteId);
  assert.equal((await call('attempt',{ritualId:r.id,path:r.pattern,requestId})).kiteId,done.kiteId);
  assert.equal((await call('attempt',{ritualId:r.id,path:r.pattern,requestId:randomUUID()})).kiteId,done.kiteId);
  await db.exec('reset role');assert.equal((await db.query('select count(*)::int n from public.player_kites where owner_id=$1',[a])).rows[0].n,5);
  await auth(a);r=await call('start',{tailId:tail2});
  for(let i=0;i<3;i++)r=await call('attempt',{ritualId:r.id,path:[1],requestId:randomUUID()});
  assert.equal(r.status,'failed');assert.equal(r.remaining,0);assert.equal((await call('attempt',{ritualId:r.id,path:r.pattern,requestId:randomUUID()})).status,'failed');
  await assert.rejects(()=>call('start',{tailId:tail3}),/ainda não viu/);
  await db.query('select public.record_player_sighting($1)',['marulume']);
  r=await call('start',{tailId:tail3});const soul=await call('attempt',{ritualId:r.id,path:r.pattern,requestId:randomUUID()});assert.equal(soul.status,'succeeded');
  await db.exec('reset role');assert.equal((await db.query('select permanent from public.player_kites where id=$1',[soul.kiteId])).rows[0].permanent,true);await assert.rejects(()=>db.query('update public.player_kites set owner_id=$1 where id=$2',[b,soul.kiteId]),/vinculada/);
  await auth(a);r=await call('start',{tailId:tail4});assert.equal((await call('abandon',{ritualId:r.id})).status,'abandoned');
  assert.equal((await call('inventory')).tails.find(t=>t.id===tail4).status,'damaged');await assert.rejects(()=>call('start',{tailId:tail4,sessionId:randomUUID()}),/utilizada/);
  await call('discard',{tailId:tail4});assert.equal((await call('inventory')).tails.length,0);
  await db.exec('reset role');const expiredTail=await grant('mata','expired');await auth(a);r=await call('start',{tailId:expiredTail});
  await db.exec('reset role');await db.query("update public.summon_rituals set expires_at=now()-interval '1 second' where id=$1",[r.id]);
  await auth(a);assert.equal((await call('attempt',{ritualId:r.id,path:r.pattern,requestId:randomUUID()})).status,'abandoned');assert.equal((await call('inventory')).tails[0].status,'damaged');
  await db.exec('reset role');assert.equal((await db.query('select count(*)::int n from public.summon_recipes')).rows[0].n,0,'no alternative is enabled by default');
  const alt=await grant('mata','alternative');await auth(a);
  const targetedStart=async()=> (await db.query("select public.player_summon('start',$1,null,null,null,$2,'azulao') r",[alt,session])).rows[0].r;
  await assert.rejects(targetedStart,/não aceita/);
  await db.exec('reset role');assert.equal((await db.query('select status from public.summon_tails where id=$1',[alt])).rows[0].status,'ready','unsupported combinations do not consume the tail');
  await db.query("insert into public.summon_recipes values('azulao','mata','raio')");await auth(a);
  r=await targetedStart();assert.equal(r.targetModelId,'azulao');assert.equal(r.resultModelId,'raio');
  const variant=await call('attempt',{ritualId:r.id,path:r.pattern,requestId:randomUUID()});
  await db.exec('reset role');assert.equal((await db.query('select model_id from public.player_kites where id=$1',[variant.kiteId])).rows[0].model_id,'raio','the configured form is awarded, rather than the tail or target model');
  const opponent=(await db.query("select public.grant_event_soul($1,'hiponilo','sighting-test') id",[b])).rows[0].id;
  await db.query('update public.player_profiles set equipped_kite_id=$1 where id=$2',[opponent,b]);
  const encounter=randomUUID();await db.query("select public.reserve_player_match($1,$2,'ABCDEF','casual')",[a,encounter]);await db.query("select public.reserve_player_match($1,$2,'ABCDEF','casual')",[b,encounter]);
  await auth(a);assert.ok((await call('inventory')).seen.some(p=>p.modelId==='hiponilo'),'encountering another equipped Pipamon records a sighting');
  await assert.rejects(()=>db.query("select public.record_player_sighting('inventado')"),/desconhecido/);
 }finally{await db.close();}
});
test('spell tracing captures intermediate stars, ignores repeated nodes and samples fast swipes in order',()=>{
 assert.deepEqual(extendSummonPath([1],3),[1,2,3]);assert.deepEqual(extendSummonPath([1],9),[1,5,9]);assert.deepEqual(extendSummonPath([1,5],9),[1,5,9]);assert.deepEqual(extendSummonPath([1,2],1),[1,2]);
 assert.deepEqual(sampleSummonSegment([],{x:50,y:50},{x:250,y:250}),[1,5,9]);assert.deepEqual(sampleSummonSegment([1],{x:50,y:50},{x:250,y:50}),[1,2,3]);assert.deepEqual(sampleSummonSegment([],{x:0,y:0},{x:0,y:300}),[]);
});
test('summon HTTP rejects invalid paths and missing authentication before RPC',async()=>{
 let rpcCalls=0;const accounts=createAccounts({SUPABASE_URL:'https://db.test',SUPABASE_PUBLISHABLE_KEY:'key'},{gameDatabase:{},fetcher:async url=>{if(url.endsWith('/user'))return new Response(JSON.stringify({id:a}));rpcCalls++;return new Response('{}');}});
 const req=(body,cookie='pipa_access=local')=>new Request('http://localhost/account/summon',{method:'POST',headers:{'Content-Type':'application/json',cookie},body:JSON.stringify(body)});
 assert.equal((await accounts.handle(req({action:'start'},''))).status,401);
 for(const path of [[0],[10],[1.5],Array(10).fill(1),'123'])assert.equal((await accounts.handle(req({action:'attempt',path}))).status,400);
 assert.equal(rpcCalls,0);assert.equal((await accounts.handle(req({action:'inventory'}))).status,200);
});
function summonUI(request){
 const {document}=parseHTML('<html><body><div id="accountCollection"><div id="collectionMain"><div id="inventoryList"></div></div></div></body></html>');
 const context=vm.createContext({document,crypto,console,playerAccount:{},mode:null,keys:{},setInterval(){},addEventListener(){},refreshAccount(){},accountRequest:async(action,body)=>({summon:await request(body)}),$:id=>document.getElementById(id),uiElement(tag,text,className){const el=document.createElement(tag);if(text)el.textContent=text;if(className)el.className=className;return el;},art:{markup:()=>'<span></span>',load:async()=>true,draw(){}}});
 vm.runInContext(fs.readFileSync('src/summon-pattern.js','utf8').replaceAll('export function','function')+'\n'+fs.readFileSync('src/summon-client.js','utf8'),context);
 document.getElementById('summonAssis').getContext=()=>({});
 return {document,run:code=>vm.runInContext(code,context)};
}
const testTail={id:'tail',modelId:'mata',name:'Mata verde',color:1,source:'drop',status:'ready',pattern:[1,2,3,6,9]};
const testInventory=()=>({tails:[testTail],seen:[{modelId:'mata',name:'Mata verde',color:1,pattern:testTail.pattern,availableTailIds:['tail']},{modelId:'azulao',name:'Azulão',color:2,pattern:[1,2,5,6],availableTailIds:[]}]});
function chooseTestTail(app){app.document.getElementById('summonInvoke').onclick();app.document.querySelector('#summonSeenGrid button').onclick();app.document.querySelector('#summonTailList button').onclick();}
test('summon UI retries a lost response with the same request and abandons on leaving',async()=>{
 const calls=[];let lost=true;
 const app=summonUI(async body=>{calls.push(body);if(body.action==='inventory')return testInventory();if(body.action==='start')return {id:'ritual',status:'active',remaining:3,pattern:testTail.pattern};if(body.action==='attempt'){if(lost){lost=false;throw Error('offline');}return {id:'ritual',status:'active',remaining:2,pattern:testTail.pattern};}return {};});
 await app.run('openSummoner()');chooseTestTail(app);await app.run('summonStart.onclick()');
 await app.run('summonPath=[1];submitSummon()');assert.equal(app.run('!!summonPending'),true);
 await app.run('submitSummon()');const attempts=calls.filter(c=>c.action==='attempt');assert.equal(attempts.length,2);assert.equal(attempts[0].requestId,attempts[1].requestId);assert.equal(app.run('summonRitual.remaining'),2);
 app.run('leaveSummoner()');assert.equal(calls.at(-1).action,'abandon');assert.equal(calls.at(-1).ritualId,'ritual');assert.equal(app.document.getElementById('collectionMain').hidden,false);
});
test('closing during an in-flight ritual start still abandons the consumed tail',async()=>{
 let resolveStart;const calls=[];
 const app=summonUI(async body=>{calls.push(body);if(body.action==='inventory')return testInventory();if(body.action==='start')return new Promise(resolve=>{resolveStart=resolve;});return {};});
 await app.run('openSummoner()');chooseTestTail(app);const pending=app.run('summonStart.onclick()');app.run('leaveSummoner()');
 resolveStart({id:'late-ritual',status:'active',remaining:3,pattern:testTail.pattern});await pending;assert.equal(calls.at(-1).action,'abandon');assert.equal(calls.at(-1).ritualId,'late-ritual');assert.equal(app.run('summonRitual'),null);
});
test('NPC catalog lists seen Pipamon with availability badges, then requires tail selection and explicit Use',async()=>{
 const calls=[];const app=summonUI(async body=>{calls.push(body);if(body.action==='inventory')return testInventory();return {id:'ritual',status:'active',remaining:3,pattern:testTail.pattern};});
 await app.run('openSummoner()');assert.equal(app.document.getElementById('summonMenu').hidden,false);assert.equal(app.document.getElementById('summonCatalog').hidden,true);
 app.document.getElementById('summonInvoke').onclick();const cards=app.document.querySelectorAll('#summonSeenGrid button');assert.equal(cards.length,2);assert.equal(cards[1].classList.contains('locked'),true);
 cards[1].onclick();assert.equal(app.document.querySelector('#summonTailList button').disabled,true);assert.equal(app.document.getElementById('summonStart').disabled,true);
 app.document.getElementById('summonPreparationBack').onclick();cards[0].onclick();assert.equal(app.document.getElementById('summonStart').disabled,true);
 app.document.querySelector('#summonTailList button').onclick();assert.equal(app.document.getElementById('summonStart').disabled,false);assert.equal(app.document.getElementById('summonRitual').hidden,true);assert.equal(calls.length,1,'browsing and selection do not consume anything');
 await app.run('summonStart.onclick()');assert.equal(calls.at(-1).targetModelId,'mata');assert.equal(calls.at(-1).tailId,'tail');assert.equal(app.document.getElementById('summonPreparation').hidden,true);assert.equal(app.document.getElementById('summonRitual').hidden,false);
});
