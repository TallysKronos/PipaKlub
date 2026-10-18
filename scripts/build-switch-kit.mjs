// Mechanical atlas extraction and packaging. Painted source art stays untouched.
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
import {createHash} from 'node:crypto';
const root=fileURLToPath(new URL('../assets/ui/kit-switch-v1/',import.meta.url));
const require=createRequire(import.meta.url);
let sharp;
try { sharp=require('sharp'); }
catch { if(!process.env.PIPA_KIT_NODE_MODULES)throw Error('Install sharp or set PIPA_KIT_NODE_MODULES to its node_modules directory.'); sharp=require(path.join(process.env.PIPA_KIT_NODE_MODULES,'sharp')); }
const names=['button-primary','button-secondary','button-destructive','button-disabled','window','portrait-card','tab-selected','tab','action-paper','action-teal','speech','header','footer','resource','input','tooltip'];
const slices={
 'button-primary':[0,64,0,64], 'button-secondary':[0,64,0,64],
 'button-destructive':[0,64,0,64], 'button-disabled':[0,64,0,64],
 window:[50,50,48,50], 'portrait-card':[66,32,28,54],
 tab:[22,62,28,62],
 speech:[32,38,48,48],header:[18,42,34,62],footer:[20,62,20,62],
 resource:[22,60,22,60],input:[44,44,44,44],tooltip:[36,42,36,42],
};
const iconNames=['menu-play','menu-partners','menu-dex','menu-club','menu-school','menu-options','battle-maneuver','battle-skill','battle-dodge'];
await fs.mkdir(path.join(root,'components'),{recursive:true});
await fs.mkdir(path.join(root,'icons'),{recursive:true});
await fs.mkdir(path.join(root,'glyphs'),{recursive:true});
await fs.mkdir(path.join(root,'examples'),{recursive:true});
const manifest={version:1,name:'Papel e bambu · Switch',units:'source pixels',components:{},icons:{},glyphs:{},tokens:{paper:'#fff0cd',ink:'#213d39',teal:'#14534f',primary:'#e96723',danger:'#a73129',focus:'#ffe16a',minTarget:48}};

async function extract(image,region,id,folder,insets){
 const raw=await sharp(image).extract(region).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 let l=raw.info.width,t=raw.info.height,r=-1,b=-1;
 for(let y=0;y<raw.info.height;y++)for(let x=0;x<raw.info.width;x++){
  if(raw.data[(y*raw.info.width+x)*4+3]>8){l=Math.min(l,x);r=Math.max(r,x);t=Math.min(t,y);b=Math.max(b,y);}
 }
 if(r<l)throw Error('Empty crop: '+id);
 const bounds={left:Math.max(0,l-3),top:Math.max(0,t-3),width:0,height:0};
 bounds.width=Math.min(raw.info.width,r+4)-bounds.left;bounds.height=Math.min(raw.info.height,b+4)-bounds.top;
 const imagePath=folder+'/'+id+'.png';
 // Extract directly from original pixels: no recolouring, resize or alpha changes.
 const bytes=await sharp(image).extract({left:region.left+bounds.left,top:region.top+bounds.top,width:bounds.width,height:bounds.height}).png().toBuffer();
 await fs.writeFile(path.join(root,imagePath),bytes);
 const entry={image:imagePath,width:bounds.width,height:bounds.height,sourceRect:[region.left+bounds.left,region.top+bounds.top,bounds.width,bounds.height],sha256:createHash('sha256').update(bytes).digest('hex')};
 if(insets){
  const [top,right,bottom,left]=insets;
  if(left+right>=entry.width||top+bottom>=entry.height)throw Error('Invalid slice '+id);
  Object.assign(entry,{mode:id.startsWith('button-')?'three':'nine',insets,scale:0.5,minSize:[Math.ceil((left+right)*.5)+24,Math.ceil((top+bottom)*.5)+24]});
 }else entry.mode='whole';
 return entry;
}
const source=path.join(root,'sources/components.png'),size=await sharp(source).metadata();
for(let i=0;i<names.length;i++){
 const col=i%4,row=Math.floor(i/4),left=Math.round(col*size.width/4),top=Math.round(row*size.height/4);
 const region={left,top,width:Math.round((col+1)*size.width/4)-left,height:Math.round((row+1)*size.height/4)-top};
 manifest.components[names[i]]=await extract(source,region,names[i],'components',slices[names[i]]);
}
const iconSource=path.join(root,'sources/icons.png'),is=await sharp(iconSource).metadata();
// Source illustration has unequal visual row heights. These gutters were inspected.
const rowCuts=[0,Math.round(is.height*.395),Math.round(is.height*.704),is.height];
for(let i=0;i<iconNames.length;i++){
 const col=i%3,row=Math.floor(i/3),left=Math.round(col*is.width/3),top=rowCuts[row];
 manifest.icons[iconNames[i]]=await extract(iconSource,{left,top,width:Math.round((col+1)*is.width/3)-left,height:rowCuts[row+1]-top},iconNames[i],'icons');
}

