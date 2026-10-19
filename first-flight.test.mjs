import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {PGlite} from '@electric-sql/pglite';
import {createEngine} from './src/engine.js';
import {createFirstFlight} from './src/first-flight.js';
import {createAccounts} from './src/accounts.js';
import {createAssetHandler} from './src/static-assets.js';
import vm from 'node:vm';
import {parseHTML} from 'linkedom';

function journeyUI(){
 const html=fs.readFileSync('docs/index.html','utf8'),{document}=parseHTML(html),listeners=new Map();
 const canvasPrototype=Object.getPrototypeOf(document.createElement('canvas'));
 canvasPrototype.getContext=()=>new Proxy({imageSmoothingEnabled:true},{get:(o,k)=>k in o?o[k]:()=>{},set:(o,k,v)=>(o[k]=v,true)});
 for(const select of document.querySelectorAll('select')){let value;Object.defineProperty(select,'value',{get(){return value??this.querySelector('option')?.value??''},set(v){value=v}})}
 const context=vm.createContext({document,console,Date,Intl,crypto,URLSearchParams,AbortController,performance:{now:()=>0},location:{search:'',hash:'',pathname:'/',protocol:'http:',host:'test'},history:{replaceState(){}},localStorage:{getItem(){return null},setItem(){}},matchMedia:()=>({matches:true}),ResizeObserver:class{observe(){}},MutationObserver:class{observe(){}},requestAnimationFrame(){},cancelAnimationFrame(){},setInterval(){},clearInterval(){},setTimeout(){return 1},clearTimeout(){},fetch:async()=>({ok:true,json:async()=>({enabled:false})}),Image:class{width=1536;height=864;set src(v){queueMicrotask(()=>this.onload?.())}},addEventListener(name,fn){if(!listeners.has(name))listeners.set(name,[]);listeners.get(name).push(fn)}});
 vm.runInContext(html.match(/<script>([\s\S]*?)<\/script>/)[1],context);
 return {document,run:code=>vm.runInContext(code,context),settle:()=>new Promise(r=>setImmediate(r))};
}

test('late journey responses cannot open or overwrite another account, and the saved practice checkpoint resumes',async()=>{
 const ui=journeyUI();await ui.settle();
 ui.run(`var resolveOld;accountRequest=async(action,body)=>{if(action==='journey'&&playerAccount.profile.id==='old')return new Promise(r=>resolveOld=r);if(action==='journey')return {journey:{phase:'practice',lesson:3,starter_model:'mata'}};return {}};playerAccount={profile:{id:'old',nickname:'Antiga',equipped_kite_id:'k1'},inventory:[{id:'k1',model_id:'basica',model:{color:0,name:'Carcará'}}]};var oldLoad=onCourtyardAccount();`);
 await ui.run(`playerAccount={profile:{id:'new',nickname:'Nova',equipped_kite_id:'k2'},inventory:[{id:'k2',model_id:'mata',model:{color:1,name:'Mata verde'}}]};onCourtyardAccount()`);await ui.settle();
 ui.run(`resolveOld({journey:{phase:'arrival',lesson:0}})`);await ui.run('oldLoad');await ui.settle();
 assert.equal(ui.run('journeyOwner'),'new');assert.equal(ui.run('journey.phase'),'practice');assert.equal(ui.run('journey.lesson'),3);assert.equal(ui.document.getElementById('journeyTitle').textContent,'Vamos voar juntos?');
 ui.run('startFirstFlight()');assert.equal(ui.run('firstFlightRun.index'),3);assert.equal(ui.run('firstFlightRun.state.players[0].color'),1);ui.run('leave()');assert.equal(ui.run('mode'),null);assert.equal(ui.document.getElementById('courtyard').hidden,false);
 ui.run('playerAccount=null;onCourtyardAccount()');assert.equal(ui.run('journey'),null);assert.equal(ui.document.getElementById('courtyard').hidden,true);
});

