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

export function openPaintEditor({part,assets,images}){
 return new Promise(resolve=>{
  const dialog=document.createElement('dialog');dialog.className='paint-dialog';
  dialog.innerHTML=`<header><div><span class="eyebrow">RETOQUE DA PEÇA</span><h2></h2></div><button data-id="cancel" aria-label="Fechar retoque">Fechar</button></header>
  <div class="paint-toolbar"><label>Imagem<select data-id="face"></select></label><label>Ferramenta<select data-id="tool"><option value="brush">Pincel · B</option><option value="erase">Borracha · E</option><option value="pick">Conta-gotas · I</option></select></label><label>Cor<input data-id="color" type="color" value="#ef9b32"></label><label>Tamanho <output data-id="sizeValue">12 px</output><input data-id="size" type="range" min="1" max="160" value="12"></label><label>Opacidade <output data-id="opacityValue">100%</output><input data-id="opacity" type="range" min="1" max="100" value="100"></label><label>Zoom<select data-id="zoom"><option value=".25">25%</option><option value=".5">50%</option><option value="1">100%</option><option value="2">200%</option><option value="4">400%</option><option value="8">800%</option></select></label></div>
  <div class="paint-actions"><button data-id="undo">Desfazer</button><button data-id="redo">Refazer</button><button data-id="fit">Ajustar à janela</button><button data-id="background">Fundo escuro</button><button data-id="restore">Restaurar original desta imagem</button></div>
  <div class="paint-scroll" tabindex="0" aria-label="Área de pintura. Use as barras de rolagem ou arraste com Espaço para navegar."><canvas aria-label="Imagem selecionada para retoque"></canvas></div>
  <p data-id="status" role="status"></p><footer><span>Ctrl+Z desfaz · Ctrl+Shift+Z refaz · Espaço + arrastar navega. Cada expressão é editada separadamente.</span><button data-id="apply" class="primary">Aplicar e voltar ao personagem</button></footer>`;
  document.body.append(dialog);dialog.querySelector('h2').textContent=part.name;
  const $=id=>dialog.querySelector('[data-id="'+id+'"]'),view=dialog.querySelector('.paint-scroll'),canvas=dialog.querySelector('canvas'),ctx=canvas.getContext('2d',{willReadFrequently:true});
  const labels={normal:'Neutra',fierce:'Golpe',hurt:'Dano',happy:'Vitória'};
  for(const face of ['normal',...Object.keys(part.faces||{})]){const o=document.createElement('option');o.value=face;o.textContent=labels[face]||face;$('face').append(o);}
  let active='normal',dirty=false,stroke=null,pan=null,space=false,past=[],future=[],done=false;
  function finish(value){if(done)return;done=true;dialog.close();dialog.remove();resolve(value);}
  function discard(){if(dirty&&!confirm('Descartar os retoques ainda não aplicados?'))return false;return true;}
  function status(text){$('status').textContent=text;}
  function buttons(){$('undo').disabled=!past.length;$('redo').disabled=!future.length;$('apply').disabled=!dirty;$('restore').disabled=!part.paintOriginals?.[active];}
  function zoom(value){canvas.style.width=Math.max(1,canvas.width*value)+'px';canvas.style.height=Math.max(1,canvas.height*value)+'px';}
  function fit(){const z=Math.min(4,Math.max(.1,Math.min((view.clientWidth-32)/canvas.width,(view.clientHeight-32)/canvas.height)));zoom(z);$('zoom').value='';}
  function load(face){active=face;const t=paintTarget(part,face),[x,y,w,h]=t.source;if(w*h>16e6)throw Error('Imagem muito grande para retoque (máximo 16 milhões de pixels).');canvas.width=w;canvas.height=h;ctx.clearRect(0,0,w,h);ctx.drawImage(images[t.asset],x,y,w,h,0,0,w,h);past=[];future=[];dirty=false;buttons();fit();status(w+' × '+h+' px · Apenas esta peça e esta expressão serão alteradas.');}
  function snapshot(){past.push(ctx.getImageData(0,0,canvas.width,canvas.height));const max=Math.max(2,Math.min(20,Math.floor(64e6/(canvas.width*canvas.height*4))));if(past.length>max)past.shift();future=[];}
  function undo(){if(!past.length)return;future.push(ctx.getImageData(0,0,canvas.width,canvas.height));ctx.putImageData(past.pop(),0,0);dirty=true;buttons();}
  function redo(){if(!future.length)return;past.push(ctx.getImageData(0,0,canvas.width,canvas.height));ctx.putImageData(future.pop(),0,0);dirty=true;buttons();}
  function at(e){const r=canvas.getBoundingClientRect();return {x:(e.clientX-r.left)*canvas.width/r.width,y:(e.clientY-r.top)*canvas.height/r.height};}
  function dab(p){ctx.beginPath();ctx.arc(p.x,p.y,Number($('size').value)/2,0,Math.PI*2);ctx.fill();}
  function paint(p){ctx.save();ctx.globalCompositeOperation=$('tool').value==='erase'?'destination-out':'source-over';ctx.globalAlpha=Number($('opacity').value)/100;ctx.fillStyle=$('color').value;ctx.strokeStyle=$('color').value;ctx.lineWidth=Number($('size').value);ctx.lineCap='round';ctx.lineJoin='round';if(stroke){ctx.beginPath();ctx.moveTo(stroke.x,stroke.y);ctx.lineTo(p.x,p.y);ctx.stroke();}else dab(p);ctx.restore();stroke=p;dirty=true;buttons();}
  canvas.onpointerdown=e=>{if(e.button!==0&&e.button!==1)return;e.preventDefault();canvas.setPointerCapture(e.pointerId);if(space||e.button===1){pan={x:e.clientX,y:e.clientY,left:view.scrollLeft,top:view.scrollTop};return;}const p=at(e);if($('tool').value==='pick'){const rgba=ctx.getImageData(Math.min(canvas.width-1,Math.max(0,Math.floor(p.x))),Math.min(canvas.height-1,Math.max(0,Math.floor(p.y))),1,1).data;if(!rgba[3]){status('Pixel transparente: escolha uma área com cor.');return;}$('color').value='#'+[...rgba].slice(0,3).map(v=>v.toString(16).padStart(2,'0')).join('');$('tool').value='brush';status('Cor capturada. Pincel selecionado.');return;}snapshot();stroke=null;paint(p);};
  canvas.onpointermove=e=>{if(pan){view.scrollLeft=pan.left-(e.clientX-pan.x);view.scrollTop=pan.top-(e.clientY-pan.y);return;}if(stroke)paint(at(e));};
  function end(){stroke=null;pan=null;}canvas.onpointerup=end;canvas.onpointercancel=end;canvas.onlostpointercapture=end;
  $('tool').onchange=()=>canvas.style.cursor=$('tool').value==='pick'?'copy':'crosshair';
  $('size').oninput=()=>$('sizeValue').textContent=$('size').value+' px';$('opacity').oninput=()=>$('opacityValue').textContent=$('opacity').value+'%';
  $('undo').onclick=undo;$('redo').onclick=redo;$('fit').onclick=fit;$('zoom').onchange=()=>zoom(Number($('zoom').value));
  $('background').onclick=()=>{const dark=view.classList.toggle('dark');$('background').textContent=dark?'Fundo claro':'Fundo escuro';};
  $('face').onchange=()=>{end();if(!discard()){$('face').value=active;return;}try{load($('face').value);}catch(e){status(e.message);}};
  $('cancel').onclick=()=>{if(discard())finish(null);};dialog.oncancel=e=>{e.preventDefault();if(discard())finish(null);};
  $('restore').onclick=()=>{if(confirm('Restaurar a imagem original desta expressão?'))finish({face:active,restore:true});};
  $('apply').onclick=()=>{end();finish({face:active,src:canvas.toDataURL('image/png')});};
  dialog.addEventListener('keydown',e=>{if(['INPUT','SELECT','TEXTAREA'].includes(e.target.tagName))return;if(e.code==='Space'){e.preventDefault();space=true;}if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==='z'){e.preventDefault();e.shiftKey?redo():undo();}if(!e.ctrlKey&&!e.metaKey){if(e.key.toLowerCase()==='b')$('tool').value='brush';if(e.key.toLowerCase()==='e')$('tool').value='erase';if(e.key.toLowerCase()==='i')$('tool').value='pick';}});
  dialog.addEventListener('keyup',e=>{if(e.code==='Space')space=false;});dialog.addEventListener('blur',()=>space=false,true);
  dialog.showModal();try{load('normal');view.focus();}catch(e){finish(null);throw e;}
 });
}
