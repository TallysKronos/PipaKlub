import fs from 'node:fs/promises';import path from 'node:path';import {execFileSync} from 'node:child_process';import {createRequire} from 'node:module';
const require=createRequire(import.meta.url),{createCanvas,loadImage}=require(process.env.SOULGEN_CANVAS_MODULE||'@napi-rs/canvas');
const base='art/concepts/montaria-doberman/animation-v1',out=base+'/correction-front-walk-v1';await fs.mkdir(out+'/source-frames',{recursive:true});await fs.mkdir(out+'/frames',{recursive:true});
const ff=path.resolve('tmp/video-encoder/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe');
execFileSync(ff,['-hide_banner','-loglevel','error','-i',base+'/video-original/walk-s.mp4','-vf',"select='gte(n,24)*lte(n,52)*not(mod(n-24,4))'",'-fps_mode','vfr','-frames:v','8','-y',out+'/source-frames/raw-%02d.png']);
const sheet=createCanvas(1536,1024),ctx=sheet.getContext('2d'),refs=[];
for(let i=0;i<8;i++){const im=await loadImage(out+'/source-frames/raw-'+String(i+1).padStart(2,'0')+'.png');const cell=createCanvas(384,512),g=cell.getContext('2d');g.fillStyle='#ff00ff';g.fillRect(0,0,384,512);g.drawImage(im,170,120,240,360,42,31,300,450);ctx.drawImage(cell,(i%4)*384,Math.floor(i/4)*512);refs.push({sourceFrame:24+i*4,rect:[(i%4)*384,Math.floor(i/4)*512,384,512],durationMs:166.6667});}
await fs.writeFile(out+'/before-sheet.png',sheet.toBuffer('image/png'));
const mount=await loadImage(base+'/sources/idle-eight.png'),dog=createCanvas(384,512);dog.getContext('2d').drawImage(mount,0,0,384,512,0,0,384,512);await fs.writeFile(out+'/mount-front-approved.png',dog.toBuffer('image/png'));
await fs.writeFile(out+'/extraction.json',JSON.stringify({sourceVideo:'../video-original/walk-s.mp4',sourceFps:24,cell:[384,512],columns:4,rows:2,commonCrop:[170,120,240,360],drawRect:[42,31,300,450],frames:refs,approval:'pending'},null,2));
console.log('8 front gait frames extracted; 1536x1024 joint correction target.');
