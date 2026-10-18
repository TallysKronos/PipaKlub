// Tiled finite orthogonal object-map contract. Geometry is authored in map pixels.
export function createWorldGeometry(tiled){
 const {Walkable:walk,Solids:solids}=tiled.layers,radius=tiled.properties.foot_radius??12;
 const contains=(r,p)=>p.x>=r.x&&p.x<=r.x+r.w&&p.y>=r.y&&p.y<=r.y+r.h;
 const region=p=>walk.find(r=>contains(r,p));
 // A conservative square around the feet must be covered by the UNION of ground
 // rectangles. Partitioning at every boundary avoids cracks and missed thin gaps.
 function safe(p){
  if(!Number.isFinite(p?.x)||!Number.isFinite(p?.y))return false;
  const left=p.x-radius,right=p.x+radius,top=p.y-radius,bottom=p.y+radius;
  if(solids.some(r=>right>r.x&&left<r.x+r.w&&bottom>r.y&&top<r.y+r.h))return false;
  const xs=[left,right,...walk.flatMap(r=>[r.x,r.x+r.w]).filter(x=>x>left&&x<right)].sort((a,b)=>a-b);
  for(let i=1;i<xs.length;i++){
   const x=(xs[i-1]+xs[i])/2,spans=walk.filter(r=>x>=r.x&&x<=r.x+r.w).map(r=>[r.y,r.y+r.h]).sort((a,b)=>a[0]-b[0]);let covered=top;
   for(const [a,b]of spans){if(a>covered)break;if(b>=covered)covered=b;if(covered>=bottom)break;}
   if(covered<bottom)return false;
  }
  return !!region(p);
 }
 function transition(a,b){
  if(!a||!b)return false;if(a===b||a.properties.level===b.properties.level)return true;
  const stair=a.properties.connects_to===b.properties.level?a:b.properties.connects_to===a.properties.level?b:null;
  if(!stair)return false;const floor=stair===a?b:a;
  // Rectangular stairs only attach at their north/south ends, never through a side.
  return (stair.y===floor.y+floor.h||stair.y+stair.h===floor.y)&&Math.min(stair.x+stair.w,floor.x+floor.w)>Math.max(stair.x,floor.x);
 }
 function segment(a,b){
  if(!safe(a)||!safe(b))return false;
  // Swept foot bounds reject even sub-pixel walls between samples.
  const left=Math.min(a.x,b.x)-radius,right=Math.max(a.x,b.x)+radius,top=Math.min(a.y,b.y)-radius,bottom=Math.max(a.y,b.y)+radius;
  if(solids.some(r=>right>r.x&&left<r.x+r.w&&bottom>r.y&&top<r.y+r.h))return false;
  const count=Math.max(1,Math.ceil(Math.hypot(b.x-a.x,b.y-a.y)));let prev=region(a);
  for(let i=1;i<=count;i++){const p={x:a.x+(b.x-a.x)*i/count,y:a.y+(b.y-a.y)*i/count},next=region(p);if(!safe(p)||!transition(prev,next))return false;prev=next;}
  return true;
 }
 return {safe,segment,level:p=>region(p)?.properties.level??null,radius};
}

