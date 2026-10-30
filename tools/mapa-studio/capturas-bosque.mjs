import fs from 'node:fs';
const root=new URL('../../',import.meta.url);
export function writeCapturePlan(map,features={}){
 const shots=[{name:'area-inteira',u:map.w/2,v:map.h/2,zoom:.36,kind:'geral'}];
 const add=(name,u,v,zoom=2.3,kind='junta')=>shots.push({name,u,v,zoom,kind});
 add('entrada',map.spawn.u+.5,map.spawn.v+.5,1,'jogo');
 add('centro',map.w/2,map.h/2,1,'jogo');
 for(const e of map.events.filter(e=>e.type==='saida'))add('saida-'+e.u+'-'+e.v,e.u+.5,e.v+.5,1,'jogo');
 // Toda mudança de contorno de cada faixa de cota: 1/3 cantos convexos e côncavos,
 // diagonal 2+2, e contato com rampa; inclui as bordas ocultas na vista geral.
 for(let level=1;level<=2;level++)for(let v=1;v<map.h;v++)for(let u=1;u<map.w;u++){
  const cells=[[u-1,v-1],[u,v-1],[u,v],[u-1,v]].map(([x,y])=>map.cells[y*map.w+x]);
  const bits=cells.map(c=>c.level>=level&&!c.ramp),n=bits.filter(Boolean).length;
  if(n===1||n===3||(n===2&&bits[0]===bits[2]))add(`canto-n${level}-${u}-${v}`,u,v);
 }
 map.cells.forEach((c,i)=>{if(!c.ramp)return;const u=i%map.w,v=Math.floor(i/map.w);
  if((c.rampFrom??0)===0)add(`rampa-pe-${u}-${v}`,u+.5,v+.5);
  if((c.rampTo??1)===1){add(`rampa-topo-${u}-${v}`,u+.5,v+.5);add(`plato-${u}-${v}`,u+.5,v+.5,1,'jogo');}
 });
 if(features.water){
  features.water.contour.forEach(([u,v],i)=>add('poco-contorno-'+i,u,v));
  for(const u of [0,12,24,36,51])add('riacho-margem-'+u,u,22+Math.sin(u*.13)*2);
 }
 const joins=new Map();for(const g of features.guards??[]){const a=g.side==='u'?[g.u+1,g.v]:[g.u,g.v+1],b=[g.u+1,g.v+1];for(const p of[a,b]){const k=p.join(',');const entry=joins.get(k)??{u:p[0],v:p[1],sides:[]};entry.sides.push(g.side);joins.set(k,entry);}}
 for(const j of joins.values())if(j.sides.length===1||new Set(j.sides).size>1)add('mureta-junta-'+j.u+'-'+j.v,j.u,j.v);
 for(const shot of features.shots??[])add(shot.name,shot.u,shot.v,shot.zoom??2.3,shot.kind??'junta');
 const dir=new URL('documentation/overworld/kronasta/planos/',root);fs.mkdirSync(dir,{recursive:true});
 fs.writeFileSync(new URL(map.id+'.json',dir),JSON.stringify({area:map.id,shots},null,2)+'\n');
 return shots;
}
