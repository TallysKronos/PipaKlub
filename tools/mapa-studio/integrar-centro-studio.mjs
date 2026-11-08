import fs from 'node:fs';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';

const root=new URL('../../godot/assets/overworld/maps/',import.meta.url);
const layouts={
  a:[
    ['fonte','Fonte da Praça da Matriz',27,19],
    ['jardineira','Banco do jardim oeste',15,24],
    ['jardineira','Banco do jardim leste',32,24],
    ['bancada','Bancada de pipas',17,26],
    ['poste','Iluminação da alameda',21,35],
    ['poste','Iluminação da alameda',27,35],
  ],
  b:[
    ['jardineira','Banco do estúdio',33,12],
    ['poste','Iluminação do estúdio',32,13],
    ['bancada','Bancada de demonstração',31,14],
  ],
  c:[
    ['jardineira','Banco da arena',30,16],
    ['jardineira','Banco da arena',18,16],
    ['poste','Iluminação da arena',21,11],
    ['poste','Iluminação da arena',26,11],
  ],
};
// Paved aprons connect the Studio landmarks to the existing campaign paths.
const aprons={
  a:[[24,18,28,21,0],[16,28,31,33,0]],
  b:[[30,11,34,14,1]],
  c:[[18,15,20,16,1],[28,15,30,16,1]],
};
const key=(map,u,v)=>v*map.w+u;
function accessible(start,edges){
  const graph=new Map();
  for(const [from,to] of edges){
    if(!graph.has(from))graph.set(from,[]);
    graph.get(from).push(to);
  }
  const queue=[start],seen=new Set(queue);
  for(const from of queue)for(const to of graph.get(from)??[]){
    if(seen.has(to))continue;
    seen.add(to);
    queue.push(to);
  }
  return seen;
}

function paintAprons(map,rectangles){
  const changed=new Set();
  for(const [left,top,right,bottom,level] of rectangles){
    for(let v=top;v<=bottom;v++)for(let u=left;u<=right;u++){
      const i=key(map,u,v),cell=map.cells[i];
      if(cell.material!=='grama'||cell.level!==level||cell.ramp)continue;
      cell.material='piso';
      for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++)changed.add(key(map,u+dx,v+dy));
    }
  }
  for(const i of changed){
    const u=i%map.w,v=Math.floor(i/map.w);
    map.cells[i].corners=[[u,v],[u+1,v],[u+1,v+1],[u,v+1]].map(([x,y])=>{
      const votes=new Map();
      for(const [du,dv] of [[-1,-1],[0,-1],[0,0],[-1,0]]){
        const material=map.cells[key(map,x+du,y+dv)].material;
        votes.set(material,(votes.get(material)??0)+1);
      }
      return [...votes].sort((a,b)=>b[1]-a[1]||a[0].localeCompare(b[0]))[0][0];
    });
  }
  return changed.size>0;
}

export function integrateDistrict(district,layouts,aprons){
 for(const [part,placements] of Object.entries(layouts)){
  const file=new URL('kronasta-'+district+'-'+part+'.json',root);
  const map=JSON.parse(fs.readFileSync(file));
  const start=key(map,map.spawn.u,map.spawn.v);
  const original=accessible(start,map.oracle.edges);
  const occupied=new Set(map.oracle.walkable);
  let nextId=Math.max(...map.pieces.map(piece=>piece.id),...map.events.map(event=>event.id))+1;
  const additions=[];
  for(const [kind,name,u,v,fu=1,fv=1] of placements){
    const asset=district+'-'+kind;
    if(map.pieces.some(piece=>piece.u===u&&piece.v===v&&piece.asset===asset))continue;
    const level=map.cells[key(map,u,v)].level;
    for(let y=v;y<v+fv;y++)for(let x=u;x<u+fu;x++){
      const cell=key(map,x,y);
      assert.ok(occupied.has(cell)&&original.has(cell)&&!map.cells[cell].ramp&&map.cells[cell].level===level,
        `${name}: apoio inválido em ${x},${y}`);
      assert.ok(!map.events.some(event=>event.u===x&&event.v===y),`${name}: evento no mesmo espaço`);
      occupied.delete(cell);
    }
    const piece={id:nextId++,name,asset,u,v,fu,fv,blocks:true,interact:null,props:{asset,pegada:fu+'x'+fv,bloqueia:true}};
    additions.push(piece);
  }
  const painted=paintAprons(map,aprons[part]);
  if(!additions.length&&!painted)continue;
  const edges=map.oracle.edges.filter(([from,to])=>occupied.has(from)&&occupied.has(to));
  const reachable=accessible(start,edges);
  for(const cell of original){
    if(occupied.has(cell))assert.ok(reachable.has(cell),`${district} ${part}: acesso perdido na célula ${cell}`);
  }
  map.pieces.push(...additions);
  map.oracle.edges=edges;
  map.oracle.walkable=map.oracle.walkable.filter(cell=>occupied.has(cell));
  fs.writeFileSync(file,JSON.stringify(map));
  console.log(district,part.toUpperCase(),additions.length+' peças,',reachable.size+' células alcançáveis.');
 }
}

if(process.argv[1]===fileURLToPath(import.meta.url))integrateDistrict('centro',layouts,aprons);
