import * as BedroomIso from '../tools/iso-studio/model.mjs';
// The same Iso Studio grid as upstairs; 96 logical units = one 64×32 art cell.
const homePiece=(id,name,kind,footprint,height,cell,elevation=0)=>BedroomIso.normalizePiece({id,name,kind,footprint,height,cell,elevation});
export const homeProject={name:'Casa de Kael · sala e cozinha',room:BedroomIso.defaultRoom([12,9],5),pieces:[
 homePiece('tapete','Tapete do estar','flat',[5,3],0,[7.5,6.5]),
 homePiece('janela','Janela do estar','wallLeft',[2],1.5,[0,5.5],2.5),
 homePiece('porta','Porta para a rua','wallLeft',[2],4,[0,8.5]),
 homePiece('sofa','Sofá do estar','floor',[2,3],2.3,[2,6]),
 homePiece('mesa-centro','Mesa de centro','floor',[1.5,1.5],1.1,[5,6]),
 homePiece('mesa-jantar','Mesa de refeições','floor',[3,2],1.5,[7,3]),
 homePiece('banco-jantar','Banco de refeições','floor',[3,.5],.8,[7,4]),
 homePiece('banco-fundo','Banco junto à parede','floor',[3,.5],.8,[7,.5]),
 homePiece('cozinha','Cozinha da família','floor',[4,1],3.5,[12,1]),
 homePiece('escada','Escada para o quarto','floor',[2,3],4,[12,8]),
]};
const homeRect=p=>{const r=BedroomIso.footprintRect(p);return [384+r.u0*96,288+r.v0*96,(r.u1-r.u0)*96,(r.v1-r.v0)*96];};
export const HOME_LAYOUT={version:1,floor:{x:384,y:288,w:1152,h:864},wallHeight:160,actorHeight:102,
 objects:homeProject.pieces.filter(p=>p.kind==='floor').map(p=>({asset:p.id,footprint:homeRect(p),anchor:[384+p.cell[0]*96,288+p.cell[1]*96],w:BedroomIso.pieceBox(p).w})),
 hotspots:[{id:'mother',name:'Conversar com a mãe',x:1040,y:912,lookAt:[960,864]},{id:'exit',name:'Sair para a rua',x:432,y:1008,lookAt:[384,1008]},{id:'upstairs',name:'Subir para o quarto',x:1424,y:1104,lookAt:[1440,960]}],
 blocking:{kaelEntry:[1424,1104],mother:[960,864],rabbitoEntry:[1344,1104]},
};
export function homeRoom(){const p=HOME_LAYOUT,f=p.floor;return {layoutVersion:p.version,width:1728,height:1280,entry:p.blocking.kaelEntry,floor:[f.x,f.y,f.w,f.h],walkable:[[f.x,f.y,f.w,f.h]],blocked:p.objects.map(o=>o.footprint),hotspots:p.hotspots.map(h=>({...h,hit:[h.x-24,h.y-24,48,48]})),blocking:p.blocking,actorHeight:p.actorHeight,exit:{target:'quintal',x:432,y:1008}};}
export function homeMap(){const p=HOME_LAYOUT,r=homeRoom();let next=1;
 const props=a=>Object.entries(a).map(([name,value])=>({name,type:typeof value==='number'?'int':typeof value==='boolean'?'bool':'string',value}));
 const rect=(name,a,properties={level:0})=>({id:next++,name,x:a[0],y:a[1],width:a[2],height:a[3],properties:props(properties)}),interact=(id,properties)=>{const h=p.hotspots.find(h=>h.id===id);return rect(h.name,[h.x-24,h.y-24,48,48],properties);};
 const layers={Walkable:[rect('Piso da sala',r.floor)],Solids:p.objects.map(o=>rect(o.asset,o.footprint)),Foreground:[],Interactions:[interact('exit',{action:'street_scene',target:'quintal'}),interact('upstairs',{action:'street_scene',target:'kael-bedroom'}),interact('mother',{action:'pilot_story',story:'Sua mãe sorri ao ver o Rabbito: cuide bem dele e volte para contar como foi o primeiro voo.'})],Spawns:[rect('Entrada da casa',[408,984,48,48])],Exits:[]};
 return {type:'map',orientation:'orthogonal',infinite:false,width:54,height:40,tilewidth:32,tileheight:32,properties:props({scene_name:'Casa de Kael · sala',overview:true,actor_height:102,foot_radius:14,walk_speed:360}),layers:Object.entries(layers).map(([name,objects],i)=>({id:i+1,name,type:'objectgroup',objects}))};
}
