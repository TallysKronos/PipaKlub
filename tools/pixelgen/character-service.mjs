import fs from 'node:fs/promises';
import path from 'node:path';
import {createHash,randomUUID} from 'node:crypto';
import {validateProject,serialize,pixels} from './core.mjs';
import {encodePNG} from './png.mjs';
import {aseprite} from './aseprite.mjs';
import {characters,bindings} from './character-catalog.mjs';
const revision=bytes=>createHash('sha256').update(bytes).digest('hex');
const fail=(status,message)=>Object.assign(Error(message),{status});
export function createCharacterService(root,{catalog=characters,assets=bindings}={}){
 const locks=new Map();
 const location=rel=>{const full=path.resolve(root,rel);if(!full.startsWith(path.resolve(root)+path.sep))throw fail(400,'Caminho inválido.');return full;};
 async function read(id){const binding=assets.get(id);if(!binding)throw fail(404,'Personagem não encontrado.');const bytes=await fs.readFile(location(binding.project));return {binding,bytes,project:validateProject(JSON.parse(bytes)),revision:revision(bytes)};}
 function sheet(project){const width=project.width*project.cols,height=project.height*project.rows,data=new Uint8ClampedArray(width*height*4);for(let i=0;i<project.frames.length;i++){const frame=pixels(project,project.frames[i]),ox=i%project.cols*project.width,oy=Math.floor(i/project.cols)*project.height;for(let y=0;y<project.height;y++)data.set(frame.subarray(y*project.width*4,(y+1)*project.width*4),((oy+y)*width+ox)*4);}return encodePNG(data,width,height);}
 async function transact(id,updates){
  const history=location(`.local/pixelgen-history/${id}/${Date.now()}-${randomUUID()}`);await fs.mkdir(history,{recursive:true});
  const staged=[];const originals=[];const committed=[];
  try{
   for(const [rel,bytes] of updates){const file=location(rel);let old=null;try{old=await fs.readFile(file);}catch(e){if(e.code!=='ENOENT')throw e;}
    originals.push({file,old});if(old)await fs.writeFile(path.join(history,`${originals.length}.bak`),old);
    await fs.mkdir(path.dirname(file),{recursive:true});const temp=file+'.pixelgen-'+randomUUID()+'.tmp';await fs.writeFile(temp,bytes);staged.push({file,temp});}
   await fs.writeFile(path.join(history,'manifest.json'),JSON.stringify(originals.map((o,i)=>({file:path.relative(root,o.file),backup:o.old?`${i+1}.bak`:null})),null,2));
   for(const item of staged){await fs.rename(item.temp,item.file);committed.push(item.file);}
  }catch(error){for(const item of originals)if(committed.includes(item.file)){if(item.old)await fs.writeFile(item.file,item.old);else await fs.rm(item.file,{force:true});}throw error;}
  finally{for(const item of staged)await fs.rm(item.temp,{force:true}).catch(()=>{});}
  // Retain twenty complete local revisions per asset, bounded to this service's backup folder.
  const parent=path.dirname(history);
  await (async()=>{const entries=(await fs.readdir(parent,{withFileTypes:true})).filter(e=>e.isDirectory()&&/^\d{13}-[a-f0-9-]{36}$/.test(e.name)).map(e=>e.name).sort().reverse();for(const name of entries.slice(20)){const target=path.resolve(parent,name);if(path.dirname(target)!==parent)throw Error('Unsafe history path');await fs.rm(target,{recursive:true,force:true});}})().catch(()=>{});
 }
 return {
  async list(){return Promise.all(catalog.map(async c=>({...c,assets:await Promise.all(c.assets.map(async a=>{try{const d=await read(a.id);return {id:a.id,label:a.label,available:true,revision:d.revision,width:d.project.width,height:d.project.height,frames:d.project.frames.length};}catch{return {id:a.id,label:a.label,available:false};}}))})));},
  async open(id){const d=await read(id);return {id,project:serialize(d.project),revision:d.revision,inGame:d.binding.inGame};},
  async preview(id){const d=await read(id);const i=d.project.frames.findIndex(f=>/^(idle|walk)-SE(-1)?$/.test(f.name));return encodePNG(pixels(d.project,d.project.frames[Math.max(0,i)]),d.project.width,d.project.height);},
  async save(id,value){
   if(!value||typeof value!=='object'||typeof value.revision!=='string')throw fail(400,'Informe a revisão e o projeto.');
   const previous=locks.get(id)||Promise.resolve();const task=previous.catch(()=>{}).then(async()=>{
    const d=await read(id);if(value.revision!==d.revision)throw fail(409,'Este sprite mudou em outra aba ou ferramenta. Use Salvar projeto para exportar sua cópia e recarregue o Pixelgen para abrir a versão atual.');
    let p;try{p=validateProject(value.project);}catch(e){throw fail(422,e.message);}
    if(['width','height','cols','rows'].some(k=>p[k]!==d.project[k])||p.frames.length!==d.project.frames.length||p.frames.some((f,i)=>f.name!==d.project.frames[i].name))throw fail(422,'Mantenha a grade e a ordem dos quadros do personagem. Use uma cópia para criar novas ações.');
    const native=Buffer.from(JSON.stringify(serialize(p))),png=sheet(p),updates=new Map([[d.binding.project,native],[d.binding.png,png],[d.binding.runtime,png],[d.binding.project.replace(/\.pixelgen\.json$/,'.aseprite'),Buffer.from(aseprite(p))]]);
    await transact(id,updates);return {revision:revision(native),inGame:d.binding.inGame,savedAt:new Date().toISOString()};
   });locks.set(id,task);try{return await task;}finally{if(locks.get(id)===task)locks.delete(id);}
  }
 };
}
