import {validateCollision} from './collision-shapes.mjs';
export function validateCustomAssets(raw){
 if(!Array.isArray(raw)||raw.length>32)throw Error('Máximo de 32 assets próprios por mapa.');let total=0,pixels=0;const ids=new Set();
 return raw.map(a=>{
  if(!a||!/^custom-[a-z0-9-]{1,64}$/.test(a.id)||ids.has(a.id))throw Error('ID de asset próprio inválido ou repetido.');ids.add(a.id);
  if(typeof a.source!=='string'||!/^data:image\/png;base64,[A-Za-z0-9+/=]+$/.test(a.source)||(total+=a.source.length)>8_000_000)throw Error('Assets precisam ser PNG e somar até 8 MB no JSON.');
  const bytes=Uint8Array.from(atob(a.source.split(',')[1].slice(0,44)),c=>c.charCodeAt(0));if(bytes.length<24||bytes[0]!==137||bytes[1]!==80||bytes[2]!==78||bytes[3]!==71)throw Error('PNG inválido.');const view=new DataView(bytes.buffer),width=view.getUint32(16),height=view.getUint32(20);
  if((pixels+=width*height)>16_777_216)throw Error('A biblioteca excede 16 milhões de pixels de textura.');
  const fw=Number(a.frameWidth??width),fh=Number(a.frameHeight??height),frames=Number(a.frames??1),fps=Number(a.fps??8);
  if(width<1||height<1||width>2048||height>2048||!Number.isInteger(fw)||!Number.isInteger(fh)||fw<1||fh<1||width%fw||height%fh||frames<1||!Number.isInteger(frames)||frames>Math.min(64,width/fw*height/fh)||!Number.isFinite(fps)||fps<1||fps>30)throw Error('Grade de frames inválida; use PNG até 2048 px, divisões exatas e até 64 frames.');
  const anchor=a.anchor??[fw/2,fh];if(!Array.isArray(anchor)||anchor.length!==2||anchor.some(v=>!Number.isFinite(v)||Math.abs(v)>2048))throw Error('Pivô inválido.');
  return {id:a.id,name:String(a.name||a.id).slice(0,80),source:a.source,width,height,frameWidth:fw,frameHeight:fh,frames,fps,anchor:[...anchor],custom:true,collidable:!!a.collidable,...(a.collision?{collision:validateCollision(a.collision)}:{})};
 });
}
