// Mechanical metadata extraction only; never paints or removes backgrounds.
import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url),sharp=require(process.env.PIPA_KIT_NODE_MODULES?path.join(process.env.PIPA_KIT_NODE_MODULES,'sharp'):'sharp');
const root='assets/story/kael-birthday-v1';
if(!fs.existsSync(root+'/rabbito-source.png'))fs.copyFileSync(root+'/rabbito.png',root+'/rabbito-source.png');
// The generated source is 1774×887, with one ear crossing the nominal row.
// Authored source rectangles exclude neighbouring poses, then receive padding
// in a uniform grid. No colour, alpha or silhouette is painted/removed.
const regions=[[0,0,444,430],[444,0,443,430],[887,0,430,420],[1317,0,457,420],[0,444,444,443],[444,444,443,443],[887,444,444,443],[1331,430,443,457]];
const tiles=[];for(const [i,[left,top,width,height]] of regions.entries())tiles.push({input:await sharp(root+'/rabbito-source.png').extract({left,top,width,height}).png().toBuffer(),left:i%4*512+Math.floor((512-width)/2),top:Math.floor(i/4)*512+12});
await sharp({create:{width:2048,height:1024,channels:4,background:'#00000000'}}).composite(tiles).png().toFile(root+'/rabbito.png');
async function measure(file,cols,rows){
 const {data,info}=await sharp(root+'/'+file).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const frames=Array.from({length:cols*rows},(_,i)=>{const x=Math.round(i%cols*info.width/cols),y=Math.round(Math.floor(i/cols)*info.height/rows),w=Math.round((i%cols+1)*info.width/cols)-x,h=Math.round((Math.floor(i/cols)+1)*info.height/rows)-y;let left=w,top=h,right=-1,bottom=-1;for(let cy=0;cy<h;cy++)for(let cx=0;cx<w;cx++)if(data[((y+cy)*info.width+x+cx)*4+3]>32){left=Math.min(left,cx);top=Math.min(top,cy);right=Math.max(right,cx);bottom=Math.max(bottom,cy);}if(right<left)throw Error('Empty cell '+file+' '+i);return {x,y,w,h,bounds:{x:left,y:top,w:right-left+1,h:bottom-top+1}};});
 return {width:info.width,height:info.height,frames};
}
const mother=await measure('mother-overworld-v2.png',4,2),rabbit=await measure('rabbito.png',4,2);
const actors={mother,rabbito:rabbit},images={};
for(const file of ['bedroom','downstairs','mother','rabbito','tail']){const m=await sharp(root+'/'+file+'.png').metadata();images[file]={image:'story/kael-birthday-v1/'+file+'.png',width:m.width,height:m.height,alpha:!!m.hasAlpha};}
images.mother={...images.mother,image:'story/kael-birthday-v1/mother-overworld-v2.png',width:mother.width,height:mother.height,alpha:true};
const projectMetadata=await sharp(root+'/rabbito-project-clean-v2.png').metadata();
if(projectMetadata.width!==1536||projectMetadata.height!==1024||!projectMetadata.hasAlpha)throw Error('Projeto Rabbito: os recortes da bancada exigem PNG RGBA 1536×1024.');
images.project={image:'story/kael-birthday-v1/rabbito-project-clean-v2.png',width:projectMetadata.width,height:projectMetadata.height,alpha:!!projectMetadata.hasAlpha};
images.kael={image:'hub/praca-v1/kael.png'};
const rooms={bedroom:{image:'bedroom',width:1536,height:1024,entry:[760,800],floor:[450,460,850,330],tv:[473,178,88,59],desk:[1010,560],exit:{target:'downstairs',x:760,y:800}},downstairs:{image:'downstairs',width:1536,height:1024,entry:[1220,630],floor:[520,460,680,240],exit:{target:'quintal',x:760,y:700},stairs:{target:'bedroom',x:1220,y:630}}};
rooms.bedroom.blocking={kaelTV:[540,570],kaelDesk:[1050,510],motherEntry:[780,855],mother:[900,640],rabbito:[1145,640]};
rooms.bedroom.blocked=[[1080,390,110,150]];
rooms.bedroom.walkable=[[450,460,850,330],[670,780,200,130]];
rooms.downstairs.blocking={kael:[860,650],mother:[660,640],rabbito:[1000,650]};
rooms.downstairs.walkable=[[520,460,680,240],[670,650,220,230]];
fs.writeFileSync(root+'/manifest.json',JSON.stringify({version:1,images,actors,rooms},null,2)+'\n');
const atlas=JSON.parse(fs.readFileSync('assets/atlas.json','utf8'));
const animations={idle:['0','1'],flight:['2','3'],skill:['4','5'],hurt:['6'],victory:['7']};
atlas.atlases.rabbito={frames:Object.fromEntries(rabbit.frames.map((f,i)=>[String(i),{frame:{x:f.x,y:f.y,w:f.w,h:f.h},contentBounds:f.bounds,rotated:false,trimmed:false,spriteSourceSize:{x:0,y:0,w:f.w,h:f.h},sourceSize:{w:f.w,h:f.h}}])),meta:{image:images.rabbito.image,size:{w:rabbit.width,h:rabbit.height},scale:'1',viewport:{x:0,y:0,w:rabbit.frames[0].w,h:rabbit.frames[0].h}},animations,playback:Object.fromEntries(Object.entries(animations).map(([id,seq])=>[id,{durations:seq.map(()=>id==='idle'?280:id==='flight'?160:220),loop:['idle','flight','victory'].includes(id),returnTo:['skill','hurt'].includes(id)?'idle':null}]))};
fs.writeFileSync('assets/atlas.json',JSON.stringify(atlas,null,2)+'\n');
const portraits=JSON.parse(fs.readFileSync('assets/portraits.json','utf8'));portraits.rabbito={frame:'0',crop:[215,155,170]};fs.writeFileSync('assets/portraits.json',JSON.stringify(portraits,null,2)+'\n');
const dex=JSON.parse(fs.readFileSync('assets/pipa-dex.json','utf8'));
if(!dex.entries.some(e=>e.id==='rabbito')){
 const entry={id:'rabbito',model:'rabbito',name:'Rabbito',title:'Um fio de sorte',color:0,group:'story',collection:'Parceiro da história',rarity:'especial',atlas:'rabbito',habitat:'A casa de Kael',story:['Desenhado por Kael, Rabbito ganhou vida quando recebeu a Rabiola Antiga que sua mãe guardava desde criança.'],note:'Um parceiro inventado. Uma rabiola cheia de lembranças.',obtain:'Nasce na abertura da história. Vinculado à sua conta.',items:[]};
 const raw=fs.readFileSync('assets/pipa-dex.json','utf8'),end=raw.lastIndexOf(']');
 fs.writeFileSync('assets/pipa-dex.json',raw.slice(0,end).trimEnd()+',\n'+JSON.stringify(entry,null,1).split('\n').map(line=>'  '+line).join('\n')+'\n '+raw.slice(end));
}
console.log(JSON.stringify({images,actors},null,2));
