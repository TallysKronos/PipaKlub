import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {parseTiled} from './model.mjs';
import {compile} from '../import-overworld.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
import {writeCapturePlan} from './capturas-bosque.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),W=48,H=40;
const source=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
const gid=Object.fromEntries(source.tiles.filter(t=>t.id<16).map(t=>[t.properties[0].value,t.id+1]));
const heights={...source,firstgid:101,name:'cais-alturas',image:'../tiles/rascunho.png',tiles:[]};
for(let n=0;n<5;n++)heights.tiles.push({id:n,type:'altura',properties:props({nivel:n})});
for(let n=0;n<4;n++)heights.tiles.push({id:8+n,type:'altura',properties:props({nivel:n,rampa:'v-'})});
const id=p=>'kronasta-cais-'+p.toLowerCase();
export function caisPart(part){
 const mat=Array(W*H).fill('agua'),level=Array(W*H).fill(0),ramp=new Set(),events=[],pieces=[];let oid=0;
 const I=(u,v)=>v*W+u;
 const rect=(u,v,w,h,m='piso',l=1)=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++){mat[I(x,y)]=m;level[I(x,y)]=l;}};
 const obj=(type,name,u,v,p={})=>({id:++oid,type,name,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 const E=(t,n,u,v,p={})=>events.push(obj(t,n,u,v,p));
 const f={harbor:true,nativeProps:true,stairs:[],guards:[],buildings:[],docks:[],props:[],ships:[],shots:[]};
 rect(4,4,30,32);rect(23,0,5,40);
 const stairs=(u,v,base,width=4)=>{
  rect(u,v-2,width,2,'piso',base+1);rect(u,v,width,4,'terra',base);
  for(let x=u;x<u+width;x++)ramp.add(I(x,v));f.stairs.push({u,v,width,length:2});
 };
 const building=(u,v,w,h,n)=>{pieces.push(obj('peca',n,u,v,{asset:'cais-volume',pegada:w+'x'+h,bloqueia:true}));f.buildings.push({u,v,w,h,height:160,name:n});};
 if(part==='A'){
  rect(4,4,16,14,'piso',2);stairs(12,18,1);
  rect(34,22,8,5);rect(34,10,6,4);f.docks.push({u:32,v:22,w:10,h:5},{u:32,v:10,w:8,h:4});
  building(5,5,6,5,'Oficina de velame');building(6,26,5,5,'Casa do ancoradouro');building(14,25,5,5,'Casa das redes');building(27,28,5,5,'Casa do barco azul');building(13,5,4,5,'Oficina de costura');
  E('npc','Neril',24,30,{acao:'districtDuel',district:'cais',duel:'cais-1',npcId:'neril'});
  E('npc','Ossian',16,11,{acao:'districtDuel',district:'cais',duel:'cais-2',npcId:'ossian'});
 }
 if(part==='B'){
  rect(4,4,38,32);rect(20,20,22,8,'agua',0);rect(24,20,4,8,'ponte',1);
  rect(4,4,14,12,'piso',2);stairs(10,16,1);
  building(5,5,4,5,'Depósito de redes');building(32,6,6,6,'Galpão dos mastros');building(6,26,5,4,'Casa do pescador');building(11,5,5,4,'Casa do vigia');building(36,30,4,4,'Casa da doca');
  E('npc','Vaelis',15,10,{acao:'districtDuel',district:'cais',duel:'cais-3',npcId:'vaelis'});
  E('npc','Rhuna',34,31,{acao:'districtDuel',district:'cais',duel:'cais-4',npcId:'rhuna'});
  E('interacao','Descanso das docas',12,30,{acao:'districtRest',district:'cais'});
  f.docks.push({u:24,v:20,w:4,h:8});
  f.shots.push({name:'ponte-cabeceira-sul',u:26,v:28},{name:'ponte-cabeceira-norte',u:26,v:20});
 }
 if(part==='C'){
  rect(23,0,5,4,'agua',0);
  rect(4,4,38,32);rect(34,20,8,12,'agua',0);
  rect(14,4,18,12,'piso',2);stairs(22,16,1);
  rect(20,4,8,6,'piso',3);stairs(22,10,2);
  building(5,7,5,5,'Casa de sinais');building(35,5,5,5,'Oficina de pipas');building(5,18,5,5,'Casa do cais alto');building(16,26,5,5,'Ateliê de bandeiras');
  E('npc','Marisol',24,7,{acao:'districtDuel',district:'cais',duel:'cais-5',npcId:'marisol'});
  E('saida','Retorno ao ancoradouro',28,37,{destino:id('A'),chegada_u:24,chegada_v:36,requer:'cais',atalho:true});rect(28,35,3,5);
 }
 const prop=(asset,u,v,w=2,h=2,width=130)=>{pieces.push(obj('peca','Material do cais',u,v,{asset:'cais-'+asset,pegada:w+'x'+h,bloqueia:true}));f.props.push({asset,u,v,w,h,width});};
 if(part==='A'){prop('materiais',6,12);prop('banca',8,22,3,2,170);prop('mastro',29,8,2,2,140);f.ships.push({u:38,v:18},{u:38,v:31});}
 if(part==='B'){prop('materiais',6,11);prop('banca',14,30,3,2,170);prop('materiais',35,13);f.ships.push({u:34,v:24});}
 if(part==='C'){prop('mastro',20,5,2,2,180);prop('materiais',11,22);prop('banca',12,28,3,2,170);f.ships.push({u:38,v:26});}
 E('entrada','Chegada Cais '+part,25,37);
 E('saida',part==='A'?'Kronasta':'Voltar',25,39,{destino:part==='A'?'kronasta':id(part==='B'?'A':'B'),chegada_u:25,chegada_v:2});
 if(part!=='C')E('saida','Próxima doca',25,0,{destino:id(part==='A'?'B':'C'),chegada_u:25,chegada_v:37});
 const rewards=part==='A'?[[18,7],[39,24],[18,31]]:part==='B'?[[15,12],[36,16],[18,32]]:[[18,7],[31,30],[8,25]];
 rewards.forEach(([u,v],n)=>E('item',['Material escondido','Linha guardada','Cola de reparo'][n],u,v,{item:['papel-seda','linha-encerada','cola-reparo'][n],quantidade:2,visibilidade:n===0?'escondido':'brilho'}));
 // Edge rails only where geometry already blocks movement; stairs/doors remain open.
 for(let v=4;v<36;v++)for(let u=4;u<42;u++){
  const c=I(u,v);if(level[c]<1||ramp.has(c)||mat[c]==='agua')continue;
  for(const [du,dv,side]of [[1,0,'u'],[0,1,'v']]){
   const j=I(u+du,v+dv);if(ramp.has(j))continue;
   if(level[j]<level[c]&&(mat[j]==='agua'||level[c]>1))f.guards.push({u,v,side});
  }
 }
 for(const [name,u,v]of [['praca',24,30],['patamar',15,12],['margem',33,23],['saida',25,3]])f.shots.push({name,u,v,zoom:1,kind:'jogo'});
 const raw={type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,properties:props({nome:'Cais Velho · '+part,regras:'overworld-1',bioma:'floresta',cena_jogo:id(part),regiao:'cais',parte:part,trajetoria:'1',rampa_comprimento:2,forest:JSON.stringify(f)}),tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'},heights],layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(m=>gid[m])},{name:'altura',type:'tilelayer',width:W,height:H,data:level.map((l,i)=>101+l+(ramp.has(i)?8:0))},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]};
 return {id:id(part),part,raw,feature:f};
}
export function generateCais(){
 const parts=['A','B','C'].map(caisPart),region=parts.map(p=>({id:p.id,part:p.part,map:parseTiled(p.raw,{'rascunho.tsj':source})}));
 const links=[['A','B'],['B','C']].map(([a,b])=>({from:{area:id(a),u:25,v:0,direction:'v-'},to:{area:id(b),u:25,v:39,direction:'v+'}}));
 const dir=root+'documentation/overworld/cais';fs.mkdirSync(dir+'/relatorios',{recursive:true});
 for(const p of parts){
  const m=region.find(r=>r.id===p.id).map,r=auditZeroBreak(m,{region,links,guards:p.feature.guards,requiredRoute:[m.spawn,...m.events]});
  console.log(p.id+'\n'+r.lines.join('\n'));if(!r.ok)throw Error(JSON.stringify(r.issues.filter(i=>i.level==='fail')));
  fs.writeFileSync(root+'art/overworld/mapas/'+p.id+'.tmj',JSON.stringify(p.raw,null,1)+'\n');
  const out=compile(p.raw,p.id);fs.writeFileSync(root+'godot/assets/overworld/maps/'+p.id+'.json',JSON.stringify(out));
  writeCapturePlan(out,p.feature,'documentation/overworld/cais');fs.writeFileSync(dir+'/relatorios/'+p.id+'.json',JSON.stringify(r,null,2)+'\n');
 }
 const file=root+'godot/assets/overworld/maps/index.json',index=JSON.parse(fs.readFileSync(file));
 for(const p of parts){index.areas=index.areas.filter(a=>a.id!==p.id);index.areas.push({id:p.id,name:'Cais Velho · '+p.part,scene:p.id,biome:'floresta'});index.scenes[p.id]=p.id;}
 fs.writeFileSync(file,JSON.stringify(index,null,2)+'\n');return parts;
}
if(process.argv[1]===fileURLToPath(import.meta.url))generateCais();