test('failed starter save keeps the choice screen open and does not start a practice or alter the account',async()=>{
 const ui=journeyUI();await ui.settle();await ui.run(`accountRequest=async()=>({journey:{phase:'choose',lesson:0}});playerAccount={profile:{id:'new',nickname:'Nova',equipped_kite_id:'k1'},inventory:[{id:'k1',model_id:'basica',model:{color:0,name:'Carcará'}}]};onCourtyardAccount()`);await ui.settle();
 assert.equal(ui.document.getElementById('partnerChoice').hidden,false);
 ui.run(`accountRequest=async()=>{throw Error('Sem conexão')}`);await ui.document.getElementById('partnerConfirm').onclick();
 assert.equal(ui.run('mode'),null);assert.equal(ui.run('firstFlightRun'),null);assert.equal(ui.run('playerAccount.profile.equipped_kite_id'),'k1');assert.equal(ui.document.getElementById('partnerChoice').hidden,false);assert.equal(ui.document.getElementById('partnerStatus').textContent,'Sem conexão');
});

test('city navigation respects unlocks, enters Morro exploration and preserves other district briefings',async()=>{
 const ui=journeyUI();await ui.settle();await ui.run(`accountRequest=async()=>({journey:{phase:'complete',lesson:5}});playerAccount={profile:{id:'city-player',nickname:'Nova',equipped_kite_id:'k1'},inventory:[{id:'k1',model_id:'basica',model:{color:0,name:'Carcará'}}]};onCourtyardAccount()`);await ui.settle();
 await ui.run('openCity()');assert.equal(ui.document.getElementById('cityScreen').hidden,false);
 ui.run('selectCity(1)');assert.equal(ui.document.getElementById('cityExplore').disabled,true);assert.equal(ui.document.querySelector('[data-district="1"]').classList.contains('locked'),true);
 ui.run('selectCity(3)');assert.equal(ui.document.getElementById('cityExplore').hidden,true);
 ui.run('selectCity(0)');assert.equal(ui.document.getElementById('cityExplore').disabled,false);ui.document.getElementById('cityExplore').onclick();assert.equal(ui.document.getElementById('trails').hidden,true);assert.equal(ui.document.getElementById('cityScreen').hidden,true);assert.equal(ui.run('worldRuntime.id'),'morro');
 ui.run('openWorld("quintal");openCity();selectCity(1)');assert.equal(ui.document.getElementById('cityExplore').disabled,true);assert.equal(ui.document.getElementById('trails').hidden,true);
 ui.run('openHomeMenu();renderHomeMenu("playGroup")');assert.ok(ui.document.getElementById('homeMenuLinks').children.length<=6);
});

test('exploration cannot unlock encounters, preserves position after battle and clears another account',async()=>{
 const ui=journeyUI();await ui.settle();await ui.run(`accountRequest=async()=>({journey:{phase:'complete'}});playerAccount={profile:{id:'world-a',nickname:'Ana'},inventory:[]};onCourtyardAccount()`);await ui.settle();
 ui.run(`openWorld('morro');worldGo(worldScene().places.find(p=>p.stage==='morro-5'));for(let i=0;i<3000&&worldState().actor.path.length;i++)worldState().navigation.step(worldState().actor,.1);worldRuntime.loading=false;updateWorldContext();interactWorld()`);
 assert.equal(ui.run('mode'),null);assert.notEqual(ui.document.getElementById('modal').style.display,'flex');assert.equal(ui.run('trailProgress.stars["morro-5"]||0'),0);
 ui.run(`worldGo(worldScene().places.find(p=>p.stage==='morro-1'));for(let i=0;i<3000&&worldState().actor.path.length;i++)worldState().navigation.step(worldState().actor,.1);worldRuntime.loading=false;updateWorldContext();interactWorld()`);
 assert.equal(ui.document.getElementById('modal').classList.contains('encounter-preview'),true);assert.equal(ui.run('mode'),null);assert.equal(ui.run('modalReturnFocus.id'),'worldInteract');
 ui.run(`closeModal();var lastWorldPosition={x:worldState().actor.x,y:worldState().actor.y};returnToDistrict('morro-1',false)`);
 assert.equal(ui.run('worldRuntime.id'),'morro');assert.equal(ui.run('worldState().actor.x'),ui.run('lastWorldPosition.x'));assert.equal(ui.document.getElementById('trails').hidden,true);
 await ui.run(`playerAccount={profile:{id:'world-b',nickname:'Bia'},inventory:[]};onCourtyardAccount()`);await ui.settle();assert.equal(ui.run('worldRuntime.id'),'quintal');assert.equal(ui.run('worldRuntime.owner'),'world-b');assert.equal(ui.run('worldState().actor.path.length'),0);
 ui.run(`worldArtLoaded('quintal',false)`);assert.match(ui.document.getElementById('worldPlace').textContent,/não carregou/);assert.equal(ui.document.getElementById('worldInteract').disabled,false);
 await ui.run(`homeLoadImage=async()=>true;loadWorldImage('quintal',true)`);assert.equal(ui.run('worldRuntime.error'),'');assert.equal(ui.run('worldRuntime.loading'),false);
});

