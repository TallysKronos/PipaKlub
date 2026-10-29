import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import assert from 'node:assert/strict';
import {parseTiled,audit,verdict,blockedByPiece,reachable,walkable,findPath,canStep,heightAt} from './model.mjs';
import {configs} from './parque-abc.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
const output=root+'art/overworld/revisao/parque-abc/';
const sets={'rascunho.tsj':JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj','utf8'))};
const P=o=>Object.fromEntries((o.properties||[]).map(p=>[p.name,p.value]));
const report={region:'parque-dos-ventos',areas:[],failures:[],warnings:[],scope:'planta e grafo regional; sem concessão de itens, saves ou campanha'};
const documents=configs.map(c=>JSON.parse(fs.readFileSync(root+`art/overworld/mapas/${c.id}.tmj`,'utf8')));
assert.deepEqual(documents.map(m=>P(m).parte),['A','B','C']);
for(let index=0;index<documents.length;index++){
 const raw=documents[index],c=configs[index],m=parseTiled(raw,sets),solid=blockedByPiece(m),seen=reachable(m,m.spawn,solid);
 const issues=audit(m);assert.equal(verdict(issues),'ok',JSON.stringify(issues));
 assert(m.w>=40&&m.w<=72&&m.h>=32&&m.h<=56,'Dimensões fora da faixa regional');
 const raised=m.cells.filter(p=>p.level>0).length/m.cells.length;
 assert(raised>=.4,`${c.id}: menos de 40% em platôs`);
 const original=JSON.parse(fs.readFileSync(output+`antes-${c.id}.tmj`,'utf8'));
 const oldIds=original.layers.flatMap(l=>l.objects||[]).filter(o=>o.id<=c.maxOld).map(o=>o.id);
 const ids=raw.layers.flatMap(l=>l.objects||[]).map(o=>o.id);
 assert.equal(new Set(ids).size,ids.length,'ID duplicado');
 for(const id of oldIds)assert(ids.includes(id),'Objeto existente perdido: '+id);
 const items=m.events.filter(e=>e.type==='item');
 assert(items.length>=3,'Menos de três itens');assert(items.some(e=>e.props.visibilidade==='escondido'),'Sem item escondido');
 for(const item of items){assert(['linha','folha'].includes(item.props.item),'ID não identificado nos materiais da oficina');assert(item.props.quantidade>=1,'Quantidade inválida');}
 const safe={...m,cells:m.cells.map(p=>p.material==='mato'?{...p,material:'bosque'}:p)};
 const visits=[];
 const targets=[...m.events,...m.pieces.filter(p=>p.interact)];
 for(const e of targets){
  const candidates=[[0,0],[1,0],[-1,0],[0,1],[0,-1]].map(([du,dv])=>({u:e.u+du,v:e.v+dv}));
  const destination=candidates.find(p=>walkable(safe,p.u,p.v,solid)&&findPath(safe,safe.spawn,p,solid));
  assert(destination,`${c.id}: ${e.name} exige mato ou é inalcançável`);
  const route=findPath(safe,safe.spawn,destination,solid);
  for(let i=1;i<route.length;i++)assert(canStep(m,route[i-1],route[i],solid),'Rota pulou desnível');
  assert(findPath(safe,destination,safe.spawn,solid),'Sem rota de retorno');
  visits.push({id:e.id,name:e.name,steps:route.length-1,seconds_minimum_at_3_cells_s:Math.round((route.length-1)/3*10)/10,
   requires:e.props?.requer||null,return:true,no_forced_grass:true});
 }
 const overlap=new Map();
 for(const p of m.pieces)if(p.blocks)for(let du=0;du<p.fu;du++)for(let dv=0;dv<p.fv;dv++){
  const k=(p.v+dv)*m.w+p.u+du;assert(!overlap.has(k),`Peças sobrepostas: ${p.name}/${overlap.get(k)}`);overlap.set(k,p.name);
 }
 const rampChecks=[];
 for(let v=0;v<m.h;v++)for(let u=0;u<m.w;u++){
  const cell=m.cells[v*m.w+u];if(!cell.ramp)continue;
  const [du,dv]=cell.ramp==='v-'?[0,-1]:[-1,0],lo={u:u-du,v:v-dv},r={u,v},hi={u:u+du,v:v+dv};
  assert(canStep(m,lo,r,solid)&&canStep(m,r,hi,solid)&&canStep(m,hi,r,solid)&&canStep(m,r,lo,solid),'Rampa sem ida e volta');
  assert(seen[v*m.w+u],'Rampa fora do percurso acessível');
  assert(Math.abs(heightAt(m,u+.5,v+.5)-.5)<.00001,'Plano da rampa divergente');
  rampChecks.push([u,v]);
 }
 const neighbours=m.events.filter(e=>e.type==='saida').map(e=>e.props.destino);
 if(c.part==='B'){
  const withoutCentral={...safe,cells:safe.cells.map((cell,i)=>{const u=i%m.w,v=Math.floor(i/m.w);return u>=31&&u<=33&&v>=28&&v<=32?{...cell,material:'bosque'}:cell;})};
  const exit=m.events.find(e=>e.type==='saida'&&e.props.destino==='park-veredas');
  assert(findPath(withoutCentral,m.spawn,exit,solid),'Ponte alternativa não mantém ligação B→C');
  const withoutBridges={...safe,cells:safe.cells.map(cell=>cell.material==='ponte'?{...cell,material:'bosque'}:cell)};
  assert(findPath(withoutBridges,m.spawn,exit,solid),'Circuito alto não oferece alternativa de exploração');
 }
 if(index>0)assert(neighbours.includes(configs[index-1].scene),'Saída anterior ausente');
 if(index<2)assert(neighbours.includes(configs[index+1].scene),'Saída seguinte ausente');
 const unimplemented=['requer','ocultar_apos','entrada_destino'];
 for(const e of m.events)if(unimplemented.some(k=>e.props[k]!=null))report.warnings.push(`${c.id}/${e.id}: condições são dados propostos; a prévia atual não as aplica.`);
 const forward=visits.find(v=>m.events.some(e=>e.id===v.id&&e.type==='saida'&&e.props.destino===configs[index+1]?.scene));
 if(forward&&forward.seconds_minimum_at_3_cells_s<60)report.warnings.push(`${c.id}: travessia mínima ${forward.seconds_minimum_at_3_cells_s}s; meta de 1–3min ainda não validada com conteúdo.`);
 report.areas.push({id:c.id,part:c.part,size:[m.w,m.h],verdict:'ok',raised_percent:Math.round(raised*10000)/100,
  reachable:seen.reduce((a,b)=>a+b,0),raised_walkable:m.cells.filter((cell,i)=>cell.level>0&&seen[i]).length,
  piece_count:m.pieces.length,tree_count:m.pieces.filter(p=>p.asset==='arvore').length,item_count:items.length,
  ramps:rampChecks,visits,preserved_ids:oldIds.length,source:root+`art/overworld/mapas/${c.id}.tmj`});
}
const end=documents[2].layers.find(l=>l.name==='eventos').objects.find(e=>e.type==='saida'&&P(e).destino==='park-trail');
assert(end&&P(end).requer==='guardianDefeated','Atalho C→A não depende da vitória');
for(const index of [1,2]){
 const source=documents[index],destination=documents[index===1?2:1],events=source.layers.find(l=>l.name==='eventos').objects;
 const high=events.find(e=>e.type==='saida'&&P(e).entrada_destino);
 assert(high,'Ligação alta ausente');
 const target=destination.layers.find(l=>l.name==='eventos').objects.find(e=>e.type==='entrada'&&P(e).entrada===P(high).entrada_destino);
 assert(target,'A rota alta não tem chegada correspondente');
 assert.notEqual(target.id,destination.layers.find(l=>l.name==='eventos').objects.find(e=>e.type==='entrada').id,'Rota alta volta para a mesma entrada');
}
report.graph={A:['B','Rua dos Ventos'],B:['A','C pela trilha baixa','C pelo mirante alto'],C:['B pela trilha baixa','B pelo canal alto','A após guardianDefeated']};
fs.writeFileSync(output+'conferencia.json',JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({areas:report.areas.map(a=>({id:a.id,raised:a.raised_percent,reachable:a.reachable,items:a.item_count,targets:a.visits.length})),failures:0,warnings:report.warnings}));
