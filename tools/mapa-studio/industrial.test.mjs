import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {industrialPart} from './desenhar-industrial.mjs';
import {compile} from '../import-overworld.mjs';
import {parseTiled} from './model.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
const root=new URL('../../',import.meta.url);
const read=p=>JSON.parse(fs.readFileSync(new URL(p,root)));
const ts=read('art/overworld/tiles/rascunho.tsj');
const parts=['A','B','C'].map(industrialPart);
test('industrial source matches compiled geometry and every footprint owns its volume',()=>{
 for(const p of parts){const c=read('godot/assets/overworld/maps/'+p.id+'.json');assert.deepEqual(JSON.parse(JSON.stringify(compile(p.raw,p.id))),c);
  for(const b of c.forest.buildings){const prop=c.pieces.find(q=>q.name===b.name);assert.ok(prop.blocks);assert.equal(prop.fu,b.w);assert.equal(prop.fv,b.h);}
 }
});
test('industrial parts preserve reachable materials and optional exit loop',()=>{
 const region=parts.map(p=>({id:p.id,part:p.part,map:parseTiled(p.raw,{'rascunho.tsj':ts})}));
 const links=[['A','B'],['B','C']].map(([a,b])=>({from:{area:'kronasta-industrial-'+a.toLowerCase(),u:36,v:0,direction:'v-'},to:{area:'kronasta-industrial-'+b.toLowerCase(),u:36,v:39,direction:'v+'}}));
 for(const p of parts){const result=auditZeroBreak(region.find(r=>r.id===p.id).map,{region,links,guards:p.feature.guards});assert.ok(result.ok,result.lines.join('\n'));assert.equal(result.stats.items,3);assert.equal(result.stats.hidden,1);}
 const end=parts[2].raw.layers.find(l=>l.name==='eventos').objects;assert.ok(end.some(e=>e.properties.some(p=>p.name==='destino'&&p.value==='kronasta-industrial-a')));
});
