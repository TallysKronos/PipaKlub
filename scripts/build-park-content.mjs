import fs from 'node:fs';
// Authored modular maps. Whole tree sprites share one foot anchor and one collision.
const dir='assets/world/park-v1';fs.mkdirSync(dir,{recursive:true});
const props=o=>Object.entries(o).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
for(const [id,title] of [['park-trail','Parque dos Ventos · Jardim das Pipas'],['park-clearing','Parque dos Ventos · Clareira do Papel']]){
 const clearing=id==='park-clearing';let sequence=0;
 const layers=['Walkable','Solids','Foreground','Interactions','Spawns','Exits'].map((name,i)=>({id:i+1,name,type:'objectgroup',objects:[]}));
 const layout={bindings:{},decorations:[],audit:{enforce:true}};
 const obj=(layer,name,x,y,w,h,p={})=>{const o={id:++sequence,name,x,y,width:w,height:h,properties:props({level:0,...p})};layers.find(l=>l.name===layer).objects.push(o);return o;};
 const ground=(name,x,y,w,h,frame,safe=false)=>obj('Walkable',name,x,y,w,h,{ground_frame:frame,...safe?{safe_area:true}:{}});
 ground('Prado explorável',80,192,1376,752,'grass');
 ground('Entrada',144,744,160,200,'dirt',true);
 ground('Passeio do jardim',192,744,480,144,'dirt',true);
 ground('Curva dos bancos',528,464,144,368,'dirt',true);
 ground('Passeio até a clareira',576,448,800,144,'dirt',true);
 ground('Saída entre árvores',1232,336,144,224,'dirt',true);
 ground('Largo de descanso',272,432,280,240,'sidewalk',true);
 ground('Acesso ao largo',432,576,168,96,'dirt',true);
 ground('Recanto do banco',1040,528,160,160,'dirt',true);
 obj('Spawns','Chegada ao parque',192,784,64,64);
 obj('Exits',clearing?'Voltar ao Jardim das Pipas':'Voltar à Rua dos Ventos',192,864,64,64,{action:'street_scene',target:clearing?'park-trail':'quintal'});
 obj('Exits',clearing?'Atalho para a Rua dos Ventos':'Seguir para a Clareira',1256,368,64,64,{action:'street_scene',target:clearing?'quintal':'park-clearing'});
 obj('Interactions','Placa: habitats e encontros',296,784,72,64,{action:'wildGuide'});
 obj('Interactions','Descansar no largo',344,576,72,64,{action:'wildRest'});
 const place=(frame,x,y,width,w=32,h=24)=>{const r=obj('Solids',frame,x-w/2,y-h,w,h,{sort_y:y});layout.bindings[r.id]={frame,width,footX:x,footY:y,...frame.startsWith('park-tree')?{occludesActors:true}:{}};return r;};
 const decor=(frame,x,y,width,sortY=y)=>layout.decorations.push({frame,width,footX:x,footY:y,level:0,sortY});
 // Overlapping groves establish a continuous perimeter, with planting bays
 // rather than alternating isolated trees on one horizontal baseline.
 const trees=[[48,262,290],[402,244,280],[650,240,280],[810,212,300],
  [1140,242,300],[1300,266,310],[1476,264,300],
  [42,530,270],[78,760,290],[32,1010,230],
  [1492,514,300],[1480,758,320],[1432,1000,330],
  [420,1018,240],[610,1002,220],[852,1020,240],[1100,1008,240]];
 for(const [i,[x,y,size]]of trees.entries()){const frame=i%3===0?'park-tree-a':'park-tree-b';place(frame,x,y,size*(frame==='park-tree-b'?.78:1),38,28);}
 // One tree with a caught kite is a landmark, rather than a repeated ornament.
 place('park-tree',482,254,245,38,28);
 place('park-tree-flower',204,290,285,38,28);
 if(clearing){place('park-tree',856,782,280,42,30);place('park-tree-flower',414,488,290,40,28);}
 else{place('park-gazebo',414,488,290,180,68);place('park-tree-flower',872,766,270,40,28);}
 place('bench',408,574,118,96,22);
 place('bench',1118,622,118,96,22);
 place('lamp',276,688,30,18,18);place('lamp',1220,626,30,18,18);
 const patches=clearing?[[740,308,360,112],[160,348,144,160],[1016,712,300,152]]:[[742,308,350,112],[160,348,144,160],[1032,712,284,152]];
 for(const [i,[x,y,w,h]]of patches.entries()){
  const habitat=(name,px,py,pw,ph)=>obj('Walkable',name,px,py,pw,ph,{ground_frame:'park-tall-grass',encounter_zone:id});
  habitat('Habitat de capim '+(i+1),x,y+16,w,h-24);
  habitat('Lóbulo do habitat '+(i+1),x+24,y-8,w-60,h);
  habitat('Borda do habitat '+(i+1),x+14,y+32,w-42,h-24);
 }
 // Two pots belong to the rest plaza; avoid unrelated solitary fence/shrub stamps.
 for(const [x,y]of [[300,638],[518,638]])decor('flowerpot',x,y,38);
 for(const [x,y,w]of [[88,344,132],[1402,380,144],[1278,954,148],[112,898,136]])decor('park-shrub',x,y,w);
 for(const [x,y,w]of [[310,504,88],[508,492,82]])decor('park-flowers',x,y,w);
 const map={type:'map',version:'1.10',tiledversion:'1.11.0',orientation:'orthogonal',renderorder:'right-down',width:48,height:32,tilewidth:32,tileheight:32,infinite:false,tilesets:[],layers,properties:props({scene_name:title,scene_id:id,overview:false,actor_height:72,foot_radius:10,ground_corner_radius:56,terrain_tile_size:384,terrain_repeat:'mirror',terrain_feather:5,terrain_edge_mode:'none'})};
 fs.writeFileSync(dir+'/'+id+'.tmj',JSON.stringify(map,null,2)+'\n');fs.writeFileSync(dir+'/'+id+'.art.json',JSON.stringify(layout,null,2)+'\n');
}
