import test from 'node:test';
import assert from 'node:assert/strict';
import {createEngine} from './src/engine.js';
import {createNetworkView} from './src/network-view.js';
const e=createEngine();
// The test duel crosses at an open angle with a still kite: a clean golden-centre cut, 24 x 1.2 = 28.8.
const CLEAN=100-24*1.2;
test('facing follows horizontal steering and dash, persists at rest, and reaches network observers',()=>{
 const p=e.player('Direção',1,'facing',1000);
 e.move(p,{x:-1},.1);assert.equal(p.facing,-1);
 e.move(p,{y:1},.1);assert.equal(p.facing,-1);
 e.move(p,{x:.01},.1);assert.equal(p.facing,-1,'tiny analog noise does not turn the character');
 e.move(p,{},.1);assert.equal(p.facing,-1);
 e.move(p,{x:1},.1);assert.equal(p.facing,1);
 e.move(p,{skill:-1},0);assert.equal(p.facing,-1);
 const s=e.create(1000);s.players=[p];assert.equal(e.visible(s).players[0].facing,-1);
 const view=createNetworkView(e);view.receive(s,p.id,1000);assert.equal(view.render(1016,{x:1},.016)[0].facing,1,'own prediction turns immediately');
 assert.equal(p.facing,-1,'prediction does not change authority');
});
function duel(){const s=e.create(1000),a=e.player('A',0,'a',1000),b=e.player('B',1,'b',1000);Object.assign(a,{x:700,y:180,anchorX:90,input:{cut:true}});Object.assign(b,{x:300,y:180,anchorX:910});s.players=[a,b];return {s,a,b};}

test('a captured collectible falls back to the owned story partner with its species, name and level',()=>{
 const {s,b}=duel();s.rules='capture';Object.assign(b,{hp:1,accountId:'owner',kiteId:'collectible',basicKiteId:'story',basicSoul:'rabbito',basicColor:0,basicPartnerName:'Pingo',basicPipamonLevel:4});
 e.step(s,1034);assert.equal(b.kiteId,'story');assert.equal(b.soul,'rabbito');assert.equal(b.partnerName,'Pingo');assert.equal(b.pipamonLevel,4);assert.equal(b.kitePermanent,true);
});

