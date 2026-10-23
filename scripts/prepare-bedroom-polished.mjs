import fs from 'node:fs/promises';
import {createRequire} from 'node:module';
import {presetKaelRoom,pieceBox,manifest,auditSource,auditPiece,auditScene,verdict,alphaBounds,roomSize} from '../tools/iso-studio/model.mjs';
const require=createRequire(import.meta.url);let sharp;try{sharp=require('sharp');}catch{sharp=require('C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');}
const root='art/kael-bedroom-iso-v4',out='assets/world/kael-bedroom-iso-v4',project=presetKaelRoom();project.name='Quarto de Kael · arte final ilustrada';
await fs.mkdir(out,{recursive:true});const images={},reports=[];
const polished=['cama','guarda-roupa','mesa','estante','tv','janela','tapete','abertura-escada','quadros'];
async function normalize(source,w,h,destination,guide=null){
 const src=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true}),bounds=alphaBounds({width:src.info.width,height:src.info.height,data:src.data});
 if(!bounds)throw Error('Fonte vazia: '+source);
 let {data}=await sharp(source).extract({left:bounds.x,top:bounds.y,width:bounds.w,height:bounds.h}).resize(w,h,{fit:'fill',kernel:'lanczos3'}).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 // Geometric registration only: vertical edges remain vertical. Match the
 // approved guide's top/bottom envelope per column, preserving the painted
 // materials and transparent interiors, rather than stretching at runtime.
 if(guide){
  const target=await sharp(guide).resize(w,h,{kernel:'nearest'}).ensureAlpha().raw().toBuffer(),fitted=Buffer.alloc(data.length);
  const column=(pixels,x)=>{let lo=h,hi=-1;for(let y=0;y<h;y++)if(pixels[(y*w+x)*4+3]>=128){lo=Math.min(lo,y);hi=y;}return {lo,hi};};
  for(let x=0;x<w;x++){const a=column(data,x),b=column(target,x);if(a.hi<0||b.hi<0)continue;for(let y=b.lo;y<=b.hi;y++){
   const sy=a.lo+(y-b.lo)*(a.hi-a.lo)/Math.max(1,b.hi-b.lo),s0=Math.floor(sy),s1=Math.min(h-1,s0+1),t=sy-s0,di=(y*w+x)*4;
   for(let c=0;c<4;c++)fitted[di+c]=Math.round(data[(s0*w+x)*4+c]*(1-t)+data[(s1*w+x)*4+c]*t);
  }}data=fitted;
 }
 for(let i=3;i<data.length;i+=4)data[i]=data[i]>=128?255:0;
 await sharp(data,{raw:{width:w,height:h,channels:4}}).png().toFile(destination);
 return {width:w,height:h,data};
}
for(const p of project.pieces){const b=pieceBox(p),dest=`${out}/${p.id}.png`;let img;
 if(polished.includes(p.id))img=await normalize(`${root}/sources/${p.id}.png`,b.w,b.h,dest,`assets/world/kael-bedroom-iso-v3/${p.id}.png`);
 else{await fs.copyFile(`assets/world/kael-bedroom-iso-v3/${p.id}.png`,dest);const r=await sharp(dest).ensureAlpha().raw().toBuffer({resolveWithObject:true});img={width:r.info.width,height:r.info.height,data:r.data};}
 const items=[...auditSource(img),...auditPiece(p,img).items],r={id:p.id,verdict:verdict(items),items};reports.push(r);console.log(p.id,r.verdict,items.filter(i=>i.level==='fail').map(i=>i.text).join('; '));
 p.image='data:image/png;base64,'+(await fs.readFile(dest)).toString('base64');images['bedroom-'+p.id]={image:`world/kael-bedroom-iso-v4/${p.id}.png`,width:b.w,height:b.h,pivot:[b.anchor[0]/b.w,1]};
}
const size=roomSize(project.room);await normalize(`${root}/sources/casca.png`,size.w,size.h,`${out}/casca.png`);project.room.image='data:image/png;base64,'+(await fs.readFile(`${out}/casca.png`)).toString('base64');images['bedroom-casca']={image:'world/kael-bedroom-iso-v4/casca.png',width:size.w,height:size.h};
await fs.writeFile(`${out}/manifest.json`,JSON.stringify({...manifest(project),images,provenance:'Built-in image_gen art polish using Iso Studio per-piece geometry guides and approved park bench style. Alpha crop, native-size normalization, vertical envelope registration to guide, binary-alpha export; sources retained.'},null,2)+'\n');
await fs.writeFile(`${root}/quarto-kael.isostudio.json`,JSON.stringify(project));await fs.writeFile(`${root}/conferencia.json`,JSON.stringify({scene:auditScene(project.room,project.pieces),pieces:reports},null,2)+'\n');
if(reports.some(r=>r.verdict==='fail'))process.exitCode=1;
