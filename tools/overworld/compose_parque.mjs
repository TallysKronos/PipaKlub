// Authored composition pass: simplify silhouettes without moving destinations.
import fs from 'node:fs';
const decisions={
 'jardim-das-pipas':{keep:[2,4,6,8,9,11,13,14,15,17,18,20,21],relocate:{21:[20,11]},landmarks:['coreto','entry-map','east-bench'],rest:'Open lawn and sightline between entry plaza, coreto and first encounter patch'},
 'clareira-do-papel':{keep:[1,2,4,5,7,8,10,12,13,14,16,17,19,20],relocate:{20:[21,12]},landmarks:['flowering-tree','encounter-grass','Veredas exit'],rest:'Open central lawn; foreground tree screen interrupted near the trail'}
};
const report={issue:'PIP-85',revision:'volume-correction',automaticTreeFill:false,contextTrees:{automatic:false,authoredPerArea:2},areas:{}};
const previous=fs.existsSync('art/overworld/kits/parque/composicao.json')?JSON.parse(fs.readFileSync('art/overworld/kits/parque/composicao.json','utf8')):{};
for(const [id,decision] of Object.entries(decisions)){
 const file=`art/overworld/mapas/${id}.tmj`;
 const raw=JSON.parse(fs.readFileSync(file,'utf8'));
 const layer=raw.layers.find(l=>l.name==='pecas');
 const before=layer.objects.filter(o=>o.properties?.some(p=>p.name==='asset'&&p.value==='arvore'));
 const removed=before.filter(o=>!decision.keep.includes(o.id));
 layer.objects=layer.objects.filter(o=>!removed.includes(o));
 for(const [objectId,cell] of Object.entries(decision.relocate)){
   const object=layer.objects.find(o=>o.id===Number(objectId));
   if(object){object.x=cell[0]*32;object.y=cell[1]*32;}
 }
 fs.writeFileSync(file,JSON.stringify(raw,null,1)+'\n');
 const history=[...(previous.areas?.[id]?.removedTrees||[]),...removed.map(o=>({id:o.id,cell:[o.x/32,o.y/32]}))];
 report.areas[id]={...decision,retainedTreeCount:decision.keep.length,removedTrees:[...new Map(history.map(o=>[o.id,o])).values()],source:file};
}
fs.writeFileSync('art/overworld/kits/parque/composicao.json',JSON.stringify(report,null,2)+'\n');
console.log('Parque: authored tree selection, 13 in Jardim and 14 in Clareira; source destinations unchanged.');
