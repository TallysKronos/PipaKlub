#!/usr/bin/env node
// Action boards for the reference model: climbing a vertical wooden ladder (back view),
// victory, defeat, and swimming (front and side). Limbs are jointed (shoulder → elbow → hand,
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
function shoe(c,F,view,shift=0){const [fx,fy]=F,a=-2,b=view==='E'?3:2;for(let y=fy-3;y<fy;y++)for(let i=a;i<=b;i++){if(y===fy-3&&(i===a||i===b))continue;c.set(fx+i,y,tone('tenis',lit((i-(a+b)/2)/3.2,(y-fy+1.5)/2)*1.1,shift));}for(let i=a;i<=b;i++)c.set(fx+i,fy,'roupa:1');}
function leg(c,Hp,K,F,view,shift=0){limb(c,F?[Hp,K,[F[0],F[1]-2]]:[Hp,K],3,'pele',shift);if(F)shoe(c,F,view,shift);}
function torso(c,view,[bx,by]){c.at(bx,by);
 if(view==='E'){capsule(c,22,26,25,29,'pele',{shift:-1,r:0});capsule(c,18,29,29,42,'roupa',{r:3});capsule(c,16,28,19,32,'roupa',{shift:-1,r:2});capsule(c,19,41,29,47,'calca',{r:1,tilt:.2});for(const y of [32,33,34])c.set(28,y,'tenis:2');}
 else{capsule(c,22,26,26,29,'pele',{shift:-1,r:0});capsule(c,16,29,32,42,'roupa',{r:3});capsule(c,17,41,31,47,'calca',{r:1,tilt:.2});for(let y=46;y<=47;y++)for(let x=23;x<=25;x++)c.del(x,y);
  if(view==='S'){for(let y=33;y<=42;y++)c.set(24,y,'roupa:0');for(const x of [21,27])for(const y of [31,32,33])c.set(x,y,'tenis:2');}
  else{capsule(c,19,29,29,34,'roupa',{shift:-1,r:3});for(let x=21;x<=27;x++)c.set(x,30,'roupa:0');}}
 c.at(0,0);}
function eyes(h,expr){for(const ex of [19,27]){const L=ex===19;
 if(expr==='feliz'){for(const [x,y] of [[ex,17],[ex+1,17],[ex-1,18],[ex+2,18]])h.set(x,y,'tinta:0');}
 else if(expr==='dor'){for(const [x,y] of L?[[ex,17],[ex+1,18],[ex,19]]:[[ex+1,17],[ex,18],[ex+1,19]])h.set(x,y,'tinta:0');}
 else if(expr==='fechado'){h.set(ex,19,'tinta:0');h.set(ex+1,19,'tinta:0');h.set(L?ex-1:ex+2,18,'tinta:0');}
 else{for(const y of [17,18,19,20])h.set(ex,y,'tinta:0');h.set(ex+1,17,'olho:0');h.set(ex+1,18,'cabelo:2');h.set(ex+1,19,'cabelo:1');h.set(ex+1,20,'tinta:0');h.set(ex,16,'tinta:0');h.set(ex+1,16,'tinta:0');}}
 if(expr==='feliz'){for(const [x,y] of [[22,24],[23,25],[24,25],[25,24]])h.set(x,y,'tinta:0');h.set(23,24,'roupa:1');h.set(24,24,'roupa:1');for(const x of [17,18,30,31])h.set(x,22,'roupa:2');}
 else if(expr==='dor'){for(const [x,y] of [[22,25],[23,24],[24,25],[25,24]])h.set(x,y,'tinta:0');}
 else if(expr==='fechado'){h.set(23,25,'pele:0');h.set(24,25,'pele:0');for(const [x,y] of [[33,11],[33,12],[32,12],[33,13]])h.set(x,y,'agua:1');h.set(33,11,'agua:2');}
 else{for(const x of [17,30])h.set(x,22,'roupa:3');h.set(23,25,'pele:0');h.set(24,25,'pele:0');}}
