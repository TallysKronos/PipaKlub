import {render,identity,multiply,matrices,artworkMatrix} from './model.mjs';
// Painting owns a private copy of the selected crop, never its shared atlas.
export function paintTarget(part,face='normal'){
 const target=face==='normal'?part:part.faces?.[face];
 if(!target)throw Error('Expressão ausente nesta peça.');
 return {asset:target.asset,source:[...target.source]};
}
export function applyPaintAsset(project,partId,face,src){
 const part=project.parts.find(p=>p.id===partId),target=paintTarget(part,face);
 const [, ,w,h]=target.source;
 if(!src.startsWith('data:image/png;base64,'))throw Error('Retoque precisa ser PNG.');
 part.paintOriginals??={};part.paintOriginals[face]??=structuredClone(target);
 const id='paint-'+partId+'-'+face+'-'+globalThis.crypto.randomUUID();
 project.assets[id]={src,width:w,height:h,name:'Retoque · '+part.name+' · '+face};
 const next={asset:id,source:[0,0,w,h]};
 if(face==='normal'){part.asset=id;part.source=next.source;}else part.faces[face]=next;
 return id;
}
export function restorePaintAsset(project,partId,face){
 const part=project.parts.find(p=>p.id===partId),original=part.paintOriginals?.[face];
 if(!original)return false;
 if(face==='normal'){part.asset=original.asset;part.source=[...original.source];}
 else part.faces[face]=structuredClone(original);
 return true;
}

const toolIcon={brush:'<path d="m4 16 11-11 4 4-11 11H4zM13 7l4 4M4 16l4 4"/>',erase:'<path d="m3 14 9-10 9 8-8 9H9zM8 9l9 8M12 21h9"/>',pick:'<path d="m14 4 6 6M12 6l6 6M16 10 6 20H3v-3L13 7"/>'};
const iconButton=(id,label,key)=>'<button type="button" data-tool="'+id+'" title="'+label+' · '+key+'" aria-label="'+label+' ('+key+')" aria-pressed="'+(id==='brush')+'"><svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">'+toolIcon[id]+'</svg></button>';
export function stabilizedPoint(previous,next,strength=0){const weight=1-Math.min(.98,Math.max(0,strength/100));return {x:previous.x+(next.x-previous.x)*weight,y:previous.y+(next.y-previous.y)*weight};}

