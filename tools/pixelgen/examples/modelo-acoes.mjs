#!/usr/bin/env node
// Action boards for the reference model in the 8 directions: climbing a vertical wooden
// ladder (back view, up and down), victory, defeat and swimming. Limbs are jointed (shoulder → elbow → hand,
// hip → knee → foot), so knees bend and arms rise. Usage:
//   node tools/pixelgen/examples/modelo-acoes.mjs saida.pixelgen.json
import fs from 'node:fs';
import {validateProject,serialize} from '../core.mjs';
import {apply} from '../draw.mjs';
import {validateSheet} from '../rig.mjs';
import {RAMPS,canvas,tone,lit,ellipse,capsule,selout,ops} from './modelo-referencia.mjs';

const W=48,H=64,LAYERS=['Braço de trás','Perna de trás','Perna da frente','Tronco','Braço da frente','Cabeça','Cabelo'];
RAMPS.agua=['#2f6f9f','#7cc8e4','#e4fbff'];
// Thick polyline shaded as a cylinder across its length.
function limb(c,pts,w,ramp,shift=0){const hw=w/2,xs=pts.map(p=>p[0]),ys=pts.map(p=>p[1]);
 for(let y=Math.floor(Math.min(...ys)-hw-1);y<=Math.max(...ys)+hw+1;y++)for(let x=Math.floor(Math.min(...xs)-hw-1);x<=Math.max(...xs)+hw+1;x++){let best=null;
  for(let i=0;i<pts.length-1;i++){const [ax,ay]=pts[i],[bx,by]=pts[i+1],dx=bx-ax,dy=by-ay,len2=dx*dx+dy*dy||1,len=Math.sqrt(len2);let t=((x-ax)*dx+(y-ay)*dy)/len2;t=Math.max(0,Math.min(1,t));
   const px=ax+t*dx,py=ay+t*dy,d=Math.hypot(x-px,y-py);if(!best||d<best.d)best={d,nx:-dy/len,ny:dx/len,s:((x-px)*-dy+(y-py)*dx)/len};}
  if(best.d>hw+.01)continue;const k=best.s/(hw+.5);c.set(x,y,tone(ramp,lit(best.nx*k*.95,best.ny*k*.95-.1),shift));}}
function arm(c,S,E,Hd,shift=0){limb(c,[E,Hd],3,'pele',shift);limb(c,[S,E],4,'roupa',shift);ellipse(c,Hd[0],Hd[1],1.5,1.5,'pele',{shift});selout(c,'roupa');}
const Q34=v=>v==='SE'||v==='NE';
function shoe(c,F,view,shift=0){const [fx,fy]=F,a=-2,b=view==='E'||Q34(view)?3:2;for(let y=fy-3;y<fy;y++)for(let i=a;i<=b;i++){if(y===fy-3&&(i===a||i===b))continue;c.set(fx+i,y,tone('tenis',lit((i-(a+b)/2)/3.2,(y-fy+1.5)/2)*1.1,shift));}for(let i=a;i<=b;i++)c.set(fx+i,fy,'roupa:1');}
// A leg ending in a shoe, or (kneeling seen from the side) a shin lying on the ground with the sole up.
function leg(c,Hp,K,F,view,shift=0,lying=false){
 if(lying){limb(c,[Hp,K,F],3,'pele',shift);for(const [x,y,v] of [[F[0]-2,F[1]-1,'tenis:1'],[F[0]-1,F[1]-1,'tenis:1'],[F[0]-2,F[1],'roupa:1'],[F[0]-1,F[1],'roupa:1']])c.set(x,y,v);return;}
 limb(c,F?[Hp,K,[F[0],F[1]-2]]:[Hp,K],3,'pele',shift);if(F)shoe(c,F,view,shift);}
