import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {initialLayout} from './model.mjs';
import {exportProject} from './server.mjs';
const target=fileURLToPath(new URL('./godot-preview/',import.meta.url));
await fs.mkdir(target,{recursive:true});
const data=await exportProject(initialLayout());
let offset=0;
while(data.readUInt32LE(offset)===0x04034b50){const size=data.readUInt32LE(offset+18),n=data.readUInt16LE(offset+26),extra=data.readUInt16LE(offset+28),name=data.subarray(offset+30,offset+30+n).toString(),start=offset+30+n+extra,file=path.resolve(target,name);if(!file.startsWith(path.resolve(target)+path.sep))throw Error('Entrada fora do projeto.');await fs.mkdir(path.dirname(file),{recursive:true});await fs.writeFile(file,data.subarray(start,start+size));offset=start+size;}
await fs.writeFile(path.join(target,'.gitignore'),'.godot/\n');
console.log(path.join(target,'project.godot'));
