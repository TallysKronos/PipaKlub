// Review images for agents: enlarged frames with grid, silhouette, onion skin, ground
// previews and labelled contact sheets. Pure RGBA buffers; png.mjs/gif.mjs write them.
import {compositeFrame} from './document.mjs';
import {sequencesFor,playbackOrder} from './animation.mjs';
import {GROUNDS,silhouetteRGBA} from './legibility.mjs';
import {drawPose} from './rig.mjs';
const FONT={'0':'111101101101111','1':'010110010010111','2':'111001111100111','3':'111001111001111','4':'101101111001001','5':'111100111001111','6':'111100111101111','7':'111001010010010','8':'111101111101111','9':'111101111001111',
 a:'010101111101101',b:'110101110101110',c:'011100100100011',d:'110101101101110',e:'111100110100111',f:'111100110100100',g:'011100101101011',h:'101101111101101',i:'111010010010111',j:'001001001101010',k:'101101110101101',l:'100100100100111',m:'101111111101101',n:'110101101101101',o:'010101101101010',p:'110101110100100',q:'010101101011001',r:'110101110101101',s:'011100010001110',t:'111010010010010',u:'101101101101111',v:'101101101101010',w:'101101111111101',x:'101101010101101',y:'101101010010010',z:'111001010100111','-':'000000111000000','.':'000000000000010',':':'000010000010000','/':'001001010100100',' ':'000000000000000','·':'000000010000000'};
export class Canvas{
 constructor(w,h,bg=[24,32,43,255]){this.w=w;this.h=h;this.data=new Uint8ClampedArray(w*h*4);for(let i=0;i<w*h;i++)this.data.set(bg,i*4);}
 set(x,y,c){if(x<0||y<0||x>=this.w||y>=this.h)return;const o=(y*this.w+x)*4,a=(c[3]??255)/255;if(a>=1){this.data.set(c.length===4?c:[...c,255],o);return;}for(let k=0;k<3;k++)this.data[o+k]=this.data[o+k]*(1-a)+c[k]*a;}
 rect(x,y,w,h,c){for(let j=y;j<y+h;j++)for(let i=x;i<x+w;i++)this.set(i,j,c);}
 // rgba sprite at integer zoom; transparent pixels let the background show.
 blit(rgba,sw,sh,x,y,z=1,alpha=1){for(let j=0;j<sh;j++)for(let i=0;i<sw;i++){const o=(j*sw+i)*4;if(!rgba[o+3])continue;const c=[rgba[o],rgba[o+1],rgba[o+2],255*alpha];for(let dy=0;dy<z;dy++)for(let dx=0;dx<z;dx++)this.set(x+i*z+dx,y+j*z+dy,c);}}
 text(s,x,y,c=[233,228,216,255],z=1){let cx=x;for(const ch of String(s).toLowerCase()){const g=FONT[ch]||FONT[' '];for(let r=0;r<5;r++)for(let k=0;k<3;k++)if(g[r*3+k]==='1')this.rect(cx+k*z,y+r*z,z,z,c);cx+=4*z;}return cx;}
 checker(x,y,w,h,s=6){for(let j=0;j<h;j++)for(let i=0;i<w;i++)this.set(x+i,y+j,((Math.floor(i/s)+Math.floor(j/s))%2)?[42,53,66,255]:[37,48,60,255]);}
}
export function frameRGBA(p,index,{silhouette=false,tint=null}={}){
 const ind=compositeFrame(p,p.frames[index]);if(silhouette)return silhouetteRGBA(ind,[20,24,30],[0,0,0]).map((v,i)=>i%4===3?(ind[i>>2]?255:0):v);
 const out=new Uint8ClampedArray(ind.length*4);for(let i=0;i<ind.length;i++){if(!ind[i])continue;out.set(tint?[...tint,255]:p.palette[ind[i]],i*4);}return out;
}
function background(cv,x,y,w,h,ground){if(GROUNDS[ground])cv.rect(x,y,w,h,[...GROUNDS[ground],255]);else if(ground==='papel')cv.rect(x,y,w,h,[233,228,216,255]);else cv.checker(x,y,w,h,Math.max(4,Math.floor(w/16)));}
// One frame, enlarged, optionally with grid, onion skin (previous green, next violet) and silhouette.
export function renderFrame(p,index,{zoom=8,grid=true,ground='xadrez',silhouette=false,onion=false,neighbours=null,pose=false}={}){
 const pad=2,w=p.width*zoom,h=p.height*zoom,cv=new Canvas(w+pad*2,h+pad*2+12);
 background(cv,pad,pad,w,h,silhouette?'papel':ground);
 if(onion&&neighbours){if(neighbours[0]!=null)cv.blit(frameRGBA(p,neighbours[0],{tint:[75,230,175]}),p.width,p.height,pad,pad,zoom,.35);if(neighbours[1]!=null)cv.blit(frameRGBA(p,neighbours[1],{tint:[193,125,255]}),p.width,p.height,pad,pad,zoom,.35);}
 cv.blit(frameRGBA(p,index,{silhouette}),p.width,p.height,pad,pad,zoom);
 if(grid&&zoom>=4){for(let x=0;x<=p.width;x++)for(let y=0;y<h;y++)cv.set(pad+x*zoom-(x===p.width?1:0),pad+y,x%8===0?[239,187,104,90]:[170,184,201,40]);for(let y=0;y<=p.height;y++)for(let x=0;x<w;x++)cv.set(pad+x,pad+y*zoom-(y===p.height?1:0),y%8===0?[239,187,104,90]:[170,184,201,40]);}
 if(pose)drawPose(cv,p.frames[index].pose,pad,pad,zoom);
 cv.text(`${index} ${p.frames[index].name}`.slice(0,Math.floor(w/4)),pad,pad+h+4);return cv;
}
// Contact sheet: every listed frame at the given zoom on a ground, labelled with index and name.
export function renderSheet(p,frames,{zoom=2,ground='grama',cols=8,silhouette=false}={}){
 const cw=Math.max(p.width*zoom,40)+6,ch=p.height*zoom+16,cols2=Math.min(cols,frames.length),rows=Math.ceil(frames.length/cols2),cv=new Canvas(cols2*cw+4,rows*ch+4);
 frames.forEach((f,n)=>{const x=4+(n%cols2)*cw,y=4+Math.floor(n/cols2)*ch;background(cv,x,y,p.width*zoom,p.height*zoom,silhouette?'papel':ground);cv.blit(frameRGBA(p,f,{silhouette}),p.width,p.height,x,y,zoom);cv.text(`${f} ${p.frames[f].name}`.slice(0,Math.floor((cw-2)/4)),x,y+p.height*zoom+3,[160,175,189,255]);});
 return cv;
}
// Same pose on every ground, at 1× and 3×: the in-game reading test.
export function renderGrounds(p,index){const keys=Object.keys(GROUNDS),cell=p.width*3+p.width+18,cv=new Canvas(keys.length*cell+4,p.height*3+22);
 keys.forEach((k,n)=>{const x=4+n*cell;cv.rect(x,4,cell-6,p.height*3+4,[...GROUNDS[k],255]);cv.blit(frameRGBA(p,index),p.width,p.height,x+2,6,3);cv.blit(frameRGBA(p,index),p.width,p.height,x+p.width*3+8,6+p.height*2,1);cv.text(k,x,p.height*3+12);});return cv;}
