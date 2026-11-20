// Compila só os mapas pedidos (sem regravar os demais) e mantém o índice em dia.
//   node tools/compilar-mapas.mjs kronasta-centro-a kronasta-lajes-b ...
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {compile} from './import-overworld.mjs';
const root=fileURLToPath(new URL('../',import.meta.url));
const out=path.join(root,'godot/assets/overworld/maps');
const indexFile=path.join(out,'index.json');
const index=JSON.parse(fs.readFileSync(indexFile,'utf8'));
for(const id of process.argv.slice(2)){
 const raw=JSON.parse(fs.readFileSync(path.join(root,'art/overworld/mapas',id+'.tmj'),'utf8'));
 const map=compile(raw,id);
 fs.writeFileSync(path.join(out,id+'.json'),JSON.stringify(map));
 index.scenes[map.scene]=id;
 const area=index.areas.find(a=>a.id===id);
 if(area)Object.assign(area,{name:map.name,scene:map.scene,biome:map.biome});else index.areas.push({id,name:map.name,scene:map.scene,biome:map.biome});
 const warns=map.audit.filter(i=>i.level!=='ok').map(i=>`${i.level}: ${i.text}`);
 console.log(`${id}: ${map.oracle.walkable.length} células andáveis, ${map.pieces.length} peças, ${map.events.length} eventos${warns.length?'\n  '+warns.join('\n  '):''}`);
}
fs.writeFileSync(indexFile,JSON.stringify(index,null,2)+'\n');
