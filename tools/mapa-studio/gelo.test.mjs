import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {icePart,W,H,ENTRY} from './desenhar-gelo.mjs';
import {compile} from '../import-overworld.mjs';
import {parseTiled} from './model.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
const root=new URL('../../',import.meta.url),source=JSON.parse(fs.readFileSync(new URL('art/overworld/tiles/rascunho.tsj',root)));
const parts=['A','B','C','D'].map(icePart),maps=parts.map(p=>compile(p.raw,p.id));
function route(m,target,blocked=new Set()) {
 const start=m.spawn.v*m.w+m.spawn.u,end=target.v*m.w+target.u,edges=new Map();
 for(const[a,b]of m.oracle.edges)if(!blocked.has(a)&&!blocked.has(b)){if(!edges.has(a))edges.set(a,[]);edges.get(a).push(b);}
 const q=[start],seen=new Set(q);for(let i=0;i<q.length;i++)for(const b of edges.get(q[i])||[])if(!seen.has(b)){seen.add(b);q.push(b);}return seen.has(end);
}
const blockAccess=(m,a)=>new Set(Array.from({length:a.width*2},(_,n)=>(a.v+Math.floor(n/a.width))*m.w+a.u+n%a.width));
test('ice maps are deterministic and all regional zero-break checks pass without warnings',()=>{
 const region=parts.map(p=>({id:p.id,part:p.part,map:parseTiled(p.raw,{'rascunho.tsj':source})}));
 const links=[['a','b'],['b','c'],['c','d']].map(([a,b])=>({from:{area:'gelo-'+a,u:ENTRY,v:0,direction:'v-'},to:{area:'gelo-'+b,u:ENTRY,v:H-1,direction:'v+'}}));
 for(const[n,p]of parts.entries()){const m=region[n].map,r=auditZeroBreak(m,{region,links,requiredRoute:[m.spawn,...m.events.filter(e=>e.type==='saida'||e.name==='Formação glacial')]});assert.ok(r.ok,r.lines.join('\n'));assert.ok(!r.lines.some(s=>s.startsWith('AVISO')),r.lines.join('\n'));assert.deepEqual(JSON.parse(JSON.stringify(maps[n])),JSON.parse(fs.readFileSync(new URL('godot/assets/overworld/maps/'+p.id+'.json',root))));}
});
test('links match altitude and material; frozen patches stay supported and the lake has a traversable interior',()=>{
 for(let n=0;n<3;n++){assert.equal(maps[n].cells[ENTRY].level,maps[n+1].cells[(H-1)*W+ENTRY].level);assert.equal(maps[n].cells[ENTRY].material,maps[n+1].cells[(H-1)*W+ENTRY].material);}
 for(const m of maps)for(const p of m.forest.icePatches){assert.ok(p.cells.length>20);const levels=new Set(p.cells.map(([u,v])=>m.cells[v*W+u].level));assert.equal(levels.size,1,'each lake patch belongs to one plateau');for(const[u,v]of p.cells)assert.equal(m.cells[v*W+u].ramp,null);}
 const m=maps[1];assert.ok(m.cells.filter(c=>c.material==='piso').length>180);assert.equal(m.cells[35*W+28].material,'piso');assert.ok(route(m,{u:28,v:35}));
});
test('crevasse is a connected real void; both banks offer independent routes, with no isolated pinholes',()=>{
 const m=maps[2];for(let v=1;v<H-1;v++)for(let u=1;u<W-1;u++){const i=v*W+u;if(m.cells[i].level>=0)continue;assert.ok([i-1,i+1,i-W,i+W].some(j=>m.cells[j].level<0),'no single-cell hole');}
 for(let v=32;v<40;v++)for(let u=26;u<30;u++){assert.equal(m.cells[v*W+u].level,-2);assert.equal(m.cells[v*W+u].material,'rocha');}
 for(const[a,b]of[[4,26],[32,52]]){const blocked=new Set();for(let v=32;v<41;v++)for(let u=a;u<b;u++)blocked.add(v*W+u);assert.ok(route(m,{u:ENTRY,v:0},blocked),'the other bank remains open');}
});
test('all three floors are reached through ascents; summit has two independent paths at both height changes',()=>{
 for(const m of maps){const b=m.forest.baseLevel;for(let h=b;h<=b+2;h++)assert.ok(m.cells.filter(c=>c.level===h&&!c.ramp).length>=140,'substantial floor '+h);const goal=m.events.find(e=>e.type==='item'&&m.cells[e.v*W+e.u].level===b+2);assert.ok(goal&&route(m,goal));const upper=m.forest.accesses.filter(a=>a.level===b+1);const blocked=new Set(upper.flatMap(a=>[...blockAccess(m,a)]));assert.ok(!route(m,goal,blocked),'upper floor cannot be reached by walking through cliff');}
 const d=maps[3],goal=d.events.find(e=>e.name==='Formação glacial');for(const a of d.forest.accesses)assert.ok(route(d,goal,blockAccess(d,a)),'each single ramp has a valid alternate');
});
test('groves leave access mouths clear; props have level support, and every reward is reachable',()=>{
 for(const m of maps){const trees=m.pieces.filter(p=>p.props.variante==='pinheiro');assert.ok(trees.length>=24,'forest mass');for(const t of trees)assert.ok(trees.some(q=>q!==t&&Math.max(Math.abs(q.u-t.u),Math.abs(q.v-t.v))<=1),'trees belong to masses');assert.equal(m.events.filter(e=>e.type==='item').length,3);assert.equal(m.events.filter(e=>e.type==='item'&&e.props.visibilidade==='escondido').length,1);
  for(const e of m.events.filter(e=>e.type==='item'))assert.ok(route(m,e));
  for(const p of m.pieces){const levels=new Set();for(let v=p.v;v<p.v+p.fv;v++)for(let u=p.u;u<p.u+p.fu;u++){const c=m.cells[v*W+u];assert.ok(c.level>=0,m.id+' floating '+p.name);assert.equal(c.ramp,null);levels.add(c.level);}assert.equal(levels.size,1,m.id+' uneven '+p.name);}
 }
});
