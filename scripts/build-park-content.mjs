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
 ground('Entrada',160,768,128,160,'sidewalk',true);
 ground('Passeio do jardim',192,752,464,112,'dirt',true);
 ground('Curva dos bancos',544,480,112,320,'dirt',true);
 ground('Passeio até a clareira',576,464,768,112,'dirt',true);
 ground('Saída entre árvores',1232,352,112,176,'dirt',true);
 ground('Largo de descanso',272,416,272,256,'sidewalk',true);
 ground('Acesso ao largo',400,608,200,96,'dirt',true);
 obj('Spawns','Chegada ao parque',192,784,64,64);
 obj('Exits',clearing?'Voltar ao Jardim das Pipas':'Voltar à Rua dos Ventos',192,864,64,64,{action:'street_scene',target:clearing?'park-trail':'quintal'});
 obj('Exits',clearing?'Atalho para a Rua dos Ventos':'Seguir para a Clareira',1256,368,64,64,{action:'street_scene',target:clearing?'quintal':'park-clearing'});
 obj('Interactions','Placa: habitats e encontros',296,784,72,64,{action:'wildGuide'});
 obj('Interactions','Descansar no largo',344,576,72,64,{action:'wildRest'});
 const place=(frame,x,y,width,w=32,h=24)=>{const r=obj('Solids',frame,x-w/2,y-h,w,h,{sort_y:y});layout.bindings[r.id]={frame,width,footX:x,footY:y};return r;};
 const decor=(frame,x,y,width,sortY=y)=>layout.decorations.push({frame,width,footX:x,footY:y,level:0,sortY});
 // Clustered border canopy; the grove frames paths rather than covering the exits.
 const trees=[[112,280,290],[360,272,310],[650,276,280],[948,280,320],[1230,274,285],[1460,304,290],[90,590,280],[1445,670,300],[60,970,220],[840,982,240],[1120,970,250],[1440,951,320]];
 for(const [i,[x,y,size]]of trees.entries())place(i%3===1?'park-tree-flower':'park-tree',x,y,size,38,28);
 if(clearing){place('park-tree-flower',916,720,320,42,30);place('park-tree',274,500,290,40,28);}
 else{place('park-gazebo',414,488,290,180,68);place('park-tree-flower',900,740,300,40,28);}
 place('bench',380,574,132,100,22);
 place('bench',1110,600,130,100,22);
 place('lamp',270,685,32,18,18);place('lamp',1210,580,32,18,18);
 // Gate posts keep the blue threshold open in the middle.
 place('flowerpot',146,881,48,24,20);place('flowerpot',304,881,48,24,20);
 const patches=clearing?[[730,310,430,112],[130,340,126,150],[1000,672,330,144]]:[[726,320,412,100],[130,340,126,150],[1050,680,280,136]];
 for(const [i,[x,y,w,h]]of patches.entries()){
  obj('Walkable','Habitat de capim '+(i+1),x,y,w,h,{ground_frame:'grass',encounter_zone:id});
  for(let row=0;row<Math.ceil(h/42);row++)for(let col=0;col<Math.ceil(w/76);col++){
   const px=x+30+col*72+(row%2)*10,py=y+32+row*38;
   if(px>x+w-4||py>y+h+8)continue;
   if(w>240&&((col===0&&row===0)||(col>=Math.ceil(w/76)-1&&row>=Math.ceil(h/42)-1)))continue;
   decor('park-habitat',px,py,110+(col%3)*6,py-12);
  }
 }
 // Low borders break repetition and leave habitat approaches readable.
 for(const [x,y,width]of [[136,425,115],[180,466,90],[1300,622,110],[1390,798,125],[710,875,110],[1160,910,110],[490,326,95]])decor('shrub',x,y,width);
 for(const [x,y]of [[320,636],[490,624],[1170,610]])decor('flowerpot',x,y,42);
 // Short fence runs frame the rest garden without blocking the main walkway.
 place('fence',365,704,160,150,18);place('fence',1100,850,164,150,18);
 const map={type:'map',version:'1.10',tiledversion:'1.11.0',orientation:'orthogonal',renderorder:'right-down',width:48,height:32,tilewidth:32,tileheight:32,infinite:false,tilesets:[],layers,properties:props({scene_name:title,scene_id:id,overview:false,actor_height:72,foot_radius:10,ground_corner_radius:34,terrain_tile_size:256})};
 fs.writeFileSync(dir+'/'+id+'.tmj',JSON.stringify(map,null,2)+'\n');fs.writeFileSync(dir+'/'+id+'.art.json',JSON.stringify(layout,null,2)+'\n');
}
