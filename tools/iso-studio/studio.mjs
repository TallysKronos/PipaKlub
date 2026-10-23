import {CELL,KINDS,SCALES,RULES,screen,roomSize,defaultRoom,normalizePiece,pieceBox,anchorPoint,footprintRect,placement,drawOrder,auditScene,autoFit,alphaBounds,auditSource,auditPiece,verdict,manifest,presetKaelRoom,zip} from './model.mjs';
const $=id=>document.getElementById(id),STORE='iso-studio:projeto',INK='#203b3c',GRID='rgba(214,80,170,.55)';
const state={project:presetKaelRoom(),selected:'guarda-roupa',view:'piece',zoom:{piece:3,scene:1.5},grid:true,boxes:true,kael:{on:true,u:8.5,v:4.5},overflow:true,history:[],future:[]};
const zooms={piece:[1,2,3,4,6,8],scene:[1,1.25,1.5,2,3]};
const images=new Map(),composed=new Map(),audits=new Map();
let shellImage=null,drag=null;
const say=text=>{$('message').textContent=text;};
const fmt=n=>String(Math.round(n*100)/100).replace('.',',');
const slug=text=>String(text).normalize('NFD').replace(/[̀-ͯ]/g,'').toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'')||'cenario';
const current=()=>state.project.pieces.find(p=>p.id===state.selected)||null;
function loadImage(src){return new Promise((resolve,reject)=>{const img=new Image();img.onload=()=>resolve(img);img.onerror=()=>reject(Error('PNG inválido.'));img.src=src;});}
async function ensureImages(){
 for(const p of state.project.pieces)if(p.image&&images.get(p.id)?.src!==p.image){try{images.set(p.id,await loadImage(p.image));}catch{images.delete(p.id);}}
 for(const id of [...images.keys()])if(!state.project.pieces.some(p=>p.id===id&&p.image))images.delete(id);
 shellImage=state.project.room.image?await loadImage(state.project.room.image).catch(()=>null):null;
}
// ---------- histórico e persistência ----------
function snapshot(){return JSON.stringify(state.project);}
function commit(label,mutate){state.history.push(snapshot());if(state.history.length>60)state.history.shift();state.future=[];mutate();invalidate();persist();refresh();if(label)say(label);}
function invalidate(){composed.clear();audits.clear();}
function persist(){try{localStorage.setItem(STORE,snapshot());}catch{/* armazenamento cheio ou bloqueado: o projeto continua na sessão */}}
async function restore(json,label){const data=typeof json==='string'?JSON.parse(json):json;if(!data?.room||!Array.isArray(data.pieces))throw Error('Arquivo não é um projeto do Iso Studio.');
 state.project={name:String(data.name||'Cenário'),room:{...defaultRoom(data.room.cells,data.room.wall),...data.room},pieces:data.pieces.map(p=>({...normalizePiece(p)}))};
 state.selected=state.project.pieces[0]?.id||null;invalidate();await ensureImages();refresh();if(label)say(label);}
