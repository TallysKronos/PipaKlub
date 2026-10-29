// Prova das regras contra o mapa chapado (art/overworld/REGIOES-E-PARTES.md, seção 6):
// Bosque dos Ventos · parte A. Platôs de nível 1 com rampas longas, mesa de nível 2 coberta de
// mata, trilha orgânica que passa entre os blocos, mata em massa na moldura e no alto dos
// platôs, bosques de 3 a 7 copas, mato de encontro fora do caminho e itens espalhados.
// Uso: node tools/mapa-studio/desenhar-kronasta-bosque.mjs   (grava a planta e compila para o Godot)
import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {parseTiled,audit,verdict,canStep,blockedByPiece} from './model.mjs';
import {compile} from '../import-overworld.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
const tileset=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj','utf8'));
const GID=Object.fromEntries(tileset.tiles.filter(t=>typeof t.properties?.[0]?.value==='string'&&t.id<16).map(t=>[t.properties[0].value,t.id+1]));
const LEVEL={1:17,2:18},RAMP={'u+':21,'u-':22,'v+':23,'v-':24};

const hash=(x,y,s)=>{let h=Math.imul(x*374761393+y*668265263+s*982451653,1274126177);h^=h>>>13;return ((Math.imul(h,1103515245)>>>0)%10000)/10000;};
const smooth=t=>t*t*(3-2*t);
function noise(x,y,s=1,scale=3){const fx=x/scale,fy=y/scale,x0=Math.floor(fx),y0=Math.floor(fy),tx=smooth(fx-x0),ty=smooth(fy-y0);
 const a=hash(x0,y0,s),b=hash(x0+1,y0,s),c=hash(x0,y0+1,s),d=hash(x0+1,y0+1,s);return (a+(b-a)*tx)+((c+(d-c)*tx)-(a+(b-a)*tx))*ty;}
const segDist=(p,a,b)=>{const dx=b[0]-a[0],dy=b[1]-a[1],t=Math.max(0,Math.min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/(dx*dx+dy*dy)));return Math.hypot(p[0]-a[0]-t*dx,p[1]-a[1]-t*dy);};
function curve(points,steps=10){const out=[];const P=[points[0],...points,points.at(-1)];
 for(let i=1;i<P.length-2;i++)for(let s=0;s<steps;s++){const t=s/steps,t2=t*t,t3=t2*t,[p0,p1,p2,p3]=[P[i-1],P[i],P[i+1],P[i+2]];
  out.push([0,1].map(k=>.5*((2*p1[k])+(-p0[k]+p2[k])*t+(2*p0[k]-5*p1[k]+4*p2[k]-p3[k])*t2+(-p0[k]+3*p1[k]-3*p2[k]+p3[k])*t3)));}
 out.push(points.at(-1));return out;}
const pathDist=(p,pts)=>{let d=Infinity;for(let i=0;i<pts.length-1;i++)d=Math.min(d,segDist(p,pts[i],pts[i+1]));return d;};
const blob=(p,b,s)=>{const e=b.p??2;return Math.pow(Math.abs((p[0]-b.c[0])/b.r[0])**e+Math.abs((p[1]-b.c[1])/b.r[1])**e,1/e)+(noise(p[0],p[1],s,2.4)-.5)*(b.rough??.35);};
// Platôs e mesa em blocos de 2×2 células e com contorno quase retangular (expoente 3): o paredão
// corre ao longo dos eixos isométricos em trechos longos, como nos penhascos do Data Forest,
// em vez de serrilhar uma célula por degrau quando a borda é diagonal.
const BLOCK=2;

