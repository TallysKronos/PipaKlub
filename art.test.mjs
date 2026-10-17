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
 assert.equal(entries.length,24);assert.equal(new Set(entries.map(e=>e.id)).size,24);
 for(const e of entries){
  const a=config.atlases[e.atlas],v=a.meta.viewport;assert.equal(e.model,e.id);assert.ok(e.color>=0&&e.color<=3);
  assert.ok(v&&v.w>0&&v.h>0);assert.equal(Object.keys(a.frames).length,16);
  for(const f of Object.values(a.frames)){const b=f.contentBounds;assert.ok(v.x<=b.x&&v.y<=b.y);assert.ok(v.x+v.w>=b.x+b.w&&v.y+v.h>=b.y+b.h);assert.ok(v.x+v.w<=f.frame.w&&v.y+v.h<=f.frame.h);}
  assert.equal(Object.keys(a.animations).length,5);assert.ok(e.story.length>0);
 }
});

function app({seen=false,search='',failed=false,reduced=false,member=false}={}){
 const html=fs.readFileSync('docs/index.html','utf8'),{document}=parseHTML(html),timers=[],requests=[],draws=[],listeners=new Map(),storage=new Map(seen?[['pipaAssisIntroV1','done']]:[]);
 for(const canvas of document.querySelectorAll('canvas'))canvas.getContext=()=>({clearRect(){},drawImage(...args){draws.push({canvas:canvas.id,args});},imageSmoothingEnabled:true});
 const context=vm.createContext({document,console,crypto,Date,Intl,URLSearchParams,AbortController,performance:{now:()=>100},location:{search,hash:'',pathname:'/',protocol:'https:',host:'test'},history:{replaceState(){}},localStorage:{getItem:k=>storage.get(k)??null,setItem:(k,v)=>storage.set(k,v)},matchMedia:()=>({matches:reduced}),ResizeObserver:class{observe(){}},requestAnimationFrame(){},setInterval(){},clearInterval(){},setTimeout(fn,delay){timers.push({fn,delay});return timers.length;},clearTimeout(){},fetch:async()=>({ok:true,json:async()=>({enabled:false})}),Image:class{set src(url){requests.push(url);queueMicrotask(()=>failed?this.onerror():this.onload());}},addEventListener(name,fn){if(!listeners.has(name))listeners.set(name,[]);listeners.get(name).push(fn);}});
 vm.runInContext(html.match(/<script>([\s\S]*?)<\/script>/)[1],context);
 if(member)vm.runInContext('playerAccount={profile:{nickname:"Ana",level:1},inventory:[]}',context);
 context.cancelAnimationFrame=()=>{};
 // Linkedom exposes select.value as read-only; browsers implement a setter.
 for(const select of document.querySelectorAll('select')){let value;Object.defineProperty(select,'value',{configurable:true,get(){return value??this.querySelector('option[selected]')?.value??this.querySelector('option')?.value??'';},set(next){value=next;}});}
 return {document,requests,draws,storage,run:code=>vm.runInContext(code,context),auto:()=>timers.find(t=>t.delay===650).fn(),settle:()=>new Promise(r=>setImmediate(r)),key:key=>{for(const fn of listeners.get('keydown'))fn({key,target:{tagName:'BODY'},preventDefault(){},stopImmediatePropagation(){}});}};
}
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