async function undo(){if(!state.history.length)return;state.future.push(snapshot());await restore(state.history.pop(),'Desfeito.');persist();}
async function redo(){if(!state.future.length)return;state.history.push(snapshot());await restore(state.future.pop(),'Refeito.');persist();}
// ---------- peça ajustada no tamanho da caixa ----------
function compose(p){
 if(composed.has(p.id))return composed.get(p.id);const box=pieceBox(p),c=document.createElement('canvas');c.width=box.w;c.height=box.h;
 const img=images.get(p.id);if(img){const g=c.getContext('2d'),s=p.freeScale||p.scale;g.imageSmoothingEnabled=false;g.drawImage(img,p.offset[0],p.offset[1],Math.round(img.naturalWidth*s),Math.round(img.naturalHeight*s));}
 composed.set(p.id,c);return c;
}
function sourceData(img){const c=document.createElement('canvas');c.width=img.naturalWidth;c.height=img.naturalHeight;const g=c.getContext('2d');g.drawImage(img,0,0);return g.getImageData(0,0,c.width,c.height);}
function audit(p){
 if(audits.has(p.id))return audits.get(p.id);const img=images.get(p.id);let result;
 if(!img)result={items:[{level:'warn',rule:'—',text:'Sem imagem: só a caixa aparece na cena.'}],mask:null,block:null};
 else{const src=sourceData(img),source=auditSource(src),box=pieceBox(p),c=compose(p),piece=auditPiece(p,c.getContext('2d').getImageData(0,0,box.w,box.h)),items=[];
  items.push(p.freeScale?{level:'fail',rule:'R7',text:`Escala fracionária (${fmt(p.freeScale)}×). A fonte não é múltiplo inteiro da caixa: peça de novo no tamanho certo ou em 2×/4×.`}:{level:'ok',rule:'R7',text:`Fonte ${img.naturalWidth}×${img.naturalHeight}, redução ${p.scale===1?'nenhuma':p.scale>1?p.scale+'×':'1/'+Math.round(1/p.scale)} sem reamostragem.`});
  const block=source.find(i=>i.block)?.block||1,out=block*(p.freeScale||p.scale);
  items.push(...source.filter(i=>!i.block),...piece.items);
  result={items,mask:piece.mask,block:out};}
 audits.set(p.id,result);return result;
}
function scaleConsistency(){
 const blocks=state.project.pieces.map(p=>images.get(p.id)&&audit(p).block).filter(Boolean),counts={};for(const b of blocks){const k=Math.round(b*4)/4;counts[k]=(counts[k]||0)+1;}
 const mode=Number(Object.entries(counts).sort((a,b)=>b[1]-a[1])[0]?.[0]);return {mode,odd:state.project.pieces.filter(p=>images.get(p.id)&&Math.abs(audit(p).block-mode)>.3).map(p=>p.name)};
}
// ---------- desenho ----------
const stage=$('stage'),g=stage.getContext('2d');
function checker(ctx,w,h,size=8){ctx.fillStyle='#e9e4d8';ctx.fillRect(0,0,w,h);ctx.fillStyle='#ddd6c6';for(let y=0;y<h;y+=size)for(let x=(y/size)%2?size:0;x<w;x+=size*2)ctx.fillRect(x,y,size,size);}
function path(ctx,pts,close=true){ctx.beginPath();pts.forEach(([x,y],i)=>i?ctx.lineTo(x,y):ctx.moveTo(x,y));if(close)ctx.closePath();}
function drawPieceView(){
 const p=current(),wrap=$('viewport');if(!p){stage.width=wrap.clientWidth;stage.height=320;g.clearRect(0,0,stage.width,stage.height);return;}
 const box=pieceBox(p),Z=state.zoom.piece,pad=48,W=box.w*Z+pad*2,H=box.h*Z+pad*2;stage.width=W;stage.height=H;stage.style.width=W+'px';stage.style.height=H+'px';
 g.imageSmoothingEnabled=false;checker(g,W,H,8);
 const X=x=>pad+x*Z,Y=y=>pad+y*Z;
 if(state.grid)drawPieceGrid(p,box,X,Y);
 const img=images.get(p.id);
 if(img){const s=p.freeScale||p.scale;g.globalAlpha=.28;g.drawImage(img,X(p.offset[0]),Y(p.offset[1]),img.naturalWidth*s*Z,img.naturalHeight*s*Z);g.globalAlpha=1;g.drawImage(compose(p),X(0),Y(0),box.w*Z,box.h*Z);
  const a=audit(p);if(state.overflow&&a.mask){g.fillStyle='rgba(230,30,40,.85)';for(let i=0;i<a.mask.length;i++)if(a.mask[i])g.fillRect(X(i%box.w),Y(Math.floor(i/box.w)),Z,Z);}}
 if(state.boxes){g.strokeStyle='#d6339b';g.lineWidth=2;path(g,box.poly.map(([x,y])=>[X(x),Y(y)]));g.stroke();g.setLineDash([4,4]);g.strokeStyle='rgba(32,59,60,.5)';g.strokeRect(X(0),Y(0),box.w*Z,box.h*Z);g.setLineDash([]);}
 g.fillStyle='#e0262f';g.beginPath();g.arc(X(box.anchor[0]),Y(box.anchor[1]),5,0,Math.PI*2);g.fill();
 g.fillStyle=INK;g.font='600 12px ui-monospace,monospace';g.fillText(`${box.w} × ${box.h} px · âncora (${box.anchor.join(', ')})`,pad,pad-16);
 if(!img){g.fillStyle='rgba(32,59,60,.75)';g.font='600 14px system-ui';g.fillText('Arraste o PNG desta peça para cá',pad,H-pad/2+4);}
}
function drawPieceGrid(p,box,X,Y){
 // Linhas da grade na escala da peça: piso da pegada e verticais a cada célula de altura.
 g.strokeStyle=GRID;g.lineWidth=1;const [a,b]=p.footprint,P=(u,v,h=0)=>{if(p.kind==='wallRight')return [X(u*32),Y(box.h-(a-u)*16-h*32)];if(p.kind==='wallLeft')return [X((a-v)*32),Y(box.h-(a-v)*16-h*32)];return [X(box.anchor[0]+(u-a)*32-(v-b)*32),Y(box.h+(u-a)*16+(v-b)*16-h*32)];};
 const H=Math.ceil(p.height);
 if(p.kind.startsWith('wall')){for(let i=0;i<=Math.ceil(a);i++){const s=p.kind==='wallRight'?[P(Math.min(i,a),0),P(Math.min(i,a),0,p.height)]:[P(0,Math.min(i,a)),P(0,Math.min(i,a),p.height)];path(g,s,false);g.stroke();}
  for(let h=0;h<=H;h++){const s=p.kind==='wallRight'?[P(0,0,Math.min(h,p.height)),P(a,0,Math.min(h,p.height))]:[P(0,0,Math.min(h,p.height)),P(0,a,Math.min(h,p.height))];path(g,s,false);g.stroke();}return;}
 for(let u=0;u<=Math.ceil(a);u++){path(g,[P(Math.min(u,a),0),P(Math.min(u,a),b)],false);g.stroke();}
 for(let v=0;v<=Math.ceil(b);v++){path(g,[P(0,Math.min(v,b)),P(a,Math.min(v,b))],false);g.stroke();}
 for(let h=1;h<=H;h++){const z=Math.min(h,p.height);path(g,[P(0,b,z),P(a,b,z),P(a,0,z)],false);g.stroke();}
}
function sceneMetrics(){const size=roomSize(state.project.room),margin=40;return {size,margin,W:size.w+margin*2,H:size.h+margin*2};}
function drawShell(ctx,room,{grid=true,image=shellImage}={}){
 const {cells:[U,V],wall}=room,P=(u,v,h=0)=>{const s=screen(room,u,v,h);return [s.x,s.y];};
 ctx.lineWidth=1;ctx.strokeStyle=INK;
 if(image)ctx.drawImage(image,0,0);
 else{ctx.fillStyle='#f3e6c9';path(ctx,[P(0,0),P(U,0),P(U,0,wall),P(0,0,wall)]);ctx.fill();ctx.stroke();ctx.fillStyle='#e8d6ae';path(ctx,[P(0,0),P(0,V),P(0,V,wall),P(0,0,wall)]);ctx.fill();ctx.stroke();ctx.fillStyle='#d9b27c';path(ctx,[P(0,0),P(U,0),P(U,V),P(0,V)]);ctx.fill();ctx.stroke();}
 if(!grid)return;ctx.strokeStyle=GRID;
 for(let u=0;u<=U;u++){path(ctx,[P(u,0),P(u,V)],false);ctx.stroke();path(ctx,[P(u,0),P(u,0,wall)],false);ctx.stroke();}
 for(let v=0;v<=V;v++){path(ctx,[P(0,v),P(U,v)],false);ctx.stroke();path(ctx,[P(0,v),P(0,v,wall)],false);ctx.stroke();}
 for(let h=1;h<=Math.floor(wall);h++){path(ctx,[P(0,V,h),P(0,0,h),P(U,0,h)],false);ctx.stroke();}
}
function sceneItems(){
 const items=state.project.pieces.map(p=>({id:p.id,piece:p,layer:p.kind==='flat'?'flat':p.kind.startsWith('wall')?'wall':'solid',rect:footprintRect(p)}));
 if(state.kael.on)items.push({id:'__kael',layer:'actor',rect:{u0:state.kael.u-.5,v0:state.kael.v-.5,u1:state.kael.u+.5,v1:state.kael.v+.5}});
 return drawOrder(items);
}
// Caixa sombreada com luz da esquerda: topo claro, face esquerda média, face direita escura.
function paintBox(ctx,p,x,y,alpha=1){
 const box=pieceBox(p),T=([a,b])=>[x+a,y+b],poly=box.poly.map(T),fill=(c,pts)=>{ctx.fillStyle=c;path(ctx,pts);ctx.fill();};
 ctx.save();ctx.globalAlpha=alpha;ctx.strokeStyle=INK;
 if(p.kind==='floor'&&p.height>0){const [l,f,r,rt,b,lt]=poly,hz=p.height*CELL.z,ft=[f[0],f[1]-hz];
  fill('#c9d8de',[l,f,ft,lt]);fill('#93aab4',[f,r,rt,ft]);fill('#eef4f6',[lt,ft,rt,b]);path(ctx,poly);ctx.stroke();path(ctx,[lt,ft,rt],false);ctx.stroke();path(ctx,[ft,f],false);ctx.stroke();}
 else{fill(p.kind==='flat'?'#b9cdd3':'#dfe9ec',poly);ctx.stroke();}
 ctx.restore();
}
function drawBoxFaces(ctx,room,p){const at=placement(room,p);paintBox(ctx,p,at.x,at.y,.8);}
function drawKael(ctx,room){const {u,v}=state.kael,base=screen(room,u,v),top=screen(room,u,v,3.2);ctx.fillStyle='rgba(31,95,99,.25)';ctx.beginPath();ctx.ellipse(base.x,base.y,16,8,0,0,Math.PI*2);ctx.fill();
 ctx.fillStyle='#1f5f63';ctx.fillRect(base.x-11,top.y+26,22,base.y-top.y-26);ctx.beginPath();ctx.arc(base.x,top.y+14,13,0,Math.PI*2);ctx.fill();ctx.fillStyle='#f5eddd';ctx.font='600 10px system-ui';ctx.textAlign='center';ctx.fillText('Kael',base.x,base.y-30);ctx.textAlign='start';}
