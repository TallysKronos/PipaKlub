import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {caisPart} from './desenhar-kronasta-cais.mjs';
import {parseTiled} from './model.mjs';
import {compile} from '../import-overworld.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
import {writeCapturePlan} from './capturas-bosque.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
const source=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
const get=(o,n)=>o.properties.find(p=>p.name===n);
const parts=['A','B','C'].map(part=>{
 const p=caisPart(part),id='kronasta-palafitas-'+part.toLowerCase();p.id=id;
 get(p.raw,'nome').value='Palafitas · '+({A:'Chegada do resgate',B:'Travessia das docas',C:'Patamar do resgate'}[part]);
 get(p.raw,'cena_jogo').value=id;get(p.raw,'regiao').value='palafitas';
 for(const layer of p.raw.layers)if(layer.type==='objectgroup'){
  if(layer.name==='eventos')layer.objects=layer.objects.filter(o=>o.type!=='npc');
  for(const o of layer.objects){o.name=o.name.replace('Cais ','Palafitas ');const action=get(o,'acao');if(action?.value==='districtRest')action.value='retalhoTrustRest';const target=get(o,'destino');if(target?.value.startsWith('kronasta-cais-'))target.value=target.value.replace('kronasta-cais-','kronasta-palafitas-');const required=get(o,'requer');if(required?.value==='cais')required.value='retalhoPalafitasLivre';}
 }
 return p;
});
const region=parts.map(p=>({id:p.id,part:p.part,map:parseTiled(p.raw,{'rascunho.tsj':source})}));
const links=[['a','b'],['b','c']].map(([a,b])=>({from:{area:'kronasta-palafitas-'+a,u:25,v:0,direction:'v-'},to:{area:'kronasta-palafitas-'+b,u:25,v:39,direction:'v+'}}));
const outdir=root+'documentation/qa/retalho-trust-v1';fs.mkdirSync(outdir,{recursive:true});
for(const p of parts){
 const m=region.find(r=>r.id===p.id).map;
 const r=auditZeroBreak(m,{region,links,guards:p.feature.guards,requiredRoute:[m.spawn,...m.events,{u:24,v:7}]});
 console.log(p.id+'\n'+r.lines.join('\n'));if(!r.ok)throw Error(JSON.stringify(r.issues.filter(i=>i.level==='fail')));
 fs.writeFileSync(root+'art/overworld/mapas/'+p.id+'.tmj',JSON.stringify(p.raw,null,1)+'\n');
 const compiled=compile(p.raw,p.id);fs.writeFileSync(root+'godot/assets/overworld/maps/'+p.id+'.json',JSON.stringify(compiled));
 writeCapturePlan(compiled,p.feature,'documentation/qa/retalho-trust-v1');
 fs.writeFileSync(outdir+'/'+p.id+'-audit.json',JSON.stringify(r,null,2)+'\n');
}
const path=root+'godot/assets/overworld/maps/index.json',index=JSON.parse(fs.readFileSync(path));
for(const p of parts){index.areas=index.areas.filter(a=>a.id!==p.id);index.areas.push({id:p.id,name:get(p.raw,'nome').value,scene:p.id,biome:'floresta'});index.scenes[p.id]=p.id;}
fs.writeFileSync(path,JSON.stringify(index,null,2)+'\n');
