// Code-native art: every face is authored in the measured Iso Studio volume.
// Rasterization is a deterministic export of the editable SVG, not a resized atlas crop.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
import {presetKaelRoom,pieceBox,placement,manifest,auditPiece,auditSource,auditScene,verdict} from '../tools/iso-studio/model.mjs';
const require=createRequire(import.meta.url);
let sharp;try{sharp=require('sharp');}catch{sharp=require('C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');}
const out='assets/world/kael-bedroom-iso-v3',author='art/kael-bedroom-iso-v3';
await fs.mkdir(out,{recursive:true});await fs.mkdir(author,{recursive:true});
const project=presetKaelRoom();project.name='Quarto de Kael · madeira e vento';
const C={ink:'#243e49',wood:'#bb7e46',light:'#ecc28a',edge:'#f3d5a0',dark:'#80583b',teal:'#357d85',blue:'#245765',cream:'#f5e8bd',paper:'#fff4d1',red:'#ce684b'};
const svg=(w,h,body)=>`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}"><g stroke="${C.ink}" stroke-width="1" stroke-linejoin="round">${body}</g></svg>`;
const polygon=(ps,fill,stroke=C.ink)=>`<polygon points="${ps.map(p=>p.join(',')).join(' ')}" fill="${fill}" stroke="${stroke}"/>`;
const line=(ps,color=C.ink,width=1)=>`<polyline points="${ps.map(p=>p.join(',')).join(' ')}" fill="none" stroke="${color}" stroke-width="${width}"/>`;
function art(p){const b=pieceBox(p),[U,V]=p.footprint;
 const P=(u,v,z=0)=>[b.anchor[0]+(u-U)*32-(v-V)*32,b.h+(u-U)*16+(v-V)*16-z*32];
 const face=(ps,c)=>polygon(ps.map(([u,v,z])=>P(u,v,z)),c);
 const box=(u,v,w,d,z,h,top=C.light,left=C.wood,right=C.dark)=>face([[u,v+d,z],[u+w,v+d,z],[u+w,v+d,z+h],[u,v+d,z+h]],left)+face([[u+w,v,z],[u+w,v+d,z],[u+w,v+d,z+h],[u+w,v,z+h]],right)+face([[u,v,z+h],[u+w,v,z+h],[u+w,v+d,z+h],[u,v+d,z+h]],top);
 let a='';
 if(p.id==='tapete'){
  a=face([[0,0,0],[U,0,0],[U,V,0],[0,V,0]],C.teal);
  a+=face([[.2,.2,0],[U-.2,.2,0],[U-.2,V-.2,0],[.2,V-.2,0]],C.cream);
  a+=face([[.27,.27,0],[U-.27,.27,0],[U-.27,V-.27,0],[.27,V-.27,0]],C.blue);
  for(const u of [1.25,3.75])a+=face([[u,1,0],[u+.5,1.5,0],[u,2,0],[u-.5,1.5,0]],'#e7bd72');
 }else if(p.id==='abertura-escada'){
  a=face([[0,0,0],[U,0,0],[U,V,0],[0,V,0]],'#20383c');
  // Actual descending treads, clipped by the aperture in the floor plane.
  const opening=polygon([[0,0,0],[U,0,0],[U,V,0],[0,V,0]].map(q=>P(...q)),'white','none');
  a+=`<defs><clipPath id="stair-cut">${opening}</clipPath></defs><g clip-path="url(#stair-cut)">`;
  for(let i=5;i>=0;i--){const v=.12+i*.27,z=-i*.16; a+=face([[.12,v,z],[U-.12,v,z],[U-.12,v+.25,z],[.12,v+.25,z]],['#c79c67','#b68b59','#a87e50','#947047','#7e6040','#684f38'][i]);a+=face([[.12,v+.25,z],[U-.12,v+.25,z],[U-.12,v+.25,z-.12],[.12,v+.25,z-.12]],'#674d36');}
  a+='</g>';
 }else if(p.id==='cama'){
  a+=box(0,0,2,4,0,.45,C.light,C.wood,C.dark);
  a+=box(0,0,2,.18,.45,1.55,C.light,C.teal,C.blue);
  a+=box(.08,.2,1.84,3.72,.45,.35,'#f9edce','#c8b893','#b0a48d');
  a+=box(.12,.3,1.76,.8,.8,.2,'#fff5d8','#e5d3a9','#caba95');
  a+=box(.02,1.3,1.96,2.7,.79,.08,'#4d9b9c','#368085','#286570');
  for(const v of [1.44,3.55,3.7])a+=line([P(.06,v,.88),P(1.94,v,.88)],'#e9d598',2);
  a+=box(0,3.82,2,.18,0,.75,C.light,C.teal,C.blue);
 }else if(p.id==='estante'){
  a+=box(0,0,3,1,0,1.3,C.light,C.wood,C.dark);
  a+=face([[.15,1,.2],[1.8,1,.2],[1.8,1,1.05],[.15,1,1.05]],'#504b3d');
  a+=line([P(.15,1,.6),P(1.8,1,.6)],C.light,3);
  for(let i=0;i<6;i++)a+=face([[.25+i*.22,1,.65],[.42+i*.22,1,.65],[.42+i*.22,1,.98],[.25+i*.22,1,.98]],[C.blue,C.red,C.cream][i%3]);
  a+=face([[2,1,.2],[2.85,1,.2],[2.85,1,1.05],[2,1,1.05]],C.teal);
  a+=line([P(2.35,1,.65),P(2.55,1,.65)],C.edge,2);
 }else if(p.id==='tv'){
  a+=box(0,0,1.5,1,0,1.3,'#68827d','#456469','#2b4854');
  a+=face([[.1,1,.16],[1.14,1,.16],[1.14,1,1.16],[.1,1,1.16]],'#172e3c');
  a+=face([[.17,1,.24],[1.07,1,.24],[1.07,1,1.08],[.17,1,1.08]],'#7cbeb3');
  a+=face([[.18,1,.25],[1.07,1,.25],[1.07,1,.5],[.18,1,.5]],'#477c83');
  a+=line([P(.25,1,.7),P(.53,1,.93),P(.78,1,.7),P(.53,1,.49),P(.25,1,.7)],C.paper,2);
  for(const z of [.38,.65,.92])a+=line([P(1.25,1,z),P(1.4,1,z)],C.light,2);
 }else if(p.id==='guarda-roupa'){
  a+=box(0,0,2,1,0,4,C.light,C.wood,C.dark);
  for(let i=0;i<2;i++){
   a+=face([[.1+i,1,.2],[.9+i,1,.2],[.9+i,1,3.7],[.1+i,1,3.7]],C.teal);
   a+=face([[.2+i,1,.4],[.8+i,1,.4],[.8+i,1,3.5],[.2+i,1,3.5]],'#438e91');
   a+=line([P(.72+i*.55,1,1.8),P(.72+i*.55,1,2.06)],C.edge,2);
  }
  a+=box(0,0,2,1,3.8,.2,C.edge,C.light,C.wood);
 }else if(p.id==='mesa'){
  // Full side panels and a floor stretcher give the workbench a legible support.
  a+=box(0,0,.16,2,0,1.35,C.light,C.wood,C.dark);
  a+=box(2.84,0,.16,2,0,1.35,C.light,C.wood,C.dark);
  a+=box(0,1.82,3,.18,0,.13,C.light,C.wood,C.dark);
  a+=box(0,0,3,2,1.32,.18,C.edge,C.wood,C.dark);
  a+=face([[.45,.35,1.5],[2.5,.35,1.5],[2.5,1.65,1.5],[.45,1.65,1.5]],C.paper);
  const z=1.5;a+=line([P(1.4,.5,z),P(2.2,1,z),P(1.4,1.5,z),P(.7,1,z),P(1.4,.5,z)],C.teal,1);
  a+=line([P(.7,1,z),P(2.2,1,z)],C.wood);a+=line([P(1.4,.5,z),P(1.4,1.5,z)],C.wood);
 }else if(p.kind.startsWith('wall')){
  const W=(s,z)=>p.kind==='wallRight'?[s*32,b.h-(U-s)*16-z*32]:[(U-s)*32,b.h-(U-s)*16-z*32];
  const q=(x,y,w,h,color)=>polygon([W(x,y),W(x+w,y),W(x+w,y+h),W(x,y+h)],color);
  if(p.id==='janela'){
   a+=q(0,0,2,1.5,C.light)+q(.12,.12,1.76,1.25,C.blue)+q(.22,.22,1.56,1.05,'#9fd3cd');
   a+=line([W(1,.2),W(1,1.3)],C.cream,3)+line([W(.2,.72),W(1.8,.72)],C.cream,2);
   a+=line([W(.3,1.05),W(.7,1.05)],'#d8f1dd',2);
  }else{
   for(let i=0;i<3;i++){const x=.04+i*.66;a+=q(x,0,.57,.87,C.paper);a+=q(x+.21,.83,.15,.17,C.light);
    a+=line([W(x+.28,.68),W(x+.47,.43),W(x+.28,.19),W(x+.09,.43),W(x+.28,.68)],i===1?C.teal:C.wood);
   }
  }
 }
 return svg(b.w,b.h,a);
}
// Export exact native PNGs with binary alpha. SVG remains the editable source.
async function raster(source,file){const {data,info}=await sharp(Buffer.from(source)).ensureAlpha().raw().toBuffer({resolveWithObject:true});for(let i=3;i<data.length;i+=4)data[i]=data[i]>=128?255:0;await sharp(data,{raw:{width:info.width,height:info.height,channels:4}}).png().toFile(file);return {width:info.width,height:info.height,data};}
const reports=[],images={};
for(const p of project.pieces){const source=art(p),file=`${out}/${p.id}.png`;await fs.writeFile(`${author}/${p.id}.svg`,source);const img=await raster(source,file),b=pieceBox(p),items=[...auditSource(img),...auditPiece(p,img).items];reports.push({id:p.id,verdict:verdict(items),items});p.image='data:image/png;base64,'+(await fs.readFile(file)).toString('base64');images['bedroom-'+p.id]={image:`world/kael-bedroom-iso-v3/${p.id}.png`,width:b.w,height:b.h,pivot:[b.anchor[0]/b.w,1]};}
await fs.writeFile(`${out}/manifest.json`,JSON.stringify({...manifest(project),images,provenance:'Editable code-native SVG, measured with Iso Studio model; binary-alpha raster export.'},null,2)+'\n');
await fs.writeFile(`${author}/quarto-kael.isostudio.json`,JSON.stringify(project));
await fs.writeFile(`${author}/conferencia.json`,JSON.stringify({scene:auditScene(project.room,project.pieces),pieces:reports},null,2)+'\n');
for(const r of reports)console.log(`${r.id}: ${r.verdict} ${r.items.filter(i=>i.level==='fail').map(i=>i.text).join('; ')}`);
if(reports.some(r=>r.verdict==='fail')||auditScene(project.room,project.pieces).some(i=>i.level==='fail'))process.exitCode=1;
