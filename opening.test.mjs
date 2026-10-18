import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {PGlite} from '@electric-sql/pglite';
import {KAEL_OPENING} from './src/opening-story.js';
import {createAssetHandler} from './src/static-assets.js';
import vm from 'node:vm';
import {parseHTML} from 'linkedom';

function openingUI(){
 const html=fs.readFileSync('docs/index.html','utf8'),{document}=parseHTML(html);
 Object.getPrototypeOf(document.createElement('canvas')).getContext=()=>new Proxy({imageSmoothingEnabled:true},{get:(o,k)=>o[k]||(()=>{}),set:(o,k,v)=>(o[k]=v,true)});
 for(const select of document.querySelectorAll('select')){let value;Object.defineProperty(select,'value',{get(){return value??this.querySelector('option')?.value??''},set(v){value=v}});}
 const context=vm.createContext({document,console,Date,Intl,crypto,URLSearchParams,AbortController,performance:{now:()=>0},location:{search:'',hash:'',pathname:'/',protocol:'http:',host:'test'},history:{replaceState(){}},localStorage:{getItem(){return null},setItem(){}},matchMedia:()=>({matches:true}),ResizeObserver:class{observe(){}},MutationObserver:class{observe(){}},requestAnimationFrame(){return 1},cancelAnimationFrame(){},setInterval(){},clearInterval(){},setTimeout(){return 1},clearTimeout(){},fetch:async()=>({ok:true,json:async()=>({enabled:false})}),Image:class{set src(v){queueMicrotask(()=>this.onload?.())}},addEventListener(){}});
 vm.runInContext(html.match(/<script>([\s\S]*?)<\/script>/)[1],context);
 return {document,run:s=>vm.runInContext(s,context),settle:()=>new Promise(r=>setImmediate(r))};
}

test('naming failure stays in the opening, retries once, and stale-account responses cannot grant or open a scene',async()=>{
 const ui=openingUI();await ui.settle();
 await ui.run(`accountRequest=async(action)=>action==='opening'?{opening:{step:10,tail_state:'attached'}}:{journey:{phase:'arrival',lesson:0}};playerAccount={profile:{id:'a',nickname:'Nova',equipped_kite_id:'basic'},inventory:[{id:'basic',model_id:'basica',model:{color:0,name:'Carcará'}}]};onCourtyardAccount()`);await ui.settle();
 assert.equal(ui.document.getElementById('kaelOpening').hidden,false);assert.equal(ui.document.getElementById('openingName').getAttribute('placeholder'),'Rabbito');
 ui.run(`accountRequest=async()=>{throw Error('Sem conexão')}`);await ui.document.getElementById('openingNameForm').onsubmit({preventDefault(){}});
 assert.equal(ui.run('openingState.step'),10);assert.equal(ui.run('playerAccount.inventory.length'),1);assert.equal(ui.run('openingBusy'),false);assert.equal(ui.document.getElementById('openingStatus').textContent,'Sem conexão');
 ui.run(`var resolveName;accountRequest=async(action,body)=>{if(action==='opening'&&body.action==='name')return new Promise(r=>resolveName=r);if(action==='opening')return {opening:{step:14,legacy:true}};return {journey:{phase:'complete',lesson:5}}};var oldName=$('openingNameForm').onsubmit({preventDefault(){}});`);
 assert.equal(ui.run('openingBusy'),true);
 await ui.run(`playerAccount={profile:{id:'b',nickname:'Outra',equipped_kite_id:null},inventory:[]};onCourtyardAccount()`);await ui.settle();
 ui.run(`resolveName({opening:{step:11,partner_name:'Antigo'},account:{profile:{id:'a'},inventory:[{id:'extra'}]}})`);await ui.run('oldName');
 assert.equal(ui.run('playerAccount.profile.id'),'b');assert.equal(ui.run('playerAccount.inventory.length'),0);assert.equal(ui.document.getElementById('kaelOpening').hidden,true);
});

test('legacy replay names a local partner and leaves both saved checkpoint and inventory untouched',async()=>{
 const ui=openingUI();await ui.settle();await ui.run(`var openingCalls=0;accountRequest=async(action)=>{if(action==='opening'){openingCalls++;return {opening:{step:14,legacy:true}};}return {journey:{phase:'complete',lesson:5}}};playerAccount={profile:{id:'legacy',nickname:'Antiga',equipped_kite_id:null},inventory:[]};onCourtyardAccount()`);await ui.settle();
 await ui.run('showOpening(true)');for(let i=0;i<10;i++)await ui.run('nextOpening()');
 ui.document.getElementById('openingName').value='<Lua>';await ui.document.getElementById('openingNameForm').onsubmit({preventDefault(){}});assert.equal(ui.run('openingState.partner_name'),'<Lua>');assert.equal(ui.run('openingState.step'),11);
 assert.equal(ui.run('openingCalls'),1,'replay performs no economy writes');assert.equal(ui.run('playerAccount.inventory.length'),0);assert.match(ui.document.getElementById('openingSpeech').textContent,/<Lua>/);assert.equal(ui.document.getElementById('openingSpeech').children.length,0,'custom name uses text, never HTML');
 await ui.document.getElementById('openingPause').onclick();assert.equal(ui.run('openingState.step'),14);assert.equal(ui.document.getElementById('kaelOpening').hidden,true);
});

