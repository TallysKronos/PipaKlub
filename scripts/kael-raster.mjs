import fs from 'node:fs/promises';
import {createRequire} from 'node:module';
import {sample,matrices} from '../tools/soulgen-studio/model.mjs';
const require=createRequire(import.meta.url);let sharp;try{sharp=require('sharp');}catch{sharp=require('C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');}
export {sharp};
const cached=new Map();
export async function raster(project,clip,time,{size=128,parts=null}={}){
 const m=matrices(project,sample(project,clip,time)),groups=[];
 for(const p of [...project.parts].sort((a,b)=>a.z-b.z)){
  if(p.visible===false||parts&&!parts.includes(p.id))continue;
  const a=project.assets[p.asset],key=a.src+'|'+p.source;
  if(!cached.has(key)){const data=a.src.startsWith('data:')?Buffer.from(a.src.split(',')[1],'base64'):await fs.readFile(a.src.slice(1)),[left,top,width,height]=p.source;cached.set(key,(await sharp(data).extract({left,top,width,height}).png().toBuffer()).toString('base64'));}
  const [x,y,w,h]=p.rect;
  groups.push(`<g transform="matrix(${m[p.id].join(' ')})"><image x="${x}" y="${y}" width="${w}" height="${h}" href="data:image/png;base64,${cached.get(key)}"/></g>`);
 }
 return sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${project.width} ${project.height}">${groups.join('')}</svg>`)).png().toBuffer();
}