test('only a valid line crossing deals damage; kite proximity, ground intersections and parallel lines do not',()=>{
 const {s,a,b}=duel();assert.ok(e.contact(a,b).valid);e.step(s,1034);assert.ok(Math.abs(b.hp-CLEAN)<1e-9);assert.equal(a.hp,100);
 const nearby=duel();nearby.a.x=400;nearby.b.x=401;nearby.a.y=nearby.b.y=200;e.step(nearby.s,1034);assert.equal(nearby.b.hp,100);
 const parallel=duel();parallel.b.anchorX=90;parallel.a.x=parallel.b.x=400;e.step(parallel.s,1034);assert.equal(parallel.b.hp,100);
 const ground=duel();ground.a.x=900;ground.b.x=100;ground.b.anchorX=110;assert.equal(e.contact(ground.a,ground.b),null);e.step(ground.s,1034);assert.equal(ground.b.hp,100);
});
test('one pull hits one target, misses cost energy, cooldown and low energy prevent spam',()=>{
 const {s,a,b}=duel(),c={...b,id:'c'};s.players.push(c);e.step(s,1034);assert.ok(Math.abs(b.hp-CLEAN)<1e-9);assert.equal(c.hp,100);const hp=b.hp;e.step(s,1068);assert.equal(b.hp,hp);
 a.attackCooldown=0;a.energy=11;e.step(s,1100);assert.equal(b.hp,hp);a.energy=100;a.x=80;a.attackCooldown=0;e.step(s,1134);assert.ok(a.energy<90);assert.equal(b.hp,hp);
});
test('simultaneous fatal strikes resolve identically when player order is reversed',()=>{
 for(const reverse of [false,true]){const {s,a,b}=duel();a.hp=b.hp=1;b.input={cut:true};if(reverse)s.players.reverse();e.step(s,1034);assert.equal(a.cuts,1);assert.equal(b.cuts,1);assert.ok(a.respawn&&b.respawn);assert.equal(s._pendingCuts.length,2);assert.equal(new Set(s.events.map(x=>x.id)).size,2);}
});
test('precision is consumed once, guard reduces damage, focus opens a previously invalid crossing',()=>{
 const precise=duel();precise.a.input={cut:true,skill:1};e.step(precise.s,1034);assert.ok(Math.abs(precise.b.hp-(CLEAN-8))<1e-9);assert.equal(precise.a.skillTime,0);
 const guard=duel();guard.b.color=2;guard.b.input={skill:1};e.step(guard.s,1034);assert.ok(Math.abs(guard.b.hp-(100-24*1.2*.4))<.001);
 const {a,b}=duel();a.color=3;let found=false;
 for(let y=80;y<460;y+=10)for(let x=100;x<900;x+=10){a.x=x;a.y=y;a.skillTime=0;const before=e.contact(a,b);a.skillTime=1;const after=e.contact(a,b);if(before&&!before.valid&&after?.valid){found=true;break;}}
 assert.ok(found,'focus must expand the enemy vulnerability zone');
});
test('dash obeys direction, arena limits, cost, cooldown and input sanitization',()=>{
 for(const direction of [-1,1]){const p=e.player('Dash',1,'dash',0);p.x=500;e.move(p,{skill:direction,hp:999,damage:999},0);assert.equal(p.x,500+96*direction);assert.equal(p.energy,75);assert.equal(p.skillCount,1);e.move(p,{skill:-direction},.1);assert.equal(p.skillCount,1);assert.equal(p.x,500+96*direction);}
 const p=e.player('Edge',1,'edge',0);p.x=940;e.move(p,{skill:1},0);assert.equal(p.x,945);p.skillCooldown=0;p.energy=24;e.move(p,{skill:-1},0);assert.equal(p.x,945);
 assert.deepEqual(e.sanitizeInput({x:Infinity,y:-99,skill:99,damage:999}),{x:0,y:-1,cut:false,skill:0,dodge:false});
});
test('prediction does not repeat a dash when an older authority snapshot arrives',()=>{
 const {s,a}=duel();a.color=1;a.x=400;a.input={};const view=createNetworkView(e);view.receive(structuredClone(s),'a',0,200);
 assert.equal(view.render(16,{skill:1},.016).find(p=>p.id==='a').x,496);
 view.receive(structuredClone(s),'a',50,200);
 const after=view.render(66,{skill:1},.016).find(p=>p.id==='a');assert.equal(after.x,496);assert.equal(after.skillCount,1);
});
test('damage remains comparable at 30 and 60 Hz, and releasing attack recovers energy without repairing line',()=>{
 const run=hz=>{const {s,a,b}=duel();b.hp=1000;for(let i=1;i<=hz*2;i++)e.step(s,1000+i*1000/hz);return {a,b,s};};
 const a=run(30),b=run(60);assert.equal(a.b.hp,b.b.hp);assert.ok(Math.abs(a.a.energy-b.a.energy)<1);
 a.a.input={};const energy=a.a.energy,hp=a.a.hp;e.step(a.s,a.s.last+100);assert.ok(a.a.energy>energy);assert.equal(a.a.hp,hp);
});
test('anchors are stable, distinct across eight seats and not selected by a forged input',()=>{
 const s=e.create();for(let i=0;i<8;i++){const p=e.player('P',i%4,'p'+i,Date.now());e.seat(s,p);s.players.push(p);}assert.equal(new Set(s.players.map(p=>p.anchorX)).size,8);const a=s.players[0],x=a.anchorX;e.move(a,{anchorX:910,type:3},.1);assert.equal(a.anchorX,x);assert.equal(a.color,0);
});

