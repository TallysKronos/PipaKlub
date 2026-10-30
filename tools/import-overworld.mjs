// PIP-88: compile source maps without changing campaign rules or save coordinates.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {parseTiled,audit,verdict,blockedByPiece,walkable,canStep,cliffs,heightAt} from './mapa-studio/model.mjs';
const root=fileURLToPath(new URL('../',import.meta.url));
const input=path.join(root,'art/overworld/mapas');
const out=path.join(root,'godot/assets/overworld/maps');fs.mkdirSync(out,{recursive:true});
const sets={'rascunho.tsj':JSON.parse(fs.readFileSync(path.join(root,'art/overworld/tiles/rascunho.tsj'),'utf8'))};
const props=raw=>Object.fromEntries((raw.properties||[]).map(p=>[p.name,p.value]));
export function compile(raw,id){
 const m=parseTiled(raw,sets),issues=audit(m);
 if(verdict(issues)==='fail')throw Error(`${id}: ${JSON.stringify(issues.filter(i=>i.level==='fail'))}`);
 const solid=blockedByPiece(m),allowed=[],edges=[],heightProbes=[];
 for(let v=0;v<m.h;v++)for(let u=0;u<m.w;u++){
  const i=v*m.w+u;
  if(walkable(m,u,v,solid))allowed.push(i);
  for(const[du,dv]of[[1,0],[-1,0],[0,1],[0,-1]])if(u+du>=0&&v+dv>=0&&u+du<m.w&&v+dv<m.h&&canStep(m,{u,v},{u:u+du,v:v+dv},solid))edges.push([i,(v+dv)*m.w+u+du]);
  if(m.cells[i].ramp)for(const t of[.01,.25,.5,.75,.99])heightProbes.push([u+t,v+t,heightAt(m,u+t,v+t)]);
 }
 // One canonical material per shared vertex; corner bits top/right/bottom/left.
 const vertex=(u,v)=>{
  const votes=new Map();
  for(const[du,dv]of[[-1,-1],[0,-1],[0,0],[-1,0]]){const c=m.cells[(v+dv)*m.w+u+du];if(u+du<0||u+du>=m.w||v+dv<0||v+dv>=m.h||!c)continue;votes.set(c.material,(votes.get(c.material)||0)+1);}
  return [...votes].sort((a,b)=>b[1]-a[1]||String(a[0]).localeCompare(String(b[0])))[0]?.[0];
 };
 const cells=m.cells.map((c,i)=>{const u=i%m.w,v=Math.floor(i/m.w);return {...c,corners:[vertex(u,v),vertex(u+1,v),vertex(u+1,v+1),vertex(u,v+1)]};});
 const p=props(raw);
 return {...(p.forest?{forest:JSON.parse(p.forest)}:{}),schema:'overworld-godot-1',id,name:m.name,scene:p.cena_jogo||id,biome:p.bioma||'veredas',grid:[64,32],levelPx:64,w:m.w,h:m.h,cells,pieces:m.pieces,events:m.events,spawn:m.spawn,zones:m.zones,cliffs:cliffs(m),audit:issues,oracle:{walkable:allowed,edges,heightProbes},source:{file:`art/overworld/mapas/${id}.tmj`,sha256:crypto.createHash('sha256').update(JSON.stringify(raw)).digest('hex')}};
}
export function build(){
 const index={schema:'overworld-index-1',areas:[],scenes:{},campaignReplacement:false};
 for(const file of fs.readdirSync(input).filter(f=>f.endsWith('.tmj')).sort()){
  const id=file.slice(0,-4),map=compile(JSON.parse(fs.readFileSync(path.join(input,file),'utf8')),id);
  fs.writeFileSync(path.join(out,id+'.json'),JSON.stringify(map));
  index.areas.push({id,name:map.name,scene:map.scene,biome:map.biome});
  if(id!=='veredas-piloto')index.scenes[map.scene]=id;
 }
 fs.writeFileSync(path.join(out,'index.json'),JSON.stringify(index,null,2)+'\n');
 buildPieceScenes();
 console.log(`${index.areas.length} plantas compiladas (9 áreas + piloto); células, conexões e faces do modelo preservadas.`);
 return index;
}
export function buildPieceScenes(){
 const kitRoot=path.join(root,'godot/assets/overworld/kits');
 if(!fs.existsSync(kitRoot))return;
 for(const biome of fs.readdirSync(kitRoot).filter(b=>/^[a-z0-9-]+$/.test(b))){
  const file=path.join(root,`godot/assets/overworld/kits/${biome}/kit.json`);
  if(!fs.existsSync(file))continue;
  const kit=JSON.parse(fs.readFileSync(file,'utf8'));
  const dir=path.join(root,`godot/scenes/overworld/pieces/${biome}`);fs.mkdirSync(dir,{recursive:true});
  for(const[asset,group]of Object.entries(kit.pieces))for(const[variant,entry]of Object.entries(group.variants)){
   const resource=`res://assets/overworld/kits/${biome}/`;
   const [u,v]=entry.footprint,a=u*32,b=v*32;
   const points=[(b-a)/2,-(a+b)/4,(a+b)/2,(a-b)/4,(a-b)/2,(a+b)/4,-(a+b)/2,(b-a)/4];
   const body=entry.bloqueia?`\n[node name="Body" type="StaticBody2D" parent="."]\ncollision_layer = 2\ncollision_mask = 0\n\n[node name="Footprint" type="CollisionPolygon2D" parent="Body"]\npolygon = PackedVector2Array(${points.join(', ')})\n`:'';
   const text=`[gd_scene load_steps=4 format=3]\n\n[ext_resource type="Script" path="res://scripts/overworld/prop.gd" id="1"]\n[ext_resource type="Texture2D" path="${resource+entry.file}" id="2"]\n[ext_resource type="Texture2D" path="${resource+entry.shadow}" id="3"]\n\n[node name="Piece" type="Node2D"]\nscript = ExtResource("1")\n\n[node name="Art" type="Sprite2D" parent="."]\ntexture = ExtResource("2")\ncentered = false\nposition = Vector2(${-entry.anchor[0]}, ${-entry.anchor[1]})\n\n[node name="Contact" type="Sprite2D" parent="."]\ntexture = ExtResource("3")\nz_index = -1\n${body}`;
   fs.writeFileSync(path.join(dir,`${asset}-${variant}.tscn`),text);
   entry.scene=`res://scenes/overworld/pieces/${biome}/${asset}-${variant}.tscn`;
  }
  fs.writeFileSync(file,JSON.stringify(kit,null,2)+'\n');
 }
}
if(process.argv[1]===fileURLToPath(import.meta.url))build();
