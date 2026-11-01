import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
import {sample,render} from './model.mjs';
const require=createRequire(import.meta.url),{createCanvas,loadImage}=require(process.env.SOULGEN_CANVAS_MODULE||'@napi-rs/canvas');
const folder='art/soulgen/keys/doberman-c/sliced-rig-v2/',project=JSON.parse(fs.readFileSync(folder+'doberman-c.soulgen.json')),plan=JSON.parse(fs.readFileSync(folder+'export.json'));
const images={};for(const [id,a]of Object.entries(project.assets))images[id]=await loadImage(folder+path.basename(a.src));
const atlas=createCanvas(plan.width,plan.height),tile=createCanvas(plan.cell,plan.cell),g=atlas.getContext('2d');
const animations={},playback={};const bounds=[plan.cell,plan.cell,0,0];
for(const f of plan.frames){render(tile.getContext('2d'),project,images,sample(project,f.clip,f.time),{scale:plan.renderScale});g.drawImage(tile,f.x,f.y);const pixels=tile.getContext('2d').getImageData(0,0,plan.cell,plan.cell).data;for(let y=0;y<plan.cell;y++)for(let x=0;x<plan.cell;x++)if(pixels[(y*plan.cell+x)*4+3]>8){bounds[0]=Math.min(bounds[0],x);bounds[1]=Math.min(bounds[1],y);bounds[2]=Math.max(bounds[2],x);bounds[3]=Math.max(bounds[3],y);}const key=f.clip==='skill'?'attack':f.clip;(animations[key]??=[]).push({x:f.x,y:f.y,w:f.w,h:f.h});playback[key]={fps:plan.fps,loop:project.clips[f.clip].loop,seconds:project.clips[f.clip].seconds};}
fs.writeFileSync('godot/assets/campaign/combat-doberman-c-soulgen-v2.png',atlas.toBuffer('image/png'));
const file='godot/assets/campaign/content.json',content=JSON.parse(fs.readFileSync(file));content.combat['doberman-c']={image:'combat-doberman-c-soulgen-v2.png',animations,playback,source:folder+'doberman-c.soulgen.json'};fs.writeFileSync(file,JSON.stringify(content,null,2)+'\n');
for(const [file,rect]of [['sprite-bounds.json',[bounds[0],bounds[1],bounds[2]-bounds[0]+1,bounds[3]-bounds[1]+1]],['portrait-regions.json',[143,50,60,82]]]){const p='godot/assets/campaign/battle-ink/'+file,data=JSON.parse(fs.readFileSync(p));data['doberman-c']=rect;fs.writeFileSync(p,JSON.stringify(data,null,2)+'\n');}
console.log('Dóber: exported Soulgen atlas,',plan.frames.length,'frames,',Object.keys(animations).join(', '),bounds);