function head(h,hair,view,[bx,by],expr){h.at(bx,by);hair.at(bx,by);
 if(view==='E'){ellipse(h,24,18,9,10,'pele',{soft:.7});for(const [x,y] of [[21,18],[21,19],[22,19],[21,20],[22,20]])h.set(x,y,'pele:0');
  for(const y of [17,18,19,20])h.set(28,y,'tinta:0');h.set(29,17,'olho:0');h.set(29,18,'cabelo:2');h.set(29,19,'cabelo:1');h.set(29,20,'tinta:0');h.set(27,16,'tinta:0');h.set(28,16,'tinta:0');h.set(31,22,'roupa:2');h.set(30,22,'roupa:3');
  if(expr==='esforco'){h.set(31,24,'tinta:0');h.set(32,24,'tinta:0');h.set(31,25,'roupa:1');h.set(32,25,'tinta:0');}else{h.set(31,25,'pele:0');h.set(32,25,'pele:0');}h.set(34,20,'pele:2');
  ellipse(hair,23.5,16.5,10.5,10.5,'cabelo',{keep:(x,y)=>y<=12||(x<=20&&y<=25)||(x<=22&&y<=15)});
  for(const [x,y] of [[12,12],[11,13],[12,13],[12,14],[13,14],[11,17],[12,17],[12,18],[13,18],[12,21],[13,21],[13,22],[14,22],[13,25],[14,25],[14,26],[18,5],[19,5],[19,6],[23,4],[24,4],[23,5],[24,5],[28,5],[28,6],[29,6]])hair.set(x,y,'cabelo:1');
  for(const [x,y] of [[25,13],[26,13],[27,13],[28,13],[29,13],[30,13],[31,13],[32,13],[27,14],[28,14],[30,14],[31,14],[32,14],[31,15],[32,15],[33,14],[33,13]])hair.set(x,y,y>13?'cabelo:1':'cabelo:2');
  for(const [x,y] of [[19,9],[20,9],[21,8],[22,8],[18,10]])hair.set(x,y,'cabelo:3');}
 else{ellipse(h,24,18,10,10,'pele',{soft:.7});
  if(view==='S'){eyes(h,expr);ellipse(hair,24,16.5,11,10.5,'cabelo',{keep:(x,y)=>y<=12||((x<=15||x>=33)&&y<=23)});for(let x=15;x<=33;x++){hair.set(x,13,'cabelo:2');if(x%3!==0)hair.set(x,14,'cabelo:1');if(x%3===1)hair.set(x,15,'cabelo:1');}}
  else{for(const [x,y] of [[13,19],[13,20],[35,19],[35,20]])h.set(x,y,'pele:1');ellipse(hair,24,16.5,11,10.5,'cabelo',{keep:(x,y)=>y<=24});for(const [x,y] of [[18,25],[19,26],[23,26],[24,27],[25,26],[29,26],[30,25]])hair.set(x,y,'cabelo:0');}
  for(const [x,y] of [[17,5],[18,5],[18,6],[24,4],[25,4],[24,5],[30,5],[31,6],[30,6],[12,14],[13,14],[12,17],[13,17],[36,14],[35,14],[36,17],[35,17],[13,22],[14,22],[35,22],[34,22]])hair.set(x,y,'cabelo:1');
  for(const [x,y] of view==='S'?[[18,8],[19,8],[20,7],[21,7],[17,9]]:[[18,8],[19,8],[20,7],[21,7],[17,9],[20,12],[21,11],[22,11]])hair.set(x,y,'cabelo:3');}
 h.at(0,0);hair.at(0,0);}
