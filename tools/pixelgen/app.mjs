import {settings, pixels, audit, serialize, validateProject} from './core.mjs';
import {aseprite} from './aseprite.mjs';
import {duration,sequencesFor,duplicateFrame,atlas as animationAtlas} from './animation.mjs';
const $=id=>document.getElementById(id),editor=$('editor'),ctx=editor.getContext('2d');
const fields=['cols','rows','width','height','colors','margin','alpha','tolerance','specks','background','sample','align','x','y','cropWidth','cropHeight'];
let project=null,source=null,sourceCanvas=null,sourceUrl=null,selected=0,colorIndex=1,tool='brush',view='pixel',worker=null;
let undo=[],redo=[],drawing=false,lastPoint=null,playTimer=null,saveTimer=null,saveWarning=false,sequenceIndex=0,playing=false;
const status=text=>{$('status').textContent=text;};
const hex=c=>'#'+c.slice(0,3).map(v=>v.toString(16).padStart(2,'0')).join('');
const copy=p=>({...p,sequences:p.sequences?.map(s=>({...s})),palette:p.palette.map(c=>[...c]),frames:p.frames.map(f=>({...f,indices:f.indices.slice()}))});
const busy=value=>{$('busy').hidden=!value;$('convert').disabled=value;$('convert').textContent=value?'Convertendo…':'Converter para a grade →';};
const safeName=()=>($('projectName').value||'pixelgen').normalize('NFKD').replace(/[^a-zA-Z0-9_-]+/g,'-').slice(0,70);
function checkpoint(){if(!project)return;undo.push(copy(project));if(undo.length>20)undo.shift();redo=[];}
function persist(){
 clearTimeout(saveTimer);saveTimer=setTimeout(()=>{if(!project)return;try{localStorage.setItem('pixelgen-project-v1',JSON.stringify(serialize({...project,name:$('projectName').value})));}
 catch{if(!saveWarning){status('Projeto grande para a gravação do navegador. Use Salvar projeto para guardar uma cópia.');saveWarning=true;}}},350);
}
function changed(all=false){if(!project)return;project.name=$('projectName').value;renderEditor();if(all)renderFrames();else renderThumb(selected);renderAudit();persist();}
function readSettings(){return settings(Object.fromEntries(fields.map(k=>[k,$(k).value])));}
function applySettings(s){for(const k of fields)if(s?.[k]!==undefined)$(k).value=s[k];}
function stop(){clearTimeout(playTimer);playTimer=null;playing=false;$('play').textContent='▷ Reproduzir';}
function sequence(){return sequencesFor(project)[sequenceIndex]||sequencesFor(project)[0];}
function renderSequence(){
 const list=sequencesFor(project);sequenceIndex=Math.max(0,Math.min(sequenceIndex,list.length-1));$('sequence').replaceChildren();
 list.forEach((s,i)=>{const o=document.createElement('option');o.value=i;o.textContent=s.name+` · ${s.start+1}–${s.end+1}`;$('sequence').append(o);});$('sequence').value=sequenceIndex;
 const s=sequence();$('sequenceName').value=s.name;$('sequenceStart').value=s.start+1;$('sequenceEnd').value=s.end+1;$('sequenceStart').max=$('sequenceEnd').max=project.frames.length;$('sequenceLoop').checked=s.loop!==false;
}
function play(){
 if(playing){stop();renderEditor();return;}if(!project)return;
 playing=true;$('play').textContent='Ⅱ Parar';chooseFrame(sequence().start);
 const next=()=>{if(!playing)return;const s=sequence();if(selected>=s.end){if(s.loop===false){stop();renderEditor();return;}chooseFrame(s.start);}else chooseFrame(selected+1);schedule();};
 const schedule=()=>{playTimer=setTimeout(next,duration(project.frames[selected])/Number($('playSpeed').value));};schedule();
}
function setTool(next){tool=next;document.querySelectorAll('[data-tool]').forEach(b=>b.classList.toggle('selected',b.dataset.tool===next));}
function chooseFrame(index){if(!project)return;selected=Math.max(0,Math.min(index,project.frames.length-1));$('frameName').value=project.frames[selected].name;
 $('frameDuration').value=duration(project.frames[selected]);
 document.querySelectorAll('.frame').forEach((b,i)=>b.classList.toggle('selected',i===selected));renderEditor();drawSource();}
