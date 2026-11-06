import {TILE,floorCell,MAX_LEVEL} from './model.mjs';
export {MAX_LEVEL};
export const RISE=16,PAD=MAX_LEVEL*RISE+8;
export function heightAt(a,x,y){const i=floorCell(a,Math.max(0,Math.min(a.width*TILE-.001,x)),Math.max(0,Math.min(a.height*TILE-.001,y)));if(i<0)return 0;const h=a.levels[i];return h+(a.ramps[i]==='n'?1-(y%TILE)/TILE:0);}
export function project(a,p){return {x:p.x,y:p.y-heightAt(a,p.x,p.y)*RISE};}
export function topRect(a,i){const y=Math.floor(i/a.width),r=!!a.ramps[i];return {x:(i%a.width)*TILE,y:y*TILE-(a.levels[i]+Number(r))*RISE,w:TILE,h:TILE+(r?RISE:0)};}
export function faceRect(a,i){const row=Math.floor(i/a.width),front=(row+1)*TILE,high=a.levels[i],j=i+a.width,low=j<a.levels.length?a.levels[j]+Number(!!a.ramps[j]):0;if(high<=low)return null;return {x:i%a.width*TILE,y:front-high*RISE,w:TILE,h:(high-low)*RISE,high,low,depth:front,material:a.cliffs[i],i};}
export const contains=(r,p)=>p.x>=r.x&&p.y>=r.y&&p.x<r.x+r.w&&p.y<r.y+r.h;
export function pickTerrain(a,p){for(let i=a.levels.length-1;i>=0;i--){const face=faceRect(a,i);if(face&&contains(face,p))return {kind:'face',cell:i,point:{x:p.x,y:(Math.floor(i/a.width)+1)*TILE-.01}};const r=topRect(a,i);if(contains(r,p)){const y=Math.floor(i/a.width)*TILE,local=(p.y-r.y)/(a.ramps[i]?1+RISE/TILE:1);return {kind:'top',cell:i,point:{x:p.x,y:y+local}};}}return null;}
// Inspect an actual support surface even when a nearer cliff covers it.
export function pickSupport(a,p,level){for(let i=a.levels.length-1;i>=0;i--){if(a.levels[i]!==level)continue;const r=topRect(a,i);if(!contains(r,p))continue;const local=(p.y-r.y)/(a.ramps[i]?1+RISE/TILE:1);return {kind:'top',cell:i,point:{x:p.x,y:Math.floor(i/a.width)*TILE+local}};}return null;}
export function validRamp(a,i){return i>=a.width&&i<a.levels.length-a.width&&a.levels[i-a.width]===a.levels[i]+1&&a.levels[i+a.width]===a.levels[i]&&!a.ramps[i-a.width]&&!a.ramps[i+a.width];}
export function cleanRamps(a){for(let i=0;i<a.ramps.length;i++)if(a.ramps[i]&&!validRamp(a,i))a.ramps[i]=null;}
export function moveOnTerrain(a,p,delta){let out={...p};const steps=Math.max(1,Math.ceil(Math.hypot(delta.x,delta.y)/2)),dx=delta.x/steps,dy=delta.y/steps;
  const next=(x,y)=>({x:Math.max(1,Math.min(a.width*TILE-1,x)),y:Math.max(1,Math.min(a.height*TILE-1,y))});
  const allowed=(from,to)=>Math.abs(heightAt(a,from.x,from.y)-heightAt(a,to.x,to.y))<.22;
  for(let i=0;i<steps;i++){let q=next(out.x+dx,out.y+dy);if(allowed(out,q))out=q;else{q=next(out.x+dx,out.y);if(allowed(out,q))out=q;q=next(out.x,out.y+dy);if(allowed(out,q))out=q;}}return out;
}
export function occluders(a,o){const z=heightAt(a,o.x,o.y),own=floorCell(a,o.x,o.y),out=[];for(let i=0;i<a.levels.length;i++){if(i===own)continue;const front=(Math.floor(i/a.width)+1)*TILE;if(front<=o.y+.01)continue;const high=a.levels[i]+Number(!!a.ramps[i]);if(high>z+.001){const r=topRect(a,i);if(a.ramps[i])r.h=Math.max(0,Math.min(1,high-z))*(TILE+RISE);if(r.h>0)out.push(r);}const f=faceRect(a,i);if(f&&f.high>z+.001)out.push(f);}return out;}
export function isOccluded(a,o,p){return occluders(a,o).some(r=>contains(r,p));}
export function hash(x,y){let n=(x*374761393+y*668265263)|0;n=(n^(n>>>13))*1274126177;return (n^(n>>>16))>>>0;}
function floorTile(c,a,i,r){const type=a.floors[i],col=i%a.width,row=Math.floor(i/a.width);c.fillStyle=type==='grass'?['#8fa65b','#91a85d','#8da45b'][hash(col,row)%3]:type==='dirt'?'#c3a16e':'#9eafa4';c.fillRect(r.x,r.y,r.w,r.h);if(a.levels[i]>0&&type==='grass'){c.fillStyle=a.levels[i]===1?'#a1b765':'#acbe72';c.fillRect(r.x,r.y,r.w,r.h);}
  for(let k=0;k<5;k++){const n=hash(col*7+k,row*11+k),x=2+n%27,y=2+(n>>>6)%27;c.fillStyle=type==='grass'?(k%2?'#a9bd70':'#78934e'):type==='dirt'?(k%2?'#d5b782':'#ad8b5f'):(k%2?'#b7c3b3':'#849a90');c.fillRect(r.x+x,r.y+Math.floor(y*r.h/TILE),2+(n%2),1);}
  if(type==='stone'){c.fillStyle='#7d9589';c.fillRect(r.x+2,r.y+r.h-2,27,1);}
  if(a.ramps[i]){c.fillStyle='#b28e5d';for(let y=6;y<r.h;y+=8)c.fillRect(r.x+4,r.y+y,24,1);c.fillStyle='#dfc08a';c.fillRect(r.x+1,r.y,1,r.h);c.fillRect(r.x+30,r.y,1,r.h);}
}
function cliff(c,a,f){const rock=f.material==='rock';c.fillStyle=rock?'#747c75':'#8e6245';c.fillRect(f.x,f.y,f.w,f.h);
  // Bands follow absolute elevation; they do not restart at a neighbouring tile.
  for(let z=f.low*RISE;z<f.high*RISE;z++){const yy=f.depth-z-1;if(z%7===0){c.fillStyle=rock?'#626e68':'#765038';c.fillRect(f.x,yy,32,2);}else if(z%7===2){c.fillStyle=rock?'#8f9788':'#aa7c50';c.fillRect(f.x,yy,32,1);}}
  for(let x=0;x<32;x+=4){const n=hash((f.x+x)/4,f.depth);const z=f.low*RISE+3+n%Math.max(1,f.h-5),yy=f.depth-z;c.fillStyle=rock?'#9ba18f':'#b88b59';c.fillRect(f.x+x,Math.max(f.y,yy),2,1);}
  const groundType=a.floors[f.i];c.fillStyle=groundType==='grass'?'#536e39':groundType==='stone'?'#b5bca9':'#d4b37c';c.fillRect(f.x,f.y,32,2);
  if(groundType==='grass'){for(let x=0;x<32;x+=4){const len=2+hash(f.x+x,f.depth)%3;c.fillStyle=x%8?'#729348':'#93ad5e';c.fillRect(f.x+x,f.y,3,len);}}
  c.fillStyle=rock?'#46594c':'#553f2e';c.fillRect(f.x,f.y+f.h-1,32,1);
}
export function paintTerrain(c,a){const canvas=c.canvas;canvas.width=a.width*TILE;canvas.height=a.height*TILE+PAD;c.imageSmoothingEnabled=false;c.save();c.translate(0,PAD);
  for(let i=0;i<a.floors.length;i++)floorTile(c,a,i,{x:i%a.width*TILE,y:Math.floor(i/a.width)*TILE,w:32,h:32});
  for(let i=0;i<a.floors.length;i++){floorTile(c,a,i,topRect(a,i));const f=faceRect(a,i);if(f)cliff(c,a,f);const r=topRect(a,i),w=a.width,h=a.levels[i];if(h>0&&!a.ramps[i]){c.fillStyle='#c4d58a';if(i<w||a.levels[i-w]<h)c.fillRect(r.x,r.y,32,1);if(i%w===0||a.levels[i-1]<h)c.fillRect(r.x,r.y,1,32);c.fillStyle='#6b8546';if(i%w===w-1||a.levels[i+1]<h)c.fillRect(r.x+31,r.y,1,32);}}
  // Contact darkening is outside the wall, and never paints over a ramp mouth.
  for(let i=0;i<a.floors.length;i++){const f=faceRect(a,i);if(f){c.fillStyle='#263b242c';c.fillRect(f.x,f.y+f.h,32,2);}}
  c.restore();
}