test('real page handlers preserve a quick skill tap for the next network frame and reset it between matches',async()=>{
 const {parseHTML}=await import('linkedom'),fs=await import('node:fs'),vm=await import('node:vm');
 const html=fs.readFileSync('docs/index.html','utf8'),{document}=parseHTML(html),listeners=new Map();
 const context=vm.createContext({document,console,crypto,Date,Intl,URLSearchParams,AbortController,performance:{now:()=>0},location:{search:'',hash:'',pathname:'/',protocol:'https:',host:'game.test'},history:{replaceState(){}},localStorage:{getItem(){return null;},setItem(){}},matchMedia:()=>({matches:false}),MutationObserver:document.defaultView.MutationObserver,ResizeObserver:class{observe(){}},requestAnimationFrame(){},setInterval(){},setTimeout(){return 1;},clearTimeout(){},fetch:async()=>({ok:true,json:async()=>({enabled:false})}),addEventListener:(name,fn)=>{if(!listeners.has(name))listeners.set(name,[]);listeners.get(name).push(fn);}});
 document.getElementById('sky').getContext=()=>({});
 vm.runInContext(html.match(/<script>([\s\S]*?)<\/script>/)[1],context);
 vm.runInContext("selected=1;$('practice').onclick();state.phase='live';state.phaseUntil=state.last+60000",context);
 const button=document.querySelector('[data-key="e"]');button.setPointerCapture=()=>{};button.onpointerdown({preventDefault(){},pointerId:1});button.onpointerup();
 assert.equal(vm.runInContext('input().skill',context),1);
 vm.runInContext('eng.practiceStep(state,me,input(),state.last+16)',context);
 assert.equal(vm.runInContext('state.players.find(p=>p.id===me).skillCount',context),1);
 vm.runInContext('leave()',context);assert.equal(vm.runInContext('input().skill',context),0);
 vm.runInContext("$('practice').onclick()",context);
 for(const fn of listeners.get('keydown'))fn({key:'Q',target:{tagName:'CANVAS'},preventDefault(){}});
 assert.equal(vm.runInContext('input().skill',context),-1);
 for(const fn of listeners.get('blur'))fn();assert.equal(vm.runInContext('input().skill',context),0);
});

test('spawn shield blocks damage until it expires, and attacking ends it early',()=>{
 const {s,a,b}=duel();b.shield=e.SHIELD;assert.equal(e.contact(a,b).valid,false);e.step(s,1034);assert.equal(b.hp,100);assert.equal(a.hits||0,0);
 b.shield=0;a.attackCooldown=0;e.step(s,1068);assert.ok(Math.abs(b.hp-CLEAN)<1e-9);assert.equal(a.hits,1);
 const own=duel();own.a.shield=e.SHIELD;e.step(own.s,1034);assert.equal(own.a.shield,0);assert.equal(own.a.strikes,1);
 const back=duel();back.b.hp=1;e.step(back.s,1034);assert.ok(back.b.respawn);back.a.input={};e.step(back.s,back.b.respawn);assert.ok(back.b.shield>2&&back.b.shield<=e.SHIELD);
});

function roundsDuel(mode='rounds'){const s=e.create(0,{mode}),a=e.player('A',0,'a',0),b=e.player('B',1,'b',0);e.admit(s,a,0);e.admit(s,b,0);return {s,a,b};}
const at=(s,t)=>{for(const p of s.players)p.seen=t;return e.step(s,t);};
test('players get stable numbers P1..P8 from their seats',()=>{
 const s=e.create(0,{mode:'rounds'});for(let i=0;i<8;i++)e.admit(s,e.player('P',0,'p'+i,0),0);assert.deepEqual(s.players.map(p=>p.slot),[0,1,2,3,4,5,6,7]);
});
test('rounds: countdown blocks attacks, the last kite standing wins, nobody respawns mid-round, everyone returns at full line',()=>{
 const {s,a,b}=roundsDuel();at(s,16);assert.equal(s.phase,'countdown');assert.equal(s.round,1);
 Object.assign(a,{x:700,y:180,input:{cut:true}});Object.assign(b,{x:300,y:180,anchorX:910});a.anchorX=90;
 at(s,1000);assert.equal(b.hp,100,'no damage during countdown');
 at(s,3016);assert.equal(s.phase,'live');Object.assign(a,{x:700,y:180});Object.assign(b,{x:300,y:180});b.hp=1;a.attackCooldown=0;at(s,3050);
 assert.ok(b.respawn);assert.equal(s.phase,'intermission');assert.equal(a.rounds,1);assert.equal(s.events[0].kind,'round');assert.equal(s.events[0].winnerId,'a');
 a.hp=40;at(s,5000);assert.ok(b.respawn,'the cut player waits for the round to end');
 at(s,6300);assert.equal(s.phase,'countdown');assert.equal(s.round,2);assert.equal(b.respawn,0);assert.equal(a.hp,100);assert.equal(b.hp,100);
});
test('rounds: three round wins end the match; a timeout goes to the healthiest line',()=>{
 const {s,a,b}=roundsDuel();let t=16;at(s,t);
 for(let r=0;r<3;r++){t+=3100;at(s,t);assert.equal(s.phase,'live');a.hp=90;b.hp=50;t+=60100;at(s,t);assert.equal(s.phase,'intermission');t+=3300;at(s,t);}
 assert.equal(a.rounds,3);assert.equal(b.rounds||0,0);assert.ok(t>=s.end,'match is over after the third round win');
});
test('time mode waits for a second player before the clock starts; late joiners in rounds watch until the next round',()=>{
 const s=e.create(0,{mode:'time'}),a=e.player('A',0,'a',0);e.admit(s,a,0);at(s,5000);assert.equal(s.phase,'waiting');assert.ok(s.end>3000000);
 e.admit(s,e.player('B',1,'b',5000),5000);at(s,5016);assert.equal(s.phase,'countdown');a.seen=s.players[1].seen=8100;at(s,8100);assert.equal(s.phase,'live');assert.equal(s.end,8100+180000);
 const r=roundsDuel();at(r.s,16);at(r.s,3100);assert.equal(r.s.phase,'live');const c=e.admit(r.s,e.player('C',2,'c',3100),3100);assert.ok(c.respawn);at(r.s,3200);assert.ok(c.respawn);
});

