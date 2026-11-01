import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {parseTiled,audit,verdict,reachable,walkable} from './model.mjs';
import {compile} from '../import-overworld.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
import {writeCapturePlan} from './capturas-bosque.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
const ts=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
const G=Object.fromEntries(ts.tiles.filter(t=>t.id<16).map(t=>[t.properties[0].value,t.id+1]));
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
const W=48,H=40,outputs=[];
for(const part of ['A','B','C']){
 const id='kronasta-feira-'+part.toLowerCase(),mat=Array(W*H).fill('grama'),levels=Array(W*H).fill(0),ramps=Array(W*H).fill(0),pieces=[],events=[];let oid=0;
 const I=(u,v)=>v*W+u;
 const rect=(u,v,w,h,m=null,l=null)=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++){if(m)mat[I(x,y)]=m;if(l!==null)levels[I(x,y)]=l;}};
 const obj=(type,name,u,v,p={})=>({id:++oid,name,type,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 const E=(t,n,u,v,p={})=>events.push(obj(t,n,u,v,p));
 const P=(a,n,u,v,p={})=>pieces.push(obj('peca',n,u,v,{asset:a,...p}));
 const f={market:true,nativeProps:true,stairs:[],guards:[],shots:[]};
 rect(0,0,18,H,null,1);rect(32,0,16,H,null,1);
 rect(0,0,W,4,'bosque');rect(0,36,W,4,'bosque');rect(0,0,4,H,'bosque');rect(44,0,4,H,'bosque');
 rect(22,0,5,H,'piso',0);rect(18,22,14,12,'piso',0);rect(18,8,14,8,'piso',0);
 const stair=(u,v,base,width=4)=>{rect(u,v-2,width,2,'piso',base+1);rect(u,v,width,4,'terra',base);for(let x=u;x<u+width;x++)ramps[I(x,v)]=base===1?124:24;f.stairs.push({u,v,width,length:2});};
 rect(12,30,11,3,'piso',0);stair(12,28,0);
 rect(26,30,12,3,'piso',0);stair(35,28,0);
 const stall=(u,v,color='coral')=>{P('feira-banca','Banca da feira',u,v,{pegada:'3x2',bloqueia:true,variante:color});f.shots.push({name:`banca-${u}-${v}`,u:u+1.5,v:v+2,zoom:1,kind:'jogo'});};
 for(const [u,v,color]of [[6,5,'azul'],[7,19,'creme'],[37,5,'coral'],[38,19,'azul']])P('bambuzal-casa','Casa da feira',part==='B'&&u===6?35:u,part==='B'&&u===6?10:v,{pegada:'4x4',bloqueia:true,variante:color});
 rect(10,24,5,3,'mato',1);rect(36,24,5,2,'mato',1);
 if(part==='A'){stall(18,24);stall(28,24,'teal');stall(18,9,'ochre');stall(28,9);stall(12,19,'teal');stall(34,19,'ochre');}
 if(part==='B'){
  rect(5,5,11,12,'piso',2);stair(11,17,1);
  for(let u=5;u<16;u++)if(u<11||u>=15)f.guards.push({u,v:16,side:'v'});
  for(let v=5;v<17;v++)f.guards.push({u:15,v,side:'u'});
  stall(6,7,'ochre');stall(12,7,'teal');stall(6,12);stall(18,24,'teal');stall(28,24);stall(33,15,'ochre');
  P('banco','Banco do descanso',19,30,{pegada:'2x1',bloqueia:true});
  E('interacao','Descanso do mercado',21,31,{acao:'feiraRestPreview',texto:'Ponto seguro do mercado. Serviço de descanso será integrado na etapa narrativa.'});
  E('npc','Grampo',34,17,{storySpritePath:'res://assets/campaign/beira-canal-v1/grampo.png',fala:'Grampo',texto:'Você está procurando alguma coisa?',preview:true});
 }
 if(part==='C'){
  rect(16,4,16,13,'piso',1);rect(16,4,16,6,'piso',2);rect(16,0,16,4,'bosque',2);
  stair(22,17,0);stair(22,10,1);
  for(let u=16;u<32;u++)if(u<22||u>=26)f.guards.push({u,v:9,side:'v'});
  for(let v=4;v<10;v++)f.guards.push({u:31,v,side:'u'});
  stall(17,6,'ochre');stall(28,6,'teal');stall(18,25);stall(28,25,'ochre');
  E('saida','Retorno à praça',27,37,{destino:'kronasta-feira-a',chegada_u:24,chegada_v:37,requer:'feira',atalho:true});rect(25,35,4,5,'piso',0);
 }
 const npc=(name,u,v,n)=>E('npc',name,u,v,{fala:name,texto:'Estamos preparando o campeonato da Feira do Largo.',preview:true,futureDuel:'feira-'+n});
 if(part==='A'){npc('Veyra',24,31,1);npc('Orven',24,12,2);E('npc','Seu Lalau',20,26,{fala:'Seu Lalau',texto:'Apitos e novidades do mercado.',preview:true});}
 if(part==='B'){npc('Zafri',24,31,3);npc('Nymel',24,12,4);}
 if(part==='C')npc('Dona Zulmira',24,6,5);
 E('entrada','Chegada Feira '+part,24,37);
 E('saida',part==='A'?'Kronasta':'Voltar',24,39,{destino:part==='A'?'kronasta':'kronasta-feira-'+(part==='B'?'a':'b'),chegada_u:24,chegada_v:2});
 if(part!=='C')E('saida','Próxima parte',24,0,{destino:'kronasta-feira-'+(part==='A'?'b':'c'),chegada_u:24,chegada_v:37});
 E('item','Papel guardado',16,14,{item:'papel-seda',quantidade:2,visibilidade:'escondido'});
 E('item','Linha de reparo',33,21,{item:'linha-encerada',quantidade:2,visibilidade:'brilho'});
 E('item','Cola',27,33,{item:'cola-reparo',quantidade:1,visibilidade:'visivel'});
 for(let v=0;v<H;v+=3)for(let u=0;u<W-1;u+=3)if(mat[I(u,v)]==='bosque'&&mat[I(u+1,v)]==='bosque'&&Math.abs(u-24)>5){P('arvore','Moldura',u,v,{bloqueia:false});P('arvore','Moldura',u+1,v,{bloqueia:false});}
 const raw=()=>({type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,properties:props({nome:'Feira do Largo · '+part,regras:'overworld-1',bioma:'floresta',cena_jogo:id,regiao:'feira',parte:part,trajetoria:'1',rampa_comprimento:2,forest:JSON.stringify(f)}),tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'},{firstgid:101,name:'rampa-v-menos-nivel1',tilewidth:64,tileheight:32,tilecount:24,columns:8,image:'../tiles/rascunho.png',imagewidth:512,imageheight:96,tiles:[{id:23,properties:props({nivel:1,rampa:'v-'})}]}],layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(x=>G[x])},{name:'altura',type:'tilelayer',width:W,height:H,data:levels.map((l,i)=>ramps[i]||(l?16+l:0))},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]});
 for(const piece of pieces.filter(p=>p.properties.some(x=>x.name==='asset'&&x.value==='feira-banca'))){
  const u=Math.floor(piece.x/32),v=Math.floor(piece.y/32),base=levels[I(u,v)];
  for(let y=v;y<v+2;y++)for(let x=u;x<u+3;x++)if(levels[I(x,y)]!==base||ramps[I(x,y)])throw Error(id+' banca sem apoio plano '+u+','+v);
 }
 let m=parseTiled(raw(),{'rascunho.tsj':ts}),seen=reachable(m,m.spawn);
 for(let v=0;v<H;v++)for(let u=0;u<W;u++)if(walkable(m,u,v)&&!seen[I(u,v)])mat[I(u,v)]='bosque';
 const data=raw();m=parseTiled(data,{'rascunho.tsj':ts});if(verdict(audit(m))==='fail')throw Error(id+JSON.stringify(audit(m).filter(x=>x.level==='fail')));
 outputs.push({id,part,map:m,data,out:compile(data,id),feature:f});
}
const region=outputs.map(x=>({id:x.id,part:x.part,map:x.map}));
const links=[['a','b'],['b','c']].map(([a,b])=>({from:{area:'kronasta-feira-'+a,u:24,v:0,direction:'v-'},to:{area:'kronasta-feira-'+b,u:24,v:39,direction:'v+'}}));
const reports=[];
for(const x of outputs){const r=auditZeroBreak(x.map,{region,links,guards:x.feature.guards});console.log(x.id+'\n'+r.lines.join('\n'));if(!r.ok)throw Error(x.id+' reprovado');reports.push({id:x.id,...r});}
for(const x of outputs){fs.writeFileSync(root+'art/overworld/mapas/'+x.id+'.tmj',JSON.stringify(x.data,null,1)+'\n');fs.writeFileSync(root+'godot/assets/overworld/maps/'+x.id+'.json',JSON.stringify(x.out));writeCapturePlan(x.out,x.feature,'documentation/overworld/feira');}
const ip=root+'godot/assets/overworld/maps/index.json',index=JSON.parse(fs.readFileSync(ip));for(const x of outputs){index.scenes[x.id]=x.id;index.areas=index.areas.filter(a=>a.id!==x.id);index.areas.push({id:x.id,name:x.out.name,scene:x.id,biome:'floresta'});}fs.writeFileSync(ip,JSON.stringify(index,null,2)+'\n');fs.writeFileSync(root+'documentation/overworld/feira/conferencia.json',JSON.stringify(reports,null,2)+'\n');