function frameCanvas(frame){const c=document.createElement('canvas');c.width=project.width;c.height=project.height;c.getContext('2d').putImageData(new ImageData(pixels(project,frame),project.width,project.height),0,0);return c;}
function checker(context,w,h){for(let y=0;y<h;y+=12)for(let x=0;x<w;x+=12){context.fillStyle=((x/12+y/12)%2)?'#2a3542':'#25303c';context.fillRect(x,y,12,12);}}
function drawRaw(context,x,y,w,h){
 const f=project.frames[selected],r=f.sourceBounds||f.sourceRect;
 if(!sourceCanvas||!r)return;
 const factor=Math.min((w-8)/r.w,(h-8)/r.h),dw=r.w*factor,dh=r.h*factor;
 context.imageSmoothingEnabled=true;context.drawImage(sourceCanvas,r.x,r.y,r.w,r.h,x+(w-dw)/2,y+h-dh-4,dw,dh);context.imageSmoothingEnabled=false;
}
function renderEditor(){
 if(!project)return;
 const z=Number($('zoom').value),w=project.width*z,h=project.height*z,gap=view==='compare'?20:0;
 const cw=view==='compare'?w*2+gap:w;if(editor.width!==cw)editor.width=cw;if(editor.height!==h)editor.height=h;
 checker(ctx,editor.width,editor.height);ctx.imageSmoothingEnabled=false;
 const frame=frameCanvas(project.frames[selected]);
 if(view==='pixel'){
  if($('onion').checked&&!playing){const s=sequence(),indices=[];
   if(selected>s.start&&selected<=s.end)indices.push([selected-1,[75,230,175]]);else if(s.loop!==false&&selected===s.start&&s.end>s.start)indices.push([s.end,[75,230,175]]);
   if(selected>=s.start&&selected<s.end)indices.push([selected+1,[193,125,255]]);else if(s.loop!==false&&selected===s.end&&s.end>s.start)indices.push([s.start,[193,125,255]]);
   for(const [index,tint] of indices){const c=frameCanvas(project.frames[index]),cx=c.getContext('2d'),rgba=pixels(project,project.frames[index]);for(let i=0;i<rgba.length;i+=4)if(rgba[i+3]){rgba.set(tint,i);rgba[i+3]=90;}cx.putImageData(new ImageData(rgba,project.width,project.height),0,0);ctx.drawImage(c,0,0,w,h);}
  }ctx.drawImage(frame,0,0,w,h);
 }
 else if(view==='source')drawRaw(ctx,0,0,w,h);
 else{drawRaw(ctx,0,0,w,h);ctx.fillStyle='#111923';ctx.fillRect(w,0,gap,h);ctx.drawImage(frame,w+gap,0,w,h);}
 if($('grid').checked&&z>=6&&view!=='source'){
  const start=view==='compare'?w+gap:0;ctx.strokeStyle='#aab8c922';ctx.lineWidth=1;ctx.beginPath();
  for(let x=0;x<=project.width;x++){ctx.moveTo(start+x*z+.5,0);ctx.lineTo(start+x*z+.5,h);}
  for(let y=0;y<=project.height;y++){ctx.moveTo(start,y*z+.5);ctx.lineTo(start+w,y*z+.5);}ctx.stroke();
 }
 const native=$('native');native.width=project.width;native.height=project.height;native.getContext('2d').drawImage(frame,0,0);
 native.parentElement.hidden=project.width>80||project.height>110;
 $('frameCaption').textContent=(view==='compare'?'Fonte → pixel · ':view==='source'?'Fonte reduzida · ':'')+project.frames[selected].name;
 $('sizeCaption').textContent=`${project.width} × ${project.height} PX / ${z}×`;
 $('undo').disabled=!undo.length;$('redo').disabled=!redo.length;
}
function renderThumb(index){
 const button=$('frames').children[index];if(!button||!project)return;
 const canvas=button.querySelector('canvas');canvas.width=project.width;canvas.height=project.height;
 canvas.getContext('2d').putImageData(new ImageData(pixels(project,project.frames[index]),project.width,project.height),0,0);
 const scale=Math.min(1,66/project.height,80/project.width);canvas.style.width=project.width*scale+'px';canvas.style.height=project.height*scale+'px';
 button.querySelector('span').textContent=project.frames[index].name+' · '+duration(project.frames[index])+' ms';button.title=project.frames[index].name;
}
function renderFrames(){
 $('frames').replaceChildren();project.frames.forEach((f,i)=>{const b=document.createElement('button');b.className='frame';b.setAttribute('aria-label',f.name);
  b.append(document.createElement('canvas'),document.createElement('span'));b.onclick=()=>{stop();if(i<sequence().start||i>sequence().end){const n=sequencesFor(project).findIndex(s=>i>=s.start&&i<=s.end);if(n>=0)sequenceIndex=n;renderSequence();}chooseFrame(i);};$('frames').append(b);renderThumb(i);});
 $('frameCount').textContent=project.frames.length+' quadros';renderSequence();chooseFrame(selected);
}
function chooseColor(i){colorIndex=i;document.querySelectorAll('.swatch').forEach((b,n)=>b.classList.toggle('active',n===i));
 $('color').value=hex(project.palette[i]);$('colorValue').textContent=i===0?'TRANSPARENTE':hex(project.palette[i]).toUpperCase();$('color').disabled=i===0;}
