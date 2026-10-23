import * as BedroomIso from '../tools/iso-studio/model.mjs';
const servicePiece=(id,name,kind,footprint,height,cell,elevation=0)=>BedroomIso.normalizePiece({id,name,kind,footprint,height,cell,elevation});
export const SERVICE_INTERIORS={
 'professor-home':{name:'Casa do Sr. Assis',prefix:'assis-',room:BedroomIso.defaultRoom([14,11],5),pieces:[
  servicePiece('rug','Tapete da biblioteca','flat',[6,4],0,[9,8]),
  servicePiece('library','Biblioteca da Pipa Dex','floor',[3,1],3.5,[3,1]),
  servicePiece('study','Estante de técnicas','floor',[3,1],3.5,[7,1]),
  servicePiece('workbench','Bancada das almas','floor',[4,2],1.6,[13,3]),
  servicePiece('desk','Mesa do professor','floor',[3,2],1.6,[4,5]),
  servicePiece('chest','Baú de materiais','floor',[2,1],1.2,[13,8]),
  servicePiece('window','Janela da biblioteca','wallLeft',[3],2,[0,8],1.6),
  servicePiece('papers','Estudos de pipas','wallRight',[3],1.4,[12,0],2.6),
  servicePiece('exit','Entrada da biblioteca','flat',[2,1],0,[8,11]),
 ],npc:[960,672],companion:[1032,704],hotspots:[
  {id:'exit',name:'Sair para a rua',at:[7,10.5],action:'street_scene',target:'quintal'},
  {id:'professor',name:'Sr. Assis e Nozinho · primeiro voo',at:[6,5],action:'professor'},
  {id:'library',name:'Biblioteca · Pipa Dex',at:[2,2],action:'dex'},
  {id:'study',name:'Estudo de técnicas',at:[5.5,2],action:'school'},
  {id:'workbench',name:'Oficina das Almas',at:[11,4],action:'summon'},
 ]},
 'kite-shop':{name:'Loja de pipas',prefix:'shop-',room:BedroomIso.defaultRoom([14,11],5),pieces:[
  servicePiece('rug','Tapete da loja','flat',[6,4],0,[9,9]),
  servicePiece('library','Prateleira de linhas','floor',[3,1],3.5,[3,1]),
  servicePiece('study','Prateleira de papéis','floor',[3,1],3.5,[12,1]),
  servicePiece('counter','Balcão de atendimento','floor',[5,1.5],1.8,[8,3]),
  servicePiece('workbench','Bancada de criação','floor',[4,2],1.6,[13,7]),
  servicePiece('rack','Expositor de pipas','floor',[2,1],3.8,[2,7]),
  servicePiece('chest','Caixa de materiais','floor',[2,1],1.2,[13,10]),
  servicePiece('window','Janela da loja','wallLeft',[3],2,[0,4],1.6),
  servicePiece('exit','Entrada da loja','flat',[2,1],0,[8,11]),
 ],hotspots:[
  {id:'exit',name:'Sair para a rua',at:[7,10.5],action:'street_scene',target:'quintal'},
  {id:'counter',name:'Balcão · linhas e acessórios',at:[5.5,4],action:'shop'},
  {id:'workbench',name:'Oficina de pipas',at:[10.5,8],action:'pilot_story',story:'Varetas, papel, linha e nós dão forma ao corpo da pipa. A rabiola guarda a alma e é colocada por último na Oficina das Almas.'},
 ]},
};
export function serviceLayout(id){const p=SERVICE_INTERIORS[id];if(!p)return null;const floor={x:384,y:288,w:p.room.cells[0]*96,h:p.room.cells[1]*96};
 return {...p,floor,objects:p.pieces.filter(p=>p.kind==='floor').map(p=>{const r=BedroomIso.footprintRect(p);return {asset:p.id,footprint:[floor.x+r.u0*96,floor.y+r.v0*96,(r.u1-r.u0)*96,(r.v1-r.v0)*96],anchor:[floor.x+p.cell[0]*96,floor.y+p.cell[1]*96],w:BedroomIso.pieceBox(p).w};}),hotspots:p.hotspots.map(h=>({...h,x:floor.x+h.at[0]*96,y:floor.y+h.at[1]*96}))};
}
export function serviceMap(id){const p=serviceLayout(id);let seq=1;
 const props=o=>Object.entries(o).map(([name,value])=>({name,type:typeof value==='number'?'int':typeof value==='boolean'?'bool':'string',value}));
 const rect=(name,a,properties={level:0})=>({id:seq++,name,x:a[0],y:a[1],width:a[2],height:a[3],properties:props(properties)});
 const f=p.floor,e=p.hotspots.find(h=>h.id==='exit'),layers={Walkable:[rect('Piso',[f.x,f.y,f.w,f.h])],Solids:p.objects.map(o=>rect(o.asset,o.footprint)),Foreground:[],Interactions:p.hotspots.map(h=>rect(h.name,[h.x-24,h.y-24,48,48],{action:h.action,...h.target?{target:h.target}:{},...h.story?{story:h.story}:{}})),Spawns:[rect('Entrada',[e.x-24,e.y-88,48,48])],Exits:[]};
 return {type:'map',orientation:'orthogonal',infinite:false,width:64,height:48,tilewidth:32,tileheight:32,properties:props({scene_name:p.name,overview:true,actor_height:102,foot_radius:14,walk_speed:360}),layers:Object.entries(layers).map(([name,objects],i)=>({id:i+1,name,type:'objectgroup',objects}))};
}
