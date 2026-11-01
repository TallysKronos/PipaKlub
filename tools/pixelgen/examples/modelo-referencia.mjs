#!/usr/bin/env node
// Reference model for judging poses and recipes: a 2.5-head character drawn from shaded
// shapes (light from top-left, 3–4 tone cel shading, darker back limbs), in the E and S views,
// then animated with the idle/walk/run recipes. Usage:
//   node tools/pixelgen/examples/modelo-referencia.mjs saida.pixelgen.json
import fs from 'node:fs';
import {validateProject,serialize} from '../core.mjs';
import {apply} from '../draw.mjs';
import {recipe,validateSheet} from '../rig.mjs';

const W=48,H=64,L=(()=>{const v=[-.55,-.62,.56],n=Math.hypot(...v);return v.map(x=>x/n);})();
export const RAMPS={
 tinta:['#1b1a2e'],
 pele:['#94503f','#d68f63','#f4c391','#fde2bd'],
 cabelo:['#2a2152','#4a3a93','#7663d8','#b9a8ff'],
 roupa:['#73264a','#cf4458','#ff7866','#ffbd9c'],
 calca:['#232b52','#3a4c88','#6079bd'],
 tenis:['#7d80a6','#d9dcec','#ffffff'],
 olho:['#ffffff']};
// Per-layer pixel maps; later writes win, like painting.
// at(dx,dy) translates later drawing, so a whole part can be posed by an offset.
export function canvas(){const m=new Map();let ox=0,oy=0;return {m,at(dx=0,dy=0){ox=dx;oy=dy;return this;},set(x,y,c){x+=ox;y+=oy;if(x>=0&&y>=0&&x<W&&y<H)m.set(x+','+y,c);},del(x,y){m.delete((x+ox)+','+(y+oy));},has(x,y){return m.has((x+ox)+','+(y+oy));}};}
export const tone=(ramp,dot,shift=0)=>{const n=RAMPS[ramp].length,t=n>=4?(dot>.93?3:dot>.6?2:dot>.08?1:0):n===3?(dot>.6?2:dot>.08?1:0):0;return `${ramp}:${Math.max(0,Math.min(n-1,t+shift))}`;};
export const lit=(nx,ny)=>{const nz=Math.sqrt(Math.max(0,1-nx*nx-ny*ny));return nx*L[0]+ny*L[1]+nz*L[2];};
export function ellipse(c,cx,cy,rx,ry,ramp,{shift=0,keep=()=>true,soft=.9}={}){for(let y=Math.floor(cy-ry);y<=cy+ry;y++)for(let x=Math.floor(cx-rx);x<=cx+rx;x++){const nx=(x-cx)/(rx+.5),ny=(y-cy)/(ry+.5);if(nx*nx+ny*ny>1||!keep(x,y))continue;c.set(x,y,tone(ramp,lit(nx*soft,ny*soft),shift));}}
// Vertical cylinder (limb, torso) with rounded ends; r rounds the corners.
export function capsule(c,x0,y0,x1,y1,ramp,{shift=0,r=1,tilt=-.2}={}){const cx=(x0+x1)/2,hw=(x1-x0)/2+.5;for(let y=y0;y<=y1;y++)for(let x=x0;x<=x1;x++){
 const cornerX=x<x0+r?x0+r-x:x>x1-r?x-(x1-r):0,cornerY=y<y0+r?y0+r-y:y>y1-r?y-(y1-r):0;if(cornerX&&cornerY&&cornerX*cornerX+cornerY*cornerY>r*r+.5)continue;
 const ny=y<y0+2?-.5:y>y1-1?.3:tilt;c.set(x,y,tone(ramp,lit((x-cx)/hw*.95,ny),shift));}}
// Interior edge of a part in the part's darkest shade (sel-out), so overlapping parts separate.
export function selout(c,ramp,{skipTop=false}={}){const edge=[];for(const k of c.m.keys()){const [x,y]=k.split(',').map(Number);if(!c.m.get(k).startsWith(ramp+':'))continue;
 for(const [dx,dy] of [[1,0],[-1,0],[0,1],[0,-1]]){if(skipTop&&dy===-1)continue;if(!c.m.has((x+dx)+','+(y+dy))){edge.push([x,y]);break;}}}for(const [x,y] of edge)c.m.set(x+','+y,ramp+':0');}
export const ops=layers=>Object.entries(layers).flatMap(([layer,c])=>{const by=new Map();for(const [k,v] of c.m){if(!by.has(v))by.set(v,[]);by.get(v).push(k.split(',').map(Number));}return [...by].map(([color,points])=>({op:'pixels',layer,color,points}));});

