import {clusterStats,DRAWN,MIRROR,facing8,RULES,DIRS,DIR_NAMES,SPEC,ACTIONS,SLOTS,VARIANTS,hexToInt,intToHex,blank,keyIndex,quantize,suggestMapping,applyMapping,appearanceRamps,recolor,metrics,autoHead,registerToPivot,mirror,composeFrame,auditFrames,auditHeadLayer,auditFrameLayer,manifest,paletteJson,downscale} from './model.mjs';
import {zip} from './iso-studio/model.mjs';
const $=id=>document.getElementById(id),STORE='avatar-studio:projeto',C=SPEC.cell,PIVOT=SPEC.pivot;
const LAYER_SLOTS={cabelo:'Cabelo (frente)','cabelo-tras':'Cabelo (trás)',acessorio:'Acessório de cabeça',mochila:'Mochila',roupa:'Roupa de modelo'};
const LAYER_COLORS={cabelo:['cabelo','contorno'],'cabelo-tras':['cabelo','contorno'],acessorio:['jaqueta','camiseta','calca','tenis','detalhe','mochila','contorno'],mochila:['mochila','detalhe','contorno'],roupa:['jaqueta','camiseta','calca','detalhe','contorno']};
const emptyProject=()=>({name:'Kael',actions:Object.fromEntries(Object.entries(ACTIONS).map(([id,a])=>[id,{ms:a.ms,dirs:{s:{frames:[]},se:{frames:[]},e:{frames:[]},ne:{frames:[]},n:{frames:[]},w:{mirror:'e'},sw:{mirror:'se'},nw:{mirror:'ne'}}}])),mapping:{clusters:[],assign:[]},slots:structuredClone(SLOTS),appearance:{},layers:[]});
const state={project:emptyProject(),step:'frames',action:'andar',dir:'e',frame:0,playing:false,onion:true,guides:true,layer:null};
const raw=new Map(),keyedCache=new Map();let looksSeed=1,timer=null,tick=0;
const say=t=>{$('message').textContent=t;};
const slug=t=>String(t).normalize('NFD').replace(/[̀-ͯ]/g,'').toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'')||'avatar';
// ---------- imagens ----------
const loadImage=src=>new Promise((ok,err)=>{const i=new Image();i.onload=()=>ok(i);i.onerror=()=>err(Error('PNG inválido.'));i.src=src;});
function toData(img,w=img.naturalWidth||img.width,h=img.naturalHeight||img.height,sx=0,sy=0){const c=document.createElement('canvas');c.width=w;c.height=h;const g=c.getContext('2d');g.drawImage(img,sx,sy,w,h,0,0,w,h);const d=g.getImageData(0,0,w,h);return {width:w,height:h,data:d.data};}
function toCanvas(data){const c=document.createElement('canvas');c.width=data.width;c.height=data.height;c.getContext('2d').putImageData(new ImageData(new Uint8ClampedArray(data.data),data.width,data.height),0,0);return c;}
const toURL=data=>toCanvas(data).toDataURL('image/png');
async function ensureRaw(){for(const src of allSources())if(!raw.has(src))raw.set(src,toData(await loadImage(src)));}
function allSources(){const out=[];for(const a of Object.values(state.project.actions))for(const d of Object.values(a.dirs))for(const f of d.frames||[])out.push(f.src);for(const l of state.project.layers)for(const v of Object.values(l.images||{}))out.push(v);for(const l of state.project.layers)for(const a of Object.values(l.frames||{}))for(const list of Object.values(a))for(const v of list)if(v)out.push(v);return out;}
function keyed(src){if(keyedCache.has(src))return keyedCache.get(src);const r=raw.get(src);if(!r)return null;const m=state.project.mapping,out=m.clusters.length?applyMapping(r,m.clusters,m.assign,state.project.slots):r;keyedCache.set(src,out);return out;}
// Camadas novas vão direto para as cores-chave dos grupos permitidos.
function keyLayer(data,slot){const allowed=LAYER_COLORS[slot],slots=state.project.slots.filter(s=>!allowed||allowed.includes(s.id)),clusters=[],assign=[];for(const s of slots)s.tones.forEach((t,tone)=>{clusters.push({color:hexToInt(t)});assign.push({slot:s.id,tone});});return applyMapping(data,clusters,assign,state.project.slots);}
// ---------- acesso ----------
const entry=(action=state.action,dir=state.dir)=>state.project.actions[action].dirs[dir];
function framesOf(action=state.action,dir=state.dir){const e=entry(action,dir);if(e?.mirror){const src=entry(action,e.mirror);return (src.frames||[]).map(f=>({...f,mirrored:true,head:f.head?[C-1-f.head[0],f.head[1]]:null}));}return e?.frames||[];}
function baseImage(f){const k=keyed(f.src);return k&&f.mirrored?mirror(k):k;}
const layersFor=(dir,action,i)=>state.project.layers.filter(l=>l.on!==false).map(l=>{const m=MIRROR[dir];
 if(l.kind==='head'){const own=l.images?.[dir],src=own||(m&&l.mirror!==false?l.images?.[m]:null);if(!src||!raw.get(src))return null;const img=own?raw.get(own):mirror(raw.get(src)),a=own?l.anchors?.[dir]:l.anchors?.[m]&&[img.width-1-l.anchors[m][0],l.anchors[m][1]];return a?{kind:'head',slot:l.slot,image:img,anchor:a}:null;}
 const own=l.frames?.[action]?.[dir],list=own||(m&&l.frames?.[action]?.[m]),src=list?.[i];if(!src||!raw.get(src))return null;return {kind:'frames',slot:l.slot,image:own?raw.get(src):mirror(raw.get(src))};}).filter(Boolean);
