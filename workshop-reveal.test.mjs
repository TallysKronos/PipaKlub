import test from 'node:test';
import assert from 'node:assert/strict';
import {createReveal,revealStrike,revealScore,REVEAL_AREA,REVEAL_FAIL} from './src/workshop-reveal.js';
import {workshopPayload,validWorkshopPayload,workshopInput} from './src/workshop-model.js';

const mask=(x,y)=>Math.abs(x)/90+Math.abs(y+20)/120<=1;
const sweep=(s,tool,step,onlyCovered=true)=>{for(let y=REVEAL_AREA.y+4;y<REVEAL_AREA.y+REVEAL_AREA.h;y+=step)for(let x=REVEAL_AREA.x+4;x<REVEAL_AREA.x+REVEAL_AREA.w;x+=step){const c=s.cells.find(q=>Math.abs(q.x-x)<=3&&Math.abs(q.y-y)<=3);if(!onlyCovered||(c&&c.cover>.05))revealStrike(s,tool,x,y);}};

test('a folha é reproduzível pela semente e começa coberta',()=>{
 const a=createReveal(mask,7),b=createReveal(mask,7);assert.deepEqual(a.cells.map(c=>c.cover),b.cells.map(c=>c.cover));assert.equal(revealScore(a).revealed,0);
});
test('estilete e depois tesourinha revelam com nota alta; martelar a marca exposta rasga e faz a folha ceder',()=>{
 const good=createReveal(mask,3);sweep(good,'estilete',34,false);for(let k=0;k<6&&!revealScore(good).done;k++)sweep(good,'tesourinha',6);
 const g=revealScore(good);assert.ok(g.done&&g.score>=80&&!g.failed,JSON.stringify(g));
 const bad=createReveal(mask,3);for(let k=0;k<8;k++)sweep(bad,'estilete',20,false);assert.ok(revealScore(bad).damage>=REVEAL_FAIL&&revealScore(bad).failed);
});
test('payload da etapa do papel: aceita o contorno antigo e o novo com a nota, recusa nota inválida',()=>{
 assert.ok(validWorkshopPayload(2,{cuts:[0,1,2,3]}));
 assert.ok(validWorkshopPayload(2,workshopPayload(2,{...workshopInput(),cuts:[0,1,2,3],revealScore:87.4})));
 assert.deepEqual(workshopPayload(2,{...workshopInput(),cuts:[0,1,2,3],revealScore:87.4}),{cuts:[0,1,2,3],reveal:87});
 for(const reveal of [101,-1,50.5,'90'])assert.equal(validWorkshopPayload(2,{cuts:[0,1,2,3],reveal}),false);
 assert.equal(validWorkshopPayload(2,{cuts:[0,1,2,3],reveal:90,extra:1}),false);
});
