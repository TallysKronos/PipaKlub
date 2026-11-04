import fs from 'node:fs/promises';
import path from 'node:path';
import {createHash,randomUUID} from 'node:crypto';
import {decodePNG,encodePNG} from '../pixelgen/png.mjs';
const hash=b=>createHash('sha256').update(b).digest('hex');
const fail=(status,message)=>Object.assign(Error(message),{status});
const ROOT='godot/assets/mounts/doberman-c-v1/';
export const gameSprites=[{id:'doberman-c',name:'Montaria C',file:ROOT+'idle-eight.png',role:'mount'},{id:'kael-mounted',name:'Kael montado',file:ROOT+'kael-rider-refined.png',role:'rider'}];
export function createGameSpritesService(root){
 const locks=new Map();
 async function read(id){const asset=gameSprites.find(a=>a.id===id);if(!asset)throw fail(404,'Sprite não encontrado.');const bytes=await fs.readFile(path.join(root,asset.file));return {asset,bytes,revision:hash(bytes)};}
 async function definition(){return JSON.parse(await fs.readFile(path.join(root,ROOT+'mount.json'),'utf8'));}
 return {
  async list(){const bytes=await fs.readFile(path.join(root,ROOT+'mount.json')),rig=JSON.parse(bytes);return {assets:await Promise.all(gameSprites.map(async a=>{const d=await read(a.id);return {...a,revision:d.revision};})),rig,rigRevision:hash(bytes)};},
  async saveRig(value){
   const previous=locks.get('rig')||Promise.resolve(),task=previous.catch(()=>{}).then(async()=>{
    const file=path.join(root,ROOT+'mount.json'),bytes=await fs.readFile(file);
    if(value?.revision!==hash(bytes))throw fail(409,'O encaixe mudou em outra janela. Baixe suas alterações antes de recarregar.');
    const rig=JSON.parse(bytes),frame=rig.directions[value.direction],patch=value.patch;
    if(!Object.hasOwn(rig.directions,value.direction)||!frame||!patch||Array.isArray(patch)||Object.keys(patch).length!==4||Object.keys(patch).some(k=>!['seat','hip','ground','farLegAngle'].includes(k)))throw fail(422,'Envie apenas os pivôs e o ângulo da perna da direção selecionada.');
    for(const k of ['seat','hip','ground'])if(!Array.isArray(patch[k])||patch[k].length!==2||patch[k].some(n=>typeof n!=='number'||!Number.isFinite(n)||Math.abs(n)>4096))throw fail(422,'Pivô inválido: '+k);
    if(typeof patch.farLegAngle!=='number'||!Number.isFinite(patch.farLegAngle)||Math.abs(patch.farLegAngle)>180)throw fail(422,'Ângulo inválido.');
    Object.assign(frame,structuredClone(patch));for(const f of frame.frames||[])f.seat=[...patch.seat];
    const output=Buffer.from(JSON.stringify(rig,null,2)+'\n'),backup=path.join(root,'.local/soulgen-history/mount-layout',Date.now()+'-'+randomUUID()+'.json');
    await fs.mkdir(path.dirname(backup),{recursive:true});await fs.writeFile(backup,bytes);
    const temp=file+'.'+randomUUID()+'.tmp';try{await fs.writeFile(temp,output);await fs.rename(temp,file);}finally{await fs.rm(temp,{force:true});}
    return {revision:hash(output),backup:path.relative(root,backup)};
   });locks.set('rig',task);try{return await task;}finally{if(locks.get('rig')===task)locks.delete('rig');}
  },
  async image(id){return (await read(id)).bytes;},
  async save(id,value){
   const previous=locks.get(id)||Promise.resolve();const task=previous.catch(()=>{}).then(async()=>{
    const d=await read(id);if(value?.revision!==d.revision)throw fail(409,'O arquivo mudou. Exporte sua edição e recarregue antes de salvar.');
    const rig=await definition(),frame=rig.directions[value.direction];if(!frame)throw fail(422,'Direção inválida.');
    const rect=d.asset.role==='mount'?frame.rect:frame.riderRect;
    if(typeof value.png!=='string'||!/^data:image\/png;base64,[A-Za-z0-9+/=]+$/.test(value.png)||value.png.length>4e6)throw fail(422,'Envie um recorte PNG válido.');
    const bytes=Buffer.from(value.png.split(',')[1],'base64');
    if(bytes.length<33||!bytes.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10]))||bytes.readUInt32BE(16)!==rect[2]||bytes.readUInt32BE(20)!==rect[3])throw fail(422,'Mantenha as dimensões do recorte.');
    let patch;try{patch=decodePNG(bytes);}catch{throw fail(422,'PNG inválido.');}
    const sheet=decodePNG(d.bytes);
    const otherRects=Object.entries(rig.directions).filter(([key])=>key!==value.direction).map(([,frame])=>d.asset.role==='mount'?frame.rect:frame.riderRect);
    for(let y=0;y<rect[3];y++)for(let x=0;x<rect[2];x++){
     const ax=rect[0]+x,ay=rect[1]+y;
     if(!otherRects.some(([ox,oy,w,h])=>ax>=ox&&ax<ox+w&&ay>=oy&&ay<oy+h))continue;
     const pi=(y*rect[2]+x)*4,si=(ay*sheet.width+ax)*4;
     if(patch.data.subarray(pi,pi+4).some((v,i)=>v!==sheet.data[si+i]))throw fail(422,'Esse traço alcança a margem compartilhada com outra direção. Desfaça o traço na borda antes de salvar.');
    }
    for(let y=0;y<rect[3];y++)sheet.data.set(patch.data.subarray(y*rect[2]*4,(y+1)*rect[2]*4),((rect[1]+y)*sheet.width+rect[0])*4);
    const output=encodePNG(sheet.data,sheet.width,sheet.height);
    const backup=path.join(root,'.local','soulgen-history',id,Date.now()+'-'+randomUUID()+'.png');
    await fs.mkdir(path.dirname(backup),{recursive:true});await fs.writeFile(backup,d.bytes);
    const file=path.join(root,d.asset.file),temp=file+'.'+randomUUID()+'.tmp';
    try{await fs.writeFile(temp,output);await fs.rename(temp,file);}finally{await fs.rm(temp,{force:true}).catch(()=>{});}
    return {revision:hash(output),savedAt:new Date().toISOString(),backup:path.relative(root,backup),file:d.asset.file};
   });locks.set(id,task);try{return await task;}finally{if(locks.get(id)===task)locks.delete(id);}
  }
 };
}
