// Minimal PNG writer/reader for the command line (Node zlib, no dependencies).
// Reads 8-bit non-interlaced grey, grey+alpha, RGB, RGBA and indexed images.
import zlib from 'node:zlib';
const CRC=new Int32Array(256).map((_,n)=>{let c=n;for(let k=0;k<8;k++)c=c&1?0xedb88320^(c>>>1):c>>>1;return c;});
const crc=bytes=>{let c=-1;for(const b of bytes)c=CRC[(c^b)&255]^(c>>>8);return (c^-1)>>>0;};
function chunk(type,data){const out=Buffer.alloc(12+data.length),name=Buffer.from(type,'ascii');out.writeUInt32BE(data.length,0);name.copy(out,4);Buffer.from(data).copy(out,8);out.writeUInt32BE(crc(Buffer.concat([name,Buffer.from(data)])),8+data.length);return out;}
export function encodePNG(rgba,width,height){
 const raw=Buffer.alloc((width*4+1)*height);
 for(let y=0;y<height;y++){raw[y*(width*4+1)]=0;Buffer.from(rgba.buffer,rgba.byteOffset+y*width*4,width*4).copy(raw,y*(width*4+1)+1);}
 const head=Buffer.alloc(13);head.writeUInt32BE(width,0);head.writeUInt32BE(height,4);head[8]=8;head[9]=6;
 return Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',head),chunk('IDAT',zlib.deflateSync(raw,{level:9})),chunk('IEND',Buffer.alloc(0))]);
}
export function decodePNG(buffer){
 const b=Buffer.from(buffer);if(b.readUInt32BE(0)!==0x89504e47)throw Error('Arquivo não é PNG.');
 let p=8,w=0,h=0,depth=0,type=0,interlace=0,palette=null,trns=null;const idat=[];
 while(p<b.length){const len=b.readUInt32BE(p),name=b.toString('ascii',p+4,p+8),data=b.subarray(p+8,p+8+len);p+=12+len;
  if(name==='IHDR'){w=data.readUInt32BE(0);h=data.readUInt32BE(4);depth=data[8];type=data[9];interlace=data[12];}
  else if(name==='PLTE')palette=data;else if(name==='tRNS')trns=data;else if(name==='IDAT')idat.push(data);else if(name==='IEND')break;}
 if(depth!==8||interlace)throw Error('Use PNG de 8 bits por canal, sem entrelaçamento.');
 if(w*h>16777216)throw Error('Use uma imagem de até 16 megapixels.');
 const channels={0:1,2:3,3:1,4:2,6:4}[type];if(!channels)throw Error('Tipo de cor PNG não suportado.');
 const raw=zlib.inflateSync(Buffer.concat(idat)),stride=w*channels,out=new Uint8ClampedArray(w*h*4);let prev=new Uint8Array(stride);
 for(let y=0;y<h;y++){const f=raw[y*(stride+1)],line=Uint8Array.from(raw.subarray(y*(stride+1)+1,(y+1)*(stride+1)));
  for(let x=0;x<stride;x++){const a=x>=channels?line[x-channels]:0,up=prev[x],c=x>=channels?prev[x-channels]:0;
   line[x]=(line[x]+(f===1?a:f===2?up:f===3?(a+up)>>1:f===4?(()=>{const q=a+up-c,pa=Math.abs(q-a),pb=Math.abs(q-up),pc=Math.abs(q-c);return pa<=pb&&pa<=pc?a:pb<=pc?up:c;})():0))&255;}
  for(let x=0;x<w;x++){const o=(y*w+x)*4,s=x*channels;
   if(type===6)out.set(line.subarray(s,s+4),o);
   else if(type===2){out.set(line.subarray(s,s+3),o);out[o+3]=255;}
   else if(type===0){out.fill(line[s],o,o+3);out[o+3]=255;}
   else if(type===4){out.fill(line[s],o,o+3);out[o+3]=line[s+1];}
   else{const i=line[s];out[o]=palette[i*3];out[o+1]=palette[i*3+1];out[o+2]=palette[i*3+2];out[o+3]=trns&&i<trns.length?trns[i]:255;}}
  prev=line;}
 return {data:out,width:w,height:h};
}
