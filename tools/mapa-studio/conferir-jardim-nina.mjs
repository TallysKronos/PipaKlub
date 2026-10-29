import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import assert from 'node:assert/strict';
import {parseTiled,audit,verdict,at,canStep,findPath,blockedByPiece,walkable,reachable} from './model.mjs';
import {compile} from '../import-overworld.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
const raw=JSON.parse(fs.readFileSync(root+'art/overworld/mapas/jardim-das-pipas.tmj','utf8'));
if(raw.properties?.some(p=>p.name==='origem'&&p.value==='parque-abc-v1')){
 await import('./conferir-parque-abc.mjs');
 process.exit(0);
}
const sets={'rascunho.tsj':JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj','utf8'))};
const m=parseTiled(raw,sets),items=audit(m),solid=blockedByPiece(m);
assert.equal(verdict(items),'ok',JSON.stringify(items));
const oldIds=[...m.events,...m.pieces].map(o=>o.id);
for(let id=1;id<=42;id++)assert(oldIds.includes(id),`Objeto antigo ${id} perdido`);
const safe={...m,cells:m.cells.map(c=>c.material==='mato'?{...c,material:'bosque'}:c)};
const visits=[];
function visit(target,label){
 const path=findPath(safe,safe.spawn,target,solid);assert(path,`Encontro no mato obrigatório ou destino bloqueado: ${label}`);
 for(let i=1;i<path.length;i++)assert(canStep(safe,path[i-1],path[i],solid));
 assert(findPath(safe,target,safe.spawn,solid),`Sem retorno: ${label}`);
 visits.push({label,celula:target,passos:path.length-1,ida_e_volta:true,sem_mato:true});
}
for(const e of m.events)visit({u:e.u,v:e.v},e.name);
for(const chest of m.pieces.filter(p=>p.asset==='bau')){
 const candidates=[[0,1],[1,0],[0,-1],[-1,0]].map(([du,dv])=>({u:chest.u+du,v:chest.v+dv}));
 const pos=candidates.find(p=>walkable(safe,p.u,p.v,solid)&&findPath(safe,safe.spawn,p,solid));
 assert(pos,`Baú inacessível: ${chest.name}`);visit(pos,chest.name);
}
for(const u of [9,10,11]){
 assert(canStep(m,{u,v:14},{u,v:13},solid));assert(canStep(m,{u,v:13},{u,v:12},solid));
 assert(canStep(m,{u,v:12},{u,v:13},solid));assert(canStep(m,{u,v:13},{u,v:14},solid));
}
assert(!canStep(m,{u:8,v:13},{u:8,v:12},solid),'É possível escalar a parede fora da rampa');
assert(findPath(safe,{u:12,v:24},{u:32,v:9},new Set([...solid,...Array.from({length:12},(_,i)=>(23+Math.floor(i/3))*m.w+21+i%3)])), 'O laço norte não contorna interrupção da trilha principal');
const count=reachable(m,m.spawn,solid).reduce((s,n)=>s+n,0);
const report={area:'jardim-das-pipas',dimensoes:[m.w,m.h],veredito:verdict(items),conferencia:items,visitas:visits,
 celulas_alcancaveis:count,rampas_bidirecionais:3,sem_mato_obrigatorio:true,objetos_antigos_preservados:42,
 status:'planta conferida pelo modelo; inspeção visual e integração narrativa registradas separadamente'};
const dir=root+'art/overworld/revisao/jardim-das-pipas/';fs.mkdirSync(dir,{recursive:true});
fs.writeFileSync(dir+'conferencia.json',JSON.stringify(report,null,2)+'\n');
// Deliberately compile ONE map: build() would rewrite every kit and generated scene.
const compiled=compile(raw,'jardim-das-pipas');
fs.writeFileSync(root+'godot/assets/overworld/maps/jardim-das-pipas.json',JSON.stringify(compiled));
console.log(JSON.stringify({veredito:report.veredito,celulas:count,visitas:visits.length,rampas:3,importacao:'somente jardim-das-pipas'}));
