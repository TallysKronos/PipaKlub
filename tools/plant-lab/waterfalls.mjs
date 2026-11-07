import {terrainHeight} from './terrain-field.mjs';
import {rasterPlan} from './terrain-raster.mjs';
import {waterAt} from './water.mjs';
import {WATERFALLS} from './waterfall-assets.mjs';
export {WATERFALLS,isWaterfall} from './waterfall-assets.mjs';
export function waterfallGeometry(a,o){
 const definition=WATERFALLS.find(w=>w.id===o.asset);if(!definition)return null;
 const left=Math.round(o.x-definition.width/2),columns=[];
 for(let x=left;x<left+definition.width;x++){
  let best=null;
  for(let y=Math.max(1,Math.round(o.y)-20);y<Math.min(a.height*32-1,Math.round(o.y)+21);y++){
   if(x<0||x>=a.width*32)continue;
   const high=terrainHeight(a,x+.5,y-.5),low=terrainHeight(a,x+.5,y+.5);
   if(high-low<.99||!waterAt(a,x+.5,y-1)||!waterAt(a,x+.5,y+1))continue;
   if(!best||Math.abs(y-o.y)<Math.abs(best.front-o.y))best={x,front:y,high,low,top:y-high*16,bottom:y-low*16};
  }
  columns.push(best);
 }
 const valid=columns.filter(Boolean);if(valid.length<definition.width*.75)return null;
 const y=Math.floor(Math.min(...valid.map(c=>c.top)))-20,bottom=Math.ceil(Math.max(...valid.map(c=>c.bottom)))+12;
 return {x:left-8,y,width:definition.width+16,height:bottom-y,left,columns};
}
export function waterfallPixels(a,o,atlas,phase=0){
 const g=waterfallGeometry(a,o);if(!g)return null;const r=rasterPlan(a),data=new Uint32Array(g.width*g.height);
 for(let yy=0;yy<g.height;yy++)for(let xx=0;xx<g.width;xx++){
  const x=g.x+xx,y=g.y+yy,column=g.columns[Math.max(0,Math.min(g.columns.length-1,x-g.left))];if(!column||x<0||x>=r.width||y+r.pad<0||y+r.pad>=r.height)continue;
  const n=(y+r.pad)*r.width+x;if(r.owner[n]<0)continue;
  let sx,sy,opacity=1;const local=x-g.left,inCurtain=local>=0&&local<g.columns.length;
  if(inCurtain&&y>=column.top&&y<column.bottom&&r.kind[n]&&Math.abs(r.depth[n]-column.front)<1.1){sx=8+(local%32);sy=16+((y-column.top)%64);}
  else if(local>=-4&&local<g.columns.length+4&&y<column.top+6&&!r.kind[n]&&Math.abs(r.zmap[n]-column.high)<.01&&a.floors[r.owner[n]]==='water'){
   // Use interior flowing water, never the sprite's dark horizontal cap.
   // A staggered upstream reach and feathered shoulders join the river to the fall.
   const reach=12+[0,2,4,3,5,2,4,1][((Math.floor(local/4)%8)+8)%8],distance=y-(column.top-reach);
   if(distance<0)continue;
   sx=local<0?8+local:local>=g.columns.length?40+local-g.columns.length:8+local%32;
   sy=y>=column.top-3?12+(y-column.top+3)*2:20+Math.min(45,distance*3);
   opacity=Math.min(1,(distance+1)/6,(local+5)/5,(g.columns.length+4-local)/5)*(y<column.top-3?.65:1);
  }
  else if(y>=column.bottom-4&&y<column.bottom+12&&!r.kind[n]&&Math.abs(r.zmap[n]-column.low)<.01&&a.floors[r.owner[n]]==='water'){
   sx=local<8?local+8:local>=g.columns.length-8?48-(g.columns.length+8-local):16+(local%16);sy=80+(y-column.bottom+4);
  }else continue;
  if(sx>=0&&sx<48&&sy>=0&&sy<96){const color=atlas[sy*192+(phase%4)*48+sx];if(color>>>24){const alpha=Math.round((color>>>24)*opacity);data[yy*g.width+xx]=((color&0xffffff)|(alpha<<24))>>>0;}}
 }
 return {...g,data};
}
export function waterfallSample(source){
 const width=24,height=16,n=width*height,a={...structuredClone(source),width,height,levels:Array(n).fill(2),ramps:Array(n).fill(null),cliffs:Array(n).fill('face-rocha-cinza'),floors:Array(n).fill('grass'),objects:[],player:{x:80,y:400},nextId:4};
 // Recessed receiving pool: surrounding banks are level 2, water is level 0.
 for(let y=6;y<=12;y++)for(let x=3;x<=20;x++)if(!((x===3||x===20)&&(y===6||y===12))){a.levels[y*width+x]=0;a.floors[y*width+x]='water';}
 for(let y=1;y<=5;y++)for(let x=3;x<=20;x++){a.levels[y*width+x]=5;a.floors[y*width+x]='chao-grama-viva';}
 const centers=[176,368,560];WATERFALLS.forEach((w,k)=>{
  for(let y=1;y<=5;y++)for(let x=Math.floor((centers[k]-w.width/2)/32);x<Math.ceil((centers[k]+w.width/2)/32);x++)a.floors[y*width+x]='water';
  a.objects.push({id:k+1,asset:w.id,x:centers[k],y:192,flip:false,layer:'objects',collidable:false});
 });return a;
}