const W=52,H=44,S=211;
const mat=new Array(W*H).fill('grama'),alt=new Array(W*H).fill(0),lvl=new Array(W*H).fill(0);
const I=(u,v)=>v*W+u,inside=(u,v)=>u>=0&&v>=0&&u<W&&v<H;
// Trilha principal: da entrada (frente, embaixo) até a saída para a parte B (fundo, em cima), passando
// entre os platôs. Ramais sobem aos platôs por rampas longas.
const main=curve([[27,43.6],[26.5,38],[23,33.5],[22.6,28],[26.5,23.5],[26,18],[22.5,13],[23,7.5],[24.5,0.4]]);
// Toda rampa sobe para o fundo (u- ou v-). Com degrau de 64 px e rampa de 2 células, a subida em
// u+ ou v+ fica paralela à linha de visão da câmera isométrica e some (vira uma linha). Por isso os
// platôs do leste e do sudeste recebem o ramal pela face da frente (sul), subindo em v-.
const spurDefs=[{pts:[[24.6,25.6],[29,27.8],[34,27.9],[35.6,26.6]],dir:'v-'},{pts:[[22.8,31.2],[18.5,31.2],[16.4,30.6]],dir:'u-'},{pts:[[23.4,10.2],[19,9.6],[16.2,9.2]],dir:'u-'},{pts:[[25.6,37.2],[31,38.2],[37,38],[38.6,36.8]],dir:'v-'}];
const spurs=spurDefs.map(d=>curve(d.pts));
const plateaus=[{c:[38.5,15],r:[13,10],rough:.3,p:3},{c:[10.5,30.5],r:[8.6,7.6],rough:.3,p:3},{c:[9.5,10.5],r:[8,6.6],rough:.3,p:3},{c:[40,31.5],r:[8.5,4.5],rough:.3,p:3}];
const mesa={c:[41,12.5],r:[5,3.6],rough:.25,p:3};
// Mata: moldura irregular de 4 a 6 células, copas sobre os platôs (ref. Data Forest) e bosques soltos.
const groves=[{c:[42,11.5],r:[6.6,4.6]},{c:[6.5,34.5],r:[4.2,3.6]},{c:[7,8],r:[4,3]},{c:[44,37],r:[5,3]},{c:[16,20],r:[2.2,1.6]},{c:[33,30.5],r:[2.1,1.5]},{c:[30,6],r:[2.4,1.6]},{c:[17,39],r:[2.2,1.5]}];
const mato=[{c:[31.5,27],r:[3.2,1.8],rough:.7},{c:[15.5,24.5],r:[2.6,2],rough:.7},{c:[29.5,11.5],r:[2.6,2],rough:.6}];
const onPath=(u,v)=>{const p=[u+.5,v+.5];return pathDist(p,main)<1.25+(noise(u,v,S+7,2.2)-.5)*.7||spurs.some(sp=>pathDist(p,sp)<.95+(noise(u,v,S+9,2)-.5)*.5);};
const blockLevel=new Map();
const levelOf=(u,v)=>{const bu=Math.floor(u/BLOCK),bv=Math.floor(v/BLOCK),k=bu+','+bv;
 if(!blockLevel.has(k)){const c=[bu*BLOCK+BLOCK/2,bv*BLOCK+BLOCK/2];let cut=false;
  for(let dv=0;dv<BLOCK;dv++)for(let du=0;du<BLOCK;du++)if(onPath(bu*BLOCK+du,bv*BLOCK+dv))cut=true;
  let l=0;if(!cut&&plateaus.some(b=>blob(c,b,S+b.c[0])<1))l=1;if(l===1&&blob(c,mesa,S+3)<1)l=2;blockLevel.set(k,l);}
 return blockLevel.get(k);};
for(let v=0;v<H;v++)for(let u=0;u<W;u++){const p=[u+.5,v+.5],i=I(u,v);
 const onMain=pathDist(p,main)<1.25+(noise(u,v,S+7,2.2)-.5)*.7,onSpur=spurs.some(sp=>pathDist(p,sp)<.95+(noise(u,v,S+9,2)-.5)*.5);
 const edge=Math.min(u+.5,v+.5,W-u-.5,H-v-.5),border=4.2+noise(u,v,S,3.2)*2.6;
 lvl[i]=levelOf(u,v);
 if(edge<border&&!onMain)mat[i]='bosque';
 if(groves.some(b=>blob(p,b,S+b.c[1])<1)&&!onMain&&!onSpur)mat[i]='bosque';
 if(mato.some(b=>blob(p,b,S+b.c[0]*3)<1)&&!onMain&&!onSpur&&mat[i]==='grama'&&lvl[i]===0)mat[i]='mato';
 if(onMain||onSpur)mat[i]='terra';
 if(onMain||onSpur)lvl[i]=0;}
