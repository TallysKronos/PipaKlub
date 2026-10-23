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

test('autosave shows pending confirmation, preserves bank drafts and skips disabled or loading scenes',async()=>{
 const ui=journeyUI();await ui.settle();
 ui.run("playerAccount={profile:{id:'autosaver',nickname:'Kael'},inventory:[]};journey={phase:'complete'};journeyOwner='autosaver';openingState={step:14};showCourtyard();refreshWorldHUD();");await ui.run('loadWorldImage(worldRuntime.id)');
 ui.run("campaignData={revision:3,autosave_enabled:true};campaignKeep=new Set(['draft']);var autoCalls=[];var resolveAuto;accountRequest=(endpoint,body)=>{autoCalls.push(body);return new Promise(resolve=>resolveAuto=resolve);};var autoPending=campaignAutosave();");
 assert.equal(ui.run('autosaveIndicator.hidden'),false);assert.match(ui.run('autosaveIndicator.textContent'),/Salvando/);assert.equal(ui.run('autoCalls[0].action'),'autosave');
 ui.run("resolveAuto({campaign:{revision:4,autosave_enabled:true,autosave_checkpoint:autoCalls[0].checkpoint}})");await ui.run('autoPending');
 assert.match(ui.run('autosaveIndicator.textContent'),/Salvo.*slot 0/);assert.equal(ui.run("campaignKeep.has('draft')"),true);
 ui.run("autosaveLast='';campaignData.autosave_enabled=false;");await ui.run('campaignAutosave()');assert.equal(ui.run('autoCalls.length'),1);
 ui.run("campaignData.autosave_enabled=true;var heldGate=gameLoading.start('test','Carregando');");await ui.run('campaignAutosave()');assert.equal(ui.run('autoCalls.length'),1);ui.run('heldGate.cancel()');
});

test('scene loading blocks movement until essential art resolves and exposes a recoverable failure',async()=>{
 const ui=journeyUI();await ui.settle();
 ui.run("playerAccount={profile:{id:'loading-player',nickname:'Kael'},inventory:[]};journey={phase:'complete'};journeyOwner='loading-player';openingState={step:14};showCourtyard();refreshWorldHUD();var originalHomeLoad=homeLoadImage;var releaseArt;var heldArt=new Promise(resolve=>{releaseArt=resolve;});homeLoadImage=()=>heldArt;var pendingScene=loadWorldImage(worldRuntime.id);");
 assert.equal(ui.run('gameLoading.active'),true);assert.equal(ui.run('worldWalkActive()'),false);
 ui.run('releaseArt(false)');await ui.run('pendingScene');
 assert.equal(ui.run('loadingView.failed'),true);assert.equal(ui.run("typeof loadingView.retry==='function'&&typeof loadingView.back==='function'"),true);
 ui.run('homeLoadImage=originalHomeLoad');await ui.run('loadingView.retry()');
 assert.equal(ui.run('gameLoading.active'),false);assert.equal(ui.run('worldWalkActive()'),true);
});

test('walking enters doors automatically, latches the return portal and pauses under menus',async()=>{
 const ui=journeyUI();await ui.settle();
 ui.run("playerAccount={profile:{id:'doors',nickname:'Kael'},inventory:[]};journey={phase:'complete'};journeyOwner='doors';openingState={step:14};showCourtyard();refreshWorldHUD();");
 await ui.run('loadWorldImage(worldRuntime.id)');
 ui.run("var door=worldScene().places.find(p=>p.target==='kael-home'),point=worldState().navigation.nodes[door.node];worldState().navigation.target(worldState().actor,{x:point.x,y:point.y+40},true);worldKeys.add('arrowup');worldKeys.add('arrowright');drawWorldScene($('courtyardCanvas').getContext('2d'),100,.1);drawWorldScene($('courtyardCanvas').getContext('2d'),200,.1);");
 assert.equal(ui.run('worldRuntime.id'),'kael-home');await ui.run('loadWorldImage(worldRuntime.id)');
 ui.run("worldKeys.add('arrowdown');worldKeys.add('arrowleft');drawWorldScene($('courtyardCanvas').getContext('2d'),300,.1);");
 assert.equal(ui.run('worldRuntime.id'),'kael-home','the reciprocal spawn does not bounce straight back outside');
 ui.run("worldClearWalking();var still={x:worldState().actor.x,y:worldState().actor.y};openHomeMenu();worldKeys.add('arrowleft');drawWorldScene($('courtyardCanvas').getContext('2d'),400,.1);");
 assert.equal(ui.run('worldState().actor.x===still.x&&worldState().actor.y===still.y'),true);
 assert.equal(ui.run('worldKeys.size'),0);
});

