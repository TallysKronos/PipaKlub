import fs from 'node:fs';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../../',import.meta.url));
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const report={resolution:[1280,720],areas:[]};
for(const part of ['a','b','c']){
 const area='kronasta-bosque-'+part;
 const map=fs.readFileSync(root+'godot/assets/overworld/maps/'+area+'.json');
 const plan=JSON.parse(fs.readFileSync(root+'documentation/overworld/kronasta/planos/'+area+'.json'));
 const expected=plan.shots.map(s=>s.name+'.png').sort();
 if(new Set(expected).size!==expected.length)throw Error(area+': nomes de captura duplicados');
 const versions=[];
 for(const version of ['geometria','arte','arte-terreno']){
  const directory='documentation/overworld/kronasta/captures/'+area+'/'+version+'/';
  const actual=fs.readdirSync(root+directory).filter(n=>n.endsWith('.png')).sort();
  if(JSON.stringify(actual)!==JSON.stringify(expected))throw Error(directory+': capturas ausentes ou antigas');
  const files=actual.map(name=>{
   const bytes=fs.readFileSync(root+directory+name);
   if(bytes.readUInt32BE(16)!==1280||bytes.readUInt32BE(20)!==720)throw Error(directory+name+': resolução incorreta');
   return {file:directory+name,sha256:sha(bytes),bytes:bytes.length};
  });
  versions.push({version,count:files.length,files});
 }
 const entry={area,mapSha256:sha(map),shots:plan.shots.length,versions};report.areas.push(entry);
 console.log(area+': '+entry.shots+' enquadramentos × 3 versões; arquivos e resolução OK');
}
fs.writeFileSync(root+'documentation/overworld/kronasta/relatorios/capturas.json',JSON.stringify(report,null,2)+'\n');
