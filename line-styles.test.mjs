import {seedCollection} from './test-support/collection-fixture.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {PGlite} from '@electric-sql/pglite';
import {createLineStyles} from './src/line-styles.js';
import {createEngine} from './src/engine.js';
import {createNetworkView} from './src/network-view.js';
import {createAccounts} from './src/accounts.js';
const a='11111111-1111-4111-8111-111111111111',b='22222222-2222-4222-8222-222222222222';
test('line shop atomically debits confirmed coins, owns/equips once and reserves the server-selected style',async()=>{
 const db=new PGlite();try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;grant execute on function auth.uid() to authenticated,anon,service_role;");
  for(const f of fs.readdirSync('supabase/migrations').filter(f=>f.endsWith('.sql')).sort())await db.exec(fs.readFileSync('supabase/migrations/'+f,'utf8'));
  for(const id of [a,b])await db.query('insert into auth.users values($1,$2)',[id,{nickname:'Teste'}]);
await seedCollection(db,[a,b]);
  const as=async id=>db.exec("reset role;set role authenticated;set request.jwt.claim.sub='"+id+"'");
  const call=async(action='read',style=null,op=null)=>(await db.query('select public.player_lines($1,$2,$3) l',[action,style,op])).rows[0].l;
  await db.exec('set role anon');await assert.rejects(()=>call(),/permission denied/);
  await as(a);await assert.rejects(()=>db.query('select * from public.player_line_styles'),/permission denied/);
  let data=await call();assert.equal(data.equipped,'classic');
  const styles=createLineStyles();assert.deepEqual(data.catalog.map(i=>[i.id,i.price]).sort(),styles.items.map(i=>[i.id,i.price]).sort());
  await assert.rejects(()=>call('buy','azul',crypto.randomUUID()),/insuficientes/);
  await assert.rejects(()=>call('equip','azul'),/adquira/);
  // Trusted fixture only: players can no longer mint coins through legacy imports.
  await db.exec('reset role');await db.query("update public.player_trails set progress=jsonb_set(progress,'{coins}','50'::jsonb) where owner_id=$1",[a]);await as(a);
  // Simultaneous purchases cannot spend the same 50 coins twice.
  const buys=await Promise.allSettled([call('buy','azul',crypto.randomUUID()),call('buy','coral',crypto.randomUUID())]);
  assert.equal(buys.filter(r=>r.status==='fulfilled').length,1);data=await call();assert.equal(data.progress.coins,20);assert.equal(data.owned.length,1);
  const owned=data.owned[0],op=crypto.randomUUID();data=await call('buy',owned,op);assert.equal(data.progress.coins,20);
  assert.equal((await call('buy',owned,op)).progress.coins,20);
  await assert.rejects(()=>call('buy','dourada',op),/já utilizada/);
  data=await call('equip',owned);assert.equal(data.equipped,owned);
  await db.exec('reset role;set role pipa_server');
  await assert.rejects(()=>db.query("select public.reserve_player_match_without_lines($1,$2,'TESTE1','casual')",[a,crypto.randomUUID()]),/permission denied/);
  const match=crypto.randomUUID(),snapshot=(await db.query("select public.reserve_player_match($1,$2,'TESTE1','casual') s",[a,match])).rows[0].s;
  assert.equal(snapshot.lineStyle,owned);
  await as(a);await assert.rejects(()=>call('equip','classic'),/saia da partida/);
  await as(b);data=await call();assert.deepEqual(data.owned,[]);assert.equal(data.progress.coins,0);assert.equal(data.equipped,'classic');await assert.rejects(()=>call('equip',owned),/adquira/);
 }finally{await db.close();}
});
test('line visuals survive snapshots and prediction while combat and physics stay identical',()=>{
 const engine=createEngine(),styles=createLineStyles(),plain=engine.player('A',0,'you',1000);Object.assign(plain,{x:500,y:200,anchorX:90});
 for(const item of styles.items){const styled={...structuredClone(plain),lineStyle:item.id},baseline=structuredClone(plain);engine.move(styled,{x:1,cut:true},.1);engine.move(baseline,{x:1,cut:true},.1);const {lineStyle,...physical}=styled;assert.deepEqual(physical,baseline);assert.deepEqual(engine.line(styled),engine.line(baseline));
  const state=engine.create(1000);state.players=[styled];const view=createNetworkView(engine);view.receive(engine.visible(state),'you',1000);assert.equal(view.render(1016,{},.016)[0].lineStyle,item.id);
 }
 const c={setLineDash(d){this.dash=d;}};styles.apply(c,'dourada',true);assert.equal(c.shadowBlur,undefined);styles.apply(c,'pontilhada');assert.deepEqual(c.dash,[3,6]);assert.equal(styles.get('forged').id,'classic');
});
test('line shop HTTP rejects foreign origins, missing login and forged styles; prices never enter RPC',async()=>{
 const calls=[],api=createAccounts({SUPABASE_URL:'https://supabase.test',SUPABASE_ANON_KEY:'public'},{gameDatabase:{},fetcher:async(url,options)=>{if(url.endsWith('/auth/v1/user'))return new Response(JSON.stringify({id:a}));calls.push(JSON.parse(options.body));return new Response(JSON.stringify({equipped:'classic',owned:[],catalog:[],progress:{coins:0},revision:0}));}});
 const call=(body,extra={})=>api.handle(new Request('https://game.test/account/lines',{method:'POST',headers:{'Content-Type':'application/json',...extra},body:JSON.stringify(body)}));
 assert.equal((await call({action:'read'})).status,401);const headers={cookie:'__Host-pipa_access=test'};
 assert.equal((await call({action:'equip',styleId:'forged'},headers)).status,400);assert.equal((await call({action:'read'},{...headers,origin:'https://foreign.test'})).status,403);
 const op=crypto.randomUUID();assert.equal((await call({action:'buy',styleId:'azul',operationId:op,price:0,userId:b},headers)).status,200);assert.deepEqual(calls[0],{p_action:'buy',p_style:'azul',p_operation:op});
});
