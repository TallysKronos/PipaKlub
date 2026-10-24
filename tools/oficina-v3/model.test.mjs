import test from 'node:test';
import assert from 'node:assert/strict';
import {CLASSES,FLIGHT_TIME,SOUL_ZONES,geometry,createRun,placeRod,holdKnot,tickKnot,releaseKnot,cutAt,tickFlight,windAt,nextGust,holdSoul,tickSoul,releaseSoul,starsOf,restock,gradeLabel,knotWindow,VARIANT_CHANCE,VARIANT_ODDS,startStage,tickCraft,craftBonus,applyCraftBonus} from './model.mjs';
const rods=run=>{for(const r of geometry(run.kind).rods)placeRod(run,r.mid,0);};
// Segura até a fração pedida do anel e solta.
const knot=(run,i,target)=>{holdKnot(run,i);let out=null;while(run.step.holding!=null&&run.step.fill<target&&!out)out=tickKnot(run,1/120);return out||releaseKnot(run);};
const goodKnots=run=>{for(let i=0;i<CLASSES[run.kind].rods;i++){const [a,b]=knotWindow(run,i);knot(run,i,(a+b)/2);}};
const cutAll=(run,offset=0)=>{let r=null;for(const p of geometry(run.kind).samples){r=cutAt(run,{x:p.x+offset,y:p.y},.03)||r;if(run.stage!==2)break;}return r;};
// Controle simples e honesto: reage ao ângulo atual (o jogador "endireita" a pipa).
const fly=(run,gain=.03)=>{let r=null;while(run.stage===3&&!r?.done&&!r?.fell)r=tickFlight(run,1/60,-gain*run.step.theta-.02*run.step.omega);return r;};
test('classe muda a dificuldade, não a repetição: no máximo 6 ações por etapa',()=>{
 for(const [k,c] of Object.entries(CLASSES)){assert.ok(c.rods>=4&&c.rods<=6,k);assert.equal(geometry(k).rods.length,c.rods);}
 assert.ok(CLASSES.raro.snap<CLASSES.comum.snap&&CLASSES.raro.cut.tol<CLASSES.comum.cut.tol&&CLASSES.raro.ring.width<CLASSES.comum.ring.width);
});
test('armação: encaixe perto e alinhado conclui a etapa; torto ou longe volta sem custo',()=>{
 const run=createRun('raro'),r0=geometry('raro').rods[0];
 assert.equal(placeRod(run,{x:900,y:600}).ok,false);assert.match(placeRod(run,r0.mid,20).msg,/Torta/);assert.deepEqual(run.materials,{linha:3,folha:2});
 rods(run);assert.equal(run.stage,1);assert.ok(run.grades[0]>.95);
});
test('nós: frouxo repete, verde amarra, vermelho arrebenta e gasta linha',()=>{
 const run=createRun('comum');rods(run);const [a]=knotWindow(run,0);
 assert.match(knot(run,0,a-.1).msg,/Frouxo/);assert.equal(run.materials.linha,3);
 const [a2,b2]=knotWindow(run,0);assert.equal(knot(run,0,(a2+b2)/2).ok,true);
 assert.equal(knot(run,1,knotWindow(run,1)[1]+.05).lost,'linha');assert.equal(run.materials.linha,2);
 assert.equal(knot(run,1,1.2).lost,'linha');assert.equal(run.materials.linha,1);
 assert.equal(knot(run,1,1.2).lost,'linha');assert.equal(run.blocked,'linha');restock(run);assert.equal(run.blocked,null);
});
test('papel: seguir a linha conclui com nota alta; cortar dentro da vela rasga e gasta folha',()=>{
 const run=createRun('comum');rods(run);goodKnots(run);assert.equal(run.stage,2);
 const r=cutAll(run);assert.equal(r.done,true);assert.ok(r.grade>.8,String(r.grade));assert.equal(run.stage,3);
 const bad=createRun('raro');rods(bad);goodKnots(bad);let torn=null;for(let k=0;k<200&&!torn;k++)torn=cutAt(bad,{x:480+k%40,y:286},.03)?.torn?cutAt:null;
 assert.equal(bad.materials.folha,1);assert.equal(bad.stage,2);
});
test('voo: rajadas avisadas antes; quem endireita passa, quem ignora cai ou pontua pouco',()=>{
 const run=createRun('comum');rods(run);goodKnots(run);cutAll(run);const s=run.step;assert.ok(s.gusts.length>=3);
 assert.ok(nextGust(s,s.gusts[0].t-.5,CLASSES.comum.wind.tell));assert.equal(windAt(s,s.gusts[0].t-.1),0);
 const ok=fly(run);assert.equal(ok.done,true);assert.ok(run.grades[3]>.6,String(run.grades[3]));
 const lazy=createRun('raro',{seed:3});rods(lazy);goodKnots(lazy);cutAll(lazy);let r=null,t=0;while(lazy.stage===3&&t<FLIGHT_TIME+1&&!r?.fell){r=tickFlight(lazy,1/60,0);t+=1/60;}
 assert.ok(r?.fell||lazy.grades[3]<.7,'sem controle não pode dar nota alta');
});
test('despertar: sucesso tem chance fixa de variante; excesso ainda parte o elo',()=>{
 const ready=k=>{const run=createRun(k,{seed:11});rods(run);goodKnots(run);cutAll(run);fly(run);assert.equal(run.stage,4);return run;};
 const hold=(run,target)=>{holdSoul(run);let r=null;while(run.step.holding&&run.step.fill<target&&!r)r=tickSoul(run,1/120);return r||releaseSoul(run);};
 let run=ready('comum');assert.match(hold(run,.2).msg,/não pegou/);assert.equal(hold(run,(SOUL_ZONES.weak+SOUL_ZONES.safe)/2).outcome.type,'born');assert.equal(run.outcome.shine,false);
 run=ready('comum');const shine=hold(run,(SOUL_ZONES.safe+SOUL_ZONES.shine)/2).outcome;assert.equal(shine.shine,true);assert.equal(shine.chance,1/459);
 run=ready('comum');assert.equal(hold(run,2).outcome.type,'broken');
 assert.ok(starsOf(run)>=3);assert.equal(gradeLabel(.9),'Perfeito');
});
test('modo artesão soma bônus de nota em cada etapa',()=>{
 const a=createRun('incomum',{artesao:true}),b=createRun('incomum');rods(a);rods(b);
 assert.ok(a.grades[0]>=b.grades[0]);assert.ok(a.grades[0]-b.grades[0]<=.0600001);
});

