import fs from 'node:fs/promises';
import path from 'node:path';
import {createHash,randomUUID} from 'node:crypto';
import {validate} from './model.mjs';
import {decodePNG} from '../pixelgen/png.mjs';
const target='godot/assets/mounts/kael-mounted-rig-v1/project.json';
const hash=b=>createHash('sha256').update(b).digest('hex');
const fail=(status,message)=>Object.assign(Error(message),{status});
export function createMountedRigService(root){
 let lock=Promise.resolve();
 const read=async()=>{const bytes=await fs.readFile(path.join(root,target));return {project:JSON.parse(bytes),revision:hash(bytes)};};
 return {read,async save(value){
  const task=lock.catch(()=>{}).then(async()=>{
   const old=await read();if(value?.revision!==old.revision)throw fail(409,'O rig mudou. Salve uma cópia e recarregue antes de aplicar.');
   const p=value.project,audit=validate(p);
   if(!audit.ok)throw fail(422,audit.errors.join(' '));
   if(p.creatureId!=='kael-mounted'||p.direction!=='se'||p.width!==384||p.height!==512||p.parts.length<1)throw fail(422,'Este destino aceita somente o Kael montado SE, 384 × 512.');
   // Runtime intentionally supports this bounded subset of the portable format.
   if(p.parts.some(x=>x.faces||x.lag)||Object.values(p.clips).some(c=>c.expressions?.length||c.frames.some(f=>f.ease==='spline')))throw fail(422,'Use canais básicos e interpolação linear/suave neste piloto.');
   for(const a of Object.values(p.assets)){
    if(!a.src.startsWith('data:image/png;base64,'))throw fail(422,'Salve as imagens incorporadas ao projeto.');
    let image;try{image=decodePNG(Buffer.from(a.src.split(',')[1],'base64'));}catch{throw fail(422,'PNG incorporado inválido.');}
    if(image.width!==a.width||image.height!==a.height)throw fail(422,'As dimensões da imagem não correspondem ao projeto.');
   }
   const backup=path.join(root,'.local/soulgen-history/kael-mounted-rig',Date.now()+'-'+randomUUID()+'.json');
   await fs.mkdir(path.dirname(backup),{recursive:true});await fs.copyFile(path.join(root,target),backup);
   const bytes=Buffer.from(JSON.stringify(p)),file=path.join(root,target),temp=file+'.'+randomUUID()+'.tmp';
   try{await fs.writeFile(temp,bytes);await fs.rename(temp,file);}finally{await fs.rm(temp,{force:true});}
   return {revision:hash(bytes),file:target,backup:path.relative(root,backup)};
  });lock=task;return await task;
 }};
}
