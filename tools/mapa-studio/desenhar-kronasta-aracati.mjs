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
const id=p=>'kronasta-aracati-'+p.toLowerCase();
export function aracatiPart(part){
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
  mat.fill('agua');level.fill(0);
  f.closedStairs=true;
  rect(21,36,10,4,'terra',1);
  rect(23,30,5,6,'ponte',1);
  rect(12,26,24,4,'terra',1);
  rect(8,20,30,6,'terra',1);
  rect(6,12,30,8,'terra',1);
  rect(8,6,26,6,'terra',1);
  rect(23,0,5,8,'piso',1);
  rect(21,20,10,10,'piso',1);
  rect(15,17,16,7,'piso',1);
  rect(8,8,14,10,'terra',2);stairs(16,18,1);
  rect(16,12,4,6,'piso',2);
  rect(32,20,6,4,'piso',1);
 }
 if(part==='B'){
  f.closedStairs=true;
  rect(4,30,8,6,'agua',0);rect(4,4,4,6,'agua',0);
  rect(34,6,8,14,'piso',1);
  rect(4,4,14,18,'piso',2);stairs(10,22,1);
 }
 if(part==='C'){
  f.closedStairs=true;
  rect(23,0,5,4,'agua',0);rect(4,4,6,7,'agua',0);rect(4,28,3,8,'agua',0);
  rect(14,4,20,18,'piso',2);stairs(22,22,1);
  E('npc','Rabiolava',24,10,{acao:'aracatiTerreiro',bloqueia:false,storySpritePath:'res://assets/overworld/kits/aracati-v1/rabiolava.png'});
  E('npc','Rato',28,11,{acao:'aracatiRato',bloqueia:false,storySpritePath:'res://assets/overworld/kits/camara-do-elo-v1/rato-0.png'});
 }
 E('entrada','Chegada Aracati '+part,25,37);
 E('saida',part==='A'?'Kronasta':'Voltar',25,39,{destino:part==='A'?'kronasta':id(part==='B'?'A':'B'),chegada_u:25,chegada_v:2});
 if(part!=='C')E('saida','Trilha costeira',25,0,{destino:id(part==='A'?'B':'C'),chegada_u:25,chegada_v:37});
 const rewards=part==='A'?[[12,10],[35,22],[25,28]]:part==='B'?[[15,12],[36,16],[18,32]]:[[18,7],[31,30],[8,25]];
 rewards.forEach(([u,v],n)=>E('item',['Material escondido','Linha guardada','Cola de reparo'][n],u,v,{item:['papel-seda','linha-encerada','cola-reparo'][n],quantidade:2,visibilidade:n===0?'escondido':'brilho'}));
 // Edge rails only where geometry already blocks movement; stairs/doors remain open.
 for(let v=4;v<36;v++)for(let u=4;u<42;u++){
  const c=I(u,v);if(level[c]<1||ramp.has(c)||mat[c]==='agua')continue;
  for(const [du,dv,side]of [[1,0,'u'],[0,1,'v']]){
   const j=I(u+du,v+dv);if(ramp.has(j))continue;
   if(level[j]<level[c]&&(level[c]>1||mat[c]==='ponte')&&(mat[j]==='agua'||level[c]>1))f.guards.push({u,v,side});
  }
 }
 for(const [name,u,v]of [['praca',24,30],['patamar',15,12],['margem',33,23],['saida',25,3]])f.shots.push({name,u,v,zoom:1,kind:'jogo'});
 for(const e of events){const id=e.properties?.find(p=>p.name==='npcId')?.value;if(id)e.properties.push({name:'storySpritePath',type:'string',value:'res://assets/npc-ds/cais-v1/'+id+'.png'});}
 const raw={type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,properties:props({nome:'Ilha do Aracati · '+part,regras:'overworld-1',bioma:'floresta',cena_jogo:id(part),regiao:'aracati',parte:part,trajetoria:'2',rampa_comprimento:2,forest:JSON.stringify(f)}),tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'},heights],layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(m=>gid[m])},{name:'altura',type:'tilelayer',width:W,height:H,data:level.map((l,i)=>101+l+(ramp.has(i)?8:0))},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]};
 return {id:id(part),part,raw,feature:f};
}
export function generateAracati(){
 const parts=['A','B','C'].map(aracatiPart),region=parts.map(p=>({id:p.id,part:p.part,map:parseTiled(p.raw,{'rascunho.tsj':source})}));
 const links=[['A','B'],['B','C']].map(([a,b])=>({from:{area:id(a),u:25,v:0,direction:'v-'},to:{area:id(b),u:25,v:39,direction:'v+'}}));
 const dir=root+'documentation/overworld/aracati';fs.mkdirSync(dir+'/relatorios',{recursive:true});
 for(const p of parts){
  const m=region.find(r=>r.id===p.id).map,r=auditZeroBreak(m,{region,links,guards:p.feature.guards,requiredRoute:[m.spawn,...m.events]});
  console.log(p.id+'\n'+r.lines.join('\n'));if(!r.ok)throw Error(JSON.stringify(r.issues.filter(i=>i.level==='fail')));
  fs.writeFileSync(root+'art/overworld/mapas/'+p.id+'.tmj',JSON.stringify(p.raw,null,1)+'\n');
  const out=compile(p.raw,p.id);fs.writeFileSync(root+'godot/assets/overworld/maps/'+p.id+'.json',JSON.stringify(out));
  writeCapturePlan(out,p.feature,'documentation/overworld/aracati');fs.writeFileSync(dir+'/relatorios/'+p.id+'.json',JSON.stringify(r,null,2)+'\n');
 }
 const file=root+'godot/assets/overworld/maps/index.json',index=JSON.parse(fs.readFileSync(file));
 for(const p of parts){index.areas=index.areas.filter(a=>a.id!==p.id);index.areas.push({id:p.id,name:'Ilha do Aracati · '+p.part,scene:p.id,biome:'floresta'});index.scenes[p.id]=p.id;}
 fs.writeFileSync(file,JSON.stringify(index,null,2)+'\n');return parts;
}
if(process.argv[1]===fileURLToPath(import.meta.url))generateAracati();

