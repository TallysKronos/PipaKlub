import fs from 'node:fs';
const root='assets/world/morro-plaza-v1/';
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='number'?'int':typeof value==='boolean'?'bool':'string',value}));
let next=1;const layers=[];
function objects(name,list){layers.push({id:layers.length+1,name,type:'objectgroup',draworder:'topdown',opacity:1,visible:true,objects:list.map(([name,x,y,width,height,p={}])=>({id:next++,name,x,y,width,height,rotation:0,visible:true,properties:props(p)}))});}
layers.push({id:1,name:'Cenario pintado',type:'imagelayer',x:0,y:0,opacity:1,visible:true,image:'plaza-base-v1.png',imagewidth:1536,imageheight:1024,properties:props({sheet:'plaza-slice-base',render:'ground',level:0})});
objects('Walkable',[
 ['Praca principal',352,544,992,192,{level:0}],
 ['Largo da entrada',352,736,768,96,{level:0}],
 ['Oficina de pipas',160,656,256,112,{level:0}],
 ['Portao de casa',224,736,128,128,{level:0}],
 ['Caminho do quintal',224,864,192,64,{level:0}],
 ['Escadaria',800,240,112,304,{level:0,connects_to:1}],
 ['Patamar da caixa dagua',640,144,512,96,{level:1}]
]);
objects('Solids',[
 ['Contencao oeste',320,240,464,288,{level:0,hidden:true}],
 ['Contencao leste',928,240,512,288,{level:0,hidden:true}],
 ['Mesa do artesao',176,528,144,112,{level:0,hidden:true}],
 ['Pilar oeste do portao',192,752,40,112,{level:0,hidden:true}],
 ['Pilar leste do portao',344,776,56,88,{level:0,hidden:true}],
 ['Tronco de sombra',1184,768,64,56,{level:0,hidden:true}]
]);
objects('Foreground',[
 ['Cobertura do portao',192,704,192,96,{level:0,sort_y:816,image_sheet:'plaza-slice-base'}]
]);
objects('Interactions',[
 ['Zeca',512,592,64,64,{level:0,stage:'morro-1'}],
 ['Bia',992,160,64,64,{level:1,stage:'morro-2'}],
 ['Oficina de pipas',192,656,64,64,{level:0,action:'pilot_story',story:'Na oficina da praça, cada pipa começa com bambu, papel e um pouco de paciência. Os moradores usam a caixa-d’água para indicar o caminho: siga a escadaria e encontre o patamar do bairro.'}]
]);
objects('Spawns',[['Chegada ao Morro',512,736,32,32,{level:0}]]);
objects('Exits',[['Voltar ao quintal',256,864,64,64,{level:0,action:'quintal'}],['Proximo trecho do bairro',1088,160,32,64,{level:1,action:'pilot_boundary'}]]);
layers.push({id:layers.length+1,name:'Arvore em primeiro plano',type:'imagelayer',x:0,y:0,opacity:1,visible:true,image:'plaza-tree-v1.png',imagewidth:1536,imageheight:1024,properties:props({sheet:'plaza-slice-tree',render:'depth',level:0,sort_y:800,occlusion_x:928,occlusion_y:400,occlusion_w:512,occlusion_h:400})});
const map={type:'map',version:'1.10',tiledversion:'1.11.0',orientation:'orthogonal',renderorder:'right-down',width:48,height:32,tilewidth:32,tileheight:32,infinite:false,nextlayerid:layers.length+1,nextobjectid:next,layers,tilesets:[],properties:props({name:'Morro do Sol · Praça da Chegada',actor_height:64,foot_radius:12,design_phase:'painted-slice-v1'})};
fs.writeFileSync(root+'plaza.tmj',JSON.stringify(map,null,2)+'\n');
const manifest={sheets:{'plaza-slice-base':{image:'world/morro-plaza-v1/plaza-base-v1.png',width:1536,height:1024},'plaza-slice-tree':{image:'world/morro-plaza-v1/plaza-tree-v1.png',width:1536,height:1024}}};
fs.writeFileSync(root+'manifest.json',JSON.stringify(manifest,null,2)+'\n');
