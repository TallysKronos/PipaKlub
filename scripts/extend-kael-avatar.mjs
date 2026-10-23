// Incremental publisher: preserve the approved 24 drawings, mounts and backpack lag.
import fs from 'node:fs/promises';
import {sharp} from './kael-raster.mjs';
import {SLOTS,blank,metrics,hexToInt,colorDistance,over,downscale,manifest,paletteJson} from '../tools/avatar-studio/model.mjs';
const art='art/avatar/kael-v1',assets='assets/avatar/kael-v1';
const p=JSON.parse(await fs.readFile(`${art}/kael.avatarstudio.json`,'utf8'));
export const read=async src=>{const {data,info}=await sharp(src).ensureAlpha().raw().toBuffer({resolveWithObject:true});return {width:info.width,height:info.height,data:new Uint8ClampedArray(data)};};
export const png=img=>sharp(Buffer.from(img.data),{raw:{width:img.width,height:img.height,channels:4}}).png().toBuffer();
export async function cell(file,cols,rows,i){const m=await sharp(file).metadata(),x=Math.round(i%cols*m.width/cols),y=Math.round(Math.floor(i/cols)*m.height/rows);return read(await sharp(file).extract({left:x,top:y,width:Math.round((i%cols+1)*m.width/cols)-x,height:Math.round((Math.floor(i/cols)+1)*m.height/rows)-y}).png().toBuffer());}
export function keyed(img,ids){const out=blank(img.width,img.height),colors=SLOTS.filter(s=>ids.includes(s.id)).flatMap(s=>s.tones.map(hexToInt));for(let i=0;i<img.data.length;i+=4){if(img.data[i+3]<160)continue;const c=img.data[i]<<16|img.data[i+1]<<8|img.data[i+2];let pick=colors[0],best=Infinity;for(const n of colors){const d=colorDistance(c,n);if(d<best){best=d;pick=n;}}out.data.set([pick>>16,pick>>8&255,pick&255,255],i);}return out;}
export async function fitted(img,w,h){const b=metrics(img).bounds;if(!b)throw Error('Empty source cell');const crop=await sharp(await png(img)).extract({left:b.x,top:b.y,width:b.w,height:b.h}).png().toBuffer();return read(await sharp(crop).resize(w,h,{kernel:'nearest'}).png().toBuffer());}
export async function publish(project){
 for(const [id,a] of Object.entries(project.actions))for(const [dir,d] of Object.entries(a.dirs))for(const [i,f] of (d.frames||[]).entries()){const img=await read(Buffer.from(f.src.split(',')[1],'base64')),file=`${id}-${dir}-${i}.png`;await fs.writeFile(`${art}/base/${file}`,await png(img));await fs.writeFile(`${assets}/base/${file}`,await png(downscale(img)));}
 for(const l of project.layers)for(const [dir,src] of Object.entries(l.images||{})){const img=await read(Buffer.from(src.split(',')[1],'base64')),even=blank(Math.ceil(img.width/2)*2,Math.ceil(img.height/2)*2);over(even,img);const file=`${l.id}-${dir}.png`;await fs.writeFile(`${art}/camadas/${file}`,await png(img));await fs.writeFile(`${assets}/camadas/${file}`,await png(downscale(even)));}
 await fs.writeFile(`${art}/kael.avatarstudio.json`,JSON.stringify(project));await fs.writeFile(`${assets}/manifest.json`,JSON.stringify(manifest(project),null,2)+'\n');await fs.writeFile(`${assets}/paleta.json`,JSON.stringify(paletteJson(project),null,2)+'\n');
}
if(process.argv[1]?.replaceAll('\\','/').endsWith('/extend-kael-avatar.mjs')){
 const source=`${art}/source/mochila-duas-pecas.png`,bag=p.layers.find(l=>l.slot==='mochila');
 const straps={id:'alcas-mochila',name:'Alças da mochila',slot:'alcas',kind:'torso',mirror:true,on:true,images:{},anchors:{},frames:{}};
 for(const [i,dir,w,h,anchor] of [[0,'se',40,44,bag.anchors.se],[1,'ne',60,64,[30,42]],[2,'se',48,36,[24,12]],[3,'ne',60,22,[30,44]]]){
  const layer=i<2?bag:straps,img=keyed(await fitted(await cell(source,4,1,i),w,h),['contorno','mochila','detalhe']);layer.images[dir]='data:image/png;base64,'+(await png(img)).toString('base64');layer.anchors[dir]=anchor;
 }
 bag.lag=1;p.layers=p.layers.filter(l=>l.slot!=='alcas');p.layers.push(straps);await publish(p);console.log('Published backpack and straps; original mounts preserved.');
}
