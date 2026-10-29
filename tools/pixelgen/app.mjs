import {settings, pixels, audit, serialize, validateProject} from './core.mjs';
import {aseprite} from './aseprite.mjs';
import {duration,sequencesFor,duplicateFrame,deleteFrame,playbackOrder,atlas as animationAtlas} from './animation.mjs';
import {upgrade,cloneDocument,compositeFrame,compositeAll,editable,layerPixels,addLayer,removeLayer,moveLayer,extract,transform} from './document.mjs';
import {createStorage} from './storage.mjs';
import {qualityReport} from './quality.mjs';
import {godotResource} from './godot.mjs';
import {GROUNDS,GROUND_LABELS,addOutline,selectiveOutline,silhouetteRGBA,legibilityReport} from './legibility.mjs';
const $=id=>document.getElementById(id),editor=$('editor'),ctx=editor.getContext('2d');
const fields=['cols','rows','width','height','colors','margin','alpha','tolerance','specks','background','sample','align','x','y','cropWidth','cropHeight'];
let project=null,source=null,sourceCanvas=null,sourceUrl=null,selected=0,colorIndex=1,tool='brush',view='pixel',worker=null;
let undo=[],redo=[],drawing=false,lastPoint=null,playTimer=null,saveTimer=null,saveWarning=false,sequenceIndex=0,playing=false;
let activeLayer=0,selection=null,selectionStart=null,libraryItems=[],saveRevision=0;
const storage=createStorage();
const status=text=>{$('status').textContent=text;};
const hex=c=>'#'+c.slice(0,3).map(v=>v.toString(16).padStart(2,'0')).join('');
const copy=cloneDocument;
const busy=value=>{$('busy').hidden=!value;$('convert').disabled=value;$('convert').textContent=value?'Convertendo…':'Converter para a grade →';};
const safeName=()=>($('projectName').value||'pixelgen').normalize('NFKD').replace(/[^a-zA-Z0-9_-]+/g,'-').slice(0,70);
function snapshot(){return project?{document:copy(project),source,sourceCanvas,sourceUrl,activeLayer,selected,sequenceIndex}:null;}
function pushUndo(value){if(!value)return;undo.push(value);const sources=()=>[...new Set(undo.map(s=>s.source).filter(Boolean))].reduce((n,s)=>n+s.data.byteLength,0);while(undo.length>1&&(undo.length>20||undo.reduce((n,s)=>n+s.document.width*s.document.height*s.document.frames.length*(s.document.layers.length+1),0)>16777216||sources()>67108864))undo.shift();redo=[];}
function checkpoint(){pushUndo(snapshot());}
function persist(){
 const revision=++saveRevision;clearTimeout(saveTimer);$('saveState').textContent='Gravando…';saveTimer=setTimeout(async()=>{if(!project)return;try{await storage.automatic({...serialize({...project,name:$('projectName').value}),source:sourceUrl});if(revision===saveRevision)$('saveState').textContent='Salvo neste navegador';saveWarning=false;}
 catch{if(revision!==saveRevision)return;$('saveState').textContent='Exporte uma cópia';if(!saveWarning){status('Não foi possível gravar no navegador. Use Salvar projeto para guardar uma cópia.');saveWarning=true;}}},500);
}
function changed(all=false,save=true){if(!project)return;if(all)compositeAll(project);else compositeFrame(project,project.frames[selected]);project.name=$('projectName').value;renderEditor();if(all)renderFrames();else renderThumb(selected);renderAudit();renderLayers();if(save)persist();}
function readSettings(){return settings(Object.fromEntries(fields.map(k=>[k,$(k).value])));}
function applySettings(s){for(const k of fields)if(s?.[k]!==undefined)$(k).value=s[k];}
function stop(){clearTimeout(playTimer);playTimer=null;playing=false;$('play').textContent='▷ Reproduzir';}
function sequence(){return sequencesFor(project)[sequenceIndex]||sequencesFor(project)[0];}
function renderSequence(){
 const list=sequencesFor(project);sequenceIndex=Math.max(0,Math.min(sequenceIndex,list.length-1));$('sequence').replaceChildren();
 list.forEach((s,i)=>{const o=document.createElement('option');o.value=i;o.textContent=s.name+` · ${s.start+1}–${s.end+1}`;$('sequence').append(o);});$('sequence').value=sequenceIndex;
 const s=sequence();$('sequenceName').value=s.name;$('sequenceStart').value=s.start+1;$('sequenceEnd').value=s.end+1;$('sequenceStart').max=$('sequenceEnd').max=project.frames.length;$('sequenceLoop').checked=s.loop!==false;$('sequenceDirection').value=s.direction||'forward';
 renderDirectionBrowser();
}
const facingLabels={S:'↓ Sul',SO:'↙ Sudoeste',O:'← Oeste',NO:'↖ Noroeste',N:'↑ Norte',NE:'↗ Nordeste',E:'→ Leste',SE:'↘ Sudeste'};
const motionLabels={idle:'Parado / respirar',walk:'Caminhar',run:'Correr',interact:'Interagir / pegar',attack:'Comandar ataque',hurt:'Receber dano',victory:'Comemorar',fall:'Cair / desmaiar'};
function renderDirectionBrowser(){
 const list=sequencesFor(project),parts=list.map(s=>/^(.*)-(S|SO|O|NO|N|NE|E|SE)$/.exec(s.name));
 const enabled=list.length>1&&parts.every(Boolean);$('directionBrowser').hidden=!enabled;
 if(enabled){const current=parts[sequenceIndex];for(const [id,values,labels,index]of [['facingChoice',[...new Set(parts.map(m=>m[2]))],facingLabels,2],['motionChoice',[...new Set(parts.map(m=>m[1]))],motionLabels,1]]){const select=$(id);select.replaceChildren();for(const value of values){const option=document.createElement('option');option.value=value;option.textContent=labels[value]||value;select.append(option);}select.value=current[index];}}
 const s=sequence();Array.from($('frames').children).forEach((button,i)=>{button.hidden=enabled&&$('onlySequence').checked&&(i<s.start||i>s.end);});
}
function chooseDirectionMotion(){
 const index=sequencesFor(project).findIndex(s=>s.name===`${$('motionChoice').value}-${$('facingChoice').value}`);if(index<0)return;
 const resume=playing;stop();sequenceIndex=index;renderSequence();chooseFrame(sequence().start);if(resume)play();
}
$('facingChoice').onchange=$('motionChoice').onchange=chooseDirectionMotion;$('onlySequence').onchange=()=>project&&renderDirectionBrowser();
function play(){
 if(drawing)endDraw();
 if(playing){stop();renderEditor();return;}if(!project)return;
 const order=playbackOrder(sequence());let position=0;playing=true;$('play').textContent='Ⅱ Parar';chooseFrame(order[0]);
 const next=()=>{if(!playing)return;position++;if(position>=order.length){if(sequence().loop===false){stop();renderEditor();return;}position=0;}chooseFrame(order[position]);schedule();};
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
// "Caber" picks the largest whole zoom that keeps the frame inside the visible bench.
function zoomValue(){if($('zoom').value!=='fit')return Number($('zoom').value);const area=$('canvasArea'),cols=view==='compare'?2:1;
 const w=(area.clientWidth||900)-60,h=(area.clientHeight||600)-80;return Math.max(1,Math.min(16,Math.floor(Math.min(w/(project.width*cols),h/project.height))));}
function renderPreview(frame){
 const native=$('native'),scale=Number($('previewScale').value)||1,ground=$('previewGround').value,pad=4*scale;
 native.width=project.width*scale+pad*2;native.height=project.height*scale+pad*2;const c=native.getContext('2d');c.imageSmoothingEnabled=false;
 if(GROUNDS[ground]){c.fillStyle=hex(GROUNDS[ground]);c.fillRect(0,0,native.width,native.height);}else checker(c,native.width,native.height);
 c.drawImage(frame,pad,pad,project.width*scale,project.height*scale);
 $('previewCaption').textContent=`LEITURA ${scale}× · ${(GROUND_LABELS[ground]||'XADREZ').toUpperCase()}`;
}
function renderEditor(){
 if(!project)return;
 const z=zoomValue(),w=project.width*z,h=project.height*z,gap=view==='compare'?20:0;
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
 else if(view==='silhouette'){const c=document.createElement('canvas');c.width=project.width;c.height=project.height;c.getContext('2d').putImageData(new ImageData(silhouetteRGBA(compositeFrame(project,project.frames[selected])),project.width,project.height),0,0);ctx.drawImage(c,0,0,w,h);}
 else if(view==='source')drawRaw(ctx,0,0,w,h);
 else{drawRaw(ctx,0,0,w,h);ctx.fillStyle='#111923';ctx.fillRect(w,0,gap,h);ctx.drawImage(frame,w+gap,0,w,h);}
 if($('grid').checked&&z>=6&&view!=='source'){
  const start=view==='compare'?w+gap:0;ctx.strokeStyle='#aab8c922';ctx.lineWidth=1;ctx.beginPath();
  for(let x=0;x<=project.width;x++){ctx.moveTo(start+x*z+.5,0);ctx.lineTo(start+x*z+.5,h);}
  for(let y=0;y<=project.height;y++){ctx.moveTo(start,y*z+.5);ctx.lineTo(start+w,y*z+.5);}ctx.stroke();
 }
 renderPreview(frame);const native=$('native');
 if(view==='pixel'&&selection){ctx.strokeStyle='#71cdbd';ctx.lineWidth=1;ctx.strokeRect(selection.x*z+.5,selection.y*z+.5,selection.w*z,selection.h*z);}
 native.parentElement.hidden=project.width>80||project.height>110;
 $('frameCaption').textContent=(view==='compare'?'Fonte → pixel · ':view==='source'?'Fonte reduzida · ':view==='silhouette'?'Silhueta · ':'')+project.frames[selected].name;
 $('sizeCaption').textContent=`${project.width} × ${project.height} PX / ${z}×`;
 $('undo').disabled=!undo.length;$('redo').disabled=!redo.length;
 $('selectionInfo').textContent=selection?`${selection.w}×${selection.h} · ${selection.x},${selection.y}`:'Sem seleção';
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
function renderLayers(){
 if(!project)return;activeLayer=Math.max(0,Math.min(activeLayer,project.layers.length-1));$('layers').replaceChildren();
 for(let i=project.layers.length-1;i>=0;i--){const l=project.layers[i],row=document.createElement('div');row.className='layer-row'+(i===activeLayer?' active':'');
  const visible=document.createElement('button');visible.textContent=l.visible===false?'○':'●';visible.title='Mostrar / ocultar '+l.name;visible.onclick=()=>{stop();checkpoint();l.visible=l.visible===false;changed(true);};
  const name=document.createElement('button');name.className='layer-select';name.textContent=l.name;name.onclick=()=>{activeLayer=i;renderLayers();};
  const lock=document.createElement('button');lock.textContent=l.locked?'◆':'◇';lock.title='Bloquear / desbloquear '+l.name;lock.onclick=()=>{checkpoint();l.locked=!l.locked;renderLayers();persist();};
  row.append(visible,name,lock);$('layers').append(row);
 }$('layerName').value=project.layers[activeLayer].name;$('layerCount').textContent=project.layers.length+'/8';
}
function mutateLayer(job){if(!project||worker)return false;stop();try{const next=copy(project),result=job(next);checkpoint();project=next;if(Number.isInteger(result))activeLayer=result;changed(true);return true;}catch(e){status(e.message);return false;}}
function showQuality(downloadReport=false){if(!project)return;const report=qualityReport(project);$('warnings').replaceChildren();for(const text of report.warnings){const line=document.createElement('p');line.textContent=text;$('warnings').append(line);}if(!report.warnings.length)$('warnings').textContent='✓ Sem alertas geométricos; revise o movimento.';if(downloadReport)download(new Blob([JSON.stringify(report,null,2)],{type:'application/json'}),safeName()+'-quality.json');else status('Revisão geométrica concluída. Os avisos não substituem a revisão visual.');}
function drawSource(){
 const c=$('sourceCanvas'),context=c.getContext('2d');c.width=460;c.height=270;context.clearRect(0,0,c.width,c.height);
 if(!sourceCanvas)return;const factor=Math.min(c.width/sourceCanvas.width,c.height/sourceCanvas.height),w=sourceCanvas.width*factor,h=sourceCanvas.height*factor;
 const ox=(c.width-w)/2,oy=(c.height-h)/2;checker(context,c.width,c.height);context.drawImage(sourceCanvas,ox,oy,w,h);
 const s=readSettings(),sx=Math.min(s.x,source.width-1),sy=Math.min(s.y,source.height-1),rw=Math.min(s.cropWidth,source.width-sx),rh=Math.min(s.cropHeight,source.height-sy);context.strokeStyle='#efbb68';context.lineWidth=1;
 for(let row=0;row<s.rows;row++)for(let col=0;col<s.cols;col++){const x=ox+(sx+col*rw/s.cols)*factor,y=oy+(sy+row*rh/s.rows)*factor;context.strokeRect(x,y,rw/s.cols*factor,rh/s.rows*factor);}
 const r=project?.frames[selected]?.sourceRect;if(r){context.fillStyle='#efbb6830';context.fillRect(ox+r.x*factor,oy+r.y*factor,r.w*factor,r.h*factor);}
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
function runConversion(demo=false,previous=null){
 if(!source)return status('Importe a imagem de origem para converter.');
 const prior=previous||snapshot();stop();worker?.terminate();worker=new Worker('worker.mjs',{type:'module'});busy(true);status('Amostrando a fonte e construindo a paleta…');
 worker.onmessage=({data})=>{busy(false);worker.terminate();worker=null;if(data.error)return status(data.error);
 pushUndo(prior);project=upgrade(data.project);project.name=$('projectName').value;selected=0;colorIndex=1;sequenceIndex=0;activeLayer=0;selection=null;
  if(demo)project.frames.forEach((f,i)=>f.name=(i<4?'kael':'professor')+'-'+['frente','esquerda','direita','costas'][i%4]);
  renderFrames();renderPalette();renderAudit();renderLayers();persist();status(`Conversão pronta · ${project.frames.length} quadros nativos · revise o desenho na bancada.`);
 };
 worker.onerror=e=>{busy(false);status('Falha ao converter: '+e.message);worker?.terminate();worker=null;};
 worker.postMessage({source:{data:source.data,width:source.width,height:source.height},settings:readSettings()});
}
async function example(){try{
 const previous=snapshot();await loadImage(await (await fetch('demo.png')).blob(),'Kael e professor',true);$('projectName').value='Kael e professor';applySettings({cols:4,rows:2,x:120,y:0,cropWidth:1540});$('cropHeight').value='';runConversion(true,previous);
 }catch(e){status('Exemplo indisponível. Importe uma imagem para começar.');}}
function point(event){const r=editor.getBoundingClientRect();return {x:Math.max(-1,Math.min(project.width,Math.floor((event.clientX-r.left)/r.width*project.width))),y:Math.max(-1,Math.min(project.height,Math.floor((event.clientY-r.top)/r.height*project.height)))};}
function inspect(p){if(p.x<0||p.x>=project.width||p.y<0||p.y>=project.height)return;const index=project.frames[selected].indices[p.y*project.width+p.x];$('pixelInfo').textContent=`${p.x},${p.y} · #${index}`;}
function writePixel(x,y,erase){if(x>=0&&y>=0&&x<project.width&&y<project.height&&(!selection||(x>=selection.x&&y>=selection.y&&x<selection.x+selection.w&&y<selection.y+selection.h)))layerPixels(project,selected,activeLayer)[y*project.width+x]=erase?0:colorIndex;}
function line(a,b,erase){let {x,y}=a;const dx=Math.abs(b.x-x),dy=-Math.abs(b.y-y),sx=x<b.x?1:-1,sy=y<b.y?1:-1;let err=dx+dy;
 for(;;){writePixel(x,y,erase);if(x===b.x&&y===b.y)break;const e=2*err;if(e>=dy){err+=dy;x+=sx;}if(e<=dx){err+=dx;y+=sy;}}
}
function fill(p){if(selection&&(p.x<selection.x||p.y<selection.y||p.x>=selection.x+selection.w||p.y>=selection.y+selection.h))return;const f=layerPixels(project,selected,activeLayer),target=f[p.y*project.width+p.x];if(target===colorIndex)return;
 const queue=[p.y*project.width+p.x];f[queue[0]]=colorIndex;let head=0;while(head<queue.length){const i=queue[head++],x=i%project.width,y=Math.floor(i/project.width);
  for(const n of [x?i-1:-1,x<project.width-1?i+1:-1,y?i-project.width:-1,y<project.height-1?i+project.width:-1])if(n>=0&&f[n]===target&&(!selection||(n%project.width>=selection.x&&n%project.width<selection.x+selection.w&&Math.floor(n/project.width)>=selection.y&&Math.floor(n/project.width)<selection.y+selection.h))){f[n]=colorIndex;queue.push(n);}}
}
editor.addEventListener('contextmenu',e=>e.preventDefault());
editor.addEventListener('pointerdown',e=>{
 if(!project||view!=='pixel'||worker)return;stop();const p=point(e);inspect(p);
 if(p.x<0||p.x>=project.width||p.y<0||p.y>=project.height)return;
 editor.focus();if(tool==='pick'){chooseColor(project.frames[selected].indices[p.y*project.width+p.x]);return;}
 if(tool==='select'){drawing=true;selectionStart=p;selection={...p,w:1,h:1};editor.setPointerCapture(e.pointerId);renderEditor();return;}
 try{editable(project,activeLayer);}catch(error){status(error.message);return;}
 checkpoint();if(tool==='fill'&&e.button!==2){fill(p);changed();return;}
 drawing=true;lastPoint=p;editor.setPointerCapture(e.pointerId);writePixel(p.x,p.y,tool==='erase'||e.button===2);changed();
});
editor.addEventListener('pointermove',e=>{if(!project)return;const p=point(e);inspect(p);if(!drawing)return;if(selectionStart){const x=Math.max(0,Math.min(project.width-1,p.x)),y=Math.max(0,Math.min(project.height-1,p.y));selection={x:Math.min(selectionStart.x,x),y:Math.min(selectionStart.y,y),w:Math.abs(selectionStart.x-x)+1,h:Math.abs(selectionStart.y-y)+1};renderEditor();return;}line(lastPoint,p,tool==='erase'||e.buttons===2);lastPoint=p;changed();});
const endDraw=()=>{if(drawing){drawing=false;lastPoint=null;if(selectionStart){selectionStart=null;renderEditor();}else changed();}};editor.addEventListener('pointerup',endDraw);editor.addEventListener('pointercancel',endDraw);editor.addEventListener('lostpointercapture',endDraw);
function history(back){if(!project)return;stop();const from=back?undo:redo,to=back?redo:undo;if(!from.length)return;to.push(snapshot());const state=from.pop();project=state.document;source=state.source;sourceCanvas=state.sourceCanvas;sourceUrl=state.sourceUrl;activeLayer=state.activeLayer;selected=state.selected;sequenceIndex=state.sequenceIndex;selection=null;
 $('projectName').value=project.name||$('projectName').value;applySettings(project.settings);renderFrames();renderPalette();changed(true);status(back?'Última edição desfeita.':'Edição refeita.');}
function nudge(dx,dy){if(!mutateLayer(p=>transform(p,selected,activeLayer,selection,'move',dx,dy)))return;if(selection)selection={...selection,x:Math.max(0,Math.min(project.width-selection.w,selection.x+dx)),y:Math.max(0,Math.min(project.height-selection.h,selection.y+dy))};renderEditor();}
function download(blob,name){const url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(url),10000);status('Exportado: '+name);}
function png(single=false){if(!project)return;const c=document.createElement('canvas');c.width=project.width*(single?1:project.cols);c.height=project.height*(single?1:project.rows);const cx=c.getContext('2d');
 (single?[project.frames[selected]]:project.frames).forEach((f,i)=>cx.putImageData(new ImageData(pixels(project,f),project.width,project.height),single?0:i%project.cols*project.width,single?0:Math.floor(i/project.cols)*project.height));
 c.toBlob(blob=>download(blob,safeName()+(single?'-quadro':'-sheet')+'.png'),'image/png');}
function atlas(){return animationAtlas(project,safeName()+'-sheet.png');}
function saveProject(){if(!project)return;download(new Blob([JSON.stringify({...serialize(project),name:$('projectName').value,source:sourceUrl})],{type:'application/json'}),safeName()+'.pixelgen.json');}
async function openProject(file,autosave=true){
 if(file.size>64*1024*1024)throw Error('Projeto maior que 64 MB.');
 const data=JSON.parse(await file.text()),next=validateProject(data);
 let nextBlob=null;if(data.source){if(typeof data.source!=='string'||data.source.length>48*1024*1024||!/^data:image\/(png|jpeg|webp);base64,/.test(data.source))throw Error('Fonte do projeto inválida.');const [header,encoded]=data.source.split(',');nextBlob=new Blob([Uint8Array.from(atob(encoded),c=>c.charCodeAt(0))],{type:header.slice(5,header.indexOf(';'))});const check=await createImageBitmap(nextBlob);const tooLarge=check.width*check.height>16777216;check.close();if(tooLarge)throw Error('Fonte maior que 16 megapixels.');}
 stop();worker?.terminate();worker=null;busy(false);checkpoint();project=next;source=null;sourceCanvas=null;sourceUrl=null;selected=0;sequenceIndex=0;activeLayer=0;selection=null;
 if(nextBlob)await loadImage(nextBlob,next.name,true);else{$('sourceSize').textContent='Sem fonte';$('sourceCanvas').getContext('2d').clearRect(0,0,460,270);}
 $('projectName').value=next.name;applySettings(next.settings);view='pixel';document.querySelectorAll('[data-view]').forEach(b=>b.classList.toggle('selected',b.dataset.view===view));
 renderFrames();renderPalette();changed(true,autosave);status('Projeto aberto. Pixels e paleta preservados.');
}
$('openImage').onclick=()=>$('imageFile').click();$('openProject').onclick=()=>$('projectFile').click();$('saveProject').onclick=saveProject;
$('imageFile').onchange=async e=>{try{if(!e.target.files[0])return;const previous=snapshot();await loadImage(e.target.files[0],e.target.files[0].name);runConversion(false,previous);}catch(error){status(error.message);}finally{e.target.value='';}};
$('projectFile').onchange=async e=>{try{if(e.target.files[0])await openProject(e.target.files[0]);}catch(error){status('Não foi possível abrir: '+error.message);}finally{e.target.value='';}};
const drop=$('dropzone');drop.ondragover=e=>{e.preventDefault();drop.classList.add('dragover');};drop.ondragleave=()=>drop.classList.remove('dragover');drop.ondrop=async e=>{e.preventDefault();drop.classList.remove('dragover');try{const f=e.dataTransfer.files[0];if(f){const previous=snapshot();await loadImage(f,f.name);runConversion(false,previous);}}catch(error){status(error.message);}};
async function walkExample(file,label,description='caminhada para a esquerda · quatro poses · teste de movimento.'){try{const r=await fetch(file);if(!r.ok)throw Error('Exemplo indisponível.');await openProject(new File([await r.blob()],file));$('zoom').value='fit';$('grid').checked=false;play();status(label+' · '+description);}catch(e){status(e.message);}}
$('demo').onclick=example;$('walkDemo').onclick=()=>walkExample('professor-walk.pixelgen.json','Professor');$('kaelWalkDemo').onclick=()=>walkExample('kael-walk.pixelgen.json','Kael');
$('kaelStairsDemo').onclick=()=>walkExample('kael-stairs.pixelgen.json','Kael','subir escada · vista de costas · quatro poses · estudo convertido para revisão.');
$('kaelLibraryDemo').onclick=async()=>{try{const r=await fetch('kael-library.pixelgen.json');if(!r.ok)throw Error('Biblioteca indisponível.');await openProject(new File([await r.blob()],'kael-library.pixelgen.json'));$('zoom').value='fit';$('grid').checked=false;renderEditor();play();status('Kael · 8 direções · 8 movimentos · escolha a direção e o movimento acima da timeline.');}catch(e){status(e.message);}};
$('conversionForm').onsubmit=e=>{e.preventDefault();runConversion();};fields.forEach(k=>$(k).addEventListener('change',drawSource));
document.querySelectorAll('[data-tool]').forEach(b=>b.onclick=()=>setTool(b.dataset.tool));
document.querySelectorAll('[data-view]').forEach(b=>b.onclick=()=>{if(!['pixel','silhouette'].includes(b.dataset.view)&&!source)return status('Abra a fonte original para comparar.');view=b.dataset.view;document.querySelectorAll('[data-view]').forEach(q=>q.classList.toggle('selected',q===b));renderEditor();});
$('zoom').onchange=renderEditor;$('grid').onchange=renderEditor;$('undo').onclick=()=>history(true);$('redo').onclick=()=>history(false);
$('onion').onchange=renderEditor;$('previewGround').onchange=$('previewScale').onchange=renderEditor;
globalThis.addEventListener?.('resize',()=>{if(project&&$('zoom').value==='fit')renderEditor();});
const legibilityFrames=()=>$('legibilityAll').checked?null:selected;
function showLegibility(){if(!project)return;const r=legibilityReport(project,{frames:legibilityFrames()}),box=$('legibilityResult');box.replaceChildren();
 const meter=(label,value,good)=>{const row=document.createElement('div');row.className='meter';const bar=document.createElement('i'),fillBar=document.createElement('b');fillBar.style.width=Math.round(value*100)+'%';if(!good)fillBar.className='bad';bar.append(fillBar);row.append(label,bar,Math.round(value*100)+'%');box.append(row);};
 meter('Contorno',r.darkEdge,r.darkEdge>=.7);for(const [key,v] of Object.entries(r.grounds))meter(GROUND_LABELS[key],1-v,v<=.25);
 for(const text of r.warnings){const line=document.createElement('p');line.textContent=text;box.append(line);}
 if(!r.warnings.length){const ok=document.createElement('p');ok.className='ok';ok.textContent='✓ Contorno fechado e contraste bom nos quatro chões. Confira a pose na Silhueta.';box.append(ok);}
 status('Legibilidade medida. As barras mostram a borda escura e a borda que se destaca de cada chão.');}
$('legibilityCheck').onclick=showLegibility;
$('outlineOuter').onclick=()=>{if(mutateLayer(p=>addOutline(p,{frames:legibilityFrames(),diagonal:$('outlineDiagonal').checked})))status('Camada Contorno criada no topo. Oculte, edite ou exclua quando quiser.');};
$('outlineSelective').onclick=()=>{let count=0;if(mutateLayer(p=>{count=selectiveOutline(p,activeLayer,{frames:legibilityFrames()});if(!count)throw Error('Nenhum pixel desta camada está na borda da figura.');}))status(`Contorno seletivo: ${count} pixels de borda escurecidos com a própria paleta.`);};
$('frameDuration').onchange=()=>{if(!project)return;stop();checkpoint();project.frames[selected].duration=duration({duration:$('frameDuration').value});$('frameDuration').value=project.frames[selected].duration;changed();};
$('duplicateFrame').onclick=()=>{if(!project)return;stop();try{const next=copy(project),i=duplicateFrame(next,selected);checkpoint();project=next;selected=i;changed(true);status('Quadro duplicado. Desenhe a próxima pose com onion skin.');}catch(e){status(e.message);}};
$('sequence').onchange=()=>{if(!project)return;stop();sequenceIndex=Number($('sequence').value);renderSequence();chooseFrame(sequence().start);};
$('saveSequence').onclick=()=>{if(!project)return;const start=Number($('sequenceStart').value)-1,end=Number($('sequenceEnd').value)-1;if(!Number.isInteger(start)||!Number.isInteger(end)||start<0||end<start||end>=project.frames.length)return status('Informe um intervalo válido de quadros.');stop();checkpoint();project.sequences=sequencesFor(project).map(s=>({...s}));project.sequences[sequenceIndex]={name:$('sequenceName').value.trim().slice(0,80)||'sequencia',start,end,loop:$('sequenceLoop').checked,direction:$('sequenceDirection').value};renderSequence();chooseFrame(start);changed();status('Sequência atualizada.');};
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
$('addLayer').onclick=()=>mutateLayer(p=>addLayer(p,activeLayer));$('removeLayer').onclick=()=>mutateLayer(p=>removeLayer(p,activeLayer));
$('layerUp').onclick=()=>mutateLayer(p=>moveLayer(p,activeLayer,1));$('layerDown').onclick=()=>mutateLayer(p=>moveLayer(p,activeLayer,-1));
$('layerName').onchange=()=>mutateLayer(p=>{p.layers[activeLayer].name=$('layerName').value.trim().slice(0,80)||'Camada';});
$('layerToSequence').onclick=()=>mutateLayer(p=>{editable(p,activeLayer);const data=layerPixels(p,selected,activeLayer).slice(),s=sequence();for(let i=s.start;i<=s.end;i++)p.frames[i].cels[activeLayer]=data.slice();});
$('extractPart').onclick=()=>mutateLayer(p=>extract(p,selected,activeLayer,selection,$('extractAll').checked));
$('clearSelection').onclick=()=>{selection=null;renderEditor();};
$('flipX').onclick=()=>mutateLayer(p=>transform(p,selected,activeLayer,selection,'flip-x'));$('flipY').onclick=()=>mutateLayer(p=>transform(p,selected,activeLayer,selection,'flip-y'));
$('qualityCheck').onclick=()=>showQuality();$('exportQuality').onclick=()=>showQuality(true);
$('deleteFrame').onclick=()=>{if(!project||worker)return;stop();try{const next=copy(project),i=deleteFrame(next,selected);checkpoint();project=next;selected=i;changed(true);}catch(e){status(e.message);}};
$('blankFrame').onclick=()=>{if(!project||worker)return;stop();try{const next=copy(project),i=duplicateFrame(next,selected);for(const cel of next.frames[i].cels)cel.fill(0);next.frames[i].name='novo-quadro';next.frames[i].sourceRect=undefined;next.frames[i].sourceBounds=undefined;checkpoint();project=next;selected=i;changed(true);}catch(e){status(e.message);}};
function reorderFrame(delta){if(!project||worker)return;const to=selected+delta,s=sequence();if(to<s.start||to>s.end)return status('Reordene dentro da sequência selecionada.');stop();checkpoint();[project.frames[selected],project.frames[to]]=[project.frames[to],project.frames[selected]];selected=to;project.frames.forEach((f,i)=>{f.row=Math.floor(i/project.cols);f.col=i%project.cols;});changed(true);}
$('frameBefore').onclick=()=>reorderFrame(-1);$('frameAfter').onclick=()=>reorderFrame(1);
$('durationAll').onclick=()=>{if(!project)return;stop();checkpoint();const s=sequence(),ms=duration({duration:$('frameDuration').value});for(let i=s.start;i<=s.end;i++)project.frames[i].duration=ms;changed(true);};
$('exportGodot').onclick=()=>{if(!project)return;try{download(new Blob([godotResource(project,$('godotPath').value||'res://assets/pixelgen/'+safeName()+'-sheet.png')],{type:'text/plain'}),safeName()+'.tres');}catch(e){status(e.message);}};
async function populateLibrary(){try{libraryItems=await storage.list();renderLibrary();}catch(e){$('projectList').textContent='Biblioteca indisponível neste navegador. Use os arquivos de projeto.';status(e.message);}}
function renderLibrary(){const filter=$('librarySearch').value.toLowerCase();$('projectList').replaceChildren();for(const item of libraryItems.filter(i=>i.name.toLowerCase().includes(filter))){const button=document.createElement('button');button.className='project-entry';button.textContent=item.name+` · ${item.width}×${item.height} · ${item.frames} quadros`;button.onclick=async()=>{try{const value=await storage.load(item.id);if(!value)throw Error('Projeto não encontrado.');await openProject(new File([JSON.stringify(value)],'project.json'));$('libraryDialog').close();}catch(e){status(e.message);}};$('projectList').append(button);}if(!$('projectList').children.length)$('projectList').textContent=libraryItems.length?'Nenhum projeto com esse nome.':'Guarde seu primeiro sprite nesta biblioteca.';}
$('library').onclick=()=>{stop();$('libraryDialog').showModal();populateLibrary();};$('closeLibrary').onclick=()=>$('libraryDialog').close();$('librarySearch').oninput=renderLibrary;
$('saveLibrary').onclick=async()=>{if(!project)return;try{project.name=$('projectName').value;project.id=await storage.save({...serialize(project),source:sourceUrl});persist();await populateLibrary();status('Projeto guardado na biblioteca deste navegador.');}catch(e){status('Não foi possível guardar: '+e.message);}};
$('recover').onclick=async()=>{try{const value=await storage.restore(true);if(!value)throw Error('Ainda não há uma gravação anterior.');await openProject(new File([JSON.stringify(value)],'recovery.json'));$('libraryDialog').close();status('Gravação anterior recuperada. Desfazer retorna ao estado anterior à recuperação.');}catch(e){status(e.message);}};
$('createProject').onclick=async()=>{try{const [w,h]=$('newPreset').value.split('x').map(Number),p=validateProject({kind:'pixelgen',version:1,name:$('newName').value.trim()||'Novo sprite',width:w,height:h,cols:1,rows:1,palette:project?project.palette.map(c=>[...c]):[[0,0,0,0],[24,32,48,255],[248,238,220,255]],frames:[{name:'idle',indices:Array(w*h).fill(0)}],sequences:[{name:'idle',start:0,end:0,loop:true}]});await openProject(new File([JSON.stringify(serialize(p))],'new.json'));$('libraryDialog').close();}catch(e){status(e.message);}};
document.addEventListener('keydown',e=>{
 if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==='s'){e.preventDefault();saveProject();return;}
 if(['INPUT','SELECT','TEXTAREA'].includes(e.target.tagName)||$('libraryDialog').open)return;
 if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==='z'){e.preventDefault();history(!e.shiftKey);return;}
 if(!project)return;if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==='a'){e.preventDefault();selection={x:0,y:0,w:project.width,h:project.height};setTool('select');renderEditor();return;}
 if(e.key==='Escape'){selection=null;renderEditor();return;}if(e.code==='Space'&&['BODY','CANVAS'].includes(e.target.tagName)){e.preventDefault();play();return;}
 if(e.key==='Delete'){mutateLayer(p=>{editable(p,activeLayer);const cel=layerPixels(p,selected,activeLayer),r=selection||{x:0,y:0,w:p.width,h:p.height};for(let y=r.y;y<r.y+r.h;y++)for(let x=r.x;x<r.x+r.w;x++)cel[y*p.width+x]=0;});return;}
 const tools={b:'brush',e:'erase',i:'pick',g:'fill',m:'select'};if(tools[e.key.toLowerCase()])setTool(tools[e.key.toLowerCase()]);
});
// Migrate the old autosave without deleting it. Malformed current data falls back to recovery.
async function restore(){for(const previous of [false,true]){try{const data=await storage.restore(previous);if(data){await openProject(new File([JSON.stringify(data)],'autosave.json'),false);$('saveState').textContent='Restaurado neste navegador';status(previous?'Gravação anterior recuperada.':'Projeto e fonte restaurados deste navegador.');return;}}catch{}}
 try{const saved=localStorage.getItem('pixelgen-project-v1');if(saved){await openProject(new File([saved],'legacy.json'));status('Projeto anterior migrado com seus pixels preservados.');return;}}catch{}await example();}
const ready=restore();
