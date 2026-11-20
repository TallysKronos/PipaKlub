import fs from 'node:fs';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
const root=new URL('../../',import.meta.url);
const source=new URL('art/soulgen/keys/trovareta/cutout-rig-v1/',root);
export function buildEntry(){
 const plan=JSON.parse(fs.readFileSync(new URL('export.json',source)));
 const png=fs.readFileSync(new URL('study-atlas.png',source));
 if(png.readUInt32BE(16)!==plan.width||png.readUInt32BE(20)!==plan.height)throw Error('Trovareta atlas and manifest differ');
 const frames=Object.fromEntries(plan.frames.map(f=>[f.name,f]));
 const animations={},playback={};
 for(const [action,clip] of Object.entries(plan.animations)){
  const name=action==='skill'?'attack':action;
  animations[name]=clip.frames.map(key=>{
   const f=frames[key];
   if(!f||f.x<0||f.y<0||f.x+f.w>plan.width||f.y+f.h>plan.height)throw Error('Invalid frame '+key);
   return {x:f.x,y:f.y,w:f.w,h:f.h};
  });
  playback[name]={fps:plan.fps,loop:clip.loop,seconds:clip.seconds};
 }
 return {image:'trovareta-v1/soulgen-atlas.png',animations,playback,source:{project:'art/soulgen/keys/trovareta/cutout-rig-v1/trovareta.soulgen.json',atlasSha256:crypto.createHash('sha256').update(png).digest('hex'),pixelPivot:plan.pixelPivot}};
}
export function integrate(){
 const folder=new URL('godot/assets/campaign/trovareta-v1/',root);
 fs.mkdirSync(folder,{recursive:true});
 fs.copyFileSync(new URL('study-atlas.png',source),new URL('soulgen-atlas.png',folder));
 const file=new URL('godot/assets/campaign/content.json',root);
 const original=fs.readFileSync(file,'utf8'),text=original.replaceAll('\r\n','\n');
 const combat=text.indexOf('"combat":');
 const first=text.indexOf('{',combat);
 function endOfObject(start){
  let depth=0,quoted=false,escaped=false;
  for(let i=start;i<text.length;i++){
   const ch=text[i];
   if(quoted){if(escaped)escaped=false;else if(ch==='\\')escaped=true;else if(ch==='"')quoted=false;continue;}
   if(ch==='"')quoted=true;
   else if(ch==='{')depth++;
   else if(ch==='}'&&--depth===0)return i;
  }
  throw Error('Unclosed content object');
 }
 const last=endOfObject(first),key=text.indexOf('"trovareta":',first);
 const entry=JSON.stringify(buildEntry(),null,2).replaceAll('\n','\n    ');
 let output;
 if(key>=0&&key<last){const start=text.indexOf('{',key);output=text.slice(0,start)+entry+text.slice(endOfObject(start)+1);}
 else output=text.slice(0,last).trimEnd()+',\n    "trovareta": '+entry+'\n  '+text.slice(last);
 // Keep every unrelated field and its authored formatting untouched.
 JSON.parse(output);
 fs.writeFileSync(file,output.replaceAll('\n',original.includes('\r\n')?'\r\n':'\n'));
 console.log('Trovareta: 123 frames, six actions; approved atlas copied unchanged.');
}
if(process.argv[1]===fileURLToPath(import.meta.url))integrate();
