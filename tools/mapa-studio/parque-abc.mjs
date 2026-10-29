// Three authored park blockouts. Only map data and their compiled review JSONs.
import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {parseTiled,audit,verdict,blockedByPiece,walkable,reachable,findPath,canStep} from './model.mjs';
import {compile} from '../import-overworld.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
const folder=root+'art/overworld/revisao/parque-abc/';fs.mkdirSync(folder,{recursive:true});
const sets={'rascunho.tsj':JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj','utf8'))};
const props=list=>Object.fromEntries((list||[]).map(p=>[p.name,p.value]));
const property=(name,value)=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value});
const putProps=(o,p)=>{o.properties=Object.entries({...props(o.properties),...p}).map(([k,v])=>property(k,v));};
const configs=[
 {id:'jardim-das-pipas',scene:'park-trail',part:'A',w:60,h:44,maxOld:46,
  title:'Jardim das Pipas · A chegada',
  plateaus:[[5,5,22,22,true],[36,4,54,25,true],[4,29,22,39,false],[35,30,54,39,false]],
  trail:[[29,43],[28,37],[31,31],[27,26],[31,19],[28,12],[30,7],[30,0]],
  branches:[[[28,27],[23,26],[15,24]],[[31,29],[40,28],[44,27]],[[27,33],[23,27],[26,20],[28,15]]],
  highTrails:[[[15,22],[15,18],[13,14],[17,12]],[[22,13],[19,15],[17,12]],[[44,25],[45,22],[47,19],[47,16]]],
  ramps:[{u:14,v:23,dir:'v-',width:3},{u:23,v:12,dir:'u-',width:3},{u:43,v:26,dir:'v-',width:3}],
  plazas:[[24,33,32,38],[41,19,47,23]],
  events:{36:[29,41],37:[29,43],38:[30,1],39:[31,36],40:[27,35],41:[44,21],42:[24,37],43:[26,35],44:[30,28]},
  pieces:{1:[8,8],22:[25,34],23:[43,20],29:[24,36],45:[17,12],46:[47,16]},
  items:[[18,17,'folha','escondido'],[29,34,'linha','visivel'],[47,19,'folha','brilho']],
  clusters:[[7,5],[15,5],[20,8],[7,18],[36,5],[45,5],[51,10],[51,22],[8,31],[17,34],[38,33],[47,36],[5,25],[55,27],[3,9],[56,17],[17,2],[40,2]]},
 {id:'clareira-do-papel',scene:'park-clearing',part:'B',w:64,h:48,maxOld:39,
  title:'Clareira do Papel · B os caminhos do riacho',
  plateaus:[[5,4,24,24,true],[39,5,58,28,true],[4,32,23,43,true],[39,34,58,43,false],[20,23,24,32,true,0],[39,26,43,30,true,0]],
  trail:[[31,47],[31,43],[27,38],[32,33],[32,27],[29,22],[34,15],[31,8],[33,0]],
  branches:[[[30,27],[22,27],[16,26]],[[33,33],[43,32],[48,30]],[[27,38],[25,37]],[[32,24],[36,21],[34,15]]],
  highTrails:[[[16,24],[16,20],[17,16]],[[24,14],[20,17],[17,16]],[[48,28],[48,24],[47,21]],[[23,37],[19,39],[13,37]],[[20,37],[22,32],[22,28],[20,23]]],
  ramps:[{u:15,v:25,dir:'v-',width:3},{u:25,v:13,dir:'u-',width:3},{u:47,v:29,dir:'v-',width:3},{u:24,v:36,dir:'u-',width:3}],
  plazas:[[27,36,34,40],[44,21,50,25]],
  events:{33:[31,45],34:[31,47],35:[33,1],36:[30,37],37:[29,38],38:[47,23],39:[28,39]},
  pieces:{22:[28,37],23:[46,22],26:[27,38]},
  items:[[13,37,'folha','escondido'],[17,16,'linha','brilho'],[47,21,'folha','visivel']],
  creek:true,
  clusters:[[7,5],[17,5],[21,10],[7,20],[40,6],[49,6],[55,14],[55,25],[5,34],[8,41],[19,41],[41,36],[49,39],[56,40],[3,27],[60,30],[19,2],[44,2]]},
 {id:'veredas-do-encanamento',scene:'park-veredas',part:'C',w:64,h:48,maxOld:43,
  title:'Veredas do Encanamento · C o pátio dos canos',
  plateaus:[[5,5,25,25,true],[39,4,58,28,true],[4,33,22,43,true],[39,34,58,44,false]],
  trail:[[31,47],[31,43],[27,38],[32,32],[28,26],[33,19],[30,12],[32,6]],
  branches:[[[29,28],[22,28],[17,27]],[[33,32],[43,32],[48,30]],[[27,38],[24,38]],[[31,25],[36,24],[34,18]]],
  highTrails:[[[17,25],[14,22],[15,15],[20,12]],[[25,15],[20,16],[15,15]],[[48,28],[48,24],[49,22]],[[22,38],[17,39],[12,37]]],
  ramps:[{u:16,v:26,dir:'v-',width:3},{u:26,v:14,dir:'u-',width:3},{u:47,v:29,dir:'v-',width:3},{u:23,v:37,dir:'u-',width:3}],
  plazas:[[26,37,33,41],[43,10,55,20],[44,22,51,26]],
  events:{34:[31,45],35:[31,47],36:[49,14],37:[47,24],38:[31,35],39:[28,40],40:[28,32],41:[46,18],42:[52,14],43:[30,40]},
  pieces:{17:[15,15],18:[20,12],19:[12,37],20:[46,24],21:[54,17],22:[27,39],23:[30,36],24:[50,22],25:[47,23],26:[28,30]},
  items:[[17,20,'folha','escondido'],[30,36,'linha','visivel'],[48,22,'folha','brilho']],
  clusters:[[7,6],[17,6],[22,10],[7,22],[40,5],[49,5],[55,9],[55,25],[5,35],[7,41],[19,41],[41,36],[49,40],[56,41],[3,28],[60,32],[20,2],[45,2]]}
];

