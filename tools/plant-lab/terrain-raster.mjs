import {waterTint} from './water-colors.mjs';
import {isGround,groundBackground,GROUNDS} from './ground-kit.mjs';
import {GROUND_COLORS} from './ground-data.mjs';
import {wallSupport,surfaceSupport} from './terrain-field.mjs';
import {TILE} from './model.mjs';
import {rampSpan,rampSurface} from './ramp-surface.mjs';
import {shoreSand} from './water.mjs';
import {supportHeight,materialMask,shape,tile,variantFor,cliffPixel,pack,wallFaceColor,wallCap} from './autotile.mjs';
export const RASTER_PAD=200;
const CACHE=new WeakMap();
export function invalidateRaster(a){CACHE.delete(a);}
// Paint only the high side of actual height discontinuities. Ramp gradients
// remain continuous, including their mouths; no decorative line closes them.
export function reliefRim(heights,width,height,x,y){
 const z=heights[y*width+x];if(z<=0)return 0;
 for(const distance of [1,2])for(const [dx,dy]of [[-distance,0],[distance,0],[0,-distance],[0,distance]]){
  const xx=x+dx,yy=y+dy;if(xx>=0&&yy>=0&&xx<width&&yy<height&&z-heights[yy*width+xx]>.22)return distance;
 }return 0;
}
export function rasterPlan(a,refresh=false){
const signature=refresh?[a.width,a.height,a.autotiling!==false,a.levels.join(','),a.ramps.join(','),a.variants?.join(','),a.stairs?.join(','),a.waterDepth?.join(','),a.floors.join(','),a.cliffs.join(',')].join('|'):null,old=CACHE.get(a);
if(old&&(!refresh||old.signature===signature))return old;
const geometryKey=[a.width,a.height,a.autotiling!==false,a.levels.join(','),a.ramps.join(',')].join('|');
const materialState={variants:[...(a.variants??[])],floors:[...a.floors],cliffs:[...a.cliffs],stairs:[...(a.stairs??[])],waterDepth:[...(a.waterDepth??[])]};
if(old?.geometryKey===geometryKey){
 const changed=[];for(let i=0;i<a.levels.length;i++)if(Object.keys(materialState).some(k=>materialState[k][i]!==old.materialState[k][i]))changed.push(i);
 if(!changed.length){const result={...old,signature,materialState};CACHE.set(a,result);return result;}
 const affected=new Set(changed);for(const i of changed)for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){const x=i%a.width+dx,y=Math.floor(i/a.width)+dy;if(x>=0&&y>=0&&x<a.width&&y<a.height)affected.add(y*a.width+x);}
 let cellPixels=old.cellPixels;if(!cellPixels){const counts=new Uint32Array(a.levels.length);for(const i of old.owner)if(i>=0)counts[i]++;const offsets=new Uint32Array(counts.length+1);for(let i=0;i<counts.length;i++)offsets[i+1]=offsets[i]+counts[i];const cursor=offsets.slice(),indices=new Uint32Array(offsets.at(-1));for(let n=0;n<old.owner.length;n++){const i=old.owner[n];if(i>=0)indices[cursor[i]++]=n;}cellPixels={offsets,indices};}
 const top=old.top.slice(),faces=old.faces.slice(),{pixel,faceColor}=surfacePainters(a,old.heights,old.width,old.worldHeight);
 for(const i of affected)for(let j=cellPixels.offsets[i];j<cellPixels.offsets[i+1];j++){const n=cellPixels.indices[j],x=n%old.width,sy=Math.floor(n/old.width)-old.pad,y=Math.floor(old.depth[n]-(old.kind[n]?1:.5));if(old.kind[n])faces[n]=faceColor(i,x,y,old.zmap[n],sy);else top[n]=pixel(i,x,y);}
 const result={...old,signature,geometryKey,materialState,cellPixels,top,faces};CACHE.set(a,result);return result;
}
const width=a.width*TILE,worldHeight=a.height*TILE,height=worldHeight+RASTER_PAD,length=width*height;
let columns=null;
if(old&&old.width===width&&old.worldHeight===worldHeight&&old.geometryState?.autotiling===(a.autotiling!==false)){
 columns=new Uint8Array(width);
 for(let i=0;i<a.levels.length;i++)if(a.levels[i]!==old.geometryState.levels[i]||a.ramps[i]!==old.geometryState.ramps[i]||Object.keys(materialState).some(k=>materialState[k][i]!==old.materialState[k][i])){const cx=i%a.width;for(let x=Math.max(0,(cx-2)*32);x<Math.min(width,(cx+3)*32);x++)columns[x]=1;}
}
const geometryState={autotiling:a.autotiling!==false,levels:[...a.levels],ramps:[...a.ramps]};
const top=columns?old.top.slice():new Uint32Array(length),faces=columns?old.faces.slice():new Uint32Array(length),shadow=columns?old.shadow.slice():new Uint32Array(length),depth=columns?old.depth.slice():new Float32Array(length),zmap=columns?old.zmap.slice():new Float32Array(length),owner=columns?old.owner.slice():new Int32Array(length),kind=columns?old.kind.slice():new Uint8Array(length);
if(!columns){owner.fill(-1);depth.fill(-1);}else for(let y=0;y<height;y++)for(let x=0;x<width;x++)if(columns[x]){const n=y*width+x;top[n]=0;faces[n]=0;shadow[n]=0;depth[n]=-1;zmap[n]=0;owner[n]=-1;kind[n]=0;}
const heights=columns?old.heights.slice():new Float32Array(width*worldHeight);
for(let y=0;y<worldHeight;y++)for(let x=0;x<width;x++)if(!columns||columns[x])heights[y*width+x]=supportHeight(a,x+.5,y+.5);
const contacts=[],{pixel,faceColor}=surfacePainters(a,heights,width,worldHeight);
function put(x,sy,color,i,z,d,face=false){sy+=RASTER_PAD;if(sy<0||sy>=height)return;const n=sy*width+x;top[n]=face?0:color;faces[n]=face?color:0;shadow[n]=0;depth[n]=d;zmap[n]=z;owner[n]=i;kind[n]=face?1:0;}
for(let y=0;y<worldHeight;y++)for(let x=0;x<width;x++){if(columns&&!columns[x])continue;const i=surfaceSupport(a,x+.5,y+.5,0),c=pixel(i,x,y);put(x,y,c,i,0,y+.5);}
for(let y=0;y<worldHeight;y++)for(let x=0;x<width;x++){
 if(columns&&!columns[x])continue;
 const p=y*width+x,z=heights[p],i=surfaceSupport(a,x+.5,y+.5,z),next=y+1<worldHeight?heights[p+width]:0,sy=Math.floor(y-z*16),c=pixel(i,x,y),fall=z-next>.22;
 const end=fall?Math.floor(y+1-z*16):Math.max(sy+1,Math.floor(y+1-next*16));
 for(let yy=sy;yy<end;yy++)put(x,yy,c,i,z,y+.5);
 if(fall){const start=Math.floor(y+1-z*16),bottom=Math.floor(y+1-next*16),wallCell=wallSupport(a,x+.5,y+.5,z);
  for(let yy=start;yy<bottom;yy++)put(x,yy,faceColor(wallCell,x,y,z,yy),wallCell,z,y+1,true);
  contacts.push({x,y:bottom,low:next,front:y+1});
 }
}
for(const c of contacts)for(let d=0;d<3;d++){const yy=c.y+d+RASTER_PAD;if(yy<0||yy>=height)continue;const n=yy*width+c.x;if(owner[n]>=0&&!kind[n]&&depth[n]>=c.front-.1&&zmap[n]<=c.low+.1)shadow[n]=pack('273721',[62,35,15][d]);}
const result={signature,geometryKey,geometryState,materialState,width,height,pad:RASTER_PAD,worldHeight,top,faces,shadow,depth,zmap,owner,kind,heights};CACHE.set(a,result);return result;
}
export function samplePlan(a,p){const r=rasterPlan(a),x=Math.floor(p.x),y=Math.floor(p.y)+r.pad;if(x<0||x>=r.width||y<0||y>=r.height)return null;const n=y*r.width+x;if(r.owner[n]<0)return null;return {cell:r.owner[n],kind:r.kind[n]?'face':'top',z:r.zmap[n],depth:r.depth[n]};}
export function occlusionRects(a,o,bounds){const r=rasterPlan(a),z=supportHeight(a,o.x,o.y),rects=[];const x0=Math.max(0,Math.floor(bounds.x)),x1=Math.min(r.width,Math.ceil(bounds.x+bounds.w)),y0=Math.max(-r.pad,Math.floor(bounds.y)),y1=Math.min(r.worldHeight,Math.ceil(bounds.y+bounds.h));const active=new Map();
for(let y=y0;y<y1;y++){const runs=[];let start=-1;for(let x=x0;x<=x1;x++){const n=(y+r.pad)*r.width+x,hidden=x<x1&&r.owner[n]>=0&&r.depth[n]>o.y+.01&&r.zmap[n]>z+.001;if(hidden&&start<0)start=x;if(!hidden&&start>=0){runs.push([start,x-start]);start=-1;}}
const seen=new Set();for(const [x,w]of runs){const key=x+':'+w;seen.add(key);const before=active.get(key);if(before&&before.y+before.h===y)before.h++;else{const n={x,y,w,h:1};rects.push(n);active.set(key,n);}}for(const k of active.keys())if(!seen.has(k))active.delete(k);
}return rects;}


