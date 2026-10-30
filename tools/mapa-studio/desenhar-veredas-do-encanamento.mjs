import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {parseTiled,reachable,walkable} from './model.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
import {compile} from '../import-overworld.mjs';
import {writeCapturePlan} from './capturas-bosque.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),ID='veredas-do-encanamento',W=52,H=44;
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
export function generateVeredas(){
 const seed=JSON.parse(fs.readFileSync(root+'art/overworld/briefs/'+ID+'-origem.json'));
 const ts=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
 const gid=Object.fromEntries(ts.tiles.filter(t=>t.id<16).map(t=>[t.properties[0].value,t.id+1]));
 const mat=Array(W*H).fill('grama'),level=Array(W*H).fill(0),ramps=Array(W*H).fill(0),ix=(u,v)=>v*W+u;
 const rect=(u,v,w,h,material=null,height=null)=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++)if(x>=0&&y>=0&&x<W&&y<H){if(material)mat[ix(x,y)]=material;if(height!==null)level[ix(x,y)]=height;}};
 const trail=(points,width=4)=>{for(let n=1;n<points.length;n++){const a=points[n-1],b=points[n],steps=Math.ceil(Math.hypot(b[0]-a[0],b[1]-a[1])*3);for(let t=0;t<=steps;t++){const u=Math.round(a[0]+(b[0]-a[0])*t/steps),v=Math.round(a[1]+(b[1]-a[1])*t/steps);rect(u-Math.floor(width/2),v-Math.floor(width/2),width,width,'terra',0);}}};
 rect(0,0,W,4,'bosque');rect(0,H-4,W,4,'bosque');rect(0,0,4,H,'bosque');rect(W-4,0,4,H,'bosque');
 rect(0,0,W,4,null,1);rect(0,4,4,16,null,1);rect(4,0,44,14,null,1);rect(4,26,16,10,null,1);rect(30,26,18,10,null,1);
 trail([[0,13],[14,13],[23,15],[24,18]]);trail([[24,26],[24,34],[24,38],[41,38]],4);trail([[24,34],[13,38]],3);trail([[26,16],[37,16]],3);
 for(let v=0;v<H;v+=2)for(let u=0;u<W;u+=2){const cells=[ix(u,v),ix(u+1,v),ix(u,v+1),ix(u+1,v+1)];if(cells.some(i=>level[i]===0))for(const i of cells)level[i]=0;}
 const access=(u,v,width=2)=>{for(let x=u;x<u+width;x++){rect(x,v-2,1,2,'grama',1);rect(x,v,1,4,'terra',0);ramps[ix(x,v)]=24;}};
 access(12,10);access(36,14);access(12,36);access(40,36,3);
 rect(34,27,11,7,'piso',1);rect(8,28,3,3,'mato',1);rect(29,30,3,3,'mato',0);
 // One continuous measured channel, genuinely cut out of the upper ground.
 const channel=[];for(let u=-10;u<=62;u++)channel.push([u,20+Math.sin(u*.13)*2]);for(let u=62;u>=-10;u--)channel.push([u,24+Math.sin(u*.13)*2]);
 for(let u=0;u<W;u++){const center=22+Math.sin(u*.13)*2;for(let v=0;v<H;v++)if(Math.abs(v+.5-center)<2.5)rect(u,v,1,1,'agua',0);}
 rect(23,17,3,2,'terra',0);rect(23,19,3,6,'ponte',0);rect(23,25,3,3,'terra',0);
 const originals=seed.layers.find(l=>l.name==='pecas').objects;
 const positions={1:[8,6],2:[6,32],3:[46,33],4:[39,8],5:[44,28],6:[6,15],7:[19,17],8:[44,30],9:[36,29],10:[11,32],11:[42,28],12:[41,27],13:[35,16],14:[6,7],15:[9,7],16:[13,30],17:[14,31],18:[35,7],19:[40,7],20:[43,32],21:[10,8],88:[2,13],89:[0,13],90:[39,29],91:[37,30],92:[5,15],93:[7,15],94:[11,33],95:[34,16],96:[40,31],97:[19,16]};
 const moved=o=>{const p=positions[o.id];if(!p)throw Error('Missing stable ID '+o.id);return {...structuredClone(o),x:p[0]*32+16,y:p[1]*32+16};};
 const asset=o=>o.properties.find(p=>p.name==='asset')?.value;
 const pieces=originals.filter(o=>!['arvore','buriti','capim-margem'].includes(asset(o))).map(moved);
 const events=seed.layers.find(l=>l.name==='eventos').objects.map(moved);
 let next=seed.nextobjectid;const object=(type,name,u,v,p)=>({id:next++,name,type,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 const item=(name,u,v,id,visibility)=>events.push(object('item',name,u,v,{item:id,quantidade:1,visibilidade:visibility,trajetoria:'ambas'}));
 item('Papel entre raízes úmidas',5,30,'papel-seda','escondido');item('Varetas do mirante',15,7,'vareta-bambu','brilho');item('Cola na margem sul',27,28,'cola-reparo','brilho');item('Papel do pátio',34,32,'papel-seda','visivel');
 const feature={nativeProps:true,followTrail:true,stairs:[{u:40,v:36,width:3,length:2}],guards:[],water:{contour:[],channel,channelDepth:6,depth:6},shots:[{name:'patio-dos-canos',u:39,v:30,zoom:1,kind:'jogo'},{name:'mirante-norte',u:11,v:7,zoom:1,kind:'jogo'},{name:'bosque-sul',u:11,v:31,zoom:1,kind:'jogo'},{name:'mesa-do-norte',u:38,v:9,zoom:1,kind:'jogo'},{name:'ponte-cabeceira-norte',u:24.5,v:18.5},{name:'ponte-cabeceira-sul',u:24.5,v:25.5},{name:'ponte-tabuleiro',u:24.5,v:22},{name:'escada-pe',u:41.5,v:37.8},{name:'escada-chegada',u:41.5,v:35.8},{name:'canos-implantacao',u:42,v:28,zoom:2.3}]};
 for(let u=30;u<48;u++)if(u<40||u>42)feature.guards.push({u,v:35,side:'v'});
 for(let v=26;v<36;v++)feature.guards.push({u:47,v,side:'u'});
 const mapProperties=props({nome:'Parque dos Ventos · Veredas do Encanamento',regras:'overworld-1',bioma:'veredas',cena_jogo:'park-veredas',regiao:'parque-dos-ventos',parte:'C',trajetoria:'ambas',rampa_comprimento:2,forest:JSON.stringify(feature),origem:'desenhar-veredas-do-encanamento.mjs'});
 const raw=()=>({type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,properties:mapProperties,tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'}],nextobjectid:next,layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(m=>gid[m])},{name:'altura',type:'tilelayer',width:W,height:H,data:level.map((l,i)=>ramps[i]||(l?16+l:0))},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]});
 let m=parseTiled(raw(),{'rascunho.tsj':ts}),seen=reachable(m,m.spawn);
 for(let v=0;v<H;v++)for(let u=0;u<W;u++)if(walkable(m,u,v)&&!seen[ix(u,v)])mat[ix(u,v)]='bosque';
 const trees=originals.filter(o=>['arvore','buriti'].includes(asset(o)));let tree=0;
 for(let v=0;v<H;v++)for(let u=0;u<W;u++)if(mat[ix(u,v)]==='bosque'&&(u*17+v*13)%7!==0){const old=trees[tree++];pieces.push(old?{...structuredClone(old),x:u*32+16,y:v*32+16}:object('peca','Mata das veredas',u,v,{asset:'arvore',variante:(u+v)%3?'a':'b'}));}
 const fringe=originals.filter(o=>asset(o)==='capim-margem');let n=0;
 // Wetland plants form groups on grass, never a repeated stripe across a trail.
 const offsets=[];for(let dv=-3;dv<=3;dv++)for(let du=-3;du<=3;du++)offsets.push([du,dv]);offsets.sort((a,b)=>a[0]**2+a[1]**2-b[0]**2-b[1]**2);
 for(const [du,dv]of offsets)for(const [cu,cv]of [[8,18],[44,16],[6,28],[16,28]]){
  const u=cu+du,v=cv+dv;if(n===fringe.length)break;
  if(mat[ix(u,v)]!=='grama'||ramps[ix(u,v)]||pieces.some(p=>asset(p)!=='capim-margem'&&Math.abs(p.x/32-.5-u)<1.5&&Math.abs(p.y/32-.5-v)<1.5))continue;
  pieces.push({...structuredClone(fringe[n++]),x:u*32+16,y:v*32+16});
 }
 if(n!==fringe.length||tree<trees.length)throw Error('Missing original vegetation IDs');
 const out=raw();m=parseTiled(out,{'rascunho.tsj':ts});
 const read=id=>parseTiled(JSON.parse(fs.readFileSync(root+'art/overworld/mapas/'+id+'.tmj')),{'rascunho.tsj':ts});
 const region=[{id:'park-trail',part:'A',map:read('jardim-das-pipas')},{id:'park-clearing',part:'B',map:read('clareira-do-papel')},{id:'park-veredas',part:'C',map:m}];
 const links=[{from:{area:'park-trail',u:36,v:0,direction:'v-'},to:{area:'park-clearing',u:8,v:39,direction:'v+'}},{from:{area:'park-clearing',u:47,v:8,direction:'u+'},to:{area:'park-veredas',u:0,v:13,direction:'u-'}}];
 const result=auditZeroBreak(m,{region,links,guards:feature.guards});console.log(result.lines.join('\n'));if(!result.ok)throw Error('Veredas geometry rejected');
 fs.writeFileSync(root+'art/overworld/mapas/'+ID+'.tmj',JSON.stringify(out,null,1)+'\n');fs.writeFileSync(root+'godot/assets/overworld/maps/'+ID+'.json',JSON.stringify(compile(out,ID)));
 writeCapturePlan(compile(out,ID),feature,'documentation/overworld/parque');fs.writeFileSync(root+'documentation/overworld/parque/relatorios/veredas-auditoria.json',JSON.stringify(result,null,2)+'\n');return {raw:out,result};
}
if(process.argv[1]===fileURLToPath(import.meta.url))generateVeredas();
