import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import {createHash} from 'node:crypto';
import {parseHTML} from 'linkedom';
import {createAssetHandler} from './src/static-assets.js';
import {artConfig} from './scripts/art-build.mjs';

test('collection viewports enclose every pose without changing the crop scale across states',()=>{
 const config=artConfig(),entries=config.dex.entries.filter(e=>e.collection);
 assert.equal(entries.length,25);assert.equal(new Set(entries.map(e=>e.id)).size,25);
 for(const e of entries){
  const a=config.atlases[e.atlas],v=a.meta.viewport;assert.equal(e.model,e.id);assert.ok(e.color>=0&&e.color<=3);
  assert.ok(v&&v.w>0&&v.h>0);assert.equal(Object.keys(a.frames).length,e.id==='rabbito'?8:16);
  for(const f of Object.values(a.frames)){const b=f.contentBounds;assert.ok(v.x<=b.x&&v.y<=b.y);assert.ok(v.x+v.w>=b.x+b.w&&v.y+v.h>=b.y+b.h);assert.ok(v.x+v.w<=f.frame.w&&v.y+v.h<=f.frame.h);}
  assert.equal(Object.keys(a.animations).length,5);assert.ok(e.story.length>0);
 }
});

function app({seen=false,search='',hash='',failed=false,reduced=false,member=false,hosted=false}={}){
 const html=fs.readFileSync('docs/index.html','utf8').replace('const STATIC_HOST = true;',hosted?'const STATIC_HOST = false;':'const STATIC_HOST = true;'),{document}=parseHTML(html),timers=[],requests=[],draws=[],listeners=new Map(),storage=new Map(seen?[['pipaAssisIntroV1','done']]:[]);
 for(const canvas of document.querySelectorAll('canvas'))canvas.getContext=()=>({clearRect(){},drawImage(...args){draws.push({canvas:canvas.id,args});},imageSmoothingEnabled:true});
 const context=vm.createContext({document,console,crypto,Date,Intl,URLSearchParams,AbortController,performance:{now:()=>100},location:{search,hash,pathname:'/',protocol:'https:',host:'test'},history:{replaceState(){}},localStorage:{getItem:k=>storage.get(k)??null,setItem:(k,v)=>storage.set(k,v)},matchMedia:()=>({matches:reduced}),MutationObserver:document.defaultView.MutationObserver,ResizeObserver:class{observe(){}},requestAnimationFrame(){},setInterval(){},clearInterval(){},setTimeout(fn,delay){timers.push({fn,delay});return timers.length;},clearTimeout(){},fetch:async()=>({ok:true,json:async()=>({enabled:false})}),Image:class{set src(url){requests.push(url);queueMicrotask(()=>failed?this.onerror():this.onload());}},addEventListener(name,fn){if(!listeners.has(name))listeners.set(name,[]);listeners.get(name).push(fn);}});
 vm.runInContext(html.match(/<script>([\s\S]*?)<\/script>/)[1],context);
 if(member)vm.runInContext('playerAccount={profile:{nickname:"Ana",level:1},inventory:[]}',context);
 context.cancelAnimationFrame=()=>{};
 // Linkedom exposes select.value as read-only; browsers implement a setter.
 for(const select of document.querySelectorAll('select')){let value;Object.defineProperty(select,'value',{configurable:true,get(){return value??this.querySelector('option[selected]')?.value??this.querySelector('option')?.value??'';},set(next){value=next;}});}
 return {document,requests,draws,storage,run:code=>vm.runInContext(code,context),auto:()=>timers.find(t=>t.delay===650).fn(),settle:()=>new Promise(r=>setImmediate(r)),key:key=>{let stopped=false;for(const fn of listeners.get('keydown')){fn({key,target:{tagName:'BODY'},preventDefault(){},stopImmediatePropagation(){stopped=true;}});if(stopped)break;}}};
}

test('forgot-password requests do not send a typed login password and preserve a retry path',async()=>{
 const a=app();await a.settle();a.run(`$('accountEmail').value='player@example.test';$('accountPassword').value='NeverForwardThis';var recoveryRequests=[];accountRequest=async(action,body)=>{recoveryRequests.push({action,body});return {message:'Confira seu e-mail.'};};`);
 a.document.getElementById('forgotPassword').onclick();assert.equal(a.document.getElementById('recoveryEmail').value,'player@example.test');await a.document.getElementById('recoveryForm').onsubmit({preventDefault(){}});assert.equal(a.run('recoveryRequests[0].action'),'recover');assert.equal(a.run('Object.keys(recoveryRequests[0].body).join()'),'email');assert.equal(a.document.getElementById('recoveryStatus').textContent,'Confira seu e-mail.');
 a.document.getElementById('recoveryCancel').onclick();assert.equal(a.document.getElementById('passwordRecovery').hidden,true);
});

test('recovery links open password confirmation without persisting the token and discard it after completion',async()=>{
 const a=app({hash:'#type=recovery&access_token=unit-recovery-token-not-a-credential&refresh_token=discard-this-too'});await a.settle();assert.equal(a.run('accountRecoveryMode'),'reset');assert.equal(a.document.getElementById('accountModal').style.display,'flex');assert.equal(a.run('recoveryFragment.get("access_token")'),null);assert.equal(a.run('recoveryFragment.get("refresh_token")'),null);
 a.run(`var resets=0;accountRequest=async()=>{resets++;return {message:'Senha atualizada.'};};$('recoveryPassword').value='UnitTestOnly123!';$('recoveryConfirm').value='DifferentUnitTest!';`);await a.document.getElementById('recoveryForm').onsubmit({preventDefault(){}});assert.equal(a.run('resets'),0);assert.match(a.document.getElementById('recoveryStatus').textContent,/iguais/);
 a.run(`$('recoveryConfirm').value='UnitTestOnly123!'`);await a.document.getElementById('recoveryForm').onsubmit({preventDefault(){}});assert.equal(a.run('resets'),1);assert.equal(a.run('passwordRecoveryToken'),null);assert.equal(a.run('accountRecoveryMode'),null);assert.equal(a.document.getElementById('recoveryPassword').value,'');assert.ok([...a.storage.values()].every(v=>!v.includes('unit-recovery-token')));
});

test('a verified recovery session opens the authenticated account instead of asking for another login',async()=>{
 const a=app({hash:'#type=recovery&access_token=unit-recovery-token-not-a-credential'});await a.settle();
 a.run(`loadRecentMatches=()=>{};onCourtyardAccount=()=>{};onTrailAccountChange=()=>{};onLineAccountChange=()=>{};accountRequest=async()=>({loginEmail:'verified@example.test',message:'Senha atualizada e conta conectada.',account:{profile:{id:'11111111-1111-4111-8111-111111111111',nickname:'Ana',level:1,xp:0,next_level_xp:100,cuts:0,equipped_kite_id:null},inventory:[]}});$('recoveryPassword').value='UnitTestOnlyPassword!';$('recoveryConfirm').value='UnitTestOnlyPassword!';`);
 await a.document.getElementById('recoveryForm').onsubmit({preventDefault(){}});
 assert.equal(a.document.getElementById('accountButton').textContent,'Minha conta');assert.equal(a.document.getElementById('accountAuth').hidden,true);assert.equal(a.document.getElementById('accountEmail').value,'verified@example.test');assert.equal(a.run('passwordRecoveryToken'),null);assert.equal(a.document.getElementById('recoveryConfirm').value,'');
});

test('explicit session notices return the old tab home without releasing the seat or reconnecting',async()=>{
 for(const notice of ['session-replaced','session-expired']){
  const a=app({seen:true});await a.settle();
  a.run(`var auditRequests=[],removedRooms=[];request=async(action)=>{auditRequests.push(action);return {};};roomSessions.remove=code=>removedRooms.push(code);WebSocket=class{close(){this.closed=true;}send(){}};WebSocket.OPEN=1;mode='online';room='ABCDEF';token='unit-test-seat-key';state=eng.create(Date.now());me='unit';socket=null;nextSocketAt=0;connectRealtime();var previousSocket=socket;`);
  a.run(`previousSocket.onmessage({data:JSON.stringify({type:${JSON.stringify(notice)}})});`);
  assert.equal(a.run('mode'),null);assert.equal(a.run('socket'),null);assert.equal(a.run('previousSocket.closed'),true);assert.equal(a.run('auditRequests.length'),0);assert.equal(a.run('removedRooms.join()'),'ABCDEF');assert.equal(a.document.body.classList.contains('in-match'),false);
  a.run(`previousSocket.onclose({reason:''});`);assert.equal(a.run('mode'),null);assert.equal(a.run('auditRequests.length'),0);
 }
});