function torso(c,view,[bx,by]){c.at(bx,by);
 if(view==='E'){capsule(c,22,26,25,29,'pele',{shift:-1,r:0});capsule(c,18,29,29,42,'roupa',{r:3});capsule(c,16,28,19,32,'roupa',{shift:-1,r:2});capsule(c,19,41,29,47,'calca',{r:1,tilt:.2});for(const y of [32,33,34])c.set(28,y,'tenis:2');}
 else if(Q34(view)){capsule(c,22,26,26,29,'pele',{shift:-1,r:0});capsule(c,17,29,31,42,'roupa',{r:3});capsule(c,18,41,30,47,'calca',{r:1,tilt:.2});for(let y=46;y<=47;y++)for(let x=24;x<=25;x++)c.del(x,y);
  if(view==='SE'){for(let y=33;y<=42;y++)c.set(26,y,'roupa:0');for(const x of [23,28])for(const y of [31,32,33])c.set(x,y,'tenis:2');}
  else{capsule(c,18,29,27,34,'roupa',{shift:-1,r:3});for(let x=20;x<=25;x++)c.set(x,30,'roupa:0');}}
 else{capsule(c,22,26,26,29,'pele',{shift:-1,r:0});capsule(c,16,29,32,42,'roupa',{r:3});capsule(c,17,41,31,47,'calca',{r:1,tilt:.2});for(let y=46;y<=47;y++)for(let x=23;x<=25;x++)c.del(x,y);
  if(view==='S'){for(let y=33;y<=42;y++)c.set(24,y,'roupa:0');for(const x of [21,27])for(const y of [31,32,33])c.set(x,y,'tenis:2');}
  else{capsule(c,19,29,29,34,'roupa',{shift:-1,r:3});for(let x=21;x<=27;x++)c.set(x,30,'roupa:0');}}
 c.at(0,0);}
const SWEAT=(h,x,y)=>{for(const [a,b] of [[x,y],[x,y+1],[x-1,y+1],[x,y+2]])h.set(a,b,'agua:1');h.set(x,y,'agua:2');};
function eyes(h,expr){for(const ex of [19,27]){const L=ex===19;
 if(expr==='feliz'){for(const [x,y] of [[ex,17],[ex+1,17],[ex-1,18],[ex+2,18]])h.set(x,y,'tinta:0');}
 else if(expr==='dor'){for(const [x,y] of L?[[ex,17],[ex+1,18],[ex,19]]:[[ex+1,17],[ex,18],[ex+1,19]])h.set(x,y,'tinta:0');}
 else if(expr==='fechado'){h.set(ex,19,'tinta:0');h.set(ex+1,19,'tinta:0');h.set(L?ex-1:ex+2,18,'tinta:0');}
 else{for(const y of [17,18,19,20])h.set(ex,y,'tinta:0');h.set(ex+1,17,'olho:0');h.set(ex+1,18,'cabelo:2');h.set(ex+1,19,'cabelo:1');h.set(ex+1,20,'tinta:0');h.set(ex,16,'tinta:0');h.set(ex+1,16,'tinta:0');}}
 if(expr==='feliz'){for(const [x,y] of [[22,24],[23,25],[24,25],[25,24]])h.set(x,y,'tinta:0');h.set(23,24,'roupa:1');h.set(24,24,'roupa:1');for(const x of [17,18,30,31])h.set(x,22,'roupa:2');}
 else if(expr==='dor'){for(const [x,y] of [[22,25],[23,24],[24,25],[25,24]])h.set(x,y,'tinta:0');}
 else if(expr==='fechado'){h.set(23,25,'pele:0');h.set(24,25,'pele:0');SWEAT(h,33,11);}
 else{for(const x of [17,30])h.set(x,22,'roupa:3');h.set(23,25,'pele:0');h.set(24,25,'pele:0');}}
// Three-quarter front (SE): near eye full width, far eye one pixel, mouth toward the facing side.
function eyes3q(h,expr){
 if(expr==='feliz'){for(const [x,y] of [[21,17],[22,17],[20,18],[23,18],[28,17],[29,18]])h.set(x,y,'tinta:0');for(const [x,y] of [[25,24],[26,25],[27,25],[28,24]])h.set(x,y,'tinta:0');h.set(26,24,'roupa:1');h.set(27,24,'roupa:1');for(const x of [19,20,30])h.set(x,22,'roupa:2');}
 else if(expr==='dor'){for(const [x,y] of [[21,17],[22,18],[21,19],[29,17],[28,18],[29,19],[25,25],[26,24],[27,25],[28,24]])h.set(x,y,'tinta:0');}
 else if(expr==='fechado'){for(const [x,y] of [[21,19],[22,19],[20,18],[28,19],[29,19]])h.set(x,y,'tinta:0');h.set(26,25,'pele:0');h.set(27,25,'pele:0');SWEAT(h,32,11);}
 else{for(const y of [17,18,19,20])h.set(21,y,'tinta:0');h.set(22,17,'olho:0');h.set(22,18,'cabelo:2');h.set(22,19,'cabelo:1');h.set(22,20,'tinta:0');h.set(21,16,'tinta:0');h.set(22,16,'tinta:0');
  h.set(28,16,'tinta:0');h.set(29,16,'tinta:0');h.set(28,17,'olho:0');h.set(28,18,'cabelo:2');h.set(28,19,'cabelo:1');h.set(28,20,'tinta:0');h.set(19,22,'roupa:3');h.set(26,25,'pele:0');h.set(27,25,'pele:0');}}
