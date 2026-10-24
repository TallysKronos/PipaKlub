import {parseWorldMap} from './world-map.js';
// Physics, map board and hedge placement share these rectangles. 128px lanes
// accommodate Kael and his follower without touching the collision margins.
export function createParkBossScene(){
 const props=o=>Object.entries(o).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
 let id=0;const layers=['Walkable','Solids','Foreground','Interactions','Spawns','Exits'].map((name,i)=>({id:i+1,name,type:'objectgroup',objects:[]}));
 const add=(layer,name,x,y,width,height,p={})=>layers.find(l=>l.name===layer).objects.push({id:++id,name,x,y,width,height,properties:props({level:0,...p})});
 add('Walkable','Jardim além dos muros',96,208,1344,736,{ground_frame:'grass'});
 for(const [i,r]of [[144,752,1216,144],[1184,560,176,272],[256,560,1056,112],[256,384,144,272],[304,384,1008,112],[1184,240,176,240]].entries())add('Walkable','Trilha '+i,...r,{ground_frame:'dirt',safe_area:true});
 add('Walkable','Pátio do guardião',1056,208,352,160,{ground_frame:'sidewalk',safe_area:true});
 const walls=[[96,688,1040,48],[448,512,992,48],[96,336,1040,48],[704,768,48,96],[864,384,48,64]];
 walls.forEach((r,i)=>add('Solids','maze-hedge-'+i,...r,{sort_y:r[1]+r[3]}));
 add('Spawns','Chegada da Clareira',192,800,64,64);
 add('Exits','Voltar à Clareira do Papel',192,880,64,48,{action:'street_scene',target:'park-clearing'});
 add('Interactions','Lacertubo · guardião dos canos',1216,256,96,64,{action:'parkBoss'});
 add('Interactions','Placa · além da cidade',304,816,48,48,{action:'parkBossGuide'});
 add('Interactions','Mapa das Veredas',352,816,48,48,{action:'parkMap'});
 const map={type:'map',version:'1.10',orientation:'orthogonal',renderorder:'right-down',width:48,height:32,tilewidth:32,tileheight:32,infinite:false,tilesets:[],layers,properties:props({scene_name:'Além da cidade · Veredas do Encanamento',scene_id:'park-veredas',boss_maze:true,actor_height:72,foot_radius:10,walk_speed:300,ground_corner_radius:32})};
 const scene=parseWorldMap(map);scene.isometric=true;scene.art={objects:[]};return scene;
}