test('returning from the park lands inside the square and a shop route does not re-enter the park',async()=>{
 const ui=journeyUI();await ui.settle();
 ui.run("playerAccount={profile:{id:'park-return',nickname:'Kael'},inventory:[]};journey={phase:'complete'};journeyOwner='park-return';openingState={step:14};showCourtyard();refreshWorldHUD();");
 await ui.run('loadWorldImage(worldRuntime.id)');
 ui.run("var parkDoor=worldScene().places.find(p=>p.target==='park-trail'),parkPoint=worldState().navigation.nodes[parkDoor.node];worldArriveAtDoor(parkDoor);");
 assert.equal(ui.run('worldState().actor.y<parkPoint.y'),true);
 assert.equal(ui.run('worldState().navigation.geometry.safe(worldState().actor)'),true);
 ui.run("var shopDoor=worldScene().places.find(p=>p.target==='kite-shop');worldGo(shopDoor);for(var n=0;n<500&&worldRuntime.id==='quintal';n++){var prev={x:worldState().actor.x,y:worldState().actor.y};worldState().navigation.step(worldState().actor,.1);worldAutoEnter(prev);}");
 assert.equal(ui.run('worldRuntime.id'),'kite-shop');
});

test('the controller stick walks the overworld instead of moving menu focus',async()=>{
 const ui=journeyUI();await ui.settle();
 ui.run("playerAccount={profile:{id:'pad-walker',nickname:'Kael'},inventory:[]};journey={phase:'complete'};journeyOwner='pad-walker';openingState={step:14};showCourtyard();refreshWorldHUD();");
 await ui.run('loadWorldImage(worldRuntime.id)');
 ui.run("var fakePad={connected:true,mapping:'standard',id:'Xbox',axes:[1,0,0,0],buttons:Array.from({length:17},()=>({pressed:false}))};var navigator={getGamepads:()=>[fakePad]};var beforePad=worldState().actor.x;pollPads();drawWorldScene($('courtyardCanvas').getContext('2d'),100,.1);");
 assert.ok(ui.run('worldState().actor.x>beforePad'));assert.equal(ui.run('padState.active'),false);
 ui.run("fakePad.axes=[0,0,0,0];pollPads();var afterPad=worldState().actor.x;drawWorldScene($('courtyardCanvas').getContext('2d'),200,.1);");
 assert.equal(ui.run('worldState().actor.x'),ui.run('afterPad'));
});

function journeyUI(search=''){
 const html=fs.readFileSync('docs/index.html','utf8'),{document}=parseHTML(html),listeners=new Map();
 const canvasPrototype=Object.getPrototypeOf(document.createElement('canvas'));
 canvasPrototype.getContext=()=>new Proxy({imageSmoothingEnabled:true},{get:(o,k)=>k in o?o[k]:()=>{},set:(o,k,v)=>(o[k]=v,true)});
 for(const select of document.querySelectorAll('select')){let value;Object.defineProperty(select,'value',{get(){return value??this.querySelector('option')?.value??''},set(v){value=v}})}
 const context=vm.createContext({document,console,Date,Intl,crypto,URLSearchParams,AbortController,performance:{now:()=>0},location:{search,hash:'',pathname:'/',protocol:'http:',host:'test'},history:{replaceState(){}},localStorage:{getItem(){return null},setItem(){}},matchMedia:()=>({matches:true}),ResizeObserver:class{observe(){}},MutationObserver:class{observe(){}},requestAnimationFrame(){},cancelAnimationFrame(){},setInterval(){},clearInterval(){},setTimeout(){return 1},clearTimeout(){},fetch:async()=>({ok:true,json:async()=>({enabled:false})}),Image:class{width=1536;height=864;set src(v){queueMicrotask(()=>this.onload?.())}},addEventListener(name,fn){if(!listeners.has(name))listeners.set(name,[]);listeners.get(name).push(fn)}});
 vm.runInContext(html.match(/<script>([\s\S]*?)<\/script>/)[1],context);
 return {document,run:code=>vm.runInContext(code,context),settle:()=>new Promise(r=>setImmediate(r))};
}