function sideFace(h,expr){
 if(expr==='feliz'){for(const [x,y] of [[27,18],[28,17],[29,17],[30,18],[31,24],[32,24],[32,25]])h.set(x,y,'tinta:0');h.set(31,25,'roupa:1');}
 else if(expr==='dor'){for(const [x,y] of [[28,17],[29,18],[28,19],[31,25],[32,24]])h.set(x,y,'tinta:0');}
 else if(expr==='fechado'){for(const [x,y] of [[27,18],[28,19],[29,19]])h.set(x,y,'tinta:0');h.set(31,25,'pele:0');SWEAT(h,34,11);}
 else{for(const y of [17,18,19,20])h.set(28,y,'tinta:0');h.set(29,17,'olho:0');h.set(29,18,'cabelo:2');h.set(29,19,'cabelo:1');h.set(29,20,'tinta:0');h.set(27,16,'tinta:0');h.set(28,16,'tinta:0');
  if(expr==='esforco'){h.set(31,24,'tinta:0');h.set(32,24,'tinta:0');h.set(31,25,'roupa:1');h.set(32,25,'tinta:0');}else{h.set(31,25,'pele:0');h.set(32,25,'pele:0');}}
 h.set(31,22,'roupa:2');h.set(30,22,'roupa:3');h.set(34,20,'pele:2');}
const TOP=[[17,5],[18,5],[18,6],[24,4],[25,4],[24,5],[30,5],[31,6],[30,6]],SHINE=[[18,8],[19,8],[20,7],[21,7],[17,9]];
function head(h,hair,view,[bx,by],expr){h.at(bx,by);hair.at(bx,by);
 if(view==='E'){ellipse(h,24,18,9,10,'pele',{soft:.7});for(const [x,y] of [[21,18],[21,19],[22,19],[21,20],[22,20]])h.set(x,y,'pele:0');sideFace(h,expr);
  ellipse(hair,23.5,16.5,10.5,10.5,'cabelo',{keep:(x,y)=>y<=12||(x<=20&&y<=25)||(x<=22&&y<=15)});
  for(const [x,y] of [[12,12],[11,13],[12,13],[12,14],[13,14],[11,17],[12,17],[12,18],[13,18],[12,21],[13,21],[13,22],[14,22],[13,25],[14,25],[14,26],[18,5],[19,5],[19,6],[23,4],[24,4],[23,5],[24,5],[28,5],[28,6],[29,6]])hair.set(x,y,'cabelo:1');
  for(const [x,y] of [[25,13],[26,13],[27,13],[28,13],[29,13],[30,13],[31,13],[32,13],[27,14],[28,14],[30,14],[31,14],[32,14],[31,15],[32,15],[33,14],[33,13]])hair.set(x,y,y>13?'cabelo:1':'cabelo:2');
  for(const [x,y] of [[19,9],[20,9],[21,8],[22,8],[18,10]])hair.set(x,y,'cabelo:3');}
 else if(view==='SE'){ellipse(h,24,18,9.5,10,'pele',{soft:.7});for(const [x,y] of [[17,19],[17,20],[18,20]])h.set(x,y,'pele:0');h.set(18,19,'pele:1');eyes3q(h,expr);
  ellipse(hair,23.5,16.5,11,10.5,'cabelo',{keep:(x,y)=>y<=12||(x<=16&&y<=24)||(x<=19&&y<=15)});
  for(let x=19;x<=33;x++){hair.set(x,13,'cabelo:2');if(x%3!==0)hair.set(x,14,'cabelo:1');if(x%3===1)hair.set(x,15,'cabelo:1');}
  for(const [x,y] of [...TOP,[33,14],[34,15],[34,16],[33,17],[12,13],[12,14],[13,14],[12,17],[13,17],[12,18],[13,21],[13,22],[14,22],[14,25],[15,25]])hair.set(x,y,'cabelo:1');for(const [x,y] of SHINE)hair.set(x,y,'cabelo:3');}
 else if(view==='NE'){ellipse(h,24,18,9.5,10,'pele',{soft:.7});h.set(15,19,'pele:1');h.set(15,20,'pele:0');
  ellipse(hair,24,16.5,11,10.5,'cabelo',{keep:(x,y)=>y<=24&&!(x>=31&&y>=17)&&!(x<=15&&y>=18&&y<=21)});
  for(const [x,y] of [...TOP,[12,14],[13,14],[12,17],[13,17],[13,22],[14,22],[18,25],[19,26],[23,26],[24,27],[25,26],[29,25]])hair.set(x,y,'cabelo:1');for(const [x,y] of [...SHINE,[20,12],[21,11],[22,11]])hair.set(x,y,'cabelo:3');}
 else{ellipse(h,24,18,10,10,'pele',{soft:.7});
  if(view==='S'){eyes(h,expr);ellipse(hair,24,16.5,11,10.5,'cabelo',{keep:(x,y)=>y<=12||((x<=15||x>=33)&&y<=23)});for(let x=15;x<=33;x++){hair.set(x,13,'cabelo:2');if(x%3!==0)hair.set(x,14,'cabelo:1');if(x%3===1)hair.set(x,15,'cabelo:1');}}
  else{for(const [x,y] of [[13,19],[13,20],[35,19],[35,20]])h.set(x,y,'pele:1');ellipse(hair,24,16.5,11,10.5,'cabelo',{keep:(x,y)=>y<=24});for(const [x,y] of [[18,25],[19,26],[23,26],[24,27],[25,26],[29,26],[30,25]])hair.set(x,y,'cabelo:0');}
  for(const [x,y] of [...TOP,[12,14],[13,14],[12,17],[13,17],[36,14],[35,14],[36,17],[35,17],[13,22],[14,22],[35,22],[34,22]])hair.set(x,y,'cabelo:1');
  for(const [x,y] of view==='S'?SHINE:[...SHINE,[20,12],[21,11],[22,11]])hair.set(x,y,'cabelo:3');}
 h.at(0,0);hair.at(0,0);}
