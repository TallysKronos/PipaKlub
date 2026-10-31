import fs from 'node:fs';
import crypto from 'node:crypto';
const root=new URL('../../',import.meta.url),base='documentation/overworld/pantano/';
const read=p=>fs.readFileSync(new URL(p,root)),sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const records=[];
for(const part of ['a','b','c']){
 const id='kronasta-pantano-'+part,plan=JSON.parse(read(base+'planos/'+id+'.json'));
 const record={area:id,mapSha256:sha(read('godot/assets/overworld/maps/'+id+'.json')),planSha256:sha(read(base+'planos/'+id+'.json')),images:[]};
 for(const version of ['geometria','arte','arte-terreno']){
  const folder=base+'captures/'+part+'/'+version+'/';
  const actual=fs.readdirSync(new URL(folder,root)).filter(p=>p.endsWith('.png'));
  if(actual.length!==plan.shots.length)throw Error(folder+' image count differs');
  for(const shot of plan.shots){const path=folder+shot.name+'.png',b=read(path);if(b.subarray(0,8).toString('hex')!=='89504e470d0a1a0a'||b.readUInt32BE(16)!==1280||b.readUInt32BE(20)!==720)throw Error(path+' wrong PNG dimensions');record.images.push({path,sha256:sha(b)});}
 }
 records.push(record);
}
fs.writeFileSync(new URL(base+'relatorios/capturas.json',root),JSON.stringify(records,null,2)+'\n');
console.log(records.map(r=>r.area+': '+r.images.length+' captures').join('\n'));
