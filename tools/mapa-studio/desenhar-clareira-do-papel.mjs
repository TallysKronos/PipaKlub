import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {parseTiled,reachable,walkable} from './model.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
import {compile} from '../import-overworld.mjs';
import {writeCapturePlan} from './capturas-bosque.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),ID='clareira-do-papel',W=48,H=40;
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
export function generateClareira(){
 const seed=JSON.parse(fs.readFileSync(root+'art/overworld/briefs/'+ID+'-origem.json'));
 const ts=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
 const gid=Object.fromEntries(ts.tiles.filter(t=>t.id<16).map(t=>[t.properties[0].value,t.id+1]));
 const mat=Array(W*H).fill('grama'),level=Array(W*H).fill(0),ramps=Array(W*H).fill(0);
 const ix=(u,v)=>v*W+u;
 const rect=(u,v,w,h,material=null,height=null)=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++)if(x>=0&&y>=0&&x<W&&y<H){if(material)mat[ix(x,y)]=material;if(height!==null)level[ix(x,y)]=height;}};
 const trail=(points,width=4)=>{for(let n=1;n<points.length;n++){const a=points[n-1],b=points[n],steps=Math.ceil(Math.hypot(b[0]-a[0],b[1]-a[1])*3);for(let t=0;t<=steps;t++){const u=Math.round(a[0]+(b[0]-a[0])*t/steps),v=Math.round(a[1]+(b[1]-a[1])*t/steps);rect(u-Math.floor(width/2),v-Math.floor(width/2),width,width,'terra',0);}}};
 rect(0,0,W,4,'bosque');rect(0,H-4,W,4,'bosque');rect(0,0,4,H,'bosque');rect(W-4,0,4,H,'bosque');
 rect(4,4,14,24,null,1);rect(24,0,24,14,null,1);rect(32,22,12,10,null,1);rect(0,0,4,28,null,1);
 trail([[8,39],[8,32],[22,30],[22,18],[36,18],[36,8],[47,8]]);
 trail([[8,32],[13,31]],3);trail([[8,32],[7,31]],3);trail([[25,18],[29,17]],3);trail([[22,30],[37,34]],3);
 // The clearing is an intentional open room; the low route skirts its west edge.
 for(let v=17;v<29;v++)for(let u=19;u<31;u++)if(((u-25)/7)**2+((v-23)/6)**2<1)rect(u,v,1,1,'terra',0);
 for(let v=0;v<H;v+=2)for(let u=0;u<W;u+=2){const cells=[ix(u,v),ix(u+1,v),ix(u,v+1),ix(u+1,v+1)];if(cells.some(i=>level[i]===0))for(const i of cells)level[i]=0;}
 const access=(u,v,dir='v-')=>{for(let n=0;n<2;n++){if(dir==='v-'){rect(u+n,v-2,1,2,'grama',1);rect(u+n,v,1,4,'terra',0);ramps[ix(u+n,v)]=24;}else{rect(u-2,v+n,2,1,'grama',1);rect(u,v+n,4,1,'terra',0);ramps[ix(u,v+n)]=22;}}};
 access(12,28);access(6,28);access(28,14);access(36,32);
 rect(33,24,3,4,'mato',1);rect(10,16,3,4,'mato',1);
 const originals=seed.layers.find(l=>l.name==='pecas').objects;
 const positions={1:[10,34],2:[38,26],3:[7,22],4:[41,29],5:[28,8],6:[5,7],7:[7,5],8:[41,2],9:[2,20],10:[43,32],27:[8,36],28:[8,39],29:[47,8],30:[12,34],31:[39,27],32:[9,34]};
 const moved=o=>{const p=positions[o.id];if(!p)throw Error('Missing stable ID '+o.id);return {...structuredClone(o),x:p[0]*32+16,y:p[1]*32+16};};
 const pieces=originals.filter(o=>!o.properties.some(p=>p.name==='asset'&&p.value==='arvore')).map(moved);
 const events=seed.layers.find(l=>l.name==='eventos').objects.map(moved);
 let next=seed.nextobjectid;
 const object=(type,name,u,v,p)=>({id:next++,name,type,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 const item=(name,u,v,id,visibility)=>events.push(object('item',name,u,v,{item:id,quantidade:1,visibilidade:visibility,trajetoria:'ambas'}));
 item('Papel entre as raízes',6,18,'papel-seda','escondido');item('Varetas na clareira alta',15,22,'vareta-bambu','brilho');item('Cola junto ao descanso',40,30,'cola-reparo','brilho');item('Papel no alto da biruta',30,7,'papel-seda','brilho');
 const feature={nativeProps:true,guards:[],shots:[{name:'roda-do-encontro',u:25,v:23,zoom:1,kind:'jogo'},{name:'biruta-do-alto',u:29,v:9,zoom:1,kind:'jogo'},{name:'descanso-alto',u:37,v:28,zoom:1,kind:'jogo'},{name:'desvio-do-capim',u:13,v:19,zoom:1,kind:'jogo'},{name:'pipas-nas-copas',u:6,v:7,zoom:2.3}]};
 for(let u=32;u<44;u++)if(u<36||u>37)feature.guards.push({u,v:31,side:'v'});
 feature.guards=feature.guards.filter(g=>level[ix(g.u,g.v)]>level[ix(g.u,g.v+1)]&&!ramps[ix(g.u,g.v)]&&!ramps[ix(g.u,g.v+1)]);
 const setArrival=(event,u,v)=>{event.properties=event.properties.filter(p=>!['chegada_u','chegada_v'].includes(p.name));event.properties.push(...props({chegada_u:u,chegada_v:v}));};
 setArrival(events.find(e=>e.id===28),36,2);setArrival(events.find(e=>e.id===29),2,13);
 const mapProperties=props({nome:'Parque dos Ventos · Clareira do Papel',regras:'overworld-1',bioma:'parque',cena_jogo:'park-clearing',regiao:'parque-dos-ventos',parte:'B',trajetoria:'ambas',rampa_comprimento:2,forest:JSON.stringify(feature),origem:'desenhar-clareira-do-papel.mjs'});
 const raw=()=>({type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,properties:mapProperties,tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'}],nextobjectid:next,layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(m=>gid[m])},{name:'altura',type:'tilelayer',width:W,height:H,data:level.map((l,i)=>ramps[i]||(l?16+l:0))},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]});
 let m=parseTiled(raw(),{'rascunho.tsj':ts}),seen=reachable(m,m.spawn);
 for(let v=0;v<H;v++)for(let u=0;u<W;u++)if(walkable(m,u,v)&&!seen[ix(u,v)])mat[ix(u,v)]='bosque';
 const trees=originals.filter(o=>o.properties.some(p=>p.name==='asset'&&p.value==='arvore'));let tree=0;
 for(let v=0;v<H;v++)for(let u=0;u<W;u++)if(mat[ix(u,v)]==='bosque'&&(u*17+v*13)%7!==0){const old=trees[tree++];pieces.push(old?{...structuredClone(old),x:u*32+16,y:v*32+16}:object('peca','Mata da clareira',u,v,{asset:'arvore',variante:(u+v)%13===0?'florida':(u+v)%2?'a':'b'}));}
 for(const [u,v]of [[37,24],[38,24],[39,24],[40,24],[37,25]])pieces.push(object('peca','Canteiro do descanso',u,v,{asset:'flores',variante:'amarela',bloqueia:false}));
 const out=raw();m=parseTiled(out,{'rascunho.tsj':ts});
 const neighbor=id=>JSON.parse(fs.readFileSync(root+'art/overworld/mapas/'+id+'.tmj'));
 const a=neighbor('jardim-das-pipas'),c=neighbor('veredas-do-encanamento');
 const exitTo=(map,dest)=>map.layers.find(l=>l.name==='eventos').objects.find(e=>e.type==='saida'&&e.properties.some(p=>p.name==='destino'&&p.value===dest));
 setArrival(exitTo(a,'park-clearing'),8,36);setArrival(exitTo(c,'park-clearing'),44,8);
 const region=[{id:'park-trail',part:'A',map:parseTiled(a,{'rascunho.tsj':ts})},{id:'park-clearing',part:'B',map:m},{id:'park-veredas',part:'C',map:parseTiled(c,{'rascunho.tsj':ts})}];
 const links=[{from:{area:'park-trail',u:36,v:0,direction:'v-'},to:{area:'park-clearing',u:8,v:39,direction:'v+'}},{from:{area:'park-clearing',u:47,v:8,direction:'u+'},to:{area:'park-veredas',u:0,v:13,direction:'u-'}}];
 const result=auditZeroBreak(m,{region,links,guards:feature.guards});console.log(result.lines.join('\n'));if(!result.ok)throw Error('Clareira geometry rejected');
 for(const [id,map]of [[ID,out],['jardim-das-pipas',a],['veredas-do-encanamento',c]]){fs.writeFileSync(root+'art/overworld/mapas/'+id+'.tmj',JSON.stringify(map,null,1)+'\n');fs.writeFileSync(root+'godot/assets/overworld/maps/'+id+'.json',JSON.stringify(compile(map,id)));}
 writeCapturePlan(compile(out,ID),feature,'documentation/overworld/parque');
 fs.writeFileSync(root+'documentation/overworld/parque/relatorios/clareira-auditoria.json',JSON.stringify(result,null,2)+'\n');return {raw:out,result};
}
if(process.argv[1]===fileURLToPath(import.meta.url))generateClareira();
