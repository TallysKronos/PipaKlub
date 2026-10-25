// Bake the author's approved remakes into the existing game atlas contracts.
// Run from the repository root. Source projects and their manual layout stay untouched.
import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
import {createHash} from 'node:crypto';
import {exportPlan,render,sample} from './model.mjs';
const require=createRequire(import.meta.url);
const {createCanvas,loadImage}=require(process.env.SOULGEN_CANVAS_MODULE||'@napi-rs/canvas');
const read=file=>JSON.parse(fs.readFileSync(file,'utf8'));
const write=(file,value)=>fs.writeFileSync(file,JSON.stringify(value,null,2)+'\n');
const ids=['nozinho','guaravento','micofolha','capimansa','tatutrama','flautrevo','trinca-brasas','alvaneve','chaspiral','hiponilo'];
const manifest=read('assets/atlas.json'),portraits=read('assets/portraits.json'),world=read('assets/creatures/overworld-v1/manifest.json'),dex=read('assets/pipa-dex.json').entries;
const directory='assets/creatures/remakes-soulgen-v2',cell=256,fps=12;
fs.mkdirSync(directory,{recursive:true});
function bounds(ctx,w=cell,h=cell){
 const data=ctx.getImageData(0,0,w,h).data;let x0=w,y0=h,x1=-1,y1=-1;
 for(let y=0;y<h;y++)for(let x=0;x<w;x++)if(data[(y*w+x)*4+3]){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}
 if(x1<0)throw Error('Exported pose is empty');return {x:x0,y:y0,w:x1-x0+1,h:y1-y0+1};
}
const provenance={version:1,kind:'soulgen-baked-remakes',fps,cell,species:{},overworldView:'Approved three-quarter view mirrored west/east; no invented rear anatomy.'};
const review=createCanvas(1600,800),rg=review.getContext('2d');rg.fillStyle='#163840';rg.fillRect(0,0,1600,800);
for(const [speciesIndex,id]of ids.entries()){
 const source=`art/soulgen/keys/${id}/color-rig-v2/${id}.soulgen.json`,sourceBytes=fs.readFileSync(source),project=JSON.parse(sourceBytes),entry=dex.find(e=>e.id===id);
 if(!entry||project.creatureId!==id)throw Error('Species/source mismatch: '+id);
 const images={},sourceHashes={};
 for(const [key,a]of Object.entries(project.assets)){
  const bytes=a.src.startsWith('data:')?Buffer.from(a.src.split(',')[1],'base64'):fs.readFileSync(a.src.replace(/^\//,''));
  const image=await loadImage(bytes);if(image.width!==a.width||image.height!==a.height)throw Error('Source size mismatch: '+id+'/'+key);
  images[key]=image;sourceHashes[key]=createHash('sha256').update(bytes).digest('hex');
 }
 const plan=exportPlan(project,{fps,cell,columns:8}),sheet=createCanvas(plan.width,plan.height),sg=sheet.getContext('2d'),tile=createCanvas(cell,cell),tg=tile.getContext('2d');
 // One framing for every action; normalize exported whitespace without editing the author's rig.
 let minX=cell,minY=cell,maxX=0,maxY=0;
 for(const f of plan.frames){render(tg,project,images,sample(project,f.clip,f.time),{scale:plan.renderScale});const b=bounds(tg);minX=Math.min(minX,b.x);minY=Math.min(minY,b.y);maxX=Math.max(maxX,b.x+b.w);maxY=Math.max(maxY,b.y+b.h);}
 const fit=cell*.88/Math.max(maxX-minX,maxY-minY),framing={scale:plan.renderScale*fit,offsetX:(cell/2-(minX+maxX)/2)*fit,offsetY:(cell/2-(minY+maxY)/2)*fit};
 const paint=(clip,time,facing=1,p=project)=>render(tg,p,images,sample(project,clip,time),{...framing,offsetX:framing.offsetX*facing,facing});
 const frames={},animations={},playback={};
 for(const f of plan.frames){
  paint(f.clip,f.time);const b=bounds(tg);if(b.x===0||b.y===0||b.x+b.w===cell||b.y+b.h===cell)throw Error('Pose touches export border: '+id+'/'+f.name);
  sg.drawImage(tile,f.x,f.y);frames[f.name]={frame:{x:f.x,y:f.y,w:cell,h:cell},duration:f.duration,contentBounds:b};
 }
 for(const [clip,a]of Object.entries(plan.animations)){animations[clip]=a.frames;playback[clip]={loop:a.loop,durations:a.frames.map(()=>1000/fps),hitTime:a.hitTime};}
 frames['0']=frames[animations.idle[0]];
 // Existing professor conversations use these names; retain their contracts.
 if(id==='nozinho')for(const [alias,clip]of [['happy','victory'],['greet','victory']]){animations[alias]=animations[clip];playback[alias]=playback[clip];}
 const image=`creatures/remakes-soulgen-v2/${id}.png`;
 fs.writeFileSync('assets/'+image,sheet.toBuffer('image/png'));
 if(id==='nozinho'){
  const hero=createCanvas(1024,1024);render(hero.getContext('2d'),project,images,sample(project,'skill',project.clips.skill.hitTime||.7),{scale:framing.scale*4,offsetX:framing.offsetX*4,offsetY:framing.offsetY*4});
  fs.writeFileSync(directory+'/nozinho-signature.png',hero.toBuffer('image/png'));
 }
 manifest.atlases[entry.atlas]={frames,animations,playback,meta:{image,size:{w:plan.width,h:plan.height},viewport:{x:0,y:0,w:cell,h:cell},format:'RGBA8888',source,artRevision:project.artRevision,rigRevision:project.rigRevision,facing:'east'}};
 const face=project.parts.find(p=>p.id==='headCenter')||project.parts.find(p=>p.id==='head')||project.parts.find(p=>p.faces)||project.parts.find(p=>p.id==='body');
 paint('idle',0,1,{...project,parts:project.parts.map(p=>({...p,visible:p.id===face.id}))});
 const fb=bounds(tg),s=Math.min(cell,Math.ceil(Math.max(fb.w,fb.h)*1.14));
 portraits[id]={frame:'idle',crop:[Math.round(Math.max(0,Math.min(cell-s,fb.x+fb.w/2-s/2))),Math.round(Math.max(0,Math.min(cell-s,fb.y+fb.h/2-s/2))),s]};
 paint('idle',0);const rest=bounds(tg),worldCell=128,count=16,walk=createCanvas(worldCell*8,worldCell*16),wg=walk.getContext('2d'),worldFrames=[],idle=[],move=[];
 const anchor={x:worldCell/2,y:(rest.y+rest.h)*worldCell/cell};
 for(const clip of ['idle','flight'])for(let d=0;d<4;d++){
  const sequence=[];
  for(let i=0;i<count;i++){
   const n=worldFrames.length,x=n%8*worldCell,y=Math.floor(n/8)*worldCell;
   paint(clip,i/count*project.clips[clip].seconds,d===1?-1:1);wg.drawImage(tile,x,y,worldCell,worldCell);
   worldFrames.push({x,y,w:worldCell,h:worldCell,bounds:{x:0,y:0,w:worldCell,h:worldCell},footAnchor:{...anchor}});sequence.push(n);
  }
  (clip==='idle'?idle:move).push(sequence);
 }
 const worldImage=`creatures/remakes-soulgen-v2/${id}-overworld.png`;fs.writeFileSync('assets/'+worldImage,walk.toBuffer('image/png'));
 world.species[id]={...world.species[id],id,name:entry.name,image:worldImage,referenceHeight:rest.h*worldCell/cell,scale:1,frameMs:project.clips.flight.seconds*1000/count,idleFrameMs:project.clips.idle.seconds*1000/count,frames:worldFrames,animations:{idle,move},view:'three-quarter-mirrored',artRevision:project.artRevision};
 provenance.species[id]={source,sourceHash:createHash('sha256').update(sourceBytes).digest('hex'),sourceHashes,rigRevision:project.rigRevision,atlas:entry.atlas,image,overworld:worldImage,logicalSize:[project.width,project.height],framing,frames:plan.frames.length};
 // A compact production contact sheet, rendered through the same sampler.
 const ox=speciesIndex%5*320,oy=Math.floor(speciesIndex/5)*400;
 paint('idle',0);rg.drawImage(tile,ox+32,oy+10,256,256);rg.fillStyle='#ffdf9e';rg.font='bold 20px sans-serif';rg.fillText(entry.name,ox+20,oy+298);
 for(const [j,clip]of ['flight','skill','hurt','victory'].entries()){paint(clip,clip==='skill'?project.clips.skill.hitTime||.5:.3);rg.drawImage(tile,ox+j*80,oy+310,80,80);}
 console.log('Exportado',id,plan.frames.length,'quadros +',worldFrames.length,'de acompanhamento');
}
write('assets/atlas.json',manifest);write('assets/portraits.json',portraits);write('assets/creatures/overworld-v1/manifest.json',world);write(directory+'/manifest.json',provenance);
fs.writeFileSync(directory+'/review.png',review.toBuffer('image/png'));