function shoe(c,x,front,shift){for(let y=57;y<=59;y++)for(let i=-1;i<=(front?4:3);i++){if(y===57&&(i<0||i>2))continue;c.set(x+i,y,tone('tenis',lit((i-1.5)/3.5,(y-58)/2)*1.1,shift));}for(let i=-1;i<=(front?4:3);i++)c.set(x+i,60,'roupa:1');}
function sideView(){
 const back=canvas(),front=canvas(),armB=canvas(),torso=canvas(),armF=canvas(),head=canvas(),hair=canvas();
 // Legs: shorts end at 46, skin to 56, then the shoe pointing forward (right).
 capsule(back,21,46,23,56,'pele',{shift:-1,r:0});shoe(back,21,true,-1);
 capsule(front,24,46,26,56,'pele',{r:0});shoe(front,24,true,0);
 capsule(armB,21,30,24,37,'roupa',{shift:-1});capsule(armB,22,38,24,40,'pele',{shift:-1,r:0});ellipse(armB,23,42,1.5,1.5,'pele',{shift:-1});
 capsule(torso,22,26,25,29,'pele',{shift:-1,r:0});
 capsule(torso,18,29,29,42,'roupa',{r:3});capsule(torso,16,28,19,32,'roupa',{shift:-1,r:2});
 capsule(torso,19,41,29,47,'calca',{r:1,tilt:.2});for(const y of [32,33,34])torso.set(28,y,'tenis:2');
 capsule(armF,23,30,26,38,'roupa',{r:2,tilt:-.45});selout(armF,'roupa',{skipTop:true});for(let y=32;y<=37;y++)armF.set(22,y,'tinta:0');for(let x=23;x<=26;x++)armF.set(x,38,'roupa:3');
 capsule(armF,23,39,25,40,'pele',{r:0});ellipse(armF,24.5,42,1.5,1.5,'pele');
 // Head: profile to the right; ear, tall manga eye, blush, mouth.
 ellipse(head,24,18,9,10,'pele',{soft:.7});for(const [x,y] of [[21,18],[21,19],[22,19],[21,20],[22,20]])head.set(x,y,'pele:0');head.set(22,18,'pele:1');
 for(const y of [17,18,19,20])head.set(28,y,'tinta:0');head.set(29,17,'olho:0');head.set(29,18,'cabelo:2');head.set(29,19,'cabelo:1');head.set(29,20,'tinta:0');head.set(27,16,'tinta:0');head.set(28,16,'tinta:0');
 head.set(31,22,'roupa:2');head.set(30,22,'roupa:3');head.set(31,25,'pele:0');head.set(32,25,'pele:0');head.set(34,20,'pele:2');
 // Hair: cap over the top and back, spikes behind and on top, a fringe falling over the forehead.
 ellipse(hair,23.5,16.5,10.5,10.5,'cabelo',{keep:(x,y)=>y<=12||(x<=20&&y<=25)||(x<=22&&y<=15)});
 for(const [x,y] of [[12,12],[11,13],[12,13],[12,14],[13,14],[11,17],[12,17],[12,18],[13,18],[12,21],[13,21],[13,22],[14,22],[13,25],[14,25],[14,26],[18,5],[19,5],[19,6],[23,4],[24,4],[23,5],[24,5],[28,5],[28,6],[29,6]])hair.set(x,y,'cabelo:1');
 for(const [x,y] of [[25,13],[26,13],[27,13],[28,13],[29,13],[30,13],[31,13],[32,13],[27,14],[28,14],[30,14],[31,14],[32,14],[31,15],[32,15],[33,14],[33,13]])hair.set(x,y,y>13?'cabelo:1':'cabelo:2');
 for(const [x,y] of [[19,9],[20,9],[21,8],[22,8],[18,10]])hair.set(x,y,'cabelo:3');
 return {'Perna de trás':back,'Perna da frente':front,'Braço de trás':armB,'Tronco':torso,'Braço da frente':armF,'Cabeça':head,'Cabelo':hair};
}
function frontView(){
 const back=canvas(),front=canvas(),armB=canvas(),torso=canvas(),armF=canvas(),head=canvas(),hair=canvas();
 const shoeS=(c,x,shift)=>{for(let y=57;y<=59;y++)for(let i=0;i<=4;i++){if(y===57&&(i===0||i===4))continue;c.set(x+i,y,tone('tenis',lit((i-2)/3,(y-58)/2)*1.1,shift));}for(let i=0;i<=4;i++)c.set(x+i,60,'roupa:1');};
 capsule(back,20,46,22,56,'pele',{r:0});shoeS(back,19,0);capsule(front,26,46,28,56,'pele',{r:0});shoeS(front,25,0);
 capsule(torso,22,26,26,29,'pele',{shift:-1,r:0});capsule(torso,16,29,32,42,'roupa',{r:3});capsule(torso,17,41,31,47,'calca',{r:1,tilt:.2});
 for(let y=46;y<=47;y++)for(let x=23;x<=25;x++)torso.del(x,y);for(let y=33;y<=42;y++)torso.set(24,y,'roupa:0');for(const x of [21,27])for(const y of [31,32,33])torso.set(x,y,'tenis:2');
 capsule(armB,13,30,16,38,'roupa',{r:2});capsule(armB,14,39,15,40,'pele',{r:0});ellipse(armB,14.5,42,1.5,1.5,'pele');
 capsule(armF,32,30,35,38,'roupa',{r:2,shift:-1});capsule(armF,33,39,34,40,'pele',{r:0,shift:-1});ellipse(armF,33.5,42,1.5,1.5,'pele',{shift:-1});
 for(const c of [armB,armF])selout(c,'roupa',{skipTop:true});
 ellipse(head,24,18,10,10,'pele',{soft:.7});
 for(const ex of [19,27]){for(const y of [17,18,19,20])head.set(ex,y,'tinta:0');head.set(ex+1,17,'olho:0');head.set(ex+1,18,'cabelo:2');head.set(ex+1,19,'cabelo:1');head.set(ex+1,20,'tinta:0');head.set(ex,16,'tinta:0');head.set(ex+1,16,'tinta:0');}
 for(const x of [17,30])head.set(x,22,'roupa:3');head.set(23,25,'pele:0');head.set(24,25,'pele:0');
 ellipse(hair,24,16.5,11,10.5,'cabelo',{keep:(x,y)=>y<=12||((x<=15||x>=33)&&y<=23)});
 for(let x=15;x<=33;x++){hair.set(x,13,'cabelo:2');if(x%3!==0)hair.set(x,14,'cabelo:1');if(x%3===1)hair.set(x,15,'cabelo:1');}
 for(const [x,y] of [[17,5],[18,5],[18,6],[24,4],[24,3],[25,4],[24,5],[30,5],[31,6],[30,6],[12,14],[13,14],[12,17],[13,17],[36,14],[35,14],[36,17],[35,17],[13,22],[14,22],[35,22],[34,22]])hair.set(x,y,'cabelo:1');
 for(const [x,y] of [[18,8],[19,8],[20,7],[21,7],[17,9]])hair.set(x,y,'cabelo:3');
 return {'Perna de trás':back,'Perna da frente':front,'Braço de trás':armB,'Tronco':torso,'Braço da frente':armF,'Cabeça':head,'Cabelo':hair};
}
const POSE_E={topo:[24,8],queixo:[24,28],ombroTras:[23,31],ombroFrente:[24,31],maoTras:[23,43],maoFrente:[24,43],quadril:[24,45],peTras:[23,60],peFrente:[26,60]};
const POSE_S={topo:[24,8],queixo:[24,28],ombroTras:[15,31],ombroFrente:[33,31],maoTras:[14,43],maoFrente:[33,43],quadril:[24,45],peTras:[21,60],peFrente:[27,60]};

