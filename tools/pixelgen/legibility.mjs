// Readability tools: silhouette, outlines and a contrast report against game grounds.
// Pure functions over the indexed document; the editor only draws their results.
import {addLayer,compositeFrame,compositeAll,editable,layerPixels} from './document.mjs';
// Representative ground colours from the overworld kits (grass, dirt, sidewalk, night).
export const GROUNDS={grama:[111,154,74],terra:[196,132,78],calcada:[214,207,192],noite:[27,34,48]};
export const GROUND_LABELS={grama:'Grama',terra:'Terra',calcada:'Calçada',noite:'Noite'};
const channel=v=>{v/=255;return v<=.03928?v/12.92:((v+.055)/1.055)**2.4;};
export const luminance=([r,g,b])=>.2126*channel(r)+.7152*channel(g)+.0722*channel(b);
export const contrast=(a,b)=>{const x=luminance(a),y=luminance(b);return (Math.max(x,y)+.05)/(Math.min(x,y)+.05);};
const N4=[[1,0],[-1,0],[0,1],[0,-1]],N8=[...N4,[1,1],[1,-1],[-1,1],[-1,-1]];
// Opaque pixels touching transparency or the frame border: the silhouette's own edge.
export function edgeMask(indices,w,h){const out=new Uint8Array(w*h);
 for(let y=0;y<h;y++)for(let x=0;x<w;x++){const i=y*w+x;if(!indices[i])continue;
  out[i]=N4.some(([dx,dy])=>{const a=x+dx,b=y+dy;return a<0||b<0||a>=w||b>=h||!indices[b*w+a];})?1:0;}
 return out;}
// Transparent pixels just outside the silhouette (4- or 8-neighbour ring).
export function outsideRing(indices,w,h,diagonal=false){const out=new Uint8Array(w*h),near=diagonal?N8:N4;
 for(let y=0;y<h;y++)for(let x=0;x<w;x++){const i=y*w+x;if(indices[i])continue;
  out[i]=near.some(([dx,dy])=>{const a=x+dx,b=y+dy;return a>=0&&b>=0&&a<w&&b<h&&indices[b*w+a];})?1:0;}
 return out;}
export function darkest(palette){let best=1;for(let i=1;i<palette.length;i++)if(luminance(palette[i])<luminance(palette[best]))best=i;return best;}
// Shade for a selective outline: a clearly darker palette entry of the same colour family.
export function darker(palette,index){const own=palette[index],target=luminance(own)*.55;let best=-1,score=Infinity;
 for(let i=1;i<palette.length;i++){if(i===index)continue;const c=palette[i],l=luminance(c);if(l>=luminance(own)*.8)continue;
  const sum=own[0]+own[1]+own[2]||1,csum=c[0]+c[1]+c[2]||1,hue=Math.abs(own[0]/sum-c[0]/csum)+Math.abs(own[1]/sum-c[1]/csum)+Math.abs(own[2]/sum-c[2]/csum);
  const s=hue*3+Math.abs(l-target)*4;if(s<score){score=s;best=i;}}
 return best<0?darkest(palette):best;}
const framesOf=(p,frames)=>frames==null?p.frames.map((_,i)=>i):[].concat(frames);
// Outer contour on its own top layer, so it can be hidden, edited or removed later.
export function addOutline(p,{frames=null,color=darkest(p.palette),diagonal=false}={}){
 const list=framesOf(p,frames);compositeAll(p);const rings=list.map(i=>outsideRing(p.frames[i].indices,p.width,p.height,diagonal));
 const layer=addLayer(p,p.layers.length-1,'Contorno');list.forEach((i,n)=>{const cel=p.frames[i].cels[layer];rings[n].forEach((v,k)=>{if(v)cel[k]=color;});});
 compositeAll(p);return layer;}
// Selective outline (sel-out): the active layer's pixels on the silhouette edge take a darker shade of their own colour.
export function selectiveOutline(p,layer,{frames=null}={}){editable(p,layer);const cache=new Map();let changed=0;
 for(const i of framesOf(p,frames)){const f=p.frames[i],edge=edgeMask(compositeFrame(p,f),p.width,p.height),cel=layerPixels(p,i,layer);
  for(let k=0;k<cel.length;k++)if(edge[k]&&cel[k]&&f.indices[k]===cel[k]){if(!cache.has(cel[k]))cache.set(cel[k],darker(p.palette,cel[k]));const next=cache.get(cel[k]);if(next!==cel[k]){cel[k]=next;changed++;}}
  compositeFrame(p,f);}
 return changed;}
export function silhouetteRGBA(indices,ink=[20,24,30],paper=[233,228,216]){const out=new Uint8ClampedArray(indices.length*4);
 for(let i=0;i<indices.length;i++){out.set(indices[i]?ink:paper,i*4);out[i*4+3]=255;}return out;}
// Measures what makes a small sprite read: a closed dark contour, contrast with the ground, distinguishable neighbours.
export function legibilityReport(p,{frames=null}={}){
 const list=framesOf(p,frames),w=p.width,h=p.height,result={frames:[],grounds:{},warnings:[]};let edges=0,dark=0,pairs=0,confusing=0;const low={};
 for(const key of Object.keys(GROUNDS))low[key]=0;
 for(const i of list){const f=p.frames[i],ind=compositeFrame(p,f),edge=edgeMask(ind,w,h);let fe=0,fd=0;
  for(let k=0;k<ind.length;k++){if(!ind[k])continue;const c=p.palette[ind[k]];
   if(edge[k]){fe++;if(luminance(c)<.05)fd++;for(const [key,g] of Object.entries(GROUNDS))if(contrast(c,g)<1.6)low[key]++;}
   const x=k%w,y=Math.floor(k/w);for(const [dx,dy] of [[1,0],[0,1]]){const a=x+dx,b=y+dy;if(a>=w||b>=h)continue;const j=b*w+a;if(!ind[j]||ind[j]===ind[k])continue;pairs++;if(contrast(c,p.palette[ind[j]])<1.12)confusing++;}}
  edges+=fe;dark+=fd;result.frames.push({frame:f.name,edgePixels:fe,darkEdge:fe?fd/fe:0});}
 result.darkEdge=edges?dark/edges:0;result.confusingNeighbours=pairs?confusing/pairs:0;
 for(const key of Object.keys(GROUNDS))result.grounds[key]=edges?low[key]/edges:0;
 const pct=v=>Math.round(v*100)+'%';
 if(result.darkEdge<.7)result.warnings.push(`Contorno escuro cobre ${pct(result.darkEdge)} da borda. Abaixo de 70% a silhueta se mistura ao chão; use Contorno externo ou seletivo.`);
 for(const [key,v] of Object.entries(result.grounds))if(v>.25)result.warnings.push(`${GROUND_LABELS[key]}: ${pct(v)} da borda com pouco contraste com o chão.`);
 if(result.confusingNeighbours>.18)result.warnings.push(`${pct(result.confusingNeighbours)} das cores vizinhas têm quase o mesmo brilho; separe os tons de cabelo, pele e roupa.`);
 const weak=result.frames.filter(r=>r.edgePixels&&r.darkEdge<.5).map(r=>r.frame);
 if(weak.length&&weak.length<list.length)result.warnings.push(`Quadros com contorno fraco: ${weak.slice(0,6).join(', ')}${weak.length>6?'…':''}.`);
 return result;}
