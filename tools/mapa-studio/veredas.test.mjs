import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {compile} from '../import-overworld.mjs';
import {parseTiled,reachable,blockedByPiece} from './model.mjs';
const root=new URL('../../',import.meta.url);
const read=p=>JSON.parse(fs.readFileSync(new URL(p,root)));
const raw=read('art/overworld/mapas/veredas-do-encanamento.tmj');
const compiled=read('godot/assets/overworld/maps/veredas-do-encanamento.json');
const source=read('art/overworld/briefs/veredas-do-encanamento-origem.json');

test('Veredas preserves five chest identities and guards a real bridged channel',()=>{
 assert.equal(compiled.pieces.filter(p=>p.asset==='bau').length,5);
 assert.equal(compiled.cells.filter(c=>c.material==='ponte').length,18);
 assert.equal(compiled.forest.water.channelDepth,6);
 assert.equal(compiled.forest.water.contour.length,0);
 assert.equal(compiled.forest.water.fall,undefined);
 assert.equal(compiled.forest.followTrail,true);
 const actions=compiled.events.map(e=>e.props.acao);
 for(const action of ['parkBoss','veredasTail','veredasNina','veredasTrace','veredasPipes'])assert.ok(actions.includes(action));
});
test('Veredas preserves every old object ID, action and destination while replacing the layout',()=>{
 const objects=raw.layers.filter(l=>l.objects).flatMap(l=>l.objects);
 const property=(o,k)=>o.properties?.find(p=>p.name===k)?.value;
 for(const original of source.layers.flatMap(l=>l.objects)){
  const current=objects.find(o=>o.id===original.id);assert.ok(current,original.name);
  assert.equal(current.name,original.name);assert.equal(current.type,original.type);
  for(const key of ['acao','destino','asset'])assert.equal(property(current,key),property(original,key));
 }
 assert.equal(new Set(objects.map(o=>o.id)).size,objects.length);
});
test('Veredas compiled data includes the same measured structures as its Tiled source',()=>{
 assert.deepEqual(JSON.parse(JSON.stringify(compile(raw,'veredas-do-encanamento'))),compiled);
 assert.equal(compiled.scene,'park-veredas');
 assert.ok(compiled.forest.guards.length>=8);
});
test('Veredas has four reachable material rewards and preserves the mission tail elsewhere',()=>{
 const m=parseTiled(raw,{'rascunho.tsj':read('art/overworld/tiles/rascunho.tsj')});
 const seen=reachable(m,m.spawn,blockedByPiece(m));
 const items=m.events.filter(e=>e.type==='item');assert.equal(items.length,4);
 for(const e of items){assert.ok(seen[e.v*m.w+e.u],e.name);assert.ok(['papel-seda','cola-reparo','vareta-bambu'].includes(e.props.item));}
 assert.ok(items.some(e=>e.props.visibilidade==='escondido'));
 const veredas=read('godot/assets/overworld/maps/veredas-do-encanamento.json');
 assert.ok(veredas.events.some(e=>e.props.acao==='veredasTail'));
});
