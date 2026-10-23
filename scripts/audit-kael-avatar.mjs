import fs from 'node:fs/promises';
import {sharp} from './kael-raster.mjs';
import {zip} from '../tools/iso-studio/model.mjs';
import {read,png} from './extend-kael-avatar.mjs';
import {composeFrame,appearanceRamps,auditFrames,auditHeadLayer,auditTorsoLayer,auditBackpack,laggedMount,metrics} from '../tools/avatar-studio/model.mjs';
const root='art/avatar/kael-v1',p=JSON.parse(await fs.readFile(root+'/kael.avatarstudio.json','utf8')),decode=src=>read(Buffer.from(src.split(',')[1],'base64')),out={actions:{},backpack:[],hair:[]},rows=[];
for(const [action,a]of Object.entries(p.actions))for(const [dir,d]of Object.entries(a.dirs)){if(!d.frames?.length)continue;const frames=await Promise.all(d.frames.map(async f=>({...f,image:await decode(f.src)}))),rendered=[];
 const layers=await Promise.all(p.layers.filter(l=>l.on!==false&&l.images[dir]).map(async l=>({...l,image:await decode(l.images[dir]),anchor:l.anchors[dir]})));
 out.actions[action+'-'+dir]=auditFrames(frames,{slots:p.slots,action}).items;
 for(const [i,f]of frames.entries()){const ls=layers.map(l=>({...l,mount:laggedMount(frames.map(v=>v[l.kind]),i,l.lag||0,a.loop!==false)})),bag=ls.find(l=>l.slot==='mochila'),hair=ls.find(l=>l.slot==='cabelo');out.backpack.push({action,dir,i,...auditBackpack({base:f.image,torso:bag.mount,bag,straps:ls.some(l=>l.slot==='alcas'),dir}),torso:auditTorsoLayer(f.image,bag.mount,bag)});out.hair.push({action,dir,i,...auditHeadLayer(f.image,f.head,hair)});rendered.push(composeFrame({base:f.image,...f,dir,layers:ls,ramps:appearanceRamps(p.slots,p.appearance),slots:p.slots}));}
 const framesRaw=rendered.map(im=>Buffer.from(im.data));await sharp(Buffer.concat(framesRaw),{raw:{width:256,height:256*framesRaw.length,channels:4,pageHeight:256}}).gif({delay:rendered.map(()=>a.ms),loop:a.loop===false?1:0}).toFile(root+'/'+action+'-'+dir+'.gif');
 rows.push({action,dir,rendered});
}
const layers=[];for(const [y,row]of rows.entries())for(const [x,img]of row.rendered.entries())layers.push({input:await png(img),left:x*256,top:y*280});
await sharp({create:{width:2048,height:rows.length*280,channels:4,background:'#e8eddb'}}).composite(layers).png().toFile(root+'/conferencia-integracao.png');
out.rows=rows.map(r=>r.action+'-'+r.dir);await fs.writeFile(root+'/conferencia-integracao.json',JSON.stringify(out,null,2));console.log(JSON.stringify({actions:out.actions,bag:out.backpack.filter(v=>v.level!=='ok'||v.torso.level!=='ok'),hair:out.hair.filter(v=>v.level!=='ok')},null,2));
const files=[];for(const folder of ['assets/avatar/kael-v1/base','assets/avatar/kael-v1/camadas'])for(const name of await fs.readdir(folder))files.push({name:folder+'/'+name,data:new Uint8Array(await fs.readFile(folder+'/'+name))});
for(const name of ['assets/avatar/kael-v1/manifest.json','assets/avatar/kael-v1/paleta.json',root+'/kael.avatarstudio.json',root+'/conferencia-integracao.json',root+'/conferencia-integracao.png',root+'/README.md',root+'/CORRECOES-V3.md',root+'/source/REVISAO-V3-PROMPTS.md'])files.push({name,data:new Uint8Array(await fs.readFile(name))});await fs.writeFile(root+'/kael-v1-avatar.zip',zip(files));