export function parseWorldMap(map){
 const fail=message=>{throw new Error('Mapa Tiled: '+message);};
 if(map?.type!=='map'||map.orientation!=='orthogonal'||map.infinite)fail('use mapa ortogonal finito.');
 for(const key of ['width','height','tilewidth','tileheight'])if(!Number.isInteger(map[key])||map[key]<=0)fail(key+' deve ser inteiro positivo.');
 const width=map.width*map.tilewidth,height=map.height*map.tileheight;
 if(width>16384||height>16384||map.width*map.height>65536)fail('dimensões excedem o limite de exploração.');
 const required=['Walkable','Solids','Foreground','Interactions','Spawns','Exits'],layers={},ids=new Set(),layerIds=new Set();
 const props=o=>Object.fromEntries((o.properties||[]).map(p=>[p.name,p.value]));
 function visit(list,ox=0,oy=0){
  if(!Array.isArray(list))fail('layers ausente.');
  for(const l of list){
   if(layerIds.has(l.id))fail('id de camada duplicado: '+l.id);layerIds.add(l.id);
   const x=ox+(l.offsetx||0),y=oy+(l.offsety||0);
   if(l.type==='group'){visit(l.layers,x,y);continue;}
   if(!required.includes(l.name))fail('camada não suportada: '+l.name);
   if(l.type!=='objectgroup'||layers[l.name])fail('camada deve ser um grupo de objetos único: '+l.name);
   if(l.x||l.y)fail('use offsetx/offsety para deslocar camadas.');
   layers[l.name]=(l.objects||[]).map(o=>{
    if(!Number.isInteger(o.id)||ids.has(o.id))fail('id de objeto inválido/duplicado: '+o.id);ids.add(o.id);
    if(o.rotation||o.polygon||o.polyline||o.ellipse||o.point||o.gid||o.template)fail('somente retângulos sem rotação: '+o.name);
    const r={id:o.id,name:o.name||'',x:o.x+x,y:o.y+y,w:o.width,h:o.height,properties:props(o)};
    if(![r.x,r.y,r.w,r.h].every(Number.isFinite)||r.w<=0||r.h<=0||r.x<0||r.y<0||r.x+r.w>width||r.y+r.h>height)fail('retângulo fora do mapa ou inválido: '+o.name);
    return r;
   });
  }
 }
 visit(map.layers);for(const name of required)if(!layers[name])fail('camada obrigatória ausente: '+name);
 if((map.tilesets||[]).length)fail('tilesets ainda não suportados neste contrato de blockout.');
 const properties=props(map),actorSize=properties.actor_height??64,radius=properties.foot_radius??12;
 if(!Number.isFinite(actorSize)||actorSize<=0||!Number.isFinite(radius)||radius<=0||radius>=Math.min(map.tilewidth,map.tileheight)/2)fail('escala do ator ou raio dos pés inválido.');
 const contains=(r,x,y)=>x>=r.x&&x<=r.x+r.w&&y>=r.y&&y<=r.y+r.h;
 for(const r of layers.Walkable){if(!Number.isInteger(r.properties.level)||r.properties.level<0)fail('Walkable exige level inteiro: '+r.name);if(r.properties.connects_to!==undefined&&(!Number.isInteger(r.properties.connects_to)||r.properties.connects_to===r.properties.level||!layers.Walkable.some(s=>s.properties.level===r.properties.connects_to)))fail('conexão de nível inválida: '+r.name);}
 for(const a of layers.Walkable)for(const b of layers.Walkable)if(a.id<b.id&&a.properties.level!==b.properties.level&&Math.min(a.x+a.w,b.x+b.w)>Math.max(a.x,b.x)&&Math.min(a.y+a.h,b.y+b.h)>Math.max(a.y,b.y))fail('pisos sobrepostos exigem contrato próprio: '+a.name+'/'+b.name);
 for(const r of [...layers.Solids,...layers.Foreground]){
  const level=r.properties.level??0,sortY=r.properties.sort_y??r.y+r.h;
  if(!Number.isInteger(level)||!layers.Walkable.some(w=>w.properties.level===level))fail('piso visual inválido: '+r.name);
  if(!Number.isFinite(sortY)||sortY<0||sortY>height)fail('sort_y inválido: '+r.name);
  r.properties.level=level;r.properties.sort_y=sortY;
 }
 const geometry=createWorldGeometry({layers,properties});
 const nodes=[],regions=[],lookup=new Map();
 for(let row=0;row<map.height;row++)for(let col=0;col<map.width;col++){
  const x=(col+.5)*map.tilewidth,y=(row+.5)*map.tileheight,r=layers.Walkable.find(r=>contains(r,x,y));
  if(!r||!geometry.safe({x,y}))continue;
  lookup.set(col+','+row,nodes.length);nodes.push([x,y]);regions.push(r);
 }
 const edges=[];
 for(const [key,a]of lookup){const [col,row]=key.split(',').map(Number);for(const [dx,dy]of [[1,0],[0,1]]){const b=lookup.get((col+dx)+','+(row+dy));if(b===undefined)continue;const ra=regions[a],rb=regions[b],la=ra.properties.level,lb=rb.properties.level;
  if((la===lb||ra.properties.connects_to===lb||rb.properties.connects_to===la)&&geometry.segment({x:nodes[a][0],y:nodes[a][1]},{x:nodes[b][0],y:nodes[b][1]}))edges.push([a,b]);
 }}
 if(!edges.length)fail('nenhum caminho conectado.');
 function nodeFor(r){const cx=r.x+r.w/2,cy=r.y+r.h/2;let best=-1,d=Infinity;nodes.forEach(([x,y],i)=>{if(!contains(r,x,y)||r.properties.level!==undefined&&regions[i].properties.level!==r.properties.level)return;const n=Math.hypot(x-cx,y-cy);if(n<d){best=i;d=n;}});if(best<0)fail('zona sem ponto acessível: '+r.name);return best;}
 if(layers.Spawns.length!==1)fail('exatamente um spawn obrigatório.');
 const spawn=nodeFor(layers.Spawns[0]),seen=new Set([spawn]),queue=[spawn],adj=nodes.map(()=>[]);for(const [a,b]of edges){adj[a].push(b);adj[b].push(a);}for(let i=0;i<queue.length;i++)for(const b of adj[queue[i]])if(!seen.has(b)){seen.add(b);queue.push(b);}
 const stages=new Set(),places=[...layers.Exits,...layers.Interactions].map(r=>{const node=nodeFor(r),stage=r.properties.stage,action=r.properties.action;if(!seen.has(node))fail('zona inacessível a partir do spawn: '+r.name);if(stage){if(stages.has(stage))fail('stage duplicado: '+stage);stages.add(stage);}if(!stage&&!action)fail('zona sem action/stage: '+r.name);return {id:'tiled-'+r.id,name:r.name,node,...stage?{stage}:{action}};});
 return {name:'Morro do Sol · piloto',width,height,actorSize,spawn,nodes,edges,places,tiled:{layers,properties,levels:regions.map(r=>r.properties.level)}};
}