const add=([x,y],[dx,dy])=>[x+dx,y+dy];
const FRONT={sb:[15,31],sf:[33,31],hb:[21,45],hf:[27,45]},Q={sb:[16,31],sf:[30,31],hb:[22,45],hf:[25,45]};
const JOINTS={S:FRONT,N:FRONT,E:{sb:[23,31],sf:[24,31],hb:[23,45],hf:[25,45]},SE:Q,NE:Q};
// One frame: body offset b, extra head offset, arms [elbow,hand], legs [knee,foot|null,hip?,lying?].
// "B" limbs are the screen-left ones in front/back views; in the three-quarter views they are the
// near limbs, so they go on the front layers and the far ones get the darker shade.
function frame(spec){
 const {view,b=[0,0],hd=[0,0],expr='normal'}=spec,J=JOINTS[view],L=Object.fromEntries(LAYERS.map(n=>[n,canvas()])),q=Q34(view);
 torso(L['Tronco'],view,b);head(L['Cabeça'],L['Cabelo'],view,add(b,hd),expr);
 const legLayer=k=>L[(k==='B')!==q?'Perna de trás':'Perna da frente'],farShift=k=>view==='E'?(k==='B'?-1:0):q?(k==='F'?-1:0):0;
 for(const k of ['B','F']){const l=spec['leg'+k];if(l)leg(legLayer(k),l[2]||add(J['h'+k.toLowerCase()],b),l[0],l[1],view,farShift(k),l[3]===true);}
 // Kneeling (front views): the soles show behind the knees, pointing back and out.
 if(spec.feetBehind)for(const [x0,dir] of [[14,-1],[30,1]])for(let i=0;i<4;i++){L['Perna de trás'].set(x0+i,59,i===(dir<0?0:3)?'tenis:0':'tenis:1');L['Perna de trás'].set(x0+i,60,'roupa:1');}
 for(const k of ['B','F']){const a=spec['arm'+k];if(!a)continue;const c=canvas();arm(c,add(J['s'+k.toLowerCase()],b),...a,view==='S'?(k==='F'?-1:0):farShift(k));
  // A raised near arm passes in front of the head (fist up in the side and three-quarter views).
  const near=view==='E'?k==='F':q?k==='B':false,raised=spec.water===undefined&&a[1][1]<J['s'+k.toLowerCase()][1]+b[1]-6;
  const dst=spec.armsOver||(near&&raised)?L['Cabelo']:L[(k==='B')!==q?'Braço de trás':'Braço da frente'];for(const [key,v] of c.m)dst.m.set(key,v);}
 if(spec.water!==undefined)for(const c of Object.values(L))for(const k of [...c.m.keys()])if(+k.split(',')[1]>=spec.water)c.m.delete(k);
 const pose={topo:add([24,8],add(b,hd)),queixo:add([24,28],add(b,hd)),ombroTras:add(J.sb,b),ombroFrente:add(J.sf,b),quadril:add([24,45],b)};
 if(spec.armB)pose.maoTras=spec.armB[1];if(spec.armF)pose.maoFrente=spec.armF[1];if(spec.legB)pose.peTras=spec.legB[1]||spec.legB[0];if(spec.legF)pose.peFrente=spec.legF[1]||spec.legF[0];
 for(const k of Object.keys(pose))pose[k]=[Math.max(0,Math.min(W-1,pose[k][0])),Math.max(0,Math.min(H-1,pose[k][1]))];
 const body=new Set(Object.values(L).flatMap(c=>[...c.m.keys()]));
 return {layers:L,pose,ripple:spec.water===undefined?null:ripple(spec,body)};
}
// O, SO and NO are E, SE and NE mirrored (the light flips side, accepted in the overworld).
function mirror(f){const flipKey=k=>{const [x,y]=k.split(',').map(Number);return (W-1-x)+','+y;};const layers={};
 for(const [n,c] of Object.entries(f.layers)){const m=canvas();for(const [k,v] of c.m)m.m.set(flipKey(k),v);layers[n]=m;}
 return {layers,pose:Object.fromEntries(Object.entries(f.pose).map(([k,[x,y]])=>[k,[W-1-x,y]])),ripple:f.ripple&&f.ripple.map(([x,y,c])=>[W-1-x,y,c])};}
