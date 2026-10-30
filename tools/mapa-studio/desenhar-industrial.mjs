import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {parseTiled,reachable,walkable} from './model.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
import {compile} from '../import-overworld.mjs';
import {writeCapturePlan} from './capturas-bosque.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),W=48,H=40;
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
const names=['Pátio de Cargas','Canal das Caldeiras','Usina do Vento'];
const id=p=>'kronasta-industrial-'+p.toLowerCase();
const ts=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
const gid=Object.fromEntries(ts.tiles.filter(t=>t.id<16).map(t=>[t.properties[0].value,t.id+1]));
export function industrialPart(part){
 const mat=Array(W*H).fill('grama'),height=Array(W*H).fill(0),ramps=Array(W*H).fill(0),pieces=[],events=[];let next=1;
 const ix=(u,v)=>v*W+u,inside=(u,v)=>u>=0&&v>=0&&u<W&&v<H;
 const rect=(u,v,w,h,m=null,l=null)=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++)if(inside(x,y)){if(m)mat[ix(x,y)]=m;if(l!==null)height[ix(x,y)]=l;}};
 const path=(points,width=4)=>{for(let n=1;n<points.length;n++){const a=points[n-1],b=points[n],s=Math.ceil(Math.hypot(b[0]-a[0],b[1]-a[1])*3);for(let k=0;k<=s;k++)rect(Math.round(a[0]+(b[0]-a[0])*k/s)-Math.floor(width/2),Math.round(a[1]+(b[1]-a[1])*k/s)-Math.floor(width/2),width,width,'terra',0);}};
 const obj=(type,name,u,v,p={})=>({id:next++,name,type,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 const event=(type,name,u,v,p)=>events.push(obj(type,name,u,v,p));
 const piece=(asset,name,u,v,w,h,p={})=>pieces.push(obj('peca',name,u,v,{asset,pegada:w+'x'+h,...p}));
 rect(0,0,W,4,'rocha',1);rect(0,H-4,W,4,'rocha');rect(0,0,4,H,'rocha',1);rect(W-4,0,4,H,'rocha',0);
 rect(4,4,16,24,null,1);rect(20,4,12,12,null,1);rect(38,4,6,28,null,1);
 const start=part==='B'?36:8;
 path([[start,39],[start,32],[30,30],[36,24],[36,part==='C'?8:0]]);
 path([[start,32],[13,31]],3);path([[30,30],[25,19]],3);path([[36,29],[41,30]],3);
 for(let v=0;v<H;v+=2)for(let u=0;u<W;u+=2){const cells=[ix(u,v),ix(u+1,v),ix(u,v+1),ix(u+1,v+1)];if(cells.some(i=>height[i]===0))for(const i of cells)height[i]=0;}
 const access=(u,v,width=2)=>{for(let x=u;x<u+width;x++){rect(x,v-2,1,2,'grama',1);rect(x,v,1,4,'terra',0);ramps[ix(x,v)]=24;}};
 access(12,28,3);access(24,16);access(40,28);
 if(part==='C')path([[36,39],[36,32]],4);
 const feature={nativeProps:true,industrial:true,followTrail:true,stairs:[{u:12,v:28,width:3,length:2}],guards:[],buildings:[],shots:[]};
 const building=(name,u,v,w,h,z,style)=>{piece('industrial-volume',name,u,v,w,h,{style});feature.buildings.push({name,u,v,w,h,z,style});feature.shots.push({name:'implantacao-'+feature.buildings.length,u:u+w/2,v:v+h,zoom:2.3});};
 building(part==='C'?'Usina':'Galpão de manutenção',6,5,10,7,128,part==='C'?'usina':'galpao');
 building('Depósito de peças',23,5,6,6,80,'galpao');
 building('Carga azul',6,21,4,3,52,'container');building('Carga ocre',16,21,3,4,52,'container');
 building(part==='B'?'Caldeiras':'Gerador do pátio',39,18,3,4,76,'caldeira');
 // The source footprint owns collision, while illustrated surfaces only dress it.
 for(let u=4;u<20;u++)if(u<12||u>14)feature.guards.push({u,v:27,side:'v'});
 if(part==='B'){
  const channel=[[28,18],[38,18],[38,24],[28,24]];
  rect(28,18,10,6,'agua',0);rect(34,18,4,6,'ponte',0);rect(34,16,4,2,'terra',0);rect(34,24,4,3,'terra',0);
  feature.water={contour:[],channel,depth:12,channelDepth:12,bridge:{u:34,v:18,w:4,h:6}};
  channel.forEach(([u,v],n)=>feature.shots.push({name:'canal-canto-'+n,u,v,zoom:2.3}));
  feature.shots.push({name:'canal-margem-norte',u:28,v:18,zoom:2.3},{name:'canal-margem-sul',u:31,v:24,zoom:2.3},{name:'canal-ponta-oeste',u:28,v:21,zoom:2.3},{name:'canal-ponta-leste',u:38,v:21,zoom:2.3},{name:'passarela-norte',u:36,v:17.5,zoom:2.3},{name:'passarela-sul',u:36,v:24.5,zoom:2.3});
 }
 event('entrada','Entrada de serviço',start,36,{});
 if(part!=='A')event('saida','Voltar à parte anterior',36,39,{destino:id(String.fromCharCode(part.charCodeAt(0)-1)),chegada_u:36,chegada_v:2});
 if(part!=='C')event('saida','Seguir pelo distrito',36,0,{destino:id(String.fromCharCode(part.charCodeAt(0)+1)),chegada_u:36,chegada_v:36});
 if(part==='C')event('saida','Atalho ao Pátio de Cargas',8,39,{destino:id('A'),chegada_u:8,chegada_v:36});
 for(const [name,u,v,item,vis]of [['Material na doca',18,25,'papel-seda','brilho'],['Peças atrás da carga',5,25,'vareta-bambu','escondido'],['Cola na plataforma',42,28,'cola-reparo','brilho']])event('item',name,u,v,{item,quantidade:1,visibilidade:vis,trajetoria:'ambas'});
 event('interacao','Banco da manutenção',21,25,{texto:'Um canto tranquilo junto à doca. Prévia sem recuperação ou recompensas.'});
 piece('banco','Banco da manutenção',21,24,2,1);
 feature.guards=feature.guards.filter(g=>height[ix(g.u,g.v)]>height[ix(g.u,g.v+1)]&&!ramps[ix(g.u,g.v)]&&!ramps[ix(g.u,g.v+1)]);
 feature.shots.push({name:'doca-principal',u:12,v:22,zoom:1,kind:'jogo'},{name:'deposito',u:26,v:11,zoom:1,kind:'jogo'},{name:'maquinas',u:41,v:25,zoom:1,kind:'jogo'});
 const raw=()=>({type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,nextobjectid:next,properties:props({nome:'Distrito Industrial · '+names[part.charCodeAt(0)-65],regras:'overworld-1',bioma:'parque',cena_jogo:id(part),regiao:'distrito-industrial',parte:part,trajetoria:'ambas',rampa_comprimento:2,forest:JSON.stringify(feature)}),tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'}],layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(m=>gid[m])},{name:'altura',type:'tilelayer',width:W,height:H,data:height.map((l,i)=>ramps[i]||(l?16+l:0))},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]});
 const m=parseTiled(raw(),{'rascunho.tsj':ts}),seen=reachable(m,m.spawn);
 for(let v=0;v<H;v++)for(let u=0;u<W;u++)if(walkable(m,u,v)&&!seen[ix(u,v)])mat[ix(u,v)]='rocha';
 return {id:id(part),part,raw:raw(),feature};
}
export function generateIndustrial(){
 const parts=['A','B','C'].map(industrialPart),region=parts.map(p=>({id:p.id,part:p.part,map:parseTiled(p.raw,{'rascunho.tsj':ts})}));
 const links=[['A','B'],['B','C']].map(([a,b])=>({from:{area:id(a),u:36,v:0,direction:'v-'},to:{area:id(b),u:36,v:39,direction:'v+'}}));
 for(const p of parts){const result=auditZeroBreak(region.find(r=>r.id===p.id).map,{region,links,guards:p.feature.guards});console.log(p.id+'\n'+result.lines.join('\n'));if(!result.ok)throw Error(p.id+' rejected');
  fs.writeFileSync(root+'art/overworld/mapas/'+p.id+'.tmj',JSON.stringify(p.raw,null,1)+'\n');fs.writeFileSync(root+'godot/assets/overworld/maps/'+p.id+'.json',JSON.stringify(compile(p.raw,p.id)));
  writeCapturePlan(compile(p.raw,p.id),p.feature,'documentation/overworld/industrial');
  fs.mkdirSync(root+'documentation/overworld/industrial/relatorios',{recursive:true});fs.writeFileSync(root+'documentation/overworld/industrial/relatorios/'+p.id+'-auditoria.json',JSON.stringify(result,null,2)+'\n');
 }
 const path=root+'godot/assets/overworld/maps/index.json',index=JSON.parse(fs.readFileSync(path));
 for(const p of parts){index.areas=index.areas.filter(a=>a.id!==p.id);index.areas.push({id:p.id,name:'Distrito Industrial · '+names[p.part.charCodeAt(0)-65],scene:p.id,biome:'parque'});index.scenes[p.id]=p.id;}fs.writeFileSync(path,JSON.stringify(index,null,2)+'\n');
 return parts;
}
if(process.argv[1]===fileURLToPath(import.meta.url))generateIndustrial();