test('new members meet Assis, all eight steps swap artwork, finish opens the school tour and replay remains available',async()=>{
 const a=app({member:true});await a.settle();assert.equal(a.requests.length,1);a.auto();await a.settle();assert.equal(a.document.getElementById('assisIntro').hidden,false);assert.match(a.document.getElementById('assisSpeech').textContent,/Nozinho/);assert.equal(a.requests.length,4);assert.match(a.document.getElementById('assisLoad').textContent,/pesquisador/);
 const expressions=new Set(),poses=new Set();for(let i=0;i<8;i++){expressions.add(a.run('ART_CONFIG.intro.steps[introductionStep].expression'));poses.add(a.run('ART_CONFIG.intro.steps[introductionStep].pose'));a.document.getElementById('assisNext').onclick();}
 assert.equal(expressions.size,8);assert.equal(poses.size,8);assert.equal(a.run('mode'),null);assert.equal(a.document.getElementById('schoolTourOverlay').hidden,false);assert.equal(a.document.getElementById('assisIntro').hidden,true);assert.equal(a.storage.get('pipaAssisIntroV1'),'done');assert.ok(a.draws.some(d=>d.canvas==='assisBody'));assert.ok(a.draws.some(d=>d.canvas==='assisFace'));assert.ok(a.draws.some(d=>d.canvas==='assisCompanion'));
 a.run('closeSchoolTour();closeSchool();leave()');a.document.getElementById('how').onclick();await a.settle();assert.equal(a.requests.length,4);assert.equal(a.document.getElementById('assisIntro').hidden,false);
});
test('skip, invitations, keyboard blocking and image failure do not prevent playing',async()=>{
 for(const options of [{seen:true},{search:'?sala=ABCDEF'}]){const a=app(options);a.auto();await a.settle();assert.equal(a.run('introductionOpen'),false);}
 const a=app({failed:true,member:true});a.auto();await a.settle();assert.equal(a.document.getElementById('assisRetry').hidden,false);assert.match(a.document.getElementById('assisLoad').textContent,/não carregaram/);a.key('e');assert.equal(a.run('input().skill'),0);a.document.getElementById('assisSkip').onclick();assert.equal(a.run('introductionOpen'),false);a.run("$('practice').onclick()");assert.equal(a.run('mode'),'practice');assert.equal(a.run("art.creature({},0,0)"),false);
});
test('arena draws actual atlas frames, restores smoothing, and reduced motion freezes the selected creature',async()=>{
 const a=app({reduced:true,seen:true});await a.settle();a.run("art.creature($('sky').getContext('2d'),2,0)");a.run("art.creature($('sky').getContext('2d'),2,1200)");const d=a.draws.filter(d=>d.canvas==='sky');assert.equal(d.length,2);assert.deepEqual(d[0].args.slice(1),d[1].args.slice(1));assert.match(a.run('kiteSVG(colors[2])'),/almatic-icon/);assert.match(a.run('kiteSVG(colors[2])'),/idle\.png\?v=/);
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
 const a=app({seen:true});await a.settle();assert.equal(a.requests.length,1);
 for(const soul of artConfig().dex.entries.filter(e=>e.group==='event').map(e=>e.id)){
  a.run("art.load('"+soul+"')");await a.settle();
  for(const [state,extra,victory] of [['idle',{},false],['flight',{input:{x:1}},false],['skill',{skillCooldown:6.7},false],['hurt',{hitFlash:.05},false],['victory',{},true]]){
   const time=200,p={soul,...extra};a.run("art.creature($('sky').getContext('2d'),0,"+time+",-56,-44,112,"+JSON.stringify(p)+","+victory+")");
   const actual=a.draws.at(-1).args.slice(1,5),atlas=artConfig().atlases[soul];
   assert.ok(atlas.animations[state].some(key=>{const f=atlas.frames[key].frame,v=atlas.meta.viewport;return JSON.stringify(actual)===JSON.stringify(v?[f.x+v.x,f.y+v.y,v.w,v.h]:[f.x,f.y,f.w,f.h]);}),soul+' '+state);
  }
 }
 assert.equal(a.requests.length,29);
 assert.match(a.run("art.markup(0,'alvaneve')"),/especiais\/alvaneve\.png/);
 assert.ok(!a.run("art.markup(0,'<script>')").includes('<script>'));
 const account={profile:{nickname:'Ana',level:1,xp:0,next_level_xp:100,cuts:0,equipped_kite_id:'owned'},inventory:[{id:'owned',model_id:'alvaneve',permanent:true,model:{name:'Alvaneve',color:0,soul:'alvaneve',acquisition:'event'}}]};
 a.run('playerAccount='+JSON.stringify(account)+';reflectAccount();renderAccountDialog();');
 assert.equal(a.document.querySelectorAll('#eventSoulsList .event-locked').length,27);
 assert.match(a.document.getElementById('inventoryList').textContent,/Especial de evento/);
 assert.match(a.document.getElementById('selectionName').textContent,/Alvaneve/);
 a.run("$('practice').onclick()");assert.equal(a.run("state.players.find(p=>p.id==='you').soul"),'alvaneve');
});

