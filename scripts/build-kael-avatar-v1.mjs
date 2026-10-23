// Technical preparation of the generated drawings: slicing, fixed scale, alpha,
// semantic palette, head registration and the Avatar Studio portable project.
// This does not synthesize poses or rotate body parts.
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {sharp} from './kael-raster.mjs';
import {SLOTS,ACTIONS,RULES,blank,metrics,autoTorso,hexToInt,colorDistance,over,translate,registerToPivot,composeFrame,appearanceRamps,mirror,auditFrames,auditHeadLayer,auditTorsoLayer,manifest,paletteJson,downscale} from '../tools/avatar-studio/model.mjs';
import {zip} from '../tools/iso-studio/model.mjs';
const root=fileURLToPath(new URL('../',import.meta.url));
const art=path.join(root,'art/avatar/kael-v1'),assets=path.join(root,'assets/avatar/kael-v1');
for(const p of [art+'/base',art+'/camadas',assets+'/base',assets+'/camadas'])await fs.mkdir(p,{recursive:true});
const read=async src=>{const {data,info}=await sharp(src).ensureAlpha().raw().toBuffer({resolveWithObject:true});return {width:info.width,height:info.height,data:new Uint8ClampedArray(data)};};
const png=img=>sharp(Buffer.from(img.data),{raw:{width:img.width,height:img.height,channels:4}}).png().toBuffer();
const save=async(img,file)=>fs.writeFile(file,await png(img));
const url=async img=>'data:image/png;base64,'+(await png(img)).toString('base64');
const crop=async(src,cols,rows,i)=>{const {width,height}=await sharp(src).metadata(),x=Math.round((i%cols)*width/cols),y=Math.round(Math.floor(i/cols)*height/rows),w=Math.round((i%cols+1)*width/cols)-x,h=Math.round((Math.floor(i/cols)+1)*height/rows)-y;const b=await sharp(src).extract({left:x,top:y,width:w,height:h}).png().toBuffer();return read(b);};
function binary(img){const out=blank(img.width,img.height);for(let p=0;p<img.data.length;p+=4)if(img.data[p+3]>=160){out.data.set(img.data.subarray(p,p+3),p);out.data[p+3]=255;}return out;}
async function trim(img){const m=metrics(binary(img));if(!m.bounds)throw Error('Empty generated cell');const b=m.bounds;return read(await sharp(await png(img)).extract({left:b.x,top:b.y,width:b.w,height:b.h}).png().toBuffer());}
const resize=async(img,w,h)=>read(await sharp(await png(img)).resize(w,h,{kernel:'nearest'}).png().toBuffer());
const tones=id=>SLOTS.find(s=>s.id===id).tones.map(hexToInt);
function nearest(rgb,ids){let pick=0,dist=Infinity;for(const id of ids)for(const c of tones(id)){const d=colorDistance(rgb,c);if(d<dist){dist=d;pick=c;}}return pick;}
// RGB collisions (navy hair/shoes, golden skin/soles) are resolved by region.
function palette(img,mode='body'){
 const out=binary(img),b=metrics(out).bounds;
 for(let y=0;y<img.height;y++)for(let x=0;x<img.width;x++){const p=(y*img.width+x)*4;if(!out.data[p+3])continue;const [r,g,blue]=out.data.subarray(p,p+3),c=r<<16|g<<8|blue,t=(y-b.y)/b.h;let ids;
  if(mode==='hair')ids=['cabelo','contorno'];
  else if(mode==='bag')ids=['mochila','detalhe','contorno'];
  else if(Math.max(r,g,blue)<30)ids=['contorno'];
  // Pale warm highlights are still skin. The old ratio test sent them to eye
  // white, producing white speckles all over the forehead and cheeks.
  else if(t<.47){ids=Math.max(r,g,blue)<85?['olhos','contorno']:r>g&&g>blue&&r-blue>12?['pele']:['olhos','contorno'];}
  else if(t>.84){ids=r>g*1.12&&g>blue*1.15?['detalhe']:['tenis','contorno'];}
  else if(r>g*1.13&&g>blue*1.12){ids=t>.73?['pele','detalhe']:['pele'];}
  else if(t>.71){ids=['calca','contorno'];}
  else if(t>.51&&t<.71&&(x-b.x)/b.w>.48&&(x-b.x)/b.w<.78&&blue<g*1.6){ids=['camiseta'];}
  else if(blue>r*1.6&&blue>g*1.35){ids=t>.70?['calca','contorno']:['jaqueta','contorno'];}
  else if(g>r*1.25&&g>blue*.78){ids=['jaqueta'];}
  else{ids=['camiseta','jaqueta','contorno'];}
  const n=nearest(c,ids);out.data[p]=n>>16;out.data[p+1]=n>>8&255;out.data[p+2]=n&255;
 }return out;
}
const project={format:'avatar-studio',version:1,rulesVersion:RULES,name:'Kael v1',actions:Object.fromEntries(Object.entries(ACTIONS).map(([a,v])=>[a,{ms:v.ms,dirs:{se:{frames:[]},ne:{frames:[]},sw:{mirror:'se'},nw:{mirror:'ne'}}}])),mapping:{clusters:[],assign:[]},slots:structuredClone(SLOTS),appearance:{},layers:[]};
const base={},heads={},torsos={},registration={};
for(const dir of ['se','ne']){
 const source=art+`/source/${dir}-limpo.png`,idle=await Promise.all(Array.from({length:4},(_,i)=>crop(source,4,3,i))),walk=await Promise.all(Array.from({length:8},(_,i)=>crop(source,4,3,i+4)));
 const clean=await Promise.all([...idle,...walk].map(trim));
 // One uniform scale for each generated sheet, never independent frame fitting.
 const idleScale=174/clean[0].height,walkScale=174/clean[4].height;
 registration[dir]={idleScale,walkScale,bodyHeight:174,composedTargetHeight:192,headRegistration:'skull silhouette, integer runtime pixel grid'};
 for(const [action,frames,offset] of [['parado',idle,0],['andar',walk,4]]){
  base[`${action}-${dir}`]=[];heads[`${action}-${dir}`]=[];torsos[`${action}-${dir}`]=[];
  for(let i=0;i<frames.length;i++){
   const input=clean[offset+i],scale=action==='parado'?idleScale:walkScale,small=palette(await resize(input,Math.round(input.width*scale),Math.round(input.height*scale))),cell=blank(256,256);
   over(cell,small,Math.round(128-small.width/2),224-small.height);
   // The skin centroid shifts when the cheek/ear becomes visible. Register the
   // skull silhouette instead, without changing any pose or stretching a frame.
   const b=metrics(cell).bounds;let left=256,right=0;for(let y=b.y;y<b.y+Math.round(b.h*.3);y++)for(let x=0;x<256;x++)if(cell.data[(y*256+x)*4+3]){left=Math.min(left,x);right=Math.max(right,x);}
   const center=Math.round((left+right)/2),registered=registerToPivot(translate(cell,128-center,0)).img,head=[128,Math.floor((metrics(registered).bounds.y+42)/2)*2],file=`${action}-${dir}-${i}.png`;
   const torso=autoTorso(registered);base[`${action}-${dir}`].push(registered);heads[`${action}-${dir}`].push(head);torsos[`${action}-${dir}`].push(torso);
   project.actions[action].dirs[dir].frames.push({src:await url(registered),head,torso});
   await save(registered,art+'/base/'+file);await save(downscale(registered),assets+'/base/'+file);
  }
 }
}
const layers={};
for(const [id,slot,mode,items] of [
 ['cabelo-kael','cabelo','hair',{se:{i:0,w:104,h:80,x:-52,y:-60},ne:{i:1,w:100,h:92,x:-50,y:-56}}],
 ['mochila-pipa','mochila','bag',{se:{i:2,w:32,h:38,x:-34,y:-20},ne:{i:3,w:38,h:42,x:-20,y:-22}}]
]){
 const layer={id,name:id==='cabelo-kael'?'Cabelo Kael · pontas':'Mochila · elo de pipa',slot,kind:slot==='mochila'?'torso':'head',images:{},anchors:{},frames:{},mirror:true,on:true};layers[id]={};
 for(const [dir,c] of Object.entries(items)){
  const img=palette(await resize(await trim(await crop(art+'/source/camadas.png',2,2,c.i)),c.w,c.h),mode);
  const anchor=[-c.x,-c.y];layers[id][dir]={image:img,anchor};layer.images[dir]=await url(img);layer.anchors[dir]=anchor;
  await save(img,art+`/camadas/${id}-${dir}.png`);await save(downscaleEven(img),assets+`/camadas/${id}-${dir}.png`);
 }project.layers.push(layer);
}
// Layer canvases can have odd size; pad the bottom/right before integer reduction.
function downscaleEven(img){const padded=blank(Math.ceil(img.width/2)*2,Math.ceil(img.height/2)*2);over(padded,img);return downscale(padded);}
const composed=(action,dir,i,appearance={})=>{const from=dir==='sw'?'se':dir==='nw'?'ne':dir,isMirror=from!==dir,b=base[`${action}-${from}`][i],h=heads[`${action}-${from}`][i],t=torsos[`${action}-${from}`][i],ls=project.layers.map(l=>{const v=layers[l.id][from];return {kind:l.kind,slot:l.slot,image:isMirror?mirror(v.image):v.image,anchor:isMirror?[v.image.width-1-v.anchor[0],v.anchor[1]]:v.anchor};});return composeFrame({base:isMirror?mirror(b):b,head:isMirror?[255-h[0],h[1]]:h,torso:isMirror?[255-t[0],t[1]]:t,dir,layers:ls,ramps:appearanceRamps(SLOTS,appearance)});};
const report={status:'revisao-artistica',registration,actions:{},hair:{},backpack:{},limitations:['Corrida não produzida nesta v1.','Integração no jogo pendente de revisão visual.']};
for(const action of ['parado','andar'])for(const dir of ['se','ne']){
 report.actions[`${action}-${dir}`]=auditFrames(base[`${action}-${dir}`].map((image,i)=>({image,head:heads[`${action}-${dir}`][i]})));
 report.hair[`${action}-${dir}`]=base[`${action}-${dir}`].map((b,i)=>auditHeadLayer(b,heads[`${action}-${dir}`][i],layers['cabelo-kael'][dir]));
 report.backpack[`${action}-${dir}`]=base[`${action}-${dir}`].map((b,i)=>auditTorsoLayer(b,torsos[`${action}-${dir}`][i],layers['mochila-pipa'][dir]));
}
const preview=blank(8*256,8*256);for(const [r,action,dir] of [['0','parado','se'],['1','parado','ne'],['2','parado','sw'],['3','parado','nw'],['4','andar','se'],['5','andar','ne'],['6','andar','sw'],['7','andar','nw']]){const n=action==='parado'?4:8;for(let i=0;i<n;i++)over(preview,composed(action,dir,i),i*256,Number(r)*256);}
await save(downscale(preview),art+'/previa-aparencia.png');
const looks=[{}, {pele:1,cabelo:2,jaqueta:2,camiseta:1,calca:1,tenis:1}, {pele:2,cabelo:1,jaqueta:1,camiseta:2,calca:2,mochila:1}, {pele:3,cabelo:3,jaqueta:3,camiseta:1,tenis:2,mochila:2}];
const contact=blank(1024,512);for(let j=0;j<looks.length;j++)for(let d=0;d<2;d++)over(contact,composed('parado',d?'ne':'se',0,looks[j]),j*256,d*256);await save(contact,art+'/aparencias.png');
// Animated four-direction review, using the same composition path as the Studio.
for(const action of ['parado','andar']){
 const buffers=[];for(let i=0;i<(action==='parado'?4:8);i++){const image=blank(1024,256);for(const [j,dir] of ['se','ne','nw','sw'].entries())over(image,composed(action,dir,i),j*256,0);buffers.push(Buffer.from(image.data));}
 await sharp(Buffer.concat(buffers),{raw:{width:1024,height:256*buffers.length,channels:4,pageHeight:256}}).gif({delay:Array(buffers.length).fill(ACTIONS[action].ms),loop:0}).toFile(art+`/${action}.gif`);
}
await fs.writeFile(art+'/kael.avatarstudio.json',JSON.stringify(project));
const runtime=manifest(project);delete runtime.actions.correr;runtime.reviewStatus='artistic-review';runtime.productionReady=false;
await fs.writeFile(assets+'/manifest.json',JSON.stringify(runtime,null,2));await fs.writeFile(assets+'/paleta.json',JSON.stringify(paletteJson(project),null,2));await fs.writeFile(art+'/conferencia.json',JSON.stringify(report,null,2));
const files=[];for(const folder of [assets+'/base',assets+'/camadas'])for(const name of await fs.readdir(folder))files.push({name:path.relative(root,folder+'/'+name).replaceAll('\\','/'),data:new Uint8Array(await fs.readFile(folder+'/'+name))});
for(const file of [assets+'/manifest.json',assets+'/paleta.json',art+'/kael.avatarstudio.json',art+'/previa-aparencia.png',art+'/conferencia.json'])files.push({name:path.relative(root,file).replaceAll('\\','/'),data:new Uint8Array(await fs.readFile(file))});await fs.writeFile(art+'/kael-v1-avatar.zip',zip(files));
console.log(JSON.stringify({frames:24,layers:project.layers.length,report:Object.fromEntries(Object.entries(report.actions).map(([k,v])=>[k,v.items])),hair:Object.fromEntries(Object.entries(report.hair).map(([k,v])=>[k,v.map(x=>Math.round(x.share*100))]))},null,2));