function renderPalette(){
 $('palette').replaceChildren();project.palette.forEach((c,i)=>{const b=document.createElement('button');b.className='swatch';b.style.background=hex(c);b.title=i===0?'Transparente':`${i} · ${hex(c)}`;
  b.setAttribute('aria-label',b.title);b.onclick=()=>chooseColor(i);$('palette').append(b);});
 $('paletteCount').textContent=project.palette.length-1+' + alpha';chooseColor(Math.min(colorIndex,project.palette.length-1));
}
function renderAudit(){const a=audit(project);$('auditSize').textContent=`${project.width} × ${project.height}`;$('auditColors').textContent=a.colors;$('auditAlpha').textContent=a.alpha;
 $('warnings').replaceChildren();for(const warning of a.warnings){const p=document.createElement('p');p.textContent=warning;$('warnings').append(p);}if(!a.warnings.length)$('warnings').textContent='✓ Grade íntegra · alpha binário';}
function drawSource(){
 const c=$('sourceCanvas'),context=c.getContext('2d');c.width=460;c.height=270;context.clearRect(0,0,c.width,c.height);
 if(!sourceCanvas)return;const factor=Math.min(c.width/sourceCanvas.width,c.height/sourceCanvas.height),w=sourceCanvas.width*factor,h=sourceCanvas.height*factor;
 const ox=(c.width-w)/2,oy=(c.height-h)/2;checker(context,c.width,c.height);context.drawImage(sourceCanvas,ox,oy,w,h);
 const s=readSettings(),rw=Math.min(s.cropWidth,source.width-s.x),rh=Math.min(s.cropHeight,source.height-s.y);context.strokeStyle='#efbb68';context.lineWidth=1;
 for(let row=0;row<s.rows;row++)for(let col=0;col<s.cols;col++){const x=ox+(s.x+col*rw/s.cols)*factor,y=oy+(s.y+row*rh/s.rows)*factor;
  if(project&&row===project.frames[selected]?.row&&col===project.frames[selected]?.col){context.fillStyle='#efbb6820';context.fillRect(x,y,rw/s.cols*factor,rh/s.rows*factor);}context.strokeRect(x,y,rw/s.cols*factor,rh/s.rows*factor);}
}
async function loadImage(blob,name,keep=false){
 if(blob.size>32*1024*1024)throw Error('A imagem deve ter no máximo 32 MB.');
 const bitmap=await createImageBitmap(blob);
 if(bitmap.width*bitmap.height>16777216){bitmap.close();throw Error('Use uma imagem de até 16 megapixels.');}
 const c=document.createElement('canvas');c.width=bitmap.width;c.height=bitmap.height;c.getContext('2d').drawImage(bitmap,0,0);bitmap.close();
 sourceCanvas=c;source=c.getContext('2d',{willReadFrequently:true}).getImageData(0,0,c.width,c.height);
 sourceUrl=await new Promise((resolve,reject)=>{const reader=new FileReader();reader.onload=()=>resolve(reader.result);reader.onerror=reject;reader.readAsDataURL(blob);});
 $('sourceSize').textContent=`${c.width}×${c.height}`;if(!keep)$('projectName').value=name.replace(/\.[^.]+$/,'');drawSource();
}
function runConversion(demo=false){
 if(!source)return status('Importe a imagem de origem para converter.');
 stop();worker?.terminate();worker=new Worker('worker.mjs',{type:'module'});busy(true);status('Amostrando a fonte e construindo a paleta…');
 worker.onmessage=({data})=>{busy(false);worker.terminate();worker=null;if(data.error)return status(data.error);
 checkpoint();project=data.project;project.name=$('projectName').value;selected=0;colorIndex=1;sequenceIndex=0;
  if(demo)project.frames.forEach((f,i)=>f.name=(i<4?'kael':'professor')+'-'+['frente','esquerda','direita','costas'][i%4]);
  renderFrames();renderPalette();renderAudit();persist();status(`Conversão pronta · ${project.frames.length} quadros nativos · revise o desenho na bancada.`);
 };
 worker.onerror=e=>{busy(false);status('Falha ao converter: '+e.message);worker?.terminate();worker=null;};
 worker.postMessage({source:{data:source.data,width:source.width,height:source.height},settings:readSettings()});
}
async function example(){try{
 await loadImage(await (await fetch('demo.png')).blob(),'Kael e professor',true);$('projectName').value='Kael e professor';applySettings({cols:4,rows:2,x:120,y:0,cropWidth:1540});$('cropHeight').value='';runConversion(true);
 }catch(e){status('Exemplo indisponível. Importe uma imagem para começar.');}}