// Rampas: no fim de cada ramal, a célula de terra que encosta no platô vira rampa subindo para ele.
const ramps=[];
spurs.forEach((sp,n)=>{const end=sp.at(-1),dir=spurDefs[n].dir,[du,dv]={'u+':[1,0],'u-':[-1,0],'v+':[0,1],'v-':[0,-1]}[dir];
 let [u,v]=[Math.floor(end[0]),Math.floor(end[1])];
 for(let n=0;n<12&&inside(u,v)&&lvl[I(u+du,v+dv)]!==1;n++){u+=du;v+=dv;mat[I(u,v)]='terra';lvl[I(u,v)]=0;}
 // Rampa larga de 2 células, com o pé no chão de terra e a chegada no platô.
 const side=du?[0,1]:[1,0];
 for(const k of [0,1]){const ru=u+side[0]*k,rv=v+side[1]*k;if(!inside(ru,rv))continue;
  lvl[I(ru,rv)]=0;mat[I(ru,rv)]='terra';ramps.push([ru,rv,dir]);
  for(const ahead of [1,2]){const top=I(ru+du*ahead,rv+dv*ahead);lvl[top]=1;mat[top]='grama';}
  for(const back of [1,2,3]){const b=I(ru-du*back,rv-dv*back);lvl[b]=0;mat[b]='terra';}}});


// Sem degrau solto: célula de nível 2 precisa de vizinhos de nível 1 ou 2; platô de 1 célula vira chão.
for(let pass=0;pass<2;pass++)for(let v=0;v<H;v++)for(let u=0;u<W;u++){const i=I(u,v);if(!lvl[i])continue;
 const n=[[1,0],[-1,0],[0,1],[0,-1]].filter(([du,dv])=>inside(u+du,v+dv)&&lvl[I(u+du,v+dv)]>=lvl[i]).length;
 if(n<=1&&!ramps.some(r=>r[0]+(r[2]==='u+'?1:r[2]==='u-'?-1:0)===u&&r[1]+(r[2]==='v+'?1:r[2]==='v-'?-1:0)===v))lvl[i]=Math.max(0,lvl[i]-1);}
for(let i=0;i<W*H;i++)if(lvl[i]===2&&mat[i]!=='bosque')mat[i]='bosque';
for(let i=0;i<W*H;i++)alt[i]=lvl[i]?LEVEL[lvl[i]]:0;
for(const [u,v,d] of ramps)alt[I(u,v)]=RAMP[d];

// Bolsões de chão sem acesso (atrás de platô, entre copas) viram mata: nada de plataforma solta.
{const pre={type:'map',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,properties:[{name:'rampa_comprimento',type:'int',value:2}],tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'}],
  layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(m=>GID[m])},{name:'altura',type:'tilelayer',width:W,height:H,data:alt},{name:'pecas',type:'objectgroup',objects:[]},{name:'eventos',type:'objectgroup',objects:[{id:1,name:'e',type:'entrada',x:27*32+16,y:41*32+16,properties:[]}]}]};
 const pm=parseTiled(pre,{'rascunho.tsj':tileset}),seen=new Set([41*W+27]),q=[[27,41]];
 while(q.length){const [u,v]=q.shift();for(const [du,dv] of [[1,0],[-1,0],[0,1],[0,-1]]){const k=(v+dv)*W+u+du;if(!seen.has(k)&&canStep(pm,{u,v},{u:u+du,v:v+dv},new Set())){seen.add(k);q.push([u+du,v+dv]);}}}
 for(let i=0;i<W*H;i++)if(!seen.has(i)&&!['bosque','agua'].includes(mat[i])){mat[i]='bosque';}}
