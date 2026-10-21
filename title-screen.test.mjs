import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {parseHTML} from 'linkedom';
import {shouldShowRuinsTitle,createRuinsTitle,createRuinsArt} from './src/title-screen.js';
import {artConfig} from './scripts/art-build.mjs';
import {createAssetHandler} from './src/static-assets.js';

test('title preserves room invitations, account recovery, audit routes and per-tab continuation',()=>{
 const at=(search='',hash='',pathname='/')=>({search,hash,pathname});
 assert.equal(shouldShowRuinsTitle(at()),true);
 assert.equal(shouldShowRuinsTitle(at(),true),false);
 assert.equal(shouldShowRuinsTitle(at('?title=1'),true),true);
 assert.equal(shouldShowRuinsTitle(at('?title=0')),false);
 for(const search of ['?sala=ABCDEF','?code=recovery','?type=recovery','?token_hash=redacted','?title=1&sala=ABCDEF'])assert.equal(shouldShowRuinsTitle(at(search)),false);
 assert.equal(shouldShowRuinsTitle(at('','#access_token=redacted')),false);
 for(const path of ['/menu-audit','/hud-audit','/hud-kit'])assert.equal(shouldShowRuinsTitle(at('','',path)),false);
 assert.equal(shouldShowRuinsTitle(at('','','/PipaKlub/')),true);
});

function harness({reduced=false,native=true,storageBroken=false}={}){
 const {document}=parseHTML('<html><body><main><button id="play">Jogar</button></main></body></html>'),create=document.createElement.bind(document),handlers=new Map(),timers=[],frames=new Map(),cancelled=[],memory=new Map();let count=0,started=0,pad=null;
 document.createElement=name=>{const el=create(name);if(name==='dialog'&&native){el.showModal=()=>{el.open=true;el.setAttribute('open','');};el.close=()=>{el.open=false;el.removeAttribute('open');};}return el;};
 const media={matches:reduced,addEventListener(){},removeEventListener(){}};
 const host={matchMedia:()=>media,addEventListener:(type,fn)=>handlers.set(type,fn),removeEventListener:type=>handlers.delete(type),setTimeout:fn=>{timers.push(fn);return timers.length;},clearTimeout(){},navigator:{getGamepads:()=>pad?[pad]:[]}};
 const args={document,host,location:{pathname:'/',search:'',hash:''},assets:{background:{url:'assets/ruins.png'},presence:{url:'assets/presence.png'}},storage:{getItem:k=>{if(storageBroken)throw Error('blocked');return memory.get(k);},setItem:(k,v)=>{if(storageBroken)throw Error('blocked');memory.set(k,v);}},requestFrame:fn=>{frames.set(++count,fn);return count;},cancelFrame:id=>{cancelled.push(id);frames.delete(id);},onStart:()=>started++};
 const fireKey=(key,extra={})=>{let prevented=false,stopped=false;handlers.get('keydown')?.({key,preventDefault(){prevented=true;},stopImmediatePropagation(){stopped=true;},...extra});return {prevented,stopped};};
 return {document,args,host,handlers,timers,frames,memory,media,fireKey,setPad:p=>pad=p,get started(){return started;}};
}

test('Start is idempotent, closes the native modal and persists only presentation state',()=>{
 const h=harness(),title=createRuinsTitle(h.args);
 assert.equal(title.element.open,true);assert.ok(h.document.body.classList.contains('in-title'));
 assert.equal(h.fireKey('ArrowRight').stopped,true);
 assert.equal(h.fireKey('Tab').prevented,false);
 assert.equal(h.fireKey('r',{ctrlKey:true}).prevented,false);
 h.fireKey('Enter');title.start();assert.equal(h.timers.length,1);assert.equal(title.started,true);
 assert.equal(h.memory.get('soulmonsters-title-v1'),'seen');
 h.timers[0]();title.finish();assert.equal(h.started,1);assert.equal(h.document.getElementById('ruinsTitle'),null);
 assert.equal(h.document.body.classList.contains('in-title'),false);assert.equal(h.handlers.has('keydown'),false);assert.equal(h.frames.size,0);
 assert.equal(createRuinsTitle(h.args),null,'same-tab continuation skips title');
});

