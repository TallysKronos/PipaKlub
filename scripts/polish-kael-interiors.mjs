// Only normalize generated flat-finish art. Preserve every Iso Studio box/anchor.
import fs from 'node:fs/promises';
import {sharp} from './kael-raster.mjs';
import {normalizeIsoImage} from './isometric-image-export.mjs';
const root='art/avatar/kael-v1/source',report=[];
for(const [name,pack,count,columns,ids]of [
 ['sala-flat-v2','kael-home-iso-v1',4,2,['sofa','mesa-centro','mesa-jantar','cozinha']],
 ['quarto-flat-v2','kael-bedroom-iso-v4',3,3,['cama','guarda-roupa','mesa']]
]){
 const source=`${root}/${name}.png`,{data,info}=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true}),{width:w,height:h}=info,seen=new Uint8Array(w*h),groups=[];
 for(let n=0;n<seen.length;n++){if(seen[n]||data[n*4+3]<160)continue;const queue=[n];seen[n]=1;let x0=w,x1=0,y0=h,y1=0;
  for(let j=0;j<queue.length;j++){const v=queue[j],x=v%w,y=Math.floor(v/w);x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);for(const k of [x>0?v-1:-1,x+1<w?v+1:-1,y>0?v-w:-1,y+1<h?v+w:-1])if(k>=0&&!seen[k]&&data[k*4+3]>=160){seen[k]=1;queue.push(k);}}
  if(queue.length>1000)groups.push({left:x0,top:y0,width:x1-x0+1,height:y1-y0+1,area:queue.length});
 }
 const selected=groups.sort((a,b)=>b.area-a.area).slice(0,count).sort((a,b)=>columns===2?(Math.floor((a.top+a.height/2)/(h/2))-Math.floor((b.top+b.height/2)/(h/2))||a.left-b.left):a.left-b.left);
 if(selected.length!==count)throw Error('Atlas components missing: '+name);
 const manifest=JSON.parse(await fs.readFile(`assets/world/${pack}/manifest.json`,'utf8'));
 for(const [i,id]of ids.entries()){const bounds=selected[i],cut=await sharp(source).extract({left:bounds.left,top:bounds.top,width:bounds.width,height:bounds.height}).png().toBuffer(),file=`${root}/${name}-${id}.png`;await fs.writeFile(file,cut);const old=`assets/world/${pack}/${id}.png`,m=await sharp(old).metadata();await normalizeIsoImage(file,m.width,m.height,old);report.push({id,pack,source:file,box:[m.width,m.height],anchor:manifest.pieces[id].anchor,normalization:'one uniform scale, bottom aligned; no column warping'});}
}
await normalizeIsoImage(`${root}/escada-flat-v3.png`,160,208,'assets/world/kael-home-iso-v1/escada.png');
report.push({id:'escada',pack:'kael-home-iso-v1',source:`${root}/escada-flat-v3.png`,box:[160,208],normalization:'one uniform scale; eight treads; no column warping'});
await fs.writeFile('art/avatar/kael-v1/interiores-v2.json',JSON.stringify({tool:'builtin image generation, source references from this repository',shell:'native Iso Studio geometry, flat renderer',pieces:report},null,2)+'\n');console.log('Published '+report.length+' flat-finish props without changing layout or native boxes.');
