import fs from 'node:fs';
import {pathToFileURL} from 'node:url';
import {parseWorldMap,createWorldGeometry} from '../src/world-map.js';
import {buildWorldArtPlan} from '../src/world-art.js';
import {createParkIsometricScene} from '../src/park-isometric-layout.js';
import {createParkIsometricRenderer} from '../src/park-isometric-renderer.js';
import * as model from '../tools/soulgen-studio/model.mjs';
const {createCanvas,loadImage}=await import(pathToFileURL(process.env.SOULGEN_CANVAS_MODULE));
const read=p=>JSON.parse(fs.readFileSync(p,'utf8'));
const pack=read('assets/world/park-isometric-v1/manifest.json'),base=read('assets/world/quintal-kit-v1/manifest.json'),kit=read('assets/world/park-kit-v3/manifest.json');
const artKit={...base,sheets:{...base.sheets,...kit.sheets},frames:{...base.frames,...kit.frames}};
const images=Object.fromEntries(await Promise.all(Object.entries(pack.images).map(async([id,a])=>[id,await loadImage('assets/'+a.image)])));
const folder='godot/assets/campaign/park';fs.mkdirSync(folder,{recursive:true});
const output={};
const checks=[];
for(const id of ['park-trail','park-clearing']){
 const raw=read(`assets/world/park-v1/${id}.tmj`),original=parseWorldMap(raw);
 const art=buildWorldArtPlan(original,artKit,read(`assets/world/park-v1/${id}.art.json`));
 const scene=createParkIsometricScene(raw,art,{production:true});
 const geometry=createWorldGeometry(scene.tiled);
 const probes=[];for(let y=160;y<=960;y+=37)for(let x=48;x<=1488;x+=43)probes.push({point:[x,y],safe:geometry.safe({x,y})});
 const adjacency=scene.nodes.map(()=>[]);for(const [a,b]of scene.edges){adjacency[a].push(b);adjacency[b].push(a);}
 const parent=new Map([[scene.spawn,null]]),queue=[scene.spawn];
 for(let i=0;i<queue.length;i++)for(const next of adjacency[queue[i]])if(!parent.has(next)){parent.set(next,queue[i]);queue.push(next);}
 const paths=scene.places.map(place=>{const path=[];for(let n=place.node;n!==null;n=parent.get(n)){if(n===undefined)throw Error('Unreachable '+place.name);path.unshift(scene.nodes[n]);}return {name:place.name,path};});
 checks.push({id,probes,paths});
 const renderer=createParkIsometricRenderer(scene,images,pack,model,()=>createCanvas(1,1));
 const layers=renderer.exportLayers();fs.writeFileSync(`${folder}/${id}-floor.png`,layers.floor.toBuffer('image/png'));
 const props=layers.layers.map(p=>{const image=`${id}-${p.index}.png`;fs.writeFileSync(`${folder}/${image}`,p.canvas.toBuffer('image/png'));return {...p,canvas:undefined,image};});
 output[id]={id,name:scene.name,spawn:scene.nodes[scene.spawn],walkable:scene.tiled.layers.Walkable,blocked:scene.tiled.layers.Solids,places:scene.places.map(p=>({...p,point:scene.nodes[p.node]})),props,floorImage:`${id}-floor.png`};
}
fs.writeFileSync(`${folder}/maps.json`,JSON.stringify(output,null,2));
fs.mkdirSync('godot/tests/fixtures',{recursive:true});fs.writeFileSync('godot/tests/fixtures/park.json',JSON.stringify(checks));
console.log('Parque exportado do renderer original, com objetos separados e geometria canônica.');
