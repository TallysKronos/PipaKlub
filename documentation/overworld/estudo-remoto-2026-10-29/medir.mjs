import fs from 'node:fs';
import * as remote from './prova/tools/mapa-studio/model.mjs';
import * as local from '../../../tools/mapa-studio/model.mjs';
const read=p=>JSON.parse(fs.readFileSync(new URL(p,import.meta.url),'utf8'));
const sets={'rascunho.tsj':read('./prova/art/overworld/tiles/rascunho.tsj')};
const source=read('./prova/art/overworld/mapas/kronasta-bosque-a.tmj');
function metrics(raw,api){
 const m=api.parseTiled(raw,sets),solid=api.blockedByPiece(m),seen=api.reachable(m,m.spawn,solid),issues=api.audit(m);
 const count=m.cells.length,raised=m.cells.filter(c=>c.level>0).length;
 const objects=raw.layers.flatMap(l=>l.objects||[]);
 const props=Object.fromEntries(raw.properties.map(p=>[p.name,p.value]));
 const trees=m.pieces.filter(p=>p.asset==='arvore');
 const isolated=trees.filter(p=>!trees.some(q=>q!==p&&Math.max(Math.abs(q.u-p.u),Math.abs(q.v-p.v))<=1)).length;
 const items=m.events.filter(e=>e.type==='item');
 const safe={...m,cells:m.cells.map(c=>c.material==='mato'?{...c,material:'bosque'}:c)};
 const path=m.events.filter(e=>e.type==='saida').map(e=>{
  const p=api.findPath(m,m.spawn,e,solid),s=api.findPath(safe,safe.spawn,e,solid);
  return {nome:e.name,destino:e.props.destino,passos:p?p.length-1:null,segundos_teoricos_a_3_celulas_s:p?Math.round((p.length-1)/3*10)/10:null,sem_mato:!!s};
 });
 return {dimensoes:[m.w,m.h],propriedades:props,cells:count,raised,raised_percent:Math.round(raised/count*10000)/100,
  raised_walkable:m.cells.filter((c,i)=>c.level>0&&api.walkable(m,i%m.w,Math.floor(i/m.w),solid)).length,
  reachable:seen.reduce((a,b)=>a+b,0),ramps:m.cells.filter(c=>c.ramp).length,pieces:m.pieces.length,trees:trees.length,isolated_trees:isolated,
  items:items.map(e=>({id:e.id,item:e.props.item,visibilidade:e.props.visibilidade,requer:e.props.requer||null,celula:[e.u,e.v],alcancavel:!!seen[e.v*m.w+e.u]})),
  item_events:items.length,chests:m.pieces.filter(p=>p.asset==='bau').length,verdict:api.verdict(issues),issues,path};
}
const report={prova_com_seu_modelo:metrics(source,remote),prova_com_modelo_local:metrics(source,local),
 jardim_atual:metrics(read('../../../art/overworld/mapas/jardim-das-pipas.tmj'),local),
 avisos:['Tempos são mínimos teóricos de caminho em grade, sem pausas ou batalhas; não substituem playtest.',
 'Contagem de árvores isoladas é do mapa inteiro; a regra por tela precisa da câmera.',
 'Auditores existentes não implementam integralmente as novas regras regionais.']};
const index=read('./prova/godot/assets/overworld/maps/index.json');
report.destinos_fora_do_indice=report.prova_com_seu_modelo.path.filter(p=>!index.areas.some(a=>a.id===p.destino)&&!Object.hasOwn(index.scenes,p.destino));
const newModel=remote.parseTiled(source,sets),oldModel=local.parseTiled(source,sets);
report.alturas_incompativeis=[];
for(let i=0;i<newModel.cells.length;i++){
 const u=i%newModel.w,v=Math.floor(i/newModel.w),a=remote.heightAt(newModel,u+.5,v+.5),b=local.heightAt(oldModel,u+.5,v+.5);
 if(Math.abs(a-b)>.00001)report.alturas_incompativeis.push({celula:[u,v],modelo_remoto:a,modelo_local:b});
}
fs.writeFileSync(new URL('./medicoes.json',import.meta.url),JSON.stringify(report,null,2)+'\n');
for(const [key,r]of Object.entries(report))if(r?.dimensoes)console.log(JSON.stringify({map:key,dim:r.dimensoes,elevated:r.raised_percent,verdict:r.verdict,issues:r.issues,items:r.item_events,trees:r.trees,pieces:r.pieces,path:r.path}));
console.log(JSON.stringify({alturas_incompativeis:report.alturas_incompativeis.length,exemplos:report.alturas_incompativeis.slice(0,4),saidas_sem_destino:report.destinos_fora_do_indice}));