function renderScene(ctx,room,{grid=state.grid,boxes=state.boxes,selected=state.selected,kael=state.kael.on}={}){
 for(const item of sceneItems()){
  if(item.id==='__kael'){if(kael)drawKael(ctx,room);continue;}
  const p=item.piece,at=placement(room,p);ctx.imageSmoothingEnabled=false;
  if(images.get(p.id))ctx.drawImage(compose(p),Math.round(at.x),Math.round(at.y));else drawBoxFaces(ctx,room,p);
 }
 if(boxes)for(const p of state.project.pieces){const at=placement(room,p),box=at.box;ctx.strokeStyle=p.id===selected?'#e0262f':'rgba(214,51,155,.75)';ctx.lineWidth=p.id===selected?2:1;path(ctx,box.poly.map(([x,y])=>[at.x+x,at.y+y]));ctx.stroke();
  const a=screen(room,anchorPoint(p).u,anchorPoint(p).v,anchorPoint(p).h);ctx.fillStyle='#e0262f';ctx.fillRect(a.x-2,a.y-2,4,4);}
}
function drawSceneView(){
 const {W,H,margin}=sceneMetrics(),Z=state.zoom.scene;stage.width=W*Z;stage.height=H*Z;stage.style.width=W*Z+'px';stage.style.height=H*Z+'px';
 g.setTransform(Z,0,0,Z,0,0);g.imageSmoothingEnabled=false;g.fillStyle='#14232c';g.fillRect(0,0,W,H);g.translate(margin,margin);
 drawShell(g,state.project.room,{grid:state.grid});renderScene(g,state.project.room);g.setTransform(1,0,0,1,0,0);
}
function draw(){state.view==='piece'?drawPieceView():drawSceneView();}
// ---------- interface ----------
function fillSelect(select,entries,value){select.replaceChildren(...entries.map(([v,t])=>Object.assign(document.createElement('option'),{value:v,textContent:t})));select.value=value;}
fillSelect($('pKind'),Object.entries(KINDS),'floor');
const scaleName=s=>s===1?'1× (nenhuma)':s>1?`ampliar ${s}× (fonte pequena)`:`1/${Math.round(1/s)} (fonte em ${Math.round(1/s)}×)`;
function refresh(){
 const {project}=state,p=current();$('projectName').value=project.name;$('roomU').value=project.room.cells[0];$('roomV').value=project.room.cells[1];$('roomWall').value=project.room.wall;
 const size=roomSize(project.room);$('shellInfo').textContent=project.room.image?(shellImage&&(shellImage.naturalWidth!==size.w||shellImage.naturalHeight!==size.h)?`⚠ Casca de ${shellImage.naturalWidth}×${shellImage.naturalHeight}; este cômodo pede ${size.w}×${size.h}.`:`Casca ${size.w}×${size.h} encaixada.`):`Sem casca: piso e paredes desenhados pela bancada. A casca deve ter ${size.w}×${size.h} px.`;
 document.body.dataset.view=state.view;$('viewPiece').setAttribute('aria-selected',state.view==='piece');$('viewScene').setAttribute('aria-selected',state.view==='scene');
 $('zoomLabel').textContent=state.zoom[state.view]+'×';
 const list=$('pieceList');list.replaceChildren(...project.pieces.map(piece=>{const li=document.createElement('li'),b=document.createElement('button'),v=images.get(piece.id)?verdict(audit(piece).items):'empty';
  b.className='piece';b.dataset.state=v;b.setAttribute('aria-current',piece.id===state.selected);b.innerHTML='<i></i><span></span><small></small>';b.querySelector('span').textContent=piece.name;
  b.querySelector('small').textContent=`${KINDS[piece.kind]} · ${piece.kind.startsWith('wall')?fmt(piece.footprint[0]):piece.footprint.map(fmt).join('×')}${piece.height?' · h'+fmt(piece.height):''}`;
  b.title={ok:'Aprovada na conferência',warn:'Conferir avisos',fail:'Reprovada na conferência',empty:'Sem imagem'}[v];b.onclick=()=>{state.selected=piece.id;if(state.view==='piece')fitZoom('piece');refresh();};li.append(b);return li;}));
 const issues=auditScene(project.room,project.pieces),consistency=scaleConsistency();if(consistency.odd.length)issues.push({level:'warn',text:`Escala de pixel diferente do conjunto (${fmt(consistency.mode)} px): ${consistency.odd.join(', ')} (R7).`});
 const done=project.pieces.filter(x=>images.get(x.id)),passed=done.filter(x=>verdict(audit(x).items)!=='fail');
 $('summary').textContent=`${passed.length}/${project.pieces.length} peças aprovadas`;
 $('sceneIssues').innerHTML=issues.length?'<h2>Cena</h2>':'';if(issues.length)$('sceneIssues').append(auditList(issues));
 $('pieceForm').hidden=!p;$('emptyInspector').hidden=!!p;$('pieceTitle').textContent=p?p.name:'Nenhuma peça';
 if(p){const wall=p.kind.startsWith('wall'),box=pieceBox(p);
  $('pName').value=p.name;$('pId').value=p.id;$('pKind').value=p.kind;$('pFu').value=p.footprint[0];$('pFv').value=p.footprint[1];$('pH').value=p.height;$('pCu').value=p.cell[0];$('pCv').value=p.cell[1];$('pE').value=p.elevation;
  $('lFu').firstChild.textContent=wall?'Largura':'Pegada u';$('lFv').hidden=wall;$('lH').hidden=p.kind==='flat';$('lCu').hidden=p.kind==='wallLeft';$('lCv').hidden=p.kind==='wallRight';
  $('boxInfo').textContent=`PNG ${box.w} × ${box.h} px · âncora (${box.anchor.join(', ')}) · em 4×: ${box.w*4} × ${box.h*4}`;
  const img=images.get(p.id);$('fitPanel').hidden=!img;$('imgClear').disabled=!img;$('pngDownload').disabled=!img;
  fillSelect($('pScale'),[...SCALES.map(s=>[String(s),scaleName(s)]),...(p.freeScale?[['free',`fracionária ${fmt(p.freeScale)}× (reprova)`]]:[])],p.freeScale?'free':String(p.scale));
  $('offsetLabel').textContent=`${p.offset[0]}, ${p.offset[1]}`;$('audit').replaceChildren(...auditList(audit(p).items).children);}
 $('undo').disabled=!state.history.length;$('redo').disabled=!state.future.length;
 $('hint').textContent=state.view==='piece'?'Arraste a imagem para alinhar com a caixa rosa. Setas movem 1 px (Shift: 8 px). Vermelho = pixel fora da caixa. A imagem fantasma mostra a fonte inteira.':'Arraste peças e o Kael pela grade. Setas movem a peça selecionada 1 célula (Alt: meia célula). A ordem de profundidade segue as pegadas.';
 draw();
}
function auditList(items){const ul=document.createElement('ul');ul.className='audit';for(const i of items){const li=document.createElement('li');li.dataset.level=i.level;li.innerHTML='<b></b><span></span>';li.querySelector('b').textContent=i.rule||'';li.querySelector('span').textContent=i.text;ul.append(li);}return ul;}
// ---------- ações ----------
function updatePiece(mutate,label){const p=current();if(!p)return;commit(label,()=>{const i=state.project.pieces.indexOf(p),next=normalizePiece(mutate({...p,footprint:[...p.footprint],cell:[...p.cell],offset:[...p.offset]}));
 if(next.id!==p.id&&state.project.pieces.some(x=>x.id===next.id)){say('Já existe uma peça com esse arquivo.');return;}
 if(next.id!==p.id){images.set(next.id,images.get(p.id));images.delete(p.id);state.selected=next.id;}state.project.pieces[i]=next;});}
