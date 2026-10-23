import fs from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {sharp} from './kael-raster.mjs';
const dir='art/soulgen/keys/kael-frame-test';await fs.mkdir(dir+'/frames',{recursive:true});
const source=dir+'/source/walk-east.png',xs=[0,444,887,1331,1774],ys=[0,465,887];
// Neck/head registration, measured on the source. Not a changing silhouette center.
const headX=[235,232,212,213,234,231,212,213],scale=.5,cell=256,anchor=[128,224],frames=[],renders=[];
for(let index=0;index<8;index++){
 const col=index%4,row=Math.floor(index/4),left=xs[col],top=ys[row],width=xs[col+1]-left,height=ys[row+1]-top;
 const cut=await sharp(source).extract({left,top,width,height}).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 let floor=-1,head=height,opaque=0;for(let y=0;y<height;y++)for(let x=0;x<width;x++){const i=(y*width+x)*4;if(cut.data[i+3]<32)cut.data[i+3]=0;if(cut.data[i+3]>128){floor=Math.max(floor,y);head=Math.min(head,y);opaque++;}}
 if(floor<0)throw Error('Quadro vazio: '+index);
 const dx=Math.round(anchor[0]-headX[index]*scale),w=Math.round(width*scale),h=Math.round(height*scale);
 const resized=await sharp(cut.data,{raw:cut.info}).resize(w,h).png().toBuffer();
 const alpha=await sharp(resized).extractChannel(3).raw().toBuffer();let scaledFloor=-1;for(let y=0;y<h;y++)for(let x=0;x<w;x++)if(alpha[y*w+x]>128)scaledFloor=Math.max(scaledFloor,y);
 const dy=anchor[1]-scaledFloor;
 const buffer=await sharp({create:{width:cell,height:cell,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:resized,left:dx,top:dy}]).png().toBuffer();
 await fs.writeFile(dir+'/frames/east-'+index+'.png',buffer);renders.push(buffer);
 frames.push({id:'east-'+index,x:col*cell,y:row*cell,w:cell,h:cell,duration:100,source:{left,top,width,height,headX:headX[index],floor,head,opaque},registration:{scale,dx,dy},sha256:createHash('sha256').update(buffer).digest('hex')});
}
await sharp({create:{width:1024,height:512,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(renders.map((input,i)=>({input,left:i%4*cell,top:Math.floor(i/4)*cell}))).png().toFile(dir+'/walk-east-atlas.png');
const gifRenders=[];for(const frame of renders)gifRenders.push(await sharp(frame).flatten({background:'#e8efdc'}).ensureAlpha().raw().toBuffer());
await sharp(Buffer.concat(gifRenders),{raw:{width:cell,height:cell*8,channels:4,pageHeight:cell}}).gif({delay:Array(8).fill(100),loop:0}).toFile(dir+'/walk-east.gif');
const manifest={schema:'soulgen-frame-test-v1',name:'Kael · Teste quadro a quadro',direction:'east',method:'Oito poses completas raster, sem rotação ou deformação de membros.',scope:'Teste de movimento: uma roupa e um cabelo. Ainda não contém camadas de customização.',image:'/art/soulgen/keys/kael-frame-test/walk-east-atlas.png',cell,columns:4,rows:2,anchor,scale,nativeHeight:96,cycleMs:800,frames};
await fs.writeFile(dir+'/manifest.json',JSON.stringify(manifest,null,2));console.log('8 quadros completos, mesma escala .5; PNG, GIF e metadados.');
