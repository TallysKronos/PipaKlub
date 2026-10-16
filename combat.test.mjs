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
 vm.runInContext("selected=1;$('practice').onclick()",context);
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
