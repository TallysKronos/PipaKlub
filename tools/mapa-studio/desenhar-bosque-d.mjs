import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {parseTiled} from './model.mjs';
import {compile} from '../import-overworld.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
import {writeCapturePlan} from './capturas-bosque.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
const source=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
const gid=Object.fromEntries(source.tiles.filter(t=>t.id<16).map(t=>[t.properties[0].value,t.id+1]));
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
const id='kronasta-bosque-d',W=48,H=40,mat=Array(W*H).fill('bosque'),level=Array(W*H).fill(0),ramp=new Set(),pieces=[],events=[];let oid=18000;
const I=(u,v)=>v*W+u;
const rect=(u,v,w,h,m,l)=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++){mat[I(x,y)]=m;level[I(x,y)]=l;}};
const obj=(type,name,u,v,p={})=>({id:++oid,type,name,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
const E=(t,n,u,v,p={})=>events.push(obj(t,n,u,v,p));
rect(4,4,40,32,'grama',1);rect(23,32,4,8,'terra',1);
rect(6,6,16,16,'grama',2);rect(28,6,14,16,'grama',2);
rect(23,8,4,26,'terra',1);rect(10,25,28,4,'terra',1);
const access=(u,v)=>{rect(u,v-2,4,2,'grama',2);rect(u,v,4,4,'terra',1);for(let x=u;x<u+4;x++)ramp.add(I(x,v));};
access(14,22);access(32,22);rect(12,27,6,3,'terra',1);rect(30,27,8,3,'terra',1);
rect(8,6,12,3,'bosque',2);rect(6,6,3,14,'bosque',2);rect(38,6,4,12,'bosque',2);rect(28,6,10,3,'bosque',2);
rect(5,30,4,5,'bosque',1);rect(38,29,6,7,'bosque',1);rect(6,23,4,3,'mato',1);rect(32,31,4,3,'mato',1);
for(let v=0;v<H;v++)for(let u=0;u<W;u++)if(mat[I(u,v)]==='bosque'){
 if(u>=21&&u<=28&&v>=32)continue;
 if((u*7+v*11)%4!==0)pieces.push(obj('peca','Mata em massa',u,v,{asset:'arvore',variante:(u+v)%3?'a':'b'}));
}
E('entrada','Chegada da Clareira do Marco',24,37);
E('saida','Voltar à Clareira do Marco',24,39,{destino:'kronasta-bosque-c',chegada_u:24,chegada_v:2});
E('npc','Retalho',33,12,{acao:'retalhoStory',storySpritePath:'res://assets/campaign/retalho-v1/overworld.png'});
E('item','Papel escondido no mirante',10,12,{item:'papel-seda',quantidade:3,visibilidade:'escondido'});
E('item','Linha na clareira',37,17,{item:'linha-encerada',quantidade:2,visibilidade:'brilho'});
E('item','Cola no desvio',11,30,{item:'cola-reparo',quantidade:2,visibilidade:'visivel'});
const feature={sealBoundary:true,nativeProps:true,stairs:[],guards:[],shots:[{name:'chegada',u:25,v:34,zoom:1},{name:'arena',u:33,v:13,zoom:1},{name:'mirante',u:15,v:14,zoom:1},{name:'laco',u:25,v:26,zoom:1}],water:null,landmark:null};
const heights={...source,firstgid:101,name:'bosque-d-alturas',tiles:[]};for(let n=0;n<4;n++)heights.tiles.push({id:n,properties:props({nivel:n})});heights.tiles.push({id:9,properties:props({nivel:1,rampa:'v-'})});
const raw={type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,properties:props({nome:'Bosque dos Ventos · D',regras:'overworld-1',bioma:'floresta',cena_jogo:id,regiao:'bosque',parte:'D',rampa_comprimento:2,forest:JSON.stringify(feature)}),tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'},heights],layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(m=>gid[m])},{name:'altura',type:'tilelayer',width:W,height:H,data:level.map((l,i)=>ramp.has(i)?110:101+l)},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]};
// Add the north corridor to C reproducibly, preserving every existing object ID.
const cpath=root+'art/overworld/mapas/kronasta-bosque-c.tmj',c=JSON.parse(fs.readFileSync(cpath));
for(let v=0;v<5;v++)for(let u=23;u<27;u++){
 c.layers.find(l=>l.name==='chao').data[v*c.width+u]=gid.terra;
 c.layers.find(l=>l.name==='altura').data[v*c.width+u]=17;
}
c.layers.find(l=>l.name==='pecas').objects=c.layers.find(l=>l.name==='pecas').objects.filter(p=>!(p.x/32>=21&&p.x/32<=29&&p.y/32<5));
const ce=c.layers.find(l=>l.name==='eventos').objects;
if(!ce.some(e=>e.id===18999))ce.push({id:18999,type:'saida',name:'Desvio do Retalho · após o Cais',x:24*32+16,y:16,point:true,properties:props({destino:id,chegada_u:24,chegada_v:37,requer:'cais'})});
const region=['a','b'].map((part)=>{const name='kronasta-bosque-'+part;return{id:name,part:part.toUpperCase(),map:parseTiled(JSON.parse(fs.readFileSync(root+'art/overworld/mapas/'+name+'.tmj')),{'rascunho.tsj':source})};});
region.push({id:'kronasta-bosque-c',part:'C',map:parseTiled(c,{'rascunho.tsj':source})},{id,part:'D',map:parseTiled(raw,{'rascunho.tsj':source})});
const links=[{from:{area:'kronasta-bosque-a',u:24,v:0,direction:'v-'},to:{area:'kronasta-bosque-b',u:24,v:43,direction:'v+'}},{from:{area:'kronasta-bosque-b',u:24,v:0,direction:'v-'},to:{area:'kronasta-bosque-c',u:24,v:43,direction:'v+'}},{from:{area:'kronasta-bosque-c',u:24,v:0,direction:'v-'},to:{area:id,u:24,v:39,direction:'v+'}}];
const report=auditZeroBreak(region[3].map,{region,links,requiredRoute:[region[3].map.spawn,...region[3].map.events]});console.log(report.lines.join('\n'));if(!report.ok)throw Error('Bosque D reprovado');
const dir=root+'documentation/overworld/bosque-d';fs.mkdirSync(dir+'/relatorios',{recursive:true});fs.writeFileSync(dir+'/relatorios/'+id+'.json',JSON.stringify(report,null,2)+'\n');
for(const [name,data]of [[id,raw],['kronasta-bosque-c',c]]){fs.writeFileSync(root+'art/overworld/mapas/'+name+'.tmj',JSON.stringify(data,null,1)+'\n');const out=compile(data,name);fs.writeFileSync(root+'godot/assets/overworld/maps/'+name+'.json',JSON.stringify(out));if(name===id)writeCapturePlan(out,feature,'documentation/overworld/bosque-d');}
const ip=root+'godot/assets/overworld/maps/index.json',index=JSON.parse(fs.readFileSync(ip));index.areas=index.areas.filter(a=>a.id!==id);index.areas.push({id,name:'Bosque dos Ventos · D',scene:id,biome:'floresta'});index.scenes[id]=id;fs.writeFileSync(ip,JSON.stringify(index,null,2)+'\n');