const bindNumber=(id,fn)=>$(id).addEventListener('change',e=>{const n=Number(e.target.value);if(Number.isFinite(n))updatePiece(p=>fn(p,n),'Medida atualizada.');});
bindNumber('pFu',(p,n)=>(p.footprint[0]=n,p));bindNumber('pFv',(p,n)=>(p.footprint[1]=n,p));bindNumber('pH',(p,n)=>(p.height=n,p));bindNumber('pCu',(p,n)=>(p.cell[0]=n,p));bindNumber('pCv',(p,n)=>(p.cell[1]=n,p));bindNumber('pE',(p,n)=>(p.elevation=n,p));
$('pName').addEventListener('change',e=>updatePiece(p=>(p.name=e.target.value,p),'Nome atualizado.'));
$('pId').addEventListener('change',e=>updatePiece(p=>(p.id=slug(e.target.value),p),'Arquivo renomeado.'));
$('pKind').addEventListener('change',e=>updatePiece(p=>{p.kind=e.target.value;if(p.kind.startsWith('wall')&&!p.elevation)p.elevation=1;if(!p.kind.startsWith('wall'))p.footprint[1]=p.footprint[1]||1;return p;},'Tipo atualizado.'));
$('pScale').addEventListener('change',e=>{if(e.target.value==='free')return;updatePiece(p=>(p.scale=Number(e.target.value),p.freeScale=null,p),'Redução atualizada.');});
$('autoFit').onclick=()=>fitCurrent();
function fitCurrent(){const p=current(),img=images.get(p?.id);if(!img)return;const fit=autoFit(pieceBox(p),alphaBounds(sourceData(img)));if(!fit)return say('Imagem sem pixels visíveis.');
 updatePiece(x=>({...x,...fit}),fit.exact?'Encaixada com redução inteira. Confira a conferência.':'Nenhuma redução inteira serve: escala fracionária marcada como reprovação (R7).');}