test('late journey responses cannot open or overwrite another account, and the saved practice checkpoint resumes',async()=>{
 const ui=journeyUI();await ui.settle();
 ui.run(`var resolveOld;accountRequest=async(action,body)=>{if(action==='journey'&&playerAccount.profile.id==='old')return new Promise(r=>resolveOld=r);if(action==='journey')return {journey:{phase:'practice',lesson:3,starter_model:'mata'}};return {}};playerAccount={profile:{id:'old',nickname:'Antiga',equipped_kite_id:'k1'},inventory:[{id:'k1',model_id:'basica',model:{color:0,name:'Carcará'}}]};var oldLoad=onCourtyardAccount();`);
 await ui.run(`playerAccount={profile:{id:'new',nickname:'Nova',equipped_kite_id:'k2'},inventory:[{id:'k2',model_id:'mata',model:{color:1,name:'Mata verde'}}]};onCourtyardAccount()`);await ui.settle();
 ui.run(`resolveOld({journey:{phase:'arrival',lesson:0}})`);await ui.run('oldLoad');await ui.settle();
 assert.equal(ui.run('journeyOwner'),'new');assert.equal(ui.run('journey.phase'),'practice');assert.equal(ui.run('journey.lesson'),3);ui.run('homeActions.professor()');assert.equal(ui.document.getElementById('journeyTitle').textContent,'Vamos voar juntos?');
 ui.run('startFirstFlight()');assert.equal(ui.run('firstFlightRun.index'),3);assert.equal(ui.run('firstFlightRun.state.players[0].color'),1);ui.run('leave()');assert.equal(ui.run('mode'),null);assert.equal(ui.document.getElementById('courtyard').hidden,false);
 ui.run('playerAccount=null;onCourtyardAccount()');assert.equal(ui.run('journey'),null);assert.equal(ui.document.getElementById('courtyard').hidden,true);
});

test('failed starter save keeps the choice screen open and does not start a practice or alter the account',async()=>{
 const ui=journeyUI();await ui.settle();await ui.run(`accountRequest=async()=>({journey:{phase:'choose',lesson:0}});playerAccount={profile:{id:'new',nickname:'Nova',equipped_kite_id:'k1'},inventory:[{id:'k1',model_id:'basica',model:{color:0,name:'Carcará'}}]};onCourtyardAccount()`);await ui.settle();
 ui.run('homeActions.professor()');
 assert.equal(ui.document.getElementById('partnerChoice').hidden,false);
 ui.run(`accountRequest=async()=>{throw Error('Sem conexão')}`);await ui.document.getElementById('partnerConfirm').onclick();
 assert.equal(ui.run('mode'),null);assert.equal(ui.run('firstFlightRun'),null);assert.equal(ui.run('playerAccount.profile.equipped_kite_id'),'k1');assert.equal(ui.document.getElementById('partnerChoice').hidden,false);assert.equal(ui.document.getElementById('partnerStatus').textContent,'Sem conexão');
});

