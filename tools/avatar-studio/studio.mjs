import {clusterStats,DRAWN,MIRROR,RULES,DIRS,DIR_NAMES,SPEC,ACTIONS,ANCHORS,STAIRS,SLOTS,VARIANTS,hexToInt,intToHex,blank,quantize,suggestMapping,applyMapping,appearanceRamps,metrics,autoHead,autoTorso,steadyTorso,laggedMount,registerToPivot,mirror,composeFrame,auditFrames,auditHeadLayer,auditTorsoLayer,auditBackpack,auditFrameLayer,actionDirs,manifest,paletteJson,downscale} from './model.mjs';
import {zip} from './iso-studio/model.mjs';
const $=id=>document.getElementById(id),STORE='avatar-studio:projeto',C=SPEC.cell,PIVOT=SPEC.pivot;
// Peças: onde se prendem e quais grupos de cor podem usar.
const PIECES={cabelo:{name:'Cabelo',kind:'head',colors:['cabelo','contorno']},'cabelo-tras':{name:'Cabelo (parte de trás)',kind:'head',colors:['cabelo','contorno']},acessorio:{name:'Boné ou chapéu',kind:'head',colors:['jaqueta','camiseta','calca','tenis','detalhe','mochila','contorno']},
 mochila:{name:'Mochila (bolsa)',kind:'torso',colors:['mochila','detalhe','contorno'],lag:1},alcas:{name:'Alças da mochila',kind:'torso',colors:['mochila','detalhe','contorno']},mao:{name:'Na mão (carretel)',kind:'hand',colors:['detalhe','mochila','jaqueta','camiseta','contorno']},roupa:{name:'Roupa de modelo',kind:'frames',colors:['jaqueta','camiseta','calca','detalhe','contorno']}};
const POINT_COLOR={head:'#ff4fa3',torso:'#ffa53a',hand:'#57d68d'};
const RULE_LABEL={Pivô:'Pé',Cabeça:'Cabeça',Deriva:'Redesenho',Paleta:'Cores',Altura:'Tamanho',Tronco:'Mochila',Mochila:'Mochila',Cabelo:'Cabelo',Roupa:'Roupa',Quadros:'Quadros',Alpha:'Bordas',Grade:'Tamanho'};
const RULE_STEP={Paleta:'palette',Tronco:'layers',Mochila:'layers',Cabelo:'layers',Roupa:'layers'};
const emptyProject=()=>({name:'Kael',actions:Object.fromEntries(Object.entries(ACTIONS).map(([id,a])=>[id,{ms:a.ms,dirs:actionDirs(id)}])),mapping:{clusters:[],assign:[]},slots:structuredClone(SLOTS),appearance:{},layers:[]});
const state={project:emptyProject(),step:'frames',action:'andar',dir:'se',frame:0,playing:false,onion:true,guides:true,ghosts:true,layer:null,point:'head',allFrames:true};
const raw=new Map(),keyedCache=new Map(),composedCache=new Map(),auditCache=new Map();let version=0,looksSeed=1,timer=null,tick=0,liveTick=0,drag=null;
const say=t=>{$('message').textContent=t;};
const slug=t=>String(t).normalize('NFD').replace(/[̀-ͯ]/g,'').toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'')||'avatar';
// ---------- imagens ----------
const loadImage=src=>new Promise((ok,err)=>{const i=new Image();i.onload=()=>ok(i);i.onerror=()=>err(Error('PNG inválido.'));i.src=src;});
function toData(img,w=img.naturalWidth||img.width,h=img.naturalHeight||img.height,sx=0,sy=0){const c=document.createElement('canvas');c.width=w;c.height=h;const g=c.getContext('2d');g.drawImage(img,sx,sy,w,h,0,0,w,h);const d=g.getImageData(0,0,w,h);return {width:w,height:h,data:d.data};}
function toCanvas(data){const c=document.createElement('canvas');c.width=data.width;c.height=data.height;c.getContext('2d').putImageData(new ImageData(new Uint8ClampedArray(data.data),data.width,data.height),0,0);return c;}
const toURL=data=>toCanvas(data).toDataURL('image/png');
async function ensureRaw(){for(const src of allSources())if(!raw.has(src))raw.set(src,toData(await loadImage(src)));}
function allSources(){const out=[];for(const a of Object.values(state.project.actions))for(const d of Object.values(a.dirs))for(const f of d.frames||[])out.push(f.src);for(const l of state.project.layers){for(const v of Object.values(l.images||{}))out.push(v);for(const a of Object.values(l.frames||{}))for(const list of Object.values(a))for(const v of list)if(v)out.push(v);}return out;}
function keyed(src){if(keyedCache.has(src))return keyedCache.get(src);const r=raw.get(src);if(!r)return null;const m=state.project.mapping,out=m.clusters.length?applyMapping(r,m.clusters,m.assign,state.project.slots):r;keyedCache.set(src,out);return out;}
function keyLayer(data,slot){const allowed=PIECES[slot]?.colors,slots=state.project.slots.filter(s=>!allowed||allowed.includes(s.id)),clusters=[],assign=[];for(const s of slots)s.tones.forEach((t,tone)=>{clusters.push({color:hexToInt(t)});assign.push({slot:s.id,tone});});return applyMapping(data,clusters,assign,state.project.slots);}
// ---------- acesso ----------
const entry=(action=state.action,dir=state.dir)=>state.project.actions[action]?.dirs[dir];
const dirsOf=action=>DIRS.filter(d=>entry(action,d));
const flip=p=>p?[C-1-p[0],p[1]]:null;
function framesOf(action=state.action,dir=state.dir){const e=entry(action,dir);if(e?.mirror){const src=entry(action,e.mirror);return (src?.frames||[]).map(f=>({...f,mirrored:true,head:flip(f.head),torso:flip(f.torso),hand:flip(f.hand)}));}return e?.frames||[];}
function baseImage(f){const k=keyed(f.src);return k&&f.mirrored?mirror(k):k;}
const kindOf=l=>l.kind||PIECES[l.slot]?.kind||'head';
// Imagem e ponto de encaixe de uma peça numa direção; as esquerdas espelham as direitas.
function layerView(l,dir){const m=MIRROR[dir],own=l.images?.[dir],src=own||(m&&l.mirror!==false?l.images?.[m]:null);if(!src||!raw.get(src))return null;const img=own?raw.get(own):mirror(raw.get(src)),a=own?l.anchors?.[dir]:l.anchors?.[m]&&[img.width-1-l.anchors[m][0],l.anchors[m][1]];return a?{image:img,anchor:a,mirrored:!own}:null;}
function layersFor(dir,action,i){const frames=framesOf(action,dir);return state.project.layers.filter(l=>l.on!==false).map(l=>{const kind=kindOf(l);
 if(kind!=='frames'){const v=layerView(l,dir);if(!v)return null;const points=frames.map(f=>f[kind]||(kind==='torso'?autoTorso(baseImage(f),state.project.slots):null));const mount=laggedMount(points,i,l.lag||0);return mount?{kind,slot:l.slot,image:v.image,anchor:v.anchor,mount}:null;}
 const m=MIRROR[dir],own=l.frames?.[action]?.[dir],list=own||(m&&l.frames?.[action]?.[m]),src=list?.[i];if(!src||!raw.get(src))return null;return {kind:'frames',slot:l.slot,image:own?raw.get(src):mirror(raw.get(src))};}).filter(Boolean);}
