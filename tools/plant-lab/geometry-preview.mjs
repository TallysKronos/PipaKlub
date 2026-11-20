import {waterfallPixels,isWaterfall} from './waterfalls.mjs';
import {WATERFALL_RGBA} from './waterfall-data.mjs';
import {buildRiver} from './river-builder.mjs';
import {geometryEdit} from './geometry-edit.mjs';
import {rasterPlan} from './terrain-raster.mjs';
import {pasteRegion} from './regions.mjs';
export function geometryPreview(a,options){
 const edit=options.tool==='river'?buildRiver(a,options.from,options.cell,{width:options.riverWidth,depth:options.riverDepth,seed:options.seed,focus:options.focus}):options.tool==='stamp'?pasteRegion(a,options.stamp,options.cell,{relative:options.relative,focus:options.focus}):geometryEdit(a,options);if(!edit.valid)return edit;
 if(options.tool==='stamp'){edit.changed=true;edit.cells=options.stamp.cells.map(c=>(Math.floor(options.cell/a.width)+c.y)*a.width+options.cell%a.width+c.x);}
 const before=rasterPlan(a),after=edit.changed?rasterPlan(edit.next):before,data=new Uint32Array(after.width*after.height),mask=new Uint8Array(data.length),cells=new Set(edit.cells);
 let minX=after.width,minY=after.height,maxX=-1,maxY=-1;
 for(let n=0;n<data.length;n++){
  const changed=before.top[n]!==after.top[n]||before.faces[n]!==after.faces[n]||before.shadow[n]!==after.shadow[n];
  const selected=cells.has(after.owner[n]);if(!changed&&!selected)continue;
  const x=n%after.width,y=Math.floor(n/after.width);minX=Math.min(minX,x);maxX=Math.max(maxX,x);minY=Math.min(minY,y);maxY=Math.max(maxY,y);
  if(selected)mask[n]=1;if(!changed)continue;
  let color=after.faces[n]||after.top[n]||0xff282e27;
  const s=after.shadow[n],alpha=s>>>24;if(alpha){const red=Math.round(((s&255)*alpha+(color&255)*(255-alpha))/255),green=Math.round(((s>>>8&255)*alpha+(color>>>8&255)*(255-alpha))/255),blue=Math.round(((s>>>16&255)*alpha+(color>>>16&255)*(255-alpha))/255);color=(red|green<<8|blue<<16|255<<24)>>>0;}
  data[n]=color;
 }
 if(options.tool==='river'){
  const bytes=Uint8Array.from(atob(WATERFALL_RGBA),c=>c.charCodeAt(0)),atlas=new Uint32Array(bytes.buffer);
  for(const o of edit.next.objects.filter(o=>isWaterfall(o.asset)&&o.id>=a.nextId)){const p=waterfallPixels(edit.next,o,atlas,0);if(!p)continue;for(let y=0;y<p.height;y++)for(let x=0;x<p.width;x++){const c=p.data[y*p.width+x],alpha=c>>>24;if(!alpha)continue;const xx=p.x+x,yy=p.y+y+after.pad,n=yy*after.width+xx;if(xx<0||xx>=after.width||yy<0||yy>=after.height)continue;const b=data[n]||after.faces[n]||after.top[n],red=Math.round(((c&255)*alpha+(b&255)*(255-alpha))/255),green=Math.round(((c>>>8&255)*alpha+(b>>>8&255)*(255-alpha))/255),blue=Math.round(((c>>>16&255)*alpha+(b>>>16&255)*(255-alpha))/255);data[n]=(red|green<<8|blue<<16|255<<24)>>>0;}}
 }
 return {valid:true,changed:edit.changed,message:edit.message,width:after.width,height:after.height,pad:after.pad,data,mask,bounds:{x:minX,y:minY-after.pad,width:maxX-minX+1,height:maxY-minY+1}};
}