test('every film shot renders with reduced motion and measured actor feet stay on the configured room floor',async()=>{
 const ui=openingUI();await ui.settle();await ui.run(`playerAccount={profile:{id:'film',nickname:'Kael'},inventory:[]};openingOwner='film';openingState={step:0};showOpening(false)`);await ui.settle();
 for(let step=0;step<14;step++){ui.run('openingState.step='+step+';renderOpening();drawOpening(1500)');assert.equal(ui.document.getElementById('openingSpeaker').textContent,KAEL_OPENING[step].speaker);}
 const config=JSON.parse(fs.readFileSync('assets/story/kael-birthday-v1/manifest.json','utf8'));
 for(const room of Object.values(config.rooms))for(const point of Object.values(room.blocking))assert.ok(room.walkable.some(([x,y,w,h])=>point[0]>=x&&point[0]<=x+w&&point[1]>=y&&point[1]<=y+h));
});

test('birthday opening checkpoints and the account-bound partner are atomic, isolated and idempotent',async()=>{
 const db=new PGlite(),old='11111111-1111-4111-8111-111111111111',a='22222222-2222-4222-8222-222222222222',b='33333333-3333-4333-8333-333333333333';
 try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;grant execute on function auth.uid() to authenticated,anon,service_role;");
  for(const f of fs.readdirSync('supabase/migrations').filter(f=>f.endsWith('.sql')).sort()){if(f.startsWith('017'))await db.query('insert into auth.users values($1,$2)',[old,{nickname:'Antiga'}]);await db.exec(fs.readFileSync('supabase/migrations/'+f,'utf8'));}
  const auth=async id=>db.exec("reset role;set role authenticated;set request.jwt.claim.sub='"+(id||'')+"'");
  const call=async(action='read',step=null,name=null)=>(await db.query('select public.player_opening($1,$2,$3) r',[action,step,name])).rows[0].r;
  await auth(old);assert.equal((await call()).legacy,true);await assert.rejects(()=>call('name',10,'Extra'),/rever/);await assert.rejects(()=>db.query('select * from public.player_openings'),/permission denied/);
  await db.exec('reset role');for(const id of [a,b])await db.query('insert into auth.users values($1,$2)',[id,{nickname:'Nova'}]);
  await auth(null);await assert.rejects(()=>call(),/conta/);await auth(a);
  assert.equal((await call()).step,0);await assert.rejects(()=>call('name',10,'Muito cedo'),/nascimento/);await assert.rejects(()=>call('advance',6),/cena mudou/);
  for(let i=0;i<7;i++)await call('advance',i);assert.equal((await call()).tail_state,'held');await call('advance',7);await call('advance',8);assert.equal((await call()).tail_state,'attached');await call('advance',9);
  await assert.rejects(()=>call('advance',10),/nome/);await assert.rejects(()=>call('name',10,'x'.repeat(25)),/24/);await assert.rejects(()=>call('name',10,'a\nb'),/quebras/);
  await db.exec('reset role');await db.query("update public.player_profiles set active_match=gen_random_uuid(),active_until=now()+interval '5 minutes' where id=$1",[a]);await auth(a);await assert.rejects(()=>call('name',10,'Nuvem'),/partida/);assert.equal((await call()).step,10);
  await db.exec('reset role');await db.query('update public.player_profiles set active_match=null,active_until=null where id=$1',[a]);await auth(a);
  const result=await Promise.all([call('name',10,'Nuvem'),call('name',10,'Outro')]);assert.equal(result[0].partner_id,result[1].partner_id);assert.equal(result[1].partner_name,'Nuvem');assert.equal(result[1].step,11);
  for(let i=11;i<14;i++)await call('advance',i);assert.equal((await call()).step,14);await call('name',10,'Rabbito');assert.equal((await call()).partner_name,'Nuvem');
  await auth(b);assert.equal((await call()).step,0);assert.equal((await call()).partner_id,null);
  await db.exec('reset role');const items=(await db.query("select * from public.player_kites where owner_id=$1 and model_id='rabbito'",[a])).rows;assert.equal(items.length,1);assert.equal(items[0].permanent,true);assert.equal(items[0].personal_name,'Nuvem');
  const journey=(await db.query('select * from public.player_journeys where owner_id=$1',[a])).rows[0];assert.equal(journey.phase,'practice');assert.equal(journey.starter_model,'rabbito');assert.equal((await db.query('select equipped_kite_id,xp from public.player_profiles where id=$1',[a])).rows[0].equipped_kite_id,items[0].id);
  assert.equal((await db.query('select count(*)::int n from public.summon_recipes where target_model_id=$1',['rabbito'])).rows[0].n,0);
 }finally{await db.close();}
});

test('opening keeps the requested story beats and publishes measured, separately layered assets',async()=>{
 assert.equal(KAEL_OPENING.length,14);const text=KAEL_OPENING.map(s=>s.text).join(' ');for(const word of ['Jamile','Gollia','Quinze anos','Rabiola Antiga','minha cabeça'])assert.ok(text.includes(word));assert.equal(KAEL_OPENING[10].shot,'name');
 const m=JSON.parse(fs.readFileSync('assets/story/kael-birthday-v1/manifest.json','utf8')),serve=createAssetHandler();
 for(const def of Object.values(m.images)){const response=await serve(new Request('http://test/assets/'+def.image));assert.equal(response.status,200,def.image);assert.equal(response.headers.get('content-type'),'image/png');const buffer=Buffer.from(await response.arrayBuffer());if(def.width)assert.equal(buffer.readUInt32BE(16),def.width);if(def.height)assert.equal(buffer.readUInt32BE(20),def.height);}
 for(const a of Object.values(m.actors))for(const f of a.frames){assert.ok(f.x+f.w<=a.width&&f.y+f.h<=a.height);assert.ok(f.bounds.w>0&&f.bounds.h>0);}
 assert.equal(m.images.bedroom.alpha,false);assert.equal(m.images.mother.alpha,true);assert.equal(m.rooms.downstairs.exit.target,'quintal');
});
