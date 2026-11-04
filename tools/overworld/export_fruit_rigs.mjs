// Authoring export with the SAME Soulgen sampler used by the Pipamons. No tests.
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {render,sample,validate} from '../soulgen-studio/model.mjs';
import {anatomyReport} from '../soulgen-studio/workflow.mjs';
const {createCanvas,loadImage}=await import(pathToFileURL('C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@napi-rs/canvas/index.js'));
const art='art/overworld/kits/frutiferas',runtime='godot/assets/overworld/kits/frutiferas',review='documentation/overworld/frutiferas-v1';
const specs=JSON.parse(fs.readFileSync(art+'/briefs.json','utf8').replace(/^\uFEFF/,'')).assets;
const records=JSON.parse(fs.readFileSync(art+'/rigs.json','utf8'));
for(const p of [art+'/pecas',runtime+'/pecas',review+'/frames'])fs.mkdirSync(p,{recursive:true});
const kit={schema:'overworld-kit-1',biome:'frutiferas',grid:{cell:[64,32],height:32,levelPx:64},approval:'pending_owner_review',
 role:'articulated_fruit_tree_library',campaignIntegrated:false,inventoryIntegrated:false,pieces:{},materials:{},transitions:{},walls:{},stairs:{},bridges:{}};
const reports=[];
fs.mkdirSync('godot/scenes/overworld/fruit-trees',{recursive:true});
for(const s of specs){
 const r=records.find(r=>r.id===s.id),p=JSON.parse(fs.readFileSync(r.project,'utf8')),check=validate(p);
 if(!check.ok)throw Error(s.id+': '+check.errors.join('; '));
 const joints=anatomyReport(p);if(joints.warnings.length)throw Error(s.id+': '+joints.warnings.join('; '));
 // Creature-only recommended clips are irrelevant to environmental trees.
 const images=Object.fromEntries(await Promise.all(Object.entries(p.assets).map(async([key,a])=>[key,await loadImage('.'+a.src)])));
 const canvas=createCanvas(p.width,p.height),ctx=canvas.getContext('2d');render(ctx,p,images,sample(p,'idle',0),{scale:1});
 const data=canvas.toBuffer('image/png');fs.writeFileSync(art+`/pecas/${s.id}-default.png`,data);fs.writeFileSync(runtime+`/pecas/${s.id}-default.png`,data);
 const e={file:`pecas/${s.id}-default.png`,size:[p.width,p.height],footprint:[1,1],visualFootprint:s.visualFootprint,bloqueia:true,
  height:Math.ceil(s.height/32),anchor:p.rootPivot,isoAnchor:[s.visualFootprint[0]*32,p.height],groundAnchor:'center',
  shadow:'sombras/contato.png',rasterSize:[p.width,s.height],displayName:s.name,species:s.id,
  articulatedScene:`res://scenes/overworld/fruit-trees/${s.id}.tscn`,rig:r.runtime,
  source:{file:r.project,tool:'image_gen.imagegen; Soulgen sampler',note:'Assembled from separately authored complete hidden parts.'},
  collisionStatus:'proposed_trunk_cell_requires_map_fit',approval:'pending_owner_review'};
 kit.pieces[s.id]={default:'default',variants:{default:e}};
 fs.writeFileSync(`godot/scenes/overworld/fruit-trees/${s.id}.tscn`,`[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://scripts/overworld/fruit_tree.gd" id="1"]\n\n[node name="FruitTree" type="Node2D"]\nscript = ExtResource("1")\nrig_path = "${r.runtime}"\n`);
 for(const [i,t]of [0,.08,.18,.34,.62,.95,1.6].entries()){
  render(ctx,p,images,sample(p,'drop',t),{scale:1});fs.writeFileSync(review+`/frames/${s.id}-${i}.png`,canvas.toBuffer('image/png'));
 }
 reports.push({id:s.id,parts:p.parts.map(q=>({id:q.id,parent:q.parent,pivot:q.pivot,rect:q.rect})),clips:Object.keys(p.clips),schemaValid:check.ok,
  warnings:check.warnings.filter(s=>!s.startsWith('Animação recomendada ausente:')),jointNotes:joints.notes,sourceBounds:p.environment.cropBounds});
}
for(const f of [art+'/kit.json',runtime+'/kit.json'])fs.writeFileSync(f,JSON.stringify(kit,null,2)+'\n');
fs.writeFileSync(review+'/rig-preparation.json',JSON.stringify(reports,null,2)+'\n');
console.log('12 editable Soulgen rigs exported with native-scale rest and 7 animation poses each. No test suite.');
// Smooth animation contact sheet, rendered with Soulgen, not an invented pixel redraw.
fs.mkdirSync(review+'/animacao',{recursive:true});
const projects=await Promise.all(records.map(async r=>{const p=JSON.parse(fs.readFileSync(r.project,'utf8'));return {p,images:Object.fromEntries(await Promise.all(Object.entries(p.assets).map(async([key,a])=>[key,await loadImage('.'+a.src)])))};}));
for(let i=0;i<48;i++){
 const board=createCanvas(1280,1080),b=board.getContext('2d');b.fillStyle='#ECDFC1';b.fillRect(0,0,1280,1080);
 for(let j=0;j<projects.length;j++){
  const {p,images}=projects[j],cell=createCanvas(p.width,p.height);render(cell.getContext('2d'),p,images,sample(p,'drop',Math.max(0,i/24-.2)),{scale:1});
  const x=j%4*320,y=Math.floor(j/4)*360;b.drawImage(cell,x,y+285-p.rootPivot[1]);
  b.fillStyle='#23394A';b.font='bold 19px sans-serif';b.fillText(specs[j].name,x+15,y+325);
 }
 fs.writeFileSync(review+`/animacao/frame-${String(i).padStart(3,'0')}.png`,board.toBuffer('image/png'));
}