// Hand-shaped rounded blocks; no noise, random rooms or automatically invented terrain.
function insidePlateau(u,v,[x0,y0,x1,y1,_walk,chamfer=2]){
 if(u<x0||u>x1||v<y0||v>y1)return false;
 const dx=Math.min(u-x0,x1-u),dy=Math.min(v-y0,y1-v);
 return dx+dy>=chamfer;
}
function segmentDistance(x,y,a,b){const dx=b[0]-a[0],dy=b[1]-a[1],den=dx*dx+dy*dy,t=den?Math.max(0,Math.min(1,((x-a[0])*dx+(y-a[1])*dy)/den)):0;return Math.hypot(x-a[0]-t*dx,y-a[1]-t*dy);}
function build(c){
 const file=root+`art/overworld/mapas/${c.id}.tmj`,raw=JSON.parse(fs.readFileSync(file,'utf8'));
 const before=folder+`antes-${c.id}.tmj`;if(!fs.existsSync(before))fs.copyFileSync(file,before);
 const W=c.w,H=c.h,ground=Array(W*H).fill(1),alt=Array(W*H).fill(0);
 const idx=(u,v)=>v*W+u,valid=(u,v)=>u>=0&&v>=0&&u<W&&v<H;
 const rect=(layer,value,x0,y0,x1,y1)=>{for(let v=y0;v<=y1;v++)for(let u=x0;u<=x1;u++)if(valid(u,v))layer[idx(u,v)]=value;};
 for(let v=0;v<H;v++)for(let u=0;u<W;u++){
  if(Math.min(u,v,W-1-u,H-1-v)<4)ground[idx(u,v)]=10;
  for(const p of c.plateaus)if(insidePlateau(u,v,p)){alt[idx(u,v)]=17;if(!p[4])ground[idx(u,v)]=10;}
 }
 function path(points,r=1.65,level=0){
  for(let v=0;v<H;v++)for(let u=0;u<W;u++){
   if(alt[idx(u,v)]!==level)continue;
   if(points.slice(1).some((b,i)=>segmentDistance(u+.5,v+.5,points[i],b)<=r))ground[idx(u,v)]=2;
  }
 }
 path(c.trail,1.9);for(const p of c.branches)path(p,1.6);
 // Meaningful, fully seated ramps. Current shared model supports a one-cell rise.
 // Longer ramps are intentionally not faked by stretching their art.
 const dirs={'v-':[0,-1],'u-':[-1,0]};
 for(const r of c.ramps){
  const [du,dv]=dirs[r.dir],side=du?[0,1]:[1,0];
  for(let k=0;k<r.width;k++){
   const u=r.u+side[0]*k,v=r.v+side[1]*k;
   ground[idx(u,v)]=2;alt[idx(u,v)]=r.dir==='v-'?24:22;
   ground[idx(u-du,v-dv)]=2;alt[idx(u-du,v-dv)]=0;
   ground[idx(u+du,v+dv)]=1;alt[idx(u+du,v+dv)]=17;
  }
 }
 for(const p of c.plazas)rect(ground,7,...p);
 for(const points of c.highTrails)path(points,1.3,17);
 // A shallow watercourse physically bounded by the two high banks. No waterfall.
 if(c.creek){
  // The whole low trench is a watercourse, not a dry corridor beside a stripe.
  rect(ground,4,25,25,38,33);
  rect(ground,6,31,24,33,34);rect(ground,6,26,24,28,34);
 }
 // High routes stop at rewards/views; no empty mandatory staircase or hidden teleport.
 for(const [u,v]of c.items){
  if(alt[idx(u,v)]===17)ground[idx(u,v)]=1;
 }
 // Optional wild pockets are separated from rest points, items and ramp mouths.
 for(const [x0,y0,x1,y1]of [[26,15,27,18],[35,34,37,37]])
  for(let v=y0;v<=y1;v++)for(let u=x0;u<=x1;u++)if(alt[idx(u,v)]===0&&ground[idx(u,v)]===1)ground[idx(u,v)]=3;

 const oldPieces=raw.layers.find(l=>l.name==='pecas').objects.filter(o=>o.id<=c.maxOld);
 const oldEvents=raw.layers.find(l=>l.name==='eventos').objects.filter(o=>o.id<=c.maxOld);
 const stemOffsets=[[0,0],[1,0],[0,1],[1,1],[2,1]];
 const stemCells=[];
 const forestGroups=[...c.clusters];
 for(let u=5;u<W-4;u+=6)forestGroups.push([u,1],[u,H-3]);
 for(let v=6;v<H-5;v+=6)forestGroups.push([1,v],[W-3,v]);
 const usedStems=new Set();
 for(let g=0;g<forestGroups.length;g++){
  const [x,y]=forestGroups[g];
  for(const [dx,dy]of stemOffsets){
   const u=x+dx,v=y+dy;if(!valid(u,v)||[2,6,7].includes(ground[idx(u,v)])||usedStems.has(idx(u,v)))continue;
   usedStems.add(idx(u,v));
   ground[idx(u,v)]=10;stemCells.push({u,v,group:g});
  }
 }
 const occupied=new Set(),protectedCells=new Set();
 const reserve=(u,v,fu=1,fv=1)=>{for(let dv=0;dv<fv;dv++)for(let du=0;du<fu;du++)occupied.add(idx(u+du,v+dv));};
 for(const [u,v]of [...Object.values(c.events),...c.items.map(a=>a.slice(0,2))]){
  protectedCells.add(idx(u,v));
  if(ground[idx(u,v)]===10)ground[idx(u,v)]=1;
 }
 function position(o,u,v){o.x=(u+.5)*32;o.y=(v+.5)*32;}
 function allocate(o,preferred){
  const p=props(o.properties),[fu,fv]=String(p.pegada||'1x1').split('x').map(Number);
  for(let radius=0;radius<14;radius++)for(let dv=-radius;dv<=radius;dv++)for(let du=-radius;du<=radius;du++){
   if(Math.max(Math.abs(du),Math.abs(dv))!==radius)continue;
   const u=preferred[0]+du,v=preferred[1]+dv;if(!valid(u+fu-1,v+fv-1)||!valid(u,v))continue;
   const level=alt[idx(u,v)];if(![0,17].includes(level))continue;
   let okay=true;
   for(let y=0;y<fv;y++)for(let x=0;x<fu;x++){
    const k=idx(u+x,v+y);if(occupied.has(k)||protectedCells.has(k)||![1,2,7].includes(ground[k])||alt[k]!==level)okay=false;
   }
   if(!okay)continue;
   position(o,u,v);reserve(u,v,fu,fv);return;
  }
  throw Error('Sem apoio para '+c.id+': '+o.name);
 }
 const pieces=[];let stem=0,decoration=0;
 for(const o of oldPieces){
  const p=props(o.properties);
  if(p.asset==='arvore'){
   const cell=stemCells[stem++];if(!cell)throw Error('Faltam grupos de mata');
   position(o,cell.u,cell.v);putProps(o,{grupo_mata:`${c.part}-${cell.group}`});reserve(cell.u,cell.v);
  }else{
   const preferred=c.pieces[o.id]||[c.plazas[decoration++%c.plazas.length][0]+2,c.plazas[(decoration-1)%c.plazas.length][1]+1];
   allocate(o,preferred);
  }
  pieces.push(o);
 }
 for(;stem<stemCells.length;stem++){
  const cell=stemCells[stem];
  pieces.push({id:2000+stem,name:'Mata agrupada',type:'peca',x:(cell.u+.5)*32,y:(cell.v+.5)*32,point:true,visible:true,
   properties:Object.entries({asset:'arvore',variante:stem===52?'florida':stem%2?'a':'b',grupo_mata:`${c.part}-${cell.group}`,origem:'parque-abc-v1'}).map(([k,v])=>property(k,v))});
  reserve(cell.u,cell.v);
 }
 const events=oldEvents;
 for(const e of events){const uv=c.events[e.id];if(!uv)throw Error('Evento não mapeado: '+e.name);position(e,...uv);}
 c.items.forEach(([u,v,item,visibility],i)=>events.push({id:1001+i,name:`${item==='folha'?'Papel de preparação':'Linha de preparação'} · ${visibility}`,type:'item',x:(u+.5)*32,y:(v+.5)*32,point:true,visible:true,
  properties:Object.entries({item,quantidade:1,visibilidade:visibility,trajetoria:'ambas',catalogo:'materiais-oficina',origem:'parque-abc-v1'}).map(([k,v])=>property(k,v))}));
 if(c.part==='A'){
  const nina=events.find(e=>e.id===43);nina.name='Nina';
  putProps(nina,{fase:'inicio-e-devolucao',missao:'nina',texto:'Eu voltei sem o Carcará… A rabiola dele ficou perto dos canos.'});
  putProps(events.find(e=>e.id===44),{fase:'investigacao-posterior',requer:'ninaReturned'});
 }
 if(c.part==='B')events.push({id:1100,name:'Rastro junto ao riacho',type:'interacao',x:30.5*32,y:24.5*32,point:true,visible:true,
  properties:[property('texto','O papel rasgado seguiu até os canais de barro.'),property('missao','nina'),property('fase','busca')]});
 if(c.part==='B'||c.part==='C'){
  const y=c.part==='B'?18:25;
  rect(ground,2,56,y-1,63,y+1);rect(alt,17,56,y-1,63,y+1);
  // Clear authored tree stems from the new door, rather than hiding its blockers.
  for(let i=pieces.length-1;i>=0;i--){
   const p=pieces[i],u=Math.floor(p.x/32),v=Math.floor(p.y/32);
   if(p.id>=2000&&props(p.properties).asset==='arvore'&&u>=56&&v>=y-3&&v<=y+3)pieces.splice(i,1);
  }
  events.push({id:1200,name:c.part==='B'?'Chegada pelo mirante alto':'Chegada pelo canal alto',type:'entrada',x:61.5*32,y:(y+.5)*32,point:true,visible:true,
   properties:[property('entrada',c.part==='B'?'mirante-alto':'canal-alto')]});
  events.push({id:1201,name:c.part==='B'?'Veredas pela trilha alta':'Clareira pela trilha alta',type:'saida',x:63.5*32,y:(y+.5)*32,point:true,visible:true,
   properties:[property('destino',c.part==='B'?'park-veredas':'park-clearing'),property('entrada_destino',c.part==='B'?'canal-alto':'mirante-alto')]});
 }
 if(c.part==='C'){
  // Physical door in the high bank, not an exit marker dropped in the grass.
  rect(ground,7,57,18,63,20);rect(alt,17,57,18,63,20);
  events.push({id:1100,name:'Retorno curto ao Jardim · após a vitória',type:'saida',x:63.5*32,y:19.5*32,point:true,visible:true,
   properties:[property('destino','park-trail'),property('requer','guardianDefeated'),property('entrada_destino','chegada-ao-parque')]});
  putProps(events.find(e=>e.id===36),{ocultar_apos:'guardianDefeated'});
  putProps(events.find(e=>e.id===42),{requer:'guardianDefeated',visibilidade:'brilho',missao:'nina',recompensa_separada_do_boss:true});
  putProps(events.find(e=>e.id===43),{fase:'retorno-jardim',visibilidade:'inativo-na-primeira-visita',requer:'ninaReturned'});
 }
 // Sparse landmarks, on supported ground, never stamped over the ramps or doors.
 const dressing=c.part==='A'?[['buriti',8,17],['buriti',49,20],['capim-margem',40,22]]:
  c.part==='B'?[['buriti',8,14],['buriti',53,12],['buriti',8,38],['capim-margem',29,28],['capim-margem',35,31],['capim-margem',24,29],['capim-margem',38,30]]:
  [['buriti',9,14],['buriti',53,34],['capim-margem',42,22],['capim-margem',53,22],['canos-patio',44,11],['canos-patio',54,17],['canos-patio',43,19]];
 dressing.forEach(([asset,u,v],i)=>{
  const o={id:4000+i,name:asset,type:'peca',point:true,visible:true,properties:Object.entries({asset,variante:'a',pegada:'1x1',bloqueia:asset==='buriti',origem:'ambientacao-v2'}).map(([k,v])=>property(k,v))};
  allocate(o,[u,v]);pieces.push(o);
 });
 const mapProperties={...props(raw.properties),nome:c.title,regiao:'parque-dos-ventos',parte:c.part,trajetoria:'ambas',bioma:'parque',cena_jogo:c.scene,
  regras:'overworld-1',libera_apos:'primeira-criacao-assis',origem:'parque-abc-v1',estado:'planta-regional-em-revisao'};
 const tileLayer=(id,name,data)=>({id,name,type:'tilelayer',width:W,height:H,x:0,y:0,visible:true,opacity:1,data});
 const objectLayer=(id,name,objects)=>({id,name,type:'objectgroup',draworder:'topdown',visible:true,opacity:1,objects});
 const result={...raw,width:W,height:H,properties:Object.entries(mapProperties).map(([k,v])=>property(k,v)),
  layers:[tileLayer(1,'chao',ground),tileLayer(2,'altura',alt),objectLayer(3,'pecas',pieces),objectLayer(4,'eventos',events)],nextobjectid:5001};
 // Unused walkable plateaus are not disguised islands: retain their height as blocked forest.
 let m=parseTiled(result,sets),solid=blockedByPiece(m),seen=reachable(m,m.spawn,solid);
 for(let i=0;i<W*H;i++)if(!seen[i]&&walkable(m,i%W,Math.floor(i/W),solid))ground[i]=10;
 m=parseTiled(result,sets);
 const issues=audit(m);
 if(verdict(issues)==='fail')throw Error(c.id+': '+JSON.stringify(issues));
 fs.writeFileSync(file,JSON.stringify(result,null,1)+'\n');
 fs.writeFileSync(root+`godot/assets/overworld/maps/${c.id}.json`,JSON.stringify(compile(result,c.id)));
 return {id:c.id,part:c.part,issues};
}

if(process.argv[1]===fileURLToPath(import.meta.url)){
 for(const c of configs)console.log(JSON.stringify(build(c)));
}
export {configs,build};