test('plaza HUD uses account progression, routes missions and options, and never grants collection items',async()=>{
 const a=app({seen:true});await a.settle();
 a.run(`playerAccount={profile:{id:'plaza-a',nickname:'Ana',level:8,xp:5100,next_level_xp:6400,equipped_kite_id:null},inventory:[]};journey={phase:'complete'};trailProgress.coins=123;showCourtyard();`);
 assert.equal(a.document.getElementById('plazaCoins').textContent,'123');assert.equal(a.document.getElementById('plazaLevel').textContent,'Pipeiro · Nv. 8');assert.equal(a.document.getElementById('plazaXP').getAttribute('aria-valuenow'),'13');
 a.document.getElementById('plazaNav-missions').onclick();assert.match(a.document.getElementById('dialogTitle').textContent,/próximo voo/);assert.equal(a.document.querySelectorAll('.plaza-mission-row').length,1);assert.equal(a.run('mode'),null);
 a.run('closeModal()');a.document.getElementById('plazaNav-settings').onclick();assert.equal(a.run('homeMenuGroup'),'optionsGroup');a.run('closeHomeMenu()');assert.equal(a.run('playerAccount.inventory.length'),0);
 a.run('trailProgress.coins=27;reflectCoins()');assert.equal(a.document.getElementById('plazaCoins').textContent,'27');
});
test('plaza backpack displays only confirmed owned tails and ignores replies from a previous account',async()=>{
 const a=app({seen:true});await a.settle();
 a.run(`playerAccount={profile:{id:'bag-a',nickname:'Ana',level:1},inventory:[]};accountRequest=async()=>({summon:{tails:[{id:'one',modelId:'basica',name:'Carcará',status:'ready'},{id:'another',modelId:'basica',name:'Carcará',status:'ready'},{id:'two',modelId:'basica',name:'Carcará',status:'damaged'},{id:'used',modelId:'basica',name:'Carcará',status:'consumed'}]}});`);
 await a.run('openPlazaBag()');assert.equal(a.document.querySelectorAll('.plaza-bag-item').length,2);assert.match(a.document.getElementById('plazaBagStatus').textContent,/3 rabiolas/);
 const cards=[...a.document.querySelectorAll('.plaza-bag-item')];assert.match(cards[0].textContent,/×2/);assert.match(cards[0].textContent,/Pronta/);assert.match(cards[1].textContent,/×1/);assert.match(cards[1].textContent,/Danificada/);
 a.run('closeModal();var bagResolve;accountRequest=()=>new Promise(resolve=>bagResolve=resolve);var bagRequest=openPlazaBag();playerAccount={profile:{id:"bag-b"},inventory:[]};bagResolve({summon:{tails:[{id:"old",modelId:"basica",name:"Carcará",status:"ready"}]}})');
 await a.run('bagRequest');assert.equal(a.document.querySelectorAll('.plaza-bag-item').length,0);assert.equal(a.run('playerAccount.inventory.length'),0);
});
test('portrait collections keep selection, filtering and confirmed equipment separate from ownership',async()=>{
 const a=app({seen:true,reduced:true});await a.settle();
 const account={profile:{id:'visual-test',nickname:'Ana',level:1,xp:0,next_level_xp:100,cuts:0,equipped_kite_id:'basic'},inventory:[{id:'basic',model_id:'basica',permanent:true,model:{name:'Carcará',color:0,soul:null,acquisition:'starter'}},{id:'special',model_id:'alvaneve',permanent:true,model:{name:'Alvaneve',color:0,soul:'alvaneve',acquisition:'event'}}]};
 a.run('playerAccount='+JSON.stringify(account)+";accountModal.style.display='flex';renderAccountDialog();navigateClub('collection');");
 assert.equal(a.document.querySelectorAll('#inventoryList .pipamon-portrait').length,2);
 a.document.querySelector('[data-kite-id="special"]').onclick();await a.settle();
 assert.equal(a.document.querySelector('#inventoryName').textContent,'Alvaneve');assert.equal(a.run('inventoryPreviewFrame'),0,'reduced motion does not start animation');
 assert.equal(a.run('playerAccount.profile.equipped_kite_id'),'basic');
 a.run("$('inventorySearch').value='nao existe';renderInventory();");assert.equal(a.document.querySelector('#inventoryDetails').hidden,true);assert.equal(a.document.querySelector('#inventoryEmpty').hidden,false);
 a.run("$('inventorySearch').value='';$('inventoryFilter').value='event';renderInventory();");assert.equal(a.document.querySelectorAll('#inventoryList button').length,1);assert.equal(a.document.querySelector('#inventoryName').textContent,'Alvaneve');
 a.run("var pendingEquip,called;onTrailAccountChange=()=>{};onLineAccountChange=()=>{};onCourtyardAccount=()=>{};accountRequest=(action,data)=>{called={action,data};return new Promise(resolve=>pendingEquip=resolve)};var equipPromise=equipInventory(playerAccount.inventory[1]);");
 assert.equal(a.run('playerAccount.profile.equipped_kite_id'),'basic');assert.equal(a.document.querySelector('#inventoryEquip').disabled,true);
 a.run("pendingEquip({account:{...playerAccount,profile:{...playerAccount.profile,equipped_kite_id:'special'}}});");await a.run('equipPromise');
 assert.equal(a.run('called.action'),'equip');assert.equal(a.run('called.data.kiteId'),'special');assert.equal(a.run('playerAccount.profile.equipped_kite_id'),'special');assert.equal(a.run('playerAccount.inventory.length'),2);
 a.run('closeAccount();');assert.equal(a.run('inventoryPreviewFrame'),0);
});

test('every Dex portrait is an explicit in-frame face crop shared with inventory',()=>{
 const config=artConfig();assert.equal(Object.keys(config.portraits).length,config.dex.entries.length);
 for(const e of config.dex.entries){const [x,y,size]=config.portraits[e.id].crop,a=config.atlases[e.atlas],f=a.frames[a.animations[e.sequence||'idle'][0]].frame;assert.ok(x>=0&&y>=0&&size>0&&x+size<=f.w&&y+size<=f.h,e.id);}
});

test('normal match exposes six rebicadas, keeps Q/E class skills and clears held input when pausing',async()=>{
 const ui=app({seen:true});await ui.settle();
 ui.run(`var lineState=eng.create(Date.now());lineState.players=[Object.assign(eng.player('Teste',0,'normal',Date.now()),{anchorX:90})];enter(lineState,'normal','practice');updateNormalLineHUD();`);
 assert.equal(ui.document.querySelector('#normalLineHUD').hidden,false);assert.equal(ui.document.querySelectorAll('#normalLineChoice option').length,6);
 ui.run(`$('normalLineChoice').value='puxao';normalLineStart();keys.q=true;`);
 assert.equal(ui.run('input().lineHeld'),true);assert.equal(ui.run('input().skill'),-1);
 ui.run(`eng.practiceStep(state,me,input(),state.last+50);updateNormalLineHUD();`);
 assert.match(ui.document.querySelector('#normalLineState').textContent,/tensionada/);
 ui.run('openPause();');assert.equal(ui.run('input().lineHeld'),false);
 ui.run('normalLineStart();');assert.equal(ui.run('input().lineHeld'),false,'menus cannot queue a rebicada');
 ui.run('closeSheet();leave();updateNormalLineHUD();');assert.equal(ui.document.querySelector('#normalLineHUD').hidden,true);
 ui.run(`playerAccount={profile:{id:'test',nickname:'Teste'},inventory:[]};showCourtyard();homeActions.lab();syncHomeInert();`);
 assert.equal(ui.document.querySelector('#skyExperiment').hidden,false);assert.equal(ui.document.querySelector('#courtyard').inert,true);
 ui.run('skyClose();syncHomeInert();');assert.equal(ui.document.querySelector('#courtyard').inert,false);
});

