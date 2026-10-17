import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {PGlite} from '@electric-sql/pglite';
import {createAccounts} from './src/accounts.js';
import vm from 'node:vm';
import {parseHTML} from 'linkedom';
const a='11111111-1111-4111-8111-111111111111',b='22222222-2222-4222-8222-222222222222',c='33333333-3333-4333-8333-333333333333';
test('PostgreSQL invite trade: permissions, membership, revision, atomic swap, retries and expiry',async()=>{
 const db=new PGlite();
 try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;");
  for(const f of fs.readdirSync('supabase/migrations').sort())await db.exec(fs.readFileSync('supabase/migrations/'+f,'utf8'));
  for(const id of [a,b,c])await db.query('insert into auth.users values($1,$2)',[id,{nickname:id===a?'Ana':'Amigo'}]);
  const kite=async(id,model)=>(await db.query('select id from public.player_kites where owner_id=$1 and model_id=$2',[id,model])).rows[0].id;
  const ak=await kite(a,'mata'),ak2=await kite(a,'raio'),bk=await kite(b,'azulao'),basic=await kite(a,'basica');
  const as=async id=>db.exec("reset role;set role authenticated;set request.jwt.claim.sub='"+id+"'");
  const call=async(action,code=null,k=null,rev=null)=>(await db.query('select public.player_trade($1,$2,$3,$4) t',[action,code,k,rev])).rows[0].t;
  await db.exec('set role anon');await assert.rejects(()=>call('create'),/permission denied/);
  await as(a);await assert.rejects(()=>db.query('select * from public.kite_trades'),/permission denied/);
  let t=await call('create');const code=t.code;assert.match(code,/^[A-F0-9]{12}$/);
  await assert.rejects(()=>call('create'),/negociação/);
  await assert.rejects(()=>call('confirm',code,null,t.revision),/cada participante/);
  await assert.rejects(()=>call('offer',code,basic,t.revision),/colecionável/);
  await assert.rejects(()=>call('offer',code,bk,t.revision),/colecionável/);
  await as(b);t=await call('join',code);await as(c);
  await assert.rejects(()=>call('join',code),/cheia/);await assert.rejects(()=>call('read',code),/acesso/);
  await as(a);t=await call('offer',code,ak,t.revision);
  await db.exec('reset role');
  await assert.rejects(()=>db.query("select public.reserve_player_match($1,gen_random_uuid(),'ABCDEF','casual')",[a]),/Troca:/);
  await as(b);t=await call('offer',code,bk,t.revision);
  await as(a);t=await call('confirm',code,null,t.revision);assert.equal(t.hostConfirmed,true);
  const old=t.revision;t=await call('offer',code,ak2,t.revision);assert.equal(t.hostConfirmed,false);assert.equal(t.guestConfirmed,false);
  await db.query('select public.equip_player_kite($1)',[ak2]);
  await as(b);await assert.rejects(()=>call('confirm',code,null,old),/mudou/);
  t=await call('confirm',code,null,t.revision);await as(a);t=await call('confirm',code,null,t.revision);assert.equal(t.status,'completed');
  assert.equal((await call('confirm',code,null,t.revision)).status,'completed');
  await db.exec('reset role');assert.equal((await db.query('select owner_id from public.player_kites where id=$1',[ak2])).rows[0].owner_id,b);assert.equal((await db.query('select owner_id from public.player_kites where id=$1',[bk])).rows[0].owner_id,a);
  assert.equal((await db.query('select count(*)::int n from public.player_kites')).rows[0].n,12);
  assert.equal((await db.query('select equipped_kite_id from public.player_profiles where id=$1',[a])).rows[0].equipped_kite_id,basic);
  await as(a);const history=await call('history');assert.equal(history.length,1);assert.equal(history[0].receipt.hostKite.id,ak2);
  t=await call('create');assert.equal((await call('cancel',t.code)).status,'cancelled');
  t=await call('create');await db.exec('reset role');await db.query("update public.kite_trades set expires_at=now()-interval '1 second' where code=$1",[t.code]);
  await as(a);assert.equal((await call('read',t.code)).status,'expired');await as(b);await assert.rejects(()=>call('join',t.code),/encerrada/);
  // Pending/stale matches remain protected until the game server releases them.
  await db.exec('reset role');await db.query("update public.player_profiles set active_match=gen_random_uuid(),active_until=now()-interval '1 minute' where id=$1",[a]);
  await as(a);await assert.rejects(()=>call('create'),/aguarde/);
  await db.exec('reset role');await db.query('update public.player_profiles set active_match=null where id=$1',[a]);
  const soul=(await db.query("select public.grant_event_soul($1,'flautrevo','test-event') id",[a])).rows[0].id;
  await as(a);t=await call('create');await assert.rejects(()=>call('offer',t.code,soul,t.revision),/colecionável/);
  await as(b);t=await call('join',t.code);t=await call('offer',t.code,ak2,t.revision);
  await as(a);t=await call('offer',t.code,ak,t.revision);t=await call('confirm',t.code,null,t.revision);
  // A late invalidation must roll back the second confirmation and both owners.
  await db.exec('reset role');await db.query('update public.player_kites set owner_id=$1 where id=$2',[c,ak2]);
  await as(b);await assert.rejects(()=>call('confirm',t.code,null,t.revision),/indisponíveis/);
  await db.exec('reset role');assert.equal((await db.query('select owner_id from public.player_kites where id=$1',[ak])).rows[0].owner_id,a);
  assert.equal((await db.query('select guest_confirmed from public.kite_trades where code=$1',[t.code])).rows[0].guest_confirmed,false);
 }finally{await db.close();}
});
test('trade UI filters bound kites, renders names safely and submits the displayed revision',async()=>{
 const {document}=parseHTML('<html><body><div id="collectionMain"><div id="inventoryList"></div></div><div id="accountMessage"></div></body></html>');
 const calls=[];const state={code:'ABCDEF123456',status:'open',revision:7,isHost:true,expiresAt:new Date().toISOString(),hostName:'<img src=x>',guestName:'Amigo',hostKite:{id:'regular',name:'Mata'},guestKite:{id:'other',name:'Raio'}};
 const context=vm.createContext({document,Date,console,$:id=>document.getElementById(id),setInterval(){},accountModal:{style:{display:'flex'}},playerAccount:{inventory:[{id:'regular',permanent:false,model:{name:'Mata',acquisition:'starter'}},{id:'basic',permanent:true,model:{name:'Básica'}},{id:'soul',permanent:false,model:{name:'Soul',acquisition:'event'}}]},refreshAccount:async()=>{},accountRequest:async(action,body)=>{calls.push(body);return {trade:state};},uiElement(tag,text,className){const el=document.createElement(tag);if(text)el.textContent=text;if(className)el.className=className;return el;}});
 vm.runInContext(fs.readFileSync('src/trade-client.js','utf8'),context);
 // linkedom's select value has no setter; supply the browser behavior here.
 const proto=Object.getPrototypeOf(document.createElement('select'));Object.defineProperty(proto,'value',{configurable:true,get(){return this._value||'';},set(v){this._value=v;}});
 await vm.runInContext("tradeAction('read')",context);
 assert.equal(document.querySelectorAll('#tradeActions option').length,2);
 assert.equal(document.querySelector('#tradeState img'),null);assert.match(document.getElementById('tradeState').textContent,/<img/);
 const confirm=[...document.querySelectorAll('#tradeActions button')].find(b=>b.textContent.includes('Confirmar'));
 await confirm.onclick();assert.equal(calls.at(-1).revision,7);assert.equal(calls.at(-1).action,'confirm');
});
test('trade HTTP authenticates and validates input before calling the user RPC',async()=>{
 const calls=[];const accounts=createAccounts({SUPABASE_URL:'https://db.test',SUPABASE_PUBLISHABLE_KEY:'key'},{gameDatabase:{},fetcher:async(url,o)=>{calls.push([url,o]);return new Response(JSON.stringify(url.endsWith('/user')?{id:a}:{code:'ABCDEF123456'}));}});
 const request=(body,cookie='__Host-pipa_access=token')=>new Request('https://game.test/account/trade',{method:'POST',headers:{'Content-Type':'application/json',cookie},body:JSON.stringify(body)});
 assert.equal((await accounts.handle(request({action:'create'},''))).status,401);
 assert.equal((await accounts.handle(request({action:'offer',kiteId:'bad'}))).status,400);
 assert.equal((await accounts.handle(request({action:'create'}))).status,200);
 const rpc=calls.find(([url])=>url.endsWith('/rpc/player_trade'));assert.equal(rpc[1].headers.Authorization,'Bearer token');assert.equal(JSON.parse(rpc[1].body).p_action,'create');
});
test('joining a match while trading reports a conflict instead of a database outage',async()=>{
 const accounts=createAccounts({SUPABASE_URL:'https://db.test',SUPABASE_PUBLISHABLE_KEY:'key'},{gameDatabase:{async rpc(){throw Object.assign(Error('Troca: cancele a negociação antes de entrar em partida.'),{code:'P0001'});}},fetcher:async()=>new Response(JSON.stringify({id:a}))});
 await assert.rejects(()=>accounts.preparePlayer(new Request('https://game.test/api/join',{headers:{cookie:'__Host-pipa_access=token'}}),{id:c,code:'ABCDEF',rules:'casual',players:[]}),e=>e.status===409&&e.message.startsWith('Troca:'));
});
