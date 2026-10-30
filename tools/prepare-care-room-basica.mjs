// Preserve the approved Carcara assembly, including the original art bounds.
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createCarcara} from './soulgen-studio/carcara.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const out=path.join(root,'godot/assets/care-room-v1');
const rig=await createCarcara(async src=>{
 const bytes=await fs.readFile(path.join(root,src));
 return {width:bytes.readUInt32BE(16),height:bytes.readUInt32BE(20)};
});
await fs.mkdir(path.join(out,'basica'),{recursive:true});
for(const [id,asset] of Object.entries(rig.assets)){
 await fs.copyFile(path.join(root,asset.src),path.join(out,'basica',id+'.png'));
 asset.src='res://assets/care-room-v1/basica/'+id+'.png';
}
rig.careSource='tools/soulgen-studio/carcara.mjs';
await fs.writeFile(path.join(out,'basica/rig.json'),JSON.stringify(rig));
const registry=JSON.parse(await fs.readFile(path.join(out,'rigs.json'),'utf8'));
registry.basica='res://assets/care-room-v1/basica/rig.json';
await fs.writeFile(path.join(out,'rigs.json'),JSON.stringify(registry,null,2));
