// Authoring export only: does not replace game creatures or atlas.json.
import fs from 'node:fs';
import {pathToFileURL} from 'node:url';
import {identity,validate,render,sample,exportPlan} from '../tools/soulgen-studio/model.mjs';
const {createCanvas,loadImage}=await import(pathToFileURL(process.env.SOULGEN_CANVAS_MODULE||'C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@napi-rs/canvas/index.js'));
const root='art/soulgen/keys/lobo-cordeiro',out=root+'/color-rig-v2';fs.mkdirSync(out,{recursive:true});
if(fs.existsSync(out+'/lobo-cordeiro.soulgen.json')&&JSON.parse(fs.readFileSync(out+'/lobo-cordeiro.soulgen.json')).expressionRevision>=2)throw Error('Rig salvo pelo usuário: preserve os ajustes. Use register-lobo-faces.py para registro facial.');
const sheet=await loadImage(root+'/source/parts-generated.png');
const regions={body:[40,40,465,285],head:[600,0,380,345],tail:[1050,0,475,350],front:[140,345,365,310],rear:[660,350,280,305],sail:[1050,350,465,315],happy:[95,650,390,360],fierce:[575,650,380,360],hurt:[1060,650,390,365]};
const assets={},images={};
for(const [id,r]of Object.entries(regions)){
 const c=createCanvas(r[2],r[3]),g=c.getContext('2d');g.drawImage(sheet,...r,0,0,r[2],r[3]);
 const d=g.getImageData(0,0,c.width,c.height);
 // Remove separate slivers from neighboring cells, preserving the actual head.
 if(['head','happy','fierce','hurt'].includes(id)){
  const seen=new Uint8Array(c.width*c.height);let largest=[];
  for(let k=0;k<seen.length;k++){if(seen[k]||d.data[k*4+3]<=32)continue;const q=[k];seen[k]=1;for(let j=0;j<q.length;j++){const n=q[j],x=n%c.width,y=Math.floor(n/c.width);for(const next of [x>0?n-1:-1,x<c.width-1?n+1:-1,y>0?n-c.width:-1,y<c.height-1?n+c.width:-1])if(next>=0&&!seen[next]&&d.data[next*4+3]>32){seen[next]=1;q.push(next);}}if(q.length>largest.length)largest=q;}
  const keep=new Uint8Array(seen.length);for(const n of largest)keep[n]=1;for(let k=0;k<keep.length;k++)if(!keep[k])d.data[k*4+3]=0;g.putImageData(d,0,0);
 }
 let l=c.width,t=c.height,rr=0,b=0;
 for(let y=0;y<c.height;y++)for(let x=0;x<c.width;x++)if(d.data[(y*c.width+x)*4+3]>32){l=Math.min(l,x);t=Math.min(t,y);rr=Math.max(rr,x);b=Math.max(b,y);}
 const cut=createCanvas(rr-l+1,b-t+1);cut.getContext('2d').drawImage(c,l,t,cut.width,cut.height,0,0,cut.width,cut.height);
 const file=root+'/source/'+id+'.png';fs.writeFileSync(file,cut.toBuffer('image/png'));images[id]=await loadImage(file);assets[id]={name:id,src:'/'+file,width:cut.width,height:cut.height};
}
const p={schema:'soulgen-studio',version:1,creatureId:'lobo-cordeiro',artRevision:1,rigRevision:1,name:'Lobo em pele de cordeiro · papel vivo',width:240,height:180,rootPivot:[126,105],brief:{species:'Lobo em pele de cordeiro + pipa',personality:'Astuto, atento e expressivo',kiteAnatomy:'Capuz de papel dobrado, armação dorsal, remendos e rabiola articulada.',view:'Três quartos à direita',notes:'Conceito do usuário adaptado ao acabamento Carcará. Projeto de autoria, sem integração ao jogo.'},assets,parts:[],clips:{}};
const part=(id,name,asset,rect,pivot,z,parent='body',lag=0)=>p.parts.push({id,name,asset,source:[0,0,assets[asset].width,assets[asset].height],rect,pivot,z,parent,lag,visible:true});
part('rearFar','Pata traseira distante','rear',[85,99,36,54],[96,104],0);
part('frontFar','Pata dianteira distante','front',[153,95,39,55],[166,102],1);
part('tail','Rabiola','tail',[12,42,80,59],[77,47],2,'body',.08);
part('rearNear','Pata traseira próxima','rear',[69,103,41,61],[82,109],3);
part('frontNear','Pata dianteira próxima','front',[144,104,44,61],[157,110],4);
part('body','Tronco','body',[65,69,112,63],[124,103],5,null);
part('sail','Pipa dorsal','sail',[70,47,104,70],[117,89],6,'body',.03);
part('head','Cabeça e capuz','head',[143,26,75,69],[157,87],7,'body',.015);
const h=p.parts.find(q=>q.id==='head');h.faces=Object.fromEntries(['happy','fierce','hurt'].map(id=>[id,{asset:id,source:[0,0,assets[id].width,assets[id].height]}]));
const frame=(t,root={},parts={})=>({t,ease:'spline',values:Object.fromEntries([['root',{...identity(),...root}],...p.parts.map(q=>[q.id,{...identity(),...(parts[q.id]||{})}])])});
const clip=(seconds,loop,frames,expressions=[])=>({seconds,loop,frames,expressions});
p.clips.idle=clip(2.4,true,[frame(0),frame(.6,{y:-.8},{head:{rotation:-1.3},tail:{rotation:3},sail:{rotation:1}}),frame(1.2),frame(1.8,{y:.6},{head:{rotation:1},tail:{rotation:-3},sail:{rotation:-1}}),frame(2.4)]);
p.clips.walk=clip(.8,true,[frame(0,{}, {frontNear:{rotation:-8},rearFar:{rotation:-8},frontFar:{rotation:8},rearNear:{rotation:8}}),frame(.2,{y:-1},{head:{rotation:-1}}),frame(.4,{}, {frontNear:{rotation:8},rearFar:{rotation:8},frontFar:{rotation:-8},rearNear:{rotation:-8},tail:{rotation:4}}),frame(.6,{y:-1}),frame(.8,{}, {frontNear:{rotation:-8},rearFar:{rotation:-8},frontFar:{rotation:8},rearNear:{rotation:8}})]);
p.clips.flight=clip(1.2,true,[frame(0),frame(.3,{y:-3},{frontNear:{rotation:-8},rearNear:{rotation:6},tail:{rotation:6},sail:{rotation:-2}}),frame(.6),frame(.9,{y:2},{tail:{rotation:-5},sail:{rotation:2}}),frame(1.2)]);
p.clips.skill=clip(1.1,false,[frame(0),frame(.35,{x:-3,y:2},{head:{rotation:-5},tail:{rotation:-6}}),frame(.6,{x:7,y:-2},{head:{rotation:5},frontNear:{rotation:-9},tail:{rotation:7}}),frame(1.1)],[{start:.25,end:.9,face:'fierce'}]);p.clips.skill.hitTime=.6;
p.clips.hurt=clip(.55,false,[frame(0),frame(.12,{x:-4,rotation:-2},{head:{rotation:-5},sail:{rotation:3}}),frame(.3,{x:1}),frame(.55)],[{start:0,end:.5,face:'hurt'}]);
p.clips.victory=clip(1.8,false,[frame(0),frame(.45,{y:-4},{head:{rotation:-3},tail:{rotation:8}}),frame(.9,{y:1},{tail:{rotation:-5}}),frame(1.4,{y:-2},{tail:{rotation:4}}),frame(1.8)],[{start:.2,end:1.8,face:'happy'}]);
const report=validate(p);if(!report.ok)throw Error(report.errors.join('\n'));
fs.writeFileSync(out+'/lobo-cordeiro.soulgen.json',JSON.stringify(p,null,2)+'\n');
const portable=structuredClone(p);for(const a of Object.values(portable.assets))a.src='data:image/png;base64,'+fs.readFileSync('.'+a.src).toString('base64');fs.writeFileSync(out+'/lobo-cordeiro.portable.soulgen.json',JSON.stringify(portable)+'\n');
const portrait=createCanvas(960,720);render(portrait.getContext('2d'),p,images,sample(p,'idle',0),{scale:4});fs.writeFileSync(out+'/portrait.png',portrait.toBuffer('image/png'));
const review=createCanvas(1200,720),g=review.getContext('2d');g.fillStyle='#e9ebd7';g.fillRect(0,0,1200,720);
for(const [i,id]of Object.keys(p.clips).entries()){g.fillStyle='#193c40';g.font='bold 18px sans-serif';const x=(i%3)*400,y=Math.floor(i/3)*360;g.fillText(id,x+16,y+26);render(g,p,images,sample(p,id,id==='skill'?.6:id==='hurt'?.12:.45),{clear:false,scale:1.65,offsetX:x-400,offsetY:y-180});}
fs.writeFileSync(out+'/assembly-review.png',review.toBuffer('image/png'));
const plan=exportPlan(p,{fps:12,cell:256,columns:8}),atlas=createCanvas(plan.width,plan.height);for(const f of plan.frames){const tile=createCanvas(256,256);render(tile.getContext('2d'),p,images,sample(p,f.clip,f.time),{scale:plan.renderScale});atlas.getContext('2d').drawImage(tile,f.x,f.y);}fs.writeFileSync(out+'/authoring-atlas.png',atlas.toBuffer('image/png'));fs.writeFileSync(out+'/export.json',JSON.stringify({report,plan,scope:'Soulgen authoring only; no game integration'},null,2));
console.log('Projeto Soulgen criado: '+p.parts.length+' peças, 4 expressões, '+plan.frames.length+' quadros.');
