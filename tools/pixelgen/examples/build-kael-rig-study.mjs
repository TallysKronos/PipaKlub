// Small native-pixel study. Original grids interpreted from the Kael DS concept;
// no downsampling, colour quantisation, cutout rotation or reuse of rejected sprites.
import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {createCharacterBase} from '../character-style.mjs';
import {validateProject,serialize,pixels} from '../core.mjs';
import {compositeAll} from '../document.mjs';
import {encodePNG} from '../png.mjs';
import {encodeGIF} from '../gif.mjs';
import {Canvas,frameRGBA,renderSheet,renderGrounds,gifFrames} from '../render.mjs';
import {drawPose} from '../rig.mjs';
import {atlas} from '../animation.mjs';
import {check} from '../cli.mjs';
const root=new URL('../../../',import.meta.url),out=new URL('art/characters/kael-rig-study-v4/',root);
fs.mkdirSync(out,{recursive:true});
const W=48,H=64,blank=()=>new Uint8Array(W*H);
const colors=['#152033','#22334e','#354f80','#5875a2','#b77960','#edb78c','#ffe1b0','#214773','#32649b','#6089b5','#303d52','#69798f','#e9e5d4','#2e9cae','#85d5d2','#c5a365'];
const p=createCharacterBase({name:'Kael · estudo de rig E',body:'jovem'});p.frames=[];p.sequences=[];p.cols=4;p.rows=1;
p.palette=[[0,0,0,0],...colors.map(c=>[1,3,5].map(i=>parseInt(c.slice(i,i+2),16)).concat(255))];
p.ramps={tinta:[1],cabelo:[2,3,4],pele:[5,6,7],roupa:[8,9,10],camiseta:[1,2],calca:[11,12],tenis:[2,13],fones:[14,15],metal:[16]};
p.sheet={nome:'Kael',cabecas:3.2,altura:54,base:61,cores:16,rampas:['tinta','pele','roupa'],referencia:'walk-E-1',preenchimentoMax:.78,notas:'Estudo de quatro chaves E: contato/passagem por perna; interpretação desenhada do conceito DS, ainda aguardando aprovação artística do usuário.'};
const symbols='.123456789abcdefg';
function stamp(c,x,y,rows){for(let j=0;j<rows.length;j++)for(let i=0;i<rows[j].length;i++){const v=symbols.indexOf(rows[j][i]);if(v<0)throw Error('Glyph '+rows[j][i]);if(v)put(c,x+i,y+j,v);}}
function put(c,x,y,v){x=Math.round(x);y=Math.round(y);if(x>=0&&y>=0&&x<W&&y<H)c[y*W+x]=v;}
function polygon(c,pts,color){const ys=pts.map(p=>p[1]);for(let y=Math.floor(Math.min(...ys));y<=Math.ceil(Math.max(...ys));y++){const xs=[];for(let i=0;i<pts.length;i++){const a=pts[i],b=pts[(i+1)%pts.length];if((a[1]<=y&&b[1]>y)||(b[1]<=y&&a[1]>y))xs.push(a[0]+(y-a[1])*(b[0]-a[0])/(b[1]-a[1]));}xs.sort((a,b)=>a-b);for(let i=0;i<xs.length;i+=2)for(let x=Math.ceil(xs[i]);x<=Math.floor(xs[i+1]);x++)put(c,x,y,color);}}
function segment(c,a,b,width,color){const dx=b[0]-a[0],dy=b[1]-a[1],l=Math.hypot(dx,dy)||1,nx=-dy/l*width/2,ny=dx/l*width/2;polygon(c,[[a[0]+nx,a[1]+ny],[b[0]+nx,b[1]+ny],[b[0]-nx,b[1]-ny],[a[0]-nx,a[1]-ny]],color);}
function limb(c,pts,near,kind){const outer=kind==='leg'?6:6,base=kind==='leg'?(near?12:11):(near?9:8);
 for(let i=0;i<2;i++)segment(c,pts[i],pts[i+1],outer,1);
 for(let i=0;i<2;i++)segment(c,pts[i],pts[i+1],outer-2,base);
 if(kind==='arm'){segment(c,pts[0].map((v,i)=>v+(i?1:-1)),pts[1].map((v,i)=>v+(i?0:-1)),1,near?13:10);const [x,y]=pts[2];stamp(c,x-2,y-2,['1111','d6d1','5661','5661','.11.']);}
 else{const [x,y]=pts[2];stamp(c,x-2,y-4,['.1111...','122221..','12222211','12222221','1dddddd1','.111111.']);}
}
const face=['....1111...','...156661..','..15677761.','.156776761.','.1567717611','..156717661','..15566661.','...156661..','....1111...'];
const hair=['.............11...','..........11131...','.......11133331...','.....11333333111..','...11334433333331.','..133444333333311.','.13344433333331...','13344333333333311.','12333333333333331.','123333333333311...','1223333311111.....','.12223331561......','..1222231661......','...12222161.......','....11111.........'];
const torso=['....111111...','..1182e811...','.18922fe81...','.189222281...','1899222281...','1899222281...','1899222281...','1899222281...','1899222281...','1899222281...','1899222281...','1899222281...','1899222281...','1899222281...','1899222281...','1899d22281...','1899d22281...','.18d11111....','..1d1........','...1.........'];
const keys=[
 {name:'contato-frente',bob:0,near:[[25,43],[29,51],[32,60]],far:[[25,43],[21,51],[18,60]],arm:[[23,29],[20,35],[18,41]],armFar:[[26,29],[29,35],[31,40]],support:['peTras','peFrente'],ms:130},
 {name:'passagem-tras',bob:-1,near:[[25,42],[25,51],[25,60]],far:[[25,42],[31,49],[26,55]],arm:[[23,28],[23,35],[24,41]],armFar:[[26,28],[28,34],[28,40]],support:['peFrente'],ms:120},
 {name:'contato-tras',bob:0,near:[[25,43],[21,51],[18,60]],far:[[25,43],[29,51],[32,60]],arm:[[23,29],[27,35],[30,40]],armFar:[[26,29],[23,35],[21,41]],support:['peTras','peFrente'],ms:130},
 {name:'passagem-frente',bob:-1,near:[[25,42],[31,49],[26,55]],far:[[25,42],[25,51],[25,60]],arm:[[23,28],[24,35],[25,41]],armFar:[[26,28],[26,34],[26,40]],support:['peTras'],ms:120}
];
for(const [i,key]of keys.entries()){
 const c=p.layers.map(blank),[armFar,legFar,legNear,body,armNear,head,hairCel]=c;
 limb(armFar,key.armFar,false,'arm');limb(legFar,key.far,false,'leg');limb(legNear,key.near,true,'leg');
 stamp(body,19,25+key.bob,torso);stamp(body,25,23+key.bob,['1111','1561','1561','1111']);
 limb(armNear,key.arm,true,'arm');stamp(head,24,16+key.bob,face);stamp(hairCel,15,8+key.bob,hair);
 const pose={topo:[25,8+key.bob],queixo:[29,24+key.bob],pescoco:[26,27+key.bob],quadril:[25,43+key.bob],ombroTras:key.armFar[0],cotoveloTras:key.armFar[1],maoTras:key.armFar[2],ombroFrente:key.arm[0],cotoveloFrente:key.arm[1],maoFrente:key.arm[2],joelhoTras:key.far[1],peTras:key.far[2],joelhoFrente:key.near[1],peFrente:key.near[2]};
 p.frames.push({name:`walk-E-${i+1}`,duration:key.ms,cels:c,indices:blank(),pose,support:key.support,poseDirty:false});
}
p.sequences=[{name:'walk-E',start:0,end:3,loop:true,direction:'forward'}];
const project=validateProject(serialize(p));compositeAll(project);
const write=(name,bytes)=>fs.writeFileSync(new URL(name,out),bytes);
write('kael-rig.pixelgen.json',JSON.stringify(serialize(project)));
const rgba=new Uint8ClampedArray(W*4*H*4);for(let i=0;i<4;i++){const f=pixels(project,project.frames[i]);for(let y=0;y<H;y++)rgba.set(f.subarray(y*W*4,(y+1)*W*4),(y*W*4+i*W)*4);}
write('kael-walk.png',encodePNG(rgba,W*4,H));write('kael-walk.atlas.json',JSON.stringify(atlas(project,'kael-walk.png'),null,2));
const film=renderSheet(project,[0,1,2,3],{zoom:6,ground:'papel'});write('prancha.png',encodePNG(film.data,film.w,film.h));
const grounds=renderGrounds(project,0);write('chao.png',encodePNG(grounds.data,grounds.w,grounds.h));
const cv=new Canvas(4*(W*4+8),H*4+30);for(let i=0;i<4;i++){const ox=i*(W*4+8);cv.blit(frameRGBA(project,i),W,H,ox,8,4);drawPose(cv,project.frames[i].pose,ox,8,4);cv.text(keys[i].name,ox,270);}write('rig.png',encodePNG(cv.data,cv.w,cv.h));
const gif=gifFrames(project,[0,1,2,3],{zoom:4,ground:'grama'});write('kael-walk.gif',encodeGIF(gif.frames,gif.width,gif.height,gif.palette));
write('qa.json',JSON.stringify(check(project),null,2));
console.log(fileURLToPath(out));
