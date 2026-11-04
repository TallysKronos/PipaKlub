// Door approaches: source tiles, no painted shortcuts across blocked terrain.
import fs from 'node:fs';
import {compile} from '../import-overworld.mjs';
const kit=JSON.parse(fs.readFileSync('art/overworld/kits/morro/kit.json'));
const tiles=JSON.parse(fs.readFileSync('art/overworld/tiles/rascunho.tsj'));
const pavement=tiles.tiles.find(t=>t.properties?.some(p=>p.name==='material'&&p.value==='calcada')).id+1;
const report=[];
const reportFile='documentation/overworld/morro-pip87/acessos.json';
const previous=fs.existsSync(reportFile)?JSON.parse(fs.readFileSync(reportFile)):[];
for(const [id,recipe] of Object.entries(kit.composition)){
 const file=`art/overworld/mapas/${id}.tmj`,raw=JSON.parse(fs.readFileSync(file));
 const ground=raw.layers.find(l=>l.name==='chao');
 const objects=raw.layers.flatMap(l=>l.objects||[]);
 const property=(o,key,value,type='string')=>{
  o.properties??=[];const found=o.properties.find(p=>p.name===key);
  if(found){found.value=value;found.type=type;}else o.properties.push({name:key,type,value});
 };
 const yardHouses=[];
 for(const o of objects){
  if(o.properties?.find(p=>p.name==='asset')?.value!=='casa-morro')continue;
  if(recipe.houses.includes(o.id)){property(o,'bloqueia',true,'bool');continue;}
  // These houses have no rendered building in the authored composition.
  // Do not retain invisible building collision in the corresponding yards.
  property(o,'bloqueia',false,'bool');yardHouses.push(o.id);
 }
 if(id==='morro-mirante-da-caixa-dagua'){
  const rail=objects.find(o=>o.properties?.some(p=>p.name==='asset'&&p.value==='mirante-guarda-corpo'));
  rail.x=8.5*32;rail.y=4.5*32;
  // Supported 2x2 cap at the existing upper terrace edge, no new height.
  for(let v=4;v<6;v++)for(let u=8;u<10;u++)ground.data[v*raw.width+u]=pavement;
 }
 // The former post stood halfway along the neighbouring house window.
 // Put the arrival arch at the street mouth, outside that 3x3 house lot.
 if(id==='morro-praca-da-chegada'){
  const gate=raw.layers.flatMap(l=>l.objects||[]).find(o=>o.id===1);
  gate.y=15.5*32;
  for(let u=3;u<7;u++)ground.data[15*raw.width+u]=pavement;
 }
 const m=compile(raw,id);
 const occupied=new Set();
 for(const p of m.pieces)if(p.blocks)for(let v=p.v;v<p.v+p.fv;v++)for(let u=p.u;u<p.u+p.fu;u++)occupied.add(v*m.w+u);
 const edges=new Map();
 for(const [a,b]of m.oracle.edges){if(!edges.has(a))edges.set(a,[]);edges.get(a).push(b);}
 const reachable=new Set([Math.floor(m.spawn.v)*m.w+Math.floor(m.spawn.u)]),queue=[...reachable];
 for(let n=0;n<queue.length;n++)for(const b of edges.get(queue[n])||[])if(!reachable.has(b)){reachable.add(b);queue.push(b);}
 const earlier=previous.find(r=>r.id===id);
 const changes=new Set((earlier?.changedCells||[]).map(([u,v])=>v*m.w+u)),approaches=[];
 if(id==='morro-praca-da-chegada')for(let u=3;u<7;u++)changes.add(15*m.w+u);
 const route=(p,right)=>{
  const u=right?p.u+p.fu:p.u+1,v=right?p.v+1:p.v+p.fv,level=m.cells[p.v*m.w+p.u].level;
  if(u>=m.w||v>=m.h)return {status:'door_outside_map'};
  const start=v*m.w+u,front=m.cells[start];
  if(occupied.has(start)||front.level!==level||front.ramp)return {status:'blocked_or_different_level'};
  const paths=[[start]],seen=new Set([start]);let result=null;
  for(let n=0;n<paths.length;n++){
   const path=paths[n],a=path.at(-1);
   if(reachable.has(a)){result=path;break;}
   if(path.length>=8)continue;
   const x=a%m.w,y=Math.floor(a/m.w);
   for(const [du,dv]of [[0,1],[1,0],[-1,0],[0,-1]]){
    const xx=x+du,yy=y+dv,b=yy*m.w+xx,c=m.cells[b];
    if(xx<0||yy<0||xx>=m.w||yy>=m.h||seen.has(b)||occupied.has(b)||!c||c.ramp||c.level!==level)continue;
    if(c.material!=='construcao'&&!reachable.has(b))continue;
    seen.add(b);paths.push([...path,b]);
   }
  }
  return result?{status:'connected',result}:{status:'no_safe_same_level_route'};
 };
 for(const p of m.pieces.filter(p=>p.asset==='casa-morro'&&recipe.houses.includes(p.id))){
  const currentRight=p.props.variante?.endsWith('-direita')||false;
  let right=currentRight,choice=route(p,right);
  if(choice.status!=='connected'){
   const alternate=route(p,!right);
   if(alternate.status==='connected'){right=!right;choice=alternate;}
  }
  if(choice.status!=='connected'){approaches.push({house:p.id,status:choice.status});continue;}
  const result=choice.result;
  const base=(p.props.variante||'telha').replace(/-direita$/,'');
  property(objects.find(o=>o.id===p.id),'variante',base+(right?'-direita':''));
  for(const i of result)if(m.cells[i].material==='construcao'){ground.data[i]=pavement;changes.add(i);}
  const old=earlier?.approaches.find(a=>a.house===p.id&&a.status==='connected'&&(a.doorFace||'v+')===(right?'u+':'v+')&&a.cells.every(([u,v])=>!occupied.has(v*m.w+u)));
  approaches.push({...(old||{house:p.id,status:'connected',cells:result.map(i=>[i%m.w,Math.floor(i/m.w)])}),doorFace:right?'u+':'v+'});
 }
 const output=compile(raw,id);
 fs.writeFileSync(file,JSON.stringify(raw,null,2)+'\n');
 fs.writeFileSync(`godot/assets/overworld/maps/${id}.json`,JSON.stringify(output));
 report.push({id,yardHouses,changedCells:[...changes].map(i=>[i%m.w,Math.floor(i/m.w)]),approaches});
}
fs.writeFileSync(reportFile,JSON.stringify(report,null,2)+'\n');
console.log(report.map(r=>({area:r.id,cells:r.changedCells.length,connected:r.approaches.filter(a=>a.status==='connected').length})));