const S='S',N='N',E='E';
export const DIRECTIONS=['S','SO','O','NO','N','NE','E','SE'];
// Each action is drawn in S and E (climb only in N); N, SE and NE are derived, O/SO/NO mirrored.
export const ACTIONS={
 // Back view on a vertical ladder; rails at x≈16 and x≈32, the hands grip them. A ladder is
 // always faced, so climbing has only the N view; climbdown-N plays the same frames backwards.
 climb:{loop:true,only:'N',N:[
  {d:160,view:N,b:[0,0],armsOver:true,armB:[[12,22],[16,13]],armF:[[37,28],[32,23]],legB:[[20,49],[21,55]],legF:[[27,52],[27,60]]},
  {d:120,view:N,b:[0,-1],armsOver:true,armB:[[11,25],[16,18]],armF:[[37,27],[32,20]],legB:[[20,51],[21,58]],legF:[[28,51],[27,58]]},
  {d:160,view:N,b:[0,0],armsOver:true,armB:[[11,28],[16,23]],armF:[[36,22],[32,13]],legB:[[21,52],[21,60]],legF:[[28,49],[27,55]]},
  {d:120,view:N,b:[0,-1],armsOver:true,armB:[[11,27],[16,20]],armF:[[37,25],[32,18]],legB:[[20,51],[21,58]],legF:[[28,51],[27,58]]}]},
 victory:{loop:false,
  S:[{d:120,view:S,b:[0,3],armB:[[13,37],[15,43]],armF:[[35,37],[33,43]],legB:[[19,53],[21,60],[21,48]],legF:[[29,53],[27,60],[27,48]]},
   {d:100,view:S,b:[0,-2],expr:'feliz',armB:[[12,32],[10,36]],armF:[[35,22],[35,15]],legB:[[20,49],[21,57]],legF:[[28,49],[27,57]]},
   {d:140,view:S,b:[0,-3],expr:'feliz',armB:[[11,26],[9,18]],armF:[[37,26],[39,18]],legB:[[19,48],[20,55]],legF:[[29,48],[28,55]]},
   {d:700,view:S,b:[0,0],expr:'feliz',armB:[[11,36],[17,41]],armF:[[36,23],[36,16]],legB:[[20,52],[20,60]],legF:[[28,52],[28,60]]}],
  E:[{d:120,view:E,b:[0,3],armB:[[21,38],[20,43]],armF:[[25,38],[26,43]],legB:[[26,53],[22,60],[23,48]],legF:[[29,53],[25,60],[25,48]]},
   {d:100,view:E,b:[0,-2],expr:'feliz',armF:[[30,24],[36,15]],armB:[[20,33],[17,36]],legB:[[23,50],[21,57]],legF:[[27,50],[26,57]]},
   {d:140,view:E,b:[0,-3],expr:'feliz',armF:[[30,24],[35,14]],armB:[[19,24],[16,16]],legB:[[23,49],[21,55]],legF:[[27,49],[27,55]]},
   {d:700,view:E,b:[0,0],expr:'feliz',armF:[[30,25],[36,16]],armB:[[19,36],[21,41]],legB:[[22,52],[21,60]],legF:[[27,52],[28,60]]}]},
 defeat:{loop:false,
  S:[{d:120,view:S,b:[0,-1],hd:[0,-1],expr:'dor',armB:[[11,33],[8,37]],armF:[[37,33],[40,37]],legB:[[21,52],[21,60]],legF:[[27,52],[27,60]]},
   {d:140,view:S,b:[0,3],hd:[0,1],expr:'fechado',armB:[[14,38],[15,45]],armF:[[34,38],[33,45]],legB:[[23,52],[20,60],[21,48]],legF:[[25,52],[28,60],[27,48]]},
   {d:200,view:S,b:[0,9],hd:[0,2],expr:'fechado',armB:[[13,46],[14,54]],armF:[[35,46],[34,54]],legB:[[20,59],null,[21,54]],legF:[[28,59],null,[27,54]],feetBehind:true},
   {d:900,view:S,b:[0,10],hd:[0,3],expr:'fechado',armB:[[14,48],[18,56]],armF:[[34,48],[30,56]],legB:[[20,60],null,[21,55]],legF:[[28,60],null,[27,55]],feetBehind:true}],
  E:[{d:120,view:E,b:[-1,-1],hd:[-1,-1],expr:'dor',armF:[[29,33],[33,36]],armB:[[18,33],[15,36]],legB:[[22,52],[21,60]],legF:[[26,52],[26,60]]},
   {d:140,view:E,b:[0,3],hd:[1,1],expr:'fechado',armF:[[25,39],[27,45]],armB:[[22,39],[22,45]],legB:[[26,52],[22,60],[23,48]],legF:[[28,52],[25,60],[25,48]]},
   {d:200,view:E,b:[1,9],hd:[1,2],expr:'fechado',armF:[[28,47],[31,54]],armB:[[25,47],[28,54]],legB:[[28,58],[20,60],[24,54],true],legF:[[30,58],[22,60],[26,54],true]},
   {d:900,view:E,b:[1,10],hd:[2,3],expr:'fechado',armF:[[29,49],[32,56]],armB:[[26,49],[29,56]],legB:[[28,59],[20,60],[24,55],true],legF:[[30,59],[22,60],[26,55],true]}]},
 // In water the body is cut at the waterline; ripples are added after the outline.
 swim:{loop:true,
  S:[{d:150,view:S,b:[0,10],water:43,ripple:13,armB:[[16,44],[20,42]],armF:[[32,44],[28,42]]},
   {d:150,view:S,b:[0,9],water:43,ripple:15,armB:[[13,43],[11,41]],armF:[[35,43],[37,41]]},
   {d:150,view:S,b:[0,10],water:43,ripple:17,armB:[[12,41],[13,39]],armF:[[36,41],[35,39]]},
   {d:150,view:S,b:[0,11],water:43,ripple:14,armB:[[15,43],[17,41]],armF:[[33,43],[31,41]]}],
  E:[{d:150,view:E,b:[0,10],water:43,ripple:12,expr:'esforco',armF:[[31,41],[36,42]],armB:[[19,35],[23,31]]},
   {d:150,view:E,b:[0,9],water:43,ripple:14,armF:[[28,45],[25,47]],armB:[[27,33],[32,35]]},
   {d:150,view:E,b:[0,10],water:43,ripple:12,expr:'esforco',armB:[[31,41],[36,42]],armF:[[20,35],[24,31]]},
   {d:150,view:E,b:[0,11],water:43,ripple:14,armB:[[28,45],[25,47]],armF:[[27,33],[32,35]]}]}};
