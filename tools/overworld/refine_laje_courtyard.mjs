// A paved courtyard in the source plant, with existing levels and stair mouths.
import fs from 'node:fs';
import {compile} from '../import-overworld.mjs';
const id='morro-laje-dos-ventos',file=`art/overworld/mapas/${id}.tmj`;
const raw=JSON.parse(fs.readFileSync(file)),model=compile(raw,id);
const tiles=JSON.parse(fs.readFileSync('art/overworld/tiles/rascunho.tsj'));
const floor=tiles.tiles.find(t=>t.properties?.some(p=>p.name==='material'&&p.value==='piso')).id+1;
const ground=raw.layers.find(l=>l.name==='chao');let changed=0;
for(let v=5;v<=12;v++)for(let u=5;u<=19;u++){
 const i=v*model.w+u,c=model.cells[i];
 if(c.level!==0||c.ramp||!['construcao','piso'].includes(c.material))continue;
 if(ground.data[i]!==floor){ground.data[i]=floor;changed++;}
}
const line=raw.layers.flatMap(l=>l.objects||[]).find(o=>o.id===1);
let variant=line.properties.find(p=>p.name==='variante');
if(variant)variant.value='pipas';else line.properties.push({name:'variante',type:'string',value:'pipas'});
const result=compile(raw,id);
fs.writeFileSync(file,JSON.stringify(raw,null,2)+'\n');
fs.writeFileSync(`godot/assets/overworld/maps/${id}.json`,JSON.stringify(result));
console.log(`Laje: ${changed} cells paved, existing levels/stairs/events retained.`);
