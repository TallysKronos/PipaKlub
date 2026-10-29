// Animated GIF from indexed frames. Index 0 is transparent, like the Pixelgen palette.
const bits=n=>{let b=1;while((1<<b)<n)b++;return Math.max(2,b);};
function lzw(indices,size){
 const out=[];let cur=0,nb=0;const emit=(code,width)=>{cur|=code<<nb;nb+=width;while(nb>=8){out.push(cur&255);cur>>=8;nb-=8;}};
 const clear=1<<size,end=clear+1;let width=size+1,next=end+1,dict=new Map();emit(clear,width);
 let prefix=indices[0];
 for(let i=1;i<indices.length;i++){const k=indices[i],key=prefix*4096+k;
  if(dict.has(key)){prefix=dict.get(key);continue;}
  emit(prefix,width);
  if(next<4096){dict.set(key,next++);if(next>(1<<width)&&width<12)width++;}
  else{emit(clear,width);dict=new Map();width=size+1;next=end+1;}
  prefix=k;}
 emit(prefix,width);emit(end,width);if(nb)out.push(cur&255);return out;
}
// frames: [{indices:Uint8Array(width*height), delay:ms}], palette: [[r,g,b,a]...]
export function encodeGIF(frames,width,height,palette){
 const size=bits(palette.length),table=1<<size,out=[];const u16=v=>out.push(v&255,(v>>8)&255);
 out.push(...Buffer.from('GIF89a'));u16(width);u16(height);out.push(0xf0|(size-1),0,0);
 for(let i=0;i<table;i++){const c=palette[i]||[0,0,0];out.push(c[0],c[1],c[2]);}
 out.push(0x21,0xff,11,...Buffer.from('NETSCAPE2.0'),3,1,0,0,0);
 for(const f of frames){out.push(0x21,0xf9,4,0x09);u16(Math.max(2,Math.round(f.delay/10)));out.push(0,0);
  out.push(0x2c);u16(0);u16(0);u16(width);u16(height);out.push(0,size);
  const data=lzw(f.indices,size);for(let i=0;i<data.length;i+=255){const part=data.slice(i,i+255);out.push(part.length,...part);}out.push(0);}
 out.push(0x3b);return Buffer.from(out);
}