function composed(action,dir,i,ramps){const f=framesOf(action,dir)[i];if(!f)return null;const base=baseImage(f);if(!base)return null;return composeFrame({base,head:f.head||[C/2,SPEC.eyeLine],dir,layers:layersFor(dir,action,i),ramps,slots:state.project.slots});}
// ---------- persistência ----------
function persist(){try{localStorage.setItem(STORE,JSON.stringify(state.project));}catch{/* sem espaço: o projeto continua na sessão */}}
function changed(text,{remap=false}={}){if(remap)keyedCache.clear();persist();render();if(text)say(text);}
async function restore(json,text){const data=typeof json==='string'?JSON.parse(json):json;if(!data?.actions||!data?.mapping)throw Error('Arquivo não é um projeto do Avatar Studio.');const base=emptyProject();
 state.project={...base,...data,actions:Object.fromEntries(Object.keys(base.actions).map(id=>[id,{...base.actions[id],...data.actions?.[id],dirs:{...base.actions[id].dirs,...data.actions?.[id]?.dirs}}])),slots:data.slots||base.slots,layers:data.layers||[]};raw.clear();keyedCache.clear();await ensureRaw();pickExisting();render();if(text)say(text);}
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
async function setFrames(cells,text){const dir=state.dir,list=cells.map(c=>({src:toURL(c),head:null}));state.project.actions[state.action].dirs[dir]={frames:list};
 for(const f of list)raw.set(f.src,toData(await loadImage(f.src)));if(!state.project.mapping.clusters.length)remapAll();else keyedCache.clear();autoHeads(state.action,dir);state.frame=0;changed(text);}
function remapAll(k=24){const imgs=allSources().filter(s=>!isLayerSource(s)).map(s=>raw.get(s)).filter(Boolean);if(!imgs.length)return;const clusters=quantize(imgs,k);state.project.mapping={clusters:clusters.map(c=>({color:c.color,count:c.count})),assign:suggestMapping(clusters,state.project.slots,clusterStats(imgs,clusters))};keyedCache.clear();}
const isLayerSource=src=>state.project.layers.some(l=>Object.values(l.images||{}).includes(src)||Object.values(l.frames||{}).some(a=>Object.values(a).some(list=>list.includes(src))));
function autoHeads(action,dir,force=true){for(const f of entry(action,dir).frames||[]){if(f.head&&!force)continue;const k=keyed(f.src);if(k)f.head=autoHead(k,state.project.slots);}}
// ---------- desenho ----------
const stage=$('stage'),g=stage.getContext('2d');
function checker(ctx,x,y,w,h,s=8){ctx.fillStyle='#ece7db';ctx.fillRect(x,y,w,h);ctx.fillStyle='#e0dacb';for(let yy=0;yy<h;yy+=s)for(let xx=(yy/s)%2?s:0;xx<w;xx+=s*2)ctx.fillRect(x+xx,y+yy,Math.min(s,w-xx),Math.min(s,h-yy));}
function guides(ctx,x,y,Z){ctx.save();ctx.lineWidth=1;ctx.strokeStyle='rgba(30,120,200,.55)';const line=(x0,y0,x1,y1)=>{ctx.beginPath();ctx.moveTo(x+x0*Z+.5,y+y0*Z+.5);ctx.lineTo(x+x1*Z+.5,y+y1*Z+.5);ctx.stroke();};
 line(0,PIVOT[1],C,PIVOT[1]);ctx.setLineDash([4,4]);line(0,SPEC.eyeLine,C,SPEC.eyeLine);line(0,PIVOT[1]-SPEC.height,C,PIVOT[1]-SPEC.height);line(PIVOT[0],0,PIVOT[0],C);ctx.setLineDash([]);
 ctx.fillStyle='#e0262f';ctx.fillRect(x+PIVOT[0]*Z-3,y+PIVOT[1]*Z-3,6,6);ctx.restore();}
