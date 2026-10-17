import test from 'node:test';
import assert from 'node:assert/strict';
import {createSkyDuel} from './src/sky-duel.js';
import fs from 'node:fs';
import vm from 'node:vm';
import {parseHTML} from 'linkedom';
const e=createSkyDuel();
test('3D line contact requires spatial proximity, not just an apparent screen crossing',()=>{
 const s=e.create();s.player.x=100;s.bot.x=-100;s.bot.z=s.player.z;s.bot.y=s.player.y;
 assert.equal(e.contact(s.player,s.bot).valid,true);
 s.bot.z+=350;assert.equal(e.contact(s.player,s.bot).valid,false);
 const hp=s.bot.hp;assert.equal(e.attack(s,s.player),true);assert.equal(s.bot.hp,hp);assert.equal(s.player.energy,84);
});
test('accepted pulls wear down the line once, cooldown stops spam, dodge blocks a hit',()=>{
 const s=e.create();s.bot.z=s.player.z;s.bot.y=s.player.y;
 e.attack(s,s.player);assert.equal(s.bot.hp,80);e.attack(s,s.player);assert.equal(s.bot.hp,80);
 s.player.cooldown=0;s.bot.dodge=.4;e.attack(s,s.player);assert.equal(s.bot.hp,80);
 s.bot.dodge=0;s.player.cooldown=0;s.player.energy=0;assert.equal(e.attack(s,s.player),false);
});
test('depth, arena bounds and timer stay finite; a finished game cannot award more hits',()=>{
 const s=e.create();for(let i=0;i<2000;i++)e.step(s,{x:1,y:-1,z:1},.05);
 assert.equal(s.ended,true);assert.ok(s.left>=0);assert.ok(s.player.z<=1050&&s.player.x<=270&&s.player.y>=80);
 const timed=e.create();timed.time=89.99;e.step(timed,{},.05);assert.equal(timed.left,0);assert.equal(timed.ended,true);
 const before=JSON.stringify(s);e.step(s,{attack:true},.05);e.attack(s,s.player);assert.equal(JSON.stringify(s),before);
});
test('a pilot can win using ordinary movement and attacks; restarting creates independent state',()=>{
 const s=e.create();for(let i=0;i<3600&&!s.ended;i++)e.step(s,{x:Math.sin(i/400)*.3,z:i<200?.5:0,attack:true},1/60);
 assert.equal(s.winner,'you');assert.equal(s.bot.hp,0);assert.equal(e.create().player.hp,100);assert.equal(e.create().bot.hp,100);
});
test('bot telegraphs contact before attacking and a player can dodge the release',()=>{
 const s=e.create();s.time=5;s.rest=0;s.bot.z=s.player.z;s.bot.y=s.player.y;
 e.step(s,{},.01);assert.ok(s.charge>0);assert.equal(s.player.hp,100);
 s.charge=.1;e.step(s,{dodge:true},.05);e.step(s,{},.05);e.step(s,{},.05);assert.equal(s.player.hp,100);assert.ok(s.player.dodgeCooldown>0);
});
test('lab UI draws, pauses on focus loss, resets held controls and exits without starting a match',()=>{
 const {document,window}=parseHTML('<html><body><div class="menu-actions"></div></body></html>');
 const noop=()=>{},gradient={addColorStop:noop},context=new Proxy({createLinearGradient:()=>gradient},{get:(o,k)=>o[k]||noop});
 window.HTMLCanvasElement.prototype.getContext=()=>context;
 window.HTMLCanvasElement.prototype.getBoundingClientRect=()=>({width:900,height:500,left:0,top:0});
 const listeners=new Map(),scope=vm.createContext({document,console,Math,devicePixelRatio:1,mode:null,selected:0,playerAccount:null,lightMode:false,requestAnimationFrame:()=>1,cancelAnimationFrame:noop,addEventListener:(k,fn)=>listeners.set(k,fn),toast:noop,art:{reduced:false,creature:noop},$:id=>document.getElementById(id),uiElement:(tag,text,cls)=>{const e=document.createElement(tag);if(text)e.textContent=text;if(cls)e.className=cls;return e;}});
 vm.runInContext(fs.readFileSync('src/sky-duel.js','utf8').replace('export function','function')+'\n'+fs.readFileSync('src/sky-duel-client.js','utf8'),scope);
 vm.runInContext('skyOpen();skyDraw(100)',scope);assert.equal(document.getElementById('skyExperiment').hidden,false);assert.match(document.getElementById('skyYourHP').textContent,/100%/);
 vm.runInContext("skyKeys.add(' ');skyHeld.z=1",scope);listeners.get('blur')();assert.equal(vm.runInContext('skyPaused',scope),true);assert.equal(vm.runInContext('skyKeys.size+skyHeld.z',scope),0);
 vm.runInContext('skyClose()',scope);assert.equal(document.getElementById('skyExperiment').hidden,true);assert.equal(document.body.classList.contains('sky-testing'),false);assert.equal(vm.runInContext('mode',scope),null);
});
function alignedSkill(id,{guard=false}={}){
 const s=e.create();s.bot.z=s.player.z;e.startSkill(s,id);e.releaseSkill(s);
 for(let i=0;i<100&&s.player.lineSkill;i++){s.bot.x=-s.player.x;s.bot.y=s.player.y;s.bot.z=s.player.z;if(guard)s.charge=2;e.step(s,{},.02);}
 return s;
}
test('six line skills move in distinct paths and only their contact windows deal damage',()=>{
 assert.equal(new Set(e.skills.map(d=>JSON.stringify([.2,.5,.8].map(t=>e.skillPose({id:d.id,direction:1},t))))).size,6);
 const expected={puxao:68,chicote:76,estilingue:72,laco:80,folha:100,duplo:74};
 for(const def of e.skills){const s=alignedSkill(def.id);assert.equal(s.bot.hp,expected[def.id],def.id);assert.equal(s.player.lineSkill,null);assert.ok(s.player.lineCooldown>0);assert.ok(s.player.trail.length>0);}
 assert.equal(e.skillWindow('puxao',.2),null);assert.equal(e.skillWindow('puxao',.6).critical,true);assert.equal(e.skillWindow('folha',.6),null);
});
test('line skill costs, cooldown, missed geometry and cancelled preparation cannot mint hits',()=>{
 const s=e.create();s.player.energy=0;assert.equal(e.startSkill(s,'puxao'),false);s.player.energy=100;
 assert.equal(e.startSkill(s,'unknown'),false);assert.equal(e.startSkill(s,'puxao'),true);assert.equal(s.player.energy,72);assert.equal(e.startSkill(s,'laco'),false);assert.equal(e.attack(s,s.player),false);
 e.cancelCharge(s);assert.equal(s.player.lineSkill,null);assert.equal(e.releaseSkill(s),false);assert.equal(e.startSkill(s,'puxao'),false);
 s.player.lineCooldown=0;s.bot.x=260;s.bot.z=1050;e.startSkill(s,'puxao');e.releaseSkill(s);for(let i=0;i<24;i++)e.step(s,{},.05);assert.equal(s.bot.hp,100);
});
test('second pulse defeats an existing guard, loose leaf grants no invulnerability, and a hit interrupts a loop',()=>{
 const guarded=alignedSkill('duplo',{guard:true});assert.equal(guarded.bot.hp,77);assert.equal(guarded.player.impact.guardBreak,true);
 const noGuard=alignedSkill('duplo');assert.equal(noGuard.player.impact.guardBreak,false);
 const leaf=alignedSkill('folha');assert.equal(leaf.player.dodge,0);assert.equal(leaf.bot.hp,100);
 const s=e.create();s.bot.z=s.player.z;e.startSkill(s,'laco');e.attack(s,s.bot);assert.equal(s.player.lineSkill,null);assert.equal(s.player.hp,80);assert.match(s.message,/interrompido/);
});
