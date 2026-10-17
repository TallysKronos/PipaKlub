import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import {parseHTML} from 'linkedom';
import {createAssetHandler} from './src/static-assets.js';
import {artConfig} from './scripts/art-build.mjs';

function app({seen=false,search='',failed=false,reduced=false}={}){
 const html=fs.readFileSync('docs/index.html','utf8'),{document}=parseHTML(html),timers=[],requests=[],draws=[],listeners=new Map(),storage=new Map(seen?[['pipaAssisIntroV1','done']]:[]);
 for(const canvas of document.querySelectorAll('canvas'))canvas.getContext=()=>({clearRect(){},drawImage(...args){draws.push({canvas:canvas.id,args});},imageSmoothingEnabled:true});
 const context=vm.createContext({document,console,crypto,Date,Intl,URLSearchParams,AbortController,performance:{now:()=>100},location:{search,hash:'',pathname:'/',protocol:'https:',host:'test'},history:{replaceState(){}},localStorage:{getItem:k=>storage.get(k)??null,setItem:(k,v)=>storage.set(k,v)},matchMedia:()=>({matches:reduced}),ResizeObserver:class{observe(){}},requestAnimationFrame(){},setInterval(){},clearInterval(){},setTimeout(fn,delay){timers.push({fn,delay});return timers.length;},clearTimeout(){},fetch:async()=>({ok:true,json:async()=>({enabled:false})}),Image:class{set src(url){requests.push(url);queueMicrotask(()=>failed?this.onerror():this.onload());}},addEventListener(name,fn){if(!listeners.has(name))listeners.set(name,[]);listeners.get(name).push(fn);}});
 vm.runInContext(html.match(/<script>([\s\S]*?)<\/script>/)[1],context);
 return {document,requests,draws,storage,run:code=>vm.runInContext(code,context),auto:()=>timers.find(t=>t.delay===650).fn(),settle:()=>new Promise(r=>setImmediate(r)),key:key=>{for(const fn of listeners.get('keydown'))fn({key,target:{tagName:'BODY'},preventDefault(){},stopImmediatePropagation(){}});}};
}
test('new visitors meet Assis, all eight steps swap artwork, finish starts training and replay remains available',async()=>{
 const a=app();await a.settle();assert.equal(a.requests.length,1);a.auto();await a.settle();assert.equal(a.document.getElementById('assisIntro').hidden,false);assert.match(a.document.getElementById('assisSpeech').textContent,/Nozinho/);assert.equal(a.requests.length,4);assert.match(a.document.getElementById('assisLoad').textContent,/pesquisador/);
 const expressions=new Set(),poses=new Set();for(let i=0;i<8;i++){expressions.add(a.run('ART_CONFIG.intro.steps[introductionStep].expression'));poses.add(a.run('ART_CONFIG.intro.steps[introductionStep].pose'));a.document.getElementById('assisNext').onclick();}
 assert.equal(expressions.size,8);assert.equal(poses.size,8);assert.equal(a.run('mode'),'practice');assert.equal(a.document.getElementById('assisIntro').hidden,true);assert.equal(a.storage.get('pipaAssisIntroV1'),'done');assert.ok(a.draws.some(d=>d.canvas==='assisBody'));assert.ok(a.draws.some(d=>d.canvas==='assisFace'));assert.ok(a.draws.some(d=>d.canvas==='assisCompanion'));
 a.run('leave()');a.document.getElementById('how').onclick();await a.settle();assert.equal(a.requests.length,4);assert.equal(a.document.getElementById('assisIntro').hidden,false);
});
test('skip, invitations, keyboard blocking and image failure do not prevent playing',async()=>{
 for(const options of [{seen:true},{search:'?sala=ABCDEF'}]){const a=app(options);a.auto();await a.settle();assert.equal(a.run('introductionOpen'),false);}
 const a=app({failed:true});a.auto();await a.settle();assert.equal(a.document.getElementById('assisRetry').hidden,false);assert.match(a.document.getElementById('assisLoad').textContent,/não carregaram/);a.key('e');assert.equal(a.run('input().skill'),0);a.document.getElementById('assisSkip').onclick();assert.equal(a.run('introductionOpen'),false);a.run("$('practice').onclick()");assert.equal(a.run('mode'),'practice');assert.equal(a.run("art.creature({},0,0)"),false);
});
test('arena draws actual atlas frames, restores smoothing, and reduced motion freezes the selected creature',async()=>{
 const a=app({reduced:true,seen:true});await a.settle();a.run("art.creature($('sky').getContext('2d'),2,0)");a.run("art.creature($('sky').getContext('2d'),2,1200)");const d=a.draws.filter(d=>d.canvas==='sky');assert.equal(d.length,2);assert.deepEqual(d[0].args.slice(1),d[1].args.slice(1));assert.match(a.run('kiteSVG(colors[2])'),/almatic-icon/);assert.match(a.run('kiteSVG(colors[2])'),/idle\.png\?v=/);
});
test('asset route serves every real PNG with hash caching, HEAD and ETag; unknown files cannot be read',async()=>{
 const serve=createAssetHandler();for(const a of Object.values(artConfig().atlases)){const url='https://game.test/'+a.meta.url,r=await serve(new Request(url));assert.equal(r.status,200);assert.equal(r.headers.get('content-type'),'image/png');assert.match(r.headers.get('cache-control'),/immutable/);const bytes=new Uint8Array(await r.arrayBuffer());assert.deepEqual([...bytes.slice(0,8)],[137,80,78,71,13,10,26,10]);const head=await serve(new Request(url,{method:'HEAD'}));assert.equal((await head.arrayBuffer()).byteLength,0);const cached=await serve(new Request(url,{headers:{'if-none-match':r.headers.get('etag')}}));assert.equal(cached.status,304);const file='docs/'+a.meta.url.split('?')[0];assert.ok(fs.existsSync(file));assert.deepEqual(fs.readFileSync(file),Buffer.from(bytes));}
 assert.equal((await serve(new Request('https://game.test/assets/.env'))).status,404);assert.equal((await serve(new Request('https://game.test/assets/characters/sr-assis/poses.png',{method:'POST'}))).status,405);assert.equal(await serve(new Request('https://game.test/api/create')),null);
});