function headMark(ctx,x,y,Z,head){if(!head)return;ctx.save();ctx.strokeStyle='#ff4fa3';ctx.lineWidth=2;ctx.beginPath();ctx.arc(x+head[0]*Z,y+head[1]*Z,7,0,Math.PI*2);ctx.stroke();ctx.beginPath();ctx.moveTo(x+head[0]*Z-11,y+head[1]*Z);ctx.lineTo(x+head[0]*Z+11,y+head[1]*Z);ctx.moveTo(x+head[0]*Z,y+head[1]*Z-11);ctx.lineTo(x+head[0]*Z,y+head[1]*Z+11);ctx.stroke();ctx.restore();}
const fit=(need,max)=>Math.max(.5,Math.min(max,($('viewport').clientWidth-48)/need));
function size(w,h){stage.width=w;stage.height=h;stage.style.width=w+'px';stage.style.height=h+'px';g.imageSmoothingEnabled=false;}
function drawFrames(){
 const frames=framesOf(),i=state.playing?tick%Math.max(1,frames.length):state.frame,f=frames[i],Z=2;size(C*Z+40,C*Z+40);g.fillStyle='#0c161e';g.fillRect(0,0,stage.width,stage.height);checker(g,20,20,C*Z,C*Z);
 if(!f){g.fillStyle='#203b3c';g.font='600 15px system-ui';g.fillText('Sem quadros nesta direção.',40,60);g.font='13px system-ui';g.fillText('Importe PNGs ou abra o piloto do Kael.',40,84);if(state.guides)guides(g,20,20,Z);return;}
 if(state.onion&&!state.playing&&frames.length>1){const p=baseImage(frames[(i-1+frames.length)%frames.length]);if(p){g.globalAlpha=.25;g.drawImage(toCanvas(p),20,20,C*Z,C*Z);g.globalAlpha=1;}}
 const img=composed(state.action,state.dir,i,appearanceRamps(state.project.slots,state.project.appearance));if(img)g.drawImage(toCanvas(img),20,20,C*Z,C*Z);
 if(state.guides)guides(g,20,20,Z);headMark(g,20,20,Z,f.head);
}
function drawPalette(){
 const f=framesOf()[state.frame],Z=fit(C*2+60,2);size(C*Z*2+60,C*Z+60);g.fillStyle='#0c161e';g.fillRect(0,0,stage.width,stage.height);checker(g,20,40,C*Z,C*Z);checker(g,C*Z+40,40,C*Z,C*Z);
 g.fillStyle='#afc0c6';g.font='600 12px system-ui';g.fillText('Original',20,28);g.fillText('Nas cores-chave (fora da paleta em vermelho)',C*Z+40,28);if(!f)return;
 const r=raw.get(f.src),k=keyed(f.src);if(r)g.drawImage(toCanvas(f.mirrored?mirror(r):r),20,40,C*Z,C*Z);
 if(k){const show=f.mirrored?mirror(k):k,marked=blank(C,C);marked.data.set(show.data);for(let p=0;p<marked.data.length;p+=4)if(marked.data[p+3]===254){marked.data[p]=255;marked.data[p+1]=30;marked.data[p+2]=60;marked.data[p+3]=255;}g.drawImage(toCanvas(marked),C*Z+40,40,C*Z,C*Z);}
}
function drawLayers(){
 const Z=fit(C*4+80,1.2),dirs=DIRS,pad=16;size((C*Z+pad)*4+pad,(C*Z+pad+20)*2+pad);g.fillStyle='#0c161e';g.fillRect(0,0,stage.width,stage.height);
 dirs.forEach((dir,k)=>{const x=pad+(k%4)*(C*Z+pad),y=pad+20+Math.floor(k/4)*(C*Z+pad+20);checker(g,x,y,C*Z,C*Z);g.fillStyle='#afc0c6';g.font='600 12px system-ui';g.fillText(DIR_NAMES[dir],x,y-6);
  const frames=framesOf(state.action,dir),i=state.playing?tick%Math.max(1,frames.length):0,img=composed(state.action,dir,i,appearanceRamps(state.project.slots,state.project.appearance));if(img)g.drawImage(toCanvas(img),x,y,C*Z,C*Z);
  if(!state.playing&&frames[i])headMark(g,x,y,Z,frames[i].head);});
}
function drawLook(){
 const looks=lookList(),pad=12,cols=4,Z=fit(C*cols+pad*(cols+1),1),rows=Math.ceil(looks.length/cols)*1;size((C*Z+pad)*cols+pad,(C*Z+pad)*rows*2+pad);g.fillStyle='#0c161e';g.fillRect(0,0,stage.width,stage.height);
 looks.forEach((look,k)=>{const ramps=appearanceRamps(state.project.slots,look);['se','ne'].forEach((dir,j)=>{const x=pad+(k%cols)*(C*Z+pad),y=pad+(Math.floor(k/cols)*2+j)*(C*Z+pad);checker(g,x,y,C*Z,C*Z);
  const frames=framesOf(state.action,dir).length?framesOf(state.action,dir):framesOf(state.action,'e'),d=framesOf(state.action,dir).length?dir:'e',img=composed(state.action,d,tick%Math.max(1,frames.length),ramps);if(img)g.drawImage(toCanvas(img),x,y,C*Z,C*Z);});});
}
function lookList(){const out=[state.project.appearance];let s=looksSeed;const rnd=()=>{s=(s*16807)%2147483647;return s/2147483647;};for(let i=0;i<7;i++){const look={};for(const [slot,list] of Object.entries(VARIANTS))look[slot]=Math.floor(rnd()*list.length);out.push(look);}return out;}
function draw(){({frames:drawFrames,palette:drawPalette,layers:drawLayers,look:drawLook})[state.step]();}
// ---------- interface ----------
function render(){
 document.body.dataset.step=state.step;document.querySelectorAll('.steps button').forEach(b=>b.setAttribute('aria-current',b.dataset.step===state.step?'step':'false'));
 $('projectName').value=state.project.name;
 const tree=$('actionTree');tree.replaceChildren(...Object.entries(ACTIONS).map(([id,a])=>{const box=document.createElement('div'),h=document.createElement('h3'),row=document.createElement('div');h.textContent=`${a.name} · ${a.frames} quadros`;row.className='dirs';
  for(const dir of DIRS){const b=document.createElement('button'),e=state.project.actions[id].dirs[dir],n=framesOf(id,dir).length;b.innerHTML=`${dir.toUpperCase()}<small></small>`;b.querySelector('small').textContent=e?.mirror?(n?'espelho':'—'):n?`${n} q`:'—';
   b.title=`${a.name} · ${DIR_NAMES[dir]}`;b.setAttribute('aria-current',id===state.action&&dir===state.dir);if(n)b.dataset.state=verdict(auditOf(id,dir).items);b.onclick=()=>{state.action=id;state.dir=dir;state.frame=0;render();};row.append(b);}
  box.append(h,row);return box;}));
 const frames=framesOf();$('stageTitle').textContent=`${ACTIONS[state.action].name} · ${DIR_NAMES[state.dir]}`;
 $('stageSub').textContent=entry().mirror?`Espelho de ${DIR_NAMES[entry().mirror]} · ${frames.length} quadros`:`${frames.length} de ${ACTIONS[state.action].frames} quadros · ${state.project.actions[state.action].ms} ms cada`;
 const strip=$('strip');strip.replaceChildren(...frames.map((f,i)=>{const b=document.createElement('button'),c=document.createElement('canvas');c.width=C;c.height=C;const img=baseImage(f);if(img)c.getContext('2d').putImageData(new ImageData(new Uint8ClampedArray(img.data),C,C),0,0);b.append(c);b.title=`Quadro ${i}`;b.setAttribute('aria-current',i===state.frame);b.onclick=()=>{state.frame=i;render();};return b;}));
 inspector();const counts=Object.values(state.project.actions).reduce((s,a)=>s+Object.values(a.dirs).reduce((t,d)=>t+(d.frames?.length||0),0),0);$('summary').textContent=`${counts} quadros desenhados · ${state.project.layers.length} camadas`;
 draw();
}
const verdict=items=>items.some(i=>i.level==='fail')?'fail':items.some(i=>i.level==='warn')?'warn':'ok';
function auditOf(action,dir){const frames=framesOf(action,dir).map(f=>({image:baseImage(f),head:f.head})).filter(f=>f.image);const out=auditFrames(frames,{slots:state.project.slots});
 if(frames.length&&!state.project.mapping.clusters.length)out.items.unshift({level:'fail',rule:'Paleta',text:'Paleta ainda não mapeada.'});
 const want=ACTIONS[action].frames;if(frames.length&&frames.length!==want)out.items.push({level:'warn',rule:'Quadros',text:`${frames.length} quadros; a especificação pede ${want}.`});
 for(const l of state.project.layers.filter(x=>x.on!==false)){const live=layersFor(dir,action,0).find(x=>x.slot===l.slot),f=framesOf(action,dir)[0];if(!live||!f)continue;
  if(live.kind==='head')out.items.push({...auditHeadLayer(baseImage(f),f.head||[C/2,SPEC.eyeLine],live),text:`${l.name}: `+auditHeadLayer(baseImage(f),f.head||[C/2,SPEC.eyeLine],live).text});
  else out.items.push({...auditFrameLayer(baseImage(f),live.image),text:`${l.name}: `+auditFrameLayer(baseImage(f),live.image).text});}
 return out;}