function composed(action,dir,i,ramps,rampKey=JSON.stringify(state.project.appearance)){const key=`${action}|${dir}|${i}|${rampKey}`;if(composedCache.has(key))return composedCache.get(key);const f=framesOf(action,dir)[i];if(!f)return null;const base=baseImage(f);if(!base)return null;
 const out=composeFrame({base,head:f.head||[C/2,SPEC.eyeLine],torso:f.torso,hand:f.hand,dir,layers:layersFor(dir,action,i),ramps:ramps||appearanceRamps(state.project.slots,state.project.appearance),slots:state.project.slots});composedCache.set(key,out);return out;}
const smallCache=new Map();function small(action,dir,i){const key=`${action}|${dir}|${i}`;if(!smallCache.has(key)){const img=composed(action,dir,i);smallCache.set(key,img?toCanvas(downscale(img)):null);}return smallCache.get(key);}
// ---------- persistência ----------
function persist(){try{localStorage.setItem(STORE,JSON.stringify(state.project));}catch{/* sem espaço: o projeto continua na sessão */}}
function invalidate(){version++;composedCache.clear();smallCache.clear();auditCache.clear();}
function changed(text,{remap=false,quiet=false}={}){if(remap)keyedCache.clear();invalidate();persist();if(quiet)draw();else render();if(text)say(text);}
async function restore(json,text){const data=typeof json==='string'?JSON.parse(json):json;if(!data?.actions||!data?.mapping)throw Error('Arquivo não é um projeto do Avatar Studio.');const base=emptyProject();
 state.project={...base,...data,actions:Object.fromEntries(Object.keys(base.actions).map(id=>[id,{...base.actions[id],...data.actions?.[id],dirs:{...base.actions[id].dirs,...data.actions?.[id]?.dirs}}])),slots:data.slots||base.slots,layers:(data.layers||[]).map(l=>({...l,kind:l.kind||PIECES[l.slot]?.kind}))};
 raw.clear();keyedCache.clear();invalidate();await ensureRaw();for(const id of Object.keys(ACTIONS))for(const d of DIRS)if(entry(id,d)?.frames?.length&&entry(id,d).frames.some(f=>!f.torso))setTorso(id,d);pickExisting();render();if(text)say(text);}
function pickExisting(){for(const [a,v] of Object.entries(state.project.actions))for(const d of DIRS)if(v.dirs[d]?.frames?.length){state.action=a;state.dir=d;state.frame=0;return;}}
// ---------- importação ----------
async function readFiles(files){const out=[];for(const f of files.sort((a,b)=>a.name.localeCompare(b.name,undefined,{numeric:true})))out.push({name:f.name,src:await new Promise((ok,err)=>{const r=new FileReader();r.onload=()=>ok(r.result);r.onerror=err;r.readAsDataURL(f);})});return out;}
// Folha com várias células é fatiada; quadro solto de outro tamanho é encaixado pelo pé no pivô.
async function framesFromImages(list){const frames=[];for(const {src} of list){const img=await loadImage(src),w=img.naturalWidth,h=img.naturalHeight;
  if(w%C===0&&h%C===0&&(w>C||h>C)){for(let y=0;y<h;y+=C)for(let x=0;x<w;x+=C){const cell=toData(img,C,C,x,y);if(metrics(cell).area)frames.push(cell);}}
  else if(w===C&&h===C)frames.push(toData(img));
  else{const d=toData(img),m=metrics(d),cell=blank(C,C);if(!m.bounds)continue;const k=Math.min(1,(SPEC.height+8)/m.bounds.h,(C-16)/m.bounds.w);if(k<1)throw Error(`Quadro de ${w}×${h}: reduza para a escala da guia (personagem com ${SPEC.height} px) antes de importar.`);
   for(let y=0;y<m.bounds.h;y++)for(let x=0;x<m.bounds.w;x++){const s=((m.bounds.y+y)*w+m.bounds.x+x)*4,tx=Math.round(C/2-m.bounds.w/2)+x,ty=PIVOT[1]-m.bounds.h+y;if(tx<0||ty<0||tx>=C||ty>=C)continue;const t=(ty*C+tx)*4;for(let j=0;j<4;j++)cell.data[t+j]=d.data[s+j];}frames.push(cell);}}
 return frames;}
async function setFrames(cells,text){const dir=entry()?.mirror?entry().mirror:state.dir,list=cells.map(c=>({src:toURL(c),head:null}));state.project.actions[state.action].dirs[dir]={frames:list};state.dir=dir;
 for(const f of list)raw.set(f.src,toData(await loadImage(f.src)));if(!state.project.mapping.clusters.length)remapAll();else keyedCache.clear();autoPoints(state.action,dir);state.frame=0;changed(text);}
function remapAll(k=24){const imgs=allSources().filter(s=>!isLayerSource(s)).map(s=>raw.get(s)).filter(Boolean);if(!imgs.length)return;const clusters=quantize(imgs,k);state.project.mapping={clusters:clusters.map(c=>({color:c.color,count:c.count})),assign:suggestMapping(clusters,state.project.slots,clusterStats(imgs,clusters))};keyedCache.clear();}
const isLayerSource=src=>state.project.layers.some(l=>Object.values(l.images||{}).includes(src)||Object.values(l.frames||{}).some(a=>Object.values(a).some(list=>list.includes(src))));
// Costas seguem a cabeça (sem tremer); cabeça medida pelo rosto.
function setTorso(action,dir){const e=entry(action,dir),frames=(e.frames||[]).map(f=>({image:keyed(f.src),head:f.head})),t=steadyTorso(frames,state.project.slots);e.frames.forEach((f,i)=>{f.torso=t[i]||f.torso||autoTorso(keyed(f.src),state.project.slots);});}
function autoPoints(action,dir){const e=entry(action,dir);for(const f of e.frames||[]){const k=keyed(f.src);if(k)f.head=autoHead(k,state.project.slots);}setTorso(action,dir);}
// ---------- desenho ----------
const ORIGIN=20,stage=$('stage'),g=stage.getContext('2d'),live=$('live'),lg=live.getContext('2d');lg.imageSmoothingEnabled=false;
function checker(ctx,x,y,w,h,s=8){ctx.fillStyle='#ece7db';ctx.fillRect(x,y,w,h);ctx.fillStyle='#e0dacb';for(let yy=0;yy<h;yy+=s)for(let xx=(yy/s)%2?s:0;xx<w;xx+=s*2)ctx.fillRect(x+xx,y+yy,Math.min(s,w-xx),Math.min(s,h-yy));}
function guides(ctx,x,y,Z,action=state.action){ctx.save();ctx.lineWidth=1;ctx.strokeStyle='rgba(30,120,200,.55)';const line=(x0,y0,x1,y1)=>{ctx.beginPath();ctx.moveTo(x+x0*Z+.5,y+y0*Z+.5);ctx.lineTo(x+x1*Z+.5,y+y1*Z+.5);ctx.stroke();};
 line(0,PIVOT[1],C,PIVOT[1]);ctx.setLineDash([4,4]);line(0,SPEC.eyeLine,C,SPEC.eyeLine);line(0,PIVOT[1]-SPEC.height,C,PIVOT[1]-SPEC.height);line(PIVOT[0],0,PIVOT[0],C);ctx.setLineDash([]);
 // Escada: piso do degrau atual (losango 2:1 sob o pé) e do próximo, um degrau acima (subir) ou abaixo (descer), com o espelho vertical entre eles.
 const st=ACTIONS[action]?.stairs;if(st){const up=st==='up',[px,py]=PIVOT,[dx,dy]=STAIRS.depth,nx=px+dx,ny=up?py+dy-STAIRS.rise:py-dy+STAIRS.rise,tread=(cx,cy)=>{line(cx-36,cy,cx,cy-18);line(cx,cy-18,cx+36,cy);line(cx+36,cy,cx,cy+18);line(cx,cy+18,cx-36,cy);};
  ctx.strokeStyle='rgba(160,90,20,.85)';ctx.lineWidth=2;tread(px,py);tread(nx,ny);const riser=up?[nx-18,ny+9]:[px+18,py-9],h=STAIRS.rise;line(riser[0],riser[1],riser[0],riser[1]+h);
  ctx.fillStyle='rgba(160,90,20,.95)';ctx.font='600 11px system-ui';ctx.fillText(up?'próximo degrau (+1)':'próximo degrau (−1)',x+(nx+40)*Z,y+(ny+4)*Z);}
 ctx.fillStyle='#e0262f';ctx.fillRect(x+PIVOT[0]*Z-3,y+PIVOT[1]*Z-3,6,6);ctx.restore();}
