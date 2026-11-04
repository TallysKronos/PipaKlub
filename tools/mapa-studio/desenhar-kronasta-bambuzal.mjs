// PIP-105: a planta é a fonte única de chão, colisão e apoio; arte nunca abre atalhos.
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
for(const [part,subtitle]of [['A','Praça de Chegada'],['B','Caminho das Varetas'],['C','Arena do Bambuzal']]){
 const id='kronasta-bambuzal-'+part.toLowerCase(),mat=Array(W*H).fill('grama'),level=Array(W*H).fill(0),ramp=Array(W*H).fill(0),pieces=[],events=[];
 let oid=0;
 const I=(u,v)=>v*W+u,inside=(u,v)=>u>=0&&v>=0&&u<W&&v<H;
 const rect=(u,v,w,h,m=null,l=null)=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++)if(inside(x,y)){if(m)mat[I(x,y)]=m;if(l!==null)level[I(x,y)]=l;}};
 const obj=(type,name,u,v,p={})=>({id:++oid,name,type,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 const E=(t,n,u,v,p={})=>events.push(obj(t,n,u,v,p));
 const P=(asset,n,u,v,p={})=>pieces.push(obj('peca',n,u,v,{asset,...p}));
 const feature={bamboo:true,nativeProps:true,stairs:[],guards:[],shots:[],houses:[],cutStumps:[],landmark:null};
 // Long rectangular terraces, broken by broad clear courtyards rather than saw-tooth contours.
 rect(0,0,18,H,null,1);rect(30,0,18,H,null,1);
 rect(0,0,W,4,'bosque');rect(0,H-4,W,4,'bosque');rect(0,0,4,H,'bosque');rect(W-4,0,4,H,'bosque');
 rect(22,0,5,H,'terra',0);
 rect(19,18,11,15,'piso',0);
 const access=(u,v,base,width=3,stairs=false)=>{
  // v−, two ramp cells (expanded by parseTiled); free top and foot landings.
  rect(u,v-2,width,2,stairs?'piso':'grama',base+1);rect(u,v,width,4,'terra',base);
  for(let x=u;x<u+width;x++)ramp[I(x,v)]=base===1?124:24;
  if(stairs)feature.stairs.push({u,v,width,length:2});
  feature.shots.push({name:'acesso-pe-'+u+'-'+v,u:u+width/2,v:v+1.8},{name:'acesso-topo-'+u+'-'+v,u:u+width/2,v:v-.5});
 };
 const sideAccess=()=>{
  rect(12,30,11,3,'terra',0);access(12,28,0,3);
  rect(26,29,11,3,'terra',0);access(34,27,0,3);
 };
 sideAccess();
 const house=(u,v,color)=>{rect(u,v,4,4,'piso',1);P('bambuzal-casa','Casa dos moradores',u,v,{pegada:'4x4',bloqueia:true,variante:color});feature.houses.push({u,v,color});};
 const houseLots=part==='A'?[[6,19,'creme'],[37,17,'azul'],[6,6,'coral'],[37,5,'creme']]:part==='B'?[[6,23,'creme'],[36,5,'azul'],[6,3,'coral'],[37,28,'creme']]:[[5,10,'creme'],[34,12,'azul'],[7,27,'coral'],[38,3,'creme']];
 for(const lot of houseLots)house(...lot);
 // Side terraces have a purpose: materials, view and optional encounter patch.
 rect(10,23,5,4,'mato',1);rect(34,22,5,3,'mato',1);
 if(part==='A'){
  feature.landmark={u:24,v:30,kind:'portal'};
  P('bambuzal-bancada','Bancada comunitária de pipas',20,22,{pegada:'2x1',bloqueia:true});
  E('npc','Nara',23,29,{district:'bambuzal',duel:'bambuzal-1',npcId:'bambu-1',acao:'districtDuel',fala:'Nara',texto:'Bem-vindo à Vila do Bambuzal. Vamos começar pelo nosso duelo?'});
  E('npc','Dito',26,22,{district:'bambuzal',duel:'bambuzal-2',npcId:'bambu-2',acao:'districtDuel',fala:'Dito',texto:'O vento passa por entre as varetas. Escuta antes de puxar.'});
 }else if(part==='B'){
  rect(18,4,4,12,'grama',1);rect(26,24,4,4,'grama',1);
  rect(19,18,11,15,'grama',0);rect(20,26,6,7,'piso',0);rect(24,18,5,5,'piso',0);
  // Walk in an S: lower square → narrowed bend → Bento's clearing → upper trail.
  rect(22,0,5,H,'grama',0);
  for(let v=0;v<H;v++){
   const u=v>30?24:v>25?22:v>18?24+Math.round((25-v)*.3):v>12?26:24;
   rect(u-1,v,4,1,'terra',0);
  }
  rect(26,24,4,4,'grama',1);rect(22,26,4,7,'piso',0);rect(23,18,6,5,'piso',0);
  rect(5,7,9,9,'grama',2);access(10,16,1,3,true);
  feature.landmark={u:22,v:26,kind:'rest'};
  P('banco','Banco à sombra',20,27,{pegada:'2x1',bloqueia:true,variante:'madeira'});
  feature.shots.push({name:'descanso',u:22,v:26,zoom:1,kind:'jogo'});
  E('npc','Célia',23,29,{district:'bambuzal',duel:'bambuzal-3',npcId:'bambu-3',acao:'districtDuel',fala:'Célia',texto:'Descanse antes de subir. Depois, me mostre o seu laço.'});
  E('npc','Bento',26,20,{district:'bambuzal',duel:'bambuzal-4',npcId:'bambu-4',acao:'districtDuel',fala:'Bento',texto:'Lohan espera lá em cima. Primeiro, nós dois.'});
  E('descanso','Banco e bica',22,26,{acao:'districtRest',district:'bambuzal',texto:'Um descanso à sombra do bambuzal.'});
  E('pista','Varetas cortadas à noite',10,12,{acao:'bambuzalClue',district:'bambuzal',texto:'Os cortes são recentes. À noite levam estas varetas para vender ao Bando do Cerol.'});
  for(const [u,v]of [[9,10],[10,10],[11,11],[12,10],[9,11]])feature.cutStumps.push({u,v});
  feature.shots.push({name:'pista-cortes',u:11,v:12,zoom:1,kind:'jogo'});
 }else{
  // Occupied central terrace and arena +2. Four-wide stairs face the camera.
  rect(16,4,16,20,'piso',1);rect(16,4,16,12,'piso',2);
  rect(16,0,16,4,'bosque',2);
  access(22,24,0,4,true);access(22,16,1,4,true);
  rect(22,18,4,2,'terra',1);rect(22,20,4,2,'piso',1);
  feature.landmark={u:24,v:8,kind:'arena'};
  P('banco','Banco da torcida oeste',17,10,{pegada:'2x1',bloqueia:true,variante:'madeira'});
  P('banco','Banco da torcida leste',29,11,{pegada:'2x1',bloqueia:true,variante:'madeira'});
  E('npc','Lohan',24,8,{district:'bambuzal',duel:'bambuzal-5',npcId:'lohan',acao:'districtDuel',fala:'Lohan',texto:'Você chegou até aqui. Agora deixe o seu parceiro escolher o ritmo.'});
  E('saida','Voltar a Kronasta após a vitória',27,37,{destino:'kronasta',requer:'bambuzal',atalho:true});
  rect(25,35,4,5,'terra',0);
  // Guard rails follow exposed edges and stop on either side of the staircase.
  for(let u=16;u<32;u++)if(u<22||u>=26)feature.guards.push({u,v:15,side:'v'});
  for(let v=4;v<16;v++)feature.guards.push({u:31,v,side:'u'});
  for(let u=18;u<30;u++)if(u<22||u>=26)feature.guards.push({u,v:23,side:'v'});
  // The lower patio joins the eastern terrace at the same elevation: no rail or fake wall.
  feature.shots.push({name:'arena-lohan',u:24,v:8,zoom:1,kind:'jogo'});
 }
 E('entrada','Chegada à Vila do Bambuzal '+part,24,37,{});
 E('saida',part==='A'?'Mapa de Kronasta':'Voltar à parte anterior',24,39,{destino:part==='A'?'kronasta':'kronasta-bambuzal-'+(part==='B'?'a':'b'),chegada_u:24,chegada_v:2});
 if(part!=='C')E('saida','Seguir para a parte '+(part==='A'?'B':'C'),24,0,{destino:'kronasta-bambuzal-'+(part==='A'?'b':'c'),chegada_u:24,chegada_v:37});
 E('item','Papel guardado na vista',16,14,{item:'papel-seda',quantidade:2,visibilidade:'escondido',trajetoria:'ambas'});
 E('item','Varetas do bairro',33,18,{item:'vareta-bambu',quantidade:2,visibilidade:'brilho',trajetoria:'ambas'});
 E('item','Cola de reparo',27,32,{item:'cola-reparo',quantidade:1,visibilidade:'visivel',trajetoria:'ambas'});
 for(const [u,v,w,h]of [[4,28,5,7],[39,26,5,8],[4,11,4,6],[39,10,5,5]])rect(u,v,w,h,'bosque',1);
 // Perimeter bamboo; the foreground edge uses short leaves, never a tall crown over the road.
 for(let v=0;v<H;v++)for(let u=0;u<W;u++)if(mat[I(u,v)]==='bosque'){
  const nearRoad=Math.abs(u-24)<5;
  if(!nearRoad&&u%2===0&&v%2===0&&(u*7+v*11)%7!==0)P('bambuzal-touceira','Massa de bambu',u,v,{variante:v>H-6?'baixo':'alto',bloqueia:false});
 }
 const raw=()=>({type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,
 properties:props({nome:'Vila do Bambuzal · '+subtitle,regras:'overworld-1',bioma:'floresta',cena_jogo:id,regiao:'vila-do-bambuzal',parte:part,trajetoria:'1',rampa_comprimento:2,forest:JSON.stringify(feature)}),
 tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'},{firstgid:101,name:'rampa-v-menos-nivel1',tilewidth:64,tileheight:32,tilecount:24,columns:8,image:'../tiles/rascunho.png',imagewidth:512,imageheight:96,tiles:[{id:23,properties:props({nivel:1,rampa:'v-'})}]}],
 layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(x=>G[x])},{name:'altura',type:'tilelayer',width:W,height:H,data:level.map((l,i)=>ramp[i]||(l?16+l:0))},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]});
 // Every visible patch is reachable: close inaccessible rear planting as actual bamboo.
 let m=parseTiled(raw(),{'rascunho.tsj':ts}),seen=reachable(m,m.spawn);
 for(let v=0;v<H;v++)for(let u=0;u<W;u++)if(walkable(m,u,v)&&!seen[I(u,v)])mat[I(u,v)]='bosque';
 const data=raw();m=parseTiled(data,{'rascunho.tsj':ts});
 const issues=audit(m);if(verdict(issues)==='fail')throw Error(id+JSON.stringify(issues.filter(x=>x.level==='fail')));
 const out=compile(data,id);outputs.push({id,part,map:m,data,out,feature});
}
const region=outputs.map(x=>({id:x.id,part:x.part,map:x.map}));
const links=[['a','b'],['b','c']].map(([a,b])=>({from:{area:'kronasta-bambuzal-'+a,u:24,v:0,direction:'v-'},to:{area:'kronasta-bambuzal-'+b,u:24,v:39,direction:'v+'}}));
const reports=[];
for(const x of outputs){
 const report=auditZeroBreak(x.map,{region,links,guards:x.feature.guards});
 console.log(x.id+'\n'+report.lines.join('\n'));reports.push({id:x.id,...report});
 if(!report.ok)throw Error('Geometria reprovada: '+x.id);
 fs.writeFileSync(root+'art/overworld/mapas/'+x.id+'.tmj',JSON.stringify(x.data,null,1)+'\n');
 fs.writeFileSync(root+'godot/assets/overworld/maps/'+x.id+'.json',JSON.stringify(x.out));
 writeCapturePlan(x.out,x.feature,'documentation/overworld/bambuzal');
}
const indexPath=root+'godot/assets/overworld/maps/index.json',index=JSON.parse(fs.readFileSync(indexPath));
for(const x of outputs){index.scenes[x.id]=x.id;index.areas=index.areas.filter(a=>a.id!==x.id);index.areas.push({id:x.id,name:x.out.name,scene:x.id,biome:'floresta'});}
fs.writeFileSync(indexPath,JSON.stringify(index,null,2)+'\n');
fs.mkdirSync(root+'documentation/overworld/bambuzal',{recursive:true});
fs.writeFileSync(root+'documentation/overworld/bambuzal/conferencia.json',JSON.stringify(reports,null,2)+'\n');
