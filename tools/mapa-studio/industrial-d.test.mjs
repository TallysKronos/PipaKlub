import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {industrialWarehouse} from './desenhar-industrial-d.mjs';
import {parseTiled} from './model.mjs';
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