test('a scene destination opens its own screen before background account refresh completes',async()=>{
 const ui=journeyUI();await ui.settle();await ui.run(`accountRequest=async()=>({journey:{phase:'complete',lesson:5}});playerAccount={profile:{id:'screen-player',nickname:'Nova',level:1,xp:0,next_level_xp:100,cuts:0,equipped_kite_id:'k1'},inventory:[{id:'k1',model_id:'basica',permanent:true,model:{color:0,name:'Carcará'}}]};onCourtyardAccount()`);await ui.settle();
 ui.run(`var resolveRefresh;accountsEnabled=true;accountRequest=async(action)=>action==='session'?new Promise(r=>resolveRefresh=r):{matches:[]};var destinationOpen=openClubDestination('collection');`);
 assert.equal(ui.run('accountPage'),'collection');assert.equal(ui.document.getElementById('clubHome').hidden,true);assert.equal(ui.document.getElementById('club-collection').hidden,false);
 ui.run('resolveRefresh({account:playerAccount})');await ui.run('destinationOpen');
});

test('first flight observes real movement, hit, energy, skill and a cut, for all four partners',()=>{
 for(let color=0;color<4;color++){
  const engine=createEngine(),flight=createFirstFlight(engine),run=flight.create({color},1000);let now=1000;
  assert.equal(run.state.players[1].soul,'nozinho');assert.equal(run.state.players.length,2);
  for(let index=0;index<5;index++){
   assert.equal(run.index,index);assert.equal(flight.next(run),false,'cannot skip an unobserved exercise');
   for(let frame=0;frame<2400&&!run.complete;frame++){
    const p=run.state.players[0],dx=run.target.x-p.x,dy=run.target.y-p.y,d=Math.hypot(dx,dy);
    flight.tick(run,{x:d>5?dx/d:0,y:d>5?dy/d:0,cut:index===1||index===4,skill:index===3?1:0,dodge:false},now+=1000/60);
   }
   assert.equal(run.complete,true,'partner '+color+', lesson '+index);
   if(index===0)assert.equal(run.state.players[0].hits||0,0,'movement alone has no hit');
   if(index===4)assert.ok(run.state.players[0].score>0,'a real engine cut concludes the exercise');
   if(index<4)assert.equal(flight.next(run),true);
  }
  assert.equal(run.state.trail,undefined);assert.equal(run.state.daily,undefined);
 }
});

test('first flight can resume any checkpoint and cannot complete attacking lessons by waiting',()=>{
 const flight=createFirstFlight(createEngine());
 for(const lesson of [1,3,4]){const run=flight.create({lesson},1000);for(let i=1;i<300;i++)flight.tick(run,{x:0,y:0,cut:false,skill:0},1000+i*16);assert.equal(run.complete,false);assert.equal(run.index,lesson);}
 const run=flight.create({lesson:2},1000);assert.equal(run.state.players[0].energy,25);
});