document.querySelectorAll('[data-nudge]').forEach(b=>b.onclick=()=>nudge(...b.dataset.nudge.split(',').map(Number)));
function nudge(dx,dy){updatePiece(p=>(p.offset=[p.offset[0]+dx,p.offset[1]+dy],p));}
$('imgImport').onclick=()=>{$('fileImage').dataset.target='current';$('fileImage').click();};
$('imgClear').onclick=()=>updatePiece(p=>(p.image=null,p.offset=[0,0],p.scale=1,p.freeScale=null,p),'Imagem removida.');
$('fileImage').onchange=async e=>{const files=[...e.target.files];e.target.value='';await importFiles(files,e.target.dataset.target==='current');};
const readData=file=>new Promise((resolve,reject)=>{const r=new FileReader();r.onload=()=>resolve(r.result);r.onerror=reject;r.readAsDataURL(file);});
async function importFiles(files,intoCurrent){
 files=files.filter(f=>f.type==='image/png'||/\.png$/i.test(f.name));if(!files.length)return say('Use arquivos PNG.');
 const loaded=[];for(const f of files)loaded.push([f,await readData(f)]);
 const fill=(p,data)=>{p.image=data;p.offset=[0,0];p.scale=1;p.freeScale=null;return p;};
 if(intoCurrent&&current()&&loaded.length===1){updatePiece(p=>fill(p,loaded[0][1]),'Imagem importada.');}
 else commit(`${loaded.length} peça(s) importada(s).`,()=>{for(const [f,data] of loaded){const id=slug(f.name.replace(/\.png$/i,'')),existing=state.project.pieces.find(p=>p.id===id);
  if(existing)Object.assign(existing,fill({...existing},data));else state.project.pieces.push(normalizePiece(fill({id,name:f.name.replace(/\.png$/i,''),kind:'floor',footprint:[1,1],height:1,cell:[1,1]},data)));state.selected=existing?.id||id;}});
 await ensureImages();invalidate();const p=current();if(p&&images.get(p.id)&&p.offset[0]===0&&p.offset[1]===0&&p.scale===1)fitCurrent();else refresh();
}
$('addPiece').onclick=()=>commit('Peça criada: ajuste pegada, altura e âncora.',()=>{let n=state.project.pieces.length+1;while(state.project.pieces.some(p=>p.id==='peca-'+n))n++;state.project.pieces.push(normalizePiece({id:'peca-'+n,name:'Peça '+n,kind:'floor',footprint:[1,1],height:1,cell:[1,1]}));state.selected='peca-'+n;});
$('pieceDelete').onclick=()=>{const p=current();if(!p)return;commit(`${p.name} excluída. Ctrl+Z desfaz.`,()=>{state.project.pieces=state.project.pieces.filter(x=>x!==p);state.selected=state.project.pieces[0]?.id||null;});ensureImages();};
$('preset').onclick=async()=>{state.history.push(snapshot());const keep=new Map(state.project.pieces.map(p=>[p.id,p]));const next=presetKaelRoom();
 next.pieces=next.pieces.map(p=>keep.get(p.id)?.image?{...p,image:keep.get(p.id).image,scale:keep.get(p.id).scale,freeScale:keep.get(p.id).freeScale,offset:keep.get(p.id).offset}:p);
 await restore(next,'Quarto do Kael 10×8 com as caixas da especificação. Imagens já importadas foram mantidas.');persist();};
