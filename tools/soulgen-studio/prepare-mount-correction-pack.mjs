import fs from 'node:fs/promises';import path from 'node:path';import {execFileSync} from 'node:child_process';import {createRequire} from 'node:module';
const require=createRequire(import.meta.url),{createCanvas,loadImage}=require(process.env.SOULGEN_CANVAS_MODULE||'@napi-rs/canvas');
const root='art/concepts/montaria-doberman/animation-v1',out=root+'/corrected-pack-v1',ff=path.resolve('tmp/video-encoder/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe');await fs.mkdir(out,{recursive:true});
const jobs=['walk-e','run-e','walk-sw','run-sw','walk-ne','run-ne','walk-n','run-n','run-s'];
const entries=[];
for(const id of jobs){const folder=out+'/'+id;await fs.mkdir(folder+'/source-frames',{recursive:true});await fs.mkdir(folder+'/frames',{recursive:true});
 const start=id.startsWith('run')?12:24,step=id.startsWith('run')?3:4;const select=`select='gte(n,${start})*lte(n,${start+step*7})*not(mod(n-${start},${step}))'`;
 execFileSync(ff,['-hide_banner','-loglevel','error','-i',root+'/video-original/'+id+'.mp4','-vf',select,'-fps_mode','vfr','-frames:v','8','-y',folder+'/source-frames/raw-%02d.png']);
 const sheet=createCanvas(1536,1024),ctx=sheet.getContext('2d');
 // One fixed crop per view retains gait phase and scale; this only arranges source pixels.
 const dir=id.split('-')[1],crop=dir==='n'||dir==='s'?[110,112,300,360]:[25,100,462,362];
 const scale=Math.min(344/crop[2],450/crop[3]),w=crop[2]*scale,h=crop[3]*scale;
 for(let i=0;i<8;i++){const im=await loadImage(folder+'/source-frames/raw-'+String(i+1).padStart(2,'0')+'.png');const cell=createCanvas(384,512),g=cell.getContext('2d');g.fillStyle='#ff00ff';g.fillRect(0,0,384,512);g.drawImage(im,...crop,(384-w)/2,480-h,w,h);ctx.drawImage(cell,i%4*384,Math.floor(i/4)*512);}
 await fs.writeFile(folder+'/before.png',sheet.toBuffer('image/png'));entries.push({id,source:id,mirrorTo:dir==='e'?id.replace('-e','-w'):dir==='sw'?id.replace('-sw','-se'):dir==='ne'?id.replace('-ne','-nw'):null,reference:'../../references/mount-edited-'+dir+'.png',sourceFrames:Array.from({length:8},(_,i)=>start+i*step),cell:[384,512],durationMs:1000*step/24,status:'prepared'});
}
await fs.writeFile(out+'/manifest.json',JSON.stringify({entries,notes:['walk-s uses the earlier jointly corrected front sheet','walk-se zooming take rejected; mirrored from corrected SW','run-n turning take rejected; rear run will be reconstructed from identity and gait phases']},null,2));console.log('9 correction targets prepared.');
