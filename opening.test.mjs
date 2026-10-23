import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {PGlite} from '@electric-sql/pglite';
import {KAEL_OPENING} from './src/opening-story.js';
import {createAssetHandler} from './src/static-assets.js';
import vm from 'node:vm';
import {parseHTML} from 'linkedom';
import {artConfig} from './scripts/art-build.mjs';
import {createOpeningRoom} from './src/opening-room.js';

function openingUI(){
 const html=fs.readFileSync('docs/index.html','utf8'),{document}=parseHTML(html);
 Object.getPrototypeOf(document.createElement('canvas')).getContext=()=>new Proxy({imageSmoothingEnabled:true,createRadialGradient:()=>({addColorStop(){}})},{get:(o,k)=>o[k]||(()=>{}),set:(o,k,v)=>(o[k]=v,true)});
 for(const select of document.querySelectorAll('select')){let value;Object.defineProperty(select,'value',{get(){return value??this.querySelector('option')?.value??''},set(v){value=v}});}
 const context=vm.createContext({document,console,Date,Intl,crypto,URLSearchParams,AbortController,performance:{now:()=>0},location:{search:'',hash:'',pathname:'/',protocol:'http:',host:'test'},history:{replaceState(){}},localStorage:{getItem(){return null},setItem(){}},matchMedia:()=>({matches:true}),ResizeObserver:class{observe(){}},MutationObserver:class{observe(){}},requestAnimationFrame(){return 1},cancelAnimationFrame(){},setInterval(){},clearInterval(){},setTimeout(){return 1},clearTimeout(){},fetch:async()=>({ok:true,json:async()=>({enabled:false})}),Image:class{set src(v){queueMicrotask(()=>this.onload?.())}},addEventListener(){}});
 vm.runInContext(html.match(/<script>([\s\S]*?)<\/script>/)[1],context);
 return {document,run:s=>vm.runInContext(s,context),settle:()=>new Promise(r=>setImmediate(r))};
}

test('a dismissed gift reveal is not replayed on reload and the explicit story replay still shows it',async()=>{
 const ui=openingUI();await ui.settle();ui.run(`var giftMemory=new Map();localStorage.getItem=k=>giftMemory.get(k)||null;localStorage.setItem=(k,v)=>giftMemory.set(k,v);openingOwner='gift-owner';openingState={step:7,tail_state:'kept'};renderOpening();`);
 assert.equal(ui.run('openingGiftOpen'),true);await ui.run('nextOpening()');assert.equal(ui.run('openingState.step'),7);assert.equal(ui.run('giftMemory.get("pipaGiftSeenV1:gift-owner")'),'yes');ui.run('renderOpening()');assert.equal(ui.run('openingGiftOpen'),false);ui.run('openingReplay=true;renderOpening()');assert.equal(ui.run('openingGiftOpen'),true);
});

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
 await ui.run('showOpening(true)');for(let i=0;i<20&&ui.run('openingState.step')<10;i++){ui.run('for(let n=0;n<240;n++)openingStepCast(.05)');if(ui.run('openingState.step')===3){ui.run('openingActor={x:1104,y:560,direction:2,path:[]}');await ui.run("openingInspect('desk')");await ui.document.getElementById('openingBenchPlace').onclick();await ui.run('openingFinishCraft()');}else if(ui.run('openingState.step')===7){if(ui.run('openingGiftOpen'))await ui.run('nextOpening()');ui.run('openingActor={x:1104,y:560,direction:2,path:[]}');await ui.run("openingInspect('desk')");}else await ui.run('nextOpening()');}
 ui.document.getElementById('openingName').value='<Lua>';await ui.document.getElementById('openingNameForm').onsubmit({preventDefault(){}});assert.equal(ui.run('openingState.partner_name'),'<Lua>');assert.equal(ui.run('openingState.step'),11);
 assert.equal(ui.run('openingCalls'),1,'replay performs no economy writes');assert.equal(ui.run('playerAccount.inventory.length'),0);assert.match(ui.document.getElementById('openingSpeech').textContent,/<Lua>/);assert.equal(ui.document.getElementById('openingSpeech').children.length,0,'custom name uses text, never HTML');
 await ui.document.getElementById('openingPause').onclick();assert.equal(ui.run('openingState.step'),14);assert.equal(ui.document.getElementById('kaelOpening').hidden,true);
});