// Animated GIF frames for a playback order, enlarged, on a ground colour (palette index 0 stays transparent only on xadrez).
export function gifFrames(p,order,{zoom=3,ground='grama'}={}){
 const pal=p.palette.map(c=>[...c]),bg=GROUNDS[ground];let bgIndex=0;if(bg){bgIndex=pal.length<256?pal.push([...bg,255])-1:0;}
 return {palette:pal,width:p.width*zoom,height:p.height*zoom,frames:order.map(i=>{const ind=compositeFrame(p,p.frames[i]),out=new Uint8Array(p.width*zoom*p.height*zoom).fill(bgIndex);
  for(let y=0;y<p.height;y++)for(let x=0;x<p.width;x++){const v=ind[y*p.width+x];if(!v)continue;for(let dy=0;dy<zoom;dy++)for(let dx=0;dx<zoom;dx++)out[(y*zoom+dy)*p.width*zoom+x*zoom+dx]=v;}
  return {indices:out,delay:p.frames[i].duration||150};})};
}
// Text view for exact editing: one character per pixel plus a legend.
export function asciiFrame(p,index,layer=null){
 const ind=layer===null?compositeFrame(p,p.frames[index]):p.frames[index].cels[layer],used=[...new Set(ind)].filter(Boolean).sort((a,b)=>a-b);
 const chars='123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@$%&*+=?<>',key=new Map(used.map((c,n)=>[c,chars[n]||'#']));
 const rows=[];for(let y=0;y<p.height;y++){let r='';for(let x=0;x<p.width;x++){const v=ind[y*p.width+x];r+=v?key.get(v):'.';}rows.push(r.padEnd(p.width)+' '+String(y).padStart(2));}
 const ruler='0123456789'.repeat(Math.ceil(p.width/10)).slice(0,p.width);
 const ramps=Object.entries(p.ramps||{});const legend=used.map(c=>{const r=ramps.find(([,l])=>l.includes(c));return `${key.get(c)}=${c} #${p.palette[c].slice(0,3).map(v=>v.toString(16).padStart(2,'0')).join('')}${r?` ${r[0]}:${r[1].indexOf(c)}`:''}`;});
 return [ruler,...rows,'',...legend].join('\n');
}
// Context scenes for boards and GIFs: the action seen where it happens in the game.
// escada: earth bank with a vertical wooden ladder (rails at x≈16 and x≈32, rungs scroll
// down as the character climbs); agua: water with moving glints; otherwise a ground colour.
export function sceneFor(name){return /^climb/.test(name)?'escada':/^swim/.test(name)?'agua':'grama';}
function noise(x,y){let h=(x*374761393+y*668265263)|0;h=(h^(h>>>13))*1274126177|0;return ((h^(h>>>16))>>>0)/4294967295;}
export function drawScene(cv,x0,y0,p,zoom,kind,tick=0){const w=p.width,h=p.height,px=(x,y,c)=>cv.rect(x0+x*zoom,y0+y*zoom,zoom,zoom,c);
 if(kind==='escada'){for(let y=0;y<h;y++)for(let x=0;x<w;x++){const band=Math.floor((y+tick*2)/9)%3,n=noise(x,Math.floor((y+tick*2)/2));const base=[[150,96,58],[134,84,52],[163,108,66]][band];px(x,y,[...base.map(v=>v-(n>.86?22:n<.08?-14:0)),255]);}
  for(const rx of [15,31])for(let y=0;y<h;y++){px(rx,y,[92,56,34,255]);px(rx+1,y,[171,116,66,255]);px(rx+2,y,[120,76,44,255]);}
  for(let y=((tick*2)%7+7)%7;y<h;y+=7)for(let x=17;x<31;x++){px(x,y,[188,132,78,255]);px(x,y+1,[112,70,40,255]);}return;}
 if(kind==='agua'){for(let y=0;y<h;y++)for(let x=0;x<w;x++){const n=noise(x,y);px(x,y,y<18?[58,140,182,255]:[48,124,168,255]);if(((x+tick*2+Math.floor(y/5)*7)%17===0)&&y%5===0)px(x,y,[150,214,236,255]);}return;}
 cv.rect(x0,y0,w*zoom,h*zoom,[...(GROUNDS[kind]||GROUNDS.grama),255]);}