export function surfacePainters(a,heights,width,worldHeight){
const masks=a.floors.map((k,i)=>a.autotiling===false?255:materialMask(a,i));
const tiles=a.floors.map((k,i)=>tile(k,masks[i],a.variants?.[i]??variantFor(i%a.width,Math.floor(i/a.width))));
const spans=a.ramps.map((r,i)=>r?rampSpan(a,i):null);
const rims={grass:[0,pack('526d38'),pack('b2c777')],dirt:[0,pack('886b42'),pack('d9b57a')],stone:[0,pack('58675b'),pack('c0c7a4')],sand:[0,pack('aa905e'),pack('ead29a')],water:[0,pack('315e58'),pack('67b9b1')]};
for(const [id,c]of Object.entries(GROUND_COLORS))rims[id]=[0,pack(c.dark),pack(c.light)];
const sandy=a.floors.map((k,i)=>k==='water'&&shoreSand(a,i));
const pixel=(i,x,y)=>{const ix=y%32*32+x%32,k=a.floors[i];let color=tiles[i][ix];const back=isGround(k)&&!spans[i]&&a.autotiling!==false&&!shape(masks[i])[ix]?groundBackground(a,i,x%32,y%32):null;if(back)color=tile(back,255,a.variants?.[i]??variantFor(i%a.width,Math.floor(i/a.width)))[ix];if(spans[i]&&isGround(k))color=tile(k,255,a.variants?.[i]??variantFor(i%a.width,Math.floor(i/a.width)))[ix];if(k==='water'&&(a.autotiling===false||shape(masks[i])[ix]))color=waterTint(color,a.waterDepth?.[i]??0);if(sandy[i]&&a.autotiling!==false&&!shape(masks[i])[ix])color=tile('sand',255,a.variants?.[i]??variantFor(i%a.width,Math.floor(i/a.width)))[ix];const s=spans[i];if(s){const d=a.ramps[i],cross=s.horizontal?y-s.left:x-s.left,along=d==='n'?y%32:d==='s'?31-y%32:d==='e'?31-x%32:x%32;let result=rampSurface(color,cross,along,s.width);if(a.stairs?.[i]&&along%6===0)result=pack('665641');return result;}const rim=reliefRim(heights,width,worldHeight,x,y);if(!rim)return color;const surface=isGround(k)?(back??k):k==='dirt'||(a.autotiling!==false&&!shape(masks[i])[ix])?'dirt':k;return rims[surface][rim];};
const faceColor=(wallCell,x,y,z,sy)=>{const distance=sy-Math.floor(y+1-z*16),i=surfaceSupport(a,x+.5,y+.5,z),wallKind=a.cliffs[wallCell],grass=(a.floors[i]==='grass'||GROUNDS.some(g=>g.id===a.floors[i]&&g.family==='Gramas'))&&(a.autotiling===false||shape(masks[i])[y%32*32+x%32]);let color=wallFaceColor(wallKind,x,y+1-sy,distance);if(distance<2)color=grass?pack(distance?'79974b':'496c35'):wallCap(wallKind,distance);if(distance===2&&grass&&x%4<3)color=pack('9cb85e');return color;};
return {pixel,faceColor};
}