test('every film shot renders with reduced motion and measured actor feet stay on the configured room floor',async()=>{
 const ui=openingUI();await ui.settle();await ui.run(`playerAccount={profile:{id:'film',nickname:'Kael'},inventory:[]};openingOwner='film';openingState={step:0};showOpening(false)`);await ui.settle();
 for(let step=0;step<14;step++){ui.run('openingState.step='+step+';renderOpening();drawOpening(1500)');assert.equal(ui.document.getElementById('openingSpeaker').textContent,step===3?'Termine seu projeto':step===7?'Presente de aniversário':step===11?'Seu parceiro vai com você':step===13?'Seu primeiro passeio juntos':step===9?'Kael':KAEL_OPENING[step].speaker);}
 const config=JSON.parse(fs.readFileSync('assets/story/kael-birthday-v1/manifest.json','utf8'));
 for(const room of Object.values(config.rooms))for(const point of Object.values(room.blocking))assert.ok(room.walkable.some(([x,y,w,h])=>point[0]>=x&&point[0]<=x+w&&point[1]>=y&&point[1]<=y+h));
});

test('room movement respects walls and letterboxing, clicks walk rather than teleport, and the craft is required',async()=>{
 const room=createOpeningRoom(artConfig().opening.rooms.bedroom);
 assert.equal(room.safe({x:220,y:500}),false,'bed is outside the walkable floor');assert.deepEqual(room.route({x:540,y:570},{x:220,y:500}),[]);
 assert.equal(room.safe({x:1100,y:350}),false,'the workbench is an obstacle, not walkable floor');
 const around={x:1030,y:610,path:room.route({x:1030,y:610},{x:528,y:816})};for(let n=0;n<180;n++){room.tick(around,{},.05);assert.ok(room.safe(around));}assert.ok(Math.hypot(around.x-528,around.y-816)<2,'the narrow doorway is reached without stopping at its corner');
 const actor={x:768,y:496,path:room.route({x:768,y:496},{x:1200,y:528})};room.tick(actor,{},.05);assert.ok(actor.x>768&&actor.x<1200,'reduced motion still requires real movement');assert.ok(Math.abs(Math.hypot(actor.x-768,actor.y-496)-18)<.001,'one frame advances 360 units/second, without teleporting');for(let i=0;i<80;i++){room.tick(actor,{},.05);assert.ok(room.safe(actor));}assert.ok(room.near(actor,'desk'));
 const p=room.canvasPoint({left:0,top:0,width:1000,height:500},1536,1024,500,250);assert.deepEqual(p,{x:768,y:512});assert.equal(room.canvasPoint({left:0,top:0,width:1000,height:500},1536,1024,10,250),null);
 const ui=openingUI();await ui.settle();await ui.run(`playerAccount={profile:{id:'room',nickname:'Kael'},inventory:[]};openingOwner='room';showOpening(true)`);for(let i=0;i<3;i++)await ui.run('nextOpening()');
 await ui.run('nextOpening()');assert.equal(ui.run('openingState.step'),3,'examining TV cannot advance the project');
 ui.document.getElementById('openingName').value='Too early';await ui.document.getElementById('openingNameForm').onsubmit({preventDefault(){}});assert.equal(ui.run('openingState.step'),3);
 ui.run("openingWalkTo('desk');for(let i=0;i<100;i++)openingStepRoom(.05)");assert.equal(ui.document.getElementById('openingWorkbench').hidden,false);assert.equal(ui.run('openingState.step'),3);
 await ui.document.getElementById('openingBenchPlace').onclick();await ui.run('openingFinishCraft()');assert.equal(ui.run('openingState.step'),4);assert.equal(ui.document.getElementById('openingWorkbench').hidden,true);assert.match(ui.document.getElementById('openingSpeech').textContent,/corpo de papel/);
});

test('craft shows its placement before advancing, cancellation writes nothing, and connection failure leaves a retry',async()=>{
 const ui=openingUI();await ui.settle();await ui.run(`playerAccount={profile:{id:'craft',nickname:'Kael'},inventory:[]};openingOwner='craft';showOpening(true)`);for(let i=0;i<3;i++)await ui.run('nextOpening()');
 ui.run('art.reduced=false;openingActor={x:1104,y:560,path:[]}');await ui.run("openingInspect('desk')");ui.document.getElementById('openingBenchPlace').onclick();ui.run('drawOpeningWorkbench(400)');assert.equal(ui.run('openingState.step'),3,'cannot skip visible placement');
 ui.document.getElementById('openingBenchBack').onclick();ui.run('drawOpeningWorkbench(1600)');assert.equal(ui.run('openingState.step'),3,'leaving before placement does not save the craft');
 await ui.run("openingInspect('desk')");ui.run("openingReplay=false;accountRequest=async()=>{throw Error('Sem conexão')}");ui.document.getElementById('openingBenchPlace').onclick();ui.run('drawOpeningWorkbench(1000)');await ui.settle();
 assert.equal(ui.run('openingState.step'),3);assert.equal(ui.document.getElementById('openingBenchPlace').disabled,false);assert.equal(ui.document.getElementById('openingWorkbench').hidden,false);assert.equal(ui.document.getElementById('openingBenchStatus').textContent,'Sem conexão');assert.equal(ui.run('playerAccount.inventory.length'),0);
});

