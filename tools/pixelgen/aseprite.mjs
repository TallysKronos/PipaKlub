// Indexed 8-bit Aseprite document. One editable layer, named frame tags, no lossy resampling.
// Format: https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md
import {duration,sequencesFor} from './animation.mjs';
class Bytes{
 constructor(){this.a=[];}u8(v){this.a.push(v&255);return this;}u16(v){return this.u8(v).u8(v>>8);}u32(v){return this.u16(v).u16(v>>>16);}
 raw(a){for(const v of a)this.u8(v);return this;}zero(n){for(let i=0;i<n;i++)this.u8(0);return this;}
 text(s){const a=new TextEncoder().encode(s);return this.u16(a.length).raw(a);}get data(){return Uint8Array.from(this.a);}
}
function chunk(type,b){return new Bytes().u32(b.a.length+6).u16(type).raw(b.a).data;}
export function aseprite(project){
 const definitions=project.layers||[{name:'Pixels',visible:true,locked:false}];
 const layers=definitions.map(l=>chunk(0x2004,new Bytes().u16((l.visible!==false?1:0)+(l.locked?0:2)).u16(0).u16(0).u16(0).u16(0).u16(0).u8(255).zero(3).text(l.name)));
 const pal=new Bytes().u32(project.palette.length).u32(0).u32(project.palette.length-1).zero(8);
 for(const color of project.palette)pal.u16(0).raw(color);
 const sequences=sequencesFor(project),palette=chunk(0x2019,pal),tagData=new Bytes().u16(sequences.length).zero(8);
 sequences.forEach(s=>tagData.u16(s.start).u16(s.end).u8(s.direction==='reverse'?1:s.direction==='pingpong'?2:0).u16(s.loop===false?1:0).zero(6).raw([92,206,187]).u8(0).text(s.name));
 const tags=chunk(0x2018,tagData),frames=[];
 project.frames.forEach((f,i)=>{
  const cels=(f.cels||[f.indices]).map((data,layer)=>chunk(0x2005,new Bytes().u16(layer).u16(0).u16(0).u8(255).u16(0).u16(0).zero(5)
   .u16(project.width).u16(project.height).raw(data)));
  const chunks=i===0?[...layers,palette,tags,...cels]:cels,body=new Bytes();for(const c of chunks)body.raw(c);
  frames.push(new Bytes().u32(16+body.a.length).u16(0xf1fa).u16(chunks.length).u16(duration(f)).zero(2).u32(chunks.length).raw(body.a).data);
 });
 const size=128+frames.reduce((n,f)=>n+f.length,0),header=new Bytes().u32(size).u16(0xa5e0).u16(frames.length)
  .u16(project.width).u16(project.height).u16(8).u32(1).u16(150).zero(8).u8(0).zero(3).u16(project.palette.length)
  .u8(1).u8(1).u16(0).u16(0).u16(1).u16(1).zero(84);
 const all=new Uint8Array(size);all.set(header.data);let offset=128;for(const f of frames){all.set(f,offset);offset+=f.length;}return all;
}
