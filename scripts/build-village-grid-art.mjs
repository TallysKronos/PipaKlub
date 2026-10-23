import fs from 'node:fs/promises';
import {createRequire} from 'node:module';
import {createHash} from 'node:crypto';
import {SERVICE_INTERIORS} from '../src/service-interiors.js';
import {pieceBox,roomSize,screen,placement,manifest,auditScene,auditPiece,auditSource,verdict} from '../tools/iso-studio/model.mjs';
const require=createRequire(import.meta.url);let sharp;try{sharp=require('sharp');}catch{sharp=require('C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');}
const root='art/village-grid-v2',out='assets/world/village-grid-v2';await fs.mkdir(out,{recursive:true});
const atlas=await sharp(root+'/sources/materials.png').metadata(),half=Math.floor(atlas.width/2),textures={};
for(const [name,x,y]of [['wood',0,0],['plaster',1,0],['roof',0,1],['teal',1,1]]){
 const bytes=await sharp(root+'/sources/materials.png').extract({left:x*half+8,top:y*half+8,width:half-16,height:half-16}).resize(256,256).png().toBuffer();textures[name]='data:image/png;base64,'+bytes.toString('base64');
}
let next=0;
const panels={};
const facadeAtlas=await sharp(root+'/sources/facades.png').metadata(),fw=Math.floor(facadeAtlas.width/2),fh=Math.floor(facadeAtlas.height/2);
for(const [id,x,y]of [['house',0,0],['professorHouse',1,0],['shop',0,1],['side',1,1]])panels[id]='data:image/png;base64,'+(await sharp(root+'/sources/facades.png').extract({left:x*fw+4,top:y*fh+4,width:fw-8,height:fh-8}).png().toBuffer()).toString('base64');
const furnitureAtlas=await sharp(root+'/sources/furniture.png').metadata(),bw=Math.floor(furnitureAtlas.width/2),bh=Math.floor(furnitureAtlas.height/2);
for(const [id,x,y]of [['books',0,0],['supplies',1,0],['counter',0,1],['tabletop',1,1]])panels[id]='data:image/png;base64,'+(await sharp(root+'/sources/furniture.png').extract({left:x*bw+3,top:y*bh+3,width:bw-6,height:bh-6}).png().toBuffer()).toString('base64');
function painter(width,height,origin){const parts=[],faces=[];
 const P=([u,v,z=0])=>[origin[0]+(u-v)*32,origin[1]+(u+v)*16-z*32],fmt=n=>Math.round(n*1000)/1000,points=qs=>qs.map(q=>P(q).map(fmt).join(',')).join(' ');
 const poly=(qs,fill,stroke='#594b38',sw=1)=>parts.push(`<polygon points="${points(qs)}" fill="${fill}" stroke="${stroke||'none'}" stroke-width="${sw}" stroke-linejoin="round"/>`);
 const line=(qs,color='#765737',sw=1)=>parts.push(`<polyline points="${points(qs)}" fill="none" stroke="${color}" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round"/>`);
 function face(qs,material,shade=0,clip=null){const ps=qs.map(P),a=qs[0],b=qs[1],d=qs[3],L=(q)=>Math.hypot(...q.map((n,i)=>n-a[i]))*64,w=L(b),h=L(d),id='face'+next++,m=[(ps[1][0]-ps[0][0])/w,(ps[1][1]-ps[0][1])/w,(ps[3][0]-ps[0][0])/h,(ps[3][1]-ps[0][1])/h,...ps[0]].map(fmt);
  faces.push({points:clip||qs,material});
  if(clip)parts.push(`<defs><clipPath id="${id}"><polygon points="${points(clip)}"/></clipPath></defs><g clip-path="url(#${id})">`);
  if(textures[material]||material.startsWith('panel:')){const panel=panels[material.slice(6)];parts.push(`<g transform="matrix(${m.join(' ')})">${panel?`<image href="${panel}" width="${w}" height="${h}" preserveAspectRatio="none"/>`:`<rect width="${w}" height="${h}" fill="url(#${material})"/>`}${shade?`<rect width="${w}" height="${h}" fill="${shade>0?'#273e40':'#fff2cc'}" opacity="${Math.abs(shade)}"/>`:''}</g>`);if(clip)parts.push('</g>');poly(clip||qs,'none');}
  else{poly(clip||qs,material);if(clip)parts.push('</g>');}
 }
 const roofFace=(qs,shade=0)=>{const a=qs[0],b=qs[1],d=qs.at(-1),c=b.map((n,i)=>n+d[i]-a[i]);face([a,b,c,d],'roof',shade,qs);};
 const top=(x,y,z,a,b,mat='wood',shade=-.08)=>face([[x,y,z],[x+a,y,z],[x+a,y+b,z],[x,y+b,z]],mat,shade);
 const front=(x,y,z,a,h,mat='wood',shade=0)=>face([[x,y,z+h],[x+a,y,z+h],[x+a,y,z],[x,y,z]],mat,shade);
 const side=(x,y,z,b,h,mat='wood',shade=.18)=>face([[x,y+b,z+h],[x,y,z+h],[x,y,z],[x,y+b,z]],mat,shade);
 function box(x,y,z,a,b,h,mat='wood'){front(x,y+b,z,a,h,mat);side(x+a,y,z,b,h,mat);top(x,y,z+h,a,b,mat);}
 const dot=(q,r,fill,stroke='none')=>{const [x,y]=P(q);parts.push(`<circle cx="${fmt(x)}" cy="${fmt(y)}" r="${r}" fill="${fill}" stroke="${stroke}" stroke-width=".7"/>`);};
 const window=(u,v,z,w=1.5,h=1.8,orientation='front')=>{
  const F=orientation==='front'?(s,t)=>[u+s,v,z+t]:(s,t)=>[u,v+s,z+t];
  const quad=(x,y,a,b,fill)=>poly([F(x,y),F(x+a,y),F(x+a,y+b),F(x,y+b)],fill);
  quad(-.12,-.12,w+.24,h+.24,'#b68b50');quad(0,0,w,h,'#184f59');quad(.12,.12,w-.24,h-.24,'#81c6ca');
  quad(.14,h*.5,w-.28,.08,'#f6e8c3');quad(w*.5-.04,.12,.08,h-.24,'#f6e8c3');
  line([F(.2,.3),F(w*.42,h*.38)],'#d2eeeb',1.6);line([F(w*.58,h*.55),F(w-.2,h-.2)],'#e1f2e9',1.6);
  quad(-.55,-.04,.4,h+.08,'#286e72');quad(w+.15,-.04,.4,h+.08,'#286e72');
  for(let a=.2;a<h;a+=.22){line([F(-.51,a),F(-.2,a)],'#164c55',.8);line([F(w+.2,a),F(w+.51,a)],'#164c55',.8);}
 };
 const kite=(u,v,z,w=1,h=1.5)=>{const qs=[[u+w/2,v,z+h],[u+w,v,z+h/2],[u+w/2,v,z],[u,v,z+h/2]],mid=[u+w/2,v,z+h/2],colors=['#ef9242','#f1cc68','#4b9396','#e16843'];for(let i=0;i<4;i++)poly([qs[i],qs[(i+1)%4],mid],colors[i],'#5f4937',.8);line([qs[0],qs[2]],'#f6e0a2',.8);line([qs[1],qs[3]],'#f6e0a2',.8);line([qs[2],[u+w*.7,v,z-.22],[u+w*.48,v,z-.45]],'#b57c42',.8);};
 function table(U,V,H){for(const [x,y]of [[.08,.08],[U-.3,.08],[.08,V-.3],[U-.3,V-.3]])box(x,y,0,.22,.22,H-.22,'wood');front(.1,V-.12,H-.55,U-.2,.4,'wood');side(U-.1,.12,H-.55,V-.24,.4,'wood');box(0,0,H-.22,U,V,.22,'wood');
  top(0,0,H,U,V,'panel:tabletop',0);
 }
 function shelf(U,V,H,shop=false){box(0,0,0,U,V,H,'wood');front(0,V,0,U,H,'panel:'+(shop?'supplies':'books'));
 }
 function finish(){const defs=Object.entries(textures).filter(([name])=>faces.some(f=>f.material===name)||name==='plaster').map(([name,url])=>`<pattern id="${name}" patternUnits="userSpaceOnUse" width="128" height="128"><image href="${url}" width="128" height="128"/></pattern>`).join('');return {svg:`<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}"><defs>${defs}</defs>${parts.join('')}</svg>`,faces};}
 return {P,poly,line,face,roofFace,top,front,side,box,dot,window,kite,table,shelf,finish};
}
// A grain-only swatch avoids drawing a second, conflicting board grid on the floor.
const floorGrain=await sharp(root+'/sources/materials.png').extract({left:20,top:16,width:64,height:half-32}).png().toBuffer();
textures.floorwood='data:image/png;base64,'+(await sharp(floorGrain).rotate(90).resize(256,256).png().toBuffer()).toString('base64');
const images={},reports=[],geometry={};
async function save(id,paint,w,h,anchor){const result=paint.finish();await fs.writeFile(`${root}/${id}.svg`,result.svg);await sharp(Buffer.from(result.svg),{density:288}).resize(w,h).png().toFile(`${out}/${id}.png`);images[id]={image:`world/village-grid-v2/${id}.png`,width:w,height:h,pivot:[anchor[0]/w,anchor[1]/h],sha256:createHash('sha256').update(await fs.readFile(`${out}/${id}.png`)).digest('hex')};geometry[id]=result.faces;return {width:w,height:h,data:await sharp(`${out}/${id}.png`).ensureAlpha().raw().toBuffer()};}
// Facades: roof, sill and wall edges share the same world-space axes.
for(const [id,U,V,wall,doorU]of [['house',7,6,8,3.9],['professorHouse',7,5,5,3.9],['shop',7,5,5,3.9]]){
 const height=wall+2.5,b=pieceBox({footprint:[U,V],height}),p=painter(b.w,b.h,[V*32,height*32]),{box,front,side,top,poly,line,window,kite,dot}=p;
 box(0,0,0,U,V,.12,'wood');front(.25,V-.25,0,U-.5,wall,'panel:'+id);side(U-.25,.25,0,V-.5,wall,'panel:side',.12);
 // Door and jambs are drawn in the wall plane, with a shallow real step.
 box(doorU-1.35,V-.25,0,2.7,.25,.12,'#bda478');
 // Four sloping roof surfaces cover both ends; no exposed plaster gable.
 const mid=V/2,peak=height-.05,inset=1.45,A=[inset,mid,peak],B=[U-inset,mid,peak];
 front(0,V,wall-.14,U,.14,'wood');side(U,0,wall-.14,V,.14,'wood');
 p.roofFace([[0,0,wall],[U,0,wall],B,A],.16);
 p.roofFace([[0,V,wall],[0,0,wall],A],.07);
 p.roofFace([[0,V,wall],[U,V,wall],B,A]);
 p.roofFace([[U,0,wall],[U,V,wall],B],.12);
 line([[0,V,wall],[U,V,wall]],'#824426',3);line([[0,V,wall+.035],[U,V,wall+.035]],'#f3ab58',1.2);
 for(const [a,b]of [[[0,0,wall],A],[[0,V,wall],A],[[U,0,wall],B],[[U,V,wall],B],[A,B]]){line([a,b],'#96502d',3);line([a,b],'#e9a24e',1.3);}
 // Modest sill planter: volume and leaves stay attached to the wall.
 const anchor=p.P([doorU,V-.25,0]),img=await save(id,p,b.w,b.h,anchor),items=[...auditSource(img),...auditPiece({footprint:[U,V],height},img).items];reports.push({id,footprint:[U,V],height,door:[doorU,V-.25],verdict:verdict(items),items,geometry:'projected from 64×32×32 vertices'});
}
for(const [scene,project]of Object.entries(SERVICE_INTERIORS)){
 const room=project.room,size=roomSize(room),s=painter(size.w,size.h,room.origin),[U,V]=room.cells,{top,front,side,poly,line}=s;
 top(0,0,0,U,V,'floorwood',-.2);
 front(0,0,0,U,room.wall,'plaster',-.04);side(0,0,0,V,room.wall,'plaster',.1);
 for(const z of [.12,.3,4.9]){line([[0,V,z],[0,0,z],[U,0,z]],z>4?'#f9edcc':'#936d45',z>4?2:3);}
 // Wood board seams are authored on the floor, not guessed from an illustration.
 for(let v=.5;v<V;v+=.5){line([[0,v,.002],[U,v,.002]],'#a67a4b',.55);for(let u=(v*2%2);u<U;u+=2)line([[u,v,.002],[u,v+.5,.002]],'#a67a4b',.55);}
 await save(project.prefix+'shell',s,size.w,size.h,[room.origin[0],size.h]);
 const editable=structuredClone(project);editable.name=project.name;editable.room.image='data:image/png;base64,'+(await fs.readFile(`${out}/${project.prefix}shell.png`)).toString('base64');
 for(const p of editable.pieces){const b=pieceBox(p),origin=p.kind==='wallRight'?[0,p.height*32]:p.kind==='wallLeft'?[b.w,p.height*32]:[p.footprint[1]*32,p.height*32],q=painter(b.w,b.h,origin),[a,c]=p.footprint,H=p.height;
  if(p.kind==='wallLeft'||p.kind==='wallRight'){
   const left=p.kind==='wallLeft',F=(s,z)=>left?[0,s,z]:[s,0,z];
   if(p.id==='window'){if(left)q.window(0,.55,.1,a-1.1,H-.2,'side');else q.window(.55,0,.1,a-1.1,H-.2);}
   else{for(let i=0;i<3;i++){const x=.1+i*.95,qs=[F(x,.08),F(x+.8,.08),F(x+.8,H-.12),F(x,H-.12)];q.poly(qs,'#f9edce','#a48759',.8);const m=x+.4;q.line([F(m,H-.25),F(x+.7,H/2),F(m,.22),F(x+.1,H/2),F(m,H-.25)],'#397e85',.9);q.line([F(m,.22),F(m,H-.25)],'#ba995e',.7);}}
  }else if(p.id==='rug'||p.id==='exit'){
   q.top(0,0,0,a,c,'#2d7076');q.poly([[.12,.12,0],[a-.12,.12,0],[a-.12,c-.12,0],[.12,c-.12,0]],'#3e8185','#d8bb77',1.2);
   q.line([[a/2-.4,c/2,0],[a/2,c/2-.25,0],[a/2+.4,c/2,0],[a/2,c/2+.25,0],[a/2-.4,c/2,0]],'#e7cb8d',1.3);
  }else if(['library','study'].includes(p.id))q.shelf(a,c,H,scene==='kite-shop');
  else if(['workbench','desk'].includes(p.id))q.table(a,c,H);
  else if(p.id==='counter'){q.box(0,0,0,a,c,H-.2,'teal');q.front(0,c,0,a,H-.2,'panel:counter');q.box(0,0,H-.2,a,c,.2,'wood');}
  else if(p.id==='rack'){q.box(0,0,0,a,c,.16,'wood');q.box(.1,.1,0,.16,.2,H,'teal');q.box(a-.26,.1,0,.16,.2,H,'teal');q.front(.1,.3,H-.2,a-.2,.15,'wood');q.kite(.25,.32,.9,.7,1.6);q.kite(1.05,.32,1.25,.7,1.6);}
  else{q.box(0,0,0,a,c,H,'wood');for(const x of [.22,a-.36]){q.front(x,c+.001,0,.14,H,'teal');q.top(x,0,H+.002,.14,c,'teal');}q.front(a/2-.13,c+.005,H*.4,.26,.32,'#d2ad5c');}
  const id=project.prefix+p.id,img=await save(id,q,b.w,b.h,b.anchor),items=[...auditSource(img),...auditPiece(p,img).items];reports.push({id,verdict:verdict(items),items});p.image='data:image/png;base64,'+(await fs.readFile(`${out}/${id}.png`)).toString('base64');
 }
 await fs.writeFile(`${root}/${scene}.isostudio.json`,JSON.stringify(editable));
}
const facades=reports.filter(p=>p.door),exterior={name:'Rua dos Ventos · fachadas na grade',room:{cells:[30,12],wall:12,origin:[384,384],image:null},pieces:await Promise.all(facades.map(async(p,i)=>({id:p.id.toLowerCase(),name:p.id,kind:'floor',footprint:p.footprint,height:p.height,cell:[8+i*10,8],elevation:0,scale:1,freeScale:null,offset:[0,0],locked:false,image:'data:image/png;base64,'+(await fs.readFile(`${out}/${p.id}.png`)).toString('base64')})))};
await fs.writeFile(`${root}/fachadas.isostudio.json`,JSON.stringify(exterior));
await fs.writeFile(`${out}/manifest.json`,JSON.stringify({version:2,grid:[64,32,32],images,facades:facades.map(({id,footprint,height,door})=>({id,footprint,height,door})),provenance:'Built-in image_gen flat material, facade and furniture atlases. Each raster asset is baked from exact orthographic 2:1 planar geometry; no column resampling or silhouette registration. Original paintings retained in art/village-grid-v2/sources.'},null,2)+'\n');
await fs.writeFile(`${root}/geometry.json`,JSON.stringify(geometry,null,2)+'\n');
await fs.writeFile(`${root}/conferencia.json`,JSON.stringify({scene:{facades:auditScene(exterior.room,exterior.pieces),...Object.fromEntries(Object.entries(SERVICE_INTERIORS).map(([id,p])=>[id,auditScene(p.room,p.pieces)]))},pieces:reports.map(r=>({...r,sha256:images[r.id].sha256})),notes:'Raster envelope heuristics are reported separately from exact geometry. They cannot approve or reject style; inspect the actual game.'},null,2)+'\n');
console.log('Built',Object.keys(images).length,'native grid assets.');