function el(tag,props={},...kids){const e=Object.assign(document.createElement(tag),props);e.append(...kids);return e;}
function button(text,fn,cls){const b=el('button',{textContent:text,className:cls||''});b.onclick=fn;return b;}
function auditList(items){return items.map(i=>{const li=el('li');li.dataset.level=i.level;li.append(el('b',{textContent:i.rule||''}),el('span',{textContent:i.text}));return li;});}
function inspector(){
 const box=$('inspector'),f=framesOf()[state.frame];box.replaceChildren();
 if(state.step==='frames'){$('inspEyebrow').textContent='QUADRO';$('inspTitle').textContent=f?`Quadro ${state.frame} de ${framesOf().length}`:'Sem quadro';
  box.append(el('p',{className:'muted',textContent:'Clique na imagem para marcar a âncora da cabeça (centro do crânio, na linha dos olhos). Setas movem a âncora 1 px.'}));
  if(f){const m=metrics(baseImage(f));box.append(el('p',{className:'box-info',textContent:`apoio y=${m.baseline} (pivô ${PIVOT[1]}) · altura ${m.bounds?.h||0} px · cabeça ${f.head?f.head.join(', '):'—'}`}));}
  const row=el('div',{className:'row'});if(!entry().mirror&&framesOf().length){row.append(button('Âncoras automáticas',()=>{autoHeads(state.action,state.dir);changed('Âncoras recalculadas pelo rosto (ou cabelo, nas costas). Confira quadro a quadro.');}),button('Registrar pés no pivô',()=>registerAll()),button('Excluir quadro',()=>{entry().frames.splice(state.frame,1);state.frame=Math.max(0,state.frame-1);changed('Quadro excluído.');},'danger'));}
  const m=MIRROR[state.dir];if(m)row.append(button(entry().mirror?`Desenhar ${state.dir.toUpperCase()} próprio`:`Voltar a espelhar ${m.toUpperCase()}`,()=>{const e=state.project.actions[state.action].dirs;e[state.dir]=e[state.dir]?.mirror?{frames:[]}:{mirror:m};changed(e[state.dir].mirror?`${DIR_NAMES[state.dir]} espelha ${DIR_NAMES[m]}.`:'Sem espelho: importe os quadros próprios (camada assimétrica).');}));
  box.append(row,el('label',{},'Duração do quadro (ms)',(()=>{const i=el('input',{type:'number',min:40,max:500,step:10,value:state.project.actions[state.action].ms});i.onchange=()=>{state.project.actions[state.action].ms=Math.max(40,Number(i.value)||100);changed();};return i;})()));
 }
 if(state.step==='palette'){$('inspEyebrow').textContent='PALETA';$('inspTitle').textContent='Cores da arte → cores-chave';
  const m=state.project.mapping;box.append(el('p',{className:'muted',textContent:'Cada cor agrupada da arte recebe um grupo e um tom. A sugestão é a cor-chave mais próxima: confira pele × cabelo × contorno, que a IA costuma misturar.'}));
  const k=el('input',{type:'number',min:6,max:48,value:m.clusters.length||24});box.append(el('div',{className:'row'},el('label',{className:'grow'},'Cores agrupadas',k),button('Reagrupar',()=>{remapAll(Number(k.value)||24);for(const a of Object.keys(ACTIONS))for(const d of DIRS)if(entry(a,d)?.frames?.length)autoHeads(a,d,false);changed('Cores reagrupadas e sugeridas de novo.');})));
  const list=el('div',{className:'swatches'}),options=[['','— sem grupo —'],...state.project.slots.flatMap(s=>s.tones.map((t,i)=>[`${s.id}:${i}`,`${s.name} ${i+1}`]))];
  m.clusters.forEach((c,i)=>{const sel=el('select');options.forEach(([v,t])=>sel.append(el('option',{value:v,textContent:t})));const a=m.assign[i];sel.value=a?`${a.slot}:${a.tone}`:'';
   sel.onchange=()=>{const [slot,tone]=sel.value.split(':');m.assign[i]=slot?{slot,tone:Number(tone)}:null;changed(null,{remap:true});};
   const target=a?state.project.slots.find(s=>s.id===a.slot)?.tones[a.tone]:'transparent';list.append(el('div',{className:'swatch'},el('i',{style:`background:${intToHex(c.color)}`}),el('i',{style:`background:${target}`}),sel,el('small',{textContent:c.count})));});
  box.append(list,el('h3',{textContent:'Rampas-chave'}),...state.project.slots.map(s=>el('div',{className:'ramp'},el('span',{textContent:s.name}),...s.tones.map(t=>el('i',{style:`background:${t}`,title:t})))));
 }
 if(state.step==='layers'){$('inspEyebrow').textContent='CAMADAS';$('inspTitle').textContent='Cabelo, acessórios e roupa';
  box.append(el('p',{className:'muted',textContent:'Camada de cabeça: uma imagem por direção, presa à âncora. Clique na prévia da direção para marcar o ponto da camada que vai no centro do crânio. Roupa de modelo: um PNG por quadro, mesmo tamanho do quadro.'}));
  const kind=el('select');Object.entries(LAYER_SLOTS).forEach(([v,t])=>kind.append(el('option',{value:v,textContent:t})));box.append(el('div',{className:'row'},el('label',{className:'grow'},'Nova camada',kind),button('+ Camada',()=>{const id=slug(LAYER_SLOTS[kind.value])+'-'+(state.project.layers.length+1);state.project.layers.push({id,name:LAYER_SLOTS[kind.value],slot:kind.value,kind:kind.value==='roupa'?'frames':'head',images:{},anchors:{},frames:{},mirror:true,on:true});state.layer=id;changed('Camada criada: importe as imagens.');})));
  for(const l of state.project.layers){const card=el('div',{className:'layer-card'}),name=el('input',{value:l.name});name.onchange=()=>{l.name=name.value;changed();};
   const on=el('input',{type:'checkbox',checked:l.on!==false});on.onchange=()=>{l.on=on.checked;changed();};
   const dirs=el('div',{className:'dirs'});for(const dir of l.kind==='head'?DIRS:[state.dir]){const has=l.kind==='head'?!!l.images[dir]:!!l.frames?.[state.action]?.[dir]?.[state.frame];const b=button(`${dir.toUpperCase()}`,()=>pickLayerFile(l,dir));b.append(el('small',{textContent:has?'✓':l.kind==='head'&&MIRROR[dir]&&l.mirror!==false?'espelho':'+'}));dirs.append(b);}
   card.append(el('div',{className:'row'},el('label',{className:'inline'},on,' Ativa'),button('Excluir',()=>{state.project.layers=state.project.layers.filter(x=>x!==l);changed('Camada excluída.');},'danger')),el('label',{},'Nome',name),el('small',{className:'muted',textContent:l.kind==='head'?'Imagem por direção (clique para importar):':`PNG do quadro ${state.frame} de ${ACTIONS[state.action].name} · ${DIR_NAMES[state.dir]}:`}),dirs);
   if(l.kind==='head')card.append(el('label',{className:'inline'},(()=>{const c=el('input',{type:'checkbox',checked:l.mirror!==false});c.onchange=()=>{l.mirror=c.checked;changed();};return c;})(),' Esquerdas espelham direitas'));
   box.append(card);}
 }
 if(state.step==='look'){$('inspEyebrow').textContent='APARÊNCIA';$('inspTitle').textContent='Trocar cores sem arte nova';
  for(const s of state.project.slots.filter(x=>VARIANTS[x.id])){const sel=el('select');VARIANTS[s.id].forEach(([n],i)=>sel.append(el('option',{value:i,textContent:n})));sel.value=state.project.appearance[s.id]||0;sel.onchange=()=>{state.project.appearance[s.id]=Number(sel.value);changed();};box.append(el('label',{},s.name,sel));}
  box.append(el('div',{className:'row'},button('Outras 7 aparências',()=>{looksSeed=(looksSeed*48271)%2147483647||7;draw();}),button('Usar a primeira sorteada',()=>{state.project.appearance={...lookList()[1]};changed('Aparência aplicada.');})),el('p',{className:'muted',textContent:'A primeira coluna é a aparência escolhida; as outras são sorteadas para conferir se nenhuma troca de cor vaza para outro grupo.'}));
 }
 const all=[];for(const a of Object.keys(ACTIONS))for(const d of DIRS)if(framesOf(a,d).length&&!(entry(a,d).mirror)){const r=auditOf(a,d);for(const i of r.items)all.push({...i,text:`${ACTIONS[a].name} ${d.toUpperCase()}: ${i.text}`});}
 const here=framesOf().length?auditOf(state.action,state.dir).items:[{level:'info',rule:'—',text:'Sem quadros nesta direção.'}];
 $('audit').replaceChildren(...auditList(state.step==='look'?(all.length?all:here):here));
}
function pickLayerFile(l,dir){state.layer=l.id;state.layerDir=dir;$('fileLayer').click();}
$('fileLayer').onchange=async e=>{const file=e.target.files[0];e.target.value='';const l=state.project.layers.find(x=>x.id===state.layer);if(!file||!l)return;const [{src}]=await readFiles([file]),img=await loadImage(src);let data=keyLayer(toData(img),l.slot);
 if(l.kind==='head'){const m=metrics(data),url=toURL(data);l.images[state.layerDir]=url;raw.set(url,data);l.anchors[state.layerDir]=m.bounds?[Math.round(m.bounds.x+m.bounds.w/2),Math.round(m.bounds.y+m.bounds.h*.7)]:[0,0];say('Camada importada nas cores-chave. Clique na prévia desta direção para acertar o ponto que vai no centro do crânio.');}
 else{if(data.width!==C||data.height!==C)return say(`Roupa precisa ter ${C}×${C}, como o quadro.`);const url=toURL(data);raw.set(url,data);((l.frames[state.action]??={})[state.layerDir]??=[])[state.frame]=url;say('Quadro da roupa importado.');}
 changed();};
