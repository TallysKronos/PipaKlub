import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
import {sample,render} from '../../../../tools/soulgen-studio/model.mjs';
const require=createRequire(import.meta.url),{createCanvas,loadImage}=require(process.env.SOULGEN_CANVAS_MODULE||'@napi-rs/canvas');
const folder=fileURLToPath(new URL('./sliced-rig-v2/',import.meta.url)),project=JSON.parse(fs.readFileSync(folder+'doberman-c.soulgen.json')),images={};
for(const [id,a]of Object.entries(project.assets))images[id]=await loadImage(folder+path.basename(a.src));
const contact=createCanvas(1280,640),g=contact.getContext('2d');let i=0;
for(const p of project.parts){const col=i%4,row=Math.floor(i/4);g.fillStyle='#f2e9d6';g.fillRect(col*320,row*320,320,320);const im=images[p.asset],a=createCanvas(im.width,im.height),x=a.getContext('2d');x.drawImage(im,0,0);const d=x.getImageData(0,0,im.width,im.height).data;let left=im.width,top=im.height,right=0,bottom=0;for(let y=0;y<im.height;y++)for(let xx=0;xx<im.width;xx++)if(d[(y*im.width+xx)*4+3]>32){left=Math.min(left,xx);top=Math.min(top,y);right=Math.max(right,xx);bottom=Math.max(bottom,y);}const w=right-left+1,h=bottom-top+1,s=Math.min(280/w,260/h);g.drawImage(im,left,top,w,h,col*320+(320-w*s)/2,row*320+(280-h*s)/2,w*s,h*s);g.fillStyle='#182c3b';g.font='14px sans-serif';g.fillText(p.name,col*320+10,row*320+308);i++;}
fs.writeFileSync(folder+'parts-review.png',contact.toBuffer('image/png'));
const out=fileURLToPath(new URL('../../../../tmp/doberman-sliced-motion/',import.meta.url));fs.mkdirSync(out,{recursive:true});const actions=Object.keys(project.clips);
for(let i=0;i<48;i++){const c=createCanvas(960,640),g=c.getContext('2d');for(let j=0;j<6;j++){const col=j%3,row=Math.floor(j/3),tile=createCanvas(320,290),clip=actions[j],time=i/12;render(tile.getContext('2d'),project,images,sample(project,clip,time),{scale:.72});g.fillStyle=row?'#182c3b':'#f2e9d6';g.fillRect(col*320,row*320,320,320);g.drawImage(tile,col*320,row*320);g.fillStyle=row?'#f2e9d6':'#182c3b';g.font='15px sans-serif';g.fillText(project.clips[clip].label,col*320+12,row*320+308);}fs.writeFileSync(out+'/'+String(i).padStart(3,'0')+'.png',c.toBuffer('image/png'));}