test('battle instruments show real partner, rounds and low-line state; unavailable actions and keyboard buttons remain usable',async()=>{
 const ui=app({seen:true});await ui.settle();
 ui.run(`var hudState=eng.create(Date.now(),{mode:'rounds'});hudState.phase='live';hudState.players=[Object.assign(eng.player('Ana',1,'hud',Date.now()),{hp:24,rounds:2})];enter(hudState,'hud','practice');updateNormalLineHUD();`);
 assert.equal(ui.document.querySelector('#partnerName').textContent,'Mata verde · Nv. 1');assert.equal(ui.document.querySelector('#hud').dataset.danger,'true');assert.equal(ui.document.querySelectorAll('#roundPips .won').length,2);
 assert.equal(ui.document.querySelector('#hp').parentElement.getAttribute('aria-valuenow'),'24');
 ui.run(`document.querySelector('.hud-basics [data-key=" "]').onclick({detail:0});`);assert.equal(ui.run('input().cut'),true,'Enter on the attack button queues a real attack');
 ui.run(`document.querySelector('.hud-basics [data-key="dodge"]').onclick({detail:0});`);assert.equal(ui.run('input().dodge'),true);
 ui.run(`state.players[0].energy=5;state.players[0].skillCooldown=3;updateNormalLineHUD();`);
 assert.ok(ui.document.querySelector('.skill-actions button').disabled);assert.ok(ui.document.querySelector('.hud-basics [data-key="dodge"]').disabled);assert.match(ui.document.querySelector('#skillStatus').textContent,/Recarga/);
 assert.equal(ui.document.querySelector('.combat-deck').contains(ui.document.querySelector('#normalLineHUD')),true);
});

test('painted HUD serves its real alpha atlases in both builds and every crop stays inside its image',async()=>{
 const config=artConfig(),serve=createAssetHandler();assert.equal(Object.keys(config.hud.sheets).length,2);
 for(const sheet of Object.values(config.hud.sheets)){
  const bytes=fs.readFileSync('assets/'+sheet.image);assert.equal(bytes[25],6);assert.equal(bytes.readUInt32BE(16),sheet.width);assert.equal(bytes.readUInt32BE(20),sheet.height);assert.deepEqual(fs.readFileSync('docs/assets/'+sheet.image),bytes);
  const result=await serve(new Request('https://game.test/'+sheet.url));assert.equal(result.status,200);assert.match(result.headers.get('cache-control'),/immutable/);assert.deepEqual(Buffer.from(await result.arrayBuffer()),bytes);
 }
 for(const [id,[key,x,y,w,h]] of Object.entries(config.hud.frames)){const sheet=config.hud.sheets[key];assert.ok(x>=0&&y>=0&&w>0&&h>0&&x+w<=sheet.width&&y+h<=sheet.height,id);}
 const ui=app({seen:true});await ui.settle();ui.run(`var painted=eng.create(Date.now());painted.players=[eng.player('Ana',0,'art-hud',Date.now())];enter(painted,'art-hud','practice');updateHud(Date.now());updateNormalLineHUD();`);
 assert.equal(ui.document.querySelectorAll('#playerPortrait .hud-art-portrait').length,1);assert.ok(ui.document.querySelector('.hud-player>.hud-art-ranking'));assert.ok(ui.document.querySelector('#hp').classList.contains('hud-art-hp-fill'));
 for(const state of ['normal','hover','pressed','disabled'])assert.ok(ui.document.querySelector('#normalLineUse>.hud-art-button-'+state));
 ui.run(`$('normalLineChoice').value='folha';updateNormalLineHUD();`);assert.ok(ui.document.querySelector('#normalLineUse>.hud-art-folha'));
 ui.run(`state.players[0].color=2;updateHud(Date.now());`);assert.equal(ui.document.querySelectorAll('#playerPortrait .hud-art-portrait').length,1,'equipping a different partner preserves its illustrated frame');
});

test('HUD keeps content separate from art, side changes preserve sprites, and mobile tabs release held controls',async()=>{
 const ui=app({seen:true});await ui.settle();ui.run(`var audited=eng.create(Date.now());audited.players=[eng.player('Nome comprido',1,'audited',Date.now())];enter(audited,'audited','practice');updateHud(Date.now());updateNormalLineHUD();normalLineStart();`);
 const side=ui.document.querySelector('#normalLineSide');assert.equal(side.querySelectorAll('[class*="hud-art-button-"]').length,4);side.onclick();assert.equal(side.querySelectorAll('[class*="hud-art-button-"]').length,4);assert.equal(side.querySelector('.hud-button-content').textContent,'Esquerda');
 assert.ok(ui.document.querySelector('#normalLineHUD>.hud-panel-content'));assert.equal(ui.run('normalLineHeld'),true);
 ui.document.querySelector('[data-hud-tab="partner"]').onclick();assert.equal(ui.run('normalLineHeld'),false);assert.equal(ui.document.querySelector('.combat-deck').dataset.panel,'partner');assert.equal(ui.document.querySelector('[data-hud-tab="partner"]').getAttribute('aria-pressed'),'true');
 const audit=fs.readFileSync('docs/hud-audit.html','utf8'),script=audit.slice(audit.indexOf('<script>')+8,audit.lastIndexOf('</script>'));assert.doesNotThrow(()=>new vm.Script(script));assert.match(script,/319/);assert.match(script,/content-overflow/);assert.match(script,/button-label/);
});

test('a failed initial account check retries automatically and unlocks login without losing typed fields',async()=>{
 const ui=app({seen:true,hosted:true});await ui.settle();
 await ui.run(`(async()=>{var attempts=0;globalThis.retryWake=null;setTimeout=(fn,ms)=>{if(ms===3000)retryWake=fn;return 1};fetch=async()=>{throw Error('temporary connection failure')};$('accountEmail').value='player@example.test';$('accountPassword').value='test-only-password';await initializeAccounts();accountModal.style.display='flex';renderAccountDialog();})()`);
 assert.equal(ui.run('accountConnection'),'offline');assert.ok(ui.document.querySelector('#submitAccount').disabled);assert.equal(ui.document.querySelector('#retryAccounts').hidden,false);assert.doesNotMatch(ui.document.querySelector('#accountMessage').textContent,/ainda está sendo conectado/);
 await ui.run(`(async()=>{fetch=async url=>({ok:true,json:async()=>url.endsWith('/config')?{enabled:true}:{account:null}});await retryWake();})()`);
 assert.equal(ui.run('accountsEnabled'),true);assert.equal(ui.document.querySelector('#submitAccount').disabled,false);assert.equal(ui.document.querySelector('#retryAccounts').hidden,true);assert.equal(ui.document.querySelector('#accountEmail').value,'player@example.test');assert.equal(ui.document.querySelector('#accountPassword').value,'test-only-password');
});

test('opening login recovers disabled configuration, shares pending checks and preserves explicit server unavailability',async()=>{
 const ui=app({seen:true,hosted:true});await ui.settle();
 ui.run(`var configCalls=0,releaseConfig;fetch=async url=>{if(url.endsWith('/config')){configCalls++;return new Promise(resolve=>releaseConfig=()=>resolve({ok:true,json:async()=>({enabled:true})}));}return {ok:true,json:async()=>({account:null})}};var checkOne=initializeAccounts(),checkTwo=openAccount();`);
 assert.equal(ui.run('configCalls'),1);ui.run('releaseConfig();');await ui.run('Promise.all([checkOne,checkTwo])');assert.equal(ui.document.querySelector('#submitAccount').disabled,false);
 await ui.run(`(async()=>{fetch=async()=>({ok:true,json:async()=>({enabled:false})});await initializeAccounts();})()`);
 assert.equal(ui.run('accountConnection'),'disabled');assert.ok(ui.document.querySelector('#submitAccount').disabled);assert.match(ui.document.querySelector('#accountMessage').textContent,/indisponível no servidor/);
});

test('static Pages directs accounts to the official server instead of showing a never-ending connection message',async()=>{
 const ui=app({seen:true});await ui.settle();await ui.run('openAccount()');
 assert.equal(ui.document.querySelector('#accountServerLink').hidden,false);assert.equal(ui.document.querySelector('#accountServerLink').getAttribute('href'),'https://pipaklub.onrender.com/');assert.ok(ui.document.querySelector('#submitAccount').disabled);assert.equal(ui.document.querySelector('#retryAccounts').hidden,true);
});
test('rebicar follows accepted attacks, mirrors its pull and never changes simulation coordinates',()=>{
 const a=app({seen:true});
 const result=a.run(`(()=>{const p=eng.player('Teste',0,'test',0);p.x=500;p.y=300;eng.move(p,{cut:true,x:1},.016);const start=rebicarPose(p);eng.move(p,{cut:true,x:1},.06);const pull=rebicarPose(p),left=rebicarPose({...p,facing:-1}),quiet=rebicarPose(p,true);const before=[p.x,p.y];rebicarPose(p);return {start,pull,left,quiet,position:before,after:[p.x,p.y],strikes:p.strikes,end:rebicarPose({...p,attackCooldown:.2}),dead:rebicarPose({...p,respawn:123})};})()`);
 assert.equal(result.start.active,true);assert.equal(result.strikes,1);assert.ok(Math.abs(result.pull.tilt)>.1);assert.equal(result.pull.tilt,-result.left.tilt);assert.equal(result.pull.dx,-result.left.dx);assert.equal(result.pull.dy,result.left.dy);
 assert.deepEqual([...result.position],[...result.after]);assert.equal(result.end.active,false);assert.equal(result.dead.active,false);
 assert.equal(result.quiet.active,true);assert.ok(result.quiet.alpha>0);assert.equal(result.quiet.dx,0);assert.equal(result.quiet.dy,0);assert.equal(result.quiet.tilt,0);
 for(const energy of [0,11])assert.equal(a.run(`(()=>{const p=eng.player('T',0,'t',0);p.energy=${energy};eng.move(p,{cut:true},.016);return rebicarPose(p).active;})()`),false,'insufficient energy does not fake an attack');
 assert.equal(a.run(`(()=>{const p=eng.player('T',0,'t',0);eng.move(p,{cut:true,dodge:true},.016);return rebicarPose(p).active;})()`),false,'dodging does not fake a rebicada');
});

