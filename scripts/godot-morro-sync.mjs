import fs from 'node:fs';
import {createTrails} from '../src/trails.js';
const trails=createTrails({demo:true});
const stages=trails.stages.filter(s=>trails.available(s.id));
fs.mkdirSync('godot/assets/campaign/morro',{recursive:true});
fs.writeFileSync('godot/assets/campaign/morro/trails.json',JSON.stringify({stages,stories:Object.fromEntries(stages.map(s=>[s.id,trails.story(s.id)]))},null,2));
const cases=[];
for(const st of stages)for(const mastery of [0,2,7,8])for(const fails of [0,2,3])for(const won of [false,true])for(const roundsLost of [0,1,3]){
 const progress=trails.defaults();progress.mastery=mastery;progress.fails[st.id]=fails;
 cases.push({id:st.id,progress,won,roundsLost,result:trails.settle(progress,st.id,{won,roundsLost})});
}
let progress=trails.defaults();const sequence=[];
for(const id of [...stages.map(s=>s.id),'morro-5','morro-1']){const result=trails.settle(progress,id,{won:true,roundsLost:0});sequence.push({id,progress,won:true,roundsLost:0,result});progress=result.progress;}
fs.writeFileSync('godot/tests/fixtures/morro.json',JSON.stringify([...cases,...sequence]));
console.log(`${stages.length} etapas e ${cases.length+sequence.length} casos originais exportados.`);
import path from 'node:path';
import {parseWorldMap,createWorldGeometry} from '../src/world-map.js';
const road=JSON.parse(fs.readFileSync('assets/world/morro-road-v1/manifest.json'));
const actors=JSON.parse(fs.readFileSync('assets/characters/overworld-v1/manifest.json'));
const maps={};const geometryCases=[];
for(const chapter of road.chapters){
 const source='assets/'+chapter.map;const scene=parseWorldMap(JSON.parse(fs.readFileSync(source)));const tiled=scene.tiled;
 for(const image of tiled.images)fs.copyFileSync(path.join(path.dirname(source),image.image),`godot/assets/campaign/morro/${image.image}`);
 const places=scene.places.map(p=>({...p,point:scene.nodes[p.node]}));
 const npcPlace=places.find(p=>p.stage);const entry=trails.stage(chapter.stage);
 const npcs=entry.foes.map((foe,i)=>{const actor=Object.values(actors.characters).find(a=>a.name===foe.name);const image=actor?actor.image:'characters/mikka/sprites-v1.png';const bounds=actor?actor.frames[0].bounds:{x:0,y:0,w:271.5,h:362};const file=path.basename(image);fs.copyFileSync('assets/'+image,'godot/assets/campaign/morro/'+file);return{name:foe.name,image:file,bounds,point:[npcPlace.point[0]+58+i*46,npcPlace.point[1]-3]};});
 maps[chapter.id]={id:chapter.id,name:chapter.name,stage:chapter.stage,spawn:scene.nodes[scene.spawn],walkable:tiled.layers.Walkable,blocked:tiled.layers.Solids,foreground:tiled.layers.Foreground,images:tiled.images,places,npcs,nodes:scene.nodes,edges:scene.edges};
 const geometry=createWorldGeometry(tiled);const probes=[];for(let y=32;y<1024;y+=31)for(let x=32;x<1536;x+=37)probes.push({point:[x,y],safe:geometry.safe({x,y})});
 geometryCases.push({id:chapter.id,probes});
}
fs.writeFileSync('godot/assets/campaign/morro/maps.json',JSON.stringify(maps));
fs.writeFileSync('godot/tests/fixtures/morro-maps.json',JSON.stringify(geometryCases));
console.log('Cinco mapas, navegação e personagens originais exportados.');
const kit=JSON.parse(fs.readFileSync('assets/world/quintal-kit-v1/manifest.json'));
fs.copyFileSync('assets/'+kit.sheets[kit.frames.fence.sheet].image,'godot/assets/campaign/morro/gate-sheet.png');
fs.writeFileSync('godot/assets/campaign/morro/gate.json',JSON.stringify(kit.frames.fence));