test('bônus de montagem remunera precisão, velocidade e poucas falhas; máximo 8% + 4%',()=>{
 const ready=()=>{const r=createRun('comum');r.grades=[1,1,1,1];r.elapsed=[10,8,12,9,0];return r;};
 const fast=ready(),slow=ready(),misses=ready(),imprecise=ready();slow.elapsed=[48,35,56,9,0];misses.errors=[2,3,1,1,0];imprecise.grades=[.55,.6,.65,.5];
 const top=craftBonus(fast,true);
 assert.equal(top.assemblyPercent,8);assert.equal(top.eloPercent,4);assert.equal(top.totalPercent,12);
 assert.ok(craftBonus(slow).totalPercent<craftBonus(fast).totalPercent);
 assert.ok(craftBonus(misses).totalPercent<craftBonus(fast).totalPercent);
 assert.ok(craftBonus(imprecise).totalPercent<craftBonus(fast).totalPercent);
 const base={hp:100,atk:50,name:'Rabbito'},outcome={type:'born',craftBonus:top};
 assert.deepEqual(applyCraftBonus(base,outcome),{hp:112,atk:56,name:'Rabbito'});assert.equal(base.hp,100);
 assert.deepEqual(applyCraftBonus(base,{type:'broken',craftBonus:top}),base);
});

test('relógio inicia no primeiro gesto e preserva tempo e erros ao refazer etapa',()=>{
 const run=createRun('comum');tickCraft(run,20);assert.equal(run.elapsed[0],0);
 placeRod(run,{x:950,y:600});tickCraft(run,2);assert.equal(run.elapsed[0],2);assert.equal(run.errors[0],1);
 run.blocked='linha';tickCraft(run,20);assert.equal(run.elapsed[0],2);restock(run);tickCraft(run,3);assert.equal(run.elapsed[0],5);assert.equal(run.errors[0],1);
 tickCraft(run,NaN);tickCraft(run,-1);assert.equal(run.elapsed[0],5);
});

