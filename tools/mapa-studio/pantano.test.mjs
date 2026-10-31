import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {swampPart} from './desenhar-pantano.mjs';
import {compile} from '../import-overworld.mjs';
import {parseTiled} from './model.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
const root=new URL('../../',import.meta.url),ts=JSON.parse(fs.readFileSync(new URL('art/overworld/tiles/rascunho.tsj',root)));
const parts=['A','B','C'].map(swampPart);
test('swamp region is deterministic, reachable and optional encounters do not block exits',()=>{
 const region=parts.map(p=>({id:p.id,part:p.part,map:parseTiled(p.raw,{'rascunho.tsj':ts})}));
 const links=[['a','b'],['b','c']].map(([a,b])=>({from:{area:'kronasta-pantano-'+a,u:24,v:0,direction:'v-'},to:{area:'kronasta-pantano-'+b,u:24,v:39,direction:'v+'}}));
 for(const p of parts){const result=auditZeroBreak(region.find(r=>r.id===p.id).map,{region,links});assert.ok(result.ok,result.lines.join('\n'));assert.ok(result.stats.plateau>=.4);assert.equal(result.stats.items,3);assert.equal(result.stats.hidden,1);
 const saved=JSON.parse(fs.readFileSync(new URL('godot/assets/overworld/maps/'+p.id+'.json',root)));assert.deepEqual(JSON.parse(JSON.stringify(compile(p.raw,p.id))),saved);
 assert.deepEqual(saved.forest.waterTrees,[],'no floating trees in water');
 for(const piece of saved.pieces.filter(p=>p.asset.includes('arvore')))for(let v=piece.v;v<piece.v+piece.fv;v++)for(let u=piece.u;u<piece.u+piece.fu;u++)assert.notEqual(saved.cells[v*saved.w+u].material,'agua','tree footprint must stay on dry ground');
 if(p.part==='C'){
  assert.equal(saved.forest.water.channelDepth,24);assert.equal(saved.forest.water.noBridge,true);assert.equal(saved.forest.arena.combat,false);
  for(const [u,v] of saved.forest.water.channel)assert.ok(Math.abs(Math.hypot(u-24,v-18)-8.5)<1e-5,'shared circular basin contour');
 }else{assert.equal(saved.forest.water.channelDepth,12);assert.equal(saved.forest.water.bridge.w,3);assert.ok(saved.forest.water.channel.length>100);}
 }
});
test('new B route and C arena have different terrain and water topology',()=>{
 const compiled=parts.map(p=>compile(p.raw,p.id));
 assert.equal(compiled[0].forest.water.bridge.u,23);assert.equal(compiled[1].forest.water.bridge.u,34);
 assert.notDeepEqual(compiled[0].cells,compiled[1].cells);assert.notDeepEqual(compiled[1].cells,compiled[2].cells);
 assert.equal(compiled[2].cells.filter(c=>c.material==='ponte').length,0);
});