export function build(){
 const blank=()=>Array(W*H).fill(0);
 const order=['Braço de trás','Perna de trás','Perna da frente','Tronco','Braço da frente','Cabeça','Cabelo'];
 const p=validateProject({kind:'pixelgen',version:2,name:'Modelo de referência',width:W,height:H,cols:1,rows:1,palette:[[0,0,0,0]],layers:order.map(name=>({name})),frames:[{name:'idle-E-1',indices:blank(),cels:order.map(blank)}]});
 apply(p,[...Object.entries(RAMPS).map(([name,colors])=>({op:'ramp',name,colors})),{op:'frame',add:'idle-S-1'},
  ...ops(sideView()).map(o=>({...o,frame:0})),...ops(frontView()).map(o=>({...o,frame:1})),
  {op:'pose',frame:0,points:POSE_E},{op:'pose',frame:1,points:POSE_S},{op:'outline',color:'tinta:0'}]);
 p.sheet=validateSheet({nome:'Modelo',cabecas:2.8,altura:60,base:61,cores:24,referencia:'idle-E-1',rampas:Object.keys(RAMPS),preenchimentoMax:.8,notas:'Gabarito de proporção e de tempo das receitas.'},p);
 for(const [motion,dir,base] of [['idle','E','idle-E-1'],['walk','E','idle-E-1'],['run','E','idle-E-1'],['idle','S','idle-S-1'],['walk','S','idle-S-1']])recipe(p,{motion,dir,base,replace:true});
 return p;
}
if(process.argv[1]&&import.meta.url.endsWith(process.argv[1].split('/').pop())){const out=process.argv[2]||'modelo-referencia.pixelgen.json';fs.writeFileSync(out,JSON.stringify(serialize(build())));console.log(out);}
