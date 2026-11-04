import fs from 'node:fs/promises';import path from 'node:path';import {createRequire} from 'node:module';import {execFileSync} from 'node:child_process';import {decodePNG} from '../pixelgen/png.mjs';
const require=createRequire(import.meta.url),{createCanvas,loadImage}=require(process.env.SOULGEN_CANVAS_MODULE||'@napi-rs/canvas');
const base='art/concepts/montaria-doberman/animation-v1',root=base+'/corrected-pack-v1',ff=path.resolve('tmp/video-encoder/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe');
const manifest=JSON.parse(await fs.readFile(root+'/manifest.json')),entries=manifest.entries,records=[];
entries.push({id:'walk-s',source:'walk-s',cell:[384,512],durationMs:1000/6,status:'previously-corrected',sourceSheet:'../correction-front-walk-v1/corrected-sheet-v1.png'});
const pending=[];
for(const entry of entries){const folder=root+'/'+entry.id;await fs.mkdir(folder,{recursive:true});const file=entry.sourceSheet?root+'/'+entry.sourceSheet:folder+'/generated.png',im=decodePNG(await fs.readFile(file)),image=await loadImage(file);let components;
 if(entry.sourceSheet){components=[];for(let i=0;i<8;i++){let l=im.width,t=im.height,r=0,b=0;for(let y=Math.floor(i/4)*512;y<Math.floor(i/4)*512+512;y++)for(let x=i%4*384;x<i%4*384+384;x++)if(im.data[(y*im.width+x)*4+3]>=128){l=Math.min(l,x);t=Math.min(t,y);r=Math.max(r,x);b=Math.max(b,y);}components.push({rect:[l,t,r-l+1,b-t+1]});}}
 else components=JSON.parse(await fs.readFile(folder+'/components.json'));
 if(components.length!==8)throw Error(entry.id+': expected 8 connected sprites');
 components.sort((a,b)=>(a.rect[1]+a.rect[3]/2)-(b.rect[1]+b.rect[3]/2));components=[...components.slice(0,4).sort((a,b)=>a.rect[0]-b.rect[0]),...components.slice(4).sort((a,b)=>a.rect[0]-b.rect[0])];
 const poses=[];
 for(const component of components){const [l,t,w,h]=component.rect;let minY=im.height;for(let y=t;y<t+Math.min(h,160);y++)for(let x=l;x<l+w;x++){const n=(y*im.width+x)*4,[r,g,b,a]=im.data.subarray(n,n+4);if(a>=128&&b>40&&b>r*1.2&&b>g*1.06)minY=Math.min(minY,y);}
 if(minY===im.height)throw Error('Cannot locate blue hair '+entry.id);let left=im.width,right=0,top=minY,bottom=minY;
 for(let y=minY;y<Math.min(t+h,minY+45);y++)for(let x=l;x<l+w;x++){const n=(y*im.width+x)*4,[r,g,b,a]=im.data.subarray(n,n+4);if(a>=128&&b>40&&b>r*1.2&&b>g*1.06){left=Math.min(left,x);right=Math.max(right,x);bottom=Math.max(bottom,y);}}
 const anchor=[(left+right)/2,(top+bottom)/2],crop=[Math.max(0,l-5),Math.max(0,t-5),Math.min(im.width,l+w+5)-Math.max(0,l-5),Math.min(im.height,t+h+5)-Math.max(0,t-5)];poses.push({anchor,crop,hairWidth:right-left+1,component:component.rect});
 }
 pending.push({entry,folder,file,image,poses});
}
// Normalize head scale per source sequence and use its largest downward reach as support.
const median=a=>[...a].sort((x,y)=>x-y)[Math.floor(a.length/2)];
for(const p of pending){p.scale=56/median(p.poses.map(f=>f.hairWidth));for(const f of p.poses){const [x,y,w,h]=f.crop,[ax,ay]=f.anchor;p.scale=Math.min(p.scale,228/Math.max(ax-x,x+w-ax),440/h);}
 p.groundReach=Math.max(...p.poses.map(f=>(f.crop[1]+f.crop[3]-f.anchor[1])*p.scale));p.anchorY=480-p.groundReach;
}
async function publish(id,frames,entry,scale,anchorY,mirroredFrom=null){const folder=root+'/'+id;await fs.mkdir(folder+'/frames',{recursive:true});await fs.mkdir(folder+'/preview-frames',{recursive:true});const atlas=createCanvas(2048,1024),g=atlas.getContext('2d'),checks=[];
 for(let i=0;i<8;i++){const frame=frames[i],ctx=frame.getContext('2d'),rgba=ctx.getImageData(0,0,512,512).data;let l=512,t=512,r=0,b=0,count=0;for(let y=0;y<512;y++)for(let x=0;x<512;x++)if(rgba[(y*512+x)*4+3]>=128){l=Math.min(l,x);t=Math.min(t,y);r=Math.max(r,x);b=Math.max(b,y);count++;}checks.push({frame:i,solidBounds:[l,t,r-l+1,b-t+1],marginClear:l>=16&&t>=16&&r<496&&b<496,solidPixels:count});
 const filename='frame-'+String(i+1).padStart(2,'0')+'.png';await fs.writeFile(folder+'/frames/'+filename,frame.toBuffer('image/png'));g.drawImage(frame,i%4*512,Math.floor(i/4)*512);
 const preview=createCanvas(512,512),pc=preview.getContext('2d');for(let y=0;y<512;y+=16)for(let x=0;x<512;x+=16){pc.fillStyle=(x/16+y/16)%2?'#233844':'#1c2c36';pc.fillRect(x,y,16,16);}pc.drawImage(frame,0,0);await fs.writeFile(folder+'/preview-frames/'+filename,preview.toBuffer('image/png'));}
 await fs.writeFile(folder+'/sheet.png',atlas.toBuffer('image/png'));const frameTime=entry.id.startsWith('run')?100:150;
 const meta={id,image:'sheet.png',size:[2048,1024],cell:[512,512],columns:4,rows:2,pivot:[256,480],headAnchor:[256,anchorY],scale,mirroredFrom,sourceVideo:entry.source+'.mp4',frames:checks.map((v,i)=>({rect:[i%4*512,Math.floor(i/4)*512,512,512],durationMs:frameTime,file:'frames/frame-'+String(i+1).padStart(2,'0')+'.png'})),review:{state:'draft-for-visual-review',notes:entry.id==='run-n'?['Reconstructed rear poses; source video turns and was rejected.']:[]}};
 if(!checks.every(x=>x.marginClear))throw Error('Frame clipping: '+id+' '+JSON.stringify(checks));await fs.writeFile(folder+'/atlas.json',JSON.stringify(meta,null,2));await fs.writeFile(folder+'/validation.json',JSON.stringify({frameCount:8,realAlpha:true,checks,mirroredFrom,ingame:false},null,2));
 execFileSync(ff,['-hide_banner','-loglevel','error','-framerate',String(1000/frameTime),'-i',folder+'/preview-frames/frame-%02d.png','-filter_complex','split[a][b];[a]palettegen[p];[b][p]paletteuse','-loop','0','-y',folder+'/loop.gif']);
 execFileSync(ff,['-hide_banner','-loglevel','error','-framerate',String(1000/frameTime),'-i',folder+'/preview-frames/frame-%02d.png','-vf','fps=24,format=yuv420p','-c:v','libx264','-crf','18','-y',folder+'/loop.mp4']);
 records.push({id,sheet:id+'/sheet.png',atlas:id+'/atlas.json',preview:id+'/loop.gif',video:id+'/loop.mp4',mirroredFrom,frameCount:8,durationMs:frameTime*8,review:'pending'});console.log(id,'packaged',mirroredFrom?'mirror '+mirroredFrom:'source');
}
for(const p of pending){const scale=p.scale;const frames=[];for(const pose of p.poses){const c=createCanvas(512,512),g=c.getContext('2d');g.imageSmoothingEnabled=true;const [x,y,w,h]=pose.crop;g.drawImage(p.image,x,y,w,h,256+(x-pose.anchor[0])*scale,p.anchorY+(y-pose.anchor[1])*scale,w*scale,h*scale);frames.push(c);}await publish(p.entry.id,frames,p.entry,scale,p.anchorY);
 if(p.entry.mirrorTo){const mirrored=frames.map(frame=>{const c=createCanvas(512,512),g=c.getContext('2d');g.translate(512,0);g.scale(-1,1);g.drawImage(frame,0,0);return c;});await publish(p.entry.mirrorTo,mirrored,p.entry,scale,p.anchorY,p.entry.id);}
}
await fs.writeFile(root+'/package.json',JSON.stringify({version:1,kind:'mounted-animation-review-pack',cell:[512,512],pivot:[256,480],normalization:'56px median hair width, common ground line, per-sequence fixed scale',frameCount:records.length*8,animations:records,sourcePolicy:'one side per pair, mirrored cell-by-cell; complete rider and mount sprites',integrated:false},null,2));
console.log('Complete pack:',records.length,'clips,',records.length*8,'frames');
