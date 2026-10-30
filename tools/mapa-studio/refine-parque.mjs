// Authored shoreline and service-yard composition. Source and runtime stay aligned.
import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {compile} from '../import-overworld.mjs';
export const BANK_CELLS = [[25,25],[25,26],[25,33],[38,25],[38,26],[38,33],[37,33],[38,29],[37,29],[38,30]];
export function refineMap(raw,id){
 if(id==='clareira-do-papel'){
  const ground=raw.layers.find(l=>l.name==='chao').data;
  for(const [u,v] of BANK_CELLS){
   const at=v*raw.width+u;
   if(![1,4].includes(ground[at]))throw Error(`Shore would overwrite another material at ${u},${v}`);
   ground[at]=1;
  }
 }
 if(id==='veredas-do-encanamento'){
  const pieces=raw.layers.find(l=>l.name==='pecas').objects;
  for(const [id,u,v] of [[4004,44,11],[4005,47,11],[4006,50,11]]){
   const piece=pieces.find(p=>p.id===id&&p.name==='canos-patio');
   if(!piece)throw Error(`Missing service module ${id}`);
   piece.x=(u+.5)*32;piece.y=(v+.5)*32;
  }
 }
 return raw;
}
if(process.argv[1]===fileURLToPath(import.meta.url)){
 const root=fileURLToPath(new URL('../../',import.meta.url));
 for(const id of ['clareira-do-papel','veredas-do-encanamento']){
  const file=root+`art/overworld/mapas/${id}.tmj`;
  const raw=refineMap(JSON.parse(fs.readFileSync(file)),id);
  fs.writeFileSync(file,JSON.stringify(raw,null,1)+'\n');
  fs.writeFileSync(root+`godot/assets/overworld/maps/${id}.json`,JSON.stringify(compile(raw,id)));
 }
}
