import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {parseTiled,audit,verdict,reachable,walkable} from './model.mjs';
import {compile} from '../import-overworld.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
import {writeCapturePlan} from './capturas-bosque.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),ts=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
const G=Object.fromEntries(ts.tiles.filter(t=>t.id<16).map(t=>[t.properties[0].value,t.id+1]));
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
const W=48,H=40,outputs=[];
for(const part of ['A','B','C']){
 const id='kronasta-beira-canal-'+part.toLowerCase(),mat=Array(W*H).fill('grama'),level=Array(W*H).fill(0),ramps=Array(W*H).fill(0),pieces=[],events=[];let oid=0;
 const I=(u,v)=>v*W+u;
 const rect=(u,v,w,h,m=null,l=null)=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++)if(x>=0&&y>=0&&x<W&&y<H){if(m)mat[I(x,y)]=m;if(l!==null)level[I(x,y)]=l;}};
 const obj=(type,name,u,v,p={})=>({id:++oid,name,type,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 const E=(t,n,u,v,p={})=>events.push(obj(t,n,u,v,p));
 const P=(asset,n,u,v,p={})=>pieces.push(obj('peca',n,u,v,{asset,...p}));
 const feature={canal:true,nativeProps:true,stairs:[],guards:[],shots:[],landmark:null};
 rect(0,0,18,H,null,1);rect(30,0,18,H,null,1);
 rect(0,0,W,4,'bosque');rect(0,36,W,4,'bosque');rect(0,0,4,H,'bosque');rect(44,0,4,H,'bosque');
 rect(22,0,5,H,'terra',0);rect(19,29,11,6,'piso',0);rect(19,8,11,7,'piso',0);
 const access=(u,v,base,width=3)=>{rect(u,v-2,width,2,'piso',base+1);rect(u,v,width,4,'terra',base);for(let x=u;x<u+width;x++)ramps[I(x,v)]=base===1?124:24;feature.stairs.push({u,v,width,length:2});};
 rect(12,30,11,3,'terra',0);access(12,28,0);rect(26,30,11,3,'terra',0);access(34,28,0);
 for(const [u,v,color]of [[6,6,'azul'],[6,19,'creme'],[37,6,'coral'],[37,20,'azul']]){rect(u,v,4,4,'piso',1);P('bambuzal-casa','Casa do canal',u,v,{pegada:'4x4',bloqueia:true,variante:color});}
 rect(10,23,5,4,'mato',1);rect(34,23,5,3,'mato',1);
 if(part==='B'){rect(5,7,9,9,'grama',2);access(10,16,1);P('banco','Banco da oficina',20,31,{pegada:'2x1',bloqueia:true});E('descanso','Descansar na oficina',22,30,{acao:'districtRest',district:'beira-canal'});}
 if(part==='C'){
  rect(16,4,16,12,'piso',1);rect(16,4,16,6,'piso',2);rect(16,0,16,4,'bosque',2);
  access(22,16,0,4);access(22,10,1,4);
  for(let u=16;u<32;u++)if(u<22||u>=26)feature.guards.push({u,v:9,side:'v'});
  for(let v=4;v<10;v++)feature.guards.push({u:31,v,side:'u'});
  E('saida','Atalho de retorno',27,37,{destino:'kronasta',requer:'beira-canal',atalho:true});rect(25,35,4,5,'terra',0);
 }
 const waterV=part==='C'?24:18;
 rect(18,waterV,12,6,'agua',0);rect(23,waterV,4,6,'ponte',0);
 feature.water={contour:[[18,waterV],[30,waterV],[30,waterV+6],[18,waterV+6]],channel:[],depth:12,channelDepth:12,bridge:{u:23,v:waterV,w:4,h:6}};
 for(const v of [waterV-.5,waterV+6.5])for(const u of [18,23,27,30])feature.shots.push({name:`margem-${u}-${v}`,u,v});
 const duel=(n,name,u,v)=>E('npc',name,u,v,{district:'beira-canal',duel:'beira-canal-'+n,npcId:n===5?'kleie':'canal-'+n,acao:'districtDuel',fala:name,texto:'O canal precisa voltar a correr. Vamos voar?',canalNpc:n});
 if(part==='A'){duel(1,'Vaeli',24,33);duel(2,'Noxen',25,12);}
 if(part==='B'){duel(3,'Soryn',24,33);duel(4,'Eriska',25,12);E('pista','Pressão interrompida',20,12,{acao:'canalClue',texto:'A água está represada. O controle principal fica nas Veredas.'});}
 if(part==='C')duel(5,'Kleie',24,6);
 P('canal-bomba',part==='B'?'Oficina hidráulica':'Bomba de água',19,10,{pegada:'2x2',bloqueia:true});
 P('canal-bobinas','Material de manutenção',32,13,{pegada:'2x1',bloqueia:true});
 E('entrada','Chegada Beira-Canal '+part,24,37);
 E('saida',part==='A'?'Kronasta':'Voltar',24,39,{destino:part==='A'?'kronasta':'kronasta-beira-canal-'+(part==='B'?'a':'b'),chegada_u:24,chegada_v:2});
 if(part!=='C')E('saida','Próxima parte',24,0,{destino:'kronasta-beira-canal-'+(part==='A'?'b':'c'),chegada_u:24,chegada_v:37});
 E('item','Papel guardado',16,14,{item:'papel-seda',quantidade:2,visibilidade:'escondido'});
 E('item','Linha de reparo',33,18,{item:'linha-encerada',quantidade:2,visibilidade:'brilho'});
 E('item','Cola',27,33,{item:'cola-reparo',quantidade:1,visibilidade:'visivel'});
 if(part==='B')E('item','Material no desvio de Planar',28,16,{item:'papel-seda',quantidade:3,visibilidade:'brilho'});
 for(const [u,v]of [[5,32],[6,32],[5,31],[41,31],[42,31],[41,30],[5,12],[5,13]])P('arvore','Massa de árvores',u,v,{bloqueia:false});
 for(let v=0;v<H;v+=3)for(let u=0;u<W-1;u+=3)if(mat[I(u,v)]==='bosque'&&mat[I(u+1,v)]==='bosque'&&Math.abs(u-24)>5){P('arvore','Mata de moldura',u,v,{bloqueia:false});P('arvore','Mata de moldura',u+1,v,{bloqueia:false});}
 const raw=()=>({type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,properties:props({nome:'Beira-Canal · '+part,regras:'overworld-1',bioma:'floresta',cena_jogo:id,regiao:'beira-canal',parte:part,trajetoria:'1',rampa_comprimento:2,forest:JSON.stringify(feature)}),tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'},{firstgid:101,name:'rampa-v-menos-nivel1',tilewidth:64,tileheight:32,tilecount:24,columns:8,image:'../tiles/rascunho.png',imagewidth:512,imageheight:96,tiles:[{id:23,properties:props({nivel:1,rampa:'v-'})}]}],layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(x=>G[x])},{name:'altura',type:'tilelayer',width:W,height:H,data:level.map((l,i)=>ramps[i]||(l?16+l:0))},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]});
 let m=parseTiled(raw(),{'rascunho.tsj':ts}),seen=reachable(m,m.spawn);
 for(let v=0;v<H;v++)for(let u=0;u<W;u++)if(walkable(m,u,v)&&!seen[I(u,v)])mat[I(u,v)]='bosque';
 const data=raw();m=parseTiled(data,{'rascunho.tsj':ts});if(verdict(audit(m))==='fail')throw Error(id+JSON.stringify(audit(m).filter(x=>x.level==='fail')));
 outputs.push({id,part,map:m,data,out:compile(data,id),feature});
}
const region=outputs.map(x=>({id:x.id,part:x.part,map:x.map})),links=[['a','b'],['b','c']].map(([a,b])=>({from:{area:'kronasta-beira-canal-'+a,u:24,v:0,direction:'v-'},to:{area:'kronasta-beira-canal-'+b,u:24,v:39,direction:'v+'}}));
const reports=[];
for(const x of outputs){const report=auditZeroBreak(x.map,{region,links,guards:x.feature.guards});console.log(x.id+'\n'+report.lines.join('\n'));if(!report.ok)throw Error(x.id+' reprovado');reports.push({id:x.id,...report});fs.writeFileSync(root+'art/overworld/mapas/'+x.id+'.tmj',JSON.stringify(x.data,null,1)+'\n');fs.writeFileSync(root+'godot/assets/overworld/maps/'+x.id+'.json',JSON.stringify(x.out));writeCapturePlan(x.out,x.feature,'documentation/overworld/beira-canal');}
const ip=root+'godot/assets/overworld/maps/index.json',index=JSON.parse(fs.readFileSync(ip));for(const x of outputs){index.scenes[x.id]=x.id;index.areas=index.areas.filter(a=>a.id!==x.id);index.areas.push({id:x.id,name:x.out.name,scene:x.id,biome:'floresta'});}fs.writeFileSync(ip,JSON.stringify(index,null,2)+'\n');fs.writeFileSync(root+'documentation/overworld/beira-canal/conferencia.json',JSON.stringify(reports,null,2)+'\n');
