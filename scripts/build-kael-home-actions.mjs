import fs from 'node:fs/promises';
import {read,png,cell,fitted,publish} from './extend-kael-avatar.mjs';
import {ACTIONS,actionDirs,blank,metrics,over,hexToInt,SLOTS,colorDistance,steadyTorso,translate} from '../tools/avatar-studio/model.mjs';
const art='art/avatar/kael-v1',p=JSON.parse(await fs.readFile(`${art}/kael.avatarstudio.json`,'utf8'));
// Drop disconnected specks in the generated margins, never erase connected limbs.
function silhouette(img){const seen=new Uint8Array(img.width*img.height),groups=[];for(let n=0;n<seen.length;n++){if(seen[n]||img.data[n*4+3]<160)continue;const q=[n];seen[n]=1;for(let j=0;j<q.length;j++){const v=q[j],x=v%img.width,y=Math.floor(v/img.width);for(const k of [x>0?v-1:-1,x+1<img.width?v+1:-1,y>0?v-img.width:-1,y+1<img.height?v+img.width:-1])if(k>=0&&!seen[k]&&img.data[k*4+3]>=160){seen[k]=1;q.push(k);}}groups.push(q);}groups.sort((a,b)=>b.length-a.length);const out=blank(img.width,img.height);for(const n of groups[0]||[])out.data.set([...img.data.subarray(n*4,n*4+3),255],n*4);return out;}
const tones=id=>SLOTS.find(s=>s.id===id).tones.map(hexToInt);
function palette(img){const out=blank(img.width,img.height),b=metrics(img).bounds;for(let y=0;y<img.height;y++)for(let x=0;x<img.width;x++){const i=(y*img.width+x)*4;if(img.data[i+3]<160)continue;const [r,g,blue]=img.data.subarray(i,i+3),c=r<<16|g<<8|blue,t=(y-b.y)/b.h;let ids;
 if(Math.max(r,g,blue)<35)ids=['contorno'];else if(r>g&&g>blue&&r-blue>12)ids=t>.88?['detalhe']:['pele'];else if(t<.48)ids=['olhos','contorno'];else if(t>.86)ids=['tenis','contorno'];else if(t>.7)ids=['calca','contorno'];else if(blue>r*1.6&&blue>g*1.35)ids=['jaqueta','contorno'];else ids=['camiseta','jaqueta','contorno'];
 let pick=0,best=Infinity;for(const id of ids)for(const n of tones(id)){const d=colorDistance(c,n);if(d<best){best=d;pick=n;}}out.data.set([pick>>16,pick>>8&255,pick&255,255],i);}return out;}
const jobs=!process.argv.includes('--legacy-source')?[['andar-se-v5','se',8],['andar-ne-v5','ne',8],['sentar-se-v2','se',6],['sentar-ne-v2','ne',6]]:[['subir-ne','ne',8],['descer-se','se',8],['sentar-se','se',6],['sentar-ne','ne',6]];
for(const [file,dir,total] of jobs){
 const inputs=await Promise.all(Array.from({length:total},(_,i)=>cell(`${art}/source/${file}.png`,4,2,i).then(silhouette))),scale=174/metrics(inputs[0]).bounds.h,frames=[];
 for(const input of inputs){const b=metrics(input).bounds,img=palette(await fitted(input,Math.round(b.w*scale),Math.round(b.h*scale))),out=blank(256,256);over(out,img,Math.round(128-img.width/2),224-img.height);
  const bounds=metrics(out).bounds;let x0=256,x1=0;for(let y=bounds.y;y<bounds.y+Math.min(50,bounds.h*.3);y++)for(let x=0;x<256;x++)if(out.data[(y*256+x)*4+3]){x0=Math.min(x0,x);x1=Math.max(x1,x);}const head=[Math.round((x0+x1)/4)*2,Math.round((bounds.y+42)/2)*2];frames.push({image:translate(out,128-head[0],0),head:[128,head[1]]});
 }
 const torsos=steadyTorso(frames);for(let i=0;i<frames.length;i++){frames[i].torso=[torsos[i][0],torsos[i][1]-2];frames[i].src='data:image/png;base64,'+(await png(frames[i].image)).toString('base64');delete frames[i].image;}
 const id=file.startsWith('sentar')?'sentar':file.split('-')[0];p.actions[id]??={ms:ACTIONS[id].ms,loop:ACTIONS[id].loop,dirs:actionDirs(id)};p.actions[id].loop=ACTIONS[id].loop;p.actions[id].dirs[dir]={frames:id==='sentar'?[frames[0],frames[1],frames[2],frames[4]]:frames};
 if(id==='sentar'){p.actions.sentado??={ms:ACTIONS.sentado.ms,loop:true,dirs:actionDirs('sentado')};p.actions.sentado.dirs[dir]={frames:[structuredClone(frames[4]),frames[5]]};}
}
await publish(p);console.log('Published 28 action drawings; sit-down and seated share the contact pose.');
