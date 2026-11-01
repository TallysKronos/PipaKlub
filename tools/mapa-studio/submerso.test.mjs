import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {submergedPart,W,H,ENTRY} from './desenhar-submerso.mjs';
import {compile} from '../import-overworld.mjs';
import {parseTiled} from './model.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
const root=new URL('../../',import.meta.url),source=JSON.parse(fs.readFileSync(new URL('art/overworld/tiles/rascunho.tsj',root)));
const parts=['A','B','C'].map(submergedPart),maps=parts.map(p=>compile(p.raw,p.id));
function route(m,target,blocked=new Set()){
 const start=m.spawn.v*W+m.spawn.u,end=target.v*W+target.u,edges=new Map();for(const[a,b]of m.oracle.edges)if(!blocked.has(a)&&!blocked.has(b)){if(!edges.has(a))edges.set(a,[]);edges.get(a).push(b);}const q=[start],seen=new Set(q);for(let i=0;i<q.length;i++)for(const b of edges.get(q[i])||[])if(!seen.has(b)){seen.add(b);q.push(b);}return seen.has(end);
}
test('submerged sources match runtime maps and pass zero-break regional audit without warnings',()=>{
 const region=parts.map(p=>({id:p.id,part:p.part,map:parseTiled(p.raw,{'rascunho.tsj':source})})),links=[['a','b'],['b','c']].map(([a,b])=>({from:{area:'submerso-'+a,u:ENTRY,v:0,direction:'v-'},to:{area:'submerso-'+b,u:ENTRY,v:H-1,direction:'v+'}}));
 for(const[n,p]of parts.entries()){const m=region[n].map,r=auditZeroBreak(m,{region,links,requiredRoute:[m.spawn,...m.events.filter(e=>e.type==='saida'||e.name==='Colônia do recife')]});assert.ok(r.ok,r.lines.join('\n'));assert.ok(!r.lines.some(s=>s.startsWith('AVISO')),r.lines.join('\n'));assert.deepEqual(JSON.parse(JSON.stringify(maps[n])),JSON.parse(fs.readFileSync(new URL('godot/assets/overworld/maps/'+p.id+'.json',root))));}
});
test('seabed is solid terrain at three elevations, with matching regional transitions and real ascents',()=>{
 for(let n=0;n<2;n++){assert.equal(maps[n].cells[ENTRY].level,maps[n+1].cells[(H-1)*W+ENTRY].level);assert.equal(maps[n].cells[ENTRY].material,maps[n+1].cells[(H-1)*W+ENTRY].material);}
 for(const m of maps){assert.ok(m.forest.submerged);assert.ok(!m.cells.some(c=>c.material==='agua'),'water column is not painted as a blocking lake');const b=m.forest.baseLevel;for(let h=b;h<=b+2;h++)assert.ok(m.cells.filter(c=>c.level===h&&!c.ramp).length>=140);const goal=m.events.find(e=>e.type==='item'&&m.cells[e.v*W+e.u].level===b+2);assert.ok(goal&&route(m,goal));const blocked=new Set();for(const a of m.forest.accesses.filter(a=>a.level===b+1))for(let v=a.v;v<=a.v+1;v++)for(let u=a.u;u<a.u+a.width;u++)blocked.add(v*W+u);assert.ok(!route(m,goal,blocked),'cliff cannot substitute for upper ramp');}
});
test('every prop has uniform support; kelp forms masses and every reward stays reachable',()=>{
 for(const m of maps){const kelp=m.pieces.filter(p=>p.props.variante==='alga');assert.ok(kelp.length>=24);for(const k of kelp)assert.ok(kelp.some(q=>q!==k&&Math.max(Math.abs(q.u-k.u),Math.abs(q.v-k.v))<=1));assert.equal(m.events.filter(e=>e.type==='item').length,3);assert.equal(m.events.filter(e=>e.type==='item'&&e.props.visibilidade==='escondido').length,1);for(const e of m.events)assert.ok(route(m,e),'event '+e.name);for(const p of m.pieces){const levels=new Set();for(let v=p.v;v<p.v+p.fv;v++)for(let u=p.u;u<p.u+p.fu;u++){const c=m.cells[v*W+u];assert.ok(c.level>=0,m.id+' unsupported '+p.name);assert.equal(c.ramp,null);levels.add(c.level);}assert.equal(levels.size,1,'uniform support '+p.name);}}
});
test('abyss is an actual connected cut with two walkable banks and no stray single-cell holes',()=>{
 const m=maps[2];for(let v=1;v<H-1;v++)for(let u=1;u<W-1;u++){const i=v*W+u;if(m.cells[i].level>=0)continue;assert.ok([i-1,i+1,i-W,i+W].some(j=>m.cells[j].level<0));}
 for(let v=32;v<40;v++)for(let u=26;u<30;u++)assert.equal(m.cells[v*W+u].level,-2);
 const goal=m.events.find(e=>e.name==='Colônia do recife');for(const[a,b]of[[4,26],[32,52]]){const blocked=new Set();for(let v=32;v<41;v++)for(let u=a;u<b;u++)blocked.add(v*W+u);assert.ok(route(m,goal,blocked));}
});