function registerAll(){const e=entry();let moved=0;e.frames=e.frames.map(f=>{const r=registerToPivot(raw.get(f.src));if(!r.dy)return f;moved++;const src=toURL(r.img);raw.set(src,r.img);return {src,head:f.head?[f.head[0],f.head[1]+r.dy]:null};});keyedCache.clear();changed(moved?`${moved} quadro(s) deslocado(s) para o pé cair no pivô.`:'Todos os quadros já estão no pivô.');}
// ---------- eventos ----------
document.querySelectorAll('.steps button').forEach(b=>b.onclick=()=>{state.step=b.dataset.step;render();});
$('projectName').onchange=e=>{state.project.name=e.target.value||'Avatar';changed();};
$('onion').onchange=e=>{state.onion=e.target.checked;draw();};$('guides').onchange=e=>{state.guides=e.target.checked;draw();};
$('play').onclick=()=>{state.playing=!state.playing;$('play').setAttribute('aria-pressed',state.playing);$('play').textContent=state.playing?'❚❚ Pausar':'▶ Reproduzir';clearTimeout(timer);if(state.playing)loop();else draw();};
function loop(){tick++;draw();timer=setTimeout(loop,state.project.actions[state.action].ms);}
stage.addEventListener('pointerdown',e=>{const r=stage.getBoundingClientRect(),x=e.clientX-r.left,y=e.clientY-r.top;
 if(state.step==='frames'){const f=entry().frames?.[state.frame];if(!f||entry().mirror)return say(entry().mirror?'Este quadro é espelho: marque a âncora na direção original.':'');f.head=[Math.round((x-20)/2),Math.round((y-20)/2)];changed('Âncora da cabeça marcada.');}
 if(state.step==='layers'){const Z=fit(C*4+80,1.2),pad=16,col=Math.floor((x-pad)/(C*Z+pad)),row=Math.floor((y-pad)/(C*Z+pad+20)),k=row*4+col,dir=DIRS[k],l=state.project.layers.find(x=>x.id===state.layer)||state.project.layers.find(x=>x.kind==='head');if(!dir||!l||l.kind!=='head'||!l.images[dir])return;
  const f=framesOf(state.action,dir)[0];if(!f?.head)return;const px=(x-pad-col*(C*Z+pad))/Z,py=(y-pad-20-row*(C*Z+pad+20))/Z;l.anchors[dir]=[Math.round(l.anchors[dir][0]+(f.head[0]-px)),Math.round(l.anchors[dir][1]+(f.head[1]-py))];changed('Camada reposicionada: o ponto clicado agora fica sobre a âncora da cabeça.');}});
