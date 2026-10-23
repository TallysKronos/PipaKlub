// Rua dos Ventos: one plan for ground, props, portals and navigable space.
// Map coordinates remain orthogonal; the renderer projects them at 2:1.
export const STREET_LAYOUT={version:2,width:2816,height:2112,actorHeight:100,
 road:{x:128,y:880,w:2560,h:336},
 sidewalks:[{x:128,y:736,w:2560,h:144},{x:128,y:1216,w:2560,h:160}],
 plaza:{x:896,y:1344,w:960,h:480},
 houses:[
  {asset:'house',x:480,y:640,w:416,gridFootprint:[7,6],doorCell:[3.9,5.75],target:'kael-home',name:'Casa de Kael',id:11},
  {asset:'professorHouse',x:1376,y:640,w:384,gridFootprint:[7,5],doorCell:[3.9,4.75],target:'professor-home',name:'Casa do Sr. Assis',id:12},
  {asset:'shop',x:2240,y:640,w:384,gridFootprint:[7,5],doorCell:[3.9,4.75],target:'kite-shop',name:'Loja de pipas',id:13},
 ],
 destinations:[
  {id:14,name:'Explorar a cidade',x:2592,y:1040,action:'city'},
  {id:15,name:'Mural · amigos',x:1008,y:1520,action:'friends'},
  {id:16,name:'Mural · trocas',x:1008,y:1584,action:'trades'},
  {id:17,name:'Seus parceiros',x:1376,y:1632,action:'collection'},
  {id:150,name:'Parque dos Ventos · exploração',x:1792,y:1808,action:'farm'},
 ],
};
export function streetWalkable(){const p=STREET_LAYOUT;return [
 {...p.road,material:'road'},...p.sidewalks.map(r=>({...r,material:'sidewalk'})),
 {...p.plaza,material:'sidewalk'},
 ...p.houses.map(h=>({x:h.x-112,y:640,w:224,h:160,material:'sidewalk'})),
 {x:1696,y:1760,w:192,h:192,material:'dirt'},
 ];}
export function streetObjects(){const p=STREET_LAYOUT;
 const o=(asset,x,y,w,extra={})=>({asset,x,y,w,...extra});
 return [
  ...p.houses.map(h=>({...h,action:'street_scene'})),
  o('noticeboard',1008,1472,156,{action:'friends'}),
  o('workbench',1376,1568,164,{action:'collection'}),
  o('gate',1792,1856,210,{action:'street_scene',target:'park-trail'}),
  o('park:bench',1632,1472,140),o('park:bench',672,1312,140),o('park:bench',2368,1312,140),
  o('park:windsock',1968,1840,160),
  o('park:lamp',672,704,44),o('park:lamp',1568,704,44),o('park:lamp',2432,704,44),
  o('park:bunting',2240,560,220,{lift:110}),o('park:kite',1920,1840,105,{lift:270}),
  ...[[288,656],[1184,656],[2048,656],[688,1376],[2368,1376],[1024,1856],[1600,1872]].map(([x,y])=>o('park:flowers',x,y,95)),
  ...[[208,640],[960,608],[1840,608],[2640,656],[384,1472],[2112,1504]].map(([x,y],i)=>o('park:tree',x,y,220+i%2*18)),
  ...[[832,1376],[1984,1408],[768,1760],[1984,1888],[384,768],[1152,768],[2016,768]].map(([x,y])=>o('park:shrub',x,y,92)),
  ...Array.from({length:14},(_,i)=>o('park:tree',-64+i*224,288+(i%3)*35,250+i%2*12)),
  ...Array.from({length:8},(_,i)=>o('park:tree',-32,576+i*208,250)),
  ...Array.from({length:8},(_,i)=>o('park:tree',2848,576+i*208,250)),
  ...Array.from({length:13},(_,i)=>o('park:tree',160+i*224,2144+(i%2)*40,250)),
 ];}
export function streetMap(){const p=STREET_LAYOUT;let id=200;
 const props=o=>Object.entries(o).map(([name,value])=>({name,type:typeof value==='number'?'int':typeof value==='boolean'?'bool':'string',value}));
 const rect=(name,r,properties={level:0},fixedId)=>({id:fixedId??id++,name,x:r.x,y:r.y,width:r.w,height:r.h,properties:props(properties)});
 const zone=d=>rect(d.name,{x:d.x-24,y:d.y-24,w:48,h:48},{action:d.action,...d.target?{target:d.target}:{}},d.id);
 const layers={
  Walkable:streetWalkable().map((r,i)=>rect('Chão '+i,r,{level:0,ground_frame:r.material})),
  Solids:[...p.houses.map(h=>{const unit=32/.82;return rect(h.asset,{x:h.x-h.doorCell[0]*unit,y:h.y-h.doorCell[1]*unit,w:h.gridFootprint[0]*unit,h:h.gridFootprint[1]*unit});}),...streetObjects().filter(o=>!o.target&&['noticeboard','workbench','park:bench'].includes(o.asset)).map(o=>rect(o.asset,{x:o.x-40,y:o.y-32,w:80,h:32}))],
  Foreground:[],
  Interactions:[...p.houses.map(h=>zone({...h,y:h.y+48,action:'street_scene'})),...p.destinations.map(zone)],
  Spawns:[rect('Entrada da rua',{x:456,y:744,w:48,h:48},{level:0})],Exits:[],
 };
 return {type:'map',orientation:'orthogonal',infinite:false,width:p.width/32,height:p.height/32,tilewidth:32,tileheight:32,properties:props({scene_name:'Rua dos Ventos',overview:false,actor_height:p.actorHeight,foot_radius:10,layout_version:p.version}),layers:Object.entries(layers).map(([name,objects],i)=>({id:i+1,name,type:'objectgroup',objects}))};
}
