// Mechanical atlas slicing only; the illustrations are generated source artwork.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
const sharp=require(process.env.PIPA_KIT_NODE_MODULES?path.join(process.env.PIPA_KIT_NODE_MODULES,'sharp'):'sharp');
const root='assets/hub/praca-v1';
async function cells(file,cols,rows){
 const {data,info}=await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 return Array.from({length:cols*rows},(_,i)=>{
  const x=Math.round((i%cols)*info.width/cols),y=Math.round(Math.floor(i/cols)*info.height/rows),w=Math.round((i%cols+1)*info.width/cols)-x,h=Math.round((Math.floor(i/cols)+1)*info.height/rows)-y;
  let left=w,top=h,right=0,bottom=0;
  for(let cy=0;cy<h;cy++)for(let cx=0;cx<w;cx++)if(data[((y+cy)*info.width+x+cx)*4+3]>32){left=Math.min(left,cx);right=Math.max(right,cx);top=Math.min(top,cy);bottom=Math.max(bottom,cy);}
  return {x,y,w,h,bounds:{x:left,y:top,w:right-left+1,h:bottom-top+1}};
 });
}
const frames=await cells(root+'/sources/kael.png',4,2);
await fs.copyFile(root+'/sources/kael.png',root+'/kael.png');
const f=frames[0],b=f.bounds,side=Math.min(f.w,Math.round(b.w*1.12));
await sharp(root+'/kael.png').extract({left:Math.max(0,Math.round(f.x+b.x-(side-b.w)/2)),top:f.y+b.y,width:side,height:side}).resize(256,256).png().toFile(root+'/avatar.png');
const names=['backpack','partners','map','missions','settings','chat'],icons={};
for(const [i,c]of (await cells(root+'/sources/icons.png',3,2)).entries()){
 const p=c.bounds,pad=12,left=Math.max(c.x,c.x+p.x-pad),top=Math.max(c.y,c.y+p.y-pad),width=Math.min(c.w,c.x+p.x+p.w+pad-left),height=Math.min(c.h,c.y+p.y+p.h+pad-top);
 const file='icon-'+names[i]+'.png';await sharp(root+'/sources/icons.png').extract({left,top,width,height}).resize(192,192,{fit:'contain',background:'#00000000'}).png().toFile(root+'/'+file);icons[names[i]]=file;
}
const manifest={version:1,width:1536,height:1024,files:['plaza.png','kael.png','avatar.png',...Object.values(icons)],icons,actor:{image:'kael.png',directions:['south','west','east','north'],frames}};
await fs.writeFile(root+'/manifest.json',JSON.stringify(manifest,null,2)+'\n');
console.log('Praça: 8 actor frames, avatar, 6 icons and scenery packaged.');
