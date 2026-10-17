import test from 'node:test';
import assert from 'node:assert/strict';
import {createTrails} from './src/trails.js';
import {createEngine} from './src/engine.js';
const t=createTrails();

test('stages unlock in order across trails and bosses close each trail',()=>{
 const p=t.defaults();assert.equal(t.unlocked(p,'morro-1'),true);assert.equal(t.unlocked(p,'morro-2'),false);
 p.stars['morro-1']=1;assert.equal(t.unlocked(p,'morro-2'),true);
 for(const s of t.trails[0].stages)p.stars[s.id]=2;assert.equal(t.unlocked(p,'praia-1'),true);assert.equal(t.unlocked(p,'praia-2'),false);
 for(const trail of t.trails)assert.ok(trail.stages.at(-1).boss&&trail.stages.at(-1).rounds===3);
 assert.ok(t.stages.every((s,i)=>i===0||s.level>=t.stages[i-1].level-1),'base levels climb along the road');
});
test('a win pays coins, a first clear pays double, stars reward clean wins and replays can farm',()=>{
 let p=t.defaults();const first=t.settle(p,'morro-1',{won:true,roundsLost:0});assert.equal(first.stars,3);assert.equal(first.firstClear,true);assert.equal(first.coins,Math.round(10*1.5)+10);
 p=first.progress;const again=t.settle(p,'morro-1',{won:true,roundsLost:1});assert.equal(again.firstClear,false);assert.equal(again.coins,Math.round(10*1.25));assert.equal(again.progress.stars['morro-1'],3,'best stars are kept');
 const loss=t.settle(again.progress,'morro-2',{won:false});assert.equal(loss.coins,0);assert.equal(loss.progress.coins,again.progress.coins);assert.equal(loss.progress.stars['morro-2'],undefined);
});
test('the AI adapts: wins raise mastery and AI level, losses lower it, both stay in range',()=>{
 let p=t.defaults();const st=t.stage('morro-1');assert.equal(t.aiLevel(st,p),1);
 for(let i=0;i<10;i++)p=t.settle(p,'morro-1',{won:true,roundsLost:0}).progress;assert.equal(p.mastery,t.MASTERY_MAX);assert.equal(t.aiLevel(st,p),1+t.MASTERY_MAX/2);
 assert.equal(t.aiLevel(t.stage('torres-5'),p),10,'never above level 10');
 const r=t.settle(p,'morro-1',{won:false});assert.equal(r.progress.mastery,t.MASTERY_MAX-1);
 let q=t.defaults();for(let i=0;i<5;i++)q=t.settle(q,'morro-1',{won:false}).progress;assert.equal(q.mastery,0);
});
test('stored progress is sanitised',()=>{
 const p=t.sanitize({coins:-50,stars:{'morro-1':99,'fake':3,'morro-2':'x'},mastery:999,wins:'7'});
 assert.deepEqual(p,{coins:0,stars:{'morro-1':3},mastery:t.MASTERY_MAX,wins:7,losses:0,fails:{},items:[]});
 assert.deepEqual(t.sanitize('lixo'),t.defaults());
});
test('higher AI levels beat lower ones and keep bot defaults unchanged',()=>{
 const e=createEngine();assert.deepEqual(e.brain(),{focus:.7,rest:.9,speed:.8,jitter:0,dodge:0,reserve:0,smart:false,weakest:false,evade:0,sweep:false,tip:.7});
 const duel=(la,lb,seed)=>{const s=e.create(0,{mode:'rounds',roundsToWin:2}),a=e.player('A',seed%4,'a',0),b=e.player('B',(seed+1)%4,'b',0);a.bot=b.bot=true;a.ai={level:la};b.ai={level:lb};
  if(seed%2){e.admit(s,a,0);e.admit(s,b,0);}else{e.admit(s,b,0);e.admit(s,a,0);}for(let now=16;now<s.end&&now<600000;now+=16)e.step(s,now);return (a.rounds||0)>(b.rounds||0);};
 let strong=0;for(let i=0;i<8;i++)strong+=duel(8,2,i)?1:0;assert.ok(strong>=7,'level 8 should beat level 2, won '+strong+'/8');
});

test('extra rivals cap the mastery bonus, and repeated losses ease the stage until it is won',()=>{
 const max={...t.defaults(),mastery:t.MASTERY_MAX};
 assert.equal(t.aiLevel(t.stage('praia-2'),max),t.stage('praia-2').level+1,'two rivals: at most +1');
 assert.equal(t.aiLevel(t.stage('praia-1'),max),t.stage('praia-1').level+4);
 let p=max;const levels=[];for(let i=0;i<4;i++){const r=t.settle(p,'praia-1',{won:false});p=r.progress;levels.push(r.levelAfter);assert.equal(r.fails,i+1);}
 assert.deepEqual(p.fails,{'praia-1':4});assert.equal(p.mastery,t.MASTERY_MAX-1-2-2-2,'second loss in a row drops mastery faster');
 assert.ok(levels.at(-1)<levels[0]);assert.equal(t.aiLevel(t.stage('praia-1'),{...p,mastery:0}),t.stage('praia-1').level-1,'relief after three losses');
 const won=t.settle(p,'praia-1',{won:true,roundsLost:1});assert.deepEqual(won.progress.fails,{});
 for(const id of ['morro-3','torres-2','torres-4'])assert.equal(t.stage(id).counter,2,'Guardiã is the recommended answer where the audit found it decisive');
});

test('each boss drops its Pipamon rabiola once, and only real drops survive sanitising',()=>{
 for(const trail of t.trails)assert.ok(trail.stages.at(-1).drop,'every trail boss has a drop');
 let p=t.defaults();const lost=t.settle(p,'morro-5',{won:false});assert.equal(lost.drop,null);
 const first=t.settle(lost.progress,'morro-5',{won:true,roundsLost:0});assert.equal(first.drop,'rabiola-raio-de-sol');assert.deepEqual(first.progress.items,['rabiola-raio-de-sol']);
 const again=t.settle(first.progress,'morro-5',{won:true});assert.equal(again.drop,null);assert.equal(again.progress.items.length,1);
 assert.deepEqual(t.sanitize({items:['rabiola-chaspiral','rabiola-chaspiral','inventada',7]}).items,['rabiola-chaspiral']);
});