$('projectName').addEventListener('change',e=>commit(null,()=>{state.project.name=e.target.value||'Cenário';}));
const roomField=(id,fn)=>$(id).addEventListener('change',e=>{const n=Number(e.target.value);if(!(n>=0))return;commit('Cômodo atualizado.',()=>{const room=state.project.room;fn(room,n);const fresh=defaultRoom(room.cells,room.wall);room.origin=fresh.origin;});});
roomField('roomU',(r,n)=>r.cells=[Math.max(1,Math.round(n)),r.cells[1]]);roomField('roomV',(r,n)=>r.cells=[r.cells[0],Math.max(1,Math.round(n))]);roomField('roomWall',(r,n)=>r.wall=n);
$('shellImport').onclick=()=>$('fileShell').click();
$('fileShell').onchange=async e=>{const f=e.target.files[0];e.target.value='';if(!f)return;const data=await readData(f);commit(null,()=>{state.project.room.image=data;});await ensureImages();refresh();say('Casca importada. Ela é desenhada a partir do canto de cima da imagem.');};
$('shellClear').onclick=async()=>{commit('Casca removida.',()=>{state.project.room.image=null;});await ensureImages();refresh();};
// ---------- referência e pedido ----------
function referenceCanvas(p,S=4){
 const box=pieceBox(p),c=document.createElement('canvas'),m=16;c.width=(box.w+m*2)*S;c.height=(box.h+m*2)*S;const ctx=c.getContext('2d');ctx.fillStyle='#ffffff';ctx.fillRect(0,0,c.width,c.height);ctx.scale(S,S);ctx.translate(m,m);
 ctx.lineWidth=2/S;paintBox(ctx,p,0,0,1);
 ctx.fillStyle='#e0262f';ctx.beginPath();ctx.arc(box.anchor[0],box.anchor[1],2.5,0,Math.PI*2);ctx.fill();
 ctx.fillStyle=INK;ctx.font='600 6px system-ui';ctx.fillText(`${p.name} · ${box.w}×${box.h} px (1×) · luz da esquerda`,-m+3,-m+8);return c;
}
function promptText(p){
 const box=pieceBox(p),wall=p.kind.startsWith('wall'),side=p.kind==='wallLeft'?'esquerda':'direita';
 const base='Pixel art de jogo, projeção dimétrica 2:1 (cada aresta horizontal sobe 1 px a cada 2 px, cerca de 26,57°; arestas verticais retas; sem perspectiva, sem 30°, sem vista de frente).';
 if(wall)return `${base} Um ${p.name.toLowerCase()} na parede ${side}: ${fmt(p.footprint[0])} células de largura por ${fmt(p.height)} de altura, deitado no plano da parede, com as bordas verticais retas e as bordas horizontais descendo para a ${side==='esquerda'?'esquerda':'direita'} na razão 2:1, paralelas ao rodapé. Siga exatamente o paralelogramo da imagem de referência. Tamanho final ${box.w}×${box.h} px (pode entregar em 4×: ${box.w*4}×${box.h*4}). Fundo transparente real, sem a parede, sem sombra. Contorno azul-escuro de 1 px, luz da esquerda.`;
 if(p.kind==='flat')return `${base} Um ${p.name.toLowerCase()} plano no chão, pegada de ${p.footprint.map(fmt).join(' × ')} células (losango de 64×32 px por célula), exatamente no losango da imagem de referência. Tamanho final ${box.w}×${box.h} px (ou 4×: ${box.w*4}×${box.h*4}). Fundo transparente real, sem sombra, sem outros objetos.`;
 return `${base} Um único objeto: ${p.name.toLowerCase()}, pegada de ${p.footprint.map(fmt).join(' × ')} células e altura de ${fmt(p.height)} células, onde cada célula do piso é um losango de 64 × 32 px e cada célula de altura mede 32 px. Encaixe exatamente na caixa da imagem de referência: mesmo ângulo, mesma largura, mesma altura, base tocando o ponto vermelho (âncora). Tamanho final ${box.w}×${box.h} px (pode entregar em 4×: ${box.w*4}×${box.h*4}, sem reamostrar). Fundo transparente real, sem piso, sem sombra no chão, sem outros objetos. Contorno azul-escuro de 1 px, luz da esquerda (topo claro, face esquerda média, face direita escura). Paleta do jogo: reboco creme, terracota, azul-petróleo, madeira mel.`;
}
const download=(blob,name)=>{const a=document.createElement('a'),url=URL.createObjectURL(blob);a.href=url;a.download=name;document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),2000);};
const toBlob=c=>new Promise(resolve=>c.toBlob(resolve,'image/png'));
$('refDownload').onclick=async()=>{const p=current();download(await toBlob(referenceCanvas(p)),`${p.id}-caixa-referencia.png`);say('Caixa de referência baixada (4×). Envie junto com o pedido.');};
$('promptCopy').onclick=async()=>{const text=promptText(current());try{await navigator.clipboard.writeText(text);say('Pedido copiado. Envie com a caixa de referência.');}catch{prompt('Copie o pedido:',text);}};
$('pngDownload').onclick=async()=>{const p=current();download(await toBlob(compose(p)),p.id+'.png');};
$('shellReference').onclick=async()=>{const size=roomSize(state.project.room),c=document.createElement('canvas'),S=2;c.width=size.w*S;c.height=size.h*S;const ctx=c.getContext('2d');ctx.scale(S,S);ctx.fillStyle='#fff';ctx.fillRect(0,0,size.w,size.h);drawShell(ctx,state.project.room,{image:null});download(await toBlob(c),'casca-referencia.png');say(`Referência da casca baixada (2×). A casca final tem ${size.w}×${size.h} px.`);};
// ---------- salvar, abrir e exportar ----------
$('save').onclick=()=>{download(new Blob([JSON.stringify({format:'iso-studio',version:1,rulesVersion:RULES,...state.project},null,1)],{type:'application/json'}),slug(state.project.name)+'.isostudio.json');say('Projeto salvo com as imagens incorporadas.');};
$('open').onclick=()=>$('fileProject').click();
$('fileProject').onchange=async e=>{const f=e.target.files[0];e.target.value='';if(!f)return;try{state.history.push(snapshot());await restore(await f.text(),'Projeto aberto.');persist();}catch(err){say(err.message);}};
$('export').onclick=async()=>{
 const name=slug(state.project.name),files=[],fails=state.project.pieces.filter(p=>images.get(p.id)&&verdict(audit(p).items)==='fail'),missing=state.project.pieces.filter(p=>!images.get(p.id));
 const bytes=async c=>new Uint8Array(await (await toBlob(c)).arrayBuffer());
 for(const p of state.project.pieces)if(images.get(p.id))files.push({name:`assets/world/${name}/${p.id}.png`,data:await bytes(compose(p))});
 if(shellImage){const c=document.createElement('canvas');c.width=shellImage.naturalWidth;c.height=shellImage.naturalHeight;c.getContext('2d').drawImage(shellImage,0,0);files.push({name:`assets/world/${name}/casca.png`,data:await bytes(c)});}
 files.push({name:`assets/world/${name}/manifest.json`,data:JSON.stringify(manifest(state.project,p=>images.has(p.id)),null,2)});
 const {W,H,margin}=sceneMetrics(),review=document.createElement('canvas');review.width=W;review.height=H;const rc=review.getContext('2d');rc.fillStyle='#14232c';rc.fillRect(0,0,W,H);rc.translate(margin,margin);drawShell(rc,state.project.room);renderScene(rc,state.project.room,{grid:true,boxes:true,selected:null,kael:false});
 files.push({name:`art/${name}/revisao-grade.png`,data:await bytes(review)});
 const report=state.project.pieces.map(p=>`${p.id}: ${images.get(p.id)?{ok:'aprovada',warn:'aprovada com avisos',fail:'REPROVADA'}[verdict(audit(p).items)]:'sem imagem'}\n${images.get(p.id)?audit(p).items.map(i=>`  [${i.level}] ${i.rule} ${i.text}`).join('\n'):''}`).join('\n');
 files.push({name:`art/${name}/conferencia.txt`,data:`Iso Studio · ${state.project.name} · regras ${RULES}\n\n${report}\n`});
 files.push({name:`art/${name}/${name}.isostudio.json`,data:JSON.stringify({format:'iso-studio',version:1,rulesVersion:RULES,...state.project})});
 download(new Blob([zip(files)],{type:'application/zip'}),name+'-entrega.zip');
 say(`Entrega exportada: ${files.length} arquivos.${fails.length?` Atenção: ${fails.length} peça(s) reprovada(s).`:''}${missing.length?` ${missing.length} sem imagem.`:''}`);
};
// ---------- interação na área de trabalho ----------
function fitZoom(view){const box=view==='scene'?sceneMetrics():(p=>p&&{W:pieceBox(p).w+96,H:pieceBox(p).h+96})(current()),vp=$('viewport');if(!box)return;const room=Math.min((vp.clientWidth-40)/box.W,(vp.clientHeight-40)/box.H);
 const list=zooms[view],fit=list.filter(z=>z<=room);state.zoom[view]=fit.length?fit[fit.length-1]:list[0];}
