import test from 'node:test';
import assert from 'node:assert/strict';
import {createEngine} from './src/engine.js';
import {createNetworkView} from './src/network-view.js';
const e=createEngine();
function duel(){const s=e.create(1000),a=e.player('A',0,'a',1000),b=e.player('B',1,'b',1000);Object.assign(a,{x:700,y:180,anchorX:90,input:{cut:true}});Object.assign(b,{x:300,y:180,anchorX:910});s.players=[a,b];return {s,a,b};}

test('only a valid line crossing deals damage; kite proximity, ground intersections and parallel lines do not',()=>{
 const {s,a,b}=duel();assert.ok(e.contact(a,b).valid);e.step(s,1034);assert.equal(b.hp,76);assert.equal(a.hp,100);
 const nearby=duel();nearby.a.x=400;nearby.b.x=401;nearby.a.y=nearby.b.y=200;e.step(nearby.s,1034);assert.equal(nearby.b.hp,100);
 const parallel=duel();parallel.b.anchorX=90;parallel.a.x=parallel.b.x=400;e.step(parallel.s,1034);assert.equal(parallel.b.hp,100);
 const ground=duel();ground.a.x=900;ground.b.x=100;ground.b.anchorX=110;assert.equal(e.contact(ground.a,ground.b),null);e.step(ground.s,1034);assert.equal(ground.b.hp,100);
});
test('one pull hits one target, misses cost energy, cooldown and low energy prevent spam',()=>{
 const {s,a,b}=duel(),c={...b,id:'c'};s.players.push(c);e.step(s,1034);assert.equal(b.hp,76);assert.equal(c.hp,100);const hp=b.hp;e.step(s,1068);assert.equal(b.hp,hp);
 a.attackCooldown=0;a.energy=11;e.step(s,1100);assert.equal(b.hp,hp);a.energy=100;a.x=80;a.attackCooldown=0;e.step(s,1134);assert.ok(a.energy<90);assert.equal(b.hp,hp);
});
test('simultaneous fatal strikes resolve identically when player order is reversed',()=>{
 for(const reverse of [false,true]){const {s,a,b}=duel();a.hp=b.hp=1;b.input={cut:true};if(reverse)s.players.reverse();e.step(s,1034);assert.equal(a.cuts,1);assert.equal(b.cuts,1);assert.ok(a.respawn&&b.respawn);assert.equal(s._pendingCuts.length,2);assert.equal(new Set(s.events.map(x=>x.id)).size,2);}
});
test('precision is consumed once, guard reduces damage, focus opens a previously invalid crossing',()=>{
 const precise=duel();precise.a.input={cut:true,skill:1};e.step(precise.s,1034);assert.equal(precise.b.hp,68);assert.equal(precise.a.skillTime,0);
 const guard=duel();guard.b.color=2;guard.b.input={skill:1};e.step(guard.s,1034);assert.ok(Math.abs(guard.b.hp-90.4)<.001);
 const {a,b}=duel();a.color=3;let found=false;
 for(let y=80;y<460;y+=10)for(let x=100;x<900;x+=10){a.x=x;a.y=y;a.skillTime=0;const before=e.contact(a,b);a.skillTime=1;const after=e.contact(a,b);if(before&&!before.valid&&after?.valid){found=true;break;}}
 assert.ok(found,'focus must expand the enemy vulnerability zone');
});
test('dash obeys direction, arena limits, cost, cooldown and input sanitization',()=>{
 for(const direction of [-1,1]){const p=e.player('Dash',1,'dash',0);p.x=500;e.move(p,{skill:direction,hp:999,damage:999},0);assert.equal(p.x,500+96*direction);assert.equal(p.energy,75);assert.equal(p.skillCount,1);e.move(p,{skill:-direction},.1);assert.equal(p.skillCount,1);assert.equal(p.x,500+96*direction);}
 const p=e.player('Edge',1,'edge',0);p.x=940;e.move(p,{skill:1},0);assert.equal(p.x,945);p.skillCooldown=0;p.energy=24;e.move(p,{skill:-1},0);assert.equal(p.x,945);
 assert.deepEqual(e.sanitizeInput({x:Infinity,y:-99,skill:99,damage:999}),{x:0,y:-1,cut:false,skill:0});
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
 const context=vm.createContext({document,console,crypto,Date,Intl,URLSearchParams,AbortController,performance:{now:()=>0},location:{search:'',hash:'',pathname:'/',protocol:'https:',host:'game.test'},history:{replaceState(){}},localStorage:{getItem(){return null;},setItem(){}},matchMedia:()=>({matches:false}),ResizeObserver:class{observe(){}},requestAnimationFrame(){},setInterval(){},setTimeout(){return 1;},clearTimeout(){},fetch:async()=>({ok:true,json:async()=>({enabled:false})}),addEventListener:(name,fn)=>{if(!listeners.has(name))listeners.set(name,[]);listeners.get(name).push(fn);}});
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
 b.shield=0;a.attackCooldown=0;e.step(s,1068);assert.equal(b.hp,76);assert.equal(a.hits,1);
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