function pointMark(ctx,x,y,Z,p,kind,active){if(!p)return;ctx.save();ctx.strokeStyle=POINT_COLOR[kind];ctx.fillStyle=POINT_COLOR[kind];ctx.lineWidth=active?3:2;const cx=x+p[0]*Z,cy=y+p[1]*Z;ctx.beginPath();ctx.arc(cx,cy,active?9:7,0,Math.PI*2);ctx.stroke();ctx.beginPath();ctx.arc(cx,cy,2.5,0,Math.PI*2);ctx.fill();
 if(active){ctx.font='700 11px system-ui';ctx.lineWidth=3;ctx.strokeStyle='#0c161e';ctx.strokeText(ANCHORS[kind],cx+12,cy-8);ctx.fillText(ANCHORS[kind],cx+12,cy-8);}ctx.restore();}
const Zbig=()=>Math.max(1,Math.min(2,Math.floor(Math.min(($('viewport').clientHeight-ORIGIN*2-8)/C,($('viewport').clientWidth-ORIGIN*2-8)/C)*2)/2));
function size(w,h){stage.width=w;stage.height=h;stage.style.width=w+'px';stage.style.height=h+'px';g.imageSmoothingEnabled=false;}
function drawFrames(){
 const frames=framesOf(),i=state.playing?tick%Math.max(1,frames.length):state.frame,f=frames[i],Z=Zbig();size(C*Z+ORIGIN*2,C*Z+ORIGIN*2);g.fillStyle='#0c161e';g.fillRect(0,0,stage.width,stage.height);checker(g,ORIGIN,ORIGIN,C*Z,C*Z);
 if(!f){g.fillStyle='#203b3c';g.font='600 15px system-ui';g.fillText('Ainda não há desenhos aqui.',ORIGIN+20,60);g.font='13px system-ui';g.fillText('Importe os desenhos ou baixe a guia',ORIGIN+20,84);g.fillText('e copie o pedido para o Codex.',ORIGIN+20,102);if(state.guides)guides(g,ORIGIN,ORIGIN,Z);return;}
 if(state.onion&&!state.playing&&frames.length>1){const p=baseImage(frames[(i-1+frames.length)%frames.length]);if(p){g.globalAlpha=.22;g.drawImage(toCanvas(p),ORIGIN,ORIGIN,C*Z,C*Z);g.globalAlpha=1;}}
 const img=baseImage(f);if(img)g.drawImage(toCanvas(img),ORIGIN,ORIGIN,C*Z,C*Z);
 if(state.guides)guides(g,ORIGIN,ORIGIN,Z);for(const k of Object.keys(ANCHORS))pointMark(g,ORIGIN,ORIGIN,Z,f[k],k,k===state.point);
}
function drawPalette(){
 const f=framesOf()[state.frame],Z=Math.max(1,Math.min(2,Math.floor(($('viewport').clientWidth-80)/(C*2)*2)/2));size(C*Z*2+60,C*Z+60);g.fillStyle='#0c161e';g.fillRect(0,0,stage.width,stage.height);checker(g,20,40,C*Z,C*Z);checker(g,C*Z+40,40,C*Z,C*Z);
 g.fillStyle='#afc0c6';g.font='600 12px system-ui';g.fillText('Desenho original',20,28);g.fillText('Separado por grupo (vermelho = cor sem grupo)',C*Z+40,28);if(!f)return;
 const r=raw.get(f.src),k=keyed(f.src);if(r)g.drawImage(toCanvas(f.mirrored?mirror(r):r),20,40,C*Z,C*Z);
 if(k){const show=f.mirrored?mirror(k):k,marked=blank(C,C);marked.data.set(show.data);for(let p=0;p<marked.data.length;p+=4)if(marked.data[p+3]===254){marked.data[p]=255;marked.data[p+1]=30;marked.data[p+2]=60;marked.data[p+3]=255;}g.drawImage(toCanvas(marked),C*Z+40,40,C*Z,C*Z);}
}
function selectedLayer(){return state.project.layers.find(l=>l.id===state.layer)||null;}
function drawLayers(){
 const frames=framesOf(),i=state.playing?tick%Math.max(1,frames.length):state.frame,Z=Zbig();size(C*Z+ORIGIN*2,C*Z+ORIGIN*2);g.fillStyle='#0c161e';g.fillRect(0,0,stage.width,stage.height);checker(g,ORIGIN,ORIGIN,C*Z,C*Z);
 if(!frames[i])return;const l=selectedLayer(),kind=l&&kindOf(l);
 // Fantasmas: a peça selecionada em todos os quadros do ciclo, para ver se acompanha o corpo.
 if(l&&kind!=='frames'&&state.ghosts&&!state.playing){const v=layerView(l,state.dir);if(v){const pts=frames.map(f=>f[kind]);g.globalAlpha=.16;pts.forEach((p,k)=>{const m=laggedMount(pts,k,l.lag||0);if(m&&k!==i)g.drawImage(toCanvas(v.image),ORIGIN+(m[0]-v.anchor[0])*Z,ORIGIN+(m[1]-v.anchor[1])*Z,v.image.width*Z,v.image.height*Z);});g.globalAlpha=1;}}
 const img=composed(state.action,state.dir,i);if(img)g.drawImage(toCanvas(img),ORIGIN,ORIGIN,C*Z,C*Z);
 if(state.guides)guides(g,ORIGIN,ORIGIN,Z);
 if(l&&kind!=='frames'){const v=layerView(l,state.dir),pts=frames.map(f=>f[kind]),m=laggedMount(pts,i,l.lag||0);if(v&&m){g.save();g.setLineDash([5,4]);g.strokeStyle=POINT_COLOR[kind];g.lineWidth=2;g.strokeRect(ORIGIN+(m[0]-v.anchor[0])*Z,ORIGIN+(m[1]-v.anchor[1])*Z,v.image.width*Z,v.image.height*Z);g.restore();}pointMark(g,ORIGIN,ORIGIN,Z,frames[i][kind],kind,true);}
}
function drawLook(){
 const looks=lookList(),pad=12,cols=4,Z=1,rows=Math.ceil(looks.length/cols);size((C*Z+pad)*cols+pad,(C*Z+pad)*rows*2+pad);g.fillStyle='#0c161e';g.fillRect(0,0,stage.width,stage.height);
 looks.forEach((look,k)=>{const ramps=appearanceRamps(state.project.slots,look),key=JSON.stringify(look);['se','ne'].forEach((dir,j)=>{const x=pad+(k%cols)*(C*Z+pad),y=pad+(Math.floor(k/cols)*2+j)*(C*Z+pad);checker(g,x,y,C*Z,C*Z);
  const d=framesOf(state.action,dir).length?dir:dirsOf(state.action).find(x=>framesOf(state.action,x).length),n=d?framesOf(state.action,d).length:0;if(!n)return;const img=composed(state.action,d,tick%n,ramps,key);if(img)g.drawImage(toCanvas(downscale(img)),x,y,C*Z,C*Z);});});
}
function lookList(){const out=[state.project.appearance];let s=looksSeed;const rnd=()=>{s=(s*16807)%2147483647;return s/2147483647;};for(let i=0;i<7;i++){const look={};for(const [slot,list] of Object.entries(VARIANTS))look[slot]=Math.floor(rnd()*list.length);out.push(look);}return out;}
function draw(){({frames:drawFrames,palette:drawPalette,layers:drawLayers,look:drawLook})[state.step]();}
// Prévia sempre animada, em 1× (tamanho do jogo), nas quatro direções.
function drawLive(){const w=live.width;lg.fillStyle='#0c161e';lg.fillRect(0,0,w,live.height);const cell=128,gap=4;
 DIRS.forEach((dir,k)=>{const x=k*(cell+gap),y=18;checker(lg,x,y,cell,cell,4);lg.fillStyle=dir===state.dir?'#7cc5f0':'#afc0c6';lg.font=`${dir===state.dir?700:500} 11px system-ui`;lg.fillText(DIR_NAMES[dir],x+2,12);
  const n=framesOf(state.action,dir).length;if(!n){lg.fillStyle='#8a9aa0';lg.font='11px system-ui';lg.fillText(entry(state.action,dir)?'sem desenhos':'não usada',x+30,y+68);return;}
  const loop=(state.project.actions[state.action].loop??ACTIONS[state.action].loop)!==false,i=loop?liveTick%n:Math.min(liveTick%(n+6),n-1),c=small(state.action,dir,i);if(c)lg.drawImage(c,x,y);});}