test('universal rebicar wraps every Pipamon sprite and light mode keeps its visible feedback',()=>{
 const a=app({seen:true});
 const result=a.run(`(()=>{const bodies=[],moves=[],waves=[];ctx=new Proxy({},{get:(o,k)=>k==='measureText'?()=>({width:70}):o[k]||((...args)=>{if(k==='translate')moves.push(args);if(k==='stroke')waves.push(1);}),set:(o,k,v)=>(o[k]=v,true)});kiteBody=(col,t,p)=>bodies.push(p.soul||p.color);lightMode=true;for(const entry of ART_CONFIG.dex.entries){const p=eng.player(entry.name,entry.color,entry.id,0);p.soul=entry.id;p.x=500;p.y=300;p.attackCooldown=.59;kite(p,100);}return {bodies,moves,waves,count:ART_CONFIG.dex.entries.length};})()`);
 assert.equal(result.count,35);assert.equal(result.bodies.length,35);assert.equal(result.moves.length,35);assert.ok(result.moves.every(([x,y])=>x!==500&&y!==300));assert.ok(result.waves.length>=68,'light mode retains the line pulse and pull arc');
});

test('visitors can practice but trails and Dex request an account and cannot grant progress',async()=>{
 const a=app({seen:true});await a.settle();
 assert.ok([...a.document.querySelectorAll('[data-members-only]')].every(el=>el.hidden));
 for(const id of ['practice','rulesButton','profileButton','accountButton'])assert.equal(a.document.getElementById(id).hidden,false);
 a.auto();assert.equal(a.run('introductionOpen'),false);
 await a.run('quickMatch()');assert.equal(a.run('mode'),null);
 a.run('closeAccount();playerAccount={profile:{nickname:"Ana",level:1},inventory:[]};reflectAccount()');
 assert.ok([...a.document.querySelectorAll('[data-members-only]')].every(el=>!el.hidden));
 a.run('playerAccount=null;reflectAccount()');assert.ok([...a.document.querySelectorAll('[data-members-only]')].every(el=>el.hidden));
 a.run('openTrails()');assert.equal(a.document.getElementById('trails').hidden,true);assert.equal(a.document.getElementById('accountModal').style.display,'flex');
 a.run("closeAccount();startStage('morro-1')");assert.equal(a.run('mode'),null);assert.equal(a.run('trailStage'),null);
 a.run('closeAccount();openDex()');assert.equal(a.document.getElementById('pipaDex').hidden,true);
 a.run("closeAccount();openSheet('friendsSheet');$('practice').onclick()");assert.equal(a.run('mode'),'practice');assert.equal(a.run('state.rules'),'casual');assert.equal(a.run('state.mode'),'rounds');assert.equal(a.document.getElementById('friendsSheet').hidden,true);
});

test('club menu isolates features, preserves trade inputs and returns home when reopened',async()=>{
 const a=app({seen:true});await a.settle();
 a.run(`for(const b of document.querySelectorAll('button'))b.focus=()=>{}; playerAccount={profile:{nickname:'Ana',level:1,xp:0,next_level_xp:100,cuts:0},inventory:[]}; renderAccountDialog();`);
 assert.equal(a.document.getElementById('clubHome').hidden,false);
 for(const id of ['collection','trades','profile','history','events','farm']){
  a.run(`navigateClub('${id}')`);
  assert.equal(a.document.getElementById('clubHome').hidden,true);
  for(const page of a.document.querySelectorAll('.club-page'))assert.equal(page.hidden,page.id!=='club-'+id);
 }
 a.run(`navigateClub('trades');document.getElementById('tradeCode').value='KEEP123';navigateClub('profile');renderAccountDialog();navigateClub('trades');`);
 assert.equal(a.document.getElementById('tradeCode').value,'KEEP123');
 a.run('closeAccount();openAccount()');assert.equal(a.document.getElementById('clubHome').hidden,false);
 assert.equal(a.document.getElementById('recentMatches').parentElement.id,'club-history');
 assert.equal(a.document.getElementById('eventSoulsList').parentElement.id,'club-events');
});

test('integrated designs preserve leader discovery and reveal ritual effects only after confirmed success',async()=>{
 const a=app({seen:true});await a.settle();a.run('playerAccount={profile:{nickname:"Ana",level:1},inventory:[]};openTrails()');await a.settle();
 assert.doesNotMatch(a.document.getElementById('trailList').textContent,/Mikka|Lohan|Kleie/);
 for(const [stage,name]of [['morro-5','Mikka'],['praia-5','Lohan'],['torres-5','Kleie']]){a.run("trailPick='"+stage+"';renderStage()");await a.settle();assert.equal(a.document.getElementById('stageSpeaker').textContent,'Sr. Assis:');assert.equal(a.document.getElementById('trailStart').disabled,true);}
 a.run("updateSummonRun({status:'failed',remaining:0})");assert.equal(a.document.querySelector('.ritual-reveal-portal'),null);
 a.run("updateSummonRun({status:'succeeded',remaining:2,name:'Mata',color:1})");assert.equal(a.document.querySelectorAll('#summonReveal .ritual-reveal-portal').length,1);assert.equal(a.document.querySelectorAll('#summonReveal .ritual-reveal-particles').length,1);
 assert.equal(a.document.getElementById('summonNotice').hidden,true,'completed rituals do not keep the interruption warning');
 assert.match(a.document.documentElement.style.getPropertyValue('--ritual-scene'),/ascendente-fundo-v1/);
});

test('daily menu requires login, renders confirmed coins, and starts only a server daily room',async()=>{
 const a=app({seen:true});await a.settle();
 a.run("for(const b of document.querySelectorAll('button'))b.focus=()=>{};openDaily()");
 assert.equal(a.document.getElementById('accountModal').style.display,'flex');assert.equal(a.run('mode'),null);
 a.run(`closeAccount();playerAccount={profile:{id:'daily-user'}};var dailyAccepted;trailSync.accept=data=>dailyAccepted=data;accountRequest=async()=>({daily:{date:'2026-10-17',weather:'fog',claimed:false,progress:{coins:25},revision:2}})`);
 await a.run('openDaily()');assert.match(a.document.getElementById('dialogBody').textContent,/Neblina/);assert.match(a.document.getElementById('dialogBody').textContent,/primeira vitória/);assert.equal(a.run('dailyAccepted.revision'),2);
 a.run(`request=async(action,body)=>{if(action!=='daily')throw Error('wrong action');return {code:'DA1A00',token:'secret',me:'pilot',state:{id:'daily',players:[],events:[],daily:{name:'Ventania'}}}};connectRealtime=()=>{}`);
 await a.run('startDaily()');assert.equal(a.run('mode'),'online');assert.equal(a.run('token'),'secret');assert.equal(a.document.getElementById('copy').style.display,'none');assert.match(a.document.getElementById('arenaMode').textContent,/Céu do dia/);
});

test('club navigation abandons an active ritual before opening another feature',async()=>{
 const a=app({seen:true});await a.settle();
 a.run(`for(const b of document.querySelectorAll('button'))b.focus=()=>{};playerAccount={};accountPage='summon';summonOpen=true;summonRitual={id:'ritual-1',status:'active'};var abandoned=[];summonCall=async(action,body)=>{abandoned.push({action,body});};navigateClub('profile');`);
 assert.equal(a.run('summonOpen'),false);assert.equal(a.run('summonRitual'),null);
 assert.equal(a.run('abandoned[0].action'),'abandon');assert.equal(a.run('abandoned[0].body.ritualId'),'ritual-1');
 assert.equal(a.document.getElementById('club-profile').hidden,false);
});

