import fs from 'node:fs';

const plans = {
  a: {rooms:[[23,34,27,39],[16,21,34,34],[22,13,29,21],[23,0,27,13]], duel:[30,27], columns:[[18,24],[18,30],[31,22],[31,31]], axis:25},
  b: {rooms:[[23,31,27,39],[12,26,27,31],[12,14,17,26],[12,10,28,16],[23,0,27,10]], duel:[14,18], columns:[[18,28],[23,28],[13,12],[22,12]], axis:25},
  c: {rooms:[[23,31,27,39],[18,20,31,31],[22,12,28,20],[16,5,33,12]], duel:[24,16], columns:[[19,23],[29,23],[19,7],[30,7]], axis:25},
};

for (const [part, plan] of Object.entries(plans)) {
  const file = new URL('../../godot/assets/overworld/maps/kronasta-coracao-'+part+'.json',import.meta.url);
  const map = JSON.parse(fs.readFileSync(file,'utf8'));
  map.forest = {interior:true, chamber:true, gallery:true};
  map.cells = Array.from({length:map.w*map.h},(_,i)=>{
    const u=i%map.w,v=Math.floor(i/map.w);
    const floor=plan.rooms.some(([a,b,c,d])=>u>=a&&v>=b&&u<=c&&v<=d);
    const material=floor?'piso':'rocha';
    return {material,level:0,ramp:null,corners:Array(4).fill(material)};
  });
  map.pieces = plan.columns.map(([u,v],i)=>({id:31120+i,asset:'elo-pilar',name:'Pilar de basalto',u,v,fu:1,fv:1,blocks:true,interact:null,props:{}}));
  const [asset,u,v]= {a:['carretel',32,25],b:['carretel',13,20],c:['fragmentos',30,9]}[part];
  map.pieces.push({id:31129,asset:'elo-'+asset,name:asset,u,v,fu:1,fv:1,blocks:true,interact:null,props:{}});
  const forward=map.events.find(e=>e.id===31001);
  const duel=map.events.find(e=>e.id===31002);
  [duel.u,duel.v]=plan.duel;
  duel.name="Capanga do Cerol";
  delete duel.props.npcIdentity;
  duel.props.storySpritePath="res://assets/overworld/kits/camara-do-elo-v1/capanga-"+(part==="b"?"masculino":"feminina")+"-idle-eight.png";
  duel.props.storySpriteRegion={x:448,y:0,w:64,h:96};
  if(part==="c"){duel.name="Grampo";duel.props.storySpritePath="res://assets/campaign/beira-canal-v1/grampo-idle-eight.png";duel.props.storySpriteRegion={x:192,y:96,w:64,h:96};}
  const prisoner=map.events.find(e=>e.id===31003);
  if(prisoner){prisoner.u=duel.u+1;prisoner.v=duel.v-2;}
  if(part==='c'){forward.u=25;forward.v=6;}
  if(part!=='a')Object.assign(map.events.find(e=>e.id===31000).props,{chegada_u:25,chegada_v:2});
  map.spawn.name=map.name;
  map.events.find(e=>e.type==='entrada').name=map.name;
  delete map.audit;
  const solid=new Set(map.pieces.map(piece=>piece.v*map.w+piece.u));
  const reached=new Set();
  const queue=[[map.spawn.u,map.spawn.v]];
  for(const [u,v] of queue){
    if(u<0||v<0||u>=map.w||v>=map.h)continue;
    const id=v*map.w+u;
    if(reached.has(id)||solid.has(id)||map.cells[id].material!=='piso')continue;
    reached.add(id);
    queue.push([u+1,v],[u-1,v],[u,v+1],[u,v-1]);
  }
  for(const event of map.events)if(!reached.has(event.v*map.w+event.u))throw Error(part+': evento inalcançável '+event.id);
  if(reached.size!==map.cells.filter(c=>c.material==='piso').length-solid.size)throw Error(part+': bolsão isolado');
  const walkable=[...reached].sort((a,b)=>a-b);
  const edges=[];
  for(const from of walkable){
    const u=from%map.w,v=Math.floor(from/map.w);
    for(const [du,dv] of [[1,0],[-1,0],[0,1],[0,-1]]){
      const x=u+du,y=v+dv;
      if(x<0||y<0||x>=map.w||y>=map.h)continue;
      const to=y*map.w+x;
      if(reached.has(to))edges.push([from,to]);
    }
  }
  // These three galleries are flat; the Chamber of the Elo has its own generator.
  map.oracle={walkable,edges,heightProbes:[]};
  fs.writeFileSync(file,JSON.stringify(map));
  console.log(part.toUpperCase()+': '+reached.size+' células ligadas; entrada, duelo, avanço e retorno alcançáveis');
}


