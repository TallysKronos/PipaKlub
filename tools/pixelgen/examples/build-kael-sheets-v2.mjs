// Separate, compatible sheets: native indexed pixels, shared head, rig and palette.
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {validateProject,serialize,audit} from '../core.mjs';
import {apply} from '../draw.mjs';
import {compositeAll} from '../document.mjs';
import {atlas,playbackOrder} from '../animation.mjs';
import {aseprite} from '../aseprite.mjs';
import {encodePNG} from '../png.mjs';
import {encodeGIF} from '../gif.mjs';
import {Canvas,frameRGBA,renderSheet,renderGrounds,renderBoard,gifFrames} from '../render.mjs';
import {check} from '../cli.mjs';

const ROOT=fileURLToPath(new URL('../../../',import.meta.url));
const OUT=path.join(ROOT,'art/characters/kael-compatible-sheets-v2');
fs.mkdirSync(OUT,{recursive:true});
const W=48,H=64,BASE=61;
const hex=['#111a2e','#17233f','#283f71','#455f98','#ba795e','#f2bc8e','#ffe1b3','#183755','#2c548b','#4776b2','#202936','#4b566c','#eee9d6','#40b7c7','#9be1db','#303c51'];
const palette=[[0,0,0,0],...hex.map(h=>[1,3,5].map(i=>parseInt(h.slice(i,i+2),16)).concat(255))];
const layers=['Braço de trás','Perna de trás','Perna da frente','Tronco','Braço da frente','Cabeça','Acessórios'];
const ramps={tinta:[1],cabelo:[2,3,4],pele:[5,6,7],roupa:[8,9,10],camiseta:[11],calca:[16,12],tenis:[2,13],fones:[14,15]};
const source=validateProject(JSON.parse(fs.readFileSync(path.join(ROOT,'art/characters/rpg-overworld-study-v1/pixelgen-native-v1/kael-professor.pixelgen.json'))));
const dirs=['S','SO','O','NO','N','NE','E','SE'];
const facing={S:[0,1],SO:[-.7,.7],O:[-1,0],NO:[-.7,-.7],N:[0,-1],NE:[.7,-.7],E:[1,0],SE:[.7,.7]};
const nearest=c=>{let at=1,d=Infinity;for(let i=1;i<palette.length;i++){const e=c.slice(0,3).reduce((s,v,k)=>s+(v-palette[i][k])**2,0);if(e<d){d=e;at=i;}}return at;};
const colorMap=source.palette.map(nearest);colorMap[0]=0;
const blank=()=>new Uint8Array(W*H);
function put(c,x,y,v){x=Math.round(x);y=Math.round(y);if(x>=0&&x<W&&y>=0&&y<H)c[y*W+x]=v;}
function line(c,a,b,v,w=1){let [x,y]=a.map(Math.round),[tx,ty]=b.map(Math.round),dx=Math.abs(tx-x),sx=x<tx?1:-1,dy=-Math.abs(ty-y),sy=y<ty?1:-1,err=dx+dy;for(;;){for(let yy=-Math.floor(w/2);yy<Math.ceil(w/2);yy++)for(let xx=-Math.floor(w/2);xx<Math.ceil(w/2);xx++)put(c,x+xx,y+yy,v);if(x===tx&&y===ty)break;let e=err*2;if(e>=dy){err+=dy;x+=sx;}if(e<=dx){err+=dx;y+=sy;}}}
function poly(c,p,v){for(let y=0;y<H;y++)for(let x=0;x<W;x++){let inside=false;for(let i=0,j=p.length-1;i<p.length;j=i++){let [a,b]=p[i],[d,e]=p[j];if((b>y+.5)!==(e>y+.5)&&x+.5<(d-a)*(y+.5-b)/(e-b)+a)inside=!inside;}if(inside)put(c,x,y,v);}}
function head(dir,dx=0,dy=0,expression='normal'){
 const cardinal=dir==='S'||dir==='SE'||dir==='SO'?0:dir==='E'?2:dir==='O'?1:3,c=blank();
 for(let y=0;y<31;y++)for(let x=0;x<W;x++){const v=source.frames[cardinal].indices[y*W+x];if(v)put(c,x+dx,y+dy,colorMap[v]);}
 // Diagonal face uses the same asymmetric hair master, with a turned cheek and eyes.
 if(dir==='SE'||dir==='SO'){
  const sign=dir==='SE'?1:-1,face=dir==='SE'?[[16,23],[32,23],[32,27],[28,30],[20,29],[16,27]]:[[16,23],[32,23],[32,27],[28,29],[20,30],[16,27]];
  poly(c,face.map(([x,y])=>[x+dx,y+dy]),6);
  for(const [x,y] of [[sign>0?21:27,24],[sign>0?21:27,25],[sign>0?29:18,24],[sign>0?29:18,25],[25+sign*2,28]])put(c,x+dx,y+dy,1);
 }
 if(dir==='NE'||dir==='NO'){
  const x=dir==='NE'?34:13;line(c,[x+dx,24+dy],[x+dx,27+dy],6,2);
 }
 if(expression!=='normal'&&!dir.includes('N')){
  const xs=dir==='E'?[31]:dir==='O'?[16]:dir==='SE'?[21,29]:dir==='SO'?[18,27]:[20,28];
  for(const x of xs){for(let y=23;y<=26;y++)for(let xx=x-1;xx<=x+1;xx++)put(c,xx+dx,y+dy,6);
   line(c,[x-1+dx,expression==='happy'?24+dy:25+dy],[x+1+dx,expression==='happy'?24+dy:25+dy],1);
   if(expression==='happy')put(c,x+dx,23+dy,1);
  }
  line(c,[23+dx,28+dy],[25+dx,28+dy],expression==='happy'?5:1);
 }
 return c;
}
const keys={
 idle:[{ms:700},{ms:350,breath:-1}],
 walk:[{ms:140,step:1},{ms:110,step:0,bob:-1,pass:1},{ms:140,step:-1},{ms:110,step:0,bob:-1,pass:-1}],
 run:[{ms:90,step:1.2,run:1},{ms:70,step:.5,run:1,lift:2},{ms:100,step:0,run:1,lift:4,pass:1,bob:-1},{ms:90,step:-1.2,run:1},{ms:70,step:-.5,run:1,lift:2},{ms:100,step:0,run:1,lift:4,pass:-1,bob:-1}],
 interact:[{ms:140,reach:0},{ms:130,reach:.4,crouch:1},{ms:300,reach:1,crouch:2},{ms:200,reach:.2}],
 attack:[{ms:160,command:-.4},{ms:140,command:-1},{ms:65,command:1},{ms:130,command:1},{ms:150,command:.4},{ms:230}],
 hurt:[{ms:90,hurt:1},{ms:280,hurt:.4}],
 victory:[{ms:150,cheer:.3},{ms:230,cheer:1,bob:-1},{ms:140,cheer:.7},{ms:500,cheer:1}],
 defeat:[{ms:150,hurt:1},{ms:180,crouch:3,hurt:.5},{ms:240,crouch:7,down:1},{ms:900,crouch:8,down:1}],
 swim:[{ms:180,swim:1,step:1},{ms:140,swim:1,step:0},{ms:180,swim:1,step:-1},{ms:140,swim:1,step:0,pass:1}],
 climb:[{ms:160,climb:1,step:1},{ms:130,climb:1,step:0},{ms:160,climb:1,step:-1},{ms:130,climb:1,step:0,pass:1}]
};
function pose(dir,k){
 const [dx,dy]=facing[dir],side=Math.abs(dx),back=dy<0,crouch=k.crouch||0,lift=k.lift||0;
 const bob=(k.bob||0)+crouch-(k.swim?-8:0),lean=k.run?Math.round(dx*2):k.hurt?Math.round(-dx*2):0;
 const cx=24+lean,sy=34+bob+(k.breath||0),hy=48+bob,step=k.step||0;
 const c=Array.from({length:8},blank),[far,lb,lf,torso,near,face,access]=c;
 const shoulderSpread=side>.9?2:side>.2?6:9;
 const shoulders=[[cx-shoulderSpread,sy],[cx+shoulderSpread,sy]];
 const feet=[];const hands=[];
 for(let i=0;i<2;i++){
  const s=i===0?-1:1,leg=i===0?lb:lf,advance=step*s;
  let foot=[24-dy*s*4+dx*advance*6,BASE-lift-(advance<0?Math.abs(advance)*2:0)-(k.pass===s?3:0)];
  let hip=[cx-dy*s*3,hy],knee=[(hip[0]+foot[0])*.5-dx*Math.abs(advance)*2,54+bob*.3-Math.abs(advance)*2];
  if(k.down){foot=[24+s*7,BASE];knee=[24+s*6,58];hip=[24+s*3,hy];}
  if(k.climb){foot=[24+s*5,BASE-(s*step>0?6:0)];knee=[24+s*7,53-(s*step>0?4:0)];}
  line(leg,hip,knee,1,6);line(leg,knee,[foot[0],foot[1]-2],1,5);
  line(leg,hip,knee,i?12:16,4);line(leg,knee,[foot[0],foot[1]-2],i?12:16,3);
  line(leg,[foot[0]-2,foot[1]-2],[foot[0]+2+(dx>.9?1:0),foot[1]-2],2,4);
  line(leg,[foot[0]-2,foot[1]],[foot[0]+2+(dx>.9?1:0),foot[1]],13,1);feet.push(foot);
 }
 const bw=side>.9?5:side>.2?7:9;
 poly(torso,[[cx-bw,sy],[cx+bw,sy],[cx+bw-1,hy],[cx+5,hy+1],[cx-5,hy+1],[cx-bw+1,hy-1]],back?9:11);
 if(!back){poly(torso,[[cx-bw,sy],[cx-3,sy],[cx-4,hy],[cx-bw+1,hy]],9);poly(torso,[[cx+3,sy],[cx+bw,sy],[cx+bw-1,hy],[cx+4,hy]],8);
  line(torso,[cx-bw+1,sy+1],[cx-5,hy-1],13);line(torso,[cx+bw-1,sy+1],[cx+5,hy-1],13);
 }
 line(torso,[cx-4,sy-1],[cx+4,sy-1],2,2);
 // Turquoise headphones remain attached to the neck; plain nape when facing away.
 if(!back){line(torso,[cx-5,sy-1],[cx-5,sy+2],14,3);line(torso,[cx+5,sy-1],[cx+5,sy+2],14,3);put(torso,cx-5,sy-1,15);put(torso,cx+5,sy-1,15);}
 else{line(torso,[cx-4,sy],[cx+4,sy],8,2);}
 if(!k.swim&&!k.down){for(const s of [-1,1]){const a=[cx+s*(bw-2),hy-2],b=[cx+s*(bw-2)-dx*3+(k.pass||0),Math.min(58,hy+7)];line(torso,a,b,13,2);}}
 for(let i=0;i<2;i++){
  const s=i===0?-1:1,sh=shoulders[i],arm=i===0?far:near;
  let hand=[sh[0]-dx*step*s*4,sy+11-dy*step*s*2],elbow=[sh[0]-dx*step*s*2,sy+6];
  if(k.run){elbow=[sh[0]-dx*step*s*4,sy+5];hand=[elbow[0]+dx*4,sy+2-dy*step*s*2];}
  if(k.reach&&i===1){hand=[sh[0]+dx*k.reach*9,sy+6+dy*k.reach*7];elbow=[sh[0]+dx*3,sy+5];}
  if(k.command&&i===1){hand=[sh[0]+dx*k.command*11,sy+2+dy*k.command*7];elbow=[sh[0]+dx*k.command*5,sy+5];}
  if(k.cheer&&i===1){hand=[sh[0]+s*3,sy-17*k.cheer];elbow=[sh[0]+s*6,sy-7*k.cheer];}
  if(k.hurt){hand=[cx+s*3,sy+5];elbow=[sh[0]+s*3,sy+5];}
  if(k.down){hand=[cx+s*7,BASE-4];elbow=[sh[0]+s*2,sy+5];}
  if(k.swim){hand=[cx+s*(9+step*s*4),43];elbow=[sh[0]+s*3,40];}
  if(k.climb){hand=[24+s*8,25-s*step*4];elbow=[24+s*12,32-s*step*3];}
  const dst=(hand[1]<29&&i===1)?access:arm;
  line(dst,sh,elbow,1,5);line(dst,elbow,hand,1,5);
  line(dst,sh,elbow,i?9:8,3);line(dst,elbow,hand,i?9:8,3);
  line(dst,[sh[0]-1,sh[1]+1],[elbow[0]-1,elbow[1]],13,1);
  line(dst,[elbow[0]-1,elbow[1]],[hand[0]-1,hand[1]-1],13,1);
  line(dst,hand,hand,i?6:5,3);hands.push(hand);
 }
 const hd=k.swim?8:(k.down?crouch:Math.min(5,crouch*.4))+(k.bob||0);
 face.set(head(dir,lean,hd,k.cheer?'happy':k.hurt||k.down?'hurt':'normal'));
 if(k.swim)for(const cel of c)for(let y=43;y<H;y++)cel.fill(0,y*W,(y+1)*W);
 const pose={topo:[24+lean,5+hd],queixo:[24+lean,30+hd],ombroTras:shoulders[0],ombroFrente:shoulders[1],maoTras:hands[0],maoFrente:hands[1],quadril:[cx,hy],peTras:feet[0],peFrente:feet[1]};
 for(const pt of Object.values(pose)){pt[0]=Math.max(0,Math.min(47,Math.round(pt[0])));pt[1]=Math.max(0,Math.min(63,Math.round(pt[1])));}
 return {cels:c.slice(0,7),pose};
}
const manifest={schema:'kael-compatible-sheets-2',cell:[W,H],pivot:[24,62],directions:dirs,palette,columns:8,rowsPerSheet:8,sheets:[],status:'native-verified-awaiting-user-art-review'};
const masterFrames=[],masterSequences=[];const proofs=[];
const png=(name,cv)=>fs.writeFileSync(path.join(OUT,name),encodePNG(cv.data,cv.w,cv.h));
for(const [motion,cycle] of Object.entries(keys)){
 const available=motion==='climb'?['N']:dirs;
 const frames=[],sequences=[];
 for(const dir of available){const start=frames.length;cycle.forEach((k,i)=>{const f=pose(dir,k);frames.push({name:`${motion}-${dir}-${i+1}`,duration:k.ms,indices:Array.from(blank()),cels:f.cels.map(c=>Array.from(c)),pose:f.pose});});sequences.push({name:`${motion}-${dir}`,start,end:frames.length-1,loop:['idle','walk','run','swim','climb'].includes(motion),direction:'forward'});}
 if(motion==='climb')sequences.push({name:'climbdown-N',start:0,end:3,loop:true,direction:'reverse'});
 const cols=cycle.length,rows=available.length;
 const sheetSpec={nome:'Kael',cores:16,cabecas:2.4,base:62,rampas:Object.keys(ramps),referencia:frames[0].name,notas:'Cabeça canônica assimétrica, casaco azul/branco, fones turquesa, calça comprida. Quadros 48x64; pivô 24,62; ajoelhamento acompanha cabeça e tronco.'};
 const p=validateProject({kind:'pixelgen',version:2,name:`Kael · ${motion}`,width:W,height:H,cols,rows,palette,layers:layers.map(name=>({name})),ramps,sheet:sheetSpec,frames,sequences,settings:{margin:2}});
 apply(p,[{op:'outline',color:'tinta:0',frame:'all'}]);compositeAll(p);
 // The Pixelgen/Aseprite source is compact. Runtime PNGs reserve 8 columns in each direction row.
 fs.writeFileSync(path.join(OUT,`kael-${motion}.pixelgen.json`),JSON.stringify(serialize(p)));
 fs.writeFileSync(path.join(OUT,`kael-${motion}.aseprite`),aseprite(p));
 const sheet=new Canvas(384,512,[0,0,0,0]),meta=atlas(p,`kael-${motion}.png`),sheetY=manifest.sheets.length*512;
 meta.meta.size={w:384,h:512};
 for(let i=0;i<p.frames.length;i++){
  const row=motion==='climb'?dirs.indexOf('N'):Math.floor(i/cols),col=i%cols;
  sheet.blit(frameRGBA(p,i),W,H,col*W,row*H);
  meta.frames[i].frame={x:col*W,y:row*H,w:W,h:H};
 }
 png(`kael-${motion}.png`,sheet);
 fs.writeFileSync(path.join(OUT,`kael-${motion}.atlas.json`),JSON.stringify(meta,null,2));
 png(`review-${motion}.png`,renderBoard(p,p.sequences.filter(s=>s.direction!=='reverse').map(s=>s.name),{zoom:3}));
 const gif=gifFrames(p,playbackOrder(p.sequences.find(s=>s.name===`${motion}-${motion==='climb'?'N':'SE'}`)),{zoom:5});
 fs.writeFileSync(path.join(OUT,`preview-${motion}.gif`),encodeGIF(gif.frames,gif.width,gif.height,gif.palette));
 if(motion==='idle'){png('review-directions.png',renderSheet(p,dirs.map((_,i)=>i*cols),{zoom:4,cols:8}));png('review-grounds.png',renderGrounds(p,0));png('review-silhouettes.png',renderSheet(p,dirs.map((_,i)=>i*cols),{zoom:4,cols:8,silhouette:true}));}
 const offset=masterFrames.length;
 meta.frames.forEach((f,i)=>masterFrames.push({...f,frame:{...f.frame,y:f.frame.y+sheetY},sheet:meta.meta.image,localFrame:i}));
 sequences.forEach(s=>masterSequences.push({...s,start:s.start+offset,end:s.end+offset}));
 const r=check(p);proofs.push({motion,...audit(p),delivery:r});
 manifest.sheets.push({motion,image:meta.meta.image,source:`kael-${motion}.pixelgen.json`,aseprite:`kael-${motion}.aseprite`,rect:[0,sheetY,384,512],frames:p.frames.length,framesPerDirection:cols,sequences:sequences.map(s=>s.name)});
}
// Assemble the PNG from the exact indexed frames; no resize, trimming or palette remap.
const master=new Canvas(384,manifest.sheets.length*512,[0,0,0,0]);
for(const f of masterFrames){const sheet=manifest.sheets.find(s=>s.image===f.sheet);const p=validateProject(JSON.parse(fs.readFileSync(path.join(OUT,sheet.source))));master.blit(frameRGBA(p,f.localFrame),W,H,f.frame.x,f.frame.y);}
png('kael-completo.png',master);
fs.writeFileSync(path.join(OUT,'kael-completo.atlas.json'),JSON.stringify({meta:{image:'kael-completo.png',size:{w:384,h:master.h}},cell:[W,H],pivot:[24,62],palette,sequences:masterSequences,frames:masterFrames},null,2));
const lines=[`[gd_resource type="SpriteFrames" load_steps=${masterFrames.length+2} format=3]`,'','[ext_resource type="Texture2D" path="res://assets/characters/kael-compatible-sheets-v2/kael-completo.png" id="1"]',''];
masterFrames.forEach((f,i)=>lines.push(`[sub_resource type="AtlasTexture" id="F${i}"]`,'atlas = ExtResource("1")',`region = Rect2(${f.frame.x}, ${f.frame.y}, 48, 64)`));
lines.push('[resource]','animations = ['+masterSequences.map(s=>`{"name": &${JSON.stringify(s.name)}, "loop": ${s.loop}, "speed": 1.0, "frames": [`+playbackOrder(s).map(i=>`{"duration": ${masterFrames[i].duration/1000}, "texture": SubResource("F${i}")}`).join(',')+']}').join(',\n')+']');
fs.writeFileSync(path.join(OUT,'kael-completo.tres'),lines.join('\n'));
manifest.master={image:'kael-completo.png',atlas:'kael-completo.atlas.json',spriteFrames:'kael-completo.tres',frames:masterFrames.length,sequences:masterSequences.length,size:[384,master.h]};
fs.writeFileSync(path.join(OUT,'manifest.json'),JSON.stringify(manifest,null,2));
fs.writeFileSync(path.join(OUT,'audit.json'),JSON.stringify(proofs,null,2));
console.log(JSON.stringify(manifest.master));