test('school tour can be replayed and skipped, lessons leave cleanly without changing free practice',async()=>{
 const a=app({seen:true,member:true});await a.settle();
 a.run('firstSchoolVisit()');assert.equal(a.document.getElementById('schoolTourOverlay').hidden,false);
 a.document.getElementById('schoolTourNext').onclick();assert.match(a.document.getElementById('schoolTourTitle').textContent,/Morro/);
 a.document.getElementById('schoolTourSkip').onclick();assert.equal(a.document.getElementById('schoolHub').hidden,false);
 assert.equal(a.storage.get('pipaMenuTourV1'),'done');
 a.run('startSchoolLesson(0)');assert.equal(a.run('mode'),'practice');assert.equal(a.run('state.school'),true);
 assert.equal(a.document.getElementById('schoolNext').disabled,true);
 a.document.getElementById('schoolNext').onclick();assert.equal(a.run('schoolRun.index'),0,'cannot skip completion through Next');
 a.document.getElementById('schoolExit').onclick();assert.equal(a.run('mode'),null);assert.equal(a.run('schoolRun'),null);
 assert.equal(a.document.getElementById('schoolCoach').hidden,true);
 a.run("closeSchool();$('practice').onclick()");assert.equal(a.run('mode'),'practice');assert.equal(a.run('state.school'),undefined);
 a.run('leave();firstSchoolVisit()');assert.equal(a.document.getElementById('schoolTourOverlay').hidden,true);
 a.document.getElementById('schoolTour').onclick();assert.equal(a.document.getElementById('schoolTourOverlay').hidden,false);
});

test('legacy Assis presentation remains available explicitly, while the new first-flight flow owns automatic arrival',async()=>{
 const a=app({member:true});await a.settle();assert.equal(a.requests.length,1);a.auto();assert.equal(a.run('introductionOpen'),false);a.run('openIntroduction()');await a.settle();assert.equal(a.document.getElementById('assisIntro').hidden,false);assert.match(a.document.getElementById('assisSpeech').textContent,/Nozinho/);assert.equal(a.requests.length,4);assert.match(a.document.getElementById('assisLoad').textContent,/pesquisador/);
 const expressions=new Set(),poses=new Set();for(let i=0;i<8;i++){expressions.add(a.run('ART_CONFIG.intro.steps[introductionStep].expression'));poses.add(a.run('ART_CONFIG.intro.steps[introductionStep].pose'));a.document.getElementById('assisNext').onclick();}
 assert.equal(expressions.size,8);assert.equal(poses.size,8);assert.equal(a.run('mode'),null);assert.equal(a.document.getElementById('schoolTourOverlay').hidden,false);assert.equal(a.document.getElementById('assisIntro').hidden,true);assert.equal(a.storage.get('pipaAssisIntroV1'),'done');assert.ok(a.draws.some(d=>d.canvas==='assisBody'));assert.ok(a.draws.some(d=>d.canvas==='assisFace'));assert.ok(a.draws.some(d=>d.canvas==='assisCompanion'));
 a.run('closeSchoolTour();closeSchool();leave()');a.document.getElementById('how').onclick();await a.settle();assert.equal(a.requests.length,4);assert.equal(a.document.getElementById('assisIntro').hidden,false);
});
test('skip, invitations, keyboard blocking and image failure do not prevent playing',async()=>{
 for(const options of [{seen:true},{search:'?sala=ABCDEF'}]){const a=app(options);a.auto();await a.settle();assert.equal(a.run('introductionOpen'),false);}
 const a=app({failed:true,member:true});a.auto();a.run('openIntroduction()');await a.settle();assert.equal(a.document.getElementById('assisRetry').hidden,false);assert.match(a.document.getElementById('assisLoad').textContent,/não carregaram/);a.key('e');assert.equal(a.run('input().skill'),0);a.document.getElementById('assisSkip').onclick();assert.equal(a.run('introductionOpen'),false);a.run("$('practice').onclick()");assert.equal(a.run('mode'),'practice');assert.equal(a.run("art.creature({},0,0)"),false);
});

test('a signed-in room invitation exposes join and cancel instead of an empty game shell',async()=>{
 const a=app({seen:true,member:true,search:'?sala=ABCDEF'});await a.settle();
 assert.equal(a.run('offerRoomInvitation()'),true);
 assert.equal(a.document.getElementById('courtyard').hidden,false);
 assert.equal(a.document.getElementById('friendsSheet').hidden,false);
 assert.equal(a.document.getElementById('code').value,'ABCDEF');
 assert.equal(a.run('mode'),null,'opening an invitation never silently enters a match');
 a.run('closeSheet()');assert.equal(a.document.getElementById('courtyard').hidden,false);
 assert.equal(a.run('offerRoomInvitation()'),false,'refreshing account data does not reopen a dismissed invitation');
});
test('arena draws actual atlas frames, restores smoothing, and reduced motion freezes the selected creature',async()=>{
 const a=app({reduced:true,seen:true});await a.settle();a.run("art.creature($('sky').getContext('2d'),2,0)");a.run("art.creature($('sky').getContext('2d'),2,1200)");const d=a.draws.filter(d=>d.canvas==='sky');assert.equal(d.length,2);assert.deepEqual(d[0].args.slice(1),d[1].args.slice(1));assert.match(a.run('kiteSVG(colors[2])'),/almatic-icon/);assert.match(a.run('kiteSVG(colors[2])'),/basicos-v2\/azulao\.png\?v=/);
});
test('left-facing starter and event sprites mirror around their own center without leaking canvas transforms',async()=>{
 const a=app({seen:true});await a.settle();await a.run("art.load('flautrevo')");
 a.run("var mirrorCalls=[];var mirrorCtx={imageSmoothingEnabled:true,save(){mirrorCalls.push('save')},restore(){mirrorCalls.push('restore')},translate(x,y){mirrorCalls.push(['translate',x,y])},scale(x,y){mirrorCalls.push(['scale',x,y])},drawImage(){mirrorCalls.push('draw')}}");
 for(const soul of [null,'flautrevo']){
  a.run('mirrorCalls=[];art.creature(mirrorCtx,0,200,10,20,80,'+JSON.stringify({soul,facing:-1})+')');
  const calls=JSON.parse(a.run('JSON.stringify(mirrorCalls)'));
  assert.deepEqual(calls,['save',['translate',100,0],['scale',-1,1],'draw','restore']);
  assert.equal(a.run('mirrorCtx.imageSmoothingEnabled'),true);
  a.run('mirrorCalls=[];art.creature(mirrorCtx,0,200,10,20,80,'+JSON.stringify({soul,facing:1})+')');
  assert.equal(a.run("mirrorCalls.join(',')"),'draw');
 }
});
test('asset route serves every real PNG with hash caching, HEAD and ETag; unknown files cannot be read',async()=>{
 const serve=createAssetHandler();for(const a of Object.values(artConfig().atlases)){const url='https://game.test/'+a.meta.url,r=await serve(new Request(url));assert.equal(r.status,200);assert.equal(r.headers.get('content-type'),'image/png');assert.match(r.headers.get('cache-control'),/immutable/);const bytes=new Uint8Array(await r.arrayBuffer());assert.deepEqual([...bytes.slice(0,8)],[137,80,78,71,13,10,26,10]);const head=await serve(new Request(url,{method:'HEAD'}));assert.equal((await head.arrayBuffer()).byteLength,0);const cached=await serve(new Request(url,{headers:{'if-none-match':r.headers.get('etag')}}));assert.equal(cached.status,304);const file='docs/'+a.meta.url.split('?')[0];assert.ok(fs.existsSync(file));assert.deepEqual(fs.readFileSync(file),Buffer.from(bytes));}
 assert.equal((await serve(new Request('https://game.test/assets/.env'))).status,404);assert.equal((await serve(new Request('https://game.test/assets/characters/sr-assis/poses.png',{method:'POST'}))).status,405);assert.equal(await serve(new Request('https://game.test/api/create')),null);
});
test('generated trade textures retain alpha, ship in Pages and are served by the asset allowlist',async()=>{
 const serve=createAssetHandler();
 for(const name of ['trade-celestial','trade-sky','trade-spirit-16']){
  const file='vfx/'+name+'.png',bytes=fs.readFileSync('assets/'+file),hash=createHash('sha256').update(bytes).digest('hex').slice(0,12);
  assert.deepEqual(fs.readFileSync('docs/assets/'+file),bytes);
  if(name!=='trade-sky'){assert.equal(bytes[25],6,'atlas is RGBA');assert.equal(bytes.readUInt32BE(16),bytes.readUInt32BE(20),'atlas cells use a square grid');}
  const r=await serve(new Request('https://game.test/assets/'+file+'?v='+hash));assert.equal(r.status,200);assert.match(r.headers.get('cache-control'),/immutable/);assert.deepEqual(Buffer.from(await r.arrayBuffer()),bytes);
  assert.equal((await serve(new Request('https://game.test/assets/'+file,{method:'HEAD'}))).status,200);
 }
 const css=fs.readFileSync('src/index.html','utf8');assert.match(css,/trade-celestial\.png/);assert.match(css,/trade-sky\.png/);
});