test('mouse or finger steers the kite with analog input; held keys win and the left button attacks',async()=>{
 const {parseHTML}=await import('linkedom'),fs=await import('node:fs'),vm=await import('node:vm');
 const html=fs.readFileSync('docs/index.html','utf8'),{document}=parseHTML(html),listeners=new Map(),canvasListeners=new Map();
 const context=vm.createContext({document,console,crypto,Date,Intl,URLSearchParams,AbortController,performance:{now:()=>0},location:{search:'',hash:'',pathname:'/',protocol:'https:',host:'game.test'},history:{replaceState(){}},localStorage:{getItem:k=>k==='pipaAssisIntroV1'?'done':null,setItem(){}},matchMedia:()=>({matches:true}),MutationObserver:document.defaultView.MutationObserver,ResizeObserver:class{observe(){}},requestAnimationFrame(){},setInterval(){},clearInterval(){},setTimeout(){return 1;},clearTimeout(){},fetch:async()=>({ok:true,json:async()=>({enabled:false})}),Image:class{},addEventListener:(name,fn)=>{if(!listeners.has(name))listeners.set(name,[]);listeners.get(name).push(fn);}});
 const sky=document.getElementById('sky');sky.getContext=()=>({});sky.width=1000;sky.height=600;sky.getBoundingClientRect=()=>({left:0,top:0,width:1000,height:600});sky.addEventListener=(name,fn)=>canvasListeners.set(name,fn);
 vm.runInContext(html.match(/<script>([\s\S]*?)<\/script>/)[1],context);
 vm.runInContext("$('practice').onclick();const me0=state.players.find(p=>p.id===me);me0.x=500;me0.y=300;",context);
 const fire=(name,e)=>canvasListeners.get(name)({pointerType:'mouse',button:0,pointerId:1,preventDefault(){},type:name,...e});
 fire('pointermove',{clientX:800,clientY:300});let i=vm.runInContext('input()',context);assert.equal(i.x,1);assert.equal(i.y,0);assert.equal(i.cut,false);
 fire('pointermove',{clientX:535,clientY:300});i=vm.runInContext('input()',context);assert.ok(i.x>0&&i.x<1,'slows down near the cursor');
 fire('pointerdown',{clientX:535,clientY:300});assert.equal(vm.runInContext('input().cut',context),true);fire('pointerup',{clientX:535,clientY:300});assert.equal(vm.runInContext('input().cut',context),false);
 fire('pointerdown',{button:2,clientX:200,clientY:300});assert.equal(vm.runInContext('input().skill',context),-1,'right click dashes toward the cursor side');
 for(const fn of listeners.get('keydown'))fn({key:'ArrowUp',target:{tagName:'CANVAS'},preventDefault(){}});i=vm.runInContext('input()',context);assert.equal(i.x,0);assert.equal(i.y,-1);
 for(const fn of listeners.get('keyup'))fn({key:'ArrowUp'});assert.deepEqual([vm.runInContext('input().x',context),vm.runInContext('input().y',context)],[0,0],'keys hand control back until the mouse moves again');
 canvasListeners.get('pointerdown')({pointerType:'touch',pointerId:7,button:0,clientX:500,clientY:500,preventDefault(){}});i=vm.runInContext('input()',context);assert.equal(i.x,0);assert.equal(i.y,1,'finger pulls the kite to just above the touch');
 canvasListeners.get('pointerup')({pointerType:'touch',pointerId:7,type:'pointerup'});i=vm.runInContext('input()',context);assert.equal(i.y,0);
 assert.equal(i.cut,true,'a quick tap remains queued for the next network update');
 vm.runInContext('attackUntil=Date.now()-1;skillUntil=0',context);assert.equal(vm.runInContext('input().cut',context),false);
 const touch=(name,x,y,id=8)=>fire(name,{pointerType:'touch',pointerId:id,clientX:x,clientY:y});
 touch('pointerdown',500,300);touch('pointermove',430,305);assert.equal(vm.runInContext('input().skill',context),-1);
 vm.runInContext('skillUntil=0',context);touch('pointermove',600,305);assert.equal(vm.runInContext('input().skill',context),0,'one skill per swipe');
 touch('pointerup',600,305);assert.equal(vm.runInContext('input().cut',context),false,'swipes never attack');
 touch('pointerdown',500,300);touch('pointermove',570,305);assert.equal(vm.runInContext('input().skill',context),1);touch('pointerup',570,305);
 vm.runInContext('skillUntil=0',context);touch('pointerdown',500,300);touch('pointermove',510,380);assert.equal(vm.runInContext('input().skill',context),0,'vertical movement does not trigger a skill');touch('pointerup',510,380);assert.equal(vm.runInContext('input().cut',context),false);
 touch('pointerdown',500,300);touch('pointercancel',500,300);assert.equal(vm.runInContext('input().cut',context),false,'cancel is never a tap');
 touch('pointerdown',500,300);touch('pointerdown',100,100,9);assert.equal(vm.runInContext('pointer.id',context),8,'second finger cannot steal steering');touch('pointerup',100,100,9);assert.equal(vm.runInContext('pointer.id',context),8);touch('pointercancel',500,300);
 fire('pointermove',{clientX:200,clientY:300});vm.runInContext('eng.move(state.players.find(p=>p.id===me),input(),.016)',context);assert.equal(vm.runInContext('state.players.find(p=>p.id===me).facing',context),-1);
 fire('pointermove',{clientX:800,clientY:300});vm.runInContext('eng.move(state.players.find(p=>p.id===me),input(),.016)',context);assert.equal(vm.runInContext('state.players.find(p=>p.id===me).facing',context),1);
 touch('pointerdown',500,300);touch('pointerup',500,300);for(const fn of listeners.get('blur'))fn();assert.equal(vm.runInContext('input().cut',context),false,'losing focus clears queued attacks');
 sky.width=390;sky.height=720;sky.getBoundingClientRect=()=>({left:0,top:0,width:390,height:720});
 const view=vm.runInContext('worldView()',context);assert.equal(view.portrait,true);assert.ok(view.s>390/1000,'portrait gets a closer view');
 for(const x of [55,500,945]){vm.runInContext(`state.players.find(p=>p.id===me).x=${x}`,context);const v=vm.runInContext('worldView()',context),screenX=x*v.s+v.x;assert.ok(screenX>=0&&screenX<=390,'own kite remains visible at both world boundaries');fire('pointermove',{clientX:screenX+30,clientY:300*v.s+v.y});assert.ok(vm.runInContext('input().x',context)>0,'pointer uses the same camera as rendering');}
});