$('viewPiece').onclick=()=>{state.view='piece';fitZoom('piece');refresh();};$('viewScene').onclick=()=>{state.view='scene';fitZoom('scene');refresh();};
for(const [id,key] of [['showGrid','grid'],['showBoxes','boxes'],['showOverflow','overflow']])$(id).onchange=e=>{state[key]=e.target.checked;draw();};
$('showKael').onchange=e=>{state.kael.on=e.target.checked;draw();};
$('zoomIn').onclick=()=>{const z=zooms[state.view],i=z.indexOf(state.zoom[state.view]);state.zoom[state.view]=z[Math.min(z.length-1,i+1)];refresh();};
$('zoomOut').onclick=()=>{const z=zooms[state.view],i=z.indexOf(state.zoom[state.view]);state.zoom[state.view]=z[Math.max(0,i-1)];refresh();};
function scenePoint(e){const rect=stage.getBoundingClientRect(),{margin}=sceneMetrics(),Z=state.zoom.scene,x=(e.clientX-rect.left)/Z-margin,y=(e.clientY-rect.top)/Z-margin,o=state.project.room.origin,a=(x-o[0])/32,b=(y-o[1])/16;return {x,y,u:(a+b)/2,v:(b-a)/2};}
function hitPiece(pt){for(const item of [...sceneItems()].reverse()){if(item.id==='__kael'){const {u,v}=state.kael;if(Math.abs(pt.u-u)<.7&&Math.abs(pt.v-v)<.7||Math.hypot(pt.x-screen(state.project.room,u,v).x,pt.y-screen(state.project.room,u,v).y+50)<40)return item;continue;}
 const at=placement(state.project.room,item.piece),bx=pt.x-at.x,by=pt.y-at.y;if(bx<0||by<0||bx>=at.box.w||by>=at.box.h)continue;const img=images.get(item.piece.id);if(img){if(compose(item.piece).getContext('2d').getImageData(Math.floor(bx),Math.floor(by),1,1).data[3]>40)return item;}else if(insidePoly(at.box.poly,bx,by))return item;}return null;}
