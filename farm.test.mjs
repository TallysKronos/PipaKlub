import test from 'node:test';
import assert from 'node:assert/strict';
import {createFarm} from './src/farm.js';
import fs from 'node:fs';
import vm from 'node:vm';
import {parseHTML} from 'linkedom';
const kite=(id,model='mata',name='Mata verde')=>({id,model_id:model,model:{name,color:1,soul:null}});
test('farm displays owned species only, counts duplicates and updates removed or newly acquired species without changing inventory',()=>{
 const farm=createFarm({random:()=>.5}),inventory=[kite('1'),kite('2'),kite('3','raio','Raio')],copy=structuredClone(inventory);
 farm.setCollection(inventory);assert.equal(farm.residents.length,2);assert.equal(farm.residents.find(p=>p.id==='mata').count,2);assert.deepEqual(inventory,copy);
 const resident=farm.residents[0];resident.x=300;farm.setCollection([...inventory,kite('4','azulao','Azulão')]);assert.equal(farm.residents.find(p=>p.id===resident.id).x,300);assert.equal(farm.residents.length,3);
 farm.setCollection([kite('5','azulao','Azulão')]);assert.deepEqual(farm.residents.map(p=>p.id),['azulao']);farm.setCollection([]);assert.deepEqual(farm.visible(),[]);assert.equal(farm.pages,1);
});
test('farm wandering rests, faces its movement, clamps long gaps and stays within the pasture',()=>{
 let seed=17;const random=()=>((seed=(seed*16807)%2147483647)/2147483647),farm=createFarm({random});farm.setCollection([kite('1')]);const p=farm.visible()[0];
 Object.assign(p,{x:500,y:400,tx:300,ty:400,wait:0});farm.step(.1);assert.equal(p.facing,-1);assert.equal(p.moving,true);assert.ok(p.x<500);
 Object.assign(p,{tx:800,wait:0});farm.step(.1);assert.equal(p.facing,1);p.wait=2;const x=p.x;farm.step(.1);assert.equal(p.x,x);assert.equal(p.moving,false);
 p.wait=0;farm.step(10000);assert.ok(Math.abs(p.x-x)<=p.speed*.1+.00001);
 for(let i=0;i<20000;i++){farm.step(.1);assert.ok(p.x>=farm.bounds.left&&p.x<=farm.bounds.right);assert.ok(p.y>=farm.bounds.top&&p.y<=farm.bounds.bottom);}
});
test('large collections use groups of twelve so every owned species can be seen without animating them all',()=>{
 const farm=createFarm();farm.setCollection(Array.from({length:33},(_,i)=>kite(String(i),'species-'+String(i).padStart(2,'0'))));
 const seen=[];assert.equal(farm.pages,3);for(let n=0;n<3;n++){seen.push(...farm.visible().map(p=>p.id));assert.ok(farm.visible().length<=12);farm.turn(1);}assert.equal(new Set(seen).size,33);assert.equal(farm.page,2);farm.turn(1);assert.equal(farm.page,2);farm.turn(-100);assert.equal(farm.page,0);
});

function view({reduced=false}={}){
 const {document}=parseHTML('<html><body><div id="accountModal" style="display:flex"></div><button id="closeAccount"></button><section id="farm"></section></body></html>');
 const frames=new Map(),draws=[],loads=[],listeners={},canvasContext={clearRect(){},beginPath(){},ellipse(){},fill(){}},create=document.createElement.bind(document);
 document.createElement=(tag)=>{const el=create(tag);if(tag==='canvas')el.getContext=()=>canvasContext;return el;};
 // innerHTML creates the canvas through the parser, so expose the same minimal drawing surface on its prototype.
 Object.getPrototypeOf(create('canvas')).getContext=()=>canvasContext;
 let frameId=0;
 const context=vm.createContext({document,createFarm,console,accountPage:'farm',playerAccount:{profile:{id:'ana'},inventory:[kite('1','mata','<img src=x onerror=alert(1)>'),kite('2')]},
  farmPage:document.getElementById('farm'),accountModal:document.getElementById('accountModal'),$:id=>document.getElementById(id),
  uiElement(tag,text){const el=document.createElement(tag);if(text!==undefined)el.textContent=text;return el;},
  art:{reduced,atlases:{},load:name=>{loads.push(name);return Promise.resolve(true);},creature:(...args)=>draws.push(args)},
  requestAnimationFrame:fn=>{frames.set(++frameId,fn);return frameId;},cancelAnimationFrame:id=>frames.delete(id),syncClubMenu(){},closeAccount(){document.getElementById('accountModal').style.display='none';},addEventListener:(name,fn)=>listeners[name]=fn});
 vm.runInContext(fs.readFileSync('src/farm-client.js','utf8'),context);
 return {document,frames,draws,loads,run:code=>vm.runInContext(code,context),settle:()=>new Promise(r=>setImmediate(r)),tick(time){const current=[...frames.values()];frames.clear();current.forEach(fn=>fn(time));},visibility:hidden=>{document.hidden=hidden;listeners.visibilitychange();}};
}
test('farm UI keeps names inert, pauses/resumes, stops on close or hidden tab, and clears a previous account',async()=>{
 const app=view();app.run('syncFarm()');await app.settle();assert.equal(app.frames.size,1);assert.equal(app.document.querySelector('#farmResidents img'),null);assert.match(app.document.getElementById('farmResidents').textContent,/<img/);
 app.tick(1000);app.tick(1100);assert.ok(app.draws.length>0);const actor=app.draws.at(-1)[6];assert.equal(actor.animate,true);
 app.document.getElementById('farmPause').onclick();assert.equal(app.frames.size,0);assert.equal(app.document.getElementById('farmPause').textContent,'Retomar passeio');
 app.document.getElementById('farmPause').onclick();assert.equal(app.frames.size,1);app.visibility(true);assert.equal(app.frames.size,0);app.visibility(false);assert.equal(app.frames.size,1);
 app.run('closeAccount()');await app.settle();assert.equal(app.frames.size,0);
 app.run("art.load=()=>Promise.resolve(false);accountModal.style.display='flex';syncFarm()");await app.settle();assert.equal(app.document.getElementById('farmRetry').hidden,false);
 app.run('closeAccount()');assert.equal(app.frames.size,0);
 app.run('playerAccount=null;syncFarm()');assert.equal(app.document.getElementById('farmResidents').textContent,'');
 app.run("playerAccount={profile:{id:'beto'},inventory:[]};accountModal.style.display='flex';syncFarm()");assert.equal(app.frames.size,0);assert.equal(app.document.getElementById('farmEmpty').hidden,false);
});
test('reduced motion starts the farm still and explicit resume opts in to sprite animation',async()=>{
 const app=view({reduced:true});app.run('syncFarm()');await app.settle();assert.equal(app.frames.size,0);assert.equal(app.draws.at(-1)[6].animate,false);
 app.document.getElementById('farmPause').onclick();app.tick(1000);assert.equal(app.frames.size,1);assert.equal(app.draws.at(-1)[6].animate,true);
});