function liveLoop(){liveTick++;drawLive();setTimeout(liveLoop,state.project.actions[state.action]?.ms||120);}
// ---------- o que falta ----------
const verdict=items=>items.some(i=>i.level==='fail')?'fail':items.some(i=>i.level==='warn')?'warn':'ok';
function auditOf(action,dir){const key=`${action}|${dir}`;if(auditCache.has(key))return auditCache.get(key);
 const fr=framesOf(action,dir),frames=fr.map(f=>({image:baseImage(f),head:f.head})).filter(f=>f.image),out=auditFrames(frames,{slots:state.project.slots});
 if(frames.length&&!state.project.mapping.clusters.length&&out.metrics.some(m=>m.off))out.items.unshift({level:'fail',rule:'Paleta',text:'Cores ainda não separadas por grupo.'});
 const want=ACTIONS[action].frames;if(frames.length&&frames.length!==want)out.items.push({level:'warn',rule:'Quadros',text:`${frames.length} quadros; a animação pede ${want}.`});
 const f=fr[0];if(f){const base=baseImage(f),layers=layersFor(dir,action,0);
  for(const l of state.project.layers.filter(x=>x.on!==false)){const live=layers.find(x=>x.slot===l.slot);if(!live)continue;let check;
   if(live.kind==='torso'&&l.slot==='mochila')check=auditTorsoLayer(base,live.mount,live);else if(live.kind==='head')check=auditHeadLayer(base,live.mount,live);else if(live.kind==='frames')check=auditFrameLayer(base,live.image);else continue;out.items.push({...check,text:`${l.name}: ${check.text}`});}
  const bag=layers.find(x=>x.slot==='mochila'),pack=bag&&auditBackpack({base,torso:bag.mount,bag,straps:layers.some(x=>x.slot==='alcas'),dir});if(pack)out.items.push(pack);
  if(ACTIONS[action].group==='Pipa'&&action==='empinar'&&fr.some(x=>!x.hand))out.items.push({level:'warn',rule:'Mão',text:'Marque o ponto da mão em todos os quadros para prender o carretel.'});}
 auditCache.set(key,out);return out;}
function todos(){const list=[];for(const [id,a] of Object.entries(ACTIONS))for(const dir of DRAWN){const e=entry(id,dir);if(!e||e.mirror)continue;const n=e.frames?.length||0;
  if(!n){if(a.group==='Essenciais')list.push({level:'todo',step:'frames',action:id,dir,frame:0,label:'Desenhos',text:`${a.name} · ${DIR_NAMES[dir]}: ainda sem desenhos.`});continue;}
  for(const it of auditOf(id,dir).items){if(it.level!=='fail'&&it.level!=='warn')continue;const fm=/[Qq]uadros? (\d+)/.exec(it.text);list.push({level:it.level,step:RULE_STEP[it.rule]||'frames',action:id,dir,frame:fm?Number(fm[1]):0,label:RULE_LABEL[it.rule]||it.rule,text:`${a.name} · ${DIR_NAMES[dir]}: ${it.text}`});}}
 return list.sort((a,b)=>({fail:0,warn:1,todo:2})[a.level]-({fail:0,warn:1,todo:2})[b.level]);}
