import {WALL_BYTES,WALL_COLORS} from './wall-data.mjs';
export const WALL_PIXELS=Object.fromEntries(Object.entries(WALL_BYTES).map(([id,s])=>{const b=Uint8Array.from(atob(s),c=>c.charCodeAt(0));return[id,new Uint32Array(b.buffer)];}));
export {WALL_COLORS};
import {isGround,groundRank} from './ground-kit.mjs';
import {GROUND_BYTES,GROUND_COLORS} from './ground-data.mjs';
export const GROUND_PIXELS=Object.fromEntries(Object.entries(GROUND_BYTES).map(([id,s])=>{const b=Uint8Array.from(atob(s),c=>c.charCodeAt(0));return[id,new Uint32Array(b.buffer)];}));
export {GROUND_COLORS};
import {terrainHeight} from './terrain-field.mjs';
import {TILE} from './model.mjs';
export const N=1,E=2,S=4,W=8,NE=16,SE=32,SW=64,NW=128;
export const VARIANTS=3;
export function normalizeMask(m){let n=m&15;if((m&NE)&&(m&N)&&(m&E))n|=NE;if((m&SE)&&(m&S)&&(m&E))n|=SE;if((m&SW)&&(m&S)&&(m&W))n|=SW;if((m&NW)&&(m&N)&&(m&W))n|=NW;return n;}
export const MASKS=[...new Set(Array.from({length:256},(_,i)=>normalizeMask(i)))].sort((a,b)=>a-b);
export const MASK_INDEX=new Map(MASKS.map((m,i)=>[m,i]));
export function neighborMask(a,i,matches){const x=i%a.width,y=Math.floor(i/a.width);let m=0;for(const [dx,dy,bit]of [[0,-1,N],[1,0,E],[0,1,S],[-1,0,W],[1,-1,NE],[1,1,SE],[-1,1,SW],[-1,-1,NW]])if(matches(x+dx,y+dy,dx,dy))m|=bit;return normalizeMask(m);}
export function materialMask(a,i){const kind=a.floors[i];return neighborMask(a,i,(x,y,dx)=>x<0||y<0||x>=a.width||y>=a.height||a.levels[y*a.width+x]!==a.levels[i]||(isGround(kind)||isGround(a.floors[y*a.width+x])?groundRank(a.floors[y*a.width+x])>=groundRank(kind):a.floors[y*a.width+x]===kind)||(kind==='grass'&&['water','sand'].includes(a.floors[y*a.width+x]))||(kind==='sand'&&a.floors[y*a.width+x]==='water')||(kind==='grass'&&!a.ramps[i]&&dx!==0&&!!a.ramps[y*a.width+x]));}
export function levelMask(a,i,level){return neighborMask(a,i,(x,y,dx,dy)=>{if(x<0||y<0||x>=a.width||y>=a.height)return false;const j=y*a.width+x,h=a.levels[j];if(a.ramps[j])return h+(dy===1?1:0)>=level;return h>=level;});}
const SHAPES=new Map();
function edge(t){return [4,4,3,3,3,4,4,3,3,4,4,3,3,3,4,4][Math.floor(t)%16];}
export function shape(mask){mask=normalizeMask(mask);if(SHAPES.has(mask))return SHAPES.get(mask);const out=new Uint8Array(TILE*TILE),r=14;
for(let y=0;y<TILE;y++)for(let x=0;x<TILE;x++){const qx=x<16?x:31-x,qy=y<16?y:31-y,h=x<16?W:E,v=y<16?N:S,d=x<16?(y<16?NW:SW):(y<16?NE:SE);let inside=true;
if(!(mask&h)&&qx<edge(y)+1)inside=false;if(!(mask&v)&&qy<edge(x)+1)inside=false;
if(!(mask&h)&&!(mask&v)&&qx<r+1&&qy<r+1){if((qx-r)**2+(qy-r)**2>100)inside=false;}
if((mask&h)&&(mask&v)&&!(mask&d)&&qx*qx+qy*qy<5*5)inside=false;
out[y*TILE+x]=Number(inside);}SHAPES.set(mask,out);return out;}
export const supportHeight=terrainHeight;
export function seed(x,y,k=0){let n=(Math.imul(x+1,1103515245)^Math.imul(y+7,12345)^Math.imul(k,2654435761))>>>0;n^=n>>>13;n=Math.imul(n,1540483477);return (n^(n>>>15))>>>0;}
export const variantFor=(x,y)=>((x*x*17+y*y*29+x*y*13+x*7+y*11)%65521)%3;
export function pack(hex,a=255){const n=parseInt(hex.replace('#',''),16);return ((n>>>16)|((n>>>8&255)<<8)|((n&255)<<16)|(a<<24))>>>0;}
const C={dirt:pack('c6a16c'),dirtLight:pack('dcb980'),dirtDark:pack('ad895b'),pebble:pack('8e7955'),grass:pack('8eaa53'),grassDark:pack('739044'),grassLight:pack('acc76b'),grassEdge:pack('52733b'),grassRim:pack('aac370'),stone:pack('a6ac94'),stoneDark:pack('727e72'),stoneLight:pack('c6c9ad')};
function dirtPixel(x,y,v){let c=C.dirt;for(let k=0;k<7;k++){const px=3+seed(k,v,4)%26,py=3+seed(k,v,7)%26,dx=x-px,dy=y-py;if(dx>=0&&dx<2+(k%2)&&dy===0)c=k%2?C.dirtLight:C.dirtDark;if(k<2&&dx>=0&&dx<3&&dy>=0&&dy<2)c=dy?C.pebble:C.dirtLight;}return c;}
export function floorPixel(kind,mask,v,x,y){const index=y*32+x;if(isGround(kind)){const sh=shape(mask);if(!sh[index])return tile('grass',255,v)[index];let color=GROUND_PIXELS[kind][v*1024+index];const edge=[[x-1,y],[x+1,y],[x,y-1],[x,y+1]].some(([xx,yy])=>xx>=0&&yy>=0&&xx<32&&yy<32&&!sh[yy*32+xx]);if(edge){const r=Math.round((color&255)*.85),g=Math.round((color>>>8&255)*.85),b=Math.round((color>>>16&255)*.85);color=(r|g<<8|b<<16|255<<24)>>>0;}return color;}let c=dirtPixel(x,y,v);if(kind==='dirt')return c;const sh=shape(mask);if(kind==='water'||kind==='sand'){if(!sh[index])return tile('grass',255,v)[index];const edge1=[[x-1,y],[x+1,y],[x,y-1],[x,y+1]].some(([xx,yy])=>xx>=0&&yy>=0&&xx<32&&yy<32&&!sh[yy*32+xx]);const edge2=[[x-2,y],[x+2,y],[x,y-2],[x,y+2]].some(([xx,yy])=>xx>=0&&yy>=0&&xx<32&&yy<32&&!sh[yy*32+xx]);if(kind==='sand')return edge1?pack('aa905e'):edge2?pack('ead29a'):seed(x,y,v)%127===0?pack('e5cf99'):seed(x,y,v)%97===0?pack('c3a66f'):pack('d8be86');return edge1?pack('315e58'):edge2?pack('67b9b1'):((x+y*2)%37===0&&y%7===0)?pack('328fa0'):pack('24768d');}if(!sh[index])return c;
if(kind==='grass'){c=C.grass;for(let k=0;k<6;k++){const px=2+seed(k,v,3)%28,py=2+seed(k,v,9)%28,dx=x-px,dy=y-py;if((dy===0&&dx>=0&&dx<3)||(dy===-1&&dx===1))c=k%3?C.grassDark:C.grassLight;}
const left=x>0&&!sh[index-1],right=x<31&&!sh[index+1],up=y>0&&!sh[index-32],down=y<31&&!sh[index+32];if(left||up)c=C.grassRim;if(right||down)c=C.grassEdge;
}else{let first=Infinity,second=Infinity;for(let gy=0;gy<4;gy++)for(let gx=0;gx<4;gx++){const sx=gx*8+2+seed(gx,gy,5)%4,sy=gy*8+2+seed(gx,gy,6)%4,ax=Math.abs(x-sx),ay=Math.abs(y-sy),dx=Math.min(ax,32-ax),dy=Math.min(ay,32-ay),d=dx*dx+dy*dy;if(d<first){second=first;first=d;}else if(d<second)second=d;}c=second-first<7?C.stoneDark:second-first<15?C.stoneLight:C.stone;if(seed(x,y,v)%89===0)c=C.stoneLight;}

return c;}
const TILES=new Map();
export function tile(kind,mask=255,v=0){mask=normalizeMask(mask);const key=kind+'/'+mask+'/'+v;if(!TILES.has(key)){const data=new Uint32Array(1024);for(let y=0;y<32;y++)for(let x=0;x<32;x++)data[y*32+x]=floorPixel(kind,mask,v,x,y);TILES.set(key,data);}return TILES.get(key);}
export function cliffPixel(kind,x,z){if(WALL_PIXELS[kind])return WALL_PIXELS[kind][(((-Math.floor(z))%64+64)%64)*64+((Math.floor(x)%64+64)%64)];x=((x%64)+64)%64;z=((z%64)+64)%64;const rock=kind==='rock';if(rock){let d1=Infinity,d2=Infinity,site=0;for(let gy=0;gy<4;gy++)for(let gx=0;gx<4;gx++){const sx=gx*16+4+seed(gx,gy,5)%8,sy=gy*16+4+seed(gx,gy,7)%8,ax=Math.abs(x-sx),ay=Math.abs(z-sy),dx=Math.min(ax,64-ax),dy=Math.min(ay,64-ay),d=dx*dx+dy*dy*.62;if(d<d1){d2=d1;d1=d;site=gy*4+gx;}else if(d<d2)d2=d;}if(d2-d1<8)return pack('46534d');if(d2-d1<19)return pack('9aa58a');return [pack('6a7869'),pack('7d8a75'),pack('73826c'),pack('82917a')][seed(site,1)%4];}let c=pack('977248');const vein=seed(Math.floor(x/9),Math.floor(z/7),11);if(vein%5===0&&x%9<6&&z%7<2)c=pack('a37d4e');if(vein%7===0&&x%9<5&&z%7===4)c=pack('8c6943');const stone=seed(Math.floor(x/4),Math.floor(z/4),3);if(stone%13===0&&x%4<3&&z%4<2)c=z%4?pack('78623f'):pack('c4a16b');return c;}
export function atlas(kind){const cols=8,rows=Math.ceil(MASKS.length/cols),width=cols*32,height=rows*32*VARIANTS,data=new Uint32Array(width*height);for(let v=0;v<VARIANTS;v++)for(let n=0;n<MASKS.length;n++){const im=tile(kind,MASKS[n],v),ox=n%cols*32,oy=(Math.floor(n/cols)+v*rows)*32;for(let y=0;y<32;y++)data.set(im.subarray(y*32,y*32+32),(oy+y)*width+ox);}return {width,height,data};}
export function texture(kind){if(WALL_PIXELS[kind])return {width:64,height:64,data:WALL_PIXELS[kind]};const width=kind==='dirt'?32:64,height=kind==='dirt'?96:64,data=new Uint32Array(width*height);for(let y=0;y<height;y++)for(let x=0;x<width;x++)data[y*width+x]=kind==='dirt'?dirtPixel(x,y%32,Math.floor(y/32)):cliffPixel(kind,x,y);return {width,height,data};}


export function rampTint(color,y){const factor=1-.075*Math.sin(Math.PI*(y+.5)/32),r=Math.round((color&255)*factor),g=Math.round((color>>>8&255)*factor),b=Math.round((color>>>16&255)*factor);return (r|(g<<8)|(b<<16)|(255<<24))>>>0;}

export function wallFaceColor(kind,x,z,distance){let c=cliffPixel(kind,x,z);if(WALL_PIXELS[kind]&&distance>=2&&distance<8){const p=[78,82,87,92,96,100][distance-2],r=Math.floor(((c&255)*p+50)/100),g=Math.floor(((c>>>8&255)*p+50)/100),b=Math.floor(((c>>>16&255)*p+50)/100);c=(r|g<<8|b<<16|255<<24)>>>0;}return c;}
export const wallCap=(kind,distance)=>WALL_COLORS[kind]?pack(distance?WALL_COLORS[kind].light:WALL_COLORS[kind].dark):pack(distance?'c9aa73':'78613f');
