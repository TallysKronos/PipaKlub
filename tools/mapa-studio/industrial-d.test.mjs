import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {industrialWarehouse} from './desenhar-industrial-d.mjs';
import {parseTiled,heightAt,canStep} from './model.mjs';
import {industrialPart} from './desenhar-industrial.mjs';
import {compile} from '../import-overworld.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
const ts=JSON.parse(fs.readFileSync(new URL('../../art/overworld/tiles/rascunho.tsj',import.meta.url)));
const source=industrialWarehouse();
const map=()=>parseTiled(source.raw,{'rascunho.tsj':ts});
test('warehouse source compiles reproducibly and dressing cannot change collision',()=>{
 const compiled=compile(source.raw,source.id);
 assert.deepEqual(JSON.parse(JSON.stringify(compiled)),JSON.parse(fs.readFileSync(new URL('../../godot/assets/overworld/maps/'+source.id+'.json',import.meta.url))));
 const flat=compile(industrialWarehouse({dressed:false}).raw,source.id);
 assert.deepEqual(flat.cells,compiled.cells);assert.deepEqual(flat.pieces,compiled.pieces);assert.deepEqual(flat.events,compiled.events);
});
test('warehouse checks routes, items and ramps; does not pretend connections were verified',()=>{
 const result=auditZeroBreak(map(),{guards:source.feature.guards,requireRegion:false,requiredRoute:[map().spawn,...map().events]});
 assert.ok(result.ok,result.lines.join('\n'));assert.equal(result.stats.items,3);assert.equal(result.stats.hidden,1);assert.ok(result.stats.plateau>=.4);
 assert.equal(result.issues.filter(i=>i.level==='warn').length,1);
 assert.ok(!auditZeroBreak(map(),{guards:source.feature.guards}).ok,'default regional requirement stays strict');
});
test('warehouse refuses rail across stair and forward facing ramp',()=>{
 assert.ok(!auditZeroBreak(map(),{requireRegion:false,guards:[{u:15,v:18,side:'u'}]}).ok);
 const broken=map();broken.cells.find(c=>c.ramp).ramp='v+';
 assert.ok(!auditZeroBreak(broken,{requireRegion:false}).ok);
});
test('depot threshold and warehouse door have matching material, elevation and approach',()=>{
 const b=parseTiled(industrialPart('B').raw,{'rascunho.tsj':ts}),d=map();
 const entrance=b.events.find(e=>e.type==='saida'&&e.props.destino===source.id);
 const back=d.events.find(e=>e.type==='saida'&&e.props.destino==='kronasta-industrial-b');
 assert.equal(entrance.props.requer,'golliaCarretelVencida');assert.ok(back);
 assert.equal(b.cells[entrance.v*b.w+entrance.u].material,d.cells[back.v*d.w+back.u].material);
 assert.equal(heightAt(b,entrance.u+.5,entrance.v+.5),heightAt(d,back.u+.5,back.v+.5));
 assert.ok(canStep(b,{u:entrance.u,v:entrance.v+1},entrance));
 assert.ok(canStep(d,back,{u:back.u,v:back.v-1}));
 assert.deepEqual([back.props.chegada_u,back.props.chegada_v],[entrance.u,entrance.v+1]);
 assert.deepEqual([entrance.props.chegada_u,entrance.props.chegada_v],[back.u,back.v-1]);
});
test('branched region requires the warehouse return and a measured connection',()=>{
 const region=[...['A','B','C'].map(part=>{const p=industrialPart(part);return {id:p.id,part,map:parseTiled(p.raw,{'rascunho.tsj':ts})};}),{id:source.id,part:'D',map:map()}];
 const links=[...['a','b'].map((part,i)=>({from:{area:'kronasta-industrial-'+part,u:36,v:0,direction:'v-'},to:{area:'kronasta-industrial-'+['b','c'][i],u:36,v:39,direction:'v+'}})),{from:{area:'kronasta-industrial-b',u:26,v:11,direction:'v-'},to:{area:source.id,u:10,v:35,direction:'v+'}}];
 const options={region,links,adjacencies:[['A','B'],['B','C'],['B','D']],guards:source.feature.guards};
 const result=auditZeroBreak(region[3].map,options);assert.ok(result.ok,result.lines.join('\n'));assert.equal(result.issues.filter(i=>i.level==='warn').length,0);
 assert.ok(!auditZeroBreak(region[3].map,{...options,links:links.slice(0,2)}).ok,'cannot omit warehouse geometry verification');
 region[3].map.events=region[3].map.events.filter(e=>e.type!=='saida');
 assert.ok(!auditZeroBreak(region[3].map,options).ok,'must be able to leave warehouse');
});
