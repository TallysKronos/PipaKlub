// PIP-87 set dressing only: fill already-blocked lots, never change paths/height.
import fs from 'node:fs';
import {parseTiled,walkable,canStep,blockedByPiece,audit} from '../mapa-studio/model.mjs';
const dir='art/overworld/mapas/';
const sets={'rascunho.tsj':JSON.parse(fs.readFileSync('art/overworld/tiles/rascunho.tsj','utf8'))};
const directions={'u+':[1,0],'u-':[-1,0],'v+':[0,1],'v-':[0,-1]};
const property=(name,value)=>({name,type:typeof value==='boolean'?'bool':'string',value});
const result=[];
for(const file of fs.readdirSync(dir).filter(f=>f.startsWith('morro-')&&f.endsWith('.tmj'))){
 const raw=JSON.parse(fs.readFileSync(dir+file,'utf8'));
 const layer=raw.layers.find(l=>l.name==='pecas');
 // Idempotent regeneration of this dressing; keep all source/user objects.
 layer.objects=layer.objects.filter(o=>!o.properties?.some(p=>p.name==='origem'&&p.value==='PIP-87 vestir lote bloqueado'));
 const before=parseTiled(raw,sets);const reserved=new Set();
 for(const p of before.pieces)for(let dv=0;dv<p.fv;dv++)for(let du=0;du<p.fu;du++)reserved.add((p.v+dv)*before.w+p.u+du);
 const protectedCells=new Set();
 for(const e of before.events)for(let dv=-1;dv<=1;dv++)for(let du=-1;du<=1;du++)protectedCells.add((e.v+dv)*before.w+e.u+du);
 let nextId=Math.max(...raw.layers.flatMap(l=>(l.objects||[]).map(o=>o.id)),0)+1;let houses=0,walls=0;
 const add=(asset,variant,u,v,fu,fv,blocks)=>{
  layer.objects.push({id:nextId++,name:asset==='casa-morro'?'Casa de fundo':'Mureta de quintal',type:'peca',x:u*32+16,y:v*32+16,point:true,width:0,height:0,rotation:0,visible:true,properties:[property('asset',asset),property('variante',variant),property('pegada',`${fu}x${fv}`),property('bloqueia',blocks),property('origem','PIP-87 vestir lote bloqueado')]});
 };
 const preferred=file.includes('laje')?['laje','laje','telha']:file.includes('escadaria')?['muro-chapisco','telha','muro-chapisco']:['telha','laje','muro-chapisco'];
 for(let v=0;v<=before.h-3;v++)for(let u=0;u<=before.w-3;u++){
  const ids=[];for(let dv=0;dv<3;dv++)for(let du=0;du<3;du++)ids.push((v+dv)*before.w+u+du);
  const level=before.cells[v*before.w+u].level;
  if(ids.some(i=>reserved.has(i)||protectedCells.has(i)||before.cells[i].material!=='construcao'||before.cells[i].level!==level||before.cells[i].ramp))continue;
  add('casa-morro',preferred[houses%preferred.length],u,v,3,3,true);houses++;
  ids.forEach(i=>reserved.add(i));
 }
 for(let v=0;v<before.h;v++)for(let u=0;u<before.w;u++){
  const id=v*before.w+u,c=before.cells[id];if(c.material!=='construcao'||reserved.has(id)||protectedCells.has(id))continue;
  for(const[direction,[du,dv]]of Object.entries(directions)){
   const x=u+du,y=v+dv;if(x<0||y<0||x>=before.w||y>=before.h)continue;
   const next=before.cells[y*before.w+x];
   if(next.level===c.level&&['piso','calcada','grama'].includes(next.material)&&!next.ramp){add('muro-quintal',direction,u,v,1,1,false);walls++;}
  }
 }
 raw.nextobjectid=nextId;
 const after=parseTiled(raw,sets),sa=blockedByPiece(before),sb=blockedByPiece(after);
 for(let v=0;v<before.h;v++)for(let u=0;u<before.w;u++){
  if(walkable(before,u,v,sa)!==walkable(after,u,v,sb))throw Error(`${file}: alteração de navegação`);
  for(const[du,dv]of Object.values(directions))if(canStep(before,{u,v},{u:u+du,v:v+dv},sa)!==canStep(after,{u,v},{u:u+du,v:v+dv},sb))throw Error(`${file}: conexão alterada`);
 }
 const failures=audit(after).filter(i=>i.level==='fail');if(failures.length)throw Error(JSON.stringify(failures));
 fs.writeFileSync(dir+file,JSON.stringify(raw,null,2)+'\n');result.push({area:file.slice(0,-4),houses,walls,navigationUnchanged:true,levelUnchanged:true});
}
fs.mkdirSync('documentation/overworld/reports',{recursive:true});fs.writeFileSync('documentation/overworld/reports/dressing.json',JSON.stringify(result,null,2)+'\n');
console.log(result);