test('journey migration preserves old accounts; starter choice is protected, atomic and idempotent without extra rewards',async()=>{
 const db=new PGlite(),a='11111111-1111-4111-8111-111111111111',b='22222222-2222-4222-8222-222222222222',match='33333333-3333-4333-8333-333333333333';
 try{
  await db.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;grant execute on function auth.uid() to authenticated,anon,service_role;");
  for(const f of fs.readdirSync('supabase/migrations').filter(f=>f.endsWith('.sql')).sort()){
   if(f.startsWith('015'))await db.query('insert into auth.users values($1,$2)',[a,{nickname:'Antiga'}]);
   if(f.startsWith('018'))await db.query('insert into auth.users values($1,$2) on conflict do nothing',[b,{nickname:'Nova'}]);
   await db.exec(fs.readFileSync('supabase/migrations/'+f,'utf8'));
  }
  const old=(await db.query('select equipped_kite_id,xp from public.player_profiles where id=$1',[a])).rows[0];
  const auth=async id=>db.exec("reset role;set role authenticated;set request.jwt.claim.sub='"+id+"'");
  const journey=async(action='read',model=null,lesson=null)=>(await db.query('select public.player_journey($1,$2,$3) r',[action,model,lesson])).rows[0].r;
  await auth(a);assert.equal((await journey()).phase,'complete');await assert.rejects(()=>journey('choose','raio'),/professor/);await assert.rejects(()=>db.query('select * from public.player_journeys'),/permission denied/);
  await db.exec('reset role');assert.deepEqual((await db.query('select equipped_kite_id,xp from public.player_profiles where id=$1',[a])).rows[0],old);await db.query('insert into auth.users values($1,$2) on conflict do nothing',[b,{nickname:'Nova'}]);
  await auth(b);assert.equal((await journey()).phase,'arrival');await assert.rejects(()=>journey('skip'),/escolha/i);await journey('welcome');await journey('welcome');await assert.rejects(()=>journey('choose','javali-biscoito'),/inválido/);
  await db.exec('reset role;set role pipa_server');await db.query("select public.reserve_player_match($1,$2,'ABCDEF','casual')",[b,match]);await auth(b);await assert.rejects(()=>journey('choose','azulao'),/Saia da partida/);
  await db.exec('reset role;set role pipa_server');await db.query('select public.release_player_match($1,$2)',[b,match]);await auth(b);
  const result=await Promise.allSettled([journey('choose','azulao'),journey('choose','raio')]);assert.equal(result.filter(r=>r.status==='fulfilled').length,1);assert.equal((await journey()).starter_model,'azulao');await journey('choose','azulao');
  await assert.rejects(()=>journey('advance',null,5),/anterior/);for(let i=1;i<=5;i++)await journey('advance',null,i);assert.equal((await journey()).phase,'city');await journey('finish');await journey('advance',null,1);assert.equal((await journey()).phase,'complete');
  await db.exec('reset role');const items=(await db.query('select model_id,permanent from public.player_kites where owner_id=$1',[b])).rows;assert.equal(items.length,4,'reuse the signup inventory instead of creating another item');assert.equal(items.filter(k=>k.model_id==='azulao'&&k.permanent).length,1);assert.equal((await db.query('select xp from public.player_profiles where id=$1',[b])).rows[0].xp,0);assert.equal((await db.query('select count(*)::int n from public.trail_drop_claims where owner_id=$1',[b])).rows[0].n,0);
  await db.exec('set role anon');await assert.rejects(()=>journey(),/permission denied/);
 }finally{await db.close()}
});

test('journey endpoint requires auth and rejects forged models or checkpoints before calling SQL',async()=>{
 const calls=[],accounts=createAccounts({SUPABASE_URL:'https://test.invalid',SUPABASE_PUBLISHABLE_KEY:'test'},{gameDatabase:{rpc(){}},fetcher:async(url,opts)=>{calls.push(url);if(url.endsWith('/auth/v1/user'))return new Response(JSON.stringify({id:'11111111-1111-4111-8111-111111111111'}));return new Response(JSON.stringify({phase:'arrival',lesson:0}));}});
 const request=body=>new Request('http://localhost/account/journey',{method:'POST',headers:{'Content-Type':'application/json',Cookie:'pipa_access=local'},body:JSON.stringify(body)});
 assert.equal((await accounts.handle(new Request('http://localhost/account/journey',{method:'POST',headers:{'Content-Type':'application/json'},body:'{"action":"read"}'}))).status,401);
 assert.equal((await accounts.handle(request({action:'choose',modelId:'flautrevo'}))).status,400);assert.equal((await accounts.handle(request({action:'advance',lesson:99}))).status,400);assert.equal(calls.some(url=>url.includes('/rpc/')),false);
 assert.equal((await accounts.handle(request({action:'read'}))).status,200);assert.ok(calls.some(url=>url.endsWith('/rpc/player_journey')));
});