// Three-quarter views from the front pose: near (screen-left) limbs move out 1px, far ones tuck
// 3px (arms) or 2px (legs) toward the body.
const shiftPts=(a,dx)=>a&&a.map(p=>Array.isArray(p)?[p[0]+dx,p[1]]:p);
// A raised far arm keeps its place so it still shows beside the head.
const quarter=(s,view)=>({...s,view,armB:shiftPts(s.armB,1),armF:shiftPts(s.armF,s.armF&&s.armF[1][1]<26?0:-3),legB:shiftPts(s.legB,1),legF:shiftPts(s.legF,-2)});
export function framesFor(action,dir){const a=ACTIONS[action];
 if(a.only)return dir===a.only?a[dir].map(frame):null;
 const base={S:()=>a.S,N:()=>a.S.map(s=>({...s,view:'N'})),E:()=>a.E,SE:()=>a.S.map(s=>quarter(s,'SE')),NE:()=>a.S.map(s=>quarter(s,'NE'))};
 const src={O:'E',SO:'SE',NO:'NE'}[dir];return src?base[src]().map(frame).map(mirror):base[dir]().map(frame);}
function ripple(spec,body){const out=[],cx=24+(spec.view==='E'?2:Q34(spec.view)?1:0),cy=spec.water,rx=spec.ripple,ry=2;
 for(let a=0;a<360;a+=4){const x=Math.round(cx+Math.cos(a*Math.PI/180)*rx),y=Math.round(cy+Math.sin(a*Math.PI/180)*ry);if(body.has(x+','+y))continue;if((a/4)%5===4)continue;out.push([x,y,y>cy?'agua:2':'agua:1']);}
 for(let x=cx-rx+3;x<=cx+rx-3;x+=2)if(!body.has(x+','+cy))out.push([x,cy,'agua:2']);return out;}