test('special Souls load only on demand and animate all five states using their real atlas rectangles',async()=>{
 const config=artConfig(),a=app({seen:true});await a.settle();assert.equal(a.requests.length,1);
 for(const soul of config.dex.entries.filter(e=>e.group==='event').map(e=>e.id)){
  a.run("art.load('"+soul+"')");await a.settle();
  for(const [state,extra,victory] of [['idle',{},false],['flight',{input:{x:1}},false],['skill',{skillCooldown:6.7},false],['hurt',{hitFlash:.05},false],['victory',{},true]]){
   const time=200,p={soul,...extra};a.run("art.creature($('sky').getContext('2d'),0,"+time+",-56,-44,112,"+JSON.stringify(p)+","+victory+")");
   const actual=a.draws.at(-1).args.slice(1,5),atlas=config.atlases[soul];
   assert.ok(atlas.animations[state].some(key=>{const f=atlas.frames[key].frame,v=atlas.meta.viewport;return JSON.stringify(actual)===JSON.stringify(v?[f.x+v.x,f.y+v.y,Math.min(v.w,f.w-v.x),Math.min(v.h,f.h-v.y)]:[f.x,f.y,f.w,f.h]);}),soul+' '+state);
  }
 }
 assert.equal(a.requests.length,30);
 assert.match(a.run("art.markup(0,'alvaneve')"),/especiais\/alvaneve\.png/);
 assert.ok(!a.run("art.markup(0,'<script>')").includes('<script>'));
 const account={profile:{nickname:'Ana',level:1,xp:0,next_level_xp:100,cuts:0,equipped_kite_id:'owned'},inventory:[{id:'owned',model_id:'alvaneve',permanent:true,model:{name:'Alvaneve',color:0,soul:'alvaneve',acquisition:'event'}}]};
 a.run('playerAccount='+JSON.stringify(account)+';reflectAccount();renderAccountDialog();');
 assert.equal(a.document.querySelectorAll('#eventSoulsList .event-locked').length,28);
 assert.match(a.document.getElementById('inventoryList').textContent,/Especial de evento/);
 assert.match(a.document.getElementById('selectionName').textContent,/Alvaneve/);
 a.run("$('practice').onclick()");assert.equal(a.run("state.players.find(p=>p.id==='you').soul"),'alvaneve');
});

test('member Pipa Dex lists all creatures, searches accents, filters and previews without unlocking inventory',async()=>{
 const a=app();await a.settle();a.run('playerAccount={profile:{},inventory:[]}');a.document.getElementById('workshop').onclick();await a.settle();a.auto();assert.equal(a.run('introductionOpen'),false);
 assert.equal(a.document.getElementById('pipaDex').hidden,false);
 assert.equal(a.document.querySelectorAll('#dexList button').length,35);
 assert.equal(a.document.getElementById('dexName').textContent,'Carcará');
 assert.equal(a.document.querySelectorAll('#dexAnimation option').length,5);
 a.run("$('dexSearch').value='azulao';filterDex()");await a.settle();
 assert.equal(a.document.getElementById('dexName').textContent,'Azulão');
 assert.match(a.document.getElementById('dexStory').textContent,/chuva/);
 a.run("$('dexSearch').value='';$('dexFilter').value='event';filterDex()");await a.settle();
 assert.equal(a.document.querySelectorAll('#dexList button').length,29);
 assert.equal(a.document.querySelectorAll('#dexAnimation option').length,5);
 assert.match(a.document.getElementById('dexObtain').textContent,/exclusiva de eventos/);
 assert.equal(a.run('playerAccount.inventory.length'),0);assert.equal(a.run('mode'),null);
 for(const state of ['idle','flight','skill','hurt','victory']){
  a.run("$('dexAnimation').value='"+state+"';$('dexAnimation').onchange();dexElapsed=180;drawDex()");
  const rect=a.draws.filter(d=>d.canvas==='dexCanvas').at(-1).args.slice(1,5),atlas=artConfig().atlases.flautrevo;
  assert.ok(atlas.animations[state].some(key=>JSON.stringify(Object.values(atlas.frames[key].frame))===JSON.stringify(rect)));
 }
 a.run("$('dexSearch').value='nao-existe';filterDex()");assert.equal(a.document.getElementById('dexEmpty').hidden,false);assert.equal(a.document.getElementById('dexDetails').hidden,true);
 a.run("$('dexSearch').value='';$('dexFilter').value='companion';filterDex()");await a.settle();assert.equal(a.document.getElementById('dexName').textContent,'Nozinho');assert.match(a.document.getElementById('dexObtain').textContent,/não é uma pipa equipável/);
 a.key('Escape');assert.equal(a.document.getElementById('pipaDex').hidden,true);assert.equal(a.run('dexFrame'),0);
});

test('Dex respects reduced motion and keeps lore available when sprite loading fails',async()=>{
 const a=app({seen:true,reduced:true,failed:true});await a.settle();a.run('playerAccount={profile:{},inventory:[]}');a.document.getElementById('workshop').onclick();await a.settle();
 assert.equal(a.run('dexPlaying'),false);assert.equal(a.document.getElementById('dexPlay').textContent,'Reproduzir');
 assert.equal(a.document.getElementById('dexRetry').hidden,false);assert.match(a.document.getElementById('dexLoad').textContent,/não carregou/);
 assert.match(a.document.getElementById('dexStory').textContent,/Carcará/);
 a.document.getElementById('dexPlay').onclick();assert.equal(a.run('dexPlaying'),true);
 a.document.getElementById('dexPlay').onclick();assert.equal(a.run('dexPlaying'),false);
 a.document.getElementById('dexClose').onclick();assert.equal(a.run('dexOpen'),false);
});

test('each Dex entry shows its own tail, keeps companion provenance and never grants inventory',async()=>{
 const a=app({seen:true});await a.settle();a.run('playerAccount={profile:{},inventory:[]}');a.document.getElementById('workshop').onclick();
 const config=artConfig();assert.equal(config.items.length,34);assert.equal(new Set(config.items.map(i=>i.image)).size,34);
 for(const entry of config.dex.entries){
  a.run('selectDex(dexEntries.find(e=>e.id==='+JSON.stringify(entry.id)+'))');
  const root=a.document.getElementById('dexItemsSection'),cards=root.querySelectorAll('.dex-item');if(!entry.items.length){assert.ok(['javali-biscoito','rabbito'].includes(entry.id));assert.equal(root.hidden,true);assert.equal(cards.length,0);continue;}assert.equal(root.hidden,false);assert.equal(cards.length,1);
  const item=config.items.find(i=>i.id===entry.items[0]);assert.equal(item.pipamon,entry.id);assert.equal(item.name,'Rabiola de '+entry.name);
  const image=cards[0].querySelector('img');assert.equal(image.getAttribute('src'),item.url);assert.equal(image.alt,item.name);assert.equal(image.loading,'lazy');
  if(entry.group==='companion'){assert.equal(item.source,'companion');assert.match(root.textContent,/não aparece como selvagem/);assert.doesNotMatch(root.textContent,/Drop previsto/);}
  else if(entry.id==='javali-biscoito'){assert.equal(item.source,'event');assert.match(root.textContent,/Origem: evento/);assert.doesNotMatch(root.textContent,/selvagem|Drop previsto/);}
  else{assert.equal(item.source,'wild');assert.match(root.textContent,new RegExp(entry.name+' selvagem'));
   // Rabiolas dropped by trail bosses say where to earn them; the rest are still coming.
   if(['rabiola-raio-de-sol','rabiola-chaspiral','rabiola-flautrevo'].includes(item.id))assert.match(root.textContent,/Prêmio: .+ \(Trilhas\)/);else assert.match(root.textContent,/Em breve/);}
 }
 a.run("selectDex(dexEntries.find(e=>e.id==='nozinho'))");const failed=a.document.querySelector('#dexItemsList img'),fallback=a.document.querySelector('.dex-item-fallback');failed.onerror();assert.equal(failed.hidden,true);assert.equal(fallback.hidden,false);assert.match(a.document.getElementById('dexItemsList').textContent,/Rabiola de Nozinho/);
 a.run('selectDex(dexEntries[0])');assert.equal(a.document.querySelector('.dex-item-fallback').hidden,true);assert.equal(a.run('playerAccount.inventory.length'),0);assert.equal(a.run('mode'),null);
});

