// Desenha as plantas do Parque dos Ventos (Jardim das Pipas e Clareira do Papel) por formas:
// borda de mata irregular, praça, trilha curva, manchas de mato. Substitui o traçado em
// retângulos herdado do jogo antigo. Eventos e saídas mantêm nomes, destinos e ações.
// Uso: node tools/mapa-studio/desenhar-parque.mjs   (sobrescreve os dois .tmj e confere a planta)
import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {parseTiled,audit,verdict,walkable,canStep,blockedByPiece} from './model.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
const tileset=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj','utf8'));
const GID=Object.fromEntries(tileset.tiles.filter(t=>typeof t.properties?.[0]?.value==='string'&&t.id<16).map(t=>[t.properties[0].value,t.id+1]));

// Ruído suave determinístico, para as bordas não seguirem a grade.
const hash=(x,y,s)=>{let h=Math.imul(x*374761393+y*668265263+s*982451653,1274126177);h^=h>>>13;return ((Math.imul(h,1103515245)>>>0)%10000)/10000;};
const smooth=t=>t*t*(3-2*t);
function noise(x,y,s=1,scale=3){const fx=x/scale,fy=y/scale,x0=Math.floor(fx),y0=Math.floor(fy),tx=smooth(fx-x0),ty=smooth(fy-y0);
 const a=hash(x0,y0,s),b=hash(x0+1,y0,s),c=hash(x0,y0+1,s),d=hash(x0+1,y0+1,s);return (a+(b-a)*tx)+((c+(d-c)*tx)-(a+(b-a)*tx))*ty;}
const segDist=(p,a,b)=>{const dx=b[0]-a[0],dy=b[1]-a[1],t=Math.max(0,Math.min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/(dx*dx+dy*dy)));return Math.hypot(p[0]-a[0]-t*dx,p[1]-a[1]-t*dy);};
// Curva suave (Catmull-Rom) amostrada, para trilhas sem quinas retas.
function curve(points,steps=8){const out=[];const P=[points[0],...points,points.at(-1)];
 for(let i=1;i<P.length-2;i++)for(let s=0;s<steps;s++){const t=s/steps,t2=t*t,t3=t2*t,[p0,p1,p2,p3]=[P[i-1],P[i],P[i+1],P[i+2]];
  out.push([0,1].map(k=>.5*((2*p1[k])+(-p0[k]+p2[k])*t+(2*p0[k]-5*p1[k]+4*p2[k]-p3[k])*t2+(-p0[k]+3*p1[k]-3*p2[k]+p3[k])*t3)));}
 out.push(points.at(-1));return out;}
const pathDist=(p,pts)=>{let d=Infinity;for(let i=0;i<pts.length-1;i++)d=Math.min(d,segDist(p,pts[i],pts[i+1]));return d;};

function paint(spec){
 const {w,h,seed}=spec,mat=new Array(w*h).fill('grama');
 const trails=spec.trails.map(t=>({...t,pts:curve(t.points)}));
 for(let v=0;v<h;v++)for(let u=0;u<w;u++){const p=[u+.5,v+.5],i=v*w+u;
  const edge=Math.min(u+.5,v+.5,w-u-.5,h-v-.5),border=spec.border+noise(u,v,seed,2.6)*spec.borderNoise;
  const onTrail=trails.some(t=>pathDist(p,t.pts)<t.width+(noise(u,v,seed+7,2)-.5)*.5);
  if(edge<border&&!onTrail)mat[i]='bosque';
  for(const b of spec.blobs||[]){const dx=(p[0]-b.c[0])/b.r[0],dy=(p[1]-b.c[1])/b.r[1],r=Math.hypot(dx,dy)+(noise(u,v,seed+b.c[0],2.2)-.5)*b.rough;if(r<1&&mat[i]!=='bosque')mat[i]=b.mat;}
  if(onTrail&&mat[i]!=='piso')mat[i]='terra';
  for(const b of spec.plazas||[]){const dx=(p[0]-b.c[0])/b.r[0],dy=(p[1]-b.c[1])/b.r[1];if(Math.hypot(dx,dy)+(noise(u,v,seed+3,1.6)-.5)*.25<1)mat[i]='piso';}
 }
 for(const [u,v,m] of spec.force||[])mat[v*w+u]=m;
 return mat;
}
const ascii=(mat,w,alt)=>mat.map((m,i)=>{const c={grama:'.',terra:'t',mato:'m',piso:'p',bosque:'#',agua:'~',ponte:'='}[m]||'?';return (alt&&alt[i]===24?'^':alt&&alt[i]===17?c.toUpperCase():c)+((i+1)%w?'':'\n');}).join('');