document.addEventListener('keydown',e=>{if(state.step!=='frames'||e.target.matches('input,select,textarea'))return;const k={ArrowLeft:[-1,0],ArrowRight:[1,0],ArrowUp:[0,-1],ArrowDown:[0,1]}[e.key];if(!k){if(e.key===','||e.key==='.'){const n=framesOf().length;if(n){state.frame=(state.frame+(e.key==='.'?1:-1)+n)%n;render();}}return;}
 const f=entry().frames?.[state.frame];if(!f?.head)return;e.preventDefault();f.head=[f.head[0]+k[0],f.head[1]+k[1]];changed();});
$('importFrames').onclick=()=>$('fileFrames').click();
$('fileFrames').onchange=async e=>{const files=[...e.target.files];e.target.value='';try{const cells=await framesFromImages(await readFiles(files));if(!cells.length)return say('Nenhum quadro com pixels visíveis.');await setFrames(cells,`${cells.length} quadros importados em ${ACTIONS[state.action].name} · ${DIR_NAMES[state.dir]}.`);}catch(err){say(err.message);}};
$('preset').onclick=async()=>{try{const list=[];for(let i=0;i<8;i++)list.push({src:toURL(toData(await loadImage(`art/soulgen/keys/kael-frame-test/frames/east-${i}.png`)))});state.project=emptyProject();raw.clear();keyedCache.clear();state.action='andar';state.dir='e';
 await setFrames(await framesFromImages(list),'Piloto do Kael carregado: andar · direita. Cabelo e mochila estão no corpo base porque o piloto foi gerado assim; confira a paleta na etapa 02.');}catch{say('Piloto não encontrado: rode a bancada pelo servidor do projeto (npm run studio:avatar).');}};