test('member Pipa Dex lists all creatures, searches accents, filters and previews without unlocking inventory',async()=>{
 const a=app();await a.settle();a.run('playerAccount={profile:{},inventory:[]}');a.document.getElementById('workshop').onclick();await a.settle();a.auto();assert.equal(a.run('introductionOpen'),false);
 assert.equal(a.document.getElementById('pipaDex').hidden,false);
 assert.equal(a.document.querySelectorAll('#dexList button').length,33);
 assert.equal(a.document.getElementById('dexName').textContent,'Carcará');
 assert.equal(a.document.querySelectorAll('#dexAnimation option').length,1);
 a.run("$('dexSearch').value='azulao';filterDex()");await a.settle();
 assert.equal(a.document.getElementById('dexName').textContent,'Azulão');
 assert.match(a.document.getElementById('dexStory').textContent,/chuva/);
 a.run("$('dexSearch').value='';$('dexFilter').value='event';filterDex()");await a.settle();
 assert.equal(a.document.querySelectorAll('#dexList button').length,28);
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
 const config=artConfig();assert.equal(config.items.length,33);assert.equal(new Set(config.items.map(i=>i.image)).size,33);
 for(const entry of config.dex.entries){
  a.run('selectDex(dexEntries.find(e=>e.id==='+JSON.stringify(entry.id)+'))');
  const root=a.document.getElementById('dexItemsSection'),cards=root.querySelectorAll('.dex-item');assert.equal(root.hidden,false);assert.equal(cards.length,1);
  const item=config.items.find(i=>i.id===entry.items[0]);assert.equal(item.pipamon,entry.id);assert.equal(item.name,'Rabiola de '+entry.name);
  const image=cards[0].querySelector('img');assert.equal(image.getAttribute('src'),item.url);assert.equal(image.alt,item.name);assert.equal(image.loading,'lazy');
  if(entry.group==='companion'){assert.equal(item.source,'companion');assert.match(root.textContent,/não aparece como selvagem/);assert.doesNotMatch(root.textContent,/Drop previsto/);}
  else{assert.equal(item.source,'wild');assert.match(root.textContent,new RegExp(entry.name+' selvagem'));
   // Rabiolas dropped by trail bosses say where to earn them; the rest are still coming.
   if(['rabiola-raio-de-sol','rabiola-chaspiral','rabiola-flautrevo'].includes(item.id))assert.match(root.textContent,/Prêmio: .+ \(Trilhas\)/);else assert.match(root.textContent,/Em breve/);}
 }
 const failed=a.document.querySelector('#dexItemsList img'),fallback=a.document.querySelector('.dex-item-fallback');failed.onerror();assert.equal(failed.hidden,true);assert.equal(fallback.hidden,false);assert.match(a.document.getElementById('dexItemsList').textContent,/Rabiola de Nozinho/);
 a.run('selectDex(dexEntries[0])');assert.equal(a.document.querySelector('.dex-item-fallback').hidden,true);assert.equal(a.run('playerAccount.inventory.length'),0);assert.equal(a.run('mode'),null);
});

test('all tail PNGs are published with content hashes, HEAD and cache validation',async()=>{
 const serve=createAssetHandler();
 for(const item of artConfig().items){
  const url='https://game.test/'+item.url,r=await serve(new Request(url));assert.equal(r.status,200);assert.match(r.headers.get('cache-control'),/immutable/);assert.equal(r.headers.get('content-type'),'image/png');
  const bytes=Buffer.from(await r.arrayBuffer());assert.equal(bytes.readUInt32BE(16),209);assert.equal(bytes.readUInt32BE(20),209);assert.equal(bytes[25],6);
  assert.deepEqual(fs.readFileSync('docs/assets/'+item.image),bytes);
  assert.equal((await serve(new Request(url,{method:'HEAD'}))).status,200);
  assert.equal((await serve(new Request(url,{headers:{'if-none-match':r.headers.get('etag')}}))).status,304);
 }
 assert.equal((await serve(new Request('https://game.test/assets/items/rabiolas/unknown.png'))).status,404);
});
