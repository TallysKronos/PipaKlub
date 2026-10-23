import fs from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {createKael,customizeKael,setKaelDirection} from '../tools/soulgen-studio/kael.mjs';
import {raster,sharp} from './kael-raster.mjs';
const dir='art/soulgen/keys/kael-v2';await fs.mkdir(dir+'/exports',{recursive:true});
const p=await createKael(),report=[],checks=[['idle',0],['walk',.18],['walk',.54],['run',.12],['run',.36],['wave',.7],['wave',1.3],['victory',.7],['hurt',.14]];
for(const [outfit]of [['blue'],['clay']])for(const view of p.avatar.directions){
 setKaelDirection(p,view);customizeKael(p,{outfit});
 for(const [clip,t]of checks){
  const body=await sharp(await raster(p,clip,t,{size:256,parts:['body']})).ensureAlpha().raw().toBuffer();
  for(const arm of ['armLeft','armRight']){const limb=await sharp(await raster(p,clip,t,{size:256,parts:[arm]})).ensureAlpha().raw().toBuffer();let overlap=0;for(let i=3;i<body.length;i+=4)if(body[i]>128&&limb[i]>128)overlap++;report.push({outfit,view,clip,time:t,arm,overlapPixels:overlap,ok:overlap>=8});}
 }
}
const failures=report.filter(r=>!r.ok);
setKaelDirection(p,'south');const broken=structuredClone(p);broken.parts.find(p=>p.id==='armRight').rect[0]+=130;
const body=await sharp(await raster(broken,'idle',0,{size:256,parts:['body']})).ensureAlpha().raw().toBuffer(),arm=await sharp(await raster(broken,'idle',0,{size:256,parts:['armRight']})).ensureAlpha().raw().toBuffer();let negativeOverlap=0;for(let i=3;i<body.length;i+=4)if(body[i]>128&&arm[i]>128)negativeOverlap++;
if(negativeOverlap>=8)failures.push({error:'O controle negativo não detectou o braço deslocado.'});
const hashes={};for(const a of Object.values(p.assets))hashes[a.src.slice(1)]=createHash('sha256').update(await fs.readFile(a.src.slice(1))).digest('hex');
hashes[dir+'/rig-data.mjs']=createHash('sha256').update(await fs.readFile(dir+'/rig-data.mjs')).digest('hex');
await fs.writeFile(dir+'/pixel-audit.json',JSON.stringify({resolution:256,criterion:'Pelo menos 8 pixels opacos compartilhados entre manga e tronco, incluindo extremos; não substitui revisão visual.',negativeControl:{armOffset:130,overlapPixels:negativeOverlap,detected:negativeOverlap<8},hashes,checks:report,failures},null,2));
const shots=[];for(const [outfit,row]of [['blue',0],['clay',1]])for(const [i,view]of p.avatar.directions.entries()){setKaelDirection(p,view);customizeKael(p,{outfit,skin:row?'escuro':'mel',hair:row?'curly':'spiky',hairColor:row?'copper':'navy'});shots.push({input:await raster(p,'walk',.18,{size:256}),left:i*256,top:row*256});}
await sharp({create:{width:1024,height:512,channels:4,background:'#e8efdc'}}).composite(shots).png().toFile(dir+'/exports/four-directions.png');
console.log(report.length,'checks of opaque shoulder overlap;',failures.length,'failures.',failures.slice(0,8));
if(failures.length)process.exitCode=1;