test('special Souls load only on demand and animate all five states using their real atlas rectangles',async()=>{
 const a=app({seen:true});await a.settle();assert.equal(a.requests.length,1);
 for(const soul of ['flautrevo','trinca-brasas','alvaneve','chaspiral']){
  a.run("art.load('"+soul+"')");await a.settle();
  for(const [state,extra,victory] of [['idle',{},false],['flight',{input:{x:1}},false],['skill',{skillCooldown:6.7},false],['hurt',{hitFlash:.05},false],['victory',{},true]]){
   const time=200,p={soul,...extra};a.run("art.creature($('sky').getContext('2d'),0,"+time+",-56,-44,112,"+JSON.stringify(p)+","+victory+")");
   const actual=a.draws.at(-1).args.slice(1,5),atlas=artConfig().atlases[soul];
   assert.ok(atlas.animations[state].some(key=>{const f=atlas.frames[key].frame;return JSON.stringify(actual)===JSON.stringify([f.x,f.y,f.w,f.h]);}),soul+' '+state);
  }
 }
 assert.equal(a.requests.length,5);
 assert.match(a.run("art.markup(0,'alvaneve')"),/especiais\/alvaneve\.png/);
 assert.ok(!a.run("art.markup(0,'<script>')").includes('<script>'));
 const account={profile:{nickname:'Ana',level:1,xp:0,next_level_xp:100,cuts:0,equipped_kite_id:'owned'},inventory:[{id:'owned',model_id:'alvaneve',permanent:true,model:{name:'Alvaneve',color:0,soul:'alvaneve',acquisition:'event'}}]};
 a.run('playerAccount='+JSON.stringify(account)+';reflectAccount();renderAccountDialog();');
 assert.equal(a.document.querySelectorAll('#eventSoulsList .event-locked').length,3);
 assert.match(a.document.getElementById('inventoryList').textContent,/Especial de evento/);
 assert.match(a.document.getElementById('selectionName').textContent,/Alvaneve/);
 a.run("$('practice').onclick()");assert.equal(a.run("state.players.find(p=>p.id==='you').soul"),'alvaneve');
});