const esc=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('"','&quot;');
const text=(s,size=23)=>`<text x="32" y="33" dominant-baseline="middle" text-anchor="middle" font-family="Arial,sans-serif" font-size="${size}" font-weight="700" fill="#fff4d4" stroke="none">${esc(s)}</text>`;
const circle='<circle cx="32" cy="32" r="26" fill="#164c48"/>';
const key='<rect x="5" y="9" width="54" height="46" rx="9" fill="#164c48"/>';
const stroked=body=>`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="none" stroke="#fff4d4" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round">${body}</svg>`;
const glyphBodies={};
for(const label of ['a','b','x','y'])glyphBodies['xbox-'+label]=circle+text(label.toUpperCase());
const shapes={cross:'<path d="m23 23 18 18m0-18L23 41"/>',circle:'<circle cx="32" cy="32" r="12"/>',square:'<rect x="21" y="21" width="22" height="22" rx="1"/>',triangle:'<path d="m32 19 14 24H18Z"/>'};
for(const [name,body] of Object.entries(shapes))glyphBodies['ps-'+name]=circle+body;
for(const [platform,labels] of Object.entries({xbox:['LB','RB','LT','RT','LS','RS'],ps:['L1','R1','L2','R2','L3','R3']}))for(const label of labels)glyphBodies[platform+'-'+label.toLowerCase()]=key+text(label,19);
glyphBodies['xbox-menu']=circle+'<path d="M22 24h20M22 32h20M22 40h20"/>';
glyphBodies['xbox-view']=circle+'<path d="M26 25V21H43V36H38M21 28h16v15H21Z"/>';
glyphBodies['ps-options']=key+'<path d="M22 24h20M22 32h20M22 40h20"/>';
glyphBodies['ps-create']=key+'<path d="M23 30h18M32 21v18M22 45h20"/>';
const keys={up:'↑',down:'↓',left:'←',right:'→',enter:'↵',escape:'Esc',space:'␣',tab:'Tab',w:'W',a:'A',s:'S',d:'D',q:'Q',e:'E',x:'X',y:'Y'};
for(const [id,label]of Object.entries(keys))glyphBodies['key-'+id]=key+text(label,label.length>1?18:25);
glyphBodies['dpad']='<path fill="#164c48" d="M24 6h16v18h18v16H40v18H24V40H6V24h18Z"/><path d="m28 17 4-4 4 4m11 11 4 4-4 4M28 47l4 4 4-4M17 28l-4 4 4 4"/>';
glyphBodies['stick']=circle+'<circle cx="32" cy="32" r="11"/><path d="M32 9v7m23 16h-7M32 55v-7M9 32h7"/>';
glyphBodies['mouse-left']='<rect x="16" y="7" width="32" height="50" rx="15" fill="#164c48"/><path fill="#f6c961" d="M32 9c-9 0-14 6-14 16v5h14Z"/><path d="M32 8v23M17 31h30"/>';
glyphBodies['mouse-right']='<rect x="16" y="7" width="32" height="50" rx="15" fill="#164c48"/><path fill="#f6c961" d="M32 9c9 0 14 6 14 16v5H32Z"/><path d="M32 8v23M17 31h30"/>';
glyphBodies['touch-tap']='<circle cx="32" cy="20" r="15"/><path fill="#164c48" d="M26 45V23a6 6 0 0 1 12 0v13l6-5a5 5 0 0 1 8 5L44 56H26L14 42a5 5 0 0 1 7-7Z"/>';
glyphBodies['touch-drag']='<path d="M8 15h48m-7-7 7 7-7 7M15 8l-7 7 7 7"/><path fill="#164c48" d="M26 48V31a6 6 0 0 1 12 0v9l6-5a5 5 0 0 1 8 5L44 59H26L14 45a5 5 0 0 1 7-7Z"/>';
glyphBodies['hold']='<circle cx="32" cy="32" r="25" fill="#164c48" stroke-dasharray="5 5"/><circle cx="32" cy="32" r="9" fill="#f6c961"/>';
glyphBodies['back']='<path d="m37 15-17 17 17 17M21 32h34"/>';
for(const [id,body]of Object.entries(glyphBodies)){
 const svg=stroked(body);await fs.writeFile(path.join(root,'glyphs',id+'.svg'),svg);
 manifest.glyphs[id]={image:'glyphs/'+id+'.svg',viewBox:[0,0,64,64]};
}
await fs.writeFile(path.join(root,'glyphs.svg'),'<svg xmlns="http://www.w3.org/2000/svg">'+Object.entries(glyphBodies).map(([id,body])=>`<symbol id="${id}" viewBox="0 0 64 64" fill="none" stroke="#fff4d4" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round">${body}</symbol>`).join('')+'</svg>');