test('cut quality: open angle and a moving kite add damage, a shallow angle removes it, all three on the golden centre is critical',()=>{
 const c=(angle,perfect)=>({angle,perfect});
 assert.equal(e.cutDamage({},c(.6,false)).damage,18);
 assert.ok(Math.abs(e.cutDamage({},c(.9,false)).damage-18*1.2)<1e-9);
 assert.ok(Math.abs(e.cutDamage({},c(.3,false)).damage-18*.8)<1e-9);
 assert.ok(Math.abs(e.cutDamage({vx:150},c(.6,false)).damage-18*1.15)<1e-9);
 const crit=e.cutDamage({vx:150},c(.95,true));assert.equal(crit.crit,true);assert.equal(crit.damage,24*1.75);
 assert.equal(e.cutDamage({vx:150},c(.95,false)).crit,false,'outside the golden centre is never a natural critical');
 assert.equal(e.cutDamage({counter:1},c(.6,false)).crit,true,'a counter after a perfect dodge is critical');
});
test('dodge: costs energy, has a cooldown, moves fast, blocks attacking; a perfect dodge refunds energy and makes the next hit critical',()=>{
 const p=e.player('D',0,'d',0);p.x=500;p.y=300;e.move(p,{x:1,dodge:true},.1);
 assert.equal(p.energy,100-e.DODGE.cost+18*.1);assert.ok(p.x>500+165*.1*2,'dodge is a fast burst');assert.ok(p.evade>0);
 const x=p.x;e.move(p,{dodge:true,cut:true},.05);assert.equal(p.dodges,1,'cooldown prevents a second dodge');assert.equal(p.strike,false,'no pulling while dodging');
 const {s,a,b}=duel();b.input={dodge:true};const energy=b.energy;e.step(s,1034);
 assert.equal(b.hp,100,'a strike during the dodge slides off');assert.equal(b.perfectDodges,1);assert.equal(a.aim,'dodged');assert.equal(b.energy,Math.min(100,energy-e.DODGE.cost+e.DODGE.cost+18*.034));assert.ok(b.counter>0);
 b.input={cut:true};a.input={};b.attackCooldown=0;Object.assign(b,{x:300,y:180,evade:0});Object.assign(a,{x:700,y:180});e.step(s,1068);
 assert.ok(Math.abs(a.hp-(100-24*1.75))<1e-9,'the counter hit is critical');assert.equal(b.counter,0);assert.equal(b.crits,1);
});