function build(spec){
 const {w,h}=spec,grid=spec.grid?spec.grid():{mat:paint(spec),alt:null},mat=grid.mat;let id=0;
 const prop=(name,value)=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value});
 const obj=(type,name,u,v,props={})=>({id:++id,name,type,x:u*32+16,y:v*32+16,point:true,width:0,height:0,rotation:0,visible:true,properties:Object.entries(props).map(([k,x])=>prop(k,x))});
 // Árvores na mata: só nas células de bosque perto do que é andável, com espaçamento.
 const pieces=[...spec.pieces.map(p=>obj('peca',p.name,p.u,p.v,p.props))];
 const walkCell=(u,v)=>u>=0&&v>=0&&u<w&&v<h&&!['bosque','agua'].includes(mat[v*w+u]);
 const taken=new Set(spec.pieces.map(p=>`${p.u},${p.v}`));
 const trees=[];
 for(let v=0;v<h;v++)for(let u=0;u<w;u++){if(mat[v*w+u]!=='bosque')continue;
  let near=false;for(let dv=-2;dv<=2;dv++)for(let du=-2;du<=2;du++)if(walkCell(u+du,v+dv))near=true;
  if(!near||hash(u,v,spec.seed+11)>spec.treeDensity)continue;
  // Copa alta cobre o que está acima dela na tela (u+v menor, mesma coluna): na borda da frente só arbusto.
  let hides=false;for(let y=v-5;y<=v;y++)for(let x=u-5;x<=u;x++){const d=(u+v)-(x+y);if(d>=1&&d<=4&&Math.abs((x-y)-(u-v))<=2&&walkCell(x,y))hides=true;}
  if(hides)continue;
  if(trees.some(([a,b])=>Math.abs(a-u)+Math.abs(b-v)<3)||taken.has(`${u},${v}`))continue;
  trees.push([u,v]);const r=hash(u,v,spec.seed+5);
  const asset=spec.trees?spec.trees(r,u,v):{asset:'arvore',variante:r<.12&&spec.flowering?'florida':r<.56?'a':'b'};
  pieces.push(obj('peca',asset.asset==='buriti'?'Buriti':'Árvore',u,v,asset));}
 for(const d of spec.dress?spec.dress(mat,walkCell,taken,trees):[])pieces.push(obj('peca',d.name,d.u,d.v,d.props));
 const events=spec.events.map(e=>obj(e.type,e.name,e.u,e.v,e.props||{}));
 const raw={type:'map',version:'1.10',tiledversion:'1.10.2',orientation:'isometric',renderorder:'right-down',width:w,height:h,tilewidth:64,tileheight:32,infinite:false,
  properties:Object.entries(spec.meta).map(([k,x])=>prop(k,x)),tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'}],nextlayerid:5,nextobjectid:id+1,
  layers:[{id:1,name:'chao',type:'tilelayer',width:w,height:h,x:0,y:0,opacity:1,visible:true,data:mat.map(m=>GID[m])},
   {id:2,name:'altura',type:'tilelayer',width:w,height:h,x:0,y:0,opacity:1,visible:true,data:grid.alt||new Array(w*h).fill(0)},
   {id:3,name:'pecas',type:'objectgroup',draworder:'topdown',x:0,y:0,opacity:1,visible:true,objects:pieces},
   {id:4,name:'eventos',type:'objectgroup',draworder:'topdown',x:0,y:0,opacity:1,visible:true,objects:events}]};
 // Conferência: auditoria do Mapa Studio + todo evento alcançável a partir da entrada.
 const m=parseTiled(raw,{'rascunho.tsj':tileset}),issues=audit(m);
 if(verdict(issues)==='fail')throw Error(spec.id+': '+JSON.stringify(issues.filter(i=>i.level==='fail')));
 const solid=blockedByPiece(m),seen=new Set([m.spawn.v*w+m.spawn.u]),queue=[[m.spawn.u,m.spawn.v]];
 while(queue.length){const [u,v]=queue.shift();for(const [du,dv] of [[1,0],[-1,0],[0,1],[0,-1]]){const k=(v+dv)*w+u+du;if(!seen.has(k)&&canStep(m,{u,v},{u:u+du,v:v+dv},solid)){seen.add(k);queue.push([u+du,v+dv]);}}}
 for(const e of m.events){const ok=[[0,0],[1,0],[-1,0],[0,1],[0,-1]].some(([du,dv])=>seen.has((e.v+dv)*w+e.u+du));if(!ok)throw Error(`${spec.id}: ${e.name} fora de alcance`);}
 fs.writeFileSync(root+`art/overworld/mapas/${spec.id}.tmj`,JSON.stringify(raw,null,1)+'\n');
 console.log(`${spec.id}: ${verdict(issues).toUpperCase()} · ${seen.size} células andáveis · ${trees.length} árvores de borda`);console.log(ascii(mat,w,grid.alt));
}