test('all tail PNGs are published with content hashes, HEAD and cache validation',async()=>{
 const serve=createAssetHandler();
 for(const item of artConfig().items){
  const url='https://game.test/'+item.url,r=await serve(new Request(url));assert.equal(r.status,200);assert.match(r.headers.get('cache-control'),/immutable/);assert.equal(r.headers.get('content-type'),'image/png');
  const bytes=Buffer.from(await r.arrayBuffer());assert.equal(bytes.readUInt32BE(16),item.imageSize?.w||209);assert.equal(bytes.readUInt32BE(20),item.imageSize?.h||209);assert.equal(bytes[25],6);
  assert.deepEqual(fs.readFileSync('docs/assets/'+item.image),bytes);
  assert.equal((await serve(new Request(url,{method:'HEAD'}))).status,200);
  assert.equal((await serve(new Request(url,{headers:{'if-none-match':r.headers.get('etag')}}))).status,304);
 }
 assert.equal((await serve(new Request('https://game.test/assets/items/rabiolas/unknown.png'))).status,404);
});


test('first-flight instructions follow the active input device without resetting the lesson',async()=>{
 const a=app({member:true});await a.settle();
 assert.match(a.run("inputDevice='gamepad-xbox';firstFlightInstruction(1)"),/pressione A/);
 assert.match(a.run("inputDevice='gamepad-ps';firstFlightInstruction(3)"),/L1 ou R1/);
 assert.match(a.run("inputDevice='touch';firstFlightInstruction(3)"),/botão Habilidade/);
 assert.match(a.run("inputDevice='keyboard';firstFlightInstruction(0)"),/WASD/);
});

test('demo completion leaves three working routes and future districts stay unavailable with legacy wins',async()=>{
 const a=app({member:true});await a.settle();
 a.run(`playerAccount.profile.id='demo-ui';journey={phase:'complete'};for(const stage of trails.stages)trailProgress.stars[stage.id]=3;selectCity(1);`);
 assert.equal(a.document.getElementById('cityExplore').hidden,true);assert.match(a.document.getElementById('cityDescription').textContent,/demo inclui/);assert.equal(a.run('firstOpenStage().id'),'morro-5');
 a.run('openDemoFinale()');assert.match(a.document.getElementById('dialogTitle').textContent,/Morro do Sol/);assert.ok(a.document.getElementById('demoOnline'));assert.ok(a.document.getElementById('demoSummon'));assert.ok(a.document.getElementById('demoRevisit'));
 a.document.getElementById('demoOnline').onclick();assert.equal(a.document.getElementById('friendsSheet').hidden,false);
});

test('first invocation rehearsal uses no server calls or tails and enables the real ritual only after a valid practice',async()=>{
 const a=app({member:true});await a.settle();
 a.run(`playerAccount.inventory=[{id:'story'}];summonData={tails:[{id:'tail',modelId:'raio',name:'Raio de sol',status:'ready'}],seen:[]};var rehearsalCalls=0;summonCall=async()=>{rehearsalCalls++;};prepareSummon({modelId:'raio',name:'Raio de sol',color:3,pattern:[1,2,5],availableTailIds:['tail']});`);
 a.document.querySelector('#summonTailList button').onclick();assert.equal(a.document.getElementById('summonStart').disabled,true);
 a.document.getElementById('summonPracticeButton').onclick();
 for(const n of [1,2,5])a.document.querySelector(`[aria-label="Estrela de ensaio ${n}"]`).onclick();
 assert.equal(a.document.getElementById('summonStart').disabled,false);assert.equal(a.run('rehearsalCalls'),0);assert.equal(a.run('summonData.tails[0].status'),'ready');assert.equal(a.run('playerAccount.inventory.length'),1);
});

test('choosing the first partner shows a welcome only after server confirmation, before entering practice',async()=>{
 const a=app({member:true});await a.settle();
 a.run("playerAccount.profile.id='test';journeyOwner='test';homeReplay=false;accountRequest=async()=>({journey:{phase:'practice'}});choosePartner()");
 a.document.getElementById('partnerOptions').children[2].onclick();
 assert.match(a.document.getElementById('partnerConnection').textContent,/proteção/);
 await a.document.getElementById('partnerConfirm').onclick();
 assert.equal(a.run('mode'),null);assert.match(a.document.getElementById('journeyTitle').textContent,/Azulão/);
 assert.match(a.document.getElementById('journeySpeech').textContent,/não consome itens/);
 assert.equal(a.document.getElementById('journeyDialog').hidden,false);
});


test('city district briefing keeps its five encounters separate and clears the scope when closed',async()=>{
 const a=app({member:true});await a.settle();
 a.run("$('trails').dataset.district='0';trailPick=trails.trails[0].stages[0].id;renderTrails()");
 assert.equal(a.document.querySelectorAll('.trail:not([hidden])').length,1);
 assert.doesNotMatch(a.document.getElementById('districtArrival').textContent,/Mikka/);assert.equal(a.document.querySelectorAll('.trail:not([hidden]) .place-node').length,5);
 assert.match(a.document.getElementById('stageTrail').textContent,/Encontro 1 de 5/);
 a.run('closeTrails();renderTrails()');
 assert.equal(a.document.getElementById('districtArrival').hidden,true);
 assert.equal(a.document.querySelectorAll('.trail:not([hidden])').length,1);
});

test('district maps keep every leader hidden until the final encounter is unlocked',async()=>{
 const a=app({member:true});await a.settle();
 for(const id of ['morro','praia','torres']){
  a.run(`trailProgress=trails.defaults();trailPick=trails.trails.find(t=>t.id==='${id}').stages.at(-1).id;renderTrails()`);
  const text=a.document.getElementById('trails').textContent;
  assert.doesNotMatch(text,/Mikka|Lohan|Kleie/);
  assert.equal(a.document.getElementById('trailStart').disabled,true);
  assert.equal(a.document.getElementById('stageSpeaker').textContent,'Sr. Assis:');
  a.run(`for(const st of trails.stages){if(st.id===trailPick)break;trailProgress.stars[st.id]=1;}renderTrails()`);
  const name=a.run('trails.trails[trails.stage(trailPick).trailIndex].leaderName');
  if(id!=='morro'){assert.equal(a.document.getElementById('trailStart').disabled,true,'future districts stay locked even with legacy progress');continue;}
  assert.ok(a.document.getElementById('stageFoes').textContent.includes(name));
  assert.equal(a.document.getElementById('trailStart').disabled,false);
 }
});

test('encounter presentation starts no match, blocks locked leaders and returns focus on cancellation',async()=>{
 const a=app({member:true});await a.settle();
 a.run("trailPick='morro-1';$('trails').hidden=false;renderTrails();presentStage('morro-1')");
 assert.equal(a.run('mode'),null);assert.equal(a.document.getElementById('modal').style.display,'flex');
 assert.match(a.document.getElementById('dialogTitle').textContent,/Praça de chegada/);
 assert.match(a.document.getElementById('dialogBody').textContent,/Zeca/);
 a.key('Escape');assert.equal(a.document.getElementById('trails').hidden,false);a.run('presentStage("morro-5")');
 assert.equal(a.document.getElementById('modal').style.display,'none');
 assert.equal(a.run('mode'),null);
});

test('returning to a district highlights only a confirmed unlocked next place',async()=>{
 const a=app({member:true});await a.settle();
 a.run("trailProgress=trails.defaults();trailSync.sync=()=>{};returnToDistrict('morro-1',true)");
 assert.equal(a.run('trailPick'),'morro-1');assert.equal(a.document.getElementById('trails').dataset.district,'0');
 assert.match(a.document.getElementById('districtArrival').textContent,/Conferindo o resultado/);
 a.run("trailProgress.stars['morro-1']=2;renderTrails()");
 assert.equal(a.run('trailPick'),'morro-2');assert.match(a.document.getElementById('districtArrival').textContent,/Lugar conquistado/);
 a.run("returnToDistrict('morro-2',false)");assert.equal(a.run('trailPick'),'morro-2');
});