// ---------- interface ----------
function el(tag,props={},...kids){const e=Object.assign(document.createElement(tag),props);e.append(...kids);return e;}
function button(text,fn,cls){const b=el('button',{textContent:text,className:cls||''});b.onclick=fn;return b;}
function auditList(items){return items.map(i=>{const li=el('li');li.dataset.level=i.level;li.append(el('b',{textContent:RULE_LABEL[i.rule]||i.rule||''}),el('span',{textContent:i.text}));return li;});}
function go(t){state.step=t.step;state.action=t.action;state.dir=t.dir;state.frame=Math.min(t.frame,Math.max(0,framesOf(t.action,t.dir).length-1));if(t.step==='layers'&&!selectedLayer()){const bag=state.project.layers.find(l=>l.slot==='mochila');if(bag)state.layer=bag.id;}render();}
function render(){
 document.body.dataset.step=state.step;const items=todos();
 document.querySelectorAll('.steps button').forEach(b=>{b.setAttribute('aria-current',b.dataset.step===state.step?'step':'false');const n=items.filter(i=>i.step===b.dataset.step&&i.level!=='todo').length;b.querySelector('.badge').textContent=n||'';b.querySelector('.badge').hidden=!n;});
 $('projectName').value=state.project.name;
 const groups={};for(const [id,a] of Object.entries(ACTIONS))(groups[a.group]??=[]).push([id,a]);
 $('actionTree').replaceChildren(...Object.entries(groups).map(([group,list])=>el('div',{className:'group'},el('h3',{textContent:group}),...list.map(([id,a])=>{const row=el('div',{className:'action'+(id===state.action?' current':'')}),dirs=el('div',{className:'dirs'});
  const done=a.dirs.filter(d=>(entry(id,d)?.frames?.length||0)>=a.frames).length;row.append(el('span',{className:'action-name',textContent:a.name}),el('small',{textContent:`${a.frames} q · ${done}/${a.dirs.length}`}));
  for(const dir of dirsOf(id)){const e=entry(id,dir),n=framesOf(id,dir).length,b=button(dir.toUpperCase(),()=>{state.action=id;state.dir=dir;state.frame=0;render();});b.append(el('small',{textContent:e.mirror?(n?'espelho':'—'):n?`${n}`:'—'}));b.title=`${a.name} · ${DIR_NAMES[dir]}${e.mirror?' (espelho)':''}`;b.setAttribute('aria-current',id===state.action&&dir===state.dir);if(n&&!e.mirror)b.dataset.state=verdict(auditOf(id,dir).items);dirs.append(b);}
  row.append(dirs);return row;}))));
 const frames=framesOf(),a=ACTIONS[state.action];$('stageTitle').textContent=`${a.name} · ${DIR_NAMES[state.dir]||''}`;
 $('stageSub').textContent=entry()?.mirror?`Espelho de ${DIR_NAMES[entry().mirror]} · ${frames.length} quadros`:`${frames.length} de ${a.frames} quadros · ${state.project.actions[state.action].ms} ms cada${a.loop===false?' · toca uma vez':''}`;
 $('tip').textContent=({frames:`${a.tip} Arraste os pontos coloridos: rosa = cabeça, laranja = costas, verde = mão.`,palette:'Cada cor do desenho precisa de um grupo. Corrija os grupos errados na lista ao lado; a imagem da direita mostra o resultado.',layers:'Selecione uma peça ao lado e arraste-a na imagem. A peça translúcida mostra onde ela fica nos outros quadros; a prévia embaixo anda com ela.',look:'Troque as cores ao lado. As outras colunas são aparências sorteadas para conferir se uma cor não vaza para outro grupo.'})[state.step];
 $('strip').replaceChildren(...frames.map((f,i)=>{const b=el('button'),c=small(state.action,state.dir,i);if(c)b.append(c);else b.append(el('span',{textContent:i}));b.title=`Quadro ${i+1}`;b.setAttribute('aria-current',i===state.frame);b.onclick=()=>{state.frame=i;render();};return b;}));
 const todo=$('todo');todo.replaceChildren(el('h3',{textContent:items.length?`O que falta (${items.length})`:'O que falta'}));
 if(!items.length)todo.append(el('p',{className:'all-ok',textContent:'Tudo certo nas animações essenciais ✓'}));
 else{const ul=el('ul');for(const it of items.slice(0,4)){const li=el('li');li.dataset.level=it.level;li.append(el('b',{textContent:it.label}),el('span',{textContent:it.text}),button('Ver',()=>go(it)));ul.append(li);}todo.append(ul);if(items.length>4)todo.append(el('small',{className:'muted',textContent:`+ ${items.length-4} itens. Resolva os de cima primeiro.`}));}
 inspector();const counts=Object.values(state.project.actions).reduce((s,x)=>s+Object.values(x.dirs).reduce((t,d)=>t+(d.frames?.length||0),0),0);$('summary').textContent=`${counts} desenhos · ${state.project.layers.length} peças`;
 draw();drawLive();
}
function inspector(){
 const box=$('inspector'),f=framesOf()[state.frame];box.replaceChildren();
 if(state.step==='frames'){$('inspEyebrow').textContent='DESENHO';$('inspTitle').textContent=f?`Quadro ${state.frame+1} de ${framesOf().length}`:'Sem desenho';
  const pts=el('div',{className:'points'});for(const [k,name] of Object.entries(ANCHORS)){const b=button(name,()=>{state.point=k;state.allFrames=k!=='head';render();});b.prepend(el('i',{className:`dot ${k}`}));b.setAttribute('aria-pressed',state.point===k);pts.append(b);}
  const all=el('input',{type:'checkbox',checked:state.allFrames});all.onchange=()=>{state.allFrames=all.checked;};
  box.append(el('p',{className:'muted',textContent:'Escolha o ponto e arraste na imagem (ou clique onde ele deve ficar). Setas movem 1 px; vírgula e ponto trocam de quadro.'}),pts,el('label',{className:'inline'},all,' Mover em todos os quadros desta direção'));
  if(f){const m=metrics(baseImage(f));box.append(el('p',{className:'box-info',textContent:`pé y=${m.baseline} (alvo ${PIVOT[1]}) · altura ${m.bounds?.h||0} px`}));}
  const row=el('div',{className:'row'});if(!entry()?.mirror&&framesOf().length)row.append(button('Pontos automáticos',()=>{autoPoints(state.action,state.dir);changed('Cabeça medida pelo rosto e costas acompanhando a cabeça. Confira e ajuste a mão à parte.');}),button('Costas seguem a cabeça',()=>{setTorso(state.action,state.dir);changed('Ponto das costas recalculado a partir da cabeça: não treme mais entre quadros.');}),button('Acertar pés no chão',()=>registerAll()),button('Excluir quadro',()=>{entry().frames.splice(state.frame,1);state.frame=Math.max(0,state.frame-1);changed('Quadro excluído.');},'danger'));
  const m=MIRROR[state.dir];if(m)row.append(button(entry()?.mirror?'Desenhar esta direção à parte':`Voltar a espelhar ${DIR_NAMES[m]}`,()=>{const e=state.project.actions[state.action].dirs;e[state.dir]=e[state.dir]?.mirror?{frames:[]}:{mirror:m};changed(e[state.dir].mirror?`${DIR_NAMES[state.dir]} espelha ${DIR_NAMES[m]}.`:'Esta direção agora tem desenhos próprios: importe-os.');}));
  box.append(row,el('label',{},'Duração de cada quadro (ms)',(()=>{const i=el('input',{type:'number',min:40,max:600,step:10,value:state.project.actions[state.action].ms});i.onchange=()=>{state.project.actions[state.action].ms=Math.max(40,Number(i.value)||100);changed();};return i;})()));
 }
 if(state.step==='palette'){$('inspEyebrow').textContent='CORES';$('inspTitle').textContent='Separar as cores por grupo';
  const m=state.project.mapping;box.append(el('p',{className:'muted',textContent:'À esquerda a cor do desenho, ao lado a cor do grupo escolhido. Atenção ao azul-marinho (cabelo, contorno, tênis) e aos tons de pele.'}));
  const k=el('input',{type:'number',min:6,max:48,value:m.clusters.length||24});box.append(el('div',{className:'row'},el('label',{className:'grow'},'Quantas cores separar',k),button('Separar de novo',()=>{remapAll(Number(k.value)||24);changed('Cores separadas e sugeridas de novo.');})));
  const list=el('div',{className:'swatches'}),options=[['','— sem grupo —'],...state.project.slots.flatMap(s=>s.tones.map((t,i)=>[`${s.id}:${i}`,`${s.name} ${i+1}`]))];
  m.clusters.forEach((c,i)=>{const sel=el('select');options.forEach(([v,t])=>sel.append(el('option',{value:v,textContent:t})));const a=m.assign[i];sel.value=a?`${a.slot}:${a.tone}`:'';
   sel.onchange=()=>{const [slot,tone]=sel.value.split(':');m.assign[i]=slot?{slot,tone:Number(tone)}:null;changed(null,{remap:true});};
   const target=a?state.project.slots.find(s=>s.id===a.slot)?.tones[a.tone]:'transparent';list.append(el('div',{className:'swatch'},el('i',{style:`background:${intToHex(c.color)}`}),el('i',{style:`background:${target}`}),sel,el('small',{textContent:c.count})));});
  box.append(list);
 }
 if(state.step==='layers'){$('inspEyebrow').textContent='PEÇAS';$('inspTitle').textContent='Peças presas ao corpo';
  const kind=el('select');Object.entries(PIECES).forEach(([v,p])=>kind.append(el('option',{value:v,textContent:p.name})));
  box.append(el('div',{className:'row'},el('label',{className:'grow'},'Adicionar peça',kind),button('+ Adicionar',()=>{const p=PIECES[kind.value],id=slug(p.name)+'-'+(state.project.layers.length+1);state.project.layers.push({id,name:p.name,slot:kind.value,kind:p.kind,images:{},anchors:{},frames:{},mirror:true,on:true,lag:p.lag||0});state.layer=id;changed(`${p.name} criada: importe a imagem de cada direção.`);})));
  for(const l of state.project.layers){const lk=kindOf(l),card=el('div',{className:'layer-card'+(l.id===state.layer?' selected':'')});card.onclick=e=>{if(e.target.closest('button,input,select'))return;state.layer=l.id;render();};
   const on=el('input',{type:'checkbox',checked:l.on!==false});on.onchange=()=>{l.on=on.checked;changed();};
   const head=el('div',{className:'layer-head'},el('i',{className:`dot ${lk==='frames'?'frames':lk}`}),el('strong',{textContent:l.name}),el('small',{textContent:lk==='frames'?'um desenho por quadro':`presa ${lk==='head'?'à cabeça':lk==='torso'?'às costas':'à mão'}`}));
   const dirs=el('div',{className:'dirs'});for(const dir of lk!=='frames'?DRAWN:[state.dir]){const has=lk!=='frames'?!!l.images?.[dir]:!!l.frames?.[state.action]?.[dir]?.[state.frame];const b=button(`${DIR_NAMES[dir]}`,()=>pickLayerFile(l,dir));b.append(el('small',{textContent:has?'✓ trocar':'+ importar'}));dirs.append(b);}
   card.append(head,dirs);
   if(lk==='torso'||lk==='hand'){const lag=el('select');[['0','Sem balanço'],['1','Balanço leve (1 quadro)'],['2','Balanço forte (2 quadros)']].forEach(([v,t])=>lag.append(el('option',{value:v,textContent:t})));lag.value=String(l.lag||0);lag.onchange=()=>{l.lag=Number(lag.value);changed('Balanço atualizado: veja na prévia embaixo.');};card.append(el('label',{},'Acompanha o passo',lag));}
   card.append(el('div',{className:'row'},el('label',{className:'inline'},on,' Visível'),...(lk!=='frames'?[el('label',{className:'inline'},(()=>{const c=el('input',{type:'checkbox',checked:l.mirror!==false});c.onchange=()=>{l.mirror=c.checked;changed();};return c;})(),' Esquerdas espelham')]:[]),button('Excluir',()=>{state.project.layers=state.project.layers.filter(x=>x!==l);changed('Peça excluída.');},'danger')));
   box.append(card);}
  if(!state.project.layers.length)box.append(el('p',{className:'muted',textContent:'Nenhuma peça ainda. Comece pelo cabelo; para a mochila, adicione a bolsa e as alças.'}));
 }
 if(state.step==='look'){$('inspEyebrow').textContent='VISUAL FINAL';$('inspTitle').textContent='Trocar cores sem desenhar';
  for(const s of state.project.slots.filter(x=>VARIANTS[x.id])){const sel=el('select');VARIANTS[s.id].forEach(([n],i)=>sel.append(el('option',{value:i,textContent:n})));sel.value=state.project.appearance[s.id]||0;sel.onchange=()=>{state.project.appearance[s.id]=Number(sel.value);changed();};box.append(el('label',{},s.name,sel));}
  box.append(el('div',{className:'row'},button('Sortear outras',()=>{looksSeed=(looksSeed*48271)%2147483647||7;composedCache.clear();draw();}),button('Usar a primeira sorteada',()=>{state.project.appearance={...lookList()[1]};changed('Aparência aplicada.');})));
 }
 const here=framesOf().length?auditOf(state.action,state.dir).items:[{level:'info',rule:'—',text:'Sem desenhos nesta direção.'}];$('audit').replaceChildren(...auditList(here));
}
function pickLayerFile(l,dir){state.layer=l.id;state.layerDir=dir;$('fileLayer').click();}
$('fileLayer').onchange=async e=>{const file=e.target.files[0];e.target.value='';const l=selectedLayer();if(!file||!l)return;const [{src}]=await readFiles([file]),img=await loadImage(src),data=keyLayer(toData(img),l.slot),lk=kindOf(l);
 if(lk!=='frames'){const m=metrics(data),url=toURL(data);(l.images??={})[state.layerDir]=url;raw.set(url,data);(l.anchors??={})[state.layerDir]=m.bounds?[Math.round(m.bounds.x+m.bounds.w/2),Math.round(m.bounds.y+m.bounds.h*(lk==='head'?.7:.3))]:[0,0];state.dir=state.layerDir;say(`${l.name} importada. Arraste na imagem para encaixar.`);}
 else{if(data.width!==C||data.height!==C)return say(`Roupa precisa ter ${C}×${C}, como o quadro.`);const url=toURL(data);raw.set(url,data);((l.frames[state.action]??={})[state.layerDir]??=[])[state.frame]=url;say('Quadro da roupa importado.');}
 changed();};