const P=(name,u,v,props)=>({name,u,v,props});
// Jardim das Pipas: praça do coreto, canteiros floridos, pomar e um capim pequeno de encontro.
build({id:'jardim-das-pipas',w:24,h:16,seed:41,border:1.6,borderNoise:1.7,treeDensity:.55,flowering:true,
 meta:{nome:'Parque dos Ventos · Jardim das Pipas',regras:'overworld-1',bioma:'parque',cena_jogo:'park-trail',origem:'desenhar-parque.mjs'},
 trails:[{points:[[3.5,15.6],[4.2,12.5],[6.5,9.6],[9.5,8.2],[13,7.4],[16.5,6],[19.5,4.6],[23.6,4.2]],width:1.05},
  {points:[[9.5,8.2],[11.5,10.6],[15.5,11.6],[18.6,10.8]],width:.8}],
 plazas:[{c:[6.4,5.2],r:[3.6,2.9]}],
 blobs:[{c:[18.6,8.2],r:[2.6,1.7],mat:'mato',rough:.5},{c:[13.6,13.2],r:[2.4,1.4],mat:'mato',rough:.5}],
 force:[[3,15,'terra'],[23,4,'terra']],
 pieces:[P('Coreto',4,3,{asset:'coreto',pegada:'4x4',bloqueia:false}),
  P('coreto-post-1',4,3,{asset:'coreto-pilar',apenas_colisao:true}),P('coreto-post-2',7,3,{asset:'coreto-pilar',apenas_colisao:true}),
  P('coreto-post-3',7,6,{asset:'coreto-pilar',apenas_colisao:true}),P('coreto-post-4',4,6,{asset:'coreto-pilar',apenas_colisao:true}),
  P('Placa do parque',5,12,{asset:'placa-mapa',pegada:'2x1'}),
  P('Banco do coreto',9,4,{asset:'banco',pegada:'2x1'}),P('Banco do canteiro',15,9,{asset:'banco',pegada:'2x1'}),P('Banco do mirante',19,11,{asset:'banco',pegada:'2x1'}),
  P('Poste da entrada',3,11,{asset:'poste'}),P('Poste da praça',10,6,{asset:'poste'}),P('Poste do pomar',18,5,{asset:'poste'}),
  P('Lixeira',11,6,{asset:'lixeira'}),P('Vaso',3,4,{asset:'vaso'}),P('Vaso',9,3,{asset:'vaso',variante:'pneu'}),
  // Canteiros: flores em massa ao longo da trilha (não bloqueiam).
  ...[[7,10,'coral'],[8,11,'amarela'],[6,11,'azul'],[12,9,'coral'],[13,9,'amarela'],[11,9,'azul'],[16,10,'amarela'],[17,12,'coral'],[14,12,'azul'],[10,12,'coral']]
   .map(([u,v,c],i)=>P('Canteiro',u,v,{asset:'flores',variante:c,bloqueia:false})),
  // Pomar do Sr. Assis.
  P('Mangueira',13,4,{asset:'mangueira'}),P('Jabuticabeira',16,3,{asset:'jabuticabeira'}),P('Laranjeira',21,7,{asset:'laranjeira'})],
 events:[{type:'entrada',name:'Chegada ao parque',u:4,v:13},
  {type:'saida',name:'Voltar à Rua dos Ventos',u:3,v:15,props:{destino:'quintal'}},
  {type:'saida',name:'Seguir para a Clareira',u:23,v:4,props:{destino:'park-clearing'}},
  {type:'npc',name:'Sr. Assis · encontros selvagens',u:9,v:7,props:{acao:'wildGuide'}},
  {type:'interacao',name:'Descansar no largo',u:9,v:5,props:{acao:'wildRest'}},
  {type:'interacao',name:'Descansar no banco leste',u:19,v:10,props:{acao:'wildRest'}},
  {type:'interacao',name:'Mapa do Parque dos Ventos',u:5,v:11,props:{acao:'parkMap'}}]});

