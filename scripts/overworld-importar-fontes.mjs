// Fontes da PIP-80 já conferidas na branch citada nas tarefas. Não faz merge.
import {execFileSync} from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
const revision='469cb4e4c498faf6afcca9ee3f6782d72538f4a7';
const areas=['rua-dos-ventos','jardim-das-pipas','clareira-do-papel','veredas-do-encanamento','morro-praca-da-chegada','morro-escadaria-da-sombra','morro-laje-dos-ventos','morro-mirante-da-caixa-dagua','morro-parque-dos-ventos'];
const files=[...areas.map(a=>`art/overworld/mapas/${a}.tmj`),'art/overworld/tiles/rascunho.tsj','art/overworld/tiles/rascunho.png','tools/mapa-studio/model.mjs','tools/mapa-studio/inventario.mjs','tools/mapa-studio/importar-areas.mjs'];
for(const file of files){
 const bytes=execFileSync('git',['show',`${revision}:${file}`],{maxBuffer:16*1024*1024});
 if(fs.existsSync(file)&&fs.readFileSync(file).equals(bytes))continue;
 // Only the reviewed model/tileset receive the additive material definitions;
 // maps are new files. Existing hand-edited maps must never be overwritten.
 if(areas.some(a=>file===`art/overworld/mapas/${a}.tmj`)&&fs.existsSync(file))throw Error(`Já existe: ${file}; comparar antes de substituir.`);
 fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,bytes);
}
console.log('9 plantas e dependências copiadas da revisão fixa; nenhuma branch mesclada.');
