import fs from 'node:fs';
import crypto from 'node:crypto';
const root=new URL('../../',import.meta.url);
const read=p=>fs.readFileSync(new URL(p,root));
const base='documentation/overworld/parque/';
const area=process.argv[2]??'jardim-das-pipas';
if(!['jardim-das-pipas','clareira-do-papel'].includes(area))throw Error('Unsupported park capture area');
const label=area==='clareira-do-papel'?'clareira':'jardim';
const plan=JSON.parse(read(base+'planos/'+area+'.json'));
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const images=[];
for(const version of ['geometria','arte','arte-terreno']){
 const folder=base+'captures/'+area+'/'+version+'/';
 const names=fs.readdirSync(new URL(folder,root)).filter(n=>n.endsWith('.png'));
 if(names.length!==plan.shots.length)throw Error(version+' has unexpected image count');
 for(const shot of plan.shots){
  const path=folder+shot.name+'.png',buffer=read(path);
  if(buffer.subarray(0,8).toString('hex')!=='89504e470d0a1a0a'||buffer.readUInt32BE(16)!==1280||buffer.readUInt32BE(20)!==720)throw Error(path+' is not a 1280x720 PNG');
  images.push({path,sha256:sha(buffer)});
 }
}
const manifest={area,mapSha256:sha(read('godot/assets/overworld/maps/'+area+'.json')),planSha256:sha(read(base+'planos/'+area+'.json')),images};
fs.writeFileSync(new URL(base+'relatorios/'+label+'-capturas.json',root),JSON.stringify(manifest,null,2)+'\n');
console.log(images.length+' captures verified: three versions, 1280x720; map and image hashes recorded. Visual quality is reviewed separately.');
