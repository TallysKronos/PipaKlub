import {writeFileSync,mkdirSync} from 'node:fs';
import {newRun,dispatch,pack} from '../tools/oficina-v3/protocol.mjs';
import {geometry,craftQuality as quality} from '../tools/oficina-v3/model.mjs';
import {createEngine} from '../src/engine.js';
import {createFirstFlight} from '../src/first-flight.js';
const fixtures=[];
for(const kind of ['comum','incomum','raro']){
 const run=newRun(kind,7),events=[];
 const send=e=>{events.push(e);dispatch(run,e);};
 for(const rod of geometry(kind).rods) send(['rod',rod.mid.x,rod.mid.y]);
 for(let i=0;i<geometry(kind).rods.length;i++){
  send(['knot',i]);
  const target=(run.step.windows[i][0]+run.step.windows[i][1])/2;
  for(let n=0;n<500&&run.step.fill<target;n++)send(['t',.01,0]);
  send(['knot-up']);
 }
 for(const p of geometry(kind).samples){if(run.stage!==2)break;send(['cut',p.x,p.y,.01]);}
 for(let n=0;n<2000&&run.stage===3;n++)send(['t',.01,Math.max(-1,Math.min(1,-run.step.theta*.12-run.step.omega*.1))]);
 if(run.stage===4){send(['soul']);for(let n=0;n<500&&run.step.fill<.88;n++)send(['t',.01,0]);send(['soul-up']);}
 fixtures.push({kind,seed:7,events,expected:pack(run),quality:quality(run)});
}
mkdirSync('godot/tests/fixtures',{recursive:true});
writeFileSync('godot/tests/fixtures/workshop.json',JSON.stringify(fixtures));
console.log(fixtures.map(f=>({kind:f.kind,stage:f.expected.stage,events:f.events.length})));
const engine=createEngine(),combat=[];
for(let color=0;color<4;color++){
 const s=engine.create(0),p=engine.player('Kael',color,'player',0);
 Object.assign(p,{x:172,y:290,anchorX:90,pipamonLevel:1,craftBonus:5,hull:105,guardHeld:false});
 engine.admit(s,p,0);p.shield=0;
 const events=[];
 for(let n=0;n<360;n++){
  const input={x:Math.sin(n/21),y:Math.cos(n/25),cut:n>90&&n<180,skill:n===25?1:0,dodge:n===200,guard:n===240};
  if(n>=280)Object.assign(input,{lineNonce:1,lineId:'puxao',lineHeld:false,lineSide:1});
  const wind=Math.sin(n/90)*12;
  engine.move(p,input,1/60,wind);
  events.push({input,wind});
 }
 combat.push({color,bonus:5,events,expected:Object.fromEntries(['x','y','energy','attackCooldown','skillCooldown','skillTime','dodgeCooldown','guardCooldown','lineCooldown'].map(k=>[k,p[k]]))});
}
writeFileSync('godot/tests/fixtures/combat.json',JSON.stringify(combat));
const training=createFirstFlight(engine),tutorial=[];
for(let lesson=0;lesson<5;lesson++){
 const run=training.create({lesson,color:0,soul:'rabbito'},0),events=[];
 let nonce=0;
 for(let n=1;n<=6000&&!run.complete;n++){
  const p=run.state.players[0],q=run.state.players[1];
  const input={x:Math.max(-1,Math.min(1,(700-p.x)/20)),y:Math.max(-1,Math.min(1,(180-p.y)/20)),cut:lesson===1||lesson===4};
  if(lesson===2)input.x=input.y=0;
  if(lesson===3){
   input.x=input.y=0;
   input.cut=run.exercise==='skill';input.skill=run.exercise==='skill'?1:0;
   input.dodge=run.exercise==='dodge';
   if(run.exercise==='line'&&!p.lineMove&&p.evade<=0&&p.lineCooldown<=0)nonce++;
   if(nonce)Object.assign(input,{lineNonce:nonce,lineId:'puxao',lineHeld:false,lineSide:1});
   input.guard=run.exercise==='guard'&&q.signatureWindup>0&&q.signatureWindup<.3;
  }
  const now=n*1000/60;training.tick(run,input,now);
  events.push({input,dt:(now-(n-1)*1000/60)/1000});
 }
 if(!run.complete)throw Error('Tutorial reference did not finish '+lesson+' '+run.exercise+' '+JSON.stringify(run.state.players.map(p=>({x:p.x,y:p.y,windup:p.signatureWindup,cooldown:p.signatureCooldown,guard:p.guardCooldown,hits:p.hits,energy:p.energy}))));
 tutorial.push({lesson,events,expected:{complete:run.complete,exercise:run.exercise,p:Object.fromEntries(['x','y','energy','hits','blocks','score'].map(k=>[k,run.state.players[0][k]||0]))}});
}
writeFileSync('godot/tests/fixtures/tutorial.json',JSON.stringify(tutorial));
for(const initialHp of [250,130]){
const match=engine.create(0,{mode:'rounds',roundsToWin:1});
match.boss={id:'lacertubo'};match.phase='live';match.phaseUntil=120000;match.end=720000;
const human=engine.player('Kael',0,'p',0),boss=engine.player('Lacertubo',2,'q',0);
Object.assign(human,{anchorX:90,pipamonLevel:1});
Object.assign(boss,{anchorX:910,bot:true,bossId:'lacertubo',bossPhase:1,bossRecovery:0,bossCharge:0,bossTelegraph:0,signatureCooldown:6,ai:{level:6,style:'patient'}});
engine.admit(match,human,0);engine.admit(match,boss,0);
for(const [p,x]of [[human,172],[boss,828]])Object.assign(p,{x,y:290,shield:0,hull:engine.pipamonStats(p).line,botFocus:-.4});
boss.hp=initialHp;
const trace=[];
for(let n=1;n<=720;n++){
 const input={x:Math.sin(n/60),y:Math.cos(n/75)*.6,cut:n>90&&n<360,skill:n===100?1:0,dodge:n===300,guard:n===500};
 human.input=input;human.seen=n*1000/60;engine.step(match,n*1000/60);
 trace.push({input,dt:(n*1000/60-(n-1)*1000/60)/1000,p:Object.fromEntries(['x','y','hp','hull','energy'].map(k=>[k,human[k]])),q:Object.fromEntries(['x','y','hp','hull','energy','bossCharge','bossRecovery','signatureWindup','signatureCooldown'].map(k=>[k,boss[k]||0]))});
 if(match.phase!=='live')break;
}
writeFileSync(`godot/tests/fixtures/boss-${initialHp}.json`,JSON.stringify(trace));
}
