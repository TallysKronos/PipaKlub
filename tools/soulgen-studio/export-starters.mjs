// Bake approved rigs once; the shipped game uses ordinary cached PNG atlases.
// Optional SOULGEN_CANVAS_MODULE points to an installed @napi-rs/canvas entry.
import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
import {createHash} from 'node:crypto';
import {createCarcara} from './carcara.mjs';
import {exportPlan,render,sample,matrices,point} from './model.mjs';
const require=createRequire(import.meta.url);
const {createCanvas,loadImage}=require(process.env.SOULGEN_CANVAS_MODULE||'@napi-rs/canvas');
const read=file=>JSON.parse(fs.readFileSync(file,'utf8'));
const write=(file,value)=>fs.writeFileSync(file,JSON.stringify(value,null,2)+'\n');
const manifest=read('assets/atlas.json'),portraits=read('assets/portraits.json'),world=read('assets/creatures/overworld-v1/manifest.json');
const directory='assets/creatures/starters-soulgen-v2';fs.mkdirSync(directory,{recursive:true});
const cell=256,fps=12,provenance={version:2,kind:'soulgen-baked-atlases',fps,cell,species:{},overworldView:'Approved three-quarter view, mirrored for west/east. South/north retain that same authored view; no invented rear anatomy.'};
for(const id of ['carcara','mata-verde','azulao','raio-de-sol','rabbito']){
 const source=id==='carcara'?'art/soulgen/keys/carcara/color-rig/rig.mjs':`art/soulgen/keys/${id}/color-rig-v2/${id}.soulgen.json`;
 const project=id==='carcara'?await createCarcara(async src=>{const b=fs.readFileSync(src.replace(/^\//,''));return {width:b.readUInt32BE(16),height:b.readUInt32BE(20)};}):read(source);
 const images={};for(const [key,a]of Object.entries(project.assets))images[key]=await loadImage(a.src.replace(/^\//,''));
 const plan=exportPlan(project,{fps,cell,columns:8}),canvas=createCanvas(plan.width,plan.height),g=canvas.getContext('2d'),tile=createCanvas(cell,cell),t=tile.getContext('2d');
 // Canonical game facing is east. Carcará's approved drawing faces west.
 const facing=id==='carcara'?-1:1;
 const paint=(clip,time,mirror=1)=>render(t,project,images,sample(project,clip,time),{scale:plan.renderScale,facing:facing*mirror});
 const frames={},animations={},playback={};
 for(const f of plan.frames){paint(f.clip,f.time);g.drawImage(tile,f.x,f.y);frames[f.name]={frame:{x:f.x,y:f.y,w:cell,h:cell},rotated:false,trimmed:false,sourceSize:{w:cell,h:cell},spriteSourceSize:{x:0,y:0,w:cell,h:cell},duration:f.duration};}
 for(const [clip,a]of Object.entries(plan.animations)){animations[clip]=a.frames;playback[clip]={loop:a.loop,durations:a.frames.map(()=>1000/fps),hitTime:a.hitTime};}
 frames['0']=frames[animations.idle[0]];
 const atlasId=id==='rabbito'?id:'basic-'+id,image=`creatures/starters-soulgen-v2/${id}.png`;
 fs.writeFileSync('assets/'+image,canvas.toBuffer('image/png'));
 manifest.atlases[atlasId]={frames,animations,playback,meta:{image,size:{w:plan.width,h:plan.height},viewport:{x:0,y:0,w:cell,h:cell},format:'RGBA8888',scale:'1',source,artRevision:2,rigRevision:project.rigRevision||0}};
 const facePart=project.parts.find(p=>p.id==='head')||project.parts.find(p=>p.id==='body'),m=matrices(project,sample(project,'idle',0))[facePart.id],r=facePart.rect;
 const corners=[[r[0],r[1]],[r[0]+r[2],r[1]],[r[0],r[1]+r[3]],[r[0]+r[2],r[1]+r[3]]].map(([x,y])=>point(m,x,y)).map(p=>({x:cell/2+(p.x-project.width/2)*plan.renderScale*facing,y:cell/2+(p.y-project.height/2)*plan.renderScale}));
 const cx=(Math.min(...corners.map(p=>p.x))+Math.max(...corners.map(p=>p.x)))/2,cy=(Math.min(...corners.map(p=>p.y))+Math.max(...corners.map(p=>p.y)))/2,s=Math.min(cell,Math.ceil(Math.max(r[2],r[3])*plan.renderScale*1.2));
 portraits[id]={frame:'idle',crop:[Math.round(Math.max(0,Math.min(cell-s,cx-s/2))),Math.round(Math.max(0,Math.min(cell-s,cy-s/2))),s]};
 const count=16,worldCell=128,ratio=worldCell/cell,walk=createCanvas(worldCell*8,worldCell*16),wg=walk.getContext('2d'),worldFrames=[],idle=[],move=[];
 // A fixed logical support point keeps feet/rabiola anchored between poses.
 const supportY=id==='rabbito'?project.parts.find(p=>p.id==='body').rect[1]+project.parts.find(p=>p.id==='body').rect[3]:project.rootPivot[1]+project.height*.3;
 const anchor={x:worldCell/2,y:(cell/2+(supportY-project.height/2)*plan.renderScale)*ratio};
 for(const clip of ['idle','flight'])for(let d=0;d<4;d++){
  const sequence=[];
  for(let i=0;i<count;i++){
   const n=worldFrames.length,x=n%8*worldCell,y=Math.floor(n/8)*worldCell;
   paint(clip,i/count*project.clips[clip].seconds,d===1?-1:1);wg.drawImage(tile,x,y,worldCell,worldCell);
   worldFrames.push({x,y,w:worldCell,h:worldCell,bounds:{x:0,y:0,w:worldCell,h:worldCell},footAnchor:{...anchor}});sequence.push(n);
  }
  (clip==='idle'?idle:move).push(sequence);
 }
 const worldImage=`creatures/starters-soulgen-v2/${id}-overworld.png`;fs.writeFileSync('assets/'+worldImage,walk.toBuffer('image/png'));
 world.species[id]={...world.species[id],image:worldImage,referenceHeight:project.height*plan.renderScale*ratio,scale:1,frameMs:project.clips.flight.seconds*1000/count,idleFrameMs:project.clips.idle.seconds*1000/count,frames:worldFrames,animations:{idle,move},view:'three-quarter-mirrored',artRevision:2};
 provenance.species[id]={source,sourceHash:createHash('sha256').update(fs.readFileSync(source)).digest('hex'),rigRevision:project.rigRevision||0,atlas:atlasId,image,overworld:worldImage,logicalSize:[project.width,project.height],renderScale:plan.renderScale,frames:plan.frames.length};
 console.log('Exportado',id,plan.frames.length,'quadros de combate +',worldFrames.length,'de acompanhamento');
}
write('assets/atlas.json',manifest);write('assets/portraits.json',portraits);write('assets/creatures/overworld-v1/manifest.json',world);write(directory+'/manifest.json',provenance);