test('authoritative solo pause freezes combat and round timers, resumes and expires disconnected owners',()=>{
 const now=100000,s=e.create(now,{mode:'rounds'}),p=e.player('Owner',0,'owner',now),bot=e.player('Bot',1,'bot',now);p.accountId='a';bot.bot=true;bot.ai={level:3};s.trail='morro-1';s.trailOwner='a';e.admit(s,p,now);e.admit(s,bot,now);s.phase='live';s.phaseUntil=now+60000;p.input={x:1,cut:true};
 assert.equal(e.setSoloPause(s,{id:'other',accountId:'other'},true,now),false);assert.equal(e.setSoloPause(s,p,true,now),true);
 const before=JSON.stringify(s.players),remaining=s.phaseUntil-s.last;for(let i=1;i<=4;i++){p.seen=now+i*1000;e.step(s,now+i*1000);}
 assert.deepEqual(s.players.map(q=>[q.x,q.y,q.hp,q.energy,q.cuts]),JSON.parse(before).map(q=>[q.x,q.y,q.hp,q.energy,q.cuts]));assert.equal(s.phaseUntil-s.last,remaining);assert.equal(s.cutSequence,0);
 const view=createNetworkView(e);view.receive(e.visible(s),p.id,0);assert.equal(view.render(200,{x:1,cut:true},.1)[0].x,p.x);
 assert.equal(e.setSoloPause(s,p,false,now+4000),true);e.step(s,now+4016);assert.equal(s.soloPaused,false);
 e.setSoloPause(s,p,true,now+4016);e.step(s,now+30000);assert.equal(s.soloPaused,true,'allow recovery during the one minute grace period');e.step(s,now+70000);assert.ok(s.end<=now+70000);assert.equal(s.players.some(q=>!q.bot),false);
 const multi=e.create(now,{mode:'rounds'});e.admit(multi,p,now);assert.equal(e.setSoloPause(multi,p,true,now),false);
});
