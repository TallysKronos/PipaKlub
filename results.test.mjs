import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import {parseHTML} from 'linkedom';
import {createEngine} from './src/engine.js';

function ui(accountRequest){
 const {document}=parseHTML('<html><body><div id="matchRewardSummary"></div><div id="collectionMain"></div><section id="kiteStory" hidden><button id="kiteStoryBack"></button><div id="kiteStoryBody"></div></section></body></html>');
 const context=vm.createContext({document,Intl,Date,console,$:id=>document.getElementById(id),accountRequest,refreshRewards(){},setTimeout(){return 1;},clearTimeout(){}});
 vm.runInContext(fs.readFileSync('src/results-client.js','utf8'),context);
 return {document,run:code=>vm.runInContext(code,context),settle:()=>new Promise(resolve=>setImmediate(resolve))};
}
const result=(xp=25,opponent='Beto')=>({match:{rules:'capture'},totals:{xp,cuts:1,captured:1,lost:0},events:[{outcome:'cut',opponent,captured:true,kiteName:'Azulão',at:'2026-10-16T12:00:00Z',xp}]});
test('results show pending progress before saved progress, and opponent names remain inert text',async()=>{
 let calls=0;const app=ui(async()=>({status:++calls===1?'saving':'saved',result:result(calls*25,'<img src=x onerror=alert(1)>')}));
 app.run("beginMatchResult('first')");await app.settle();
 const root=app.document.getElementById('matchRewardSummary');assert.match(root.textContent,/Salvando/);assert.ok(!root.querySelector('.saved'));assert.equal(root.querySelector('img'),null);assert.match(root.textContent,/<img/);
 await app.run('loadMatchResult()');assert.match(root.textContent,/Resultado salvo/);assert.match(root.textContent,/\+50/);assert.equal(root.querySelectorAll('button').length,0);
});
test('a late result cannot overwrite a different match, and a closed kite story stays closed',async()=>{
 const pending=[];const app=ui((action,body)=>new Promise(resolve=>pending.push({action,body,resolve})));
 app.run("beginMatchResult('first')");app.run("beginMatchResult('second')");
 pending[1].resolve({status:'saved',result:result(50,'Segundo')});await app.settle();pending[0].resolve({status:'saved',result:result(25,'Primeiro')});await app.settle();
 const root=app.document.getElementById('matchRewardSummary');assert.match(root.textContent,/Segundo/);assert.doesNotMatch(root.textContent,/Primeiro/);
 app.run("openKiteStory({id:'kite'})");app.run('closeKiteStory()');
 pending[2].resolve({history:{name:'Late kite',permanent:false,captureCount:0,captures:[],createdAt:'2026-10-16T12:00:00Z'}});await app.settle();
 assert.equal(app.document.getElementById('kiteStory').hidden,true);assert.doesNotMatch(app.document.getElementById('kiteStoryBody').textContent,/Late kite/);
});

test('practice keeps its local player past the multiplayer timeout and reaches the end',()=>{
 const engine=createEngine(),s=engine.create(1000);s.players=[engine.player('Local',0,'local',1000)];
 for(let now=1000;now<=s.end+1000;now+=1000)engine.practiceStep(s,'local',{x:1},now);
 assert.equal(s.players.length,1);assert.equal(s.players[0].id,'local');assert.ok(s.last>=s.end);
 const x=s.players[0].x;engine.practiceStep(s,'local',{x:-1},s.end+2000);assert.equal(s.players[0].x,x);
});
