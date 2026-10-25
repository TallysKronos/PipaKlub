import {parseWorldMap} from './world-map.js';
// A connected region: woodland, two canal crossings, an optional lookout,
// a high ridge with two stair approaches, then the guardian courtyard.
export const VEREDAS_CHESTS=[
 {id:'lookout',name:'Baú do mirante',x:416,y:384,level:1},
 {id:'woodland',name:'Baú entre as raízes',x:448,y:1536,level:0},
 {id:'canal',name:'Baú da margem escondida',x:2528,y:1632,level:0},
 {id:'ridge',name:'Baú da encosta',x:2112,y:256,level:1},
 {id:'courtyard',name:'Baú dos canos antigos',x:3008,y:544,level:1}
];
export function createParkBossScene(){
 const props=o=>Object.entries(o).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
 let id=0;const layers=['Walkable','Solids','Foreground','Interactions','Spawns','Exits'].map((name,i)=>({id:i+1,name,type:'objectgroup',objects:[]}));
 const add=(layer,name,x,y,width,height,p={})=>layers.find(l=>l.name===layer).objects.push({id:++id,name,x,y,width,height,properties:props({level:0,...p})});
 add('Walkable','Bosque dos retalhos',96,704,1024,1056,{ground_frame:'grass'});
 add('Walkable','Margem dos canos',1248,704,1440,1056,{ground_frame:'grass'});
 add('Walkable','Mirante das pipas',192,256,672,256,{ground_frame:'grass',level:1,elevation:96});
 add('Walkable','Encosta do vento',1600,96,960,416,{ground_frame:'grass',level:1,elevation:96});
 add('Walkable','Travessia alta',2560,256,192,160,{ground_frame:'sidewalk',level:1,elevation:96});
 add('Walkable','Pátio dos canos antigos',2752,192,384,416,{ground_frame:'sidewalk',level:1,elevation:96,safe_area:true});
 for(const [name,x]of [['Rampa do mirante',704],['Rampa oeste da encosta',1664],['Rampa leste da encosta',2368]])add('Walkable',name,x,512,160,192,{ground_frame:'stairs',connects_to:1,rise_to:96,safe_area:true});
 for(const [i,r]of [[960,896,512,128],[960,1472,512,128]].entries())add('Walkable','Ponte do canal '+i,...r,{ground_frame:'bridge',safe_area:true});
 for(const [i,r]of [[160,768,864,128],[896,816,128,768],[1376,896,768,128],[1664,704,160,896],[1376,1472,1152,128],[2368,704,160,896]].entries())add('Walkable','Trilha baixa '+i,...r,{ground_frame:'dirt',safe_area:true});
 add('Walkable','Caminho do mirante',704,704,160,128,{ground_frame:'dirt',safe_area:true});
 add('Walkable','Trilha da encosta',1664,288,832,128,{ground_frame:'dirt',level:1,elevation:96,safe_area:true});
 add('Walkable','Abrigo de Nina',1408,896,256,192,{ground_frame:'sidewalk',safe_area:true});
 for(const [i,r]of [[192,1088,320,224],[576,1376,256,224],[1344,1120,256,224],[1920,1120,320,224],[2240,160,192,96]].entries())add('Walkable','Mato de exploração '+i,...r,{ground_frame:'park-tall-grass',encounter_zone:'park-veredas-wild',level:i===4?1:0,...(i===4?{elevation:96}:{})});
 // Whole trees, with foot-sized trunks: vegetation frames paths instead of hedge walls.
 const trees=[[192,1008],[544,1040],[768,1152],[320,1408],[768,1648],[1376,816],[1888,816],[2144,1056],[1984,1408],[2496,1376],[2592,1728],[1536,1664],[256,320],[576,320],[1792,160],[2464,192]];
 for(const [x,y]of trees)add('Solids','Árvore das Veredas',x-20,y-24,40,24,{world_prop:'tree',level:y<512?1:0,sort_y:y});
 add('Spawns','Chegada da Clareira',192,784,64,64);
 add('Exits','Voltar à Clareira do Papel',192,864,64,64,{action:'street_scene',target:'park-clearing'});
 const interaction=(name,x,y,action,level=0,p={})=>add('Interactions',name,x-16,y-16,32,32,{action,level,...p});
 interaction('Lacertubo · guardião dos canos',2944,352,'parkBoss',1);
 interaction('Banco do pátio',2800,256,'wildRest',1);
 interaction('Sinais no bosque',320,816,'parkBossGuide');
 interaction('Mapa das Veredas',384,816,'parkMap');
 interaction('Papel rasgado entre as folhas',576,1216,'veredasTrace');
 interaction('Canos marcados',2080,1408,'veredasPipes');
 interaction('Rabiola do Carcará de Nina',2944,448,'veredasTail',1);
 interaction('Nina',1536,992,'veredasNina');
 for(const chest of VEREDAS_CHESTS)interaction(chest.name,chest.x,chest.y+48,'veredasChest',chest.level,{target:chest.id});
 const map={type:'map',version:'1.10',orientation:'orthogonal',renderorder:'right-down',width:100,height:64,tilewidth:32,tileheight:32,infinite:false,tilesets:[],layers,properties:props({scene_name:'Veredas do Encanamento',scene_id:'park-veredas',boss_maze:true,veredas_region:true,prefer_safe_paths:true,rescue_story:true,guardian_x:2944,guardian_y:352,nina_x:1536,nina_y:992,tail_x:2944,tail_y:448,actor_height:72,foot_radius:10,walk_speed:300,ground_corner_radius:32})};
 const scene=parseWorldMap(map);scene.isometric=true;scene.art={objects:[]};scene.veredas={chests:VEREDAS_CHESTS,water:[{x:1120,y:704,w:128,h:1056}],sectors:[{name:'Bosque dos retalhos',x:600,y:1100},{name:'Margem dos canos',x:1900,y:1200},{name:'Encosta do vento',x:2080,y:320},{name:'Pátio dos canos antigos',x:2944,y:352}]};return scene;
}
