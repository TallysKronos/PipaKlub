import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {PGlite} from '@electric-sql/pglite';
import {createTrails} from './src/trails.js';
import {createTrailSync} from './src/trail-sync.js';
import {createAccounts} from './src/accounts.js';
const trails=createTrails(),a='11111111-1111-4111-8111-111111111111',b='22222222-2222-4222-8222-222222222222';
const win={stage:'morro-1',won:true,roundsLost:0};
function storage(){const map=new Map();return {get length(){return map.size;},key:i=>[...map.keys()][i]??null,getItem:k=>map.get(k)??null,setItem:(k,v)=>map.set(k,String(v)),removeItem:k=>map.delete(k)};}
test('PostgreSQL trail progress isolates accounts, merges visitor saves once and serializes independent rewards',async()=>{
 const db=new PGlite();try{
  await db.exec("create role anon;create role authenticated;create role service_role;create role pipa_server;create schema auth;create table auth.users(id uuid primary key);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon;insert into auth.users values('"+a+"'),('"+b+"');");
  await db.exec(fs.readFileSync('supabase/migrations/009_trails_progress.sql','utf8'));
  const as=async id=>db.exec("reset role;set role authenticated;set request.jwt.claim.sub='"+id+"'");
  const call=async(action='read',id=null,payload={})=>(await db.query('select public.player_trails($1,$2,$3) p',[action,id,payload])).rows[0].p;
  await db.exec('set role anon');await assert.rejects(()=>call(),/permission denied/);
  await as(a);await assert.rejects(()=>db.query('select * from public.player_trails'),/permission denied/);
  await assert.rejects(()=>db.query("update public.trail_stages set coins=9999"),/permission denied/);
  let r=await call();assert.deepEqual(r.progress,trails.defaults());
  const importId=crypto.randomUUID(),legacy={...trails.defaults(),coins:100,stars:{'morro-1':2},wins:1,items:['rabiola-raio-de-sol','forged']};
  r=await call('import',importId,legacy);assert.equal(r.progress.coins,100);assert.deepEqual(r.progress.items,['rabiola-raio-de-sol']);
  assert.deepEqual(await call('import',importId,legacy),r);
  await assert.rejects(()=>call('import',importId,{...legacy,coins:999}),/outros dados/);
  const match=crypto.randomUUID();r=await call('result',match,win);assert.equal(r.progress.coins,115);assert.equal(r.progress.stars['morro-1'],3);
  assert.deepEqual(await call('result',match,win),r);
  await call('result',crypto.randomUUID(),win);r=await call();assert.equal(r.progress.coins,130);assert.equal(r.progress.wins,3);
  await assert.rejects(()=>call('result',crypto.randomUUID(),{...win,stage:'torres-5'}),/anterior/);
  await assert.rejects(()=>call('result',crypto.randomUUID(),{...win,roundsLost:2}),/rodadas/);
  await assert.rejects(()=>call('result',crypto.randomUUID(),{stage:'morro-1'}),/inválido/);
  // Every server award must match the shared rules, including first-clear and boss drops.
  let expected=r.progress;
  for(const stage of trails.stages){const payload={...win,stage:stage.id};expected=trails.settle(expected,stage.id,payload).progress;r=await call('result',crypto.randomUUID(),payload);assert.deepEqual({...r.progress,items:[...r.progress.items].sort()},{...expected,items:[...expected.items].sort()});}
  for(let i=0;i<3;i++){const payload={...win,won:false};expected=trails.settle(expected,'morro-1',payload).progress;r=await call('result',crypto.randomUUID(),payload);assert.deepEqual(r.progress,expected);}
  await as(b);assert.deepEqual((await call()).progress,trails.defaults());await assert.rejects(()=>call('import',importId,legacy),/outros dados/);
  const concurrent=await Promise.all([call('result',crypto.randomUUID(),win),call('result',crypto.randomUUID(),win)]);
  assert.deepEqual(concurrent.map(r=>r.progress.coins).sort((a,b)=>a-b),[25,40]);
  assert.equal((await call()).progress.wins,2);
  await db.exec('reset role');assert.equal((await db.query('select count(*) n from public.player_trails')).rows[0].n,2);
 }finally{await db.close();}
});