function point(event){const r=editor.getBoundingClientRect();return {x:Math.max(-1,Math.min(project.width,Math.floor((event.clientX-r.left)/r.width*project.width))),y:Math.max(-1,Math.min(project.height,Math.floor((event.clientY-r.top)/r.height*project.height)))};}
function inspect(p){if(p.x<0||p.x>=project.width||p.y<0||p.y>=project.height)return;const index=project.frames[selected].indices[p.y*project.width+p.x];$('pixelInfo').textContent=`${p.x},${p.y} · #${index}`;}
function writePixel(x,y,erase){if(x>=0&&y>=0&&x<project.width&&y<project.height)project.frames[selected].indices[y*project.width+x]=erase?0:colorIndex;}
function line(a,b,erase){let {x,y}=a;const dx=Math.abs(b.x-x),dy=-Math.abs(b.y-y),sx=x<b.x?1:-1,sy=y<b.y?1:-1;let err=dx+dy;
 for(;;){writePixel(x,y,erase);if(x===b.x&&y===b.y)break;const e=2*err;if(e>=dy){err+=dy;x+=sx;}if(e<=dx){err+=dx;y+=sy;}}
}
function fill(p){const f=project.frames[selected].indices,target=f[p.y*project.width+p.x];if(target===colorIndex)return;
 const queue=[p.y*project.width+p.x];f[queue[0]]=colorIndex;let head=0;while(head<queue.length){const i=queue[head++],x=i%project.width,y=Math.floor(i/project.width);
  for(const n of [x?i-1:-1,x<project.width-1?i+1:-1,y?i-project.width:-1,y<project.height-1?i+project.width:-1])if(n>=0&&f[n]===target){f[n]=colorIndex;queue.push(n);}}
}
editor.addEventListener('contextmenu',e=>e.preventDefault());
editor.addEventListener('pointerdown',e=>{
 if(!project||view!=='pixel'||worker)return;stop();const p=point(e);inspect(p);
 if(p.x<0||p.x>=project.width||p.y<0||p.y>=project.height)return;
 editor.focus();if(tool==='pick'){chooseColor(project.frames[selected].indices[p.y*project.width+p.x]);return;}
 checkpoint();if(tool==='fill'&&e.button!==2){fill(p);changed();return;}
 drawing=true;lastPoint=p;editor.setPointerCapture(e.pointerId);writePixel(p.x,p.y,tool==='erase'||e.button===2);changed();
});
editor.addEventListener('pointermove',e=>{if(!project)return;const p=point(e);inspect(p);if(!drawing)return;line(lastPoint,p,tool==='erase'||e.buttons===2);lastPoint=p;changed();});
const endDraw=()=>{if(drawing){drawing=false;lastPoint=null;changed();}};editor.addEventListener('pointerup',endDraw);editor.addEventListener('pointercancel',endDraw);editor.addEventListener('lostpointercapture',endDraw);
function history(back){if(!project)return;stop();const from=back?undo:redo,to=back?redo:undo;if(!from.length)return;to.push(copy(project));project=from.pop();selected=Math.min(selected,project.frames.length-1);
 $('projectName').value=project.name||$('projectName').value;applySettings(project.settings);renderFrames();renderPalette();changed(true);status(back?'Última edição desfeita.':'Edição refeita.');}