function registerAll(){const e=entry();let moved=0;e.frames=e.frames.map(f=>{const r=registerToPivot(raw.get(f.src));if(!r.dy)return f;moved++;const src=toURL(r.img);raw.set(src,r.img);const sh=p=>p?[p[0],p[1]+r.dy]:p;return {...f,src,head:sh(f.head),torso:sh(f.torso),hand:sh(f.hand)};});keyedCache.clear();changed(moved?`${moved} quadro(s) deslocado(s) para o pé tocar a linha do chão.`:'Os pés já estão na linha do chão.');}
// ---------- arrastar ----------
function stagePoint(e){const r=stage.getBoundingClientRect(),Z=Zbig();return [(e.clientX-r.left-ORIGIN)/Z,(e.clientY-r.top-ORIGIN)/Z];}
function movePoint(kind,dx,dy,only,abs){const e=entry();if(!e?.frames)return;const list=only!=null&&!state.allFrames?[e.frames[only]]:e.frames;for(const f of list){if(!f)continue;if(f[kind])f[kind]=[f[kind][0]+dx,f[kind][1]+dy];else if(abs)f[kind]=[...abs];}}
stage.addEventListener('pointerdown',e=>{const [x,y]=stagePoint(e),at=[Math.round(x),Math.round(y)];
 if(state.step==='frames'){if(entry()?.mirror)return say('Esta direção é espelho: ajuste os pontos na direção da direita.');const f=entry()?.frames?.[state.frame];if(!f)return;
  // Perto de um ponto: arrasta esse ponto. Longe: o ponto escolhido pula para o clique.
  let hit=null,best=14/Zbig();for(const k of Object.keys(ANCHORS)){const p=f[k];if(p&&Math.hypot(p[0]-x,p[1]-y)<best){best=Math.hypot(p[0]-x,p[1]-y);hit=k;}}
  if(hit&&hit!==state.point){state.point=hit;state.allFrames=hit!=='head';}
  const kind=hit||state.point;if(!hit){const p=f[kind];if(p)movePoint(kind,at[0]-p[0],at[1]-p[1],state.frame);else movePoint(kind,0,0,state.frame,at);}
  drag={kind:'point',point:kind,last:at};stage.setPointerCapture(e.pointerId);changed(null);return;}
 if(state.step==='layers'){const l=selectedLayer();if(!l||kindOf(l)==='frames')return say('Selecione uma peça presa ao corpo (cabelo, mochila, alças, carretel) para arrastar.');
  const v=layerView(l,state.dir);if(!v)return say(`Importe a imagem de ${l.name} para ${DIR_NAMES[MIRROR[state.dir]||state.dir]} primeiro.`);drag={kind:'layer',last:[x,y],mirrored:v.mirrored,dir:v.mirrored?MIRROR[state.dir]:state.dir};stage.setPointerCapture(e.pointerId);}});
