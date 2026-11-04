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
const id=p=>'kronasta-mirante-'+p.toLowerCase();
export function mirantePart(part){
 const mat=Array(W*H).fill('agua'),level=Array(W*H).fill(0),ramp=new Set(),events=[],pieces=[];let oid=0;
 const I=(u,v)=>v*W+u;
 const rect=(u,v,w,h,m='piso',l=1)=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++){mat[I(x,y)]=m;level[I(x,y)]=l;}};
 const obj=(type,name,u,v,p={})=>({id:++oid,type,name,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 const E=(t,n,u,v,p={})=>events.push(obj(t,n,u,v,p));
 const previous=JSON.parse(fs.readFileSync(root+'godot/assets/overworld/maps/'+id(part)+'.json'));
 const f={closedStairs:true,nativeProps:true,stairs:[],guards:[],shots:[]};
 mat.fill('bosque');
 rect(22,0,5,40);
 const outlines={
  A:[[16,26,16,10],[19,13,12,13],[19,4,15,9]],
  B:[[20,26,10,10],[14,19,22,7],[17,13,16,6],[19,4,15,9]],
  C:[[20,24,11,15],[15,8,20,16],[19,4,12,4]],
 };
 for(const [u,v,w,h] of outlines[part])rect(u,v,w,h);
 const top=part==='C'?22:8;
 rect(part==='C'?15:19,4,part==='C'?20:15,top-4,'piso',2);
 rect(22,0,5,4,part==='C'?'bosque':'piso',part==='C'?0:2);
 rect(22,top,5,3,'terra',1);
 for(let u=22;u<27;u++)ramp.add(I(u,top));
 const offset=['A','B','C'].indexOf(part); for(let i=0;i<level.length;i++)if(level[i]>0)level[i]+=offset;
 f.stairs.push({u:22,v:top,width:5,length:2});
 for(const e of previous.events.filter(e=>e.type!=="item")){
  const event=obj(e.type,e.type==='entrada'?'Chegada ao Mirante '+part:e.name,e.u,e.v,e.props);
  event.id=e.id;
  events.push(event);
 }
 const loot=[[21,33],[28,28],[23,5]];
 for(let n=0;n<loot.length;n++){
  const [u,v]=loot[n];
  if(mat[I(u,v)]==='bosque')continue;
  const item=obj('item','Material do Mirante',u,v,{item:['papel-seda','linha-encerada','cola-reparo'][n],quantidade:1,visibilidade:n===0?'escondido':'brilho'});
  item.id=100+n;events.push(item);
 }
 for(const [name,u,v] of [['chegada',24,33],['escada',24,top],['praca',24,17],['topo',24,6]])f.shots.push({name,u,v,zoom:1,kind:'jogo'});
 const raw={type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,properties:props({nome:'Alto do Mirante · '+part,regras:'overworld-1',bioma:'floresta',cena_jogo:id(part),regiao:'mirante',parte:part,trajetoria:'1',rampa_comprimento:2,forest:JSON.stringify(f)}),tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'},heights],layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(m=>gid[m])},{name:'altura',type:'tilelayer',width:W,height:H,data:level.map((l,i)=>101+l+(ramp.has(i)?8:0))},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]};
 return {id:id(part),part,raw,feature:f};
}
export function generateMirante(){
 const parts=['A','B','C'].map(mirantePart),region=parts.map(p=>({id:p.id,part:p.part,map:parseTiled(p.raw,{'rascunho.tsj':source})}));
 const links=[['A','B'],['B','C']].map(([a,b])=>({from:{area:id(a),u:25,v:0,direction:'v-'},to:{area:id(b),u:25,v:39,direction:'v+'}}));
 const dir=root+'documentation/overworld/mirante';fs.mkdirSync(dir+'/relatorios',{recursive:true});
 for(const p of parts){
  const m=region.find(r=>r.id===p.id).map,r=auditZeroBreak(m,{region,links,guards:p.feature.guards,requiredRoute:[m.spawn,...m.events]});
  console.log(p.id+'\n'+r.lines.join('\n'));if(!r.ok)throw Error(JSON.stringify(r.issues.filter(i=>i.level==='fail')));
  fs.writeFileSync(root+'art/overworld/mapas/'+p.id+'.tmj',JSON.stringify(p.raw,null,1)+'\n');
  const out=compile(p.raw,p.id);fs.writeFileSync(root+'godot/assets/overworld/maps/'+p.id+'.json',JSON.stringify(out));
  writeCapturePlan(out,p.feature,'documentation/overworld/mirante');fs.writeFileSync(dir+'/relatorios/'+p.id+'.json',JSON.stringify(r,null,2)+'\n');
 }
 const file=root+'godot/assets/overworld/maps/index.json',index=JSON.parse(fs.readFileSync(file));
 for(const p of parts){index.areas=index.areas.filter(a=>a.id!==p.id);index.areas.push({id:p.id,name:'Alto do Mirante · '+p.part,scene:p.id,biome:'floresta'});index.scenes[p.id]=p.id;}
 fs.writeFileSync(file,JSON.stringify(index,null,2)+'\n');return parts;
}
if(process.argv[1]===fileURLToPath(import.meta.url))generateMirante();

