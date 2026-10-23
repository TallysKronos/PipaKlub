import fs from 'node:fs/promises';
import{createRequire}from'node:module';
import{homeProject}from'../src/home-layout.js';
import{pieceBox,roomSize,screen,auditScene}from'../tools/iso-studio/model.mjs';
const require=createRequire(import.meta.url);let sharp;try{sharp=require('sharp');}catch{sharp=require('C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');}
const root='art/kael-home-iso-v1';await fs.mkdir(root+'/guides',{recursive:true});await fs.mkdir(root+'/sources',{recursive:true});
const poly=(pts,fill)=>`<polygon points="${pts.map(p=>p.join(',')).join(' ')}" fill="${fill}" stroke="#243e49" stroke-width="1" stroke-linejoin="round"/>`;
const svg=(w,h,a)=>`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">${a}</svg>`;
for(const p of homeProject.pieces){
 const b=pieceBox(p),[U,V]=p.footprint,P=(u,v,z=0)=>[b.anchor[0]+(u-U)*32-(v-V)*32,b.h+(u-U)*16+(v-V)*16-z*32],F=(pts,c)=>poly(pts.map(p=>P(...p)),c);
 const box=(u,v,w,d,z,h,top='#ebc189',left='#b67d47',right='#79563b')=>F([[u,v+d,z],[u+w,v+d,z],[u+w,v+d,z+h],[u,v+d,z+h]],left)+F([[u+w,v,z],[u+w,v+d,z],[u+w,v+d,z+h],[u+w,v,z+h]],right)+F([[u,v,z+h],[u+w,v,z+h],[u+w,v+d,z+h],[u,v+d,z+h]],top);
 let a='';
 if(p.id==='sofa'){
  a+=box(0,0,2,3,0,.45,'#397d81','#285d69','#204857');a+=box(0,0,.25,3,.45,1.85,'#68a5a2','#357a81','#285d69');
  for(let v=0;v<3;v++)a+=box(.25,v+.08,1.5,.84,.45,.4,'#65a4a1','#397d81','#285d69');
  a+=box(0,0,2,.22,.45,1,'#68a5a2','#397d81','#285d69')+box(0,2.78,2,.22,.45,1,'#68a5a2','#397d81','#285d69');
 }else if(p.id==='mesa-centro'){
  a+=box(0,0,1.5,1.5,0,.12);a+=box(.07,.07,.2,.2,.1,.55)+box(1.23,.07,.2,.2,.1,.55)+box(.07,1.23,.2,.2,.1,.55)+box(1.23,1.23,.2,.2,.1,.55);a+=box(0,0,1.5,1.5,.65,.17);
  a+=box(.8,.6,.35,.35,.82,.28,'#f8edcb','#e5d7b8','#af9c83');
 }else if(p.id==='mesa-jantar'||p.id.startsWith('banco')){
  const h=p.height;a+=box(0,0,U,V,0,.1);for(const u of [0,U-.2])for(const v of [0,Math.max(0,V-.2)])a+=box(u,v,.2,.2,.1,h-.25);a+=box(0,0,U,V,h-.15,.15);
 }else if(p.id==='cozinha'){
  a+=box(0,0,3,1,0,1.5,'#f7e8c5','#397d81','#285d69')+box(3,0,1,1,0,3.5,'#fff1d0','#e8d6b5','#ac9f85');
  a+=box(.3,.2,.8,.6,1.5,.03,'#6a9093','#456b70','#284c58');a+=box(1.6,.15,1.1,.75,1.5,.12,'#314b57','#52646a','#23424e');
 }else if(p.id==='escada'){
  // Solid side panel and eight rising treads, all inside the declared volume.
  a+=F([[0,0,0],[0,3,0],[0,3,.2],[0,0,4]],'#b67d47');
  a+=F([[2,0,0],[2,3,0],[2,3,.2],[2,0,4]],'#79563b');
  for(let i=0;i<8;i++)a+=box(0,i*3/8,2,3/8,0,4-i*.5,'#ebc189','#b67d47','#79563b');
 }else if(p.id==='porta'){
  const W=(s,z)=>[(U-s)*32,b.h-(U-s)*16-z*32];a+=poly([W(0,0),W(2,0),W(2,4),W(0,4)],'#c58c4e');a+=poly([W(.15,.12),W(1.85,.12),W(1.85,3.85),W(.15,3.85)],'#357a81');
  for(const z of [.4,2.2])a+=poly([W(.3,z),W(1.7,z),W(1.7,z+1.25),W(.3,z+1.25)],'#4b9293');
 }else{const source=p.id==='janela'?'janela':'tapete';await fs.copyFile(`assets/world/kael-bedroom-iso-v4/${source}.png`,`${root}/guides/${p.id}.png`);continue;}
 const source=svg(b.w,b.h,a);await fs.writeFile(`${root}/guides/${p.id}.svg`,source);await sharp(Buffer.from(source)).png().toFile(`${root}/guides/${p.id}.png`);await sharp(Buffer.from(source)).resize(b.w*4,b.h*4,{kernel:'nearest'}).png().toFile(`${root}/guides/${p.id}-4x.png`);
}
const room=homeProject.room,{w,h}=roomSize(room),P=(u,v,z=0)=>{const q=screen(room,u,v,z);return[q.x,q.y];};
let a=poly([P(0,0),P(12,0),P(12,9),P(0,9)],'#d9ab71');for(let v=0;v<=9;v+=.5)a+=`<path d="M${P(0,v)} L${P(12,v)}" stroke="#b88958" stroke-width=".6"/>`;
a+=poly([P(0,0),P(12,0),P(12,0,5),P(0,0,5)],'#f3e4bf')+poly([P(0,0),P(0,9),P(0,9,5),P(0,0,5)],'#ded4b1');
await fs.writeFile(`${root}/guides/casca.svg`,svg(w,h,a));await sharp(Buffer.from(svg(w,h,a))).resize(w*4,h*4,{kernel:'nearest'}).png().toFile(`${root}/guides/casca-4x.png`);
console.log('Room',w,h,'scene',auditScene(room,homeProject.pieces));
