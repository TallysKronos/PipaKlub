import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {mountainPart} from './desenhar-montanha.mjs';
import {compile} from '../import-overworld.mjs';
import {parseTiled} from './model.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
const root=new URL('../../',import.meta.url),source=JSON.parse(fs.readFileSync(new URL('art/overworld/tiles/rascunho.tsj',root)));
const parts=['A','B','C'].map(mountainPart),compiled=parts.map(p=>compile(p.raw,p.id));
function path(map,goal,blocked=new Set()){
 const start=map.spawn.v*map.w+map.spawn.u,end=goal.v*map.w+goal.u;
 const edges=new Map();for(const [a,b]of map.oracle.edges)if(!blocked.has(a)&&!blocked.has(b)){if(!edges.has(a))edges.set(a,[]);edges.get(a).push(b);}
 const q=[start],prev=new Map([[start,null]]);for(let i=0;i<q.length;i++)for(const b of edges.get(q[i])||[])if(!prev.has(b)){prev.set(b,q[i]);q.push(b);}
 if(!prev.has(end))return[];const route=[];for(let k=end;k!==null;k=prev.get(k))route.unshift(k);return route;
}
test('mountain sources compile deterministically and all regional checks pass',()=>{
 const region=parts.map(p=>({id:p.id,part:p.part,map:parseTiled(p.raw,{'rascunho.tsj':source})}));
 const links=[['a','b'],['b','c']].map(([a,b])=>({from:{area:'kronasta-montanha-'+a,u:24,v:0,direction:'v-'},to:{area:'kronasta-montanha-'+b,u:24,v:47,direction:'v+'}}));
 for(const [n,p]of parts.entries()){
  const m=region[n].map,result=auditZeroBreak(m,{region,links,requiredRoute:[m.spawn,...m.events.filter(e=>e.type==='saida'||e.name==='Mirante do cume')]});assert.ok(result.ok,result.lines.join('\n'));
  assert.deepEqual(JSON.parse(JSON.stringify(compiled[n])),JSON.parse(fs.readFileSync(new URL('godot/assets/overworld/maps/'+p.id+'.json',root))));
 }
});
test('reaching each summit requires real ascending ramps and preserves absolute elevations',()=>{
 for(const [n,map]of compiled.entries()){
  const target=n===2?map.events.find(e=>e.name==='Mirante do cume'):map.events.find(e=>e.props.destino==='kronasta-montanha-'+String.fromCharCode(98+n));
  const route=path(map,target);assert.ok(route.length>35);
  assert.equal(map.cells[route[0]].level,n*2);assert.equal(map.cells[route.at(-1)].level,n*2+2);
  const ramps=route.map(i=>map.cells[i]).filter(c=>c.ramp);assert.ok(ramps.some(c=>c.level===n*2));assert.ok(ramps.some(c=>c.level===n*2+1));
  for(const [u,v]of map.forest.deadEnds)assert.ok(path(map,{u,v}).length,'every dead end has a reachable reward/view');
 }
 assert.equal(compiled[0].cells[24].level,compiled[1].cells[47*56+24].level);
 assert.equal(compiled[1].cells[24].level,compiled[2].cells[47*56+24].level);
});
test('C has a walkable return loop independent of its first ascent',()=>{
 const map=compiled[2],blocked=new Set();for(let v=36;v<=37;v++)for(let u=12;u<=14;u++)blocked.add(v*map.w+u);
 assert.ok(path(map,map.events.find(e=>e.name==='Mirante do cume'),blocked).length>0);
});

test('revised mountain has connected support rather than hollow corridor islands',()=>{
 for(const map of compiled){
  const ground=map.cells.filter(c=>c.level>=0);assert.ok(ground.length/map.cells.length>.75,'most of the footprint is real continuous mountain');
  assert.ok(map.cells.filter(c=>c.material==='rocha'&&c.level>=0).length>ground.length*.4,'paths are cut through a supported rock mass');
  assert.equal(map.forest.artRevision,2);
 }
});
