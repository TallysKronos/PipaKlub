import test from 'node:test';
import assert from 'node:assert/strict';
import {CLASSES,FLIGHT_TIME,SOUL_ZONES,geometry,createRun,placeRod,holdKnot,tickKnot,releaseKnot,cutAt,tickFlight,windAt,nextGust,holdSoul,tickSoul,releaseSoul,starsOf,restock,gradeLabel} from './model.mjs';
const rods=run=>{for(const r of geometry(run.kind).rods)placeRod(run,r.mid,0);};
// Segura até a fração pedida do anel e solta.
const knot=(run,i,target)=>{holdKnot(run,i);let out=null;while(run.step.holding!=null&&run.step.fill<target&&!out)out=tickKnot(run,1/120);return out||releaseKnot(run);};
const goodKnots=run=>{const [a,b]=CLASSES[run.kind].ring.green;for(let i=0;i<CLASSES[run.kind].rods;i++)knot(run,i,(a+b)/2);};
const cutAll=(run,offset=0)=>{let r=null;for(const p of geometry(run.kind).samples){r=cutAt(run,{x:p.x+offset,y:p.y},.03)||r;if(run.stage!==2)break;}return r;};
// Controle simples e honesto: reage ao ângulo atual (o jogador "endireita" a pipa).
const fly=(run,gain=.03)=>{let r=null;while(run.stage===3&&!r?.done&&!r?.fell)r=tickFlight(run,1/60,-gain*run.step.theta-.02*run.step.omega);return r;};
test('classe muda a dificuldade, não a repetição: no máximo 6 ações por etapa',()=>{
 for(const [k,c] of Object.entries(CLASSES)){assert.ok(c.rods>=4&&c.rods<=6,k);assert.equal(geometry(k).rods.length,c.rods);}
 assert.ok(CLASSES.raro.snap<CLASSES.comum.snap&&CLASSES.raro.cut.tol<CLASSES.comum.cut.tol&&CLASSES.raro.ring.green[1]-CLASSES.raro.ring.green[0]<CLASSES.comum.ring.green[1]-CLASSES.comum.ring.green[0]);
});
test('armação: encaixe perto e alinhado conclui a etapa; torto ou longe volta sem custo',()=>{
 const run=createRun('raro'),r0=geometry('raro').rods[0];
 assert.equal(placeRod(run,{x:900,y:600}).ok,false);assert.match(placeRod(run,r0.mid,20).msg,/Torta/);assert.deepEqual(run.materials,{linha:3,folha:2});
 rods(run);assert.equal(run.stage,1);assert.ok(run.grades[0]>.95);
});
test('nós: frouxo repete, verde amarra, vermelho arrebenta e gasta linha',()=>{
 const run=createRun('comum');rods(run);const [a,b]=CLASSES.comum.ring.green;
 assert.match(knot(run,0,a-.1).msg,/Frouxo/);assert.equal(run.materials.linha,3);
 assert.equal(knot(run,0,(a+b)/2).ok,true);
 assert.equal(knot(run,1,b+.05).lost,'linha');assert.equal(run.materials.linha,2);
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
test('despertar: soltar no seguro garante, no brilho pode dar variante, passar parte o elo',()=>{
 const ready=k=>{const run=createRun(k,{seed:11});rods(run);goodKnots(run);cutAll(run);fly(run);assert.equal(run.stage,4);return run;};
 const hold=(run,target)=>{holdSoul(run);let r=null;while(run.step.holding&&run.step.fill<target&&!r)r=tickSoul(run,1/120);return r||releaseSoul(run);};
 let run=ready('comum');assert.match(hold(run,.2).msg,/não pegou/);assert.equal(hold(run,(SOUL_ZONES.weak+SOUL_ZONES.safe)/2).outcome.type,'born');assert.equal(run.outcome.shine,false);
 run=ready('comum');const shine=hold(run,(SOUL_ZONES.safe+SOUL_ZONES.shine)/2).outcome;assert.equal(shine.shine,true);assert.ok(shine.chance>=.25&&shine.chance<=.65);
 run=ready('comum');assert.equal(hold(run,2).outcome.type,'broken');
 assert.ok(starsOf(run)>=3);assert.equal(gradeLabel(.9),'Perfeito');
});
test('modo artesão soma bônus de nota em cada etapa',()=>{
 const a=createRun('incomum',{artesao:true}),b=createRun('incomum');rods(a);rods(b);
 assert.ok(a.grades[0]>=b.grades[0]);assert.ok(a.grades[0]-b.grades[0]<=.0600001);
});
