// Repeatable spatial redesign, applied once to the original pilot.
import fs from 'node:fs';
const root='assets/world/morro-pilot/',map=JSON.parse(fs.readFileSync(root+'blockout.tmj')),art=JSON.parse(fs.readFileSync(root+'art.json'));
if(map.layers[0].objects.some(o=>o.id===23))throw Error('Redesign already applied');
const layer=name=>map.layers.find(l=>l.name===name).objects;
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='number'?'int':'string',value}));
function add(name,id,title,x,y,width,height,p){layer(name).push({id,name:title,x,y,width,height,rotation:0,visible:true,properties:props(p)});}
const byId=id=>map.layers.flatMap(l=>l.objects).find(o=>o.id===id);
// A smaller western house leaves room for a return stair, with matching roof/fence.
byId(5).width=224;byId(11).width=224;art.bindings[5].width=224;
const roof=art.decorations.find(d=>d.frame==='roof-terracotta');roof.width=224;roof.footX=240;roof.footY=470;
// The eastern house becomes an island: a courtyard, narrow side passage and laundry alley.
byId(9).height=64;
byId(15).x=416;
add('Walkable',23,'Patio dos varais',672,576,480,96,{level:0});
add('Walkable',24,'Passagem da bananeira',1152,320,64,352,{level:0});
add('Walkable',25,'Beco dos varais',672,320,480,64,{level:0});
add('Walkable',26,'Escada do retorno',384,256,64,128,{level:0,connects_to:1});
add('Walkable',27,'Passagem de casa',352,384,96,192,{level:0});
add('Walkable',28,'Terraco de ligacao',384,128,128,128,{level:1});
add('Interactions',29,'Memorias do vento',992,640,64,64,{level:0,action:'pilot_story',story:'Dona Celina guarda aqui os varais que o vento vive embolando. Ela conta que, antes das disputas, as crianças aprendiam a ler o vento observando os lençóis. Da escadaria, uma caixa-d’água marca a subida. No alto, o bairro ainda tem histórias para contar.'});
add('Solids',30,'Banco do patio',976,720,96,24,{level:0,sort_y:744});
add('Walkable',31,'Recanto do banco',944,672,272,96,{level:0});
art.bindings[30]={frame:'bench',width:104};
// Keep the scenic discovery readable, without vegetation pretending to be solid.
art.decorations=art.decorations.filter(d=>!['banana','shrub'].includes(d.frame));
art.decorations.push({frame:'banana',height:110,footX:1245,footY:670,sortY:670,level:0},{frame:'pennants',width:160,footX:896,footY:320,sortY:384,level:0},{frame:'flowerpot',height:34,footX:1095,footY:744,sortY:744,level:0});
byId(18).name='Vista do Parque dos Ventos';
map.nextobjectid=32;map.properties.find(p=>p.name==='design_phase').value='exploration-slice-v2';
fs.writeFileSync(root+'blockout.tmj',JSON.stringify(map,null,2)+'\n');fs.writeFileSync(root+'art.json',JSON.stringify(art,null,2)+'\n');
