import {STREET_LAYOUT,streetWalkable} from './street-layout.js';
import {worldTerrainContours} from './world-art.js';

// Painted once on the shared ground plane; no textures stretched to arbitrary boxes.
export function paintStreetGround(c){
 const p=STREET_LAYOUT;let seed=731;const rand=()=>{seed=(seed*1664525+1013904223)>>>0;return seed/4294967296;};
 const path=rects=>{c.beginPath();for(const points of worldTerrainContours(rects)){points.forEach((q,i)=>i?c.lineTo(q.x,q.y):c.moveTo(q.x,q.y));c.closePath();}};
 const fill=(rects,color,edge)=>{path(rects);c.fillStyle=color;c.fill();if(edge){c.strokeStyle=edge;c.lineWidth=4;c.stroke();}};
 c.fillStyle='#a4c171';c.fillRect(-640,-640,p.width+1280,p.height+1280);
 for(let i=0;i<1200;i++){const x=rand()*p.width,y=rand()*p.height;c.fillStyle=i%3?'#95b76b':'#b7ce86';c.beginPath();c.ellipse(x,y,10+rand()*25,4+rand()*12,0,0,Math.PI*2);c.fill();}
 for(let i=0;i<430;i++){const x=rand()*p.width,y=rand()*p.height;c.strokeStyle=i%2?'#88a960':'#c1d48d';c.lineWidth=2;c.beginPath();c.moveTo(x-5,y+2);c.lineTo(x-7,y-5);c.moveTo(x,y+2);c.lineTo(x+2,y-9);c.moveTo(x+3,y+2);c.lineTo(x+8,y-3);c.stroke();}
 const stone=streetWalkable().filter(r=>r.material==='sidewalk'),r=p.road;
 fill(stone,'#eee0bc','#b7aa85');
 c.save();path(stone);c.clip();
 c.strokeStyle='#d9cba6';c.lineWidth=1.5;
 for(let y=480;y<1952;y+=64){c.beginPath();c.moveTo(0,y);c.lineTo(p.width,y);c.stroke();for(let x=(y/64%2)*48;x<p.width;x+=96){c.beginPath();c.moveTo(x,y);c.lineTo(x,y+64);c.stroke();}}
 // Subtle variation stays inside the continuous material, rather than tile stamps.
 for(let i=0;i<420;i++){c.fillStyle=i%2?'#f7edcf55':'#d6c49a33';c.fillRect(rand()*p.width,480+rand()*1472,20+rand()*45,3);}
 c.restore();
 fill([r],'#cda77d','#ad8c68');
 c.save();path([r]);c.clip();for(let i=0;i<900;i++){const x=r.x+rand()*r.w,y=r.y+rand()*r.h;c.fillStyle=i%3?'#bb946b55':'#e9c99e66';c.fillRect(x,y,2+rand()*5,1+rand()*2);}c.restore();
 // A modest crossing leads from Assis's porch to the small community square.
 c.fillStyle='#f6e8c8';for(let y=r.y+24;y<r.y+r.h-16;y+=48)c.fillRect(1296,y,160,24);
 for(const y of [r.y,r.y+r.h]){c.strokeStyle='#ae9873';c.lineWidth=8;c.beginPath();c.moveTo(r.x,y+4);c.lineTo(r.x+r.w,y+4);c.stroke();c.strokeStyle='#f9edcd';c.lineWidth=4;c.beginPath();c.moveTo(r.x,y-1);c.lineTo(r.x+r.w,y-1);c.stroke();
  c.strokeStyle='#bca984';c.lineWidth=2;for(let x=r.x;x<r.x+r.w;x+=96){c.beginPath();c.moveTo(x,y-4);c.lineTo(x,y+8);c.stroke();}}
 fill(streetWalkable().filter(r=>r.material==='dirt'),'#dfbf87','#b89b6b');
 // The square's inlay uses the franchise's kite shape and leaves the center free.
 c.save();c.translate(1376,1440);c.fillStyle='#c3a56b';c.beginPath();c.moveTo(0,-32);c.lineTo(38,0);c.lineTo(0,32);c.lineTo(-38,0);c.closePath();c.fill();c.strokeStyle='#f6e9c5';c.lineWidth=4;c.stroke();c.beginPath();c.moveTo(0,-30);c.lineTo(0,30);c.moveTo(-36,0);c.lineTo(36,0);c.stroke();c.restore();
}
