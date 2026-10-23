import * as BedroomIso from '../tools/iso-studio/model.mjs';
// Iso Studio is the source of footprints, height, anchors and draw order.
export const bedroomProject=BedroomIso.presetKaelRoom();
export const bedroomProjectPoint=({x,y})=>({x:(x-y)/3,y:(x+y)/6});
export const bedroomUnprojectPoint=({x,y})=>({x:1.5*x+3*y,y:3*y-1.5*x});
const bedroomFloor={x:384,y:288,w:960,h:768};
const bedroomWorldRect=p=>{const r=BedroomIso.footprintRect(p);return [384+r.u0*96,288+r.v0*96,(r.u1-r.u0)*96,(r.v1-r.v0)*96];};
export const BEDROOM_LAYOUT={
 version:3,floor:bedroomFloor,wallHeight:160,actorHeight:102,
 rug:{x:672,y:576,w:480,h:288},
 objects:bedroomProject.pieces.filter(p=>p.kind==='floor'&&!p.elevation).map(p=>({asset:p.id,footprint:bedroomWorldRect(p),anchor:[384+p.cell[0]*96,288+p.cell[1]*96],w:BedroomIso.pieceBox(p).w})),
 stairwell:{x:384,y:864,w:288,h:192},
 wallArt:{window:{wall:'left',start:480,length:192,bottom:70.4,height:48},drawings:{wall:'back',start:1104,length:192,bottom:76.8,height:32}},
 hotspots:[
  {id:'tv',name:'Televisão',x:768,y:496},
  {id:'drawings',name:'Desenhos anteriores',x:1248,y:576},
  {id:'desk',name:'Projeto do Rabbito',x:1200,y:528},
  {id:'stairs',name:'Escada para a sala',x:528,y:816},
 ],
 blocking:{kaelTV:[768,496],kaelDesk:[1200,528],motherEntry:[528,816],mother:[880,640],kaelTalk:[1030,610],kaelBirth:[990,640],rabbito:[1145,640],rabbitoNear:[1100,640]},
};
export function bedroomObjects(){
 const p=BEDROOM_LAYOUT;
 return [...p.objects.map(o=>({...o,x:o.anchor[0],y:o.anchor[1]})),
  {asset:'stairwell',x:528,y:816,w:160,footprint:Object.values(p.stairwell),action:'street_scene',target:'kael-home',hotspot:'stairs'}];
}
export function bedroomRoom(){
 const p=BEDROOM_LAYOUT,f=p.floor;
 return {layoutVersion:p.version,width:1536,height:1024,entry:p.blocking.motherEntry,floor:[f.x,f.y,f.w,f.h],walkable:[[f.x,f.y,f.w,f.h]],blocked:[...p.objects.map(o=>[...o.footprint]),Object.values(p.stairwell)],
  hotspots:p.hotspots.map(h=>({...h,hit:[h.x-24,h.y-24,48,48],lookAt:({tv:[768,384],drawings:[1248,288],desk:[1200,432],stairs:[528,900]})[h.id]})),blocking:p.blocking,actorHeight:p.actorHeight,exit:{target:'downstairs',x:528,y:816}};
}
export function bedroomMap(){
 const p=BEDROOM_LAYOUT,r=bedroomRoom();let next=1;
 const props=values=>Object.entries(values).map(([name,value])=>({name,type:typeof value==='number'?'int':typeof value==='boolean'?'bool':'string',value}));
 const rect=(name,a,properties={level:0})=>({id:next++,name,x:a[0],y:a[1],width:a[2],height:a[3],properties:props(properties)});
 const spot=id=>p.hotspots.find(h=>h.id===id),interaction=(id,name,properties)=>{const h=spot(id);return rect(name,[h.x-24,h.y-24,48,48],properties);};
 const layers={Walkable:[rect('Piso do quarto',r.floor)],Solids:r.blocked.map((a,i)=>rect(i===r.blocked.length-1?'Vão da escada':p.objects[i].asset,a)),Foreground:[],
  Interactions:[interaction('stairs','Descer para a sala',{action:'street_scene',target:'kael-home'}),interaction('desk','Mesa de criação do Rabbito',{action:'pilot_story',story:'Foi nesta mesa que seu desenho ganhou vida. A Rabiola Antiga ainda guarda muitos segredos.'})],
  Spawns:[rect('Patamar de entrada',[504,768,48,48])],Exits:[]};
 return {type:'map',orientation:'orthogonal',infinite:false,width:48,height:36,tilewidth:32,tileheight:32,properties:props({scene_name:'Quarto de Kael',overview:true,actor_height:p.actorHeight,foot_radius:14,walk_speed:360}),layers:Object.entries(layers).map(([name,objects],i)=>({id:i+1,name,type:'objectgroup',objects}))};
}
