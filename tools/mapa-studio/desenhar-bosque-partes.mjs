// Deterministic Bosque B/C. Briefs are the source of spatial/narrative intent.
import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {parseTiled,audit,verdict,reachable,walkable} from './model.mjs';
import {compile} from '../import-overworld.mjs';
import {writeCapturePlan} from './capturas-bosque.mjs';
import {auditBosque} from './conferir-regiao-bosque.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
const tileset=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj','utf8'));
const GID=Object.fromEntries(tileset.tiles.filter(t=>t.id<16).map(t=>[t.properties[0].value,t.id+1]));
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
export function generatePart(part){
 const id='kronasta-bosque-'+part.toLowerCase(),W=52,H=44;
 const mat=Array(W*H).fill('grama'),level=Array(W*H).fill(0),ramp=Array(W*H).fill(0),pieces=[],events=[],shots=[];
 let objectId=0;
 const I=(u,v)=>v*W+u,inside=(u,v)=>u>=0&&v>=0&&u<W&&v<H;
 const rect=(u,v,w,h,m=null,l=null)=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++)if(inside(x,y)){if(m)mat[I(x,y)]=m;if(l!==null)level[I(x,y)]=l;}};
 const obj=(type,name,u,v,p={})=>({id:++objectId,name,type,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 const E=(type,name,u,v,p={})=>events.push(obj(type,name,u,v,p));
 const P=(asset,name,u,v,p={})=>pieces.push(obj('peca',name,u,v,{asset,...p}));
 const path=(points,width=3,l=0)=>{for(let n=1;n<points.length;n++){const a=points[n-1],b=points[n],steps=Math.ceil(Math.hypot(b[0]-a[0],b[1]-a[1])*3);for(let s=0;s<=steps;s++){const t=s/steps,u=Math.round(a[0]+(b[0]-a[0])*t),v=Math.round(a[1]+(b[1]-a[1])*t);rect(u-Math.floor(width/2),v-Math.floor(width/2),width,width,'terra',l);}}};
 const access=(u,v,base,width=2,stairs=false)=>{
  // Seed is the upper of two ramp cells; rises v−, front foot = v+2.
  for(let x=u;x<u+width;x++){rect(x,v-2,1,2,'grama',base+1);rect(x,v,1,4,'terra',base);ramp[I(x,v)]=base===1?124:24;}
  shots.push({name:(stairs?'escada':'rampa')+'-pe-'+u+'-'+v,u:u+width/2,v:v+1.8},{name:(stairs?'escada':'rampa')+'-chegada-'+u+'-'+v,u:u+width/2,v:v-.3});
 };
 // Continuous framing; plateau cells chosen as 2x2 blocks, long axis-aligned edges.
 rect(0,0,W,4,'bosque');rect(0,H-4,W,4,'bosque');rect(0,0,4,H,'bosque');rect(W-4,0,4,H,'bosque');
 rect(2,4,18,36,null,1);rect(30,4,18,36,null,1);
 const feature={stairs:[],guards:[],shots,water:null,landmark:null};
 if(part==='B'){
  // Meandering shallow stream; water divides route, bridge is deliberate traversal.
  for(let u=0;u<W;u++){const center=22+Math.round(Math.sin(u*.13)*2);for(let v=center-2;v<=center+1;v++){mat[I(u,v)]='agua';level[I(u,v)]=0;}}
  path([[24,43],[25,32],[25,27]],4);path([[25,16],[23,9],[24,0]],4);
  rect(23,17,4,13,'terra',0);
  // Bridge v axis, 3 wide: bank rows 18 and25, deck19..24. Stream stays beneath.
  rect(23,19,3,6,'ponte',0);rect(23,17,3,2,'terra',0);rect(23,25,3,2,'terra',0);
  // West foreground plateau then second level; access fronts remain completely clear.
  path([[25,31],[19,32],[16,34]],3);access(14,32,0);
  rect(6,26,8,6,'grama',2);path([[14,29],[12,31]],2,1);access(10,32,1);
  // East plateau rest and view, fed by an independent branch.
  path([[25,32],[34,35],[44,34]],3);access(44,32,0);
  rect(32,5,14,8,'bosque',1);
  // Basin aperture touches rear edge of its 8x8 support block, so clipping has no inner ring.
  let contour=[[33,9],[37,9],[39,11],[40,13],[39,16],[37,17],[34,16],[32,14],[32,12]];
  const round=[contour[0],contour[1]];for(let i=2;i<contour.length;i++){const a=contour[i-1],b=contour[i],c=contour[(i+1)%contour.length];round.push([a[0]*.25+b[0]*.75,a[1]*.25+b[1]*.75],[b[0]*.75+c[0]*.25,b[1]*.75+c[1]*.25]);}contour=round;
  for(let v=9;v<=17;v++)for(let u=31;u<=40;u++){
   const x=u+.5,y=v+.5;let on=false;for(let i=0,j=contour.length-1;i<contour.length;j=i++)if((contour[i][1]>y)!==(contour[j][1]>y)&&x<(contour[j][0]-contour[i][0])*(y-contour[i][1])/(contour[j][1]-contour[i][1])+contour[i][0])on=!on;
   if(on){mat[I(u,v)]='agua';level[I(u,v)]=0;}
  }
  // Footprint closes visual margins: non-walkable bank cells around measured basin.
  for(let v=10;v<18;v++)for(let u=31;u<41;u++)if(mat[I(u,v)]!=='agua')mat[I(u,v)]='bosque';
  for(let v=9;v<19;v++)for(let u=31;u<42;u++)level[I(u,v)]=0;
  const channel=[];for(let u=-10;u<=62;u+=1)channel.push([u,20+Math.sin(u*.13)*2]);for(let u=62;u>=-10;u-=1)channel.push([u,24+Math.sin(u*.13)*2]);
  feature.water={contour,channel,depth:24,lipHeight:64,fall:[35,9],channelDepth:6};
  shots.push({name:'ponte-cabeceira-norte',u:24.5,v:18.5},{name:'ponte-cabeceira-sul',u:24.5,v:25.5},{name:'ponte-tabuleiro',u:24.5,v:22},{name:'margem-curva-oeste',u:12,v:24},{name:'margem-curva-leste',u:35,v:22},{name:'poco-margem-proxima',u:36,v:16},{name:'poco-labio',u:35,v:10},{name:'poco-impacto',u:36,v:13},{name:'poco-geral',u:36,v:14,zoom:1});
  E('entrada','Chegada da Trilha das Copas',24,41,{origem:'kronasta-bosque-a'});
  E('saida','Voltar à Trilha das Copas',24,43,{destino:'kronasta-bosque-a',chegada_u:24,chegada_v:2});
  E('saida','Seguir à Clareira do Marco',24,0,{destino:'kronasta-bosque-c',chegada_u:24,chegada_v:41});
  E('item','Papel no alto da mesa',8,28,{item:'papel-seda',quantidade:2,visibilidade:'escondido'});
  E('item','Cola junto ao descanso',30,16,{item:'cola-reparo',quantidade:1,visibilidade:'brilho'});
  E('item','Varetas na vereda',20,29,{item:'vareta-bambu',quantidade:2,visibilidade:'visivel'});
  rect(19,27,3,3,'mato',0);
 }else{
  path([[24,43],[24,33],[26,25],[25,18],[25,13]],4);
  // Habited plateau joins rear terraces; a broad front staircase, with guard at both lips.
  rect(18,4,16,10,'grama',1);rect(18,5,16,7,'piso',1);
  access(24,14,0,3,true);feature.stairs.push({u:24,v:14,width:3,length:2});
  // Optional viewpoints with materials, no compulsory encounter.
  path([[24,30],[18,31],[16,34]],3);access(14,33,0);
  path([[25,27],[32,29],[36,33]],3);access(36,32,0);
  // Loop back: shortcut leaves C along v+ and arrives at A's existing northern trail.
  path([[24,32],[29,35],[32,43]],3);
  feature.landmark={u:25.5,v:8.5};
  P('banco','Banco dos moradores',21,8,{pegada:'2x1',bloqueia:true,interacao:'sentar'});
  P('banco','Banco do mirante',29,10,{pegada:'2x1',bloqueia:true,interacao:'sentar'});
  // Guards sit precisely on plateau exposed edge, not as colliding cell props.
  for(let u=18;u<24;u++)feature.guards.push({u,v:13,side:'v'});
  for(let u=27;u<34;u++)feature.guards.push({u,v:13,side:'v'});
  for(let v=4;v<14;v++){feature.guards.push({u:33,v,side:'u'});feature.guards.push({u:17,v,side:'u'});}
  shots.push({name:'marco-descanso',u:25.5,v:8.5,zoom:1},{name:'mureta-ponta-esquerda',u:24,v:14},{name:'mureta-ponta-direita',u:27,v:14},{name:'mureta-encontro-leste',u:34,v:14},{name:'mureta-encontro-oeste',u:18,v:14},{name:'mureta-ponta-fundo',u:34,v:4});
  E('entrada','Chegada do Desvio do Riacho',24,41,{origem:'kronasta-bosque-b'});
  E('saida','Voltar ao Desvio do Riacho',24,43,{destino:'kronasta-bosque-b',chegada_u:24,chegada_v:2});
  E('saida','Atalho à Trilha das Copas',32,43,{destino:'kronasta-bosque-a',chegada_u:24,chegada_v:2,descoberta:'clareira-do-marco'});
  E('item','Papel dos moradores',28,8,{item:'papel-seda',quantidade:3,visibilidade:'brilho'});
  E('item','Varetas escondidas no mirante',9,29,{item:'vareta-bambu',quantidade:2,visibilidade:'escondido'});
  E('item','Cola na clareira',29,26,{item:'cola-reparo',quantidade:1,visibilidade:'visivel'});
  rect(30,28,3,3,'mato',0);
 }
 if(part==='B')rect(48,4,2,36,null,1);
 for(let bv=0;bv<H;bv+=2)for(let bu=0;bu<W;bu+=2){
  const ids=[I(bu,bv),I(bu+1,bv),I(bu,bv+1),I(bu+1,bv+1)];
  const protectedPad=ids.some(i=>{const u=i%W,v=Math.floor(i/W);return ramp[i]||[1,2].some(d=>inside(u,v+d)&&ramp[I(u,v+d)]);});
  if(!protectedPad&&ids.some(i=>level[i]===0)&&ids.some(i=>level[i]===1))for(const i of ids)level[i]=0;
 }
 if(part==='C')for(let v=4;v<36;v++)for(let u=4;u<48;u++){
  if(level[I(u,v)]===1&&mat[I(u,v)]==='grama'&&[[8,10,7,6],[43,10,7,7],[8,20,5,5],[45,26,4,5]].some(([x,y,a,b])=>((u-x)/a)**2+((v-y)/b)**2<1))mat[I(u,v)]='bosque';
 }
 // Remove accidental single-cell ledges before any art; preserve all ramp landings.
 for(let pass=0;pass<32;pass++)for(let v=1;v<H-1;v++)for(let u=1;u<W-1;u++){
  const i=I(u,v);if(!level[i]||ramp[i])continue;
  const landing=ramp[I(u,v+1)]||ramp[I(u,v+2)];if(landing)continue;
  const count=[[1,0],[-1,0],[0,1],[0,-1]].filter(([du,dv])=>level[I(u+du,v+dv)]===level[i]&&!ramp[I(u+du,v+dv)]).length;
  if(count<2)level[i]--;
 }
 feature.guards=feature.guards.filter(g=>{const du=g.side==='u'?1:0,dv=g.side==='v'?1:0;return level[I(g.u,g.v)]>level[I(g.u+du,g.v+dv)]&&!ramp[I(g.u,g.v)]&&!ramp[I(g.u+du,g.v+dv)];});
 // Mark unreachable pockets as actual forest, never apparently walkable islands.
 const raw=()=>({type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,properties:props({nome:'Bosque dos Ventos · '+(part==='B'?'Desvio do Riacho':'Clareira do Marco'),regras:'overworld-1',bioma:'floresta',cena_jogo:id,regiao:'bosque-dos-ventos',parte:part,trajetoria:'ambas',rampa_comprimento:2}),tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'},{firstgid:101,name:'rampa-v-menos-nivel1',tilewidth:64,tileheight:32,tilecount:24,columns:8,image:'../tiles/rascunho.png',imagewidth:512,imageheight:96,tiles:[{id:23,properties:props({nivel:1,rampa:'v-'})}]}],layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(x=>GID[x])},{name:'altura',type:'tilelayer',width:W,height:H,data:level.map((l,i)=>ramp[i]||(l?16+l:0))},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]});
 let m=parseTiled(raw(),{'rascunho.tsj':tileset}),seen=reachable(m,m.spawn);
 for(let v=0;v<H;v++)for(let u=0;u<W;u++)if(walkable(m,u,v)&&!seen[I(u,v)])mat[I(u,v)]='bosque';
 // Populate only closed masses. Trail front clearance tested in renderer too.
 for(let v=0;v<H;v++)for(let u=0;u<W;u++){
  if(mat[I(u,v)]!=='bosque')continue;
  if(feature.water&&u>=30&&u<=41&&v>=9&&v<=18)continue;
  let near=false;for(let dy=-2;dy<=2;dy++)for(let dx=-2;dx<=2;dx++)if(inside(u+dx,v+dy)&&['terra','ponte','piso'].includes(mat[I(u+dx,v+dy)]))near=true;
  if(!near&&(u*17+v*13)%5!==0)P('arvore','Mata em massa',u,v,{variante:(u+v)%3?'a':'b'});
 }
 for(let pass=0;pass<2;pass++)for(let v=1;v<H-1;v++)for(let u=1;u<W-1;u++){
  const i=I(u,v);if(mat[i]!=='terra'||ramp[i])continue;
  const approach=[-3,-2,-1,0,1,2].some(d=>inside(u,v+d)&&ramp[I(u,v+d)]);if(approach)continue;
  const count=[[1,0],[-1,0],[0,1],[0,-1]].filter(([du,dv])=>['terra','ponte','piso'].includes(mat[I(u+du,v+dv)])).length;
  if(count<=1&&!events.some(e=>Math.abs(e.x/32-.5-u)+Math.abs(e.y/32-.5-v)<=2))mat[i]='grama';
 }
 const data=raw();m=parseTiled(data,{'rascunho.tsj':tileset});const issues=audit(m);for(const x of issues)if(x.level!=='ok')console.log(x.level,x.text);
 if(verdict(issues)==='fail')throw Error(id+': planta reprovada');
 data.properties.push(...props({forest:JSON.stringify(feature)}));
 const out=compile(data,id);out.forest=feature;
 fs.writeFileSync(root+'art/overworld/mapas/'+id+'.tmj',JSON.stringify(data,null,1)+'\n');
 fs.writeFileSync(root+'godot/assets/overworld/maps/'+id+'.json',JSON.stringify(out));
 const idxPath=root+'godot/assets/overworld/maps/index.json',idx=JSON.parse(fs.readFileSync(idxPath));idx.areas=idx.areas.filter(x=>x.id!==id);idx.areas.push({id,name:out.name,scene:id,biome:'floresta'});idx.scenes[id]=id;fs.writeFileSync(idxPath,JSON.stringify(idx,null,2)+'\n');
 writeCapturePlan(out,feature);
 console.log(id+': '+verdict(issues)+' · '+out.oracle.walkable.length+' alcançáveis · '+Math.round(level.filter(x=>x>0).length/level.length*100)+'% platô');
 auditBosque();
 return out;
}
if(process.argv[1]===fileURLToPath(import.meta.url)){generatePart('B');generatePart('C');}