function nudge(dx,dy){if(!project)return;stop();checkpoint();const old=project.frames[selected].indices,next=new Uint8Array(old.length);
 for(let y=0;y<project.height;y++)for(let x=0;x<project.width;x++){const a=x+dx,b=y+dy;if(a>=0&&a<project.width&&b>=0&&b<project.height)next[b*project.width+a]=old[y*project.width+x];}
 project.frames[selected].indices=next;changed();}
function download(blob,name){const url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(url),10000);status('Exportado: '+name);}
function png(single=false){if(!project)return;const c=document.createElement('canvas');c.width=project.width*(single?1:project.cols);c.height=project.height*(single?1:project.rows);const cx=c.getContext('2d');
 (single?[project.frames[selected]]:project.frames).forEach((f,i)=>cx.putImageData(new ImageData(pixels(project,f),project.width,project.height),single?0:i%project.cols*project.width,single?0:Math.floor(i/project.cols)*project.height));
 c.toBlob(blob=>download(blob,safeName()+(single?'-quadro':'-sheet')+'.png'),'image/png');}
function atlas(){return animationAtlas(project,safeName()+'-sheet.png');}
function saveProject(){if(!project)return;download(new Blob([JSON.stringify({...serialize(project),name:$('projectName').value,source:sourceUrl},null,1)],{type:'application/json'}),safeName()+'.pixelgen.json');}
async function openProject(file){
 if(file.size>64*1024*1024)throw Error('Projeto maior que 64 MB.');
 const data=JSON.parse(await file.text()),next=validateProject(data);
 let nextBlob=null;if(data.source){if(typeof data.source!=='string'||data.source.length>48*1024*1024||!/^data:image\/(png|jpeg|webp);base64,/.test(data.source))throw Error('Fonte do projeto inválida.');const [header,encoded]=data.source.split(',');nextBlob=new Blob([Uint8Array.from(atob(encoded),c=>c.charCodeAt(0))],{type:header.slice(5,header.indexOf(';'))});const check=await createImageBitmap(nextBlob);const tooLarge=check.width*check.height>16777216;check.close();if(tooLarge)throw Error('Fonte maior que 16 megapixels.');}
 stop();worker?.terminate();worker=null;busy(false);checkpoint();project=next;source=null;sourceCanvas=null;sourceUrl=null;selected=0;sequenceIndex=0;
 if(nextBlob)await loadImage(nextBlob,next.name,true);else{$('sourceSize').textContent='Sem fonte';$('sourceCanvas').getContext('2d').clearRect(0,0,460,270);}
 $('projectName').value=next.name;applySettings(next.settings);view='pixel';document.querySelectorAll('[data-view]').forEach(b=>b.classList.toggle('selected',b.dataset.view===view));
 renderFrames();renderPalette();changed(true);status('Projeto aberto. Pixels e paleta preservados.');
}
$('openImage').onclick=()=>$('imageFile').click();$('openProject').onclick=()=>$('projectFile').click();$('saveProject').onclick=saveProject;
$('imageFile').onchange=async e=>{try{if(!e.target.files[0])return;await loadImage(e.target.files[0],e.target.files[0].name);runConversion();}catch(error){status(error.message);}finally{e.target.value='';}};
$('projectFile').onchange=async e=>{try{if(e.target.files[0])await openProject(e.target.files[0]);}catch(error){status('Não foi possível abrir: '+error.message);}finally{e.target.value='';}};
const drop=$('dropzone');drop.ondragover=e=>{e.preventDefault();drop.classList.add('dragover');};drop.ondragleave=()=>drop.classList.remove('dragover');drop.ondrop=async e=>{e.preventDefault();drop.classList.remove('dragover');try{const f=e.dataTransfer.files[0];if(f){await loadImage(f,f.name);runConversion();}}catch(error){status(error.message);}};
$('demo').onclick=example;$('walkDemo').onclick=async()=>{try{const r=await fetch('professor-walk.pixelgen.json');if(!r.ok)throw Error('Exemplo indisponível.');await openProject(new File([await r.blob()],'professor-walk.pixelgen.json'));$('zoom').value='6';$('grid').checked=false;play();status('Professor · caminhada para a esquerda · quatro poses · teste de movimento.');}catch(e){status(e.message);}};
$('conversionForm').onsubmit=e=>{e.preventDefault();runConversion();};fields.forEach(k=>$(k).addEventListener('change',drawSource));
document.querySelectorAll('[data-tool]').forEach(b=>b.onclick=()=>setTool(b.dataset.tool));
document.querySelectorAll('[data-view]').forEach(b=>b.onclick=()=>{if(b.dataset.view!=='pixel'&&!source)return status('Abra a fonte original para comparar.');view=b.dataset.view;document.querySelectorAll('[data-view]').forEach(q=>q.classList.toggle('selected',q===b));renderEditor();});
$('zoom').onchange=renderEditor;$('grid').onchange=renderEditor;$('undo').onclick=()=>history(true);$('redo').onclick=()=>history(false);
$('onion').onchange=renderEditor;
$('frameDuration').onchange=()=>{if(!project)return;stop();checkpoint();project.frames[selected].duration=duration({duration:$('frameDuration').value});$('frameDuration').value=project.frames[selected].duration;changed();};
$('duplicateFrame').onclick=()=>{if(!project)return;stop();try{const next=copy(project),i=duplicateFrame(next,selected);checkpoint();project=next;selected=i;changed(true);status('Quadro duplicado. Desenhe a próxima pose com onion skin.');}catch(e){status(e.message);}};
$('sequence').onchange=()=>{if(!project)return;stop();sequenceIndex=Number($('sequence').value);renderSequence();chooseFrame(sequence().start);};
$('saveSequence').onclick=()=>{if(!project)return;const start=Number($('sequenceStart').value)-1,end=Number($('sequenceEnd').value)-1;if(!Number.isInteger(start)||!Number.isInteger(end)||start<0||end<start||end>=project.frames.length)return status('Informe um intervalo válido de quadros.');stop();checkpoint();project.sequences=sequencesFor(project).map(s=>({...s}));project.sequences[sequenceIndex]={name:$('sequenceName').value.trim().slice(0,80)||'sequencia',start,end,loop:$('sequenceLoop').checked};renderSequence();chooseFrame(start);changed();status('Sequência atualizada.');};
$('newSequence').onclick=()=>{if(!project)return;if(sequencesFor(project).length>=256)return status('Limite de 256 sequências.');stop();checkpoint();project.sequences=[...sequencesFor(project).map(s=>({...s})),{name:'nova-sequencia',start:selected,end:selected,loop:true}];sequenceIndex=project.sequences.length-1;renderSequence();changed();};
$('frameName').onchange=()=>{if(project){checkpoint();project.frames[selected].name=$('frameName').value.trim().slice(0,80)||'quadro';changed(true);}};
$('projectName').onchange=()=>{if(project){project.name=$('projectName').value;persist();}};
$('color').onchange=e=>{if(!project||colorIndex===0)return;checkpoint();const h=e.target.value;project.palette[colorIndex]=[parseInt(h.slice(1,3),16),parseInt(h.slice(3,5),16),parseInt(h.slice(5,7),16),255];renderPalette();changed(true);};
$('addColor').onclick=()=>{if(!project)return;if(project.palette.length>=256)return status('A paleta já tem 256 entradas. Edite uma cor existente.');checkpoint();project.palette.push([...(project.palette[colorIndex]||[0,0,0,255]).slice(0,3),255]);colorIndex=project.palette.length-1;renderPalette();changed();status('Nova entrada criada. Use o seletor para escolher sua cor.');};
$('nudgeLeft').onclick=()=>nudge(-1,0);$('nudgeRight').onclick=()=>nudge(1,0);$('nudgeUp').onclick=()=>nudge(0,-1);$('nudgeDown').onclick=()=>nudge(0,1);
$('play').onclick=play;$('playSpeed').onchange=()=>{if(playing){stop();play();}};
$('exportPng').onclick=()=>png();$('exportFrame').onclick=()=>png(true);$('exportAtlas').onclick=()=>{if(project)download(new Blob([JSON.stringify(atlas(),null,2)],{type:'application/json'}),safeName()+'-atlas.json');};
$('exportPalette').onclick=()=>{if(project)download(new Blob(['GIMP Palette\nName: '+safeName()+'\nColumns:8\n#\n'+project.palette.slice(1).map((c,i)=>c.slice(0,3).join(' ')+' Cor-'+(i+1)).join('\n')]),safeName()+'.gpl');};
$('exportAse').onclick=()=>{if(project)download(new Blob([aseprite(project)],{type:'application/octet-stream'}),safeName()+'.aseprite');};
document.addEventListener('keydown',e=>{if(['INPUT','SELECT','TEXTAREA'].includes(e.target.tagName))return;
 if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==='z'){e.preventDefault();history(!e.shiftKey);return;}
 if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==='s'){e.preventDefault();saveProject();return;}
 const tools={b:'brush',e:'erase',i:'pick',g:'fill'};if(tools[e.key.toLowerCase()])setTool(tools[e.key.toLowerCase()]);
});
// Restore native pixels only; source images are embedded in explicit project downloads.
try{const saved=localStorage.getItem('pixelgen-project-v1');if(saved){project=validateProject(JSON.parse(saved));$('projectName').value=project.name;applySettings(project.settings);renderFrames();renderPalette();renderAudit();status('Pixels restaurados deste navegador. Abra a fonte se quiser reconverter.');}else example();}
catch{example();}