test('walking into the opening staircase advances without requiring an interaction button',async()=>{
 const ui=openingUI();await ui.settle();await ui.run("playerAccount={profile:{id:'door-walker',nickname:'Kael'},inventory:[]};openingOwner='door-walker';openingState={step:11};showOpening(false)");
 ui.run("openingReplay=true;openingActor={x:528,y:786,direction:0,path:[]};openingWalkKeys.arrowdown=true;openingWalkKeys.arrowleft=true;openingStepRoom(.05);openingStepRoom(.05);");await ui.settle();
 assert.equal(ui.run('openingState.step'),11);assert.equal(ui.run('openingAvatarActivity.state.kind'),'stairs');assert.equal(ui.run('Object.keys(openingWalkKeys).length'),0);
 ui.run('for(let i=0;i<36;i++)openingStepCast(.1)');await ui.settle();assert.equal(ui.run('openingState.step'),12);assert.equal(ui.run('openingAvatarActivity'),null);
});

test('classic staging gates the gift, keeps walking on the floor and reaches both exits with a following partner',async()=>{
 const ui=openingUI();await ui.settle();await ui.run(`playerAccount={profile:{id:'cast',nickname:'Kael'},inventory:[]};openingOwner='cast';openingState={step:5};showOpening(false)`);await ui.settle();ui.run('openingReplay=true');
 assert.equal(ui.document.getElementById('consentBar').hidden,true);
 const start=ui.run('openingMother.y');await ui.run('nextOpening()');assert.equal(ui.run('openingState.step'),5,'cannot skip the entrance');
 ui.run('openingStepCast(.05)');assert.ok(ui.run('openingMother.y')<start);assert.ok(ui.run('openingMother.y')>640,'walks rather than teleports');
 for(let n=0;n<200;n++){ui.run('openingStepCast(.05)');assert.equal(ui.run('openingBedroomNavigation.safe(openingMother)&&openingBedroomNavigation.safe(openingActor)'),true);}
 await ui.run('nextOpening()');await ui.run('nextOpening()');assert.equal(ui.run('openingState.step'),7);
 assert.equal(ui.document.getElementById('openingGift').hidden,false);assert.equal(ui.run('openingWalkActive()'),false);
 await ui.run('nextOpening()');assert.equal(ui.run('openingState.step'),7,'receiving gift does not skip returning to desk');assert.equal(ui.document.getElementById('openingGift').hidden,true);
 ui.run("openingWalkTo('desk');for(let n=0;n<200;n++)openingStepCast(.05)");await ui.settle();assert.equal(ui.run('openingState.step'),8);
 ui.run('for(let n=0;n<200;n++)openingStepCast(.05)');await ui.run('nextOpening()');ui.run('for(let n=0;n<200;n++)openingStepCast(.05)');
 await ui.run('nextOpening()');assert.match(ui.document.getElementById('openingSpeech').textContent,/ganhou vida/);
 await ui.run('nextOpening()');await ui.run('nextOpening()');assert.equal(ui.run('openingState.step'),9,'waits for Rabbito to approach');
 ui.run('for(let n=0;n<100;n++)openingStepCast(.05)');await ui.run('nextOpening()');assert.equal(ui.run('openingState.step'),10);
 ui.document.getElementById('openingName').value='Pingo';await ui.document.getElementById('openingNameForm').onsubmit({preventDefault(){}});
 assert.equal(ui.run('openingState.step'),11);assert.equal(ui.run('openingRoomStep()'),true);await ui.run('nextOpening()');assert.equal(ui.run('openingState.step'),11);
 ui.run("openingWalkTo('stairs')");for(let n=0;n<240;n++){ui.run('openingStepCast(.05)');if(ui.run('openingState.step')===11)assert.equal(ui.run('openingBedroomNavigation.safe(openingActor)&&openingBedroomNavigation.safe(openingRabbit)'),true);}
 await ui.settle();assert.equal(ui.run('openingState.step'),12,ui.run('JSON.stringify({actor:openingActor,intent:openingWalkIntent,spots:openingRoomNavigation.hotspots,status:$("openingStatus").textContent})'));await ui.run('nextOpening()');assert.equal(ui.run('openingState.step'),13);
 ui.run("openingWalkTo('exit');for(let n=0;n<240;n++)openingStepCast(.05)");await ui.settle();assert.equal(ui.run('openingState.step'),14);
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
  assert.equal((await call()).step,0);assert.equal((await db.query('select count(*)::int n from public.player_kites where owner_id=$1',[a])).rows[0].n,0,'new story account starts without unexplained partners');await assert.rejects(()=>call('name',10,'Muito cedo'),/nascimento/);await assert.rejects(()=>call('advance',6),/cena mudou/);
  for(let i=0;i<7;i++)await call('advance',i);assert.equal((await call()).tail_state,'held');await call('advance',7);await call('advance',8);assert.equal((await call()).tail_state,'attached');await call('advance',9);
  await assert.rejects(()=>call('advance',10),/nome/);await assert.rejects(()=>call('name',10,'x'.repeat(25)),/24/);await assert.rejects(()=>call('name',10,'a\nb'),/quebras/);
  await db.exec('reset role');await db.query("update public.player_profiles set active_match=gen_random_uuid(),active_until=now()+interval '5 minutes' where id=$1",[a]);await auth(a);await assert.rejects(()=>call('name',10,'Nuvem'),/partida/);assert.equal((await call()).step,10);
  await db.exec('reset role');await db.query('update public.player_profiles set active_match=null,active_until=null where id=$1',[a]);await auth(a);
  const result=await Promise.all([call('name',10,'Nuvem'),call('name',10,'Outro')]);assert.equal(result[0].partner_id,result[1].partner_id);assert.equal(result[1].partner_name,'Nuvem');assert.equal(result[1].step,11);
  for(let i=11;i<14;i++)await call('advance',i);assert.equal((await call()).step,14);await call('name',10,'Rabbito');assert.equal((await call()).partner_name,'Nuvem');
  await auth(b);assert.equal((await call()).step,0);assert.equal((await call()).partner_id,null);
  await db.exec('reset role');const items=(await db.query("select * from public.player_kites where owner_id=$1 and model_id='rabbito'",[a])).rows;assert.equal(items.length,1);assert.equal((await db.query('select count(*)::int n from public.player_kites where owner_id=$1',[a])).rows[0].n,1,'only the story partner is granted');assert.equal((await db.query('select count(*)::int n from public.player_kites where owner_id=$1',[old])).rows[0].n,4,'legacy inventory remains intact');assert.equal(items[0].permanent,true);assert.equal(items[0].personal_name,'Nuvem');
  const journey=(await db.query('select * from public.player_journeys where owner_id=$1',[a])).rows[0];assert.equal(journey.phase,'practice');assert.equal(journey.starter_model,'rabbito');assert.equal((await db.query('select equipped_kite_id,xp from public.player_profiles where id=$1',[a])).rows[0].equipped_kite_id,items[0].id);
  const tradable=(await db.query("insert into public.player_kites(owner_id,model_id) values($1,'mata') returning id",[a])).rows[0].id;
  await db.query('update public.player_profiles set equipped_kite_id=$2 where id=$1',[a,tradable]);
  const match='44444444-4444-4444-8444-444444444444';
  const reservation=(await db.query("select public.reserve_player_match($1,$2,'STORY1','capture') r",[a,match])).rows[0].r;
  assert.equal(reservation.basicKiteId,items[0].id);assert.equal(reservation.basicSoul,'rabbito');
  await db.query('insert into public.match_players(match_id,user_id) values($1,$2)',[match,b]);
  await db.query('select public.settle_player_cut($1,$2,$3,$4,$5)',['story-fallback-cut',match,b,a,tradable]);
  assert.equal((await db.query('select equipped_kite_id from public.player_profiles where id=$1',[a])).rows[0].equipped_kite_id,items[0].id,'capture returns to the actual permanent story partner');
  assert.equal((await db.query('select count(*)::int n from public.summon_recipes where target_model_id=$1',['rabbito'])).rows[0].n,0);
 }finally{await db.close();}
});

