import {parseWorldMap} from './world-map.js';
// Approved park layout. These bases are authored once and used by physics + visuals.
export const parkFixtures=[
 {id:'entry-map',type:'sign',x:320,y:738,w:142,base:[140,20]},
 {id:'planter-west',type:'planter',x:300,y:638,w:80,base:[74,20]},
 {id:'planter-east',type:'planter',x:518,y:638,w:80,base:[74,20]},
 {id:'bin-west',type:'bin',x:294,y:654,w:29,base:[18,16]},
 {id:'bin-east',type:'bin',x:1190,y:637,w:29,base:[18,16]},
 {id:'lamp-west',type:'lamp',x:286,y:478,w:43,base:[14,14]},
 {id:'lamp-east',type:'lamp',x:1300,y:362,w:43,base:[14,14]},
];
export function createParkIsometricScene(map,art,{production=false}={}){
 const draft=structuredClone(map),solids=draft.layers.find(l=>l.name==='Solids'),hasCoreto=solids.objects.some(o=>o.name==='park-gazebo');
 // Open the illustrated staircase. Small post bases replace the former full block.
 solids.objects=solids.objects.filter(o=>o.name!=='park-gazebo');
 const bench=solids.objects.find(o=>o.name==='bench'&&Math.abs(o.x+o.width/2-408)<2);
 if(bench){bench.x=420-bench.width/2;bench.y=690-bench.height;bench.properties.find(p=>p.name==='sort_y').value=690;}
 const rest=draft.layers.find(l=>l.name==='Interactions').objects.find(o=>o.properties?.some(p=>p.name==='action'&&p.value==='wildRest'));
 if(rest){rest.x=412;rest.y=700;rest.width=64;rest.height=64;}
 const posts=[[51,227],[140,235],[225,225],[242,190],[27,190]];
 let id=Math.max(...draft.layers.flatMap(l=>(l.objects||[]).map(o=>o.id)));
 for(const [i,[sx,sy]]of (hasCoreto?posts:[]).entries()){
  const px=(sx-140.5)*260/281,py=(sy-291)*260/281,x=Math.round(414+px/1.64+py/.82),y=Math.round(488+py/.82-px/1.64);
  solids.objects.push({id:++id,name:'coreto-post-'+i,x:x-7,y:y-7,width:14,height:14,properties:[{name:'level',type:'int',value:0},{name:'sort_y',type:'float',value:y}]});
 }
 for(const p of parkFixtures)solids.objects.push({id:++id,name:p.id,x:p.x-p.base[0]/2,y:p.y-p.base[1],width:p.base[0],height:p.base[1],properties:[{name:'level',type:'int',value:0},{name:'sort_y',type:'int',value:p.y}]});
 if(production){
  const interactions=draft.layers.find(l=>l.name==='Interactions'),guide=interactions.objects.find(o=>o.properties?.some(p=>p.name==='action'&&p.value==='wildGuide'));
  if(guide&&hasCoreto){guide.x=320;guide.y=463;guide.width=32;guide.height=32;guide.name='Sr. Assis · encontros selvagens';}
  interactions.objects.push({id:++id,name:'Descansar no banco leste',x:1124,y:656,width:32,height:32,properties:[{name:'level',type:'int',value:0},{name:'action',type:'string',value:'wildRest'}]});
  interactions.objects.push({id:++id,name:'Mapa do Parque dos Ventos',x:332,y:764,width:32,height:32,properties:[{name:'level',type:'int',value:0},{name:'action',type:'string',value:'parkMap'}]});
 }
 const scene=parseWorldMap(draft);scene.art=art;if(production)scene.isometric=true;return scene;
}
// Fence lines stay beyond traversable borders; the south opening aligns with the entrance.
export const parkFenceRuns=[[[80,176],[1456,176]],[[1472,192],[1472,944]],[[80,968],[144,968]],[[336,968],[1408,968]],[[64,208],[64,928]]];