// Peças: árvores em massa onde há mata (copas se sobrepõem, espaçamento de 1 célula com jitter),
// arbustos baixos na borda da frente para não esconder o caminho, pedras em grupos de 2 e 3.
let id=0;const prop=(name,value)=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value});
const obj=(type,name,u,v,props={})=>({id:++id,name,type,x:u*32+16,y:v*32+16,point:true,width:0,height:0,rotation:0,visible:true,properties:Object.entries(props).map(([k,x])=>prop(k,x))});
const walkCell=(u,v)=>inside(u,v)&&!['bosque','agua'].includes(mat[I(u,v)]);
const pieces=[],taken=new Set();
const put=(name,u,v,props)=>{if(taken.has(u+','+v))return;taken.add(u+','+v);pieces.push(obj('peca',name,u,v,props));};
for(let v=0;v<H;v++)for(let u=0;u<W;u++){if(mat[I(u,v)]!=='bosque')continue;
 // Copa alta na frente de chão andável esconderia o Kael: ali vai arbusto.
 let front=false;for(let k=1;k<=3;k++)for(const [x,y] of [[u-k,v],[u,v-k],[u-k,v-k]])if(walkCell(x,y)&&lvl[I(x,y)]>=lvl[I(u,v)])front=true;
 const r=hash(u,v,S+5);
 if(front){if(r<.55)put('Arbusto',u,v,{asset:'arbusto',variante:r<.27?'a':'b'});continue;}
 if(r<.9)put('Árvore',u,v,{asset:'arvore',variante:r<.07?'florida':r<.42?'a':r<.8?'b':'grande'});}
const rocks=[[20,36],[21,37],[29,24],[28,25],[29,25],[19,15],[20,14],[33,8],[25,29],[13,26],[14,27]];
rocks.forEach(([u,v],k)=>{if(walkCell(u,v)&&mat[I(u,v)]!=='terra')put('Pedra',u,v,{asset:'pedra',variante:String(k%3)});});
[[24,38,'amarela'],[25,39,'coral'],[19,29,'azul'],[20,30,'amarela'],[28,19,'coral'],[21,20,'azul'],[26,13,'amarela'],[20,6,'coral']]
 .forEach(([u,v,c])=>{if(walkCell(u,v)&&mat[I(u,v)]!=='terra')put('Flores',u,v,{asset:'flores',variante:c,bloqueia:false});});
put('Placa da trilha',29,40,{asset:'placa-mapa',pegada:'1x1'});

// Eventos: entrada, saídas (mapa de Kronasta e parte B), um NPC e itens com o tipo `item`.
const ev=[];const E=(type,name,u,v,props)=>ev.push(obj(type,name,u,v,props));
E('entrada','Chegada ao Bosque dos Ventos',27,41,{});
E('saida','Voltar ao mapa de Kronasta',27,43,{destino:'kronasta'});
E('saida','Seguir para o Bosque dos Ventos B',24,1,{destino:'kronasta-bosque-b'});
E('npc','Guarda-parque Dito',25,35,{fala:'Dito',texto:'Os platôs guardam mais do que vista. Repara nas rampas de terra.'});
// Item no alto do platô leste (escondido atrás das copas), outro no platô oeste, um na beira da
// trilha (visível) e um cintilando no alto do platô sudeste.
const items=[['Moedas esquecidas',22,3,'moedas',30,'visivel'],['Papel de seda',36,21,'papel-seda',2,'escondido'],['Vareta de bambu',13,30,'vareta-bambu',1,'escondido'],['Cola de reparo',24,24,'cola-reparo',1,'visivel'],['Linha encerada',42,32,'linha-encerada',1,'brilho'],['Página do caderno',12,10,'pista-caderno-heleana-1',1,'escondido']];
for(const [name,u,v,item,q,vis] of items)E('item',name,u,v,{item,quantidade:q,visibilidade:vis,trajetoria:item.startsWith('pista')?'2':'ambas'});