export function drawWorldBlockout(g,scene){
 g.fillStyle='#e6dfcb';g.fillRect(0,0,scene.width,scene.height);
 for(const r of scene.tiled.layers.Walkable){
  g.fillStyle='#d7bf8f';g.fillRect(r.x,r.y,r.w,r.h);g.strokeStyle='#695843';g.lineWidth=2;g.strokeRect(r.x,r.y,r.w,r.h);
  if(r.properties.connects_to!==undefined){g.beginPath();for(let y=r.y+16;y<r.y+r.h;y+=16){g.moveTo(r.x,y);g.lineTo(r.x+r.w,y);}g.stroke();}
 }
 g.font='16px sans-serif';g.fillStyle='#493e32';g.fillText('Morro do Sol · estudo de circulação · arte final pendente',32,48);
}

// Ground first; then one deterministic queue of solid bases, upper parts and actors.
// A higher floor always paints after a lower one, independent of screen Y.
export function worldRenderQueue(scene,actors){
 const entries=actors.map((a,i)=>({...a,level:a.level??0,kind:'actor',order:i}));
 if(scene.art)for(const entry of scene.art.objects)entries.push({...entry,order:entries.length});
 else if(scene.tiled)for(const name of ['Solids','Foreground'])for(const r of scene.tiled.layers[name])entries.push({kind:name==='Solids'?'solid':'foreground',rect:r,level:r.properties.level,y:r.properties.sort_y,order:entries.length});
 const player=actors.find(a=>a.id==='player'),size=scene.actorSize||64;
 for(const e of entries)if(e.kind==='foreground'&&player){const r=e.sprite||e.rect;e.opacity=e.level===(player.level??0)&&e.y>player.y&&player.x+size*.3>r.x&&player.x-size*.3<r.x+r.w&&player.y>r.y&&player.y-size<r.y+r.h?.45:1;}
 return entries.sort((a,b)=>a.level-b.level||a.y-b.y||((a.kind==='actor'?2:a.kind==='foreground'?1:0)-(b.kind==='actor'?2:b.kind==='foreground'?1:0))||a.order-b.order);
}

export function drawWorldObject(g,entry,images){
 if(entry.sprite){const s=entry.sprite,image=images?.get('world-kit-'+s.sheet);if(image){g.save();g.globalAlpha*=entry.opacity??1;g.drawImage(image,s.sx,s.sy,s.sw,s.sh,s.x,s.y,s.w,s.h);g.restore();}return;}
 const r=entry.rect,kind=r.properties.visual_kind;
 g.save();g.globalAlpha*=entry.opacity??1;g.fillStyle=entry.kind==='solid'?'#a76c4f':kind==='tree'?'#568963':kind==='wall'?'#c19a6b':'#955642';g.strokeStyle='#695843';g.lineWidth=2;
 if(kind==='tree'&&entry.kind==='foreground'){g.beginPath();g.ellipse(r.x+r.w/2,r.y+r.h/2,r.w/2,r.h/2,0,0,Math.PI*2);g.fill();g.stroke();}
 else {g.fillRect(r.x,r.y,r.w,r.h);g.strokeRect(r.x,r.y,r.w,r.h);}
 g.restore();
}