const add=([x,y],[dx,dy])=>[x+dx,y+dy];
const JOINTS={S:{sb:[15,31],sf:[33,31],hb:[21,45],hf:[27,45]},N:{sb:[15,31],sf:[33,31],hb:[21,45],hf:[27,45]},E:{sb:[23,31],sf:[24,31],hb:[23,45],hf:[25,45]}};
// One frame: body offset b, extra head offset, arms [elbow,hand], legs [knee,foot|null] (hip may be overridden).
function frame(spec){
 const {view,b=[0,0],hd=[0,0],expr='normal'}=spec,J=JOINTS[view],L=Object.fromEntries(LAYERS.map(n=>[n,canvas()]));
 const armLayer=spec.armsOver?L['Cabelo']:null;
 torso(L['Tronco'],view,b);head(L['Cabeça'],L['Cabelo'],view,add(b,hd),expr);
 if(spec.legB)leg(L['Perna de trás'],spec.legB[2]||add(J.hb,b),spec.legB[0],spec.legB[1],view,view==='E'?-1:0);
 if(spec.legF)leg(L['Perna da frente'],spec.legF[2]||add(J.hf,b),spec.legF[0],spec.legF[1],view);
 // Kneeling: the soles show behind the knees, pointing back and out.
 if(spec.feetBehind)for(const [x0,dir] of [[14,-1],[30,1]])for(let i=0;i<4;i++){L['Perna de trás'].set(x0+i,59,i===(dir<0?0:3)?'tenis:0':'tenis:1');L['Perna de trás'].set(x0+i,60,'roupa:1');}
 const armB=canvas(),armF=canvas();if(spec.armB)arm(armB,add(J.sb,b),...spec.armB,view==='E'?-1:0);if(spec.armF)arm(armF,add(J.sf,b),...spec.armF,view==='S'?-1:0);
 for(const [src,dst] of [[armB,armLayer||L['Braço de trás']],[armF,armLayer||L['Braço da frente']]])for(const [k,v] of src.m)dst.m.set(k,v);
 if(spec.water!==undefined)for(const c of Object.values(L))for(const k of [...c.m.keys()])if(+k.split(',')[1]>=spec.water)c.m.delete(k);
 const pose={topo:add([24,8],add(b,hd)),queixo:add([24,28],add(b,hd)),ombroTras:add(J.sb,b),ombroFrente:add(J.sf,b),quadril:add([24,45],b)};
 if(spec.armB)pose.maoTras=spec.armB[1];if(spec.armF)pose.maoFrente=spec.armF[1];if(spec.legB)pose.peTras=spec.legB[1]||spec.legB[0];if(spec.legF)pose.peFrente=spec.legF[1]||spec.legF[0];
 for(const k of Object.keys(pose))pose[k]=[Math.max(0,Math.min(W-1,pose[k][0])),Math.max(0,Math.min(H-1,pose[k][1]))];
 return {layers:L,pose};
}
const S='S',N='N',E='E';
export const SEQUENCES={
 // Back view on a vertical ladder; rails at x≈16 and x≈32, the hands grip them.
 'climb-N':{loop:true,frames:[
  {d:160,view:N,b:[0,0],armsOver:true,armB:[[12,22],[16,13]],armF:[[37,28],[32,23]],legB:[[20,49],[21,55]],legF:[[27,52],[27,60]]},
  {d:120,view:N,b:[0,-1],armsOver:true,armB:[[11,25],[16,18]],armF:[[37,27],[32,20]],legB:[[20,51],[21,58]],legF:[[28,51],[27,58]]},
  {d:160,view:N,b:[0,0],armsOver:true,armB:[[11,28],[16,23]],armF:[[36,22],[32,13]],legB:[[21,52],[21,60]],legF:[[28,49],[27,55]]},
  {d:120,view:N,b:[0,-1],armsOver:true,armB:[[11,27],[16,20]],armF:[[37,25],[32,18]],legB:[[20,51],[21,58]],legF:[[28,51],[27,58]]}]},
 'victory-S':{loop:false,frames:[
  {d:120,view:S,b:[0,3],armB:[[13,37],[15,43]],armF:[[35,37],[33,43]],legB:[[19,53],[21,60],[21,48]],legF:[[29,53],[27,60],[27,48]]},
  {d:100,view:S,b:[0,-2],expr:'feliz',armB:[[12,32],[10,36]],armF:[[35,22],[35,15]],legB:[[20,49],[21,57]],legF:[[28,49],[27,57]]},
  {d:140,view:S,b:[0,-3],expr:'feliz',armB:[[11,26],[9,18]],armF:[[37,26],[39,18]],legB:[[19,48],[20,55]],legF:[[29,48],[28,55]]},
  {d:700,view:S,b:[0,0],expr:'feliz',armB:[[11,36],[17,41]],armF:[[36,23],[36,16]],legB:[[20,52],[20,60]],legF:[[28,52],[28,60]]}]},
 'defeat-S':{loop:false,frames:[
  {d:120,view:S,b:[0,-1],hd:[0,-1],expr:'dor',armB:[[11,33],[8,37]],armF:[[37,33],[40,37]],legB:[[21,52],[21,60]],legF:[[27,52],[27,60]]},
  {d:140,view:S,b:[0,3],hd:[0,1],expr:'fechado',armB:[[14,38],[15,45]],armF:[[34,38],[33,45]],legB:[[23,52],[20,60],[21,48]],legF:[[25,52],[28,60],[27,48]]},
  {d:200,view:S,b:[0,9],hd:[0,2],expr:'fechado',armB:[[13,46],[14,54]],armF:[[35,46],[34,54]],legB:[[20,59],null,[21,54]],legF:[[28,59],null,[27,54]],feetBehind:true},
  {d:900,view:S,b:[0,10],hd:[0,3],expr:'fechado',armB:[[14,48],[18,56]],armF:[[34,48],[30,56]],legB:[[20,60],null,[21,55]],legF:[[28,60],null,[27,55]],feetBehind:true}]},
 // In water the body is cut at the waterline; ripples are added after the outline.
 'swim-S':{loop:true,frames:[
  {d:150,view:S,b:[0,10],water:43,ripple:13,armB:[[16,44],[20,42]],armF:[[32,44],[28,42]]},
  {d:150,view:S,b:[0,9],water:43,ripple:15,armB:[[13,43],[11,41]],armF:[[35,43],[37,41]]},
  {d:150,view:S,b:[0,10],water:43,ripple:17,armB:[[12,41],[13,39]],armF:[[36,41],[35,39]]},
  {d:150,view:S,b:[0,11],water:43,ripple:14,armB:[[15,43],[17,41]],armF:[[33,43],[31,41]]}]},
 'swim-E':{loop:true,frames:[
  {d:150,view:E,b:[0,10],water:43,ripple:12,expr:'esforco',armF:[[31,41],[36,42]],armB:[[19,35],[23,31]]},
  {d:150,view:E,b:[0,9],water:43,ripple:14,armF:[[28,45],[25,47]],armB:[[27,33],[32,35]]},
  {d:150,view:E,b:[0,10],water:43,ripple:12,expr:'esforco',armB:[[31,41],[36,42]],armF:[[20,35],[24,31]]},
  {d:150,view:E,b:[0,11],water:43,ripple:14,armB:[[28,45],[25,47]],armF:[[27,33],[32,35]]}]}};