stage.addEventListener('pointermove',e=>{if(!drag)return;const [x,y]=stagePoint(e);
 if(drag.kind==='point'){const nx=Math.round(x),ny=Math.round(y),dx=nx-drag.last[0],dy=ny-drag.last[1];if(!dx&&!dy)return;movePoint(drag.point,dx,dy,state.frame);drag.last=[nx,ny];invalidate();draw();return;}
 const dx=Math.round(x-drag.last[0]),dy=Math.round(y-drag.last[1]);if(!dx&&!dy)return;const l=selectedLayer(),a=l.anchors[drag.dir];l.anchors[drag.dir]=[a[0]+(drag.mirrored?dx:-dx),a[1]-dy];drag.last=[drag.last[0]+dx,drag.last[1]+dy];invalidate();draw();drawLive();});
stage.addEventListener('pointerup',()=>{if(!drag)return;const k=drag.kind;drag=null;changed(k==='layer'?'Peça reposicionada em todos os quadros.':null);});
document.addEventListener('keydown',e=>{if(e.target.matches('input,select,textarea'))return;if(e.key===','||e.key==='.'){const n=framesOf().length;if(n){state.frame=(state.frame+(e.key==='.'?1:-1)+n)%n;render();}return;}
 const k={ArrowLeft:[-1,0],ArrowRight:[1,0],ArrowUp:[0,-1],ArrowDown:[0,1]}[e.key];if(!k)return;
 if(state.step==='frames'&&!entry()?.mirror){e.preventDefault();movePoint(state.point,k[0],k[1],state.frame);changed();}
 if(state.step==='layers'){const l=selectedLayer(),v=l&&kindOf(l)!=='frames'&&layerView(l,state.dir);if(!v)return;e.preventDefault();const d=v.mirrored?MIRROR[state.dir]:state.dir,a=l.anchors[d];l.anchors[d]=[a[0]+(v.mirrored?k[0]:-k[0]),a[1]-k[1]];changed();}});
live.addEventListener('click',e=>{const r=live.getBoundingClientRect(),k=Math.floor((e.clientX-r.left)*(live.width/r.width)/132),dir=DIRS[k];if(dir&&entry(state.action,dir)){state.dir=dir;state.frame=0;render();}});
// ---------- eventos ----------
document.querySelectorAll('.steps button').forEach(b=>b.onclick=()=>{state.step=b.dataset.step;if(state.step==='layers'&&!selectedLayer())state.layer=state.project.layers[0]?.id||null;render();});
$('projectName').onchange=e=>{state.project.name=e.target.value||'Avatar';changed();};
$('onion').onchange=e=>{state.onion=e.target.checked;draw();};$('guides').onchange=e=>{state.guides=e.target.checked;draw();};$('ghosts').onchange=e=>{state.ghosts=e.target.checked;draw();};
$('play').onclick=()=>{state.playing=!state.playing;$('play').setAttribute('aria-pressed',state.playing);$('play').textContent=state.playing?'❚❚ Pausar':'▶ Reproduzir';clearTimeout(timer);if(state.playing)loop();else draw();};
function loop(){tick++;draw();timer=setTimeout(loop,state.project.actions[state.action].ms);}
$('help').onclick=()=>$('helpDialog').showModal();
$('importFrames').onclick=()=>$('fileFrames').click();
$('kaelV1').onclick=async()=>{try{const response=await fetch('art/avatar/kael-v1/kael.avatarstudio.json');if(!response.ok)throw Error('Projeto Kael v1 não encontrado.');await restore(await response.json(),'Kael v1 aberto: corpo base, cabelo e mochila em camadas.');persist();}catch(err){say(err.message);}};
$('fileFrames').onchange=async e=>{const files=[...e.target.files];e.target.value='';try{const cells=await framesFromImages(await readFiles(files));if(!cells.length)return say('Nenhum quadro com pixels visíveis.');await setFrames(cells,`${cells.length} quadros importados em ${ACTIONS[state.action].name} · ${DIR_NAMES[state.dir]}.`);}catch(err){say(err.message);}};
$('preset').onclick=async()=>{try{const list=[];for(let i=0;i<8;i++)list.push({src:toURL(toData(await loadImage(`art/soulgen/keys/kael-frame-test/frames/east-${i}.png`)))});state.project=emptyProject();raw.clear();keyedCache.clear();invalidate();state.action='andar';state.dir='se';
 await setFrames(await framesFromImages(list),'Piloto lateral antigo carregado só para comparação: foi gerado de perfil e com cabelo e mochila no corpo.');}catch{say('Piloto não encontrado: rode a bancada pelo servidor do projeto (npm run studio:avatar).');}};