test('courtyard assets are served by the allowlist with PNG types; other pack data stays private to builds',async()=>{
 const serve=createAssetHandler();for(const p of ['backgrounds/quintal-clube-v1.png','packs/cidade-v1/mapa.png','packs/cidade-v1/insignias.png']){const response=await serve(new Request('http://localhost/assets/'+p));assert.equal(response.status,200);assert.equal(response.headers.get('Content-Type'),'image/png');}
 assert.equal((await serve(new Request('http://localhost/assets/packs/cidade-v1/PROMPTS.json'))).status,404);
});


test('click-to-walk progresses with ambient motion paused and reduced, with genuine directional sprite frames',async()=>{
 const ui=journeyUI();await ui.settle();
 ui.run(`playerAccount={profile:{id:'walker',nickname:'Walker'},inventory:[]};journey={phase:'complete'};journeyOwner='walker';showCourtyard();refreshWorldHUD();homeMotionPaused=true;var walkingState=worldState(),walkingStart={x:walkingState.actor.x,y:walkingState.actor.y};worldGo(worldScene().places[0]);`);
 assert.equal(ui.run('art.reduced'),true);assert.equal(ui.run('homeMotionPaused'),true);
 assert.equal(ui.run('walkingState.actor.x===walkingStart.x&&walkingState.actor.y===walkingStart.y'),true,'input must queue a route, never teleport');
 ui.run(`drawWorldScene($('courtyardCanvas').getContext('2d'),100,.1)`);
 assert.equal(ui.run('walkingState.actor.moving'),true);assert.ok(ui.run('walkingState.navigation.distance(walkingStart,walkingState.actor)>0'));
 const poses=ui.run(`(()=>{const frames=[];homeImages.set('plaza-kael',{});const g={fillStyle:'',beginPath(){},ellipse(){},fill(){},drawImage(...args){frames.push(args.slice(1,5))}};drawWorldHuman(g,walkingState.actor,0);drawWorldHuman(g,walkingState.actor,180);return frames;})()`);
 assert.notDeepEqual([...poses[0]],[...poses[1]],'manual walking advances the existing spritesheet even with ambient motion paused');
 for(let i=0;i<200;i++)ui.run(`drawWorldScene($('courtyardCanvas').getContext('2d'),1000,.1)`);
 assert.equal(ui.run('walkingState.actor.path.length'),0);assert.equal(ui.run('worldRuntime.near.id===worldScene().places[0].id'),true);
});


test('world objectives identify the nearby rival, completion and hide the champion before unlock',async()=>{
 const ui=journeyUI();await ui.settle();await ui.run(`accountRequest=async()=>({journey:{phase:'complete'}});playerAccount={profile:{id:'mission-test',nickname:'Ana'},inventory:[]};onCourtyardAccount()`);await ui.settle();
 ui.run(`openWorld('morro');worldGo(worldScene().places.find(p=>p.stage==='morro-1'));for(let i=0;i<1000&&worldState().actor.path.length;i++)worldState().navigation.step(worldState().actor,.1);updateWorldContext()`);
 assert.match(ui.document.getElementById('homeObjective').textContent,/Converse com Zeca/);
 ui.run(`var rivalNames=[];homeImages.set('rival-Zeca',{});var rivalContext={fillStyle:'',beginPath(){},ellipse(){},fill(){},drawImage(){},strokeText(){},fillText(name){rivalNames.push(name)}};drawWorldRival(rivalContext,worldScene().places.find(p=>p.stage==='morro-1'),0);drawWorldRival(rivalContext,worldScene().places.find(p=>p.stage==='morro-5'),0);`);
 assert.equal(ui.run('rivalNames.join()'),'Zeca');
 ui.run(`for(const stage of trails.stages)trailProgress.stars[stage.id]=1;updateWorldContext()`);assert.match(ui.document.getElementById('homeObjective').textContent,/venceu os três bairros/);assert.equal(ui.document.getElementById('plazaMissionTitle').textContent,'Jornada concluída');
});
