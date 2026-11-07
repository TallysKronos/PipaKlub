import test from 'node:test';import assert from 'node:assert/strict';
import {waterfallSample,waterfallGeometry,waterfallPixels} from './waterfalls.mjs';
import {initialLayout,validateLayout} from './model.mjs';import {rasterPlan} from './terrain-raster.mjs';import {waterAt} from './water.mjs';
import {WATERFALL_RGBA} from './waterfall-data.mjs';
const bytes=Uint8Array.from(atob(WATERFALL_RGBA),c=>c.charCodeAt(0)),atlas=new Uint32Array(bytes.buffer);
test('waterfalls round trip as independent objects and use actual drop height',()=>{
 const a=waterfallSample(initialLayout());assert.deepEqual(validateLayout(a),a);
 for(const o of a.objects){const g=waterfallGeometry(a,o);assert(g);assert(g.columns.filter(Boolean).every(c=>c.high===5&&c.low===0&&c.bottom-c.top===80));}
 const b=structuredClone(a);b.floors.fill('grass');assert.equal(waterfallGeometry(b,b.objects[0]),null);
 const c=structuredClone(a);c.levels.fill(0);assert.equal(waterfallGeometry(c,c.objects[0]),null);
});
test('all waterfall frames stay on the cliff or supporting water, never walking ground',()=>{
 const a=waterfallSample(initialLayout()),r=rasterPlan(a);let colored=0,splashes=0;
 for(const o of a.objects)for(let phase=0;phase<4;phase++){
  const p=waterfallPixels(a,o,atlas,phase);assert(p);
  for(let y=0;y<p.height;y++)for(let x=0;x<p.width;x++)if(p.data[y*p.width+x]>>>24){
   const xx=p.x+x,yy=p.y+y,n=(yy+r.pad)*r.width+xx;assert(r.owner[n]>=0);colored++;
   if(!r.kind[n]){assert.equal(a.floors[r.owner[n]],'water');const wy=r.depth[n]-.5;assert(waterAt(a,xx,wy));if(r.zmap[n]===0)splashes++;}
  }
 }
 assert(colored>10000);assert(splashes>100);
});
test('animation has four distinct phases and changing terrain removes invalid falls',()=>{
 const a=waterfallSample(initialLayout()),o=a.objects[0],frames=[0,1,2,3].map(p=>waterfallPixels(a,o,atlas,p));
 assert.equal(new Set(frames.map(f=>Buffer.from(f.data.buffer).toString('base64'))).size,4);
 const b=structuredClone(a);b.floors=b.floors.map((k,i)=>b.levels[i]===0?'grass':k);assert.equal(waterfallPixels(b,b.objects[0],atlas,0),null);
});
test('curved river outlet overlaps the upper water with a feathered upstream approach',()=>{
 const a=waterfallSample(initialLayout());a.objects=[a.objects[0]];a.objects[0].y=224;
 a.levels[6*a.width+5]=5;a.floors[6*a.width+5]='water';for(let x=4;x<=6;x++)a.floors[5*a.width+x]='water';
 const p=waterfallPixels(a,a.objects[0],atlas,0),g=waterfallGeometry(a,a.objects[0]),r=rasterPlan(a);assert(p);let upstream=0,blended=0;
 assert(new Set(g.columns.filter(Boolean).map(c=>c.front)).size>1,'Outlet must follow a curved edge');
 for(let y=0;y<p.height;y++)for(let x=0;x<p.width;x++){
  const alpha=p.data[y*p.width+x]>>>24;if(!alpha)continue;const xx=p.x+x,yy=p.y+y,n=(yy+r.pad)*r.width+xx;
  if(!r.kind[n]&&r.zmap[n]===5){const col=g.columns[Math.max(0,Math.min(g.columns.length-1,xx-g.left))];if(col&&yy<col.top-8)upstream++;if(alpha<255)blended++;}
 }
 assert(upstream>50);assert(blended>50);
});