// Clareira do Papel: campo aberto de capim alto no centro, trilha em volta, pipas presas nas árvores.
build({id:'clareira-do-papel',w:24,h:16,seed:73,border:1.4,borderNoise:2.2,treeDensity:.7,flowering:false,
 meta:{nome:'Parque dos Ventos · Clareira do Papel',regras:'overworld-1',bioma:'parque',cena_jogo:'park-clearing',origem:'desenhar-parque.mjs'},
 trails:[{points:[[2.5,15.6],[3.6,12.5],[5.2,9.5],[7.8,7.4],[11.5,5.6],[15.5,4.6],[19.5,4.4],[23.6,3.6]],width:.95},
  {points:[[5.2,9.5],[8.5,12.4],[13,12.8],[17.5,11],[20,8],[19.5,4.4]],width:.75}],
 blobs:[{c:[11.2,9.6],r:[3.6,2.4],mat:'mato',rough:.9},{c:[14.6,8.4],r:[2.6,2.1],mat:'mato',rough:.9},{c:[9.6,11.4],r:[1.6,1.2],mat:'mato',rough:.6},{c:[18.6,13],r:[1.8,1.1],mat:'mato',rough:.4}],
 plazas:[{c:[4.6,12.2],r:[1.7,1.3]}],
 force:[[2,15,'terra'],[23,3,'terra']],
 pieces:[P('Placa: habitats',5,13,{asset:'placa-mapa',pegada:'2x1'}),P('Banco',20,6,{asset:'banco',pegada:'2x1'}),
  P('Pedra',9,6,{asset:'pedra',variante:'1'}),P('Pedra',16,7,{asset:'pedra',variante:'2'}),P('Biruta',14,4,{asset:'biruta'}),
  ...[[8,3],[18,2],[22,9],[3,8],[11,14]].map(([u,v])=>P('Pipa presa',u,v,{asset:'pipa-presa',bloqueia:false}))],
 events:[{type:'entrada',name:'Chegada ao parque',u:3,v:13},
  {type:'saida',name:'Voltar ao Jardim das Pipas',u:2,v:15,props:{destino:'park-trail'}},
  {type:'saida',name:'Além da cidade · Veredas do Encanamento',u:23,v:3,props:{destino:'park-veredas'}},
  {type:'interacao',name:'Placa: habitats e encontros',u:6,v:12,props:{acao:'wildGuide'}},
  {type:'interacao',name:'Descansar no banco leste',u:20,v:7,props:{acao:'wildRest'}},
  {type:'interacao',name:'Mapa do Parque dos Ventos',u:4,v:12,props:{acao:'parkMap'}}]});

