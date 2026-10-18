import fs from 'node:fs';
const root='assets/world/morro-road-v1/';fs.mkdirSync(root,{recursive:true});
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='number'?'int':typeof value==='boolean'?'bool':'string',value}));
const chapters=[
 {id:'morro',stage:'morro-1',name:'Praça da Chegada',map:'world/morro-plaza-v1/road-1.tmj'},
 {id:'morro-area-2',stage:'morro-2',name:'Escadaria da Sombra',map:'world/morro-road-v1/area-2.tmj',image:'escadaria-v1.png',ground:[448,544,704,192],lower:[640,736,320,96],entry:[736,832,128,192],stair:[752,240,112,304],upper:[576,128,480,112],exit:[784,160],foe:[608,608]},
 {id:'morro-area-3',stage:'morro-3',name:'Laje dos Ventos',map:'world/morro-road-v1/area-3.tmj',image:'laje-v1.png',ground:[384,352,736,288],lower:[448,640,640,32],entry:[736,672,96,352],stair:[736,176,80,176],upper:[576,96,480,80],exit:[752,112],foe:[640,480]},
 {id:'morro-area-4',stage:'morro-4',name:'Mirante da Caixa-d’água',map:'world/morro-road-v1/area-4.tmj',image:'mirante-v1.png',ground:[448,512,704,160],lower:[608,672,384,64],entry:[736,736,96,288],stair:[736,256,128,256],upper:[608,144,448,112],exit:[768,176],foe:[576,576]},
 {id:'morro-area-5',stage:'morro-5',name:'Parque dos Ventos',map:'world/morro-road-v1/area-5.tmj',image:'parque-v1.png',ground:[384,384,832,384],lower:[576,768,448,64],entry:[736,832,128,192],stair:[800,256,128,128],upper:[704,128,352,128],exit:[832,176],foe:[704,544]}
];
let first=JSON.parse(fs.readFileSync('assets/world/morro-plaza-v1/plaza.tmj'));let id=first.nextobjectid;
const layer=(m,n)=>m.layers.find(l=>l.name===n).objects;
function rect(m,l,name,box,p){layer(m,l).push({id:id++,name,x:box[0],y:box[1],width:box[2],height:box[3],rotation:0,visible:true,properties:props(p)});}
layer(first,'Interactions').splice(1,1); // Bia belongs to the next map, not to this view.
const exits=layer(first,'Exits');exits.splice(1,1);
rect(first,'Foreground','Passagem bloqueada da praça',[800,544,112,24],{level:0,sort_y:568,hidden:true,road_gate:true,requires_clear:'morro-1'});
rect(first,'Interactions','Subir a escadaria',[816,608,32,32],{level:0,action:'road_gate',requires_stage:'morro-1'});
rect(first,'Exits','Seguir para a Escadaria da Sombra',[816,160,64,64],{level:1,action:'road_next',requires_stage:'morro-1',target:chapters[1].id});
first.nextobjectid=id;first.properties=props({name:'Morro do Sol · Praça da Chegada',actor_height:64,foot_radius:12,chapter:1,stage_id:'morro-1'});
fs.writeFileSync('assets/'+chapters[0].map,JSON.stringify(first,null,2)+'\n');
const sheets={};
for(let i=1;i<chapters.length;i++){
 const c=chapters[i],sheet='morro-road-'+(i+1);id=1;
 const m={type:'map',version:'1.10',tiledversion:'1.11.0',orientation:'orthogonal',renderorder:'right-down',width:48,height:32,tilewidth:32,tileheight:32,infinite:false,tilesets:[],properties:props({name:'Morro do Sol · '+c.name,actor_height:64,foot_radius:12,chapter:i+1,stage_id:c.stage}),layers:[{id:1,name:'Cenario '+c.name,type:'imagelayer',x:0,y:0,visible:true,opacity:1,image:c.image,imagewidth:1536,imageheight:1024,properties:props({sheet,render:'ground',level:0})},...['Walkable','Solids','Foreground','Interactions','Spawns','Exits'].map((name,j)=>({id:j+2,name,type:'objectgroup',draworder:'topdown',visible:true,opacity:1,objects:[]}))]};
 rect(m,'Walkable','Clareira de encontro',c.ground,{level:0});rect(m,'Walkable','Acesso sul',c.lower,{level:0});rect(m,'Walkable','Entrada da área',c.entry,{level:0});
 rect(m,'Walkable','Subida de saida',c.stair,{level:0,...i===4?{}:{connects_to:1}});rect(m,'Walkable','Patamar de saida',c.upper,{level:i===4?0:1});
 rect(m,'Foreground','Passagem desta área',[c.stair[0],c.stair[1]+c.stair[3],c.stair[2],24],{level:0,sort_y:c.stair[1]+c.stair[3]+24,hidden:true,road_gate:true,requires_clear:c.stage});
 rect(m,'Interactions','Encontro do bairro',[...c.foe,64,64],{level:0,stage:c.stage});
 rect(m,'Interactions','Passagem para a próxima área',[c.stair[0],c.stair[1]+c.stair[3]+64,c.stair[2],32],{level:0,action:'road_gate',requires_stage:c.stage});
 rect(m,'Spawns','Entrada sul',[c.entry[0]+16,c.entry[1]+32,32,32],{level:0});
 rect(m,'Exits','Voltar para '+chapters[i-1].name,[c.entry[0]+16,c.entry[1]+c.entry[3]-96,64,64],{level:0,action:'road_back',target:chapters[i-1].id});
 rect(m,'Exits',i===4?'Sair para a cidade':'Seguir para '+chapters[i+1].name,[...c.exit,64,32],{level:i===4?0:1,action:'road_next',requires_stage:c.stage,...i<4?{target:chapters[i+1].id}:{}});
 m.nextobjectid=id;m.nextlayerid=8;fs.writeFileSync('assets/'+c.map,JSON.stringify(m,null,2)+'\n');
 sheets[sheet]={image:'world/morro-road-v1/'+c.image,width:1536,height:1024};
}
fs.writeFileSync(root+'manifest.json',JSON.stringify({chapters:chapters.map(({id,stage,name,map})=>({id,stage,name,map})),sheets},null,2)+'\n');