const badges={locked:'<rect x="17" y="28" width="30" height="27" rx="4" fill="#164c48"/><path d="M23 28V18a9 9 0 0 1 18 0v10M32 39v6"/>',equipped:'<circle cx="32" cy="32" r="25" fill="#164c48"/><path d="m19 32 9 9 18-20"/>',event:'<path fill="#c14e22" d="m32 5 8 17 19 3-14 14 3 19-16-9-17 9 4-19L5 25l19-3Z"/>',critical:'<path fill="#c14e22" d="m37 5-24 31h17l-4 23 25-33H34Z"/>'};
for(const [id,body]of Object.entries(badges)){await fs.writeFile(path.join(root,'icons','badge-'+id+'.svg'),stroked(body));manifest.icons['badge-'+id]={image:'icons/badge-'+id+'.svg',mode:'whole',width:64,height:64};}
const assets=fileURLToPath(new URL('../assets/',import.meta.url));
await fs.copyFile(path.join(assets,'backgrounds/quintal-clube-v1.png'),path.join(root,'examples/quintal.png'));
const dex=JSON.parse(await fs.readFile(path.join(assets,'pipa-dex.json'),'utf8')).entries;
const atlases=JSON.parse(await fs.readFile(path.join(assets,'atlas.json'),'utf8')).atlases;
const portraits=JSON.parse(await fs.readFile(path.join(assets,'portraits.json'),'utf8'));
manifest.examples=[];
for(const id of ['carcara','mata-verde','nevagume','yaguaru-memoria']){
 const entry=dex.find(e=>e.id===id),atlas=atlases[entry.atlas],frame=atlas.frames[atlas.animations.idle[0]].frame,[x,y,size]=portraits[id].crop;
 await sharp(path.join(assets,atlas.meta.image)).extract({left:frame.x+x,top:frame.y+y,width:size,height:size}).png().toFile(path.join(root,'examples',id+'.png'));
 manifest.examples.push({id,name:entry.name,image:'examples/'+id+'.png',reusedFrom:atlas.meta.image,sourceRect:[frame.x+x,frame.y+y,size,size]});
}
await fs.writeFile(path.join(root,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
const skins=Object.entries(manifest.components).map(([id,c])=>{
 if(c.mode==='whole')return `.pk-skin[data-skin="${id}"]{border:0;background:url("${c.image}") center/100% 100% no-repeat}`;
 return `.pk-skin[data-skin="${id}"]{border-width:${c.insets.map(n=>n*c.scale+'px').join(' ')};border-image-source:url("${c.image}");border-image-slice:${c.insets.join(' ')} fill;border-image-repeat:stretch}`;
}).join('\n');
await fs.writeFile(path.join(root,'skins.css'),`/* Generated from manifest. Insets are source pixels, border widths are fixed CSS pixels. */\n.pk-skin{position:absolute;inset:0;display:block;pointer-events:none;border-style:solid;border-color:transparent;box-sizing:border-box}\n${skins}\n`);
console.log(JSON.stringify({components:Object.keys(manifest.components).length,paintedIcons:iconNames.length,glyphs:Object.keys(manifest.glyphs).length,badges:Object.keys(badges).length,output:root,dimensions:Object.fromEntries(Object.entries(manifest.components).map(([id,c])=>[id,[c.width,c.height]]))},null,2));