// Board: one row per sequence, every frame on its scene, labelled; reads top to bottom.
export function renderBoard(p,names,{zoom=3}={}){const seqs=names.map(n=>{const s=sequencesFor(p).find(s=>s.name===n);if(!s)throw Error(`Sequência inexistente: ${n}`);return s;});
 const cols=Math.max(...seqs.map(s=>s.end-s.start+1)),cw=p.width*zoom+6,rh=p.height*zoom+26,cv=new Canvas(cols*cw+8,seqs.length*rh+6);
 seqs.forEach((s,r)=>{const y=6+r*rh;cv.text(`${s.name}  ${s.loop===false?'sem repetir':'em loop'}`,4,y,[239,187,104,255]);
  for(let i=s.start;i<=s.end;i++){const x=4+(i-s.start)*cw;drawScene(cv,x,y+8,p,zoom,sceneFor(s.name),i-s.start);cv.blit(frameRGBA(p,i),p.width,p.height,x,y+8,zoom);cv.text(`${i-s.start+1} · ${p.frames[i].duration||150}ms`,x,y+10+p.height*zoom,[160,175,189,255]);}});
 return cv;}
// Canvases → indexed GIF frames (exact colours; falls back to the nearest when over 256).
export function canvasGif(canvases,delays){const pal=[[0,0,0,0]],key=new Map(),frames=canvases.map((cv,n)=>{const out=new Uint8Array(cv.w*cv.h);
  for(let i=0;i<out.length;i++){const r=cv.data[i*4],g=cv.data[i*4+1],b=cv.data[i*4+2],k=(r<<16)|(g<<8)|b;let v=key.get(k);
   if(v===undefined){if(pal.length<256){v=pal.push([r,g,b,255])-1;}else{let best=1,d=1e9;for(let j=1;j<pal.length;j++){const e=(pal[j][0]-r)**2+(pal[j][1]-g)**2+(pal[j][2]-b)**2;if(e<d){d=e;best=j;}}v=best;}key.set(k,v);}out[i]=v;}
  return {indices:out,delay:delays[n]};});return {palette:pal,width:canvases[0].w,height:canvases[0].h,frames};}
export function sceneGif(p,s,{zoom=4}={}){const order=playbackOrder(s),cvs=order.map((i,n)=>{const cv=new Canvas(p.width*zoom,p.height*zoom);drawScene(cv,0,0,p,zoom,sceneFor(s.name),i-s.start);cv.blit(frameRGBA(p,i),p.width,p.height,0,0,zoom);return cv;});
 if(s.loop===false){cvs.push(cvs.at(-1));}return canvasGif(cvs,[...order.map(i=>p.frames[i].duration||150),...(s.loop===false?[1500]:[])]);}