$('guide').onclick=()=>{const n=ACTIONS[state.action].frames,cols=4,rows=Math.ceil(n/cols),c=document.createElement('canvas');c.width=C*cols;c.height=C*rows;const ctx=c.getContext('2d');ctx.fillStyle='#fff';ctx.fillRect(0,0,c.width,c.height);
 for(let i=0;i<n;i++){const x=(i%cols)*C,y=Math.floor(i/cols)*C;ctx.strokeStyle='#c8ccd2';ctx.strokeRect(x+.5,y+.5,C-1,C-1);guides(ctx,x,y,1);ctx.strokeStyle='rgba(255,79,163,.6)';ctx.beginPath();ctx.ellipse(x+C/2,y+SPEC.eyeLine-6,30,34,0,0,Math.PI*2);ctx.stroke();ctx.fillStyle='#55606c';ctx.font='11px system-ui';ctx.fillText(`${i+1}`,x+6,y+14);}
 c.toBlob(b=>download(b,`guia-${state.action}-${state.dir}.png`));say('Guia baixada: chão (linha cheia), pivô (vermelho), topo da cabeça e linha dos olhos (tracejadas).');};
$('promptCopy').onclick=async()=>{const a=ACTIONS[state.action],n=a.frames,text=`Sprite sheet de personagem para jogo 2D, estilo da imagem de referência (Kael), mesmo traço, mesma proporção e mesma roupa. ${a.name}, vista ${DIR_NAMES[state.dir].toLowerCase()}${state.dir.length===2?' (diagonal da grade isométrica 2:1, 26,57°, vista um pouco de cima)':''}, ${n} quadros, em uma grade de 4 colunas × ${Math.ceil(n/4)} linhas de células de 256 × 256 px, exatamente como a guia anexada: pés no ponto vermelho de cada célula, topo da cabeça e linha dos olhos nas linhas tracejadas, mesmo tamanho em todos os quadros. ${state.action==='andar'?'Quadro 1 = pé da frente tocando o chão; ciclo completo, o último quadro emenda no primeiro.':'Ciclo completo, o último quadro emenda no primeiro.'} Cabeça com cabelo raspado rente, sem penteado. Use apenas as cores da paleta anexada, sem degradê, sem brilho, sem sombra no chão. Contorno de 2 px na cor #0b1020. Fundo transparente real, sem textos.`;
 try{await navigator.clipboard.writeText(text);say('Pedido copiado. Envie junto com a guia de quadros e a folha de modelo.');}catch{prompt('Copie o pedido:',text);}};
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
 // Prévia: folha da aparência atual, para revisão.
 const ramps=appearanceRamps(state.project.slots,state.project.appearance),rows=[];for(const id of Object.keys(ACTIONS))for(const dir of DIRS){const n=framesOf(id,dir).length;if(n)rows.push([id,dir,n]);}
 if(rows.length){const cols=Math.max(...rows.map(r=>r[2])),sheet=blank(cols*C/2,rows.length*C/2);rows.forEach(([id,dir,n],r)=>{for(let i=0;i<n;i++){const img=composed(id,dir,i,ramps);if(!img)continue;const small=downscale(img);for(let y=0;y<small.height;y++)for(let x=0;x<small.width;x++){const s=(y*small.width+x)*4,t=((r*C/2+y)*sheet.width+i*C/2+x)*4;for(let j=0;j<4;j++)sheet.data[t+j]=small.data[s+j];}}});files.push({name:`art/avatar/${name}/previa-aparencia.png`,data:await bytes(sheet)});}
 files.push({name:`art/avatar/${name}/conferencia.json`,data:JSON.stringify(report,null,2)},{name:`art/avatar/${name}/${name}.avatarstudio.json`,data:JSON.stringify({format:'avatar-studio',version:1,rulesVersion:RULES,...state.project})});
 download(new Blob([zip(files)],{type:'application/zip'}),`${name}-avatar.zip`);const fails=Object.values(report).flat().filter(i=>i.level==='fail').length;
 say(`Pacote exportado: ${files.length} arquivos em 1×.${fails?` Atenção: ${fails} reprovação(ões) na conferência.`:''}`);};
// ---------- início ----------
(async()=>{let saved=null;try{saved=localStorage.getItem(STORE);}catch{}
 if(saved){try{await restore(saved,'Projeto recuperado deste navegador.');return;}catch{}}
 render();say('Comece por "Abrir piloto do Kael" ou importe os quadros de uma animação.');})();
