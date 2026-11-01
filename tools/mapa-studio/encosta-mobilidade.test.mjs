import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {encosta,ID} from './desenhar-encosta-mobilidade.mjs';
import {compile} from '../import-overworld.mjs';
import {parseTiled} from './model.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
const tiles=JSON.parse(fs.readFileSync(new URL('../../art/overworld/tiles/rascunho.tsj',import.meta.url)));
test('encosta has no geometric breaks; all targets have two-cell walking approaches',()=>{
 const {raw}=encosta(),m=parseTiled(raw,{'rascunho.tsj':tiles});
 const result=auditZeroBreak(m,{frameDepth:3,requiredRoute:[m.spawn,{u:7,v:6},{u:24,v:12}]});
 assert.deepEqual(result.issues.filter(i=>i.level==='fail'&&i.rule!=='Partes da região'),[]);
 assert.ok(result.stats.plateau>=.4);assert.equal(result.stats.unreachable,0);assert.equal(result.stats.loose,0);
 assert.equal(result.stats.items,3);assert.equal(result.stats.hidden,1);
});
test('Tiled source and compiled cells remain reproducible, and regular graph cannot cross the jump',()=>{
 const {raw,links}=encosta(),out=compile(raw,ID);
 assert.deepEqual(raw,encosta().raw);
 const stored=JSON.parse(fs.readFileSync(new URL('../../godot/assets/overworld/maps/'+ID+'.json',import.meta.url)));
 assert.deepEqual(out.cells,stored.cells);assert.deepEqual(links,stored.mobility.links);
 for(const link of links){
  const key=p=>Math.floor(p[1])*out.w+Math.floor(p[0]);
  assert.ok(out.oracle.walkable.includes(key(link.from)));assert.ok(out.oracle.walkable.includes(key(link.to)));
  assert.ok(!out.oracle.edges.some(([a,b])=>a===key(link.from)&&b===key(link.to)));
 }
 assert.equal(links.filter(l=>l.kind==='drop').length,1);
 assert.deepEqual(links[0].from,links[1].to);assert.deepEqual(links[0].to,links[1].from);
});