test('Elo firme é estreito, premia +4%, e ultrapassá-lo não concede nenhum bônus',()=>{
 const ready=()=>{const r=createRun('comum',{seed:9});r.stage=4;startStage(r);r.grades=[1,1,1,1];return r;};
 const settleAt=f=>{const r=ready();holdSoul(r);r.step.fill=f;return releaseSoul(r).outcome;};
 const safe=settleAt(SOUL_ZONES.safe-.001),firm=settleAt(SOUL_ZONES.safe),over=settleAt(SOUL_ZONES.shine);
 assert.equal(safe.shine,false);assert.equal(safe.craftBonus.eloPercent,0);
 assert.equal(firm.shine,true);assert.equal(firm.craftBonus.eloPercent,4);
 assert.equal(over.type,'broken');assert.equal(over.craftBonus,null);
 assert.equal(safe.variant,firm.variant);assert.equal(safe.chance,1/459);
 for(const kind of Object.keys(CLASSES)){
  const speed=CLASSES[kind].soul.speed;
  const duration=Math.log((SOUL_ZONES.shine+1/3)/(SOUL_ZONES.safe+1/3))/(speed*1.5);
  assert.ok(duration>.07&&duration<.12,kind+': '+duration);
 }
 // Analytical filling gives the same value at 30, 60 and 120 fps.
 const fills=[30,60,120].map(fps=>{const r=ready();holdSoul(r);for(let i=0;i<fps*2;i++)tickSoul(r,1/fps);return r.step.fill;});
 assert.ok(Math.max(...fills)-Math.min(...fills)<1e-10);
});


test('nós: faixa pequena, estável durante o gesto, varia entre nós, sementes e tentativas',()=>{
 for(const kind of Object.keys(CLASSES)){
  const a=createRun(kind,{seed:123}),b=createRun(kind,{seed:123}),c=createRun(kind,{seed:456});rods(a);rods(b);rods(c);
  assert.deepEqual(a.step.windows,b.step.windows);assert.notDeepEqual(a.step.windows,c.step.windows);
  assert.ok(new Set(a.step.windows.map(w=>w[0])).size>1);
  for(const [lo,hi] of a.step.windows){assert.ok(lo>=.22&&hi<=.86);assert.ok(Math.abs(hi-lo-CLASSES[kind].ring.width)<1e-10);assert.ok(hi-lo<=.16000001);}
  const before=[...knotWindow(a,0)],roll=a.variantRoll;holdKnot(a,0);tickKnot(a,.1);assert.deepEqual(knotWindow(a,0),before);releaseKnot(a);
  assert.notDeepEqual(knotWindow(a,0),before);assert.equal(a.variantRoll,roll);assert.equal(a.materials.linha,3);
  assert.equal(holdKnot(a,-1),false);assert.equal(holdKnot(a,99),false);
 }
});

test('variante: 1/459 por nascimento, independente de classe, estrelas, gesto e novas tentativas',()=>{
 assert.equal(VARIANT_ODDS,459);assert.equal(VARIANT_CHANCE,1/459);
 let rareSeed;for(let seed=1;seed<20000;seed++)if(createRun('comum',{seed}).variantRoll<VARIANT_CHANCE){rareSeed=seed;break;}
 assert.ok(rareSeed);
 for(const seed of [rareSeed,7,34])for(const kind of Object.keys(CLASSES))for(const fill of [.41,.7,.79,.89])for(const grade of [.1,1]){
  const run=createRun(kind,{seed});run.stage=4;startStage(run);run.grades=[grade,grade,grade,grade];
  holdSoul(run);run.step.fill=.1;releaseSoul(run);holdSoul(run);run.step.fill=fill;
  const result=releaseSoul(run).outcome;
  assert.equal(result.type,'born');assert.equal(result.variant,run.variantRoll<1/459);assert.equal(result.chance,1/459);
 }
 // Reproducible population sanity check, not a guarantee every 459 births.
 let rare=0;for(let seed=1;seed<=45900;seed++)if(createRun('comum',{seed}).variantRoll<VARIANT_CHANCE)rare++;
 assert.ok(rare>60&&rare<145,String(rare));
});