const raw={type:'map',version:'1.10',tiledversion:'1.10.2',orientation:'isometric',renderorder:'right-down',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,
 properties:Object.entries({nome:'Bosque dos Ventos · Trilha das Copas',regras:'overworld-1',bioma:'floresta',cena_jogo:'kronasta-bosque-a',regiao:'bosque-dos-ventos',parte:'A',trajetoria:'ambas',rampa_comprimento:2,origem:'desenhar-kronasta-bosque.mjs'}).map(([k,x])=>prop(k,x)),
 tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'}],nextlayerid:5,nextobjectid:id+1,
 layers:[{id:1,name:'chao',type:'tilelayer',width:W,height:H,x:0,y:0,opacity:1,visible:true,data:mat.map(m=>GID[m])},
  {id:2,name:'altura',type:'tilelayer',width:W,height:H,x:0,y:0,opacity:1,visible:true,data:alt},
  {id:3,name:'pecas',type:'objectgroup',draworder:'topdown',x:0,y:0,opacity:1,visible:true,objects:pieces},
  {id:4,name:'eventos',type:'objectgroup',draworder:'topdown',x:0,y:0,opacity:1,visible:true,objects:ev}]};
const m=parseTiled(raw,{'rascunho.tsj':tileset}),issues=audit(m);
for(const x of issues.filter(x=>x.level!=='ok'))console.log(x.level.toUpperCase(),x.title||'',x.text||x.message||JSON.stringify(x));
if(verdict(issues)==='fail')process.exit(1);
// Tudo alcançável a partir da entrada.
const solid=blockedByPiece(m),seen=new Set([m.spawn.v*W+m.spawn.u]),queue=[[m.spawn.u,m.spawn.v]];
while(queue.length){const [u,v]=queue.shift();for(const [du,dv] of [[1,0],[-1,0],[0,1],[0,-1]]){const k=(v+dv)*W+u+du;if(!seen.has(k)&&canStep(m,{u,v},{u:u+du,v:v+dv},solid)){seen.add(k);queue.push([u+du,v+dv]);}}}
for(const e of m.events){if(![[0,0],[1,0],[-1,0],[0,1],[0,-1]].some(([du,dv])=>seen.has((e.v+dv)*W+e.u+du))){console.error('FORA DE ALCANCE',e.name,e.u,e.v);process.exit(1);}}
const walkableCount=m.cells.filter((c,i)=>!['bosque','agua','rocha'].includes(c.material)).length,raised=m.cells.filter((c,i)=>c.level>0&&!['bosque'].includes(c.material)).length;
const plat=m.cells.filter(c=>c.level>0).length/m.cells.length;
fs.writeFileSync(root+'art/overworld/mapas/kronasta-bosque-a.tmj',JSON.stringify(raw,null,1)+'\n');
const out=compile(raw,'kronasta-bosque-a');fs.writeFileSync(root+'godot/assets/overworld/maps/kronasta-bosque-a.json',JSON.stringify(out));
const indexFile=root+'godot/assets/overworld/maps/index.json',index=JSON.parse(fs.readFileSync(indexFile,'utf8'));
index.areas=index.areas.filter(a=>a.id!=='kronasta-bosque-a');index.areas.push({id:'kronasta-bosque-a',name:'Bosque dos Ventos · Trilha das Copas',scene:'kronasta-bosque-a',biome:'floresta'});
fs.writeFileSync(indexFile,JSON.stringify(index,null,2)+'\n');
console.log(`kronasta-bosque-a: ${verdict(issues).toUpperCase()} · ${seen.size} células alcançáveis · ${pieces.filter(p=>p.name==='Árvore').length} árvores · platô ${Math.round(plat*100)}% · ${ramps.length} células de rampa · ${items.length} itens`);
// Mapa em texto: . grama, t terra, m mato, # mata, : platô, % mata no platô, 2 mesa, ^ rampa.
console.log(mat.map((x,i)=>{const c={grama:'.',terra:'t',mato:'m',bosque:'#'}[x]||'?';const a=alt[i];return (a>=21?'^':lvl[i]===2?'2':lvl[i]===1?(x==='bosque'?'%':x==='terra'?'T':x==='mato'?'M':':'):c)+((i+1)%W?'':'\n');}).join(''));
