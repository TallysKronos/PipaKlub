import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {compile} from '../import-overworld.mjs';
import {parseTiled} from './model.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
import {writeCapturePlan} from './capturas-bosque.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
export const W=56,H=48,ENTRY=28;
const source=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
const gid=Object.fromEntries(source.tiles.filter(t=>t.id<16).map(t=>[t.properties[0].value,t.id+1]));
const id=p=>'submerso-'+p.toLowerCase(),names=['Recife de entrada','Jardim de algas','Fenda abissal'];
const heights={...source,name:'submerso-alturas',image:'../tiles/rascunho.png',firstgid:101,tiles:[]};
for(let n=0;n<=6;n++)heights.tiles.push({id:n,type:'altura',properties:props({nivel:n})});
heights.tiles.push({id:7,type:'altura',properties:props({nivel:-2})});
for(let n=0;n<=5;n++)heights.tiles.push({id:8+n,type:'altura',properties:props({nivel:n,rampa:'v-'})});
export function submergedPart(part){
 if(!['A','B','C'].includes(part))throw Error('Unknown submerged part '+part);
 const n=part.charCodeAt(0)-65,base=n+1,ix=(u,v)=>v*W+u;
 const mat=Array(W*H).fill('rocha'),levels=Array(W*H).fill(-2),ramps=new Set(),events=[],pieces=[],trails=[],accesses=[],sandPatches=[];
 let next=1;
 const split=u=>part==='A'?(u<18?26:u>=40?30:28):part==='B'?(u<20?26:u>=40?30:28):(u<24?30:u>=38?28:26);
 const crown=part==='A'?[8,6,16,12]:part==='B'?[32,6,16,10]:[10,6,16,12];
 const natural=(u,v)=>base+(v<split(u)?1:0)+(u>=crown[0]&&u<crown[0]+crown[2]&&v>=crown[1]&&v<crown[1]+crown[3]?1:0);
 const paint=(u,v,w,h,m='terra')=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++)if(x>=0&&y>=0&&x<W&&y<H){mat[ix(x,y)]=m;levels[ix(x,y)]=natural(x,y);}};
 // Long contour segments, shaped by bands instead of a stair-step ellipse.
 const bands=part==='A'?[[4,12,10,44],[12,20,6,48],[20,36,4,50],[36,42,8,46],[42,44,16,40]]:part==='B'?[[4,10,12,46],[10,18,6,50],[18,38,4,50],[38,42,8,46],[42,44,16,40]]:[[4,12,10,44],[12,22,6,48],[22,38,4,52],[38,42,10,48],[42,44,18,40]];
 for(const[v0,v1,u0,u1]of bands)paint(u0,v0,u1-u0,v1-v0,'grama');
 const path=(points,width=3)=>{trails.push(points);for(let k=1;k<points.length;k++){const a=points[k-1],b=points[k],steps=Math.ceil(Math.hypot(a[0]-b[0],a[1]-b[1])*4);for(let j=0;j<=steps;j++)paint(Math.round(a[0]+(b[0]-a[0])*j/steps)-Math.floor(width/2),Math.round(a[1]+(b[1]-a[1])*j/steps)-Math.floor(width/2),width,width);}};
 const access=(u,v,width=5)=>{paint(u-1,v-2,width,6);for(let x=u-1;x<u-1+width;x++)ramps.add(ix(x,v));accesses.push({u:u-1,v,width,level:natural(u,v)});};
 path([[ENTRY,H-1],[ENTRY,39]]);
 if(part!=='C')path([[ENTRY,23],[ENTRY,0]]);
 if(part==='A'){
  path([[28,39],[34,37],[34,30]]);path([[34,27],[34,22],[20,22],[16,22],[16,20]]);access(32,28);access(14,18);
 }
 if(part==='B'){
  path([[28,39],[14,39],[12,35],[12,28]]);path([[12,25],[12,22],[28,22],[40,22],[40,18]]);access(10,26);access(38,16);
 }
 if(part==='C'){
  path([[28,47],[28,42],[38,40],[42,36],[42,30]]);path([[28,47],[28,42],[18,40],[18,33],[22,32],[22,31],[24,31],[24,25],[40,25]]);path([[42,27],[42,22],[20,22],[20,20]]);access(40,28);access(18,18);
  // A continuous crevasse: a wide central cut plus a recessed side pocket, never isolated holes.
  for(let v=32;v<40;v++)for(let u=26;u<30;u++){mat[ix(u,v)]='rocha';levels[ix(u,v)]=-2;}
  for(let v=34;v<38;v++)for(let u=30;u<32;u++){mat[ix(u,v)]='rocha';levels[ix(u,v)]=-2;}
 }

 const rewards=part==='A'?[[10,38],[14,10],[44,24]]:part==='B'?[[10,37],[42,10],[46,35]]:[[14,37],[16,10],[47,32]];
 for(const[u,v]of rewards){const from=v<18?[u,16]:v<26?[28,23]:[u,39];path([from,[u,v]]);paint(u-1,v-1,3,3);}
 // High seabed terrace paths remain within their own platform; no cut across a cliff is called a path.
 if(part==='A')path([[16,17],[16,10],[14,10]]);
 if(part==='B')path([[40,15],[40,10],[42,10]]);
 if(part==='C')path([[20,17],[20,10],[16,10]]);
 const patch=(cx,cy,rx,ry)=>{
  const cells=[];for(let v=4;v<H-4;v++)for(let u=4;u<W-4;u++){
   const i=ix(u,v),x=(u+.5-cx)/rx,y=(v+.5-cy)/ry;
   if(x*x+y*y+.10*Math.sin(u*.8+v*.6)>.90||levels[i]!==natural(Math.floor(cx),Math.floor(cy))||!['grama','piso','terra'].includes(mat[i]))continue;
   if(accesses.some(a=>u>=a.u-2&&u<a.u+a.width+2&&v>=a.v-3&&v<=a.v+4))continue;
   mat[i]='piso';cells.push([u,v]);
  }sandPatches.push({cx,cy,rx,ry,cells});
 };
 if(part==='A'){patch(24,36,7,4);patch(40,17,6,4);patch(15,11,5,3);}
 if(part==='B'){patch(30,35,13,6);patch(23,17,6,4);patch(40,10,5,3);}
 if(part==='C'){patch(39,36,5,4);patch(13,26,6,3);patch(17,10,5,3);}
 const encounter=part==='A'?[44,33]:part==='B'?[44,23]:[10,32];paint(encounter[0],encounter[1],3,2,'mato');
 const sloped=new Set([...ramps].flatMap(i=>[i,i+W]));
 // Remove isolated ledges; don't hide geometry defects behind props.
 for(let pass=0;pass<24;pass++){let changed=false;for(let v=1;v<H-1;v++)for(let u=1;u<W-1;u++){const i=ix(u,v);if(levels[i]<0||sloped.has(i))continue;const ns=[i-1,i+1,i-W,i+W];if(ns.filter(j=>levels[j]===levels[i]&&!sloped.has(j)).length>=2)continue;if(mat[i]==='grama'){mat[i]='rocha';levels[i]=-2;changed=true;}}if(!changed)break;}
 for(let v=1;v<H-1;v++)for(let u=1;u<W-1;u++){const i=ix(u,v),ns=[i-1,i+1,i-W,i+W];if(levels[i]<0&&ns.every(j=>levels[j]>=0&&levels[j]===levels[ns[0]])){levels[i]=levels[ns[0]];mat[i]='grama';}}
 const object=(type,name,u,v,p={})=>({id:next++,type,name,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 events.push(object('entrada','Entrada do recife',ENTRY,H-3));
 if(n>0)events.push(object('saida','Voltar ao trecho anterior',ENTRY,H-1,{destino:id(String.fromCharCode(64+n)),chegada_u:ENTRY,chegada_v:2}));
 if(n<2)events.push(object('saida','Seguir pelo leito',ENTRY,0,{destino:id(String.fromCharCode(66+n)),chegada_u:ENTRY,chegada_v:H-3}));
 else events.push(object('interacao','Colônia do recife',18,13,{texto:'As correntes passam entre os ramos do coral.'}));
 rewards.forEach(([u,v],i)=>events.push(object('item',['Suprimentos da expedição','Achado do mirante','Material na areia'][i],u,v,{item:['cola-reparo','vareta-bambu','papel-seda'][i],quantidade:1,visibilidade:i===2?'escondido':'brilho',trajetoria:'ambas'})));
 const occupied=new Set();
 const add=(kind,u,v,w=1,h=1,p={})=>{
  const cells=[];for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++)cells.push(ix(x,y));
  if(cells.some(i=>levels[i]<0||levels[i]!==levels[cells[0]]||sloped.has(i)||occupied.has(i)))throw Error(`${part} ${kind} invalid support ${u},${v}`);
  pieces.push(object('peca',kind==='alga'?'Alga do recife':kind,u,v,{asset:kind==='baliza'?'submerso-marker':'submerso-prop',variante:kind,pegada:w+'x'+h,...p}));cells.forEach(i=>occupied.add(i));
 };
 const propsByPart={A:[['coral',12,34,3,3],['colonia',19,8,3,3],['espirao',42,14,3,2],['rocha',7,22,3,2]],B:[['rocha',36,34,3,2],['coral',44,12,2,2],['coral',8,20,3,3],['rocha',20,13,3,2]],C:[['colonia',20,8,4,3],['espirao',43,16,3,3],['rocha',14,24,3,2],['coral',33,35,2,2]]};
 const accents={A:[['espirao',7,28,2,2],['espirao',36,12,2,2],['coral',25,32,2,2],['coral',38,24,2,2],['coral',14,32,2,2]],B:[['espirao',16,32,2,2],['espirao',32,12,2,2],['coral',44,34,2,2],['coral',23,12,2,2]],C:[['espirao',10,27,2,2],['espirao',36,18,2,2],['coral',18,26,2,2],['coral',39,33,2,2]]};
 for(const p of [...propsByPart[part],...accents[part]])add(...p);
 for(const a of accesses){const u=a.u+a.width+2,v=a.v+3;if(levels[ix(u,v)]===natural(u,v)&&levels[ix(u,v)]>=0)add('baliza',u,v);}
 // Authored kelp masses: roots carry collisions; fronds may overlap each other, never ramp mouths.
 const groves=part==='A'?[[8,16],[9,26],[42,20],[42,37],[20,38],[32,10],[38,7]]:part==='B'?[[8,13],[45,19],[45,38],[14,18],[19,7],[35,22]]:[[8,20],[10,36],[42,8],[46,25],[35,13],[18,22]];
 const offsets=[[0,0],[1,0],[2,0],[0,1],[1,1],[2,1],[0,2],[1,2],[2,2]];
 for(const[g,[cx,cy]]of groves.entries()){
  let count=0;for(const[dx,dy]of offsets){const u=cx+dx,v=cy+dy,i=ix(u,v);
   if(u<4||u>=W-4||v<4||v>=H-4||levels[i]<0||mat[i]!=='grama'||occupied.has(i))continue;
   if(accesses.some(a=>Math.abs(u-(a.u+a.width*.5))<7&&v>=a.v-4&&v<=a.v+7))continue;
   if(events.some(e=>Math.hypot(u-Math.floor(e.x/32),v-Math.floor(e.y/32))<3))continue;
   // Leave a 2-cell sand apron behind each trunk and the whole marked path unobstructed.
   if([[0,0],[-1,0],[1,0],[0,-1],[0,1],[-1,-1]].some(([x,y])=>mat[ix(u+x,v+y)]==='terra'))continue;
   add('alga',u,v,1,1,{escala:1+((g+count)%3-1)*.09,espelho:(g+count)%2===0});mat[i]='bosque';count++;
  }
 }
 const feature={nativeProps:true,submerged:true,revision:1,baseLevel:base,part,followTrail:false,guards:[],clearViews:[],shots:[],trails,sandPatches,accesses};
 for(const a of accesses)for(let u=a.u;u<a.u+a.width;u++)feature.clearViews.push([u+.5,a.v+.5],[u+.5,a.v+2.5]);
 for(const[name,u,v]of[['chegada',28,38],['patamar',28,23],['mirante',crown[0]+crown[2]/2,12],['desvio',rewards[0][0],rewards[0][1]],['marco',part==='B'?30:part==='C'?18:14,part==='B'?35:part==='C'?13:35]])feature.shots.push({name,u,v,zoom:1,kind:'jogo'});
 for(const a of accesses)feature.shots.push({name:`lateral-rampa-${a.u}-${a.v}`,u:a.u+.1,v:a.v+1,zoom:2.3,kind:'junta'});
 for(const [i,patch]of sandPatches.entries()){
  for(const[side,axis,sign]of [['oeste',0,1],['leste',0,-1],['norte',1,1],['sul',1,-1]]){
   const edge=patch.cells.reduce((a,b)=>b[axis]*sign<a[axis]*sign?b:a);
   feature.shots.push({name:'areia-'+i+'-'+side,u:edge[0]+.5,v:edge[1]+.5,zoom:2.3,kind:'junta'});
  }
 }
 const raw={type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,properties:props({nome:'Submerso · '+names[n],regras:'overworld-1',bioma:'floresta',cena_jogo:id(part),regiao:'submerso-previa',parte:part,trajetoria:'ambas',rampa_comprimento:2,forest:JSON.stringify(feature)}),tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'},heights],layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(m=>gid[m])},{name:'altura',type:'tilelayer',width:W,height:H,data:levels.map((l,i)=>ramps.has(i)?109+l:l<0?108:101+l)},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]};
 return{id:id(part),part,raw,feature};
}
export function generateSubmerged(){
 const parts=['A','B','C'].map(submergedPart),region=parts.map(p=>({id:p.id,part:p.part,map:parseTiled(p.raw,{'rascunho.tsj':source})})),links=[['A','B'],['B','C']].map(([a,b])=>({from:{area:id(a),u:ENTRY,v:0,direction:'v-'},to:{area:id(b),u:ENTRY,v:H-1,direction:'v+'}}));
 fs.mkdirSync(root+'documentation/overworld/submerso/relatorios',{recursive:true});
 for(const p of parts){
  const m=region.find(r=>r.id===p.id).map,result=auditZeroBreak(m,{region,links,requiredRoute:[m.spawn,...m.events.filter(e=>e.type==='saida'||e.name==='Colônia do recife')]});
  console.log(p.id+'\n'+result.lines.join('\n'));if(!result.ok)throw Error(p.id+' rejected');
  fs.writeFileSync(root+'art/overworld/mapas/'+p.id+'.tmj',JSON.stringify(p.raw,null,1)+'\n');
  const out=compile(p.raw,p.id);fs.writeFileSync(root+'godot/assets/overworld/maps/'+p.id+'.json',JSON.stringify(out));
  const shots=writeCapturePlan(out,p.feature,'documentation/overworld/submerso');shots[0].zoom=.34;shots[0].offsetY=70;
  fs.writeFileSync(root+'documentation/overworld/submerso/planos/'+p.id+'.json',JSON.stringify({area:p.id,shots},null,2)+'\n');
  fs.writeFileSync(root+'documentation/overworld/submerso/relatorios/'+p.id+'.json',JSON.stringify(result,null,2)+'\n');
 }
 const file=root+'godot/assets/overworld/maps/index.json',index=JSON.parse(fs.readFileSync(file));for(const[p,n]of parts.map((p,n)=>[p,n])){index.areas=index.areas.filter(a=>a.id!==p.id);index.areas.push({id:p.id,name:'Submerso · '+names[n],scene:p.id,biome:'floresta'});index.scenes[p.id]=p.id;}fs.writeFileSync(file,JSON.stringify(index,null,2)+'\n');return parts;
}
if(process.argv[1]===fileURLToPath(import.meta.url))generateSubmerged();
