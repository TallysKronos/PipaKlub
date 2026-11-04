import fs from 'node:fs';
const file = new URL('../../godot/assets/overworld/maps/kronasta-coracao-d.json',import.meta.url);
const map = JSON.parse(fs.readFileSync(file,'utf8'));
map.forest = {interior:true, chamber:true, closedStairs:true, stairs:[{u:22,v:20,width:4,length:2}]};
map.cells = Array.from({length:map.w*map.h},(_,i)=>{
  const u=i%map.w,v=Math.floor(i/map.w);
  const hall=u>=15&&u<=31&&v>=11&&v<=35;
  const entry=u>=23&&u<=27&&v>=36;
  const altar=u>=19&&u<=28&&v>=12&&v<=19;
  const ramp=u>=22&&u<=25&&(v===20||v===21);
  const material=hall||entry?'piso':'rocha';
  return {material,level:altar?1:0,ramp:ramp?'v-':null,...(ramp?{rampFrom:v===20?.5:0,rampTo:v===20?1:.5}:{}),corners:Array(4).fill(material)};
});
map.pieces=[];
for (const u of [17,29]) for (const v of [22,27,32])
  map.pieces.push({id:31100+map.pieces.length,asset:'elo-pilar',name:'Pilar',u,v,fu:2,fv:2,blocks:true,interact:null,props:{}});
map.pieces.push({id:31106,asset:'elo-fossil',name:'Enamor fossilizado',u:21,v:13,fu:6,fv:3,blocks:true,interact:null,props:{}});
map.events.find(e=>e.id===31002).u=24;
map.events.find(e=>e.id===31002).v=17;
map.spawn.name='Entrada da Câmara do Elo';
map.events.find(e=>e.type==='entrada').name=map.spawn.name;
fs.writeFileSync(file,JSON.stringify(map));
console.log('Câmara do Elo: eixo central, seis pilares laterais e altar acessível por rampa v-.');

