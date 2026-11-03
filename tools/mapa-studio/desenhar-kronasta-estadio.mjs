import fs from 'node:fs';
const file = new URL('../../godot/assets/overworld/maps/kronasta-estadio-a.json', import.meta.url);
const map = JSON.parse(fs.readFileSync(file,'utf8'));
for (let v=0; v<map.h; v++) {
  for (let u=0; u<map.w; u++) {
    const hall = u>=16 && u<=32 && v>=3 && v<=17;
    const vestibule = u>=22 && u<=26 && v>=18 && v<=21;
    const material = hall || vestibule ? 'piso' : 'bosque';
    map.cells[v*map.w+u] = {material,level:0,ramp:null,corners:Array(4).fill(material)};
  }
}
map.spawn.v = 19;
map.events.find(e=>e.type==='entrada').v = 19;
map.events.find(e=>e.id===32001).v = 21;
map.name = 'Lobby do Estádio de Kronasta';
map.forest.stairs = [];
map.forest.guards = [];
map.forest.market = false;
map.forest.interior = true;
map.pieces = [
 ['balcao',23,7,3,1,112], ['painel',16,6,1,3,123], ['bancos',17,13,2,4,155], ['poltrona',17,10,2,2,93], ['mesa',19,12,1,1,58],
 ['jardineira',18,5,2,2,86], ['jardineira',29,13,2,2,86], ['expositor',28,10,2,1,91], ['bebedouro',30,11,1,1,59],
].map(([asset,u,v,fu,fv,width],index)=>({id:32100+index,name:asset,asset,u,v,fu,fv,blocks:true,props:{width}}));
map.events.find(event=>event.id===32002).name = 'Atendente do campeonato';
map.events.find(event=>event.id===32002).props.npcIdentity = 'professor';
fs.writeFileSync(file,JSON.stringify(map));
console.log('Lobby: acesso da rua, espera, credenciamento e túnel.');




