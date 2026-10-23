import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {sharp} from './kael-raster.mjs';
const dir='art/soulgen/keys/kael-frame-test',m=JSON.parse(await fs.readFile(dir+'/manifest.json','utf8')),checks=[];
assert.equal(m.frames.length,8);assert.equal(new Set(m.frames.map(f=>f.sha256)).size,8);assert.equal(m.frames.reduce((n,f)=>n+f.duration,0),800);
for(const [index,f]of m.frames.entries()){
 const buffer=await fs.readFile(dir+'/frames/east-'+index+'.png');assert.equal(createHash('sha256').update(buffer).digest('hex'),f.sha256);
 const {data,info}=await sharp(buffer).ensureAlpha().raw().toBuffer({resolveWithObject:true});assert.equal(info.width,256);assert.equal(info.height,256);
 let top=256,bottom=-1,border=0,transparent=0;for(let y=0;y<256;y++)for(let x=0;x<256;x++){const a=data[(y*256+x)*4+3];if(a>128){top=Math.min(top,y);bottom=Math.max(bottom,y);}if(a===0)transparent++;if((x===0||y===0||x===255||y===255)&&a)border++;}
 assert.equal(border,0,'Recorte toca a borda: '+index);assert.equal(bottom,m.anchor[1],'Apoio varia: '+index);assert.ok(transparent>30000);assert.equal(f.registration.scale,.5);checks.push({index,top,bottom,transparent,border});
}
const gif=await sharp(dir+'/walk-east.gif',{animated:true}).metadata();assert.equal(gif.pages,8);assert.deepEqual(gif.delay,Array(8).fill(100));
const atlas=await sharp(dir+'/walk-east-atlas.png').metadata();assert.equal(atlas.width,1024);assert.equal(atlas.height,512);assert.equal(atlas.hasAlpha,true);
await fs.writeFile(dir+'/audit.json',JSON.stringify({technicalPass:true,checks,gif:{pages:gif.pages,delay:gif.delay},scope:'Valida arquivos, alpha, registro e tempo. Não aprova naturalidade ou identidade artística.',visualStatus:'pilot-review'},null,2));console.log('8 quadros válidos: apoio fixo, sem corte, mesma escala e GIF de 800 ms. Revisão artística continua aberta.');