export function build(){
 const blank=()=>Array(W*H).fill(0),items=[],seqs=[];
 for(const [action,a] of Object.entries(ACTIONS))for(const dir of DIRECTIONS){const fr=framesFor(action,dir);if(!fr)continue;const name=`${action}-${dir}`,src=a.only?a[a.only]:a.S;
  seqs.push({name,start:items.length,end:items.length+fr.length-1,loop:a.loop,direction:'forward'});fr.forEach((f,i)=>items.push({...f,name:`${name}-${i+1}`,d:src[i].d}));
  if(action==='climb')seqs.push({name:'climbdown-N',start:seqs.at(-1).start,end:seqs.at(-1).end,loop:true,direction:'reverse'});}
 const p=validateProject({kind:'pixelgen',version:2,name:'Modelo de referência — ações',width:W,height:H,cols:1,rows:1,palette:[[0,0,0,0]],layers:LAYERS.map(name=>({name})),frames:[{name:items[0].name,indices:blank(),cels:LAYERS.map(blank)}]});
 const list=[...Object.entries(RAMPS).map(([name,colors])=>({op:'ramp',name,colors}))];
 items.forEach((f,i)=>{list.push(i?{op:'frame',add:f.name,duration:f.d}:{op:'frame',target:0,duration:f.d});list.push(...ops(f.layers).map(o=>({...o,frame:i})),{op:'pose',frame:i,points:f.pose});});
 list.push({op:'outline',color:'tinta:0'});
 items.forEach((f,i)=>{if(!f.ripple)return;list.push({op:'erase',frame:i,layer:'Contorno',rect:{x:0,y:43,w:W,h:H-43}});const by=new Map();for(const [x,y,c] of f.ripple){if(!by.has(c))by.set(c,[]);by.get(c).push([x,y]);}
  for(const [color,points] of by)list.push({op:'pixels',frame:i,layer:'Contorno',color,points});});
 apply(p,list);p.sequences=seqs;
 p.sheet=validateSheet({nome:'Modelo',cabecas:2.8,altura:60,base:61,cores:24,referencia:'victory-S-4',notas:'Ações do gabarito: escada, vitória, derrota e nado nas 8 direções.'},p);return p;
}
if(process.argv[1]&&import.meta.url.endsWith(process.argv[1].split('/').pop())){const out=process.argv[2]||'modelo-acoes.pixelgen.json';fs.writeFileSync(out,JSON.stringify(serialize(build())));console.log(out);}