$('guide').onclick=()=>{const n=ACTIONS[state.action].frames,cols=4,rows=Math.ceil(n/cols),c=document.createElement('canvas');c.width=C*cols;c.height=C*rows;const ctx=c.getContext('2d');ctx.fillStyle='#fff';ctx.fillRect(0,0,c.width,c.height);
 for(let i=0;i<n;i++){const x=(i%cols)*C,y=Math.floor(i/cols)*C;ctx.strokeStyle='#c8ccd2';ctx.strokeRect(x+.5,y+.5,C-1,C-1);guides(ctx,x,y,1);ctx.strokeStyle='rgba(255,79,163,.6)';ctx.beginPath();ctx.ellipse(x+C/2,y+SPEC.eyeLine-6,30,34,0,0,Math.PI*2);ctx.stroke();ctx.fillStyle='#55606c';ctx.font='11px system-ui';ctx.fillText(`${i+1}`,x+6,y+14);}
 c.toBlob(b=>download(b,`guia-${state.action}-${state.dir}.png`));say(`Guia baixada: chão, pivô (vermelho), topo da cabeça e linha dos olhos${ACTIONS[state.action].stairs?' e o próximo degrau':''}.`);};
function promptFor(action,dir){const a=ACTIONS[action],n=a.frames,base=`Sprite sheet de personagem para jogo 2D, estilo da imagem de referência (Kael), mesmo traço, mesma proporção e mesma roupa. ${a.name}, vista ${DIR_NAMES[dir].toLowerCase()} (diagonal da grade isométrica 2:1, 26,57°, vista um pouco de cima), ${n} quadros, em uma grade de 4 colunas × ${Math.ceil(n/4)} linhas de células de 256 × 256 px, exatamente como a guia anexada: pés no ponto vermelho de cada célula, topo da cabeça e linha dos olhos nas linhas tracejadas, mesmo tamanho em todos os quadros.`;
 const end=' Cabeça com cabelo raspado rente, sem penteado e SEM mochila (cabelo e mochila são peças separadas). Use apenas as cores da paleta anexada, sem degradê, sem brilho, sem sombra no chão. Contorno de 2 px na cor #0b1020. Fundo transparente real, sem textos.';
 const move=a.stairs?` Movimento no lugar: o pé de apoio fica no ponto vermelho e o pé que sobe pousa na linha marrom "degrau ${a.stairs==='up'?'+1':'−1'}" da guia (32 px ${a.stairs==='up'?'acima':'abaixo'}); o corpo não anda para fora da célula, o jogo faz isso.`:'';
 return `${base} ${a.tip}${move}${a.loop===false?' Toca uma vez: o último quadro é a pose final, sem voltar ao início.':' Ciclo completo: o último quadro emenda no primeiro.'}${end}`;}
$('promptCopy').onclick=async()=>{const dir=entry()?.mirror?entry().mirror:state.dir,text=promptFor(state.action,dir);try{await navigator.clipboard.writeText(text);say('Pedido copiado. Envie junto com a guia e a folha de modelo.');}catch{prompt('Copie o pedido:',text);}};
const download=(blob,name)=>{const a=document.createElement('a'),u=URL.createObjectURL(blob);a.href=u;a.download=name;document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(u),2000);};
$('save').onclick=()=>{download(new Blob([JSON.stringify({format:'avatar-studio',version:1,rulesVersion:RULES,...state.project})],{type:'application/json'}),slug(state.project.name)+'.avatarstudio.json');say('Projeto salvo com as imagens incorporadas.');};
$('open').onclick=()=>$('fileProject').click();
$('fileProject').onchange=async e=>{const f=e.target.files[0];e.target.value='';if(!f)return;try{await restore(await f.text(),'Projeto aberto.');persist();}catch(err){say(err.message);}};
$('export').onclick=async()=>{
 const name=slug(state.project.name),files=[],bytes=async data=>new Uint8Array(await (await new Promise(ok=>toCanvas(data).toBlob(ok,'image/png'))).arrayBuffer()),report={};
 for(const [id,a] of Object.entries(state.project.actions))for(const [dir,e] of Object.entries(a.dirs)){if(e.mirror||!e.frames?.length)continue;report[`${id}-${dir}`]=auditOf(id,dir).items;
  for(const [i,f] of e.frames.entries())files.push({name:`assets/avatar/${name}/base/${id}-${dir}-${i}.png`,data:await bytes(downscale(keyed(f.src)))});}
 for(const l of state.project.layers){for(const [dir,src] of Object.entries(l.images||{}))files.push({name:`assets/avatar/${name}/camadas/${l.id}-${dir}.png`,data:await bytes(downscale(raw.get(src)))});
  for(const [action,dirs] of Object.entries(l.frames||{}))for(const [dir,list] of Object.entries(dirs))for(const [i,src] of list.entries())if(src)files.push({name:`assets/avatar/${name}/camadas/${l.id}/${action}-${dir}-${i}.png`,data:await bytes(downscale(raw.get(src)))});}
 files.push({name:`assets/avatar/${name}/manifest.json`,data:JSON.stringify(manifest(state.project),null,2)},{name:`assets/avatar/${name}/paleta.json`,data:JSON.stringify(paletteJson(state.project),null,2)});
 const rows=[];for(const id of Object.keys(ACTIONS))for(const dir of DIRS){const n=framesOf(id,dir).length;if(n)rows.push([id,dir,n]);}
 if(rows.length){const cols=Math.max(...rows.map(r=>r[2])),sheet=blank(cols*C/2,rows.length*C/2);rows.forEach(([id,dir,n],r)=>{for(let i=0;i<n;i++){const img=composed(id,dir,i);if(!img)continue;const sm=downscale(img);for(let y=0;y<sm.height;y++)for(let x=0;x<sm.width;x++){const s=(y*sm.width+x)*4,t=((r*C/2+y)*sheet.width+i*C/2+x)*4;for(let j=0;j<4;j++)sheet.data[t+j]=sm.data[s+j];}}});files.push({name:`art/avatar/${name}/previa-aparencia.png`,data:await bytes(sheet)});}
 files.push({name:`art/avatar/${name}/conferencia.json`,data:JSON.stringify(report,null,2)},{name:`art/avatar/${name}/${name}.avatarstudio.json`,data:JSON.stringify({format:'avatar-studio',version:1,rulesVersion:RULES,...state.project})});
 download(new Blob([zip(files)],{type:'application/zip'}),`${name}-avatar.zip`);const fails=Object.values(report).flat().filter(i=>i.level==='fail').length;
 say(`Pacote exportado: ${files.length} arquivos em 1×.${fails?` Atenção: ${fails} reprovação(ões) na conferência.`:''}`);};
// ---------- início ----------
(async()=>{let saved=null;try{saved=localStorage.getItem(STORE);}catch{}
 liveLoop();if(saved){try{await restore(saved,'Projeto recuperado deste navegador.');return;}catch{}}
 render();say('Comece por "Abrir avatar Kael v1" ou importe os desenhos de uma animação. Dúvidas: "? Como funciona".');})();