test('trails HTTP authenticates, rejects invalid requests and binds the RPC to the signed-in session',async()=>{
 const calls=[];
 const response=data=>new Response(JSON.stringify(data),{status:200});
 const api=createAccounts({SUPABASE_URL:'https://supabase.test',SUPABASE_ANON_KEY:'public'},{gameDatabase:{},fetcher:async(url,options)=>{
  if(url.endsWith('/auth/v1/user'))return response({id:a});
  calls.push({url,body:JSON.parse(options.body),authorization:options.headers.Authorization});
  return response({progress:trails.defaults(),revision:0});
 }});
 const request=(body,headers={})=>api.handle(new Request('https://game.test/account/trails',{method:'POST',headers:{'Content-Type':'application/json',...headers},body:JSON.stringify(body)}));
 assert.equal((await request({action:'read'})).status,401);
 const headers={cookie:'__Host-pipa_access=test-access'};
 assert.equal((await request({action:'result',operationId:crypto.randomUUID(),payload:{...win,won:'yes'}},headers)).status,400);
 assert.equal((await request({action:'import',operationId:'wrong',payload:{}},headers)).status,400);
 assert.equal((await request({action:'read'},{...headers,origin:'https://foreign.test'})).status,403);
 assert.equal(calls.length,0);
 const r=await request({action:'read',userId:b},headers);assert.equal(r.status,200);
 assert.equal(calls[0].authorization,'Bearer test-access');assert.deepEqual(calls[0].body,{p_action:'read',p_operation:null,p_payload:{}});
 assert.equal(r.headers.get('Cache-Control'),'no-store');
});

test('blocked storage never erases the guest save and can retry after storage is restored',async()=>{
 const disk=storage(),original=disk.setItem,guest={...trails.defaults(),coins:50};disk.setItem('pipaTrailsV1',JSON.stringify(guest));
 disk.setItem=()=>{throw Error('quota');};let imports=0;
 const sync=createTrailSync({trails,storage:disk,uuid:()=>crypto.randomUUID(),send:async body=>{if(body.action==='import')imports++;return {progress:body.action==='import'?guest:trails.defaults(),revision:imports};}});
 await sync.setUser(a);assert.equal(JSON.parse(disk.getItem('pipaTrailsV1')).coins,50);assert.equal(imports,0);
 disk.setItem=original;await sync.retry();assert.equal(imports,1);assert.equal(sync.progress().coins,50);assert.equal(JSON.parse(disk.getItem('pipaTrailsV1')).coins,0);
});

test('lost responses replay the same operation after reload; guest import and account switching never duplicate coins',async()=>{
 const disk=storage(),server=new Map(),seen=new Map();let owner=a,lose=false;
 disk.setItem('pipaTrailsV1',JSON.stringify({...trails.defaults(),coins:20,stars:{'morro-1':1}}));
 const send=async body=>{
  let p=server.get(owner)||trails.defaults(),key=owner+':'+body.operationId;
  if(body.action!=='read'&&!seen.has(key)){p=body.action==='import'?{...p,coins:p.coins+body.payload.coins,stars:body.payload.stars}:trails.settle(p,body.payload.stage,body.payload).progress;server.set(owner,p);seen.set(key,true);}
  if(lose&&body.action!=='read'){lose=false;throw Error('response lost');}
  return {progress:p,revision:seen.size};
 };
 const make=()=>createTrailSync({trails,storage:disk,send,uuid:()=>crypto.randomUUID()});
 let sync=make();await sync.setUser(a);assert.equal(sync.progress().coins,20);assert.equal(JSON.parse(disk.getItem('pipaTrailsV1')).coins,0);
 lose=true;const id=crypto.randomUUID();sync.record(win,id);await new Promise(r=>setImmediate(r));assert.equal(sync.pending(a).length,1);assert.equal(server.get(a).coins,35);
 sync=make();await sync.setUser(a);assert.equal(sync.progress().coins,35);assert.equal(sync.pending(a).length,0);
 await sync.setUser(null);assert.equal(sync.progress().coins,0);owner=b;await sync.setUser(b);assert.equal(sync.progress().coins,0);
 owner=a;await sync.setUser(a);assert.equal(sync.progress().coins,35);
});

test('late account responses cannot replace a different account; two tabs keep independent pending results',async()=>{
 const disk=storage();let release;const delayed=new Promise(r=>release=r);let calls=0;
 const sync=createTrailSync({trails,storage:disk,uuid:()=>crypto.randomUUID(),send:async()=>{calls++;return delayed;}});
 const first=sync.setUser(a);await new Promise(r=>setImmediate(r));await sync.setUser(null);
 release({progress:{...trails.defaults(),coins:900},revision:1});await first;assert.equal(sync.progress().coins,0);
 let offline=async()=>{throw Error('offline');};
 const one=createTrailSync({trails,storage:disk,uuid:()=>crypto.randomUUID(),send:offline});
 const two=createTrailSync({trails,storage:disk,uuid:()=>crypto.randomUUID(),send:offline});
 await one.setUser(a);await two.setUser(a);one.record(win,crypto.randomUUID());two.record(win,crypto.randomUUID());
 assert.equal(one.pending(a).length,2);assert.equal(two.pending(a).length,2);assert.equal(one.progress().coins,40);
});