function ripple(spec,body){const out=[],cx=24+(spec.view==='E'?2:0),cy=spec.water,rx=spec.ripple,ry=2;
 for(let a=0;a<360;a+=4){const x=Math.round(cx+Math.cos(a*Math.PI/180)*rx),y=Math.round(cy+Math.sin(a*Math.PI/180)*ry);if(body.has(x+','+y))continue;if((a/4)%5===4)continue;out.push([x,y,y>cy?'agua:2':'agua:1']);}
 for(let x=cx-rx+3;x<=cx+rx-3;x+=2)if(!body.has(x+','+cy))out.push([x,cy,'agua:2']);return out;}
export function build(){
 const blank=()=>Array(W*H).fill(0),specs=Object.entries(SEQUENCES).flatMap(([name,s])=>s.frames.map((f,i)=>({...f,name:`${name}-${i+1}`})));
 const p=validateProject({kind:'pixelgen',version:2,name:'Modelo de referência — ações',width:W,height:H,cols:1,rows:1,palette:[[0,0,0,0]],layers:LAYERS.map(name=>({name})),frames:[{name:specs[0].name,indices:blank(),cels:LAYERS.map(blank)}]});
 const list=[...Object.entries(RAMPS).map(([name,colors])=>({op:'ramp',name,colors}))],built=specs.map(frame);
 specs.forEach((s,i)=>{if(i)list.push({op:'frame',add:s.name,duration:s.d});else list.push({op:'frame',target:0,duration:s.d});
  list.push(...ops(built[i].layers).map(o=>({...o,frame:i})),{op:'pose',frame:i,points:built[i].pose});});
 list.push({op:'outline',color:'tinta:0'});
 specs.forEach((s,i)=>{if(s.water===undefined)return;const body=new Set(Object.values(built[i].layers).flatMap(c=>[...c.m.keys()]));
  list.push({op:'erase',frame:i,layer:'Contorno',rect:{x:0,y:s.water,w:W,h:H-s.water}});const r=ripple(s,body),by=new Map();for(const [x,y,c] of r){if(!by.has(c))by.set(c,[]);by.get(c).push([x,y]);}
  for(const [color,points] of by)list.push({op:'pixels',frame:i,layer:'Contorno',color,points});});
 apply(p,list);let at=0;p.sequences=Object.entries(SEQUENCES).map(([name,s])=>{const q={name,start:at,end:at+s.frames.length-1,loop:s.loop,direction:'forward'};at+=s.frames.length;return q;});p.sheet=validateSheet({nome:'Modelo',cabecas:2.8,altura:60,base:61,cores:24,referencia:'victory-S-4',notas:'Ações do gabarito: escada, vitória, derrota e nado.'},p);return p;
}
if(process.argv[1]&&import.meta.url.endsWith(process.argv[1].split('/').pop())){const out=process.argv[2]||'modelo-acoes.pixelgen.json';fs.writeFileSync(out,JSON.stringify(serialize(build())));console.log(out);}