test('all five Morro rival cutouts have alpha, versioned routes and identical published files',async()=>{
 const config=artConfig(),serve=createAssetHandler(),rivals=config.designs.rivals;
 assert.deepEqual(Object.keys(rivals),['Zeca','Bia','Juninho','Lia','Tião']);
 for(const [name,rival]of Object.entries(rivals)){
  const reply=await serve(new Request('https://game.test/'+rival.url));assert.equal(reply.status,200,name);
  assert.match(reply.headers.get('cache-control'),/immutable/);const bytes=Buffer.from(await reply.arrayBuffer());
  assert.equal(bytes[25],6,name+' must preserve RGBA');assert.ok(bytes.readUInt32BE(16)>=512);assert.ok(bytes.readUInt32BE(20)>=512);
  assert.deepEqual(fs.readFileSync('docs/assets/'+rival.image),bytes);
  assert.equal((await serve(new Request('https://game.test/'+rival.url,{method:'HEAD'}))).status,200);
 }
});

test('encounter portraits follow current speakers, preserve the hidden leader and wait for confirmed outcomes',async()=>{
 const a=app({member:true});await a.settle();
 const before=a.run("trailStoryMarkup('morro-1')");assert.match(before,/zeca-v1/);assert.doesNotMatch(before,/bia-v1|Mikka/);
 const duo=a.run("trailStoryMarkup('morro-3')");assert.match(duo,/juninho-v1/);assert.match(duo,/lia-v1/);
 assert.equal(a.run("trailStoryMarkup('morro-1','won')"),'');
 const after=a.run("trailStoryMarkup('morro-1','won',{confirmed:true})");assert.match(after,/zeca-v1/);assert.doesNotMatch(after,/bia-v1/);
});


test('encounter partner choice uses owned inventory and returns to the same briefing after confirmed equipment',async()=>{
 const a=app({member:true});await a.settle();
 a.run(`playerAccount={profile:{id:'choose-owner',nickname:'Ana',equipped_kite_id:'one'},inventory:[{id:'one',model_id:'basica',permanent:true,model:{name:'Carcará',color:0}},{id:'two',model_id:'mata',permanent:true,model:{name:'Mata verde',color:1}}]};onTrailAccountChange=()=>{};onCourtyardAccount=()=>{};onLineAccountChange=()=>{};var resolveChoice;accountRequest=()=>new Promise(resolve=>resolveChoice=resolve);presentStage('morro-1');chooseEncounterPartner('morro-1');`);
 assert.equal(a.document.querySelectorAll('#encounterPartnerList button').length,2);
 const pending=a.document.querySelectorAll('#encounterPartnerList button')[1].onclick();assert.equal(a.run('playerAccount.profile.equipped_kite_id'),'one');
 a.run(`resolveChoice({account:{...playerAccount,profile:{...playerAccount.profile,equipped_kite_id:'two'}}})`);await pending;
 assert.equal(a.run('playerAccount.profile.equipped_kite_id'),'two');assert.match(a.document.getElementById('dialogTitle').textContent,/Praça/);assert.match(a.document.querySelector('.encounter-partner-summary').textContent,/Mata verde/);assert.equal(a.run('mode'),null);
});


test('solo help sits above pause and closes back to the frozen practice menu',async()=>{
 const a=app({seen:true});await a.settle();
 a.run(`var pauseState=eng.create(Date.now());pauseState.players=[eng.player('Ana',0,'pause-local',Date.now())];enter(pauseState,'pause-local','practice');openPause();$('pauseRules').onclick()`);
 assert.equal(a.document.getElementById('modal').classList.contains('pause-help'),true);assert.equal(a.document.getElementById('pauseSheet').inert,true);assert.ok(a.run('pausedAt>0'));
 a.run('closeModal()');assert.equal(a.document.getElementById('pauseSheet').inert,false);assert.equal(a.document.getElementById('pauseSheet').hidden,false);assert.ok(a.run('pausedAt>0'));a.run('closeSheet()');assert.equal(a.run('pausedAt'),0);
});

test('Morro chapter gates require a confirmed account victory and preserve return transitions',async()=>{
 const a=app({seen:true,search:'?overworld=pilot'});await a.settle();
 a.run(`playerAccount={profile:{id:'road-test',nickname:'Teste',level:1},inventory:[]};journey={phase:'complete'};showCourtyard();`);
 await a.run(`trailSync.setUser('road-test')`);
 a.run(`openWorld('morro');worldSyncRoadGate();`);
 assert.equal(a.run('worldRuntime.id'),'morro');assert.equal(a.run('worldState().roadGateClosed'),true);assert.equal(a.run('worldScene().places.filter(p=>p.stage).length'),1);
 a.run(`let gateRenderCount=0;drawWorldRoadGate=()=>gateRenderCount++;drawWorldHuman=()=>{};drawWorldRival=()=>{};$('courtyardCanvas').width=854;$('courtyardCanvas').height=612;drawWorldScene(new Proxy({globalAlpha:1},{get:(o,k)=>k in o?o[k]:(()=>{})}),100,.01);`);assert.equal(a.run('gateRenderCount'),1);
 a.run(`openWorld('morro-area-2')`);assert.equal(a.run('worldRuntime.id'),'morro');
 const stars={};for(let i=1;i<=5;i++){stars['morro-'+i]=1;a.run('trailSync.accept('+JSON.stringify({revision:i,progress:{stars}})+',"road-test");worldSyncRoadGate();');assert.equal(a.run('worldState().roadGateClosed'),false);if(i<5){a.run(`worldRuntime.near=worldScene().places.find(p=>p.action==='road_next');interactWorld();`);assert.equal(a.run('worldRuntime.id'),'morro-area-'+(i+1));if(i===2){a.run(`returnToDistrict('morro-3',false);worldSyncRoadGate();`);assert.equal(a.run('worldRuntime.id'),'morro-area-3');assert.equal(a.run('worldState().roadGateClosed'),true);}}}
 a.run(`worldRuntime.near=worldScene().places.find(p=>p.action==='road_back');interactWorld();`);assert.equal(a.run('worldRuntime.id'),'morro-area-4');assert.equal(a.run('worldState().actor.level'),1);
 await a.run(`trailSync.setUser('other-owner')`);a.run(`playerAccount={profile:{id:'other-owner',nickname:'Outro',level:1},inventory:[]};refreshWorldHUD();openWorld('morro-area-5');`);assert.equal(a.run('worldRuntime.id'),'quintal');
});

test('partner class tab shows locked silhouettes and requirements without mutating collection on selection',async()=>{
 const a=app({seen:true,reduced:true});await a.settle();
 const account={profile:{id:'class-ui',nickname:'Kael',level:1,cuts:0,equipped_kite_id:'rabbit'},inventory:[{id:'rabbit',model_id:'rabbito',pipamon_xp:120,class_version:0,model:{name:'Rabbito',color:0,soul:'rabbito',acquisition:'event'}}]};
 a.run('playerAccount='+JSON.stringify(account)+";accountModal.style.display='flex';renderAccountDialog();navigateClub('collection');var classUiCalls=[];accountRequest=async(action,body)=>{classUiCalls.push({action,body});return {classes:{version:0,current:'base',nodes:[{id:'rabbitknight',branch:'rabbitknight',rank:1,name:'Rabbitknight',description:'Classe especial sem evoluções',x:82,y:48,min_level:25,stat:'attack',threshold:1.05,actualStat:1,item:'mascara-do-guerreiro',unlocked:false,hasParent:true}],items:{},parkWins:0}}};");
 assert.equal(a.run('classUiCalls.length'),0,'collection preview does not request or mutate classes');
 a.document.getElementById('inventory-detail-tab-2').onclick();await a.settle();
 assert.equal(a.document.getElementById('inventory-detail-tab-2').getAttribute('aria-selected'),'true');assert.ok(a.document.getElementById('inventoryDetails').classList.contains('class-constellation-active'));
 const node=a.document.querySelector('[data-class-node="rabbitknight"]');assert.ok(node.classList.contains('silhouette'));node.onclick();
 assert.match(a.document.querySelector('.class-node-detail').textContent,/Nível 25/);assert.match(a.document.querySelector('.class-node-detail').textContent,/Máscara do Guerreiro/);assert.equal(a.document.querySelector('.class-confirm').disabled,true);
 assert.equal(a.run('classUiCalls.length'),1);assert.equal(a.run('classUiCalls[0].body.nodeId'),undefined,'choosing a node is inspection only');
 assert.equal(a.run('playerAccount.inventory[0].class_version'),0);assert.equal(a.run('homeMenuGroups.clubGroup.some(([id])=>id==="classes")'),false);
 a.document.getElementById('inventory-detail-tab-0').onclick();assert.equal(a.document.getElementById('inventoryDetails').classList.contains('class-constellation-active'),false);
});