test('reduced motion, pause, missing art and unavailable storage keep Start usable',()=>{
 const h=harness({reduced:true,storageBroken:true}),title=createRuinsTitle(h.args);
 assert.equal(title.element.querySelector('.ruins-motion').hidden,true);assert.ok(title.element.classList.contains('ruins-paused'));
 title.element.querySelector('.ruins-background').dispatchEvent(new h.document.defaultView.Event('error'));
 title.element.querySelector('.ruins-presence').dispatchEvent(new h.document.defaultView.Event('error'));
 assert.equal(title.element.querySelector('.ruins-presence').hidden,true);
 h.fireKey(' ');assert.equal(h.started,1);assert.equal(h.timers.length,0);
 const p=harness(),second=createRuinsTitle(p.args),button=second.element.querySelector('.ruins-motion');
 p.fireKey('Enter',{target:button});assert.equal(button.getAttribute('aria-pressed'),'true');assert.equal(second.started,false);
 second.start();p.timers[0]();assert.equal(p.started,1);
 const old=harness({native:false});assert.equal(createRuinsTitle(old.args),null);assert.equal(old.document.body.classList.contains('in-title'),false);
});

test('gamepad Start closes once and never dispatches a battle or menu action',()=>{
 const h=harness({reduced:true}),title=createRuinsTitle(h.args),buttons=Array.from({length:10},()=>({pressed:false}));buttons[9].pressed=true;
 h.setPad({connected:true,buttons});const [id,frame]=[...h.frames][0];h.frames.delete(id);frame();
 assert.equal(title.started,true);assert.equal(h.started,1);assert.equal(h.frames.size,0);
});

test('opening and entry menu use separate living-art filters, and pausing stops SVG motion too',()=>{
 const h=harness(),title=createRuinsTitle(h.args),menu=createRuinsArt(h.document,h.args.assets,'menu');
 assert.equal(menu.querySelector('filter').id,'ruins-life-menu');
 assert.equal(title.element.querySelector('filter').id,'ruins-life-title');
 assert.equal(menu.querySelectorAll('.ruins-motes i').length,12);
 assert.equal(menu.querySelector('.ruins-presence').src,title.element.querySelector('.ruins-presence').src);
 const svg=title.element.querySelector('.ruins-life');let pauses=0,resumes=0;
 svg.pauseAnimations=()=>pauses++;svg.unpauseAnimations=()=>resumes++;
 const button=title.element.querySelector('.ruins-motion');button.click();button.click();
 assert.equal(pauses,1);assert.equal(resumes,1);
 menu.querySelector('.ruins-presence').dispatchEvent(new h.document.defaultView.Event('error'));
 assert.equal(menu.querySelector('.ruins-guardian').hidden,true,'failed art cannot leave floating lights behind');
 title.finish();
});

test('both original title layers ship with hash caching and remain independent from runtime text',async()=>{
 const config=artConfig(),serve=createAssetHandler();
 for(const key of ['title-background','title-presence']){
  const def=config.courtyard.images[key],png=fs.readFileSync('assets/'+def.image);
  assert.ok(png.readUInt32BE(16)>1000);assert.ok(png.readUInt32BE(20)>600);
  assert.deepEqual(fs.readFileSync('docs/assets/'+def.image),png);
  const result=await serve(new Request('https://test/'+def.url,{method:'HEAD'}));assert.equal(result.status,200);assert.match(result.headers.get('cache-control'),/immutable/);
 }
 const html=fs.readFileSync('docs/index.html','utf8');assert.ok(html.includes('Pressione Start'));assert.ok(html.includes('Elo das Ruínas'));assert.ok(!html.includes('/* TITLE_SCREEN_CLIENT */'));
});
