import fs from 'node:fs/promises';
import {createKael,setKaelDirection} from '../tools/soulgen-studio/kael.mjs';
import {raster,sharp} from './kael-raster.mjs';
const project=await createKael(),frames=[],animations={},images=[],fps=12,cell=128,columns=16;
for(const view of project.avatar.directions){setKaelDirection(project,view);for(const [id,c]of Object.entries(project.clips)){
 const key=view+'-'+id,count=Math.ceil(c.seconds*fps)+(c.loop?0:1),sequence=[];
 for(let i=0;i<count;i++){const index=frames.length,time=Math.min(i/fps,c.seconds),name=key+'-'+String(i).padStart(3,'0'),x=index%columns*cell,y=Math.floor(index/columns)*cell;frames.push({name,view,clip:id,time,x,y,w:cell,h:cell});sequence.push(name);images.push({input:await raster(project,id,time,{size:cell}),left:x,top:y});}
 animations[key]={frames:sequence,loop:c.loop,seconds:c.seconds};
}}
const dir='art/soulgen/keys/kael-v2/exports';await fs.mkdir(dir,{recursive:true});
const width=columns*cell,height=Math.ceil(frames.length/columns)*cell;
await sharp({create:{width,height,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(images).png().toFile(dir+'/kael-four-directions.png');
await fs.writeFile(dir+'/kael-four-directions.json',JSON.stringify({schema:'soulgen-avatar-atlas-v1',appearance:project.avatar.appearance,directions:project.avatar.directions,width,height,fps,cell,pixelPivot:{x:64,y:110.5},frames,animations,source:'kael-v2.soulgen.json'},null,2));
console.log(frames.length,'frames,',width+'×'+height,'PNG transparente, 24 sequências.');