// Veredas do Encanamento: planalto ao norte com borda irregular, três rampas longas cortadas no
// barranco, várzea com rio sinuoso e duas pontes, pátio de pedra do Lacertubo no alto, a leste.
const VW=50,VH=32,RAMPS=[10,26,37],RAMP_EDGE=10,BRIDGES=[[14,15],[22,23]];
function veredasGrid(){
 const mat=new Array(VW*VH).fill('bosque'),alt=new Array(VW*VH).fill(0),s=91;
 const edge=u=>{for(const r of RAMPS)if(u>=r-2&&u<=r+4)return RAMP_EDGE;
  const base=9.4+noise(u,0,s,4)*2.4;return Math.round(u>=41?Math.max(base,10+(u-41)*.75):base);};
 const riverC=v=>{for(const [a,b] of BRIDGES)if(v>=a-1&&v<=b+1)return 18;return 18+Math.sin((v-11)/4.2)*1.3;};
 const upper=[{c:[7.6,5.2],r:[5,2.3]},{c:[32,4.4],r:[8.6,2.6]}],patio={c:[45.4,6.4],r:[3.6,3.3]};
 // Trilhas seguem os eixos da grade (diagonais na tela) e só curvam nas viradas: diagonal na planta
 // vira escadinha na tela isométrica.
 const lowTrails=[{points:[[-.6,13.5],[8,13.5],[11.5,13.2],[11.5,12]],width:.9},
  {points:[[11.5,13.2],[15,14.5],[22,14.5],[27.5,14.2],[27.5,12]],width:.9},
  {points:[[25,14.5],[25.2,19.5],[23,22.8],[11,22.8],[7.6,23.5]],width:.95},
  {points:[[23,22.8],[34,22.8],[38.5,21],[38.5,12]],width:.95},
  {points:[[34,22.8],[34.6,24.5],[38,24.6]],width:.75}].map(t=>({...t,pts:curve(t.points,12)}));
 const upTrails=[{points:[[11.5,8],[11.5,6.2],[8,5.6],[6.4,5.4]],width:.8},{points:[[27.5,8],[27.5,5.4],[31,4.8],[38.5,4.8],[38.5,8]],width:.85},
  {points:[[38.5,4.8],[41.5,5.4],[44,6.2]],width:.8}].map(t=>({...t,pts:curve(t.points,12)}));
 const lowMato=[{c:[5.6,19.4],r:[3,1.9]},{c:[23.6,18],r:[1.9,1.4]},{c:[31,18.2],r:[2.6,1.6]},{c:[12,25.4],r:[2.2,1.2]}];
 const inBlob=(b,u,v,rough,seed)=>Math.hypot((u+.5-b.c[0])/b.r[0],(v+.5-b.c[1])/b.r[1])+(noise(u,v,seed,2.2)-.5)*rough<1;
 const onTrail=(T,u,v)=>T.some(t=>pathDist([u+.5,v+.5],t.pts)<t.width+(noise(u,v,s+7,2)-.5)*.4);
 for(let v=0;v<VH;v++)for(let u=0;u<VW;u++){const i=v*VW+u,E=edge(u);
  if(v<E){alt[i]=17;
   const rim=Math.min(u+.5,v+.5,VW-u-.5)<1.4+noise(u,v,s+2,2.4)*1.6;
   if(!rim&&(upper.some(b=>inBlob(b,u,v,.6,s+u))||inBlob(patio,u,v,.4,s+3)||onTrail(upTrails,u,v)))mat[i]='grama';
   if(mat[i]==='grama'&&onTrail(upTrails,u,v))mat[i]='terra';
   if(inBlob(patio,u,v,.3,s+3))mat[i]='piso';
   if(inBlob({c:[35.6,3],r:[1.8,1]},u,v,.4,s+9)&&mat[i]==='grama')mat[i]='mato';
  }else{
   const rim=Math.min(u+.5,VH-v-.5-2)<1.2+noise(u,v,s+4,2.4)*1.6||u>=42+Math.max(0,(VH-v)*.0);
   if(!rim)mat[i]='grama';
   if(mat[i]==='grama'){if(lowMato.some(b=>inBlob(b,u,v,.8,s+b.c[0])))mat[i]='mato';if(onTrail(lowTrails,u,v))mat[i]='terra';}
   const rc=riverC(v);if(Math.abs(u+.5-rc)<1.45+(BRIDGES.flat().includes(v)?0:(noise(u,v,s+5,2)-.5)*.6)&&v>=E+1)mat[i]=BRIDGES.flat().includes(v)?'ponte':'agua';
  }}
 // Rampas: quatro células de terra no nível de baixo, cortando o barranco; marca no topo (seta v-).
 for(const r of RAMPS)for(let du=0;du<3;du++){for(let n=0;n<4;n++){const i=(RAMP_EDGE-2+n)*VW+r+du;mat[i]='terra';alt[i]=0;}
  alt[(RAMP_EDGE-2)*VW+r+du]=24;mat[(RAMP_EDGE-3)*VW+r+du]='terra';mat[(RAMP_EDGE+2)*VW+r+du]='terra';}
 // Ao lado da rampa, o corte do barranco fica no nível de cima (parede), como nas Veredas antigas.
 for(const r of RAMPS)for(const du of [-1,3])for(let n=0;n<2;n++){const i=(RAMP_EDGE-2+n)*VW+r+du;alt[i]=17;mat[i]='bosque';}
 for(let u=0;u<2;u++)mat[13*VW+u]='terra';
 // Pontas soltas de trilha (uma célula de terra encostada em uma só) voltam a ser grama.
 const before=mat.slice();
 for(let v=1;v<VH-1;v++)for(let u=2;u<VW-1;u++){const i=v*VW+u;if(before[i]!=='terra'||alt[i]===24)continue;
  const n=[[1,0],[-1,0],[0,1],[0,-1]].filter(([du,dv])=>['terra','ponte','piso'].includes(before[(v+dv)*VW+u+du])).length;if(n<=1)mat[i]='grama';}
 return {mat,alt};
}
const V=(name,u,v,props)=>({name,u,v,props});
build({id:'veredas-do-encanamento',w:VW,h:VH,seed:91,treeDensity:.5,grid:veredasGrid,
 trees:(r)=>r<.22?{asset:'buriti'}:{asset:'arvore',variante:r<.5?'a':r<.75?'b':'cerrado'},
 dress:(mat,walk,taken,trees)=>{const out=[],busy=new Set([...taken,...trees.map(t=>t.join(','))]);
  // Capim de margem na beira do rio e na borda da mata, sem bloquear.
  for(let v=0;v<VH;v++)for(let u=0;u<VW;u++){const m=mat[v*VW+u];if(busy.has(`${u},${v}`)||hash(u,v,17)>.32)continue;
   const nearWater=[[1,0],[-1,0],[0,1],[0,-1]].some(([du,dv])=>mat[(v+dv)*VW+u+du]==='agua');
   if(m==='grama'&&nearWater||m==='bosque'&&[[1,0],[-1,0],[0,1],[0,-1]].some(([du,dv])=>walk(u+du,v+dv))&&hash(u,v,23)<.4)
    {out.push({name:'Capim da margem',u,v,props:{asset:'capim-margem',bloqueia:false}});busy.add(`${u},${v}`);}}
  return out;},
 meta:{nome:'Veredas do Encanamento',regras:'overworld-1',bioma:'veredas',cena_jogo:'park-veredas',origem:'desenhar-parque.mjs',rampa_comprimento:4},
 pieces:[V('Baú do mirante',6,4,{asset:'bau',interacao:'abrir',bau:'lookout'}),V('Baú entre as raízes',7,24,{asset:'bau',interacao:'abrir',bau:'woodland'}),
  V('Baú da margem escondida',38,25,{asset:'bau',interacao:'abrir',bau:'canal'}),V('Baú da encosta',34,3,{asset:'bau',interacao:'abrir',bau:'ridge'}),
  V('Baú dos canos antigos',47,8,{asset:'bau',interacao:'abrir',bau:'courtyard'}),
  V('Placa do mapa',6,11,{asset:'placa-mapa',bloqueia:false}),V('Biruta',23,16,{asset:'biruta',bloqueia:false}),
  V('Biruta do pátio',44,3,{asset:'biruta',bloqueia:false}),V('Banco do pátio',43,3,{asset:'banco',bloqueia:false}),
  V('Papel rasgado (pipa presa)',9,19,{asset:'pipa-presa',bloqueia:false}),
  V('Canos do pátio',48,5,{asset:'canos-patio'}),V('Canos do pátio',47,3,{asset:'canos-patio'}),V('Canos marcados',33,23,{asset:'canos-patio'}),
  ...[[4,7,'coral'],[9,7,'amarela'],[15,19,'azul'],[20,25,'coral'],[29,6,'amarela'],[37,6,'coral'],[41,24,'azul'],[13,12,'amarela']].map(([u,v,c])=>V('Flores',u,v,{asset:'flores',variante:c,bloqueia:false}))],
 events:[{type:'entrada',name:'Chegada da Clareira',u:2,v:13},{type:'saida',name:'Voltar à Clareira do Papel',u:0,v:13,props:{destino:'park-clearing'}},
  {type:'npc',name:'Lacertubo · guardião dos canos',u:46,v:5,props:{acao:'parkBoss'}},{type:'interacao',name:'Banco do pátio',u:43,v:4,props:{acao:'wildRest'}},
  {type:'interacao',name:'Sinais no bosque',u:5,v:12,props:{acao:'parkBossGuide'}},{type:'interacao',name:'Mapa das Veredas',u:6,v:12,props:{acao:'parkMap'}},
  {type:'interacao',name:'Papel rasgado entre as folhas',u:9,v:19,props:{acao:'veredasTrace'}},{type:'interacao',name:'Canos marcados',u:32,v:22,props:{acao:'veredasPipes'}},
  {type:'interacao',name:'Rabiola do Carcará de Nina',u:46,v:7,props:{acao:'veredasTail'}},{type:'npc',name:'Nina',u:24,v:15,props:{acao:'veredasNina'}}]});

// Compila só as plantas desenhadas aqui (sem regravar os kits).
const {compile}=await import('../import-overworld.mjs');
for(const id of ['jardim-das-pipas','clareira-do-papel','veredas-do-encanamento'])
 fs.writeFileSync(root+`godot/assets/overworld/maps/${id}.json`,JSON.stringify(compile(JSON.parse(fs.readFileSync(root+`art/overworld/mapas/${id}.tmj`,'utf8')),id)));
console.log('Plantas compiladas para o Godot.');
// The approved terraced Jardim supersedes the old flat draft above. Running the
// legacy batch must retain the new map and its stable IDs/return coordinates.
const {generateJardim}=await import('./desenhar-jardim-das-pipas.mjs');
generateJardim();