function insidePoly(poly,x,y){let hit=false;for(let i=0,j=poly.length-1;i<poly.length;j=i++){const [xi,yi]=poly[i],[xj,yj]=poly[j];if((yi>y)!==(yj>y)&&x<(xj-xi)*(y-yi)/(yj-yi)+xi)hit=!hit;}return hit;}
stage.addEventListener('pointerdown',e=>{
 stage.setPointerCapture(e.pointerId);$('viewport').focus({preventScroll:true});
 if(state.view==='piece'){const p=current();if(!p||!images.get(p.id))return;drag={kind:'image',x:e.clientX,y:e.clientY,start:[...p.offset],before:snapshot()};return;}
 const pt=scenePoint(e),hit=hitPiece(pt);if(!hit)return;
 if(hit.id==='__kael'){drag={kind:'kael',pt,start:{...state.kael}};return;}
 state.selected=hit.id;drag={kind:'piece',pt,start:[...hit.piece.cell],before:snapshot()};refresh();
});
stage.addEventListener('pointermove',e=>{if(!drag)return;
 if(drag.kind==='image'){const Z=state.zoom.piece,p=current(),dx=Math.round((e.clientX-drag.x)/Z),dy=Math.round((e.clientY-drag.y)/Z);p.offset=[drag.start[0]+dx,drag.start[1]+dy];composed.delete(p.id);audits.delete(p.id);drawPieceView();$('offsetLabel').textContent=p.offset.join(', ');return;}
 const pt=scenePoint(e),du=pt.u-drag.pt.u,dv=pt.v-drag.pt.v;
 if(drag.kind==='kael'){state.kael.u=Math.round((drag.start.u+du)*4)/4;state.kael.v=Math.round((drag.start.v+dv)*4)/4;draw();return;}
 const p=current(),snap=n=>Math.round(n*2)/2;p.cell=p.kind==='wallLeft'?[0,snap(drag.start[1]+dv-du)]:p.kind==='wallRight'?[snap(drag.start[0]+du-dv),0]:[snap(drag.start[0]+du),snap(drag.start[1]+dv)];draw();});
stage.addEventListener('pointerup',()=>{if(!drag)return;const d=drag;drag=null;if(d.before&&d.before!==snapshot()){state.history.push(d.before);state.future=[];invalidate();persist();refresh();}});
$('viewport').addEventListener('keydown',e=>{const k={ArrowLeft:[-1,0],ArrowRight:[1,0],ArrowUp:[0,-1],ArrowDown:[0,1]}[e.key];if(!k)return;e.preventDefault();
 if(state.view==='piece'){const s=e.shiftKey?8:1;nudge(k[0]*s,k[1]*s);return;}
 const s=e.altKey?.5:1;updatePiece(p=>{if(p.kind==='wallLeft')p.cell[1]+=k[0]?-k[0]*s:k[1]*s;else if(p.kind==='wallRight')p.cell[0]+=k[0]?k[0]*s:k[1]*s;else{p.cell[0]+=k[0]*s;p.cell[1]+=k[1]*s;}return p;});});
document.addEventListener('keydown',e=>{if(!(e.ctrlKey||e.metaKey)||e.key.toLowerCase()!=='z'||e.target.matches('input,select,textarea'))return;e.preventDefault();e.shiftKey?redo():undo();});
$('undo').onclick=undo;$('redo').onclick=redo;
// Arrastar PNGs: na peça vira a imagem dela; na lista cria peças.
for(const [el,into] of [[$('viewport'),true],[document.querySelector('.library'),false]]){
 el.addEventListener('dragover',e=>{e.preventDefault();if(into&&state.view==='piece'&&current())$('dropHint').hidden=false;});
 el.addEventListener('dragleave',()=>{$('dropHint').hidden=true;});
 el.addEventListener('drop',e=>{e.preventDefault();$('dropHint').hidden=true;importFiles([...e.dataTransfer.files],into&&state.view==='piece');});
}
// ---------- início ----------
(async()=>{let saved=null;try{saved=localStorage.getItem(STORE);}catch{}
 if(saved){try{await restore(saved,'Projeto recuperado deste navegador.');return;}catch{}}
 await ensureImages();refresh();say('Quarto do Kael carregado. Selecione uma peça, baixe a caixa de referência e importe o PNG gerado.');})();
