// PIP-81 authored source edits. Never invokes the legacy geometry importer.
import fs from 'node:fs';
import crypto from 'node:crypto';
import {parseTiled,audit,verdict,walkable,blockedByPiece,findPath} from '../mapa-studio/model.mjs';
const dir='art/overworld/mapas/',out='documentation/overworld/pip81';
fs.mkdirSync(out,{recursive:true});
const sets={'rascunho.tsj':JSON.parse(fs.readFileSync('art/overworld/tiles/rascunho.tsj','utf8'))};
const prop=(name,value)=>({name,type:typeof value==='number'?'int':'string',value});
function put(o,name,value){o.properties??=[];const p=o.properties.find(p=>p.name===name);if(p)p.value=value;else o.properties.push(prop(name,value));}
function move(raw,id,u,v){const p=raw.layers.find(l=>l.name==='pecas').objects.find(p=>p.id===id);if(!p)throw Error('Missing authored piece '+id);p.x=u*32+16;p.y=v*32+16;}
const report=[];
for(const file of fs.readdirSync(dir).filter(f=>f.endsWith('.tmj')&&!f.startsWith('veredas-piloto')).sort()){
 const text=fs.readFileSync(dir+file,'utf8'),indent=text.match(/\n( +)"/)?.[1]?.length||1;
 const raw=JSON.parse(text),before=parseTiled(raw,sets),changes=[];
 const pieces=raw.layers.find(l=>l.name==='pecas');
 if(file==='jardim-das-pipas.tmj'){
  move(raw,20,2,4);move(raw,34,2,7);move(raw,32,3,9);move(raw,33,19,9);
  changes.push('Árvore e poste retirados da pegada do coreto; lixeiras separadas do vaso e do poste.');
 }
 if(file==='clareira-do-papel.tmj'){
  move(raw,29,3,9);move(raw,30,19,9);
  changes.push('Lixeiras separadas do vaso e do poste. Mato alto e saídas preservados.');
 }
 if(file==='morro-laje-dos-ventos.tmj'){
  move(raw,1,6,3);changes.push('Varal aproximado da laje, fora da circulação e sem sobrepor casas.');
 }
 if(file==='morro-mirante-da-caixa-dagua.tmj'){
  pieces.objects=pieces.objects.filter(o=>!(o.id===18&&o.properties?.some(p=>p.name==='origem'&&p.value==='PIP-87 vestir lote bloqueado')));
  move(raw,2,7,2);changes.push('Guarda-corpo aproximado do patamar superior, junto à caixa-d’água; substitui uma casa gerada automaticamente em lote bloqueado.');
 }
 if(file==='morro-parque-dos-ventos.tmj'){
  pieces.objects=pieces.objects.filter(o=>!(o.id===20&&o.properties?.some(p=>p.name==='origem'&&p.value==='PIP-87 vestir lote bloqueado')));
  move(raw,1,6,4);changes.push('Árvore grande aproximada da borda do gramado; substitui uma casa gerada automaticamente, sem bloquear o parque.');
 }
 if(file==='rua-dos-ventos.tmj'){
  const doors=[[1,7,10,'Casa de Kael'],[2,21,10,'Casa do Sr. Assis'],[3,35,10,'Loja de pipas']];
  for(const[id,u,v,name]of doors){const p=pieces.objects.find(p=>p.id===id);p.name=name;put(p,'porta_u',u);put(p,'porta_v',v);put(p,'frente','v+');}
  const definitions=[['Fundos residenciais',0,0,44,6,'fundo-de-casa'],['Quintal de Kael',2,6,10,4,'quintal'],['Quintal do Sr. Assis',16,6,10,4,'quintal'],['Jardim da loja',29,6,11,4,'jardim'],['Praça e serviços',14,22,13,5,'praca'],['Trilha para o parque',26,27,4,4,'saida-parque']];
  const existing=raw.layers.find(l=>l.name==='zonas');
  const nextLayer=raw.layers.reduce((n,l)=>Math.max(n,l.id||0),0)+1;
  const layer=existing||{id:nextLayer,name:'zonas',type:'objectgroup',opacity:1,visible:true,x:0,y:0,draworder:'topdown',objects:[]};
  let nextId=Math.max(...raw.layers.flatMap(l=>(l.objects||[]).map(o=>o.id)),0)+1;
  if(!existing){for(const[name,u,v,fu,fv,use]of definitions)layer.objects.push({id:nextId++,name,type:'zona-visual',x:u*32,y:v*32,width:fu*32,height:fv*32,rotation:0,visible:true,properties:[prop('uso',use),prop('colisao','camadas chao e pecas; zona apenas orienta a arte')]});raw.layers.push(layer);raw.nextlayerid=nextLayer+1;raw.nextobjectid=nextId;}
  changes.push('Quintais, jardim, fundos, praça e trilha identificados em zonas visuais; portas vinculadas às fachadas com coordenadas explícitas. Navegação da rua intacta.');
 }
 const m=parseTiled(raw,sets),issues=audit(m);if(verdict(issues)!=='ok')throw Error(file+': '+JSON.stringify(issues));
 const reachableEvents=m.events.map(e=>{const candidates=[[0,0],[1,0],[-1,0],[0,1],[0,-1]].map(([du,dv])=>({u:e.u+du,v:e.v+dv}));const paths=candidates.filter(c=>walkable(m,c.u,c.v)).map(c=>findPath(m,m.spawn,c)).filter(Boolean).sort((a,b)=>a.length-b.length);if(!paths.length)throw Error(file+' inaccessible '+e.name);return {id:e.id,name:e.name,type:e.type,at:[e.u,e.v],approach:paths[0].at(-1),steps:paths[0].length-1};});
 const delta=[];for(let v=0;v<m.h;v++)for(let u=0;u<m.w;u++)if(walkable(before,u,v)!==walkable(m,u,v))delta.push([u,v,walkable(m,u,v)]);
 if(file==='rua-dos-ventos.tmj'&&delta.length)throw Error('Street navigation changed');
 if(changes.length)fs.writeFileSync(dir+file,JSON.stringify(raw,null,indent)+'\n');
 report.push({id:file.slice(0,-4),name:m.name,verdict:verdict(issues),changes,walkabilityChanges:delta,events:reachableEvents,ramps:m.cells.flatMap((c,i)=>c.ramp?[{at:[i%m.w,Math.floor(i/m.w)],direction:c.ramp,level:c.level}]:[]),zones:m.zones,sha256:crypto.createHash('sha256').update(JSON.stringify(raw)).digest('hex')});
}
fs.writeFileSync(out+'/plants.json',JSON.stringify(report,null,2)+'\n');
console.log(report.map(r=>`${r.id}: ${r.verdict}; ${r.events.length} acessos; ${r.changes.length} ajustes`).join('\n'));
