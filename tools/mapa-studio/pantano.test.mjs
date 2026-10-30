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
 assert.equal(saved.forest.water.channelDepth,12);assert.equal(saved.forest.water.bridge.w,3);assert.ok(saved.forest.water.channel.length>100);
 }
});
