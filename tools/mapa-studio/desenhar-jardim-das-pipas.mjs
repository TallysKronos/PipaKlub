import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {parseTiled,reachable,walkable} from './model.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
import {compile} from '../import-overworld.mjs';
import {writeCapturePlan} from './capturas-bosque.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
const ID='jardim-das-pipas',W=48,H=40;
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
export function generateJardim(){
 const seed=JSON.parse(fs.readFileSync(root+'art/overworld/briefs/jardim-das-pipas-origem.json'));
 const ts=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
 const gid=Object.fromEntries(ts.tiles.filter(t=>t.id<16).map(t=>[t.properties[0].value,t.id+1]));
 const mat=Array(W*H).fill('grama'),level=Array(W*H).fill(0),ramps=Array(W*H).fill(0);
 const index=(u,v)=>v*W+u,inside=(u,v)=>u>=0&&v>=0&&u<W&&v<H;
 const rect=(u,v,w,h,material=null,height=null)=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++)if(inside(x,y)){if(material)mat[index(x,y)]=material;if(height!==null)level[index(x,y)]=height;}};
 const trail=(points,width=4)=>{for(let n=1;n<points.length;n++){const a=points[n-1],b=points[n],steps=Math.ceil(Math.hypot(b[0]-a[0],b[1]-a[1])*3);for(let t=0;t<=steps;t++){const u=Math.round(a[0]+(b[0]-a[0])*t/steps),v=Math.round(a[1]+(b[1]-a[1])*t/steps);rect(u-Math.floor(width/2),v-Math.floor(width/2),width,width,'terra',0);}}};
 rect(0,0,W,4,'bosque');rect(0,H-4,W,4,'bosque');rect(0,0,4,H,'bosque');rect(W-4,0,4,H,'bosque');
 rect(4,4,16,24,null,1);rect(20,12,12,14,null,1);rect(38,16,8,16,null,1);rect(30,2,14,10,null,1);rect(4,0,20,4,null,1);
 trail([[8,39],[8,32],[25,30],[34,30],[36,24],[36,14],[36,0]],4);
 trail([[8,32],[13,31]],3);trail([[25,30],[25,28]],3);trail([[34,27],[41,34]],3);trail([[36,14],[31,14]],3);
 // A full block follows the lowest adjacent route: no one-cell sawtooth cliffs.
 for(let bv=0;bv<H;bv+=2)for(let bu=0;bu<W;bu+=2){const cells=[index(bu,bv),index(bu+1,bv),index(bu,bv+1),index(bu+1,bv+1)];if(cells.some(i=>level[i]===0))for(const i of cells)level[i]=0;}
 const access=(u,v,width=2)=>{for(let x=u;x<u+width;x++){rect(x,v-2,1,2,'grama',1);rect(x,v,1,4,'terra',0);ramps[index(x,v)]=24;}};
 access(12,28);access(24,26,3);access(40,32);access(30,12);
 rect(22,14,8,10,'piso',1);
 rect(16,18,3,3,'mato',1);
 rect(21,33,3,2,'terra',0);
 const sourcePieces=seed.layers.find(l=>l.name==='pecas').objects;
 const sourceEvents=seed.layers.find(l=>l.name==='eventos').objects;
 const position={1:[23,16],2:[23,16],3:[26,16],4:[26,19],5:[23,19],6:[10,35],7:[21,22],8:[30,20],9:[42,22],10:[10,33],11:[20,24],12:[16,12],13:[20,23],14:[22,15],15:[29,16],16:[10,25],17:[11,25],18:[9,25],19:[21,13],20:[22,13],21:[20,13],22:[40,26],23:[41,26],24:[42,26],25:[14,18],26:[8,10],27:[14,7],28:[10,20],43:[8,36],44:[8,39],45:[36,0],46:[21,20],47:[21,23],48:[43,23],49:[10,34]};
 const moved=o=>{const p=position[o.id];if(!p)throw Error('Missing stable position '+o.id);return {...structuredClone(o),x:p[0]*32+16,y:p[1]*32+16};};
 const pieces=sourcePieces.filter(o=>!o.properties.some(p=>p.name==='asset'&&p.value==='arvore')).map(moved);
 const events=sourceEvents.map(moved);
 let next=seed.nextobjectid;
 const object=(type,name,u,v,p)=>({id:next++,name,type,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 const item=(name,u,v,id,quantity,visibility)=>events.push(object('item',name,u,v,{item:id,quantidade:quantity,visibilidade:visibility,trajetoria:'ambas'}));
 item('Papel escondido no pomar',6,20,'papel-seda',2,'escondido');
 item('Cola do mirante florido',43,27,'cola-reparo',1,'brilho');
 item('Varetas entre o capim',17,19,'vareta-bambu',2,'visivel');
 item('Papel no terraço norte',32,6,'papel-seda',1,'brilho');
 events.push(object('interacao','Pegadas junto ao canteiro',22,34,{texto:'Pegadas palmadas cruzam a terra. Um fiapo de linha áspera ficou preso entre as folhas.',trajetoria:'2',pista:'pegadas-palmadas-cerol'}));
 const feature={nativeProps:true,stairs:[{u:24,v:26,width:3,length:2}],guards:[],shots:[{name:'praca-coreto',u:25,v:19,zoom:1,kind:'jogo'},{name:'pomar',u:11,v:13,zoom:1,kind:'jogo'},{name:'mirante-florido',u:41,v:24,zoom:1,kind:'jogo'},{name:'coreto-pilares',u:25,v:18,zoom:2.2},{name:'escada-pe',u:25.5,v:27.8,zoom:2.3},{name:'escada-chegada',u:25.5,v:25.8,zoom:2.3}]};
 feature.footprints=[[21.5,33.5],[22.5,33.5],[22.5,34.5],[23.5,34.5]];
 feature.shots.push({name:'pegadas-palmadas',u:22.5,v:34,zoom:2.3},{name:'encontro-opcional',u:17.5,v:19.5,zoom:1,kind:'jogo'});
 for(let u=20;u<32;u++)if(u<24||u>26)feature.guards.push({u,v:25,side:'v'});
 for(let v=12;v<26;v++)feature.guards.push({u:31,v,side:'u'});
 feature.guards=feature.guards.filter(g=>{const du=g.side==='u'?1:0,dv=g.side==='v'?1:0;return level[index(g.u,g.v)]>level[index(g.u+du,g.v+dv)]&&!ramps[index(g.u,g.v)]&&!ramps[index(g.u+du,g.v+dv)];});
 const exit=events.find(o=>o.id===45);exit.properties.push(...props({chegada_u:3,chegada_v:13}));
 const mapProperties=props({nome:'Parque dos Ventos · Jardim das Pipas',regras:'overworld-1',bioma:'parque',cena_jogo:'park-trail',regiao:'parque-dos-ventos',parte:'A',trajetoria:'ambas',libera_apos:'morro-do-sol',rampa_comprimento:2,forest:JSON.stringify(feature),origem:'desenhar-jardim-das-pipas.mjs'});
 const raw=()=>({type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,properties:mapProperties,tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'}],nextobjectid:next,layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(m=>gid[m])},{name:'altura',type:'tilelayer',width:W,height:H,data:level.map((l,i)=>ramps[i]||(l?16+l:0))},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]});
 let m=parseTiled(raw(),{'rascunho.tsj':ts}),seen=reachable(m,m.spawn);
 for(let v=0;v<H;v++)for(let u=0;u<W;u++)if(walkable(m,u,v)&&!seen[index(u,v)])mat[index(u,v)]='bosque';
 const legacyTrees=sourcePieces.filter(o=>o.properties.some(p=>p.name==='asset'&&p.value==='arvore'));
 let tree=0;
 for(let v=0;v<H;v++)for(let u=0;u<W;u++){
  if(mat[index(u,v)]!=='bosque'||(u*17+v*13)%7===0)continue;
  const old=legacyTrees[tree++];
  pieces.push(old?{...structuredClone(old),x:u*32+16,y:v*32+16}:object('peca','Mata do jardim',u,v,{asset:'arvore',variante:(u+v)%9===0?'florida':(u+v)%2?'a':'b'}));
 }
 if(tree<legacyTrees.length)throw Error('Not enough positions for existing tree IDs');
 // Decorate flower borders in clusters, leaving mouths and their approaches bare.
 for(const [cu,cv]of[[9,23],[19,15],[40,25]])for(const[du,dv]of[[0,0],[1,0],[0,1],[-1,0],[1,1]]){
  const u=cu+du,v=cv+dv;if(pieces.some(p=>p.x/32-.5===u&&p.y/32-.5===v))continue;
  pieces.push(object('peca','Florada do jardim',u,v,{asset:'flores',variante:['coral','amarela','azul'][(u+v)%3],bloqueia:false}));
 }
 const outRaw=raw();m=parseTiled(outRaw,{'rascunho.tsj':ts});
 const bRaw=JSON.parse(fs.readFileSync(root+'art/overworld/mapas/clareira-do-papel.tmj'));
 const bReturn=bRaw.layers.find(l=>l.name==='eventos').objects.find(o=>o.type==='saida'&&o.properties.some(p=>p.name==='destino'&&p.value==='park-trail'));
 bReturn.properties=bReturn.properties.filter(p=>!['chegada_u','chegada_v'].includes(p.name));bReturn.properties.push(...props({chegada_u:36,chegada_v:2}));
 const b=parseTiled(bRaw,{'rascunho.tsj':ts});
 const c=parseTiled(JSON.parse(fs.readFileSync(root+'art/overworld/mapas/veredas-do-encanamento.tmj')),{'rascunho.tsj':ts});
 const region=[{id:'park-trail',part:'A',map:m},{id:'park-clearing',part:'B',map:b},{id:'park-veredas',part:'C',map:c}];
 const links=[{from:{area:'park-trail',u:36,v:0,direction:'v-'},to:{area:'park-clearing',u:2,v:15,direction:'v+'}},{from:{area:'park-clearing',u:23,v:3,direction:'u+'},to:{area:'park-veredas',u:0,v:13,direction:'u-'}}];
 const result=auditZeroBreak(m,{region,links,guards:feature.guards});
 console.log(result.lines.join('\n'));if(!result.ok)throw Error('Jardim geometry rejected');
 fs.writeFileSync(root+'art/overworld/mapas/'+ID+'.tmj',JSON.stringify(outRaw,null,1)+'\n');
 fs.writeFileSync(root+'godot/assets/overworld/maps/'+ID+'.json',JSON.stringify(compile(outRaw,ID)));
 fs.writeFileSync(root+'art/overworld/mapas/clareira-do-papel.tmj',JSON.stringify(bRaw,null,1)+'\n');
 fs.writeFileSync(root+'godot/assets/overworld/maps/clareira-do-papel.json',JSON.stringify(compile(bRaw,'clareira-do-papel')));
 writeCapturePlan(compile(outRaw,ID),feature,'documentation/overworld/parque');
 fs.mkdirSync(root+'documentation/overworld/parque/relatorios',{recursive:true});
 fs.writeFileSync(root+'documentation/overworld/parque/relatorios/jardim-auditoria.json',JSON.stringify(result,null,2)+'\n');
 return {raw:outRaw,result};
}
if(process.argv[1]===fileURLToPath(import.meta.url))generateJardim();
