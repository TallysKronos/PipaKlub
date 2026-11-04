// Explicit source-map setting. No event, piece, horizontal path or reward moves.
import fs from 'node:fs';
import {compile} from '../import-overworld.mjs';
for(const id of ['veredas-piloto','veredas-do-encanamento']){
  const file=`art/overworld/mapas/${id}.tmj`,raw=JSON.parse(fs.readFileSync(file));
  raw.properties=raw.properties.filter(p=>p.name!=='rampa_comprimento');
  raw.properties.push({name:'rampa_comprimento',type:'int',value:4});
  if(id==='veredas-do-encanamento'){
    // Remove isolated blocked bank noses beside the three mouths. Keeping
    // bosque preserves blockers while the upper bank gets one straight edge.
    const height=raw.layers.find(l=>l.name==='altura');
    for(const u of [10,25,29,36])height.data[8*raw.width+u]=0;
    // The courtyard shoulder is one supported bank, not a staircase of
    // isolated columns. Only already-blocked bosque cells are raised.
    const ground=raw.layers.find(l=>l.name==='chao');
    const set=JSON.parse(fs.readFileSync('art/overworld/tiles/rascunho.tsj'));
    const forest=set.tiles.find(t=>t.properties?.some(p=>p.name==='material'&&p.value==='bosque')).id+1;
    for(let v=8;v<=10;v++)for(let u=40;u<=42;u++)if(ground.data[v*raw.width+u]===forest)height.data[v*raw.width+u]=17;
  }
  const compiled=compile(raw,id);
  fs.writeFileSync(file,JSON.stringify(raw,null,1)+'\n');
  fs.writeFileSync(`godot/assets/overworld/maps/${id}.json`,JSON.stringify(compiled));
  console.log(`${id}: rampas de quatro células, ${compiled.cells.filter(c=>c.ramp).length} trechos inclinados.`);
}
