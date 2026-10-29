// Structured drawing for agents and scripts. Every operation is a plain JSON object, so a
// whole pose can be written, reviewed and replayed. Colours: palette index, "#rrggbb", or a
// named ramp shade "pele:1" (0 = darkest). Targets: frame index, name, list or "all"; layer
// index or name.
import {addLayer,compositeFrame,compositeAll,editable,layerPixels} from './document.mjs';
import {duplicateFrame,deleteFrame,sequencesFor} from './animation.mjs';
import {addOutline,selectiveOutline} from './legibility.mjs';
const hexRGB=h=>{const m=/^#?([0-9a-f]{6})$/i.exec(h);if(!m)throw Error(`Cor inválida: ${h}`);const n=parseInt(m[1],16);return [n>>16,(n>>8)&255,n&255,255];};
export const toHex=c=>'#'+c.slice(0,3).map(v=>v.toString(16).padStart(2,'0')).join('');
export function colorIndex(p,spec){
 if(spec===0||spec==='transparente'||spec==='none')return 0;
 if(Number.isInteger(spec)){if(spec<0||spec>=p.palette.length)throw Error(`Índice de cor fora da paleta: ${spec}`);return spec;}
 if(typeof spec!=='string')throw Error('Informe a cor como índice, #hex ou rampa:tom.');
 const ramp=/^([a-z0-9-]+):(\d+)$/.exec(spec);
 if(ramp){const list=p.ramps?.[ramp[1]];if(!list)throw Error(`Rampa desconhecida: ${ramp[1]}. Crie com o comando ramp.`);const i=Number(ramp[2]);if(i>=list.length)throw Error(`A rampa ${ramp[1]} tem ${list.length} tons (0–${list.length-1}).`);return list[i];}
 const rgb=hexRGB(spec),found=p.palette.findIndex((c,i)=>i&&c[0]===rgb[0]&&c[1]===rgb[1]&&c[2]===rgb[2]);
 if(found>0)return found;if(p.palette.length>=256)throw Error('Paleta cheia (256).');p.palette.push(rgb);return p.palette.length-1;
}
// Ramp: dark → light. Colours are added to the palette when missing.
export function setRamp(p,name,colors){if(!/^[a-z0-9-]{1,32}$/.test(name))throw Error('Nome de rampa: letras minúsculas, números e hífen.');p.ramps={...(p.ramps||{}),[name]:colors.map(c=>colorIndex(p,c))};return p.ramps[name];}
export function frameList(p,target){
 if(target===undefined||target===null)return [0];if(target==='all')return p.frames.map((_,i)=>i);
 const one=t=>{if(Number.isInteger(t)){if(t<0||t>=p.frames.length)throw Error(`Quadro inexistente: ${t}`);return [t];}
  const seq=sequencesFor(p).find(s=>s.name===t);if(seq)return Array.from({length:seq.end-seq.start+1},(_,i)=>seq.start+i);
  const i=p.frames.findIndex(f=>f.name===t);if(i<0)throw Error(`Quadro ou sequência inexistente: ${t}`);return [i];};
 return [...new Set([].concat(target).flatMap(one))];
}
export function layerIndex(p,target){if(target===undefined||target===null)return p.layers.length-1;if(Number.isInteger(target)){if(!p.layers[target])throw Error(`Camada inexistente: ${target}`);return target;}
 const i=p.layers.findIndex(l=>l.name===target);if(i<0)throw Error(`Camada inexistente: ${target}. Camadas: ${p.layers.map(l=>l.name).join(', ')}`);return i;}
function plot(p,cel,x,y,c,clip){if(x<0||y<0||x>=p.width||y>=p.height)return;if(clip&&(x<clip.x||y<clip.y||x>=clip.x+clip.w||y>=clip.y+clip.h))return;cel[y*p.width+x]=c;}
function linePoints(a,b){const pts=[];let [x,y]=a;const [x1,y1]=b,dx=Math.abs(x1-x),dy=-Math.abs(y1-y),sx=x<x1?1:-1,sy=y<y1?1:-1;let err=dx+dy;
 for(;;){pts.push([x,y]);if(x===x1&&y===y1)break;const e=2*err;if(e>=dy){err+=dy;x+=sx;}if(e<=dx){err+=dx;y+=sy;}}return pts;}
// Pixel-perfect: drop L-corner pixels so 1-px lines never double up.
function perfect(pts){if(pts.length<3)return pts;const out=[pts[0]];for(let i=1;i<pts.length-1;i++){const a=out[out.length-1],b=pts[i],c=pts[i+1];
 if((a[0]===b[0]||a[1]===b[1])&&(b[0]===c[0]||b[1]===c[1])&&a[0]!==c[0]&&a[1]!==c[1])continue;out.push(b);}out.push(pts[pts.length-1]);return out;}
function ellipsePoints(cx,cy,rx,ry,fill){const pts=[];for(let y=-ry;y<=ry;y++)for(let x=-rx;x<=rx;x++){const d=(x*x)/((rx+.5)**2)+(y*y)/((ry+.5)**2);
 if(d<=1&&(fill||(x+1)**2/((rx+.5)**2)+(y*y)/((ry+.5)**2)>1||(x-1)**2/((rx+.5)**2)+(y*y)/((ry+.5)**2)>1||(x*x)/((rx+.5)**2)+(y+1)**2/((ry+.5)**2)>1||(x*x)/((rx+.5)**2)+(y-1)**2/((ry+.5)**2)>1))pts.push([cx+x,cy+y]);}return pts;}
const brushed=(pts,size)=>{if(!size||size<=1)return pts;const r=Math.floor(size/2),out=[];for(const [x,y] of pts)for(let dy=-r;dy<size-r;dy++)for(let dx=-r;dx<size-r;dx++)out.push([x+dx,y+dy]);return out;};
// One operation on one frame/layer. Returns how many pixels changed.
function applyOne(p,op,frame,layer){
 const cel=layerPixels(p,frame,layer),before=cel.slice(),c=op.color===undefined?undefined:colorIndex(p,op.color),clip=op.clip,w=p.width;
 const put=pts=>{for(const [x,y] of brushed(pts,op.size))plot(p,cel,x,y,c,clip);};
 switch(op.op){
  case 'pixel':put([[op.x,op.y]]);break;
  case 'pixels':put(op.points);break;
  case 'line':{const pts=[];for(let i=0;i<op.points.length-1;i++)pts.push(...linePoints(op.points[i],op.points[i+1]));put(op.perfect===false?pts:perfect(pts));break;}
  case 'rect':{const pts=[];for(let y=op.y;y<op.y+op.h;y++)for(let x=op.x;x<op.x+op.w;x++)if(op.fill!==false||y===op.y||x===op.x||y===op.y+op.h-1||x===op.x+op.w-1)pts.push([x,y]);put(pts);break;}
  case 'ellipse':put(ellipsePoints(op.cx,op.cy,op.rx,op.ry,op.fill!==false));break;
  case 'fill':{const t=cel[op.y*w+op.x];if(t===c)break;const q=[[op.x,op.y]];cel[op.y*w+op.x]=c;while(q.length){const [x,y]=q.pop();for(const [a,b] of [[x+1,y],[x-1,y],[x,y+1],[x,y-1]])if(a>=0&&b>=0&&a<w&&b<p.height&&cel[b*w+a]===t&&(!clip||(a>=clip.x&&b>=clip.y&&a<clip.x+clip.w&&b<clip.y+clip.h))){cel[b*w+a]=c;q.push([a,b]);}}break;}
  case 'erase':{const r=op.rect||{x:0,y:0,w,h:p.height};for(let y=r.y;y<r.y+r.h;y++)for(let x=r.x;x<r.x+r.w;x++)plot(p,cel,x,y,0);break;}
  case 'replace':{const from=colorIndex(p,op.from),to=colorIndex(p,op.to);for(let i=0;i<cel.length;i++)if(cel[i]===from)cel[i]=to;break;}
  case 'shift':{cel.fill(0);for(let y=0;y<p.height;y++)for(let x=0;x<w;x++){const v=before[y*w+x];if(v)plot(p,cel,x+(op.dx||0),y+(op.dy||0),v);}break;}
  case 'flip':{const r=op.rect||{x:0,y:0,w,h:p.height};for(let y=0;y<r.h;y++)for(let x=0;x<r.w;x++){const sx=op.axis==='y'?r.x+x:r.x+r.w-1-x,sy=op.axis==='y'?r.y+r.h-1-y:r.y+y;cel[(r.y+y)*w+r.x+x]=before[sy*w+sx];}break;}
  case 'mirror':{// Copy the left half onto the right (or top onto bottom) around an axis, for symmetric front/back views.
   const axis=op.axis??Math.floor(w/2);for(let y=0;y<p.height;y++)for(let x=0;x<w;x++){const m=2*axis-1-x;if(op.from==='right'?x>=axis&&m>=0:x<axis&&m<w){const v=before[y*w+x];if(m>=0&&m<w)cel[y*w+m]=v;}}break;}
  case 'copy':{// Region from another frame/layer, with offset and optional flip; transparent pixels skipped unless opaque:true.
   const sf=frameList(p,op.fromFrame??frame)[0],sl=layerIndex(p,op.fromLayer??layer),src=sf===frame&&sl===layer?before:layerPixels(p,sf,sl),r=op.rect||{x:0,y:0,w,h:p.height};
   for(let y=0;y<r.h;y++)for(let x=0;x<r.w;x++){const sx=op.flip==='x'?r.x+r.w-1-x:r.x+x,sy=op.flip==='y'?r.y+r.h-1-y:r.y+y;if(sx<0||sy<0||sx>=w||sy>=p.height)continue;const v=src[sy*w+sx];if(v||op.opaque)plot(p,cel,r.x+x+(op.dx||0),r.y+y+(op.dy||0),v,clip);}break;}
  default:throw Error(`Operação desconhecida: ${op.op}`);
 }
 let n=0;for(let i=0;i<cel.length;i++)if(cel[i]!==before[i])n++;return n;
}
// Document-level operations (layers, frames, sequences, outlines) plus pixel operations.
export function apply(p,ops){
 const log=[];
 for(const [k,op] of ops.entries()){
  try{
   switch(op.op){
    case 'ramp':log.push({op:'ramp',name:op.name,indices:setRamp(p,op.name,op.colors)});continue;
    case 'layer':{
     if(op.add){if(p.layers.some(l=>l.name===op.add))throw Error(`A camada ${op.add} já existe.`);const at=addLayer(p,op.below?layerIndex(p,op.below)-1:p.layers.length-1,op.add);log.push({op:'layer',added:op.add,index:at});continue;}
     const i=layerIndex(p,op.name);if(op.rename)p.layers[i].name=op.rename;if(op.visible!==undefined)p.layers[i].visible=!!op.visible;if(op.locked!==undefined)p.layers[i].locked=!!op.locked;
     if(op.remove){if(p.layers.length===1)throw Error('Mantenha uma camada.');p.layers.splice(i,1);for(const f of p.frames)f.cels.splice(i,1);}
     compositeAll(p);log.push({op:'layer',name:op.name});continue;}
    case 'frame':{
     if(op.add!==undefined){const base=frameList(p,op.copy??p.frames.length-1)[0],i=duplicateFrame(p,base);p.frames[i].name=String(op.add);if(op.copy===undefined)for(const c of p.frames[i].cels)c.fill(0);if(op.duration)p.frames[i].duration=op.duration;
      if(op.at!==undefined&&op.at!==i){const [f]=p.frames.splice(i,1);p.frames.splice(op.at,0,f);p.frames.forEach((q,n)=>{q.row=Math.floor(n/p.cols);q.col=n%p.cols;});}log.push({op:'frame',added:op.add,index:op.at??i});continue;}
     const list=frameList(p,op.target);if(op.remove){for(const i of [...list].sort((a,b)=>b-a))deleteFrame(p,i);log.push({op:'frame',removed:list.length});continue;}
     for(const i of list){if(op.rename)p.frames[i].name=op.rename;if(op.duration)p.frames[i].duration=Math.max(20,Math.min(2000,op.duration));}log.push({op:'frame',updated:list.length});continue;}
    case 'sequence':{const list=sequencesFor(p).map(s=>({...s})).filter(s=>s.name!==op.name);
     if(!op.remove){const range=frameList(p,op.frames);const start=Math.min(...range),end=Math.max(...range);if(end-start+1!==range.length)throw Error('Uma sequência usa quadros vizinhos.');list.push({name:op.name,start,end,loop:op.loop!==false,direction:['reverse','pingpong'].includes(op.direction)?op.direction:'forward'});}
     p.sequences=list.length?list:undefined;log.push({op:'sequence',name:op.name});continue;}
    case 'outline':{const frames=op.target===undefined?null:frameList(p,op.target);const i=addOutline(p,{frames,color:op.color===undefined?undefined:colorIndex(p,op.color),diagonal:!!op.diagonal});log.push({op:'outline',layer:p.layers[i].name});continue;}
    case 'selout':{const frames=op.target===undefined?null:frameList(p,op.target);log.push({op:'selout',changed:selectiveOutline(p,layerIndex(p,op.layer),{frames})});continue;}
   }
   const layer=layerIndex(p,op.layer);editable(p,layer);let changed=0;
   for(const f of frameList(p,op.frame)){changed+=applyOne(p,op,f,layer);compositeFrame(p,p.frames[f]);}
   log.push({op:op.op,changed});
  }catch(e){throw Error(`Operação ${k+1} (${op.op}): ${e.message}`);}
 }
 return log;
}