export function drawPaintContext(ctx,project,images,partId,face,edited,otherOpacity=.25){
 const p=structuredClone(project),selected=p.parts.find(q=>q.id===partId);if(!selected)return;
 const target={asset:'__paint_preview__',source:[0,0,edited.width,edited.height]};
 if(face==='normal'){selected.asset=target.asset;selected.source=target.source;}else selected.faces[face]=target;
 const pose={face,values:Object.fromEntries(['root',...p.parts.map(q=>q.id)].map(id=>[id,identity()]))},sources={...images,__paint_preview__:edited};
 ctx.clearRect(0,0,ctx.canvas.width,ctx.canvas.height);
 for(const part of [...p.parts].sort((a,b)=>a.z-b.z)){
  if(part.visible===false)continue;
  const layer={...p,parts:p.parts.map(q=>({...q,visible:q.id===part.id}))};
  ctx.save();ctx.globalAlpha=part.id===partId?1:otherOpacity;render(ctx,layer,sources,pose,{clear:false,scale:.92*Math.min(ctx.canvas.width/p.width,ctx.canvas.height/p.height)});ctx.restore();
 }
}
export function paintContextMatrix(project,partId,width,height,sourceWidth,sourceHeight){
 const part=project.parts.find(p=>p.id===partId),scale=.92*Math.min(width/project.width,height/project.height),pose={values:Object.fromEntries(['root',...project.parts.map(p=>p.id)].map(id=>[id,identity()]))};
 const view=[scale,0,0,scale,(width-project.width*scale)/2,(height-project.height*scale)/2],rect=[part.rect[2]/sourceWidth,0,0,part.rect[3]/sourceHeight,part.rect[0],part.rect[1]];
 return multiply(view,multiply(matrices(project,pose)[partId],multiply(artworkMatrix(part),rect)));
}
export function sourcePaintPoint(matrix,x,y){const [a,b,c,d,tx,ty]=matrix,det=a*d-b*c;if(Math.abs(det)<1e-12)throw Error('Peça sem escala para pintar.');return {x:(d*(x-tx)-c*(y-ty))/det,y:(a*(y-ty)-b*(x-tx))/det};}
export function paletteFromPixels(samples,limit=20){
 const bins=new Map();for(const data of samples)for(let i=0;i<data.length;i+=4){if(data[i+3]<180)continue;const rgb=[data[i],data[i+1],data[i+2]],key=rgb.map(v=>Math.floor(v/24)).join(','),hex='#'+rgb.map(v=>v.toString(16).padStart(2,'0')).join('');let bin=bins.get(key);if(!bin){bin={count:0,colors:new Map()};bins.set(key,bin);}bin.count++;bin.colors.set(hex,(bin.colors.get(hex)||0)+1);}
 return [...bins.values()].sort((a,b)=>b.count-a.count).slice(0,limit).map(b=>[...b.colors].sort((a,b)=>b[1]-a[1])[0][0]);
}
export function openPaintEditor({part,assets,images,project}){
 return new Promise(resolve=>{
  const dialog=document.createElement('dialog');dialog.className='paint-dialog';
  dialog.innerHTML=`<header><div><span class="eyebrow">RETOQUE DA PEÇA</span><h2></h2></div><button data-id="cancel" aria-label="Fechar retoque">Fechar</button></header>
  <div class="paint-toolbar"><label>Imagem<select data-id="face"></select></label><div class="paint-tool-icons" role="group" aria-label="Ferramentas de retoque">${iconButton('brush','Pincel','B')}${iconButton('erase','Borracha','E')}${iconButton('pick','Conta-gotas','I')}</div><select data-id="tool" hidden aria-label="Ferramenta"><option value="brush">Pincel</option><option value="erase">Borracha</option><option value="pick">Conta-gotas</option></select><label>Traço<select data-id="tip"><option value="round">Redondo · contornos</option><option value="soft">Suave · acabamento</option><option value="pixel">Pixel · bordas</option><option value="line">Linha reta · varetas</option><option value="ink">Nanquim · mangá</option><option value="classic">Criaturas clássicas · cel</option><option value="watercolor">Aquarela · papel</option></select></label><label>Estabilização<output data-id="smoothValue">60%</output><input data-id="smooth" type="range" min="0" max="98" value="60"></label><label>Cor<input data-id="color" type="color" value="#ef9b32"></label><label>Tamanho <output data-id="sizeValue">12 px</output><input data-id="size" type="range" min="1" max="160" value="12"></label><label>Opacidade <output data-id="opacityValue">100%</output><input data-id="opacity" type="range" min="1" max="100" value="100"></label><label>Zoom<select data-id="zoom"><option value=".25">25%</option><option value=".5">50%</option><option value="1">100%</option><option value="2">200%</option><option value="4">400%</option><option value="8">800%</option></select></label></div>
  <div class="paint-actions"><label class="paint-context-toggle"><input data-id="context" type="checkbox"> Ver todas as peças</label><label><input data-id="inPlace" type="checkbox"> Pintar na montagem</label><label><input data-id="alphaLock" type="checkbox"> Travar transparência</label><label>Outras peças<input data-id="ghost" type="range" min="5" max="65" value="25" aria-label="Opacidade das outras peças"></label><label><input data-id="pressure" type="checkbox" checked> Pressão da caneta</label><button data-id="undo">Desfazer</button><button data-id="redo">Refazer</button><button data-id="fit">Ajustar à janela</button><button data-id="background">Fundo escuro</button><button data-id="restore">Restaurar original desta imagem</button></div>
  <div class="paint-palette"><span>Paleta da criatura</span><div data-id="palette" role="group" aria-label="Cores da criatura"></div><button data-id="addColor">+ Guardar cor</button></div><div class="paint-workspace"><div class="paint-scroll" tabindex="0" aria-label="Área de pintura. Use as barras de rolagem ou arraste com Espaço para navegar."><canvas aria-label="Imagem selecionada para retoque"></canvas></div><aside data-id="contextPanel" class="paint-context-panel" hidden><h3>Montagem ao vivo</h3><canvas data-id="contextCanvas" width="640" height="640" aria-label="Montagem com as outras peças esmaecidas"></canvas><p>A peça selecionada recebe os traços; as outras permanecem protegidas.</p></aside></div>
  <div data-id="cursor" class="paint-brush-cursor" hidden aria-hidden="true"><span></span></div><p data-id="status" role="status"></p><footer><span>Ctrl+Z desfaz · Ctrl+Shift+Z refaz · Espaço + arrastar navega. Cada expressão é editada separadamente.</span><button data-id="apply" class="primary">Aplicar e voltar ao personagem</button></footer>`;
  document.body.append(dialog);dialog.querySelector('h2').textContent=part.name;
  const $=id=>dialog.querySelector('[data-id="'+id+'"]'),view=dialog.querySelector('.paint-scroll'),canvas=dialog.querySelector('canvas'),ctx=canvas.getContext('2d',{willReadFrequently:true});
  const labels={normal:'Neutra',fierce:'Golpe',hurt:'Dano',happy:'Vitória'};
  for(const face of ['normal',...Object.keys(part.faces||{})]){const o=document.createElement('option');o.value=face;o.textContent=labels[face]||face;$('face').append(o);}
  let active='normal',dirty=false,stroke=null,pan=null,space=false,past=[],future=[],done=false,lastPointer=null,lineStart=null,rawPoint=null,surface=canvas,palette=[];
  function finish(value){if(done)return;done=true;dialog.close();dialog.remove();resolve(value);}
  function discard(){if(dirty&&!confirm('Descartar os retoques ainda não aplicados?'))return false;return true;}
  function status(text){$('status').textContent=text;}
  function updateContext(){if(!project||!$('context').checked&&!$('inPlace').checked)return;drawPaintContext($('contextCanvas').getContext('2d'),project,images,part.id,active,canvas,Number($('ghost').value)/100);}
  const contextCanvas=$('contextCanvas');
  function contextMode(){end();if(!$('inPlace').checked){contextCanvas.style.width='100%';contextCanvas.style.height='auto';}$('contextPanel').hidden=!$('context').checked&&!$('inPlace').checked;dialog.classList.toggle('paint-in-place',$('inPlace').checked);surface=$('inPlace').checked?contextCanvas:canvas;cursor.hidden=true;fit();updateContext();}
  $('inPlace').disabled=!project;$('inPlace').onchange=contextMode;
  $('alphaLock').onchange=()=>{end();dialog.querySelector('[data-tool="erase"]').disabled=$('alphaLock').checked;if($('alphaLock').checked&&$('tool').value==='erase')setTool('brush');status($('alphaLock').checked?'Transparência travada: somente a silhueta existente recebe cor.':'Transparência livre para desenhar e apagar.');};
  function drawPalette(){const box=$('palette');box.replaceChildren();for(const color of palette){const b=document.createElement('button');b.type='button';b.title=color;b.setAttribute('aria-label','Usar cor '+color);b.style.background=color;b.onclick=()=>{$('color').value=color;status('Cor selecionada: '+color);};box.append(b);}}
  function initPalette(){if(project?.paintPalette?.length)palette=[...project.paintPalette].filter(c=>/^#[0-9a-f]{6}$/i.test(c)).slice(0,24);else{
   const probe=document.createElement('canvas');probe.width=64;probe.height=64;const g=probe.getContext('2d'),samples=[],ids=new Set(project?project.parts.map(p=>p.asset):[part.asset]);
   for(const id of ids){const im=images[id];if(!im)continue;g.clearRect(0,0,64,64);g.imageSmoothingEnabled=false;g.drawImage(im,0,0,64,64);samples.push(g.getImageData(0,0,64,64).data);}palette=paletteFromPixels(samples);
  }drawPalette();}
  $('addColor').onclick=()=>{const c=$('color').value;if(!palette.includes(c)){if(palette.length>=24)palette.shift();palette.push(c);drawPalette();dirty=true;buttons();}status('Cor guardada; ela será salva ao aplicar o retoque.');};
  $('context').disabled=!project;$('context').onchange=contextMode;$('ghost').oninput=updateContext;

  function buttons(){updateContext();$('undo').disabled=!past.length;$('redo').disabled=!future.length;$('apply').disabled=!dirty;$('restore').disabled=!part.paintOriginals?.[active];}
  function zoom(value){const target=$('inPlace').checked?contextCanvas:canvas;target.style.width=Math.max(1,target.width*value)+'px';target.style.height=Math.max(1,target.height*value)+'px';updateCursor();}
  function fit(){const target=$('inPlace').checked?contextCanvas:canvas,holder=$('inPlace').checked?$('contextPanel'):view;const z=Math.min(4,Math.max(.1,Math.min((holder.clientWidth-32)/target.width,(holder.clientHeight-32)/target.height)));zoom(z);$('zoom').value='';}
  function load(face){active=face;const t=paintTarget(part,face),[x,y,w,h]=t.source;if(w*h>16e6)throw Error('Imagem muito grande para retoque (máximo 16 milhões de pixels).');canvas.width=w;canvas.height=h;ctx.clearRect(0,0,w,h);ctx.drawImage(images[t.asset],x,y,w,h,0,0,w,h);past=[];future=[];dirty=false;buttons();fit();status(w+' × '+h+' px · Apenas esta peça e esta expressão serão alteradas.');}
  function snapshot(){past.push(ctx.getImageData(0,0,canvas.width,canvas.height));const max=Math.max(2,Math.min(20,Math.floor(64e6/(canvas.width*canvas.height*4))));if(past.length>max)past.shift();future=[];}
  function undo(){end();if(!past.length)return;future.push(ctx.getImageData(0,0,canvas.width,canvas.height));ctx.putImageData(past.pop(),0,0);dirty=true;buttons();}
  function redo(){end();if(!future.length)return;past.push(ctx.getImageData(0,0,canvas.width,canvas.height));ctx.putImageData(future.pop(),0,0);dirty=true;buttons();}
  function at(e){const r=surface.getBoundingClientRect(),x=(e.clientX-r.left)*surface.width/r.width,y=(e.clientY-r.top)*surface.height/r.height;return surface===contextCanvas?sourcePaintPoint(paintContextMatrix(project,part.id,surface.width,surface.height,canvas.width,canvas.height),x,y):{x,y};}
  const cursor=$('cursor');
  function updateCursor(e=lastPointer){
   if(!e)return;lastPointer=e;const r=surface.getBoundingClientRect(),pick=$('tool').value==='pick';
   const vr=surface===canvas?view.getBoundingClientRect?.():null;const outside=!!(vr?.width&&(e.clientX<vr.left||e.clientX>vr.left+vr.width||e.clientY<vr.top||e.clientY>vr.top+vr.height))||e.clientX<r.left||e.clientY<r.top||e.clientX>r.left+r.width||e.clientY>r.top+r.height;
   cursor.hidden=outside||!!pan||space||pick;if(cursor.hidden)return;
   let size=Number($('size').value),width=size*r.width/canvas.width,height=size*r.height/canvas.height,angle=0;if(surface===contextCanvas){const m=paintContextMatrix(project,part.id,surface.width,surface.height,canvas.width,canvas.height);width=size*Math.hypot(m[0],m[1])*r.width/surface.width;height=size*Math.hypot(m[2],m[3])*r.height/surface.height;angle=Math.atan2(m[1],m[0])*180/Math.PI;}cursor.style.transform='translate(-50%,-50%) rotate('+angle+'deg)';
   cursor.style.left=e.clientX+'px';cursor.style.top=e.clientY+'px';cursor.style.width=width+'px';cursor.style.height=height+'px';cursor.style.borderRadius=$('tip').value==='pixel'?'0':'50%';cursor.dataset.tool=$('tool').value;cursor.querySelector('span').textContent=size+' px';
  }
  function setTool(tool){if(tool==='erase'&&$('alphaLock').checked){status('Destrave a transparência para usar a borracha.');return;}$('tool').value=tool;for(const button of dialog.querySelectorAll('[data-tool]'))button.setAttribute('aria-pressed',String(button.dataset.tool===tool));canvas.style.cursor=tool==='pick'?'crosshair':'none';contextCanvas.style.cursor=tool==='pick'?'crosshair':'none';updateCursor();}
  for(const b of dialog.querySelectorAll('[data-tool]'))b.onclick=()=>setTool(b.dataset.tool);
  function dab(p){const size=Number($('size').value),tip=$('tip').value;
   if(tip==='pixel'){const n=Math.max(1,Math.round(size));ctx.fillRect(Math.floor(p.x)-Math.floor(n/2),Math.floor(p.y)-Math.floor(n/2),n,n);}
   else if(tip==='watercolor'){
    const color=$('color').value,r=size/2,noise=(Math.sin(p.x*12.9898+p.y*78.233)*43758.5453)%1;
    const gradient=ctx.createRadialGradient(p.x,p.y,0,p.x,p.y,r);gradient.addColorStop(0,color+'35');gradient.addColorStop(.65,color+'55');gradient.addColorStop(1,color+'00');ctx.fillStyle=gradient;ctx.fillRect(p.x-r,p.y-r,size,size);
    ctx.save();ctx.globalAlpha*=.16;ctx.fillStyle=color;for(let i=0;i<7;i++){const angle=i*2.39996+noise,dist=r*(.25+.65*((i*37%11)/11));ctx.beginPath();ctx.arc(p.x+Math.cos(angle)*dist,p.y+Math.sin(angle)*dist,Math.max(.25,r*.07),0,Math.PI*2);ctx.fill();}ctx.restore();
   }
   else if(tip==='soft'){const color=$('color').value,gradient=ctx.createRadialGradient(p.x,p.y,0,p.x,p.y,size/2);gradient.addColorStop(0,color);gradient.addColorStop(1,color+'00');ctx.fillStyle=gradient;ctx.fillRect(p.x-size/2,p.y-size/2,size,size);}
   else{const radius=tip==='ink'?size/2*Math.max(.12,p.pressure??.45):size/2;ctx.beginPath();ctx.arc(p.x,p.y,radius,0,Math.PI*2);ctx.fill();}
  }
  function paint(p){
   const tip=$('tip').value;if(tip==='line'&&lineStart)ctx.putImageData(past.at(-1),0,0);
   ctx.save();ctx.globalCompositeOperation=$('tool').value==='erase'?'destination-out':$('alphaLock').checked?'source-atop':'source-over';ctx.globalAlpha=Number($('opacity').value)/100;ctx.fillStyle=$('color').value;ctx.strokeStyle=$('color').value;ctx.lineWidth=Number($('size').value);ctx.lineCap='round';ctx.lineJoin='round';
   const from=tip==='line'?lineStart:stroke;
   if(from){if(tip==='pixel'||tip==='soft'||tip==='watercolor'){const distance=Math.hypot(p.x-from.x,p.y-from.y),step=tip==='pixel'?1:Math.max(.5,Number($('size').value)/6),count=Math.max(1,Math.ceil(distance/step));for(let i=1;i<=count;i++)dab({x:from.x+(p.x-from.x)*i/count,y:from.y+(p.y-from.y)*i/count});}else{
    if(tip==='ink')ctx.lineWidth*=Math.max(.12,Math.min(1,$('pressure').checked&&p.pressure!=null?p.pressure:.95/(1+Math.hypot(p.x-from.x,p.y-from.y)*.025)));
    ctx.beginPath();ctx.moveTo(from.x,from.y);ctx.lineTo(p.x,p.y);ctx.stroke();}}
   else dab(p);ctx.restore();stroke=p;dirty=true;buttons();
  }
  canvas.onpointerdown=e=>{if(e.button!==0&&e.button!==1)return;e.preventDefault();surface.setPointerCapture(e.pointerId);if(space||e.button===1){const holder=surface===contextCanvas?$('contextPanel'):view;pan={x:e.clientX,y:e.clientY,left:holder.scrollLeft,top:holder.scrollTop,holder};updateCursor(e);return;}const p={...at(e),pressure:e.pointerType==='pen'?Math.max(.1,e.pressure):null};rawPoint=p;updateCursor(e);if($('tool').value==='erase'&&$('alphaLock').checked){status('Destrave a transparência para apagar.');return;}if($('tool').value==='pick'){if(p.x<0||p.y<0||p.x>=canvas.width||p.y>=canvas.height){status('Escolha uma cor dentro da peça selecionada.');return;}const rgba=ctx.getImageData(Math.min(canvas.width-1,Math.max(0,Math.floor(p.x))),Math.min(canvas.height-1,Math.max(0,Math.floor(p.y))),1,1).data;if(!rgba[3]){status('Pixel transparente: escolha uma área com cor.');return;}$('color').value='#'+[...rgba].slice(0,3).map(v=>v.toString(16).padStart(2,'0')).join('');setTool('brush');status('Cor capturada. Pincel selecionado.');return;}snapshot();stroke=null;lineStart=$('tip').value==='line'?p:null;paint(p);};
  canvas.onpointermove=e=>{updateCursor(e);if(pan){pan.holder.scrollLeft=pan.left-(e.clientX-pan.x);pan.holder.scrollTop=pan.top-(e.clientY-pan.y);return;}if(stroke){rawPoint={...at(e),pressure:e.pointerType==='pen'?Math.max(.1,e.pressure):null};paint($('tip').value==='line'?rawPoint:{...stabilizedPoint(stroke,rawPoint,Number($('smooth').value)),pressure:rawPoint.pressure});}};
  function end(){if(stroke&&rawPoint&&$('tip').value!=='line'&&Math.hypot(stroke.x-rawPoint.x,stroke.y-rawPoint.y)>.01)paint(rawPoint);stroke=null;lineStart=null;pan=null;rawPoint=null;}
  canvas.onpointerup=end;canvas.onpointercancel=end;canvas.onlostpointercapture=end;
  const localDown=canvas.onpointerdown,localMove=canvas.onpointermove;
  canvas.onpointerdown=e=>{surface=canvas;localDown(e);};canvas.onpointermove=e=>{surface=canvas;localMove(e);};
  contextCanvas.onpointerdown=e=>{if(!$('inPlace').checked)return;surface=contextCanvas;localDown(e);};contextCanvas.onpointermove=e=>{if(!$('inPlace').checked)return;surface=contextCanvas;localMove(e);};contextCanvas.onpointerup=end;contextCanvas.onpointercancel=end;contextCanvas.onlostpointercapture=end;contextCanvas.onpointerleave=()=>cursor.hidden=true;

  canvas.onpointerleave=()=>cursor.hidden=true;view.onscroll=()=>cursor.hidden=true;$('contextPanel').onscroll=()=>cursor.hidden=true;
  $('tool').onchange=()=>setTool($('tool').value);$('tip').onchange=()=>{end();const tip=$('tip').value;
   const presets={ink:{color:'#211c28',size:5,opacity:100,smooth:85,help:'Nanquim: linha limpa, espessura por pressão da caneta ou velocidade do mouse.'},classic:{size:14,opacity:100,smooth:75,help:'Cel clássico: cor chapada e borda firme. Combine com nanquim para os contornos.'},watercolor:{size:30,opacity:65,smooth:60,help:'Aquarela: lavagens translúcidas com granulação. Passe mais vezes para acumular cor.'}};
   const preset=presets[tip];if(preset){for(const k of ['color','size','opacity','smooth'])if(preset[k]!=null)$(k).value=preset[k];$('size').oninput();$('opacity').oninput();$('smooth').oninput();}
   updateCursor();status(preset?.help||(tip==='line'?'Arraste para definir a linha; solte para concluir.':'Desenhe sobre a peça. [ e ] ajustam o tamanho.'));};
  $('size').oninput=()=>{$('sizeValue').textContent=$('size').value+' px';updateCursor();};$('opacity').oninput=()=>$('opacityValue').textContent=$('opacity').value+'%';$('smooth').oninput=()=>$('smoothValue').textContent=$('smooth').value+'%';
  $('undo').onclick=undo;$('redo').onclick=redo;$('fit').onclick=fit;$('zoom').onchange=()=>zoom(Number($('zoom').value));
  $('background').onclick=()=>{const dark=view.classList.toggle('dark');$('background').textContent=dark?'Fundo claro':'Fundo escuro';};
  $('face').onchange=()=>{end();if(!discard()){$('face').value=active;return;}try{load($('face').value);}catch(e){status(e.message);}};
  $('cancel').onclick=()=>{if(discard())finish(null);};dialog.oncancel=e=>{e.preventDefault();if(discard())finish(null);};
  $('restore').onclick=()=>{if(confirm('Restaurar a imagem original desta expressão?'))finish({face:active,restore:true,palette});};
  $('apply').onclick=()=>{end();finish({face:active,src:canvas.toDataURL('image/png'),palette});};
  dialog.addEventListener('keydown',e=>{if(['INPUT','SELECT','TEXTAREA'].includes(e.target.tagName))return;if(e.code==='Space'){e.preventDefault();space=true;cursor.hidden=true;}if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==='z'){e.preventDefault();e.shiftKey?redo():undo();}if(!e.ctrlKey&&!e.metaKey){if(e.key.toLowerCase()==='b')setTool('brush');if(e.key.toLowerCase()==='e')setTool('erase');if(e.key.toLowerCase()==='i')setTool('pick');if(e.key==='['||e.key===']'){e.preventDefault();$('size').value=Math.max(1,Math.min(160,Number($('size').value)+(e.key===']'?1:-1)));$('size').oninput();}}});
  dialog.addEventListener('keyup',e=>{if(e.code==='Space')space=false;});dialog.addEventListener('blur',()=>space=false,true);
  dialog.showModal();try{load('normal');initPalette();setTool('brush');view.focus();}catch(e){finish(null);throw e;}
 });
}
