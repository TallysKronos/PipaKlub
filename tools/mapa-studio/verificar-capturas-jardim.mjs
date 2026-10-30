import fs from 'node:fs';
import crypto from 'node:crypto';
const root=new URL('../../',import.meta.url);
const read=p=>fs.readFileSync(new URL(p,root));
const base='documentation/overworld/parque/';
const plan=JSON.parse(read(base+'planos/jardim-das-pipas.json'));
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const images=[];
for(const version of ['geometria','arte','arte-terreno']){
 const folder=base+'captures/jardim-das-pipas/'+version+'/';
 const names=fs.readdirSync(new URL(folder,root)).filter(n=>n.endsWith('.png'));
 if(names.length!==plan.shots.length)throw Error(version+' has unexpected image count');
 for(const shot of plan.shots){
  const path=folder+shot.name+'.png',buffer=read(path);
  if(buffer.subarray(0,8).toString('hex')!=='89504e470d0a1a0a'||buffer.readUInt32BE(16)!==1280||buffer.readUInt32BE(20)!==720)throw Error(path+' is not a 1280x720 PNG');
  images.push({path,sha256:sha(buffer)});
 }
}
const manifest={area:'jardim-das-pipas',mapSha256:sha(read('godot/assets/overworld/maps/jardim-das-pipas.json')),planSha256:sha(read(base+'planos/jardim-das-pipas.json')),images};
fs.writeFileSync(new URL(base+'relatorios/jardim-capturas.json',root),JSON.stringify(manifest,null,2)+'\n');
console.log(images.length+' captures verified: three versions, 1280x720; map and image hashes recorded. Visual quality is reviewed separately.');