test('opening keeps the requested story beats and publishes measured, separately layered assets',async()=>{
 assert.equal(KAEL_OPENING.length,14);const text=KAEL_OPENING.map(s=>s.text).join(' ');for(const word of ['Jamile','Gollia','Quinze anos','Rabiola Antiga','minha cabeça'])assert.ok(text.includes(word));assert.equal(KAEL_OPENING[10].shot,'name');
 const m=JSON.parse(fs.readFileSync('assets/story/kael-birthday-v1/manifest.json','utf8')),serve=createAssetHandler();
 for(const def of Object.values(m.images)){const response=await serve(new Request('http://test/assets/'+def.image));assert.equal(response.status,200,def.image);assert.equal(response.headers.get('content-type'),'image/png');const buffer=Buffer.from(await response.arrayBuffer());if(def.width)assert.equal(buffer.readUInt32BE(16),def.width);if(def.height)assert.equal(buffer.readUInt32BE(20),def.height);}
 for(const a of Object.values(m.actors))for(const f of a.frames){assert.ok(f.x+f.w<=a.width&&f.y+f.h<=a.height);assert.ok(f.bounds.w>0&&f.bounds.h>0);}
 assert.equal(m.images.bedroom.alpha,false);assert.equal(m.images.mother.alpha,true);assert.equal(m.rooms.downstairs.exit.target,'quintal');
 assert.equal(m.actors.mother.frames.length,8);assert.match(m.images.mother.image,/mother-overworld-v2/);
});
