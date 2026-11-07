import {rampNeighbors,rampRise} from './ramp-rules.mjs';
// The paint grid stores occupancy at cell centres. Geometry samples the shared
// dual-grid field, so neighbouring cells cannot shrink their own independent edge.
export function dualValue(a,x,y,weight){
 const gx=x/32-.5,gy=y/32-.5,cx=Math.floor(gx),cy=Math.floor(gy),fx=gx-cx,fy=gy-cy;
 const read=(dx,dy)=>weight(Math.max(0,Math.min(a.width-1,cx+dx)),Math.max(0,Math.min(a.height-1,cy+dy)));
 return read(0,0)*(1-fx)*(1-fy)+read(1,0)*fx*(1-fy)+read(0,1)*(1-fx)*fy+read(1,1)*fx*fy;
}
export function rampLanding(a,i){for(const j of [i-1,i+1,i-a.width,i+a.width])if(j>=0&&j<a.ramps.length&&a.ramps[j]){const n=rampNeighbors(a,j);if(n.high===i&&a.levels[i]===a.levels[j]+1||n.low===i&&a.levels[i]===a.levels[j])return true;}return false;}
export function wallSupport(a,x,y,z){
 const i=Math.min(a.levels.length-1,Math.floor(y/32)*a.width+Math.floor(x/32));if(a.levels[i]>=z-.001||a.ramps[i])return i;
 const gx=x/32-.5,gy=y/32-.5,cx=Math.floor(gx),cy=Math.floor(gy),fx=gx-cx,fy=gy-cy;let best=-1,source=i;
 for(let dy=0;dy<2;dy++)for(let dx=0;dx<2;dx++){const xx=Math.max(0,Math.min(a.width-1,cx+dx)),yy=Math.max(0,Math.min(a.height-1,cy+dy)),j=yy*a.width+xx,weight=(dx?fx:1-fx)*(dy?fy:1-fy);if(a.levels[j]>=z-.001&&weight>best){best=weight;source=j;}}
 return source;
}
// Rounded contours can extend across a grid-cell boundary or cut a corner off.
// The exposed surface belongs to the cell supporting its actual height.
export function surfaceSupport(a,x,y,z){
 const i=Math.min(a.levels.length-1,Math.floor(y/32)*a.width+Math.floor(x/32));
 if(a.ramps[i]||Math.abs(a.levels[i]-z)<.001)return i;
 const gx=x/32-.5,gy=y/32-.5,cx=Math.floor(gx),cy=Math.floor(gy),fx=gx-cx,fy=gy-cy;let best=-1,source=i;
 for(let dy=0;dy<2;dy++)for(let dx=0;dx<2;dx++){
  const xx=Math.max(0,Math.min(a.width-1,cx+dx)),yy=Math.max(0,Math.min(a.height-1,cy+dy)),j=yy*a.width+xx,weight=(dx?fx:1-fx)*(dy?fy:1-fy);
  if(!a.ramps[j]&&Math.abs(a.levels[j]-z)<.001&&weight>best){best=weight;source=j;}
 }
 return source;
}
export function repairRampLandings(a){let changed=0;for(let i=0;i<a.ramps.length;i++)if(a.ramps[i])for(const j of Object.values(rampNeighbors(a,i)))if(j>=0&&j<a.floors.length&&a.floors[j]==='grass'&&a.floors[i]!=='grass'){a.floors[j]=a.floors[i];changed++;}return changed;}

export function terrainHeight(a,x,y){
 x=Math.max(0,Math.min(a.width*32-.001,x));y=Math.max(0,Math.min(a.height*32-.001,y));const i=Math.floor(y/32)*a.width+Math.floor(x/32),h=a.levels[i];
 if(a.ramps[i])return h+rampRise(a.ramps[i],x,y);
 if(a.autotiling===false||rampLanding(a,i))return h;
 const gx=Math.floor(x/32-.5),gy=Math.floor(y/32-.5);
 let maximum=h;for(let dy=0;dy<2;dy++)for(let dx=0;dx<2;dx++){const xx=Math.max(0,Math.min(a.width-1,gx+dx)),yy=Math.max(0,Math.min(a.height-1,gy+dy));maximum=Math.max(maximum,a.levels[yy*a.width+xx]);}
 for(let level=maximum;level>0;level--){
 const density=dualValue(a,x,y,(cx,cy)=>{const j=cy*a.width+cx;let value=a.levels[j];if(a.ramps[j])value+=Math.max(0,Math.min(1,rampRise(a.ramps[j],Math.max(0,Math.min(31.999,x-cx*32)),Math.max(0,Math.min(31.999,y-cy*32)))));return Number(value>=level-.0001);});
 if(density>=.5)return level;
 }
 return 0;
}


export const wallMaterial=(a,x,y,z)=>a.cliffs[wallSupport(a,x,y,z)];
