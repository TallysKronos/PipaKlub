// Iso Studio: geometria da grade 2:1 (art/grade-isometrica/especificacao.html) e auditoria de peças.
// Tudo em pixels 1×: célula de piso 64×32, 1 célula de altura = 32 px. Sem DOM: testável em Node.
export const CELL={w:64,h:32,z:32},RULES='grade-iso-1',SCALES=[1,1/2,1/3,1/4,1/5,1/6,1/8,2];
export const KINDS={floor:'Móvel no piso',flat:'Plano no piso',wallLeft:'Parede esquerda',wallRight:'Parede direita'};
const r=Math.round,num=(value,fallback,min=0,max=64)=>{const n=Number(value);return Number.isFinite(n)?Math.min(max,Math.max(min,n)):fallback;};
export const screen=(room,u,v,h=0)=>({x:room.origin[0]+(u-v)*CELL.w/2,y:room.origin[1]+(u+v)*CELL.h/2-h*CELL.z});
export function roomSize(room){return {w:(room.cells[0]+room.cells[1])*CELL.w/2,h:(room.cells[0]+room.cells[1])*CELL.h/2+room.wall*CELL.z};}
export function defaultRoom(cells=[10,8],wall=5){return {cells,wall,origin:[cells[1]*CELL.w/2,wall*CELL.z],image:null};}
export function normalizePiece(piece={}){
 const kind=KINDS[piece.kind]?piece.kind:'floor',wall=kind.startsWith('wall');
 return {id:String(piece.id||'peca').replace(/[^a-z0-9-]/gi,'-').toLowerCase().slice(0,60)||'peca',name:String(piece.name||piece.id||'Peça').slice(0,80),kind,
  footprint:wall?[num(piece.footprint?.[0],2,.25),0]:[num(piece.footprint?.[0],1,.25),num(piece.footprint?.[1],1,.25)],
  height:kind==='flat'?0:num(piece.height,1,0),cell:[num(piece.cell?.[0],1,-64),num(piece.cell?.[1],1,-64)],elevation:num(piece.elevation,0,0),
  image:piece.image||null,scale:SCALES.includes(piece.scale)?piece.scale:1,freeScale:Number.isFinite(piece.freeScale)?piece.freeScale:null,offset:[r(piece.offset?.[0]||0),r(piece.offset?.[1]||0)],locked:!!piece.locked};
}
// Caixa da peça: tamanho exato do PNG (R9), âncora e polígono esperado, em coordenadas do PNG.
export function pieceBox(piece){
 const p=normalizePiece(piece),[a,b]=p.footprint,hz=p.height*CELL.z;
 if(p.kind==='wallLeft'||p.kind==='wallRight'){
  const w=r(a*CELL.w/2),h=r(a*CELL.h/2+hz),drop=r(a*CELL.h/2);
  return p.kind==='wallRight'?{w,h,anchor:[w,h],poly:[[0,0],[w,drop],[w,h],[0,h-drop]]}:{w,h,anchor:[0,h],poly:[[w,0],[w,h-drop],[0,h],[0,drop]]};
 }
 const w=r((a+b)*CELL.w/2),h=r((a+b)*CELL.h/2+hz),ax=r(a*CELL.w/2),ly=r(h-a*CELL.h/2),ry=r(h-b*CELL.h/2),bx=r(b*CELL.w/2);
 const poly=hz?[[0,ly],[ax,h],[w,ry],[w,r(ry-hz)],[bx,0],[0,r(ly-hz)]]:[[0,ly],[ax,h],[w,ry],[bx,0]];
 return {w,h,anchor:[ax,h],poly};
}
// Ponto da grade onde fica a âncora: canto frontal da pegada (piso) ou canto mais baixo do objeto de parede.
export function anchorPoint(piece){const p=normalizePiece(piece);return p.kind==='wallRight'?{u:p.cell[0],v:0,h:p.elevation}:p.kind==='wallLeft'?{u:0,v:p.cell[1],h:p.elevation}:{u:p.cell[0],v:p.cell[1],h:p.elevation};}
export function footprintRect(piece){const p=normalizePiece(piece);if(p.kind.startsWith('wall'))return null;return {u0:p.cell[0]-p.footprint[0],v0:p.cell[1]-p.footprint[1],u1:p.cell[0],v1:p.cell[1]};}
export function placement(room,piece){const box=pieceBox(piece),a=anchorPoint(piece),s=screen(room,a.u,a.v,a.h);return {x:s.x-box.anchor[0],y:s.y-box.anchor[1],box};}
// Ordem de desenho: A vem antes de B quando A termina antes de B em u ou em v (pegadas não sobrepostas).
export function drawOrder(items){
 const rect=item=>item.rect,behind=(a,b)=>{const A=rect(a),B=rect(b);if(!A||!B)return false;return A.u1<=B.u0+1e-6||A.v1<=B.v0+1e-6;};
 const flat=items.filter(i=>i.layer==='flat'),walls=items.filter(i=>i.layer==='wall'),rest=items.filter(i=>!['flat','wall'].includes(i.layer)),out=[],left=[...rest];
 while(left.length){let pick=left.findIndex(a=>!left.some(b=>b!==a&&behind(b,a)&&!behind(a,b)));if(pick<0)pick=left.reduce((best,i,k)=>(i.rect.u1+i.rect.v1)<(left[best].rect.u1+left[best].rect.v1)?k:best,0);out.push(left.splice(pick,1)[0]);}
 return [...walls,...flat,...out];
}
// Conferência da cena: pegadas dentro do quarto e sem sobreposição; objetos de parede dentro da parede.
export function auditScene(room,pieces){
 const issues=[],list=pieces.map(normalizePiece);
 for(const p of list){
  const f=footprintRect(p);
  if(f){if(f.u0<-1e-6||f.v0<-1e-6||f.u1>room.cells[0]+1e-6||f.v1>room.cells[1]+1e-6)issues.push({level:'fail',piece:p.id,text:`${p.name}: pegada fora do quarto.`});}
  else{const along=p.kind==='wallRight'?p.cell[0]:p.cell[1],max=p.kind==='wallRight'?room.cells[0]:room.cells[1];if(along-p.footprint[0]<-1e-6||along>max+1e-6||p.elevation+p.height>room.wall+1e-6)issues.push({level:'fail',piece:p.id,text:`${p.name}: sai da parede.`});}
 }
 const solid=list.filter(p=>p.kind==='floor');
 for(let i=0;i<solid.length;i++)for(let j=i+1;j<solid.length;j++){const a=footprintRect(solid[i]),b=footprintRect(solid[j]),hA=[solid[i].elevation,solid[i].elevation+solid[i].height],hB=[solid[j].elevation,solid[j].elevation+solid[j].height];
  if(a.u0<b.u1-1e-6&&b.u0<a.u1-1e-6&&a.v0<b.v1-1e-6&&b.v0<a.v1-1e-6&&hA[0]<hB[1]-1e-6&&hB[0]<hA[1]-1e-6)issues.push({level:'fail',piece:solid[i].id,text:`${solid[i].name} e ${solid[j].name} ocupam as mesmas células.`});}
 const fraction=list.filter(p=>p.footprint.some(x=>x%.5)).map(p=>p.name);
 if(fraction.length)issues.push({level:'warn',text:`Pegada fora de meia célula: ${fraction.join(', ')} (R2).`});
 return issues;
}
// Ajuste automático: maior redução inteira que deixa a parte visível com a largura da caixa (R7: nunca fracionária).
export function autoFit(box,bounds){
 if(!bounds)return null;let best=null;
 for(const scale of SCALES){const w=bounds.w*scale,err=Math.abs(w-box.w);if(!best||err<best.err-1e-9)best={scale,err};}
 const exact=best.err<=Math.max(2,box.w*.03),scale=exact?best.scale:box.w/bounds.w;
 return {scale:exact?best.scale:1,freeScale:exact?null:scale,offset:[r(-bounds.x*scale),r(box.h-(bounds.y+bounds.h)*scale)],exact};
}
export function alphaBounds(img,threshold=128){
 let x0=img.width,y0=img.height,x1=-1,y1=-1;
 for(let y=0;y<img.height;y++)for(let x=0;x<img.width;x++)if(img.data[(y*img.width+x)*4+3]>=threshold){if(x<x0)x0=x;if(x>x1)x1=x;if(y<y0)y0=y;if(y>y1)y1=y;}
 return x1<0?null:{x:x0,y:y0,w:x1-x0+1,h:y1-y0+1};
}
function inside(poly,x,y){let hit=false;for(let i=0,j=poly.length-1;i<poly.length;j=i++){const [xi,yi]=poly[i],[xj,yj]=poly[j];if((yi>y)!==(yj>y)&&x<(xj-xi)*(y-yi)/(yj-yi)+xi)hit=!hit;}return hit;}
const near=(poly,x,y,t)=>inside(poly,x,y)||inside(poly,x-t,y)||inside(poly,x+t,y)||inside(poly,x,y-t)||inside(poly,x,y+t);
function theilSen(points){const s=[];const step=Math.max(1,Math.floor(points.length/40));for(let i=0;i<points.length;i+=step)for(let j=i+step;j<points.length;j+=step){const dx=points[j][0]-points[i][0];if(dx>=8)s.push((points[j][1]-points[i][1])/dx);}if(s.length<3)return null;s.sort((a,b)=>a-b);return s[s.length>>1];}
// Fonte: transparência falsa, halo e tamanho do bloco de pixel.
export function auditSource(img){
 const out=[],{width:w,height:h,data}=img,at=(x,y)=>(y*w+x)*4;
 const corners=[[0,0],[w-1,0],[0,h-1],[w-1,h-1]].filter(([x,y])=>data[at(x,y)+3]>250).length;
 let partial=0,visible=0;for(let i=3;i<data.length;i+=4){if(data[i]>0)visible++;if(data[i]>0&&data[i]<250)partial++;}
 if(corners>=3)out.push({level:'fail',rule:'R9',text:'Fundo opaco nos cantos: transparência falsa (xadrez ou branco). Peça o PNG com fundo transparente real.'});
 else if(!visible)out.push({level:'fail',rule:'R9',text:'Imagem toda transparente.'});
 const ratio=visible?partial/visible:0;
 if(ratio>.12)out.push({level:'warn',rule:'R7',text:`${Math.round(ratio*100)}% dos pixels visíveis são semitransparentes: halo ou antialias na borda.`});
 const block=pixelBlock(img);out.push({level:'info',rule:'R7',text:block>1?`Bloco de pixel da fonte ≈ ${block} px.`:'Fonte em 1 px por pixel de arte.',block});
 return out;
}
export function pixelBlock(img){
 const {width:w,height:h,data}=img;let best=1;
 for(const k of [8,6,5,4,3,2]){if(w<k*8||h<k*8)continue;let same=0,total=0;
  for(let y=0;y<h;y+=Math.max(1,Math.floor(h/64)))for(let x=0;x+1<w;x++){if(x%k===k-1)continue;const i=(y*w+x)*4;if(data[i+3]<128||data[i+7]<128)continue;total++;if(Math.abs(data[i]-data[i+4])+Math.abs(data[i+1]-data[i+5])+Math.abs(data[i+2]-data[i+6])<24)same++;}
  if(total>200&&same/total>.93){best=k;break;}}
 return best;
}
// Peça já no tamanho da caixa (W×H): pixels fora da caixa, inclinação das arestas de baixo, contato e preenchimento.
export function auditPiece(piece,img){
 const p=normalizePiece(piece),box=pieceBox(p),out=[],{width:w,height:h,data}=img,op=(x,y)=>x>=0&&y>=0&&x<w&&y<h&&data[(y*w+x)*4+3]>=128;
 if(w!==box.w||h!==box.h)out.push({level:'fail',rule:'R9',text:`PNG ${w}×${h}; a caixa pede ${box.w}×${box.h}.`});
 let outside=0,opaque=0;const mask=new Uint8Array(w*h);
 for(let y=0;y<h;y++)for(let x=0;x<w;x++)if(op(x,y)){opaque++;if(!near(box.poly,x+.5,y+.5,1)){outside++;mask[y*w+x]=1;}}
 if(!opaque){out.push({level:'fail',rule:'R3',text:'Nenhum pixel visível dentro da caixa.'});return {items:out,mask,stats:{}};}
 const limit=Math.max(6,opaque*.003);
 out.push(outside>limit?{level:'fail',rule:'R1·R5',text:`${outside} pixels fora da caixa (em vermelho). Ângulo diferente de 2:1, peça girada ou atravessando a parede.`}:outside?{level:'warn',rule:'R1',text:`${outside} pixels encostam fora da caixa; confira a borda.`}:{level:'ok',rule:'R1',text:'Nenhum pixel fora da caixa.'});
 const b=alphaBounds(img);
 const margins=[b.x,w-(b.x+b.w),h-(b.y+b.h)];
 if(Math.max(...margins)>2)out.push({level:'warn',rule:'R3',text:`Não preenche a caixa: margem de ${margins[0]} px à esquerda, ${margins[1]} à direita e ${margins[2]} embaixo.`});
 // Arestas de baixo: pixel visível mais baixo de cada coluna, comparado com a razão 2:1.
 const bottom=[];for(let x=0;x<w;x++){for(let y=h-1;y>=0;y--)if(op(x,y)){bottom.push([x,y]);break;}}
 const segs=p.kind==='wallLeft'?[[0,w,-.5,'base']]:p.kind==='wallRight'?[[0,w,.5,'base']]:[[0,box.anchor[0],.5,'esquerda'],[box.anchor[0],w,-.5,'direita']];
 const slopes={};
 for(const [x0,x1,want,label] of segs){const pts=bottom.filter(([x])=>x>=x0&&x<x1);const s=x1-x0<24||pts.length<(x1-x0)*.6?null:theilSen(pts);if(s===null){if(x1-x0>=24)out.push({level:'info',rule:'R1',text:`Inclinação da aresta de baixo (${label}) não medida: silhueta irregular. Confira a caixa rosa.`});continue;}slopes[label]=s;const dev=Math.abs(s-want)*32;
  out.push(dev>1?{level:'fail',rule:'R1',text:`Aresta de baixo (${label}) com inclinação ${s.toFixed(2).replace('.',',')}; o 2:1 pede ${want>0?'0,50':'−0,50'} (desvio de ${dev.toFixed(1).replace('.',',')} px a cada 32).`}:{level:'ok',rule:'R1',text:`Aresta de baixo (${label}) em 2:1.`});}
 if(p.kind!=='flat'){const [ax,ay]=box.anchor,touch=[-3,-2,-1,0,1,2].some(dx=>[0,1,2,3].some(dy=>op(ax+dx-(ax>=w?1:0),ay-1-dy)));
  out.push(touch?{level:'ok',rule:'R5',text:'Âncora encostada no piso.'}:{level:'warn',rule:'R5',text:'Nenhum pixel junto à âncora: a peça pode flutuar ou a base está recortada.'});}
 const area=polyArea(box.poly);
 return {items:out,mask,stats:{outside,opaque,fill:area?opaque/area:0,slopes,bounds:b}};
}
export function polyArea(poly){let s=0;for(let i=0,j=poly.length-1;i<poly.length;j=i++)s+=(poly[j][0]+poly[i][0])*(poly[j][1]-poly[i][1]);return Math.abs(s/2);}
export function verdict(items){return items.some(i=>i.level==='fail')?'fail':items.some(i=>i.level==='warn')?'warn':'ok';}
// Manifesto no formato da especificação (seção 6).
export function manifest(project,hasImage=p=>!!p.image){
 const room=project.room,pieces={};
 for(const raw of project.pieces){const p=normalizePiece(raw),box=pieceBox(p);
  pieces[p.id]={image:hasImage(p)?p.id+'.png':null,size:[box.w,box.h],kind:p.kind,footprint:p.kind.startsWith('wall')?[p.footprint[0]]:p.footprint,height:p.height,anchor:box.anchor,cell:p.kind.startsWith('wall')?(p.kind==='wallRight'?[p.cell[0],0]:[0,p.cell[1]]):p.cell,...(p.elevation?{elevation:p.elevation}:{}),...(p.kind.startsWith('wall')?{wall:p.kind==='wallLeft'?'esquerda':'direita'}:{}),rulesVersion:RULES};}
 return {name:project.name,grid:{cell:[CELL.w,CELL.h],height:CELL.z,scale:1},room:{cells:room.cells,wall:room.wall,image:room.image?'casca.png':null,origin:room.origin},pieces};
}
export function presetKaelRoom(){
 const room=defaultRoom([10,8],5),P=(id,name,kind,footprint,height,cell,elevation=0)=>normalizePiece({id,name,kind,footprint,height,cell,elevation});
 return {name:'Quarto do Kael',room,pieces:[
  P('tapete','Tapete','flat',[5,3],0,[8,6]),P('abertura-escada','Abertura da escada','flat',[3,2],0,[3,8]),
  P('janela','Janela','wallLeft',[2],1.5,[0,4],2.2),P('quadros','Quadros','wallRight',[2],1,[9.5,0],2.4),
  P('cama','Cama','floor',[2,4],2,[2,5]),P('estante','Estante de TV','floor',[3,1],1.3,[5,1]),P('tv','TV de tubo','floor',[1.5,1],1.3,[4.5,1],1.3),
  P('guarda-roupa','Guarda-roupa','floor',[2,1],4,[7,1]),P('mesa','Mesa de trabalho','floor',[3,2],1.5,[10,2])]};
}
// ZIP sem compressão (store) para baixar a entrega inteira de uma vez.
const crcTable=(()=>{const t=new Uint32Array(256);for(let n=0;n<256;n++){let c=n;for(let k=0;k<8;k++)c=c&1?0xedb88320^(c>>>1):c>>>1;t[n]=c>>>0;}return t;})();
export function crc32(bytes){let c=0xffffffff;for(const b of bytes)c=crcTable[(c^b)&255]^(c>>>8);return (c^0xffffffff)>>>0;}
export function zip(files){
 const enc=new TextEncoder(),parts=[],central=[];let offset=0;
 for(const f of files){const name=enc.encode(f.name),data=typeof f.data==='string'?enc.encode(f.data):f.data,crc=crc32(data),head=new DataView(new ArrayBuffer(30));
  [[0,0x04034b50,4],[4,20,2],[6,0x0800,2],[14,crc,4],[18,data.length,4],[22,data.length,4],[26,name.length,2]].forEach(([o,v,s])=>s===4?head.setUint32(o,v,true):head.setUint16(o,v,true));
  parts.push(new Uint8Array(head.buffer),name,data);
  const cd=new DataView(new ArrayBuffer(46));[[0,0x02014b50,4],[4,20,2],[6,20,2],[8,0x0800,2],[16,crc,4],[20,data.length,4],[24,data.length,4],[28,name.length,2],[42,offset,4]].forEach(([o,v,s])=>s===4?cd.setUint32(o,v,true):cd.setUint16(o,v,true));
  central.push(new Uint8Array(cd.buffer),name);offset+=30+name.length+data.length;}
 const size=central.reduce((s,b)=>s+b.length,0),end=new DataView(new ArrayBuffer(22));
 [[0,0x06054b50,4],[8,files.length,2],[10,files.length,2],[12,size,4],[16,offset,4]].forEach(([o,v,s])=>s===4?end.setUint32(o,v,true):end.setUint16(o,v,true));
 const all=[...parts,...central,new Uint8Array(end.buffer)],out=new Uint8Array(all.reduce((s,b)=>s+b.length,0));let at=0;for(const b of all){out.set(b,at);at+=b.length;}return out;
}