test('first-flight continue saves the completed lesson and advances the same run',async()=>{
 const ui=journeyUI();await ui.settle();
 await ui.run(`accountRequest=async(action)=>action==='journey'?{journey:{phase:'practice',lesson:0}}:{};playerAccount={profile:{id:'flight-ui',nickname:'Kael',equipped_kite_id:'k1'},inventory:[{id:'k1',model_id:'rabbito',model:{color:0,name:'Rabbito',soul:'rabbito'}}]};onCourtyardAccount()`);await ui.settle();
 ui.run(`homeActions.professor();startFirstFlight();firstFlightRun.complete=true;renderFlightCoach();var savedFlightLesson=null;accountRequest=async(action,body)=>{savedFlightLesson=body.lesson;return {journey:{phase:'practice',lesson:body.lesson}}}`);
 await ui.document.getElementById('flightNext').onclick();
 assert.equal(ui.run('savedFlightLesson'),1);
 assert.equal(ui.run('firstFlightRun.index'),1);
 assert.equal(ui.document.getElementById('flightNext').hidden,true);
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

test('legacy exploration cannot unlock encounters, preserves position after battle and clears another account',async()=>{
 const ui=journeyUI('?overworld=legacy');await ui.settle();await ui.run(`accountRequest=async()=>({journey:{phase:'complete'}});playerAccount={profile:{id:'world-a',nickname:'Ana'},inventory:[]};onCourtyardAccount()`);await ui.settle();
 ui.run(`openWorld('morro');worldGo(worldScene().places.find(p=>p.stage==='morro-5'));for(let i=0;i<3000&&worldState().actor.path.length;i++)worldState().navigation.step(worldState().actor,.1);worldRuntime.loading=false;updateWorldContext();interactWorld()`);
 assert.equal(ui.run('mode'),null);assert.notEqual(ui.document.getElementById('modal').style.display,'flex');assert.equal(ui.run('trailProgress.stars["morro-5"]||0'),0);
 ui.run(`worldGo(worldScene().places.find(p=>p.stage==='morro-1'));for(let i=0;i<3000&&worldState().actor.path.length;i++)worldState().navigation.step(worldState().actor,.1);worldRuntime.loading=false;updateWorldContext();interactWorld()`);
 assert.equal(ui.document.getElementById('modal').classList.contains('encounter-preview'),true);assert.equal(ui.run('mode'),null);assert.equal(ui.run('modalReturnFocus.id'),'worldInteract');
 ui.run(`closeModal();var lastWorldPosition={x:worldState().actor.x,y:worldState().actor.y};returnToDistrict('morro-1',false)`);
 assert.equal(ui.run('worldRuntime.id'),'morro');assert.equal(ui.run('worldState().actor.x'),ui.run('lastWorldPosition.x'));assert.equal(ui.document.getElementById('trails').hidden,true);
 assert.match(ui.document.getElementById('homeObjective').textContent,/Converse com Zeca/);
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
    const skill=index===3&&run.exercise==='skill',dodge=index===3&&run.exercise==='dodge',line=index===3&&run.exercise==='line'&&!(p.evade>0);
    flight.tick(run,{x:index===3?0:d>5?dx/d:0,y:index===3?0:d>5?dy/d:0,cut:index===1||index===4||skill,skill:skill?1:0,dodge,lineNonce:line?1:0,lineId:'puxao',lineHeld:false,lineSide:1},now+=1000/60);
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
 await ui.run('loadWorldImage(worldRuntime.id)');
 assert.equal(ui.run('art.reduced'),true);assert.equal(ui.run('homeMotionPaused'),true);
 assert.equal(ui.run('walkingState.actor.x===walkingStart.x&&walkingState.actor.y===walkingStart.y'),true,'input must queue a route, never teleport');
 ui.run(`drawWorldScene($('courtyardCanvas').getContext('2d'),100,.1)`);
 assert.equal(ui.run('walkingState.actor.moving'),true);assert.ok(ui.run('walkingState.navigation.distance(walkingStart,walkingState.actor)>0'));
 const poses=ui.run(`(()=>{const frames=[];homeImages.set('plaza-kael',{});const g={fillStyle:'',beginPath(){},ellipse(){},fill(){},drawImage(...args){frames.push(args.slice(1,5))}};drawWorldHuman(g,walkingState.actor,0);drawWorldHuman(g,walkingState.actor,180);return frames;})()`);
 assert.notDeepEqual([...poses[0]],[...poses[1]],'manual walking advances the existing spritesheet even with ambient motion paused');
 for(let i=0;i<200;i++)ui.run(`drawWorldScene($('courtyardCanvas').getContext('2d'),1000,.1)`);
 assert.equal(ui.run('walkingState.actor.path.length'),0);assert.equal(ui.run('worldRuntime.near.id===worldScene().places[0].id'),true);
});


test('legacy world objectives identify the nearby rival, completion and hide the champion before unlock',async()=>{
 const ui=journeyUI('?overworld=legacy');await ui.settle();await ui.run(`accountRequest=async()=>({journey:{phase:'complete'}});playerAccount={profile:{id:'mission-test',nickname:'Ana'},inventory:[]};onCourtyardAccount()`);await ui.settle();
 ui.run(`openWorld('morro');worldGo(worldScene().places.find(p=>p.stage==='morro-1'));for(let i=0;i<1000&&worldState().actor.path.length;i++)worldState().navigation.step(worldState().actor,.1);updateWorldContext()`);
 assert.match(ui.document.getElementById('homeObjective').textContent,/Converse com Zeca/);
 ui.run(`var rivalNames=[];homeImages.set('rival-Zeca',{});var rivalContext={fillStyle:'',beginPath(){},ellipse(){},fill(){},drawImage(){},strokeText(){},fillText(name){rivalNames.push(name)}};drawWorldRival(rivalContext,worldScene().places.find(p=>p.stage==='morro-1'),0);drawWorldRival(rivalContext,worldScene().places.find(p=>p.stage==='morro-5'),0);`);
 assert.equal(ui.run('rivalNames.join()'),'Zeca');
 ui.run(`for(const stage of trails.stages)trailProgress.stars[stage.id]=1;updateWorldContext()`);assert.match(ui.document.getElementById('homeObjective').textContent,/conquistou o Morro/);assert.equal(ui.document.getElementById('plazaMissionTitle').textContent,'Demo concluída');
});

test('street doors preserve the account and provide repeatable entry, upstairs and return routes',async()=>{
 const ui=journeyUI();await ui.settle();
 ui.run(`playerAccount={profile:{id:'resident',nickname:'Kael',equipped_kite_id:'r'},inventory:[{id:'r',model:{color:0,name:'Rabbito'}}]};journey={phase:'complete'};journeyOwner='resident';openingState={step:14,partner_id:'r'};showCourtyard();refreshWorldHUD();var streetWrites=0;accountRequest=async()=>{streetWrites++;throw Error('Map visits must not write progress')};var residentBefore=JSON.stringify(playerAccount);`);
 for(const target of ['kael-home','kael-bedroom','kael-home','quintal','kite-shop','quintal','professor-home','quintal']){
  ui.run(`var portal=worldScene().places.find(p=>p.action==='street_scene'&&p.target===${JSON.stringify(target)});worldState().navigation.target(worldState().actor,worldState().navigation.nodes[portal.node],true);updateWorldContext();interactWorld();`);await ui.settle();assert.equal(ui.run('worldRuntime.id'),target);assert.ok(ui.run('worldRuntime.near?.action===\"street_scene\"'),'reciprocal door is immediately available');
 }
 assert.equal(ui.run('streetWrites'),0);assert.equal(ui.run('JSON.stringify(playerAccount)===residentBefore'),true);assert.equal(ui.run('openingState.step'),14);
});

test('default campaign traverses all five Morro areas only after confirmed victories and ends the demo',async()=>{
 const ui=journeyUI();await ui.settle();
 ui.run(`var roadStorage=new Map();localStorage.getItem=key=>roadStorage.get(key)||null;localStorage.setItem=(key,value)=>roadStorage.set(key,String(value));localStorage.removeItem=key=>roadStorage.delete(key);localStorage.key=i=>[...roadStorage.keys()][i];Object.defineProperty(localStorage,'length',{get:()=>roadStorage.size});`);
 await ui.run(`accountRequest=async(action)=>action==='trails'?{trails:{revision:1,progress:trails.defaults()}}:action==='journey'?{journey:{phase:'complete',lesson:5}}:{opening:{step:14}};playerAccount={profile:{id:'road-player',nickname:'Kael',equipped_kite_id:'r'},inventory:[{id:'r',model:{color:0,name:'Rabbito',soul:'rabbito'}}]};onCourtyardAccount()`);await ui.settle();
 await ui.run(`trailSync.setUser('road-player')`);
 ui.run(`acceptTrailSnapshot({revision:2,progress:trails.defaults()},'road-player');openWorld('morro');var roadVerified={stars:{}};var moveToRoadPlace=action=>{const p=worldScene().places.find(p=>p.action===action);worldState().navigation.target(worldState().actor,worldState().navigation.nodes[p.node],true);worldRuntime.loading=false;updateWorldContext();};`);
 assert.equal(ui.run('worldRoadEnabled'),true);
 assert.equal(ui.run('location.search'),'');
 for(let i=0;i<5;i++){
  const id=i?'morro-area-'+(i+1):'morro';
  assert.equal(ui.run('worldRuntime.id'),id);
  assert.equal(ui.run('worldScene().painted'),true);
  assert.equal(ui.run('worldScene().places.filter(p=>p.stage).length'),1);
  assert.equal(ui.run('worldRoadGateState().state'),'locked');
  if(i<4){ui.run(`openWorld('morro-area-${i+2}')`);assert.equal(ui.run('worldRuntime.id'),id);}
  ui.run(`moveToRoadPlace('road_gate');interactWorld()`);
  assert.equal(ui.run('worldRuntime.id'),id);
  assert.equal(ui.run('worldState().roadGateClosed'),true);
  // An optimistic result on the client is not enough to open the fence.
  ui.run(`trailProgress.stars['morro-${i+1}']=3;worldSyncRoadGate()`);
  assert.equal(ui.run('worldState().roadGateClosed'),true);
  // Simulate the existing result endpoint delivering its owner-scoped snapshot.
  ui.run(`roadVerified.stars['morro-${i+1}']=1;acceptTrailSnapshot({revision:${i+3},progress:roadVerified},'road-player');worldSyncRoadGate();updateWorldContext()`);
  assert.equal(ui.run('worldState().roadGateClosed'),false);
  assert.equal(ui.run('worldRoadGateState().state'),i===4?'complete':'open');
  ui.run(`var roadBattlePosition={x:worldState().actor.x,y:worldState().actor.y};returnToDistrict('morro-${i+1}',true)`);
  assert.equal(ui.run('worldRuntime.id'),id);
  assert.equal(ui.run('worldState().actor.x'),ui.run('roadBattlePosition.x'));
  assert.equal(ui.run('worldState().actor.y'),ui.run('roadBattlePosition.y'));
  if(i){
   ui.run(`moveToRoadPlace('road_back');interactWorld()`);
   assert.equal(ui.run('worldRuntime.id'),i===1?'morro':'morro-area-'+i);
   ui.run(`moveToRoadPlace('road_next');interactWorld()`);
   assert.equal(ui.run('worldRuntime.id'),id);
  }
  ui.run(`moveToRoadPlace('road_next');interactWorld()`);
 }
 assert.match(ui.document.getElementById('dialogTitle').textContent,/Morro do Sol/);
 assert.ok(ui.document.querySelector('#modal .demo-finale'));
 assert.equal(ui.document.getElementById('dialogAction').textContent,'Continuar explorando');
 assert.equal(ui.run('playerAccount.inventory[0].id'),'r');
 await ui.run(`closeModal();playerAccount={profile:{id:'another-road-player',nickname:'Outra conta'},inventory:[]};onCourtyardAccount()`);await ui.settle();
 assert.equal(ui.run('worldRuntime.id'),'quintal');
 assert.equal(ui.run('worldRoadProgress()'),null);
 ui.run(`openWorld('morro-area-5')`);
 assert.equal(ui.run('worldRuntime.id'),'quintal','previous owner victories never grant access to a new account');
});

test('default map selection survives leaving a match without adding a preview flag',async()=>{
 const ui=journeyUI();await ui.settle();ui.run(`var replacedURLs=[];history.replaceState=(a,b,url)=>replacedURLs.push(url);leave()`);
 assert.ok(ui.run(`replacedURLs.every(url=>!url.includes('overworld=pilot'))`));
 for(const mode of ['legacy','blockout']){
  const study=journeyUI('?overworld='+mode);await study.settle();
  assert.equal(study.run('worldRoadEnabled'),false);
  study.run(`var studyURL;history.replaceState=(a,b,url)=>studyURL=url;leave()`);
  assert.equal(study.run('studyURL'),'/?overworld='+mode);
 }
 const bookmark=journeyUI('?overworld=pilot');await bookmark.settle();assert.equal(bookmark.run('worldRoadEnabled'),true);
});
