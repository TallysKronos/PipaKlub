import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {parseWorldMap} from './src/world-map.js';
import {buildWorldArtPlan,auditWorldStructure,worldTerrainContours,drawWorldArtGround} from './src/world-art.js';
const load=()=>JSON.parse(fs.readFileSync('assets/world/quintal-modular-v1/project.json','utf8'));
const sceneOf=p=>parseWorldMap(p.map);
function change(frame,fn){const p=load(),entry=Object.entries(p.layout.bindings).find(([,b])=>b.frame===frame);fn(entry[1],p,entry[0]);return p;}
const check=p=>buildWorldArtPlan(sceneOf(p),p.kit,p.layout);

test('corrected courtyard passes structural review; original floating canopy and wall gaps fail',()=>{
 const p=load(),scene=sceneOf(p);assert.deepEqual(auditWorldStructure(scene,check(p)),[]);
 assert.throws(()=>check(change('canopy',b=>{b.footY-=24;})),/ARB-02/);
 assert.throws(()=>check(change('trunk',b=>{b.footX+=50;})),/ARB-01/);
 assert.throws(()=>check(change('wall-vertical',b=>{b.width=16;})),/MUR-01|MUR-02/);
 assert.throws(()=>check(change('wall-horizontal',b=>{b.footY-=5;})),/MUR-02/);
});
test('blocked and obscured benches and missing rounded terrain fail before export',()=>{
 assert.throws(()=>check(change('bench',b=>{b.footX=800;b.footY=864;})),/MOB-01/);
 assert.throws(()=>check(change('bench',b=>{b.footX=20;b.footY=120;})),/MOB-02/);
 const p=load();p.map.properties=p.map.properties.filter(v=>v.name!=='ground_corner_radius');assert.throws(()=>check(p),/PIS-01/);
 // Editing remains visible even while the draft is invalid; compile/export still reject it.
 const q=change('canopy',b=>b.footY-=60);assert.ok(buildWorldArtPlan(sceneOf(q),q.kit,q.layout,{audit:false}).objects.length);
});
const area=loop=>loop.reduce((sum,p,i)=>{const n=loop[(i+1)%loop.length];return sum+p.x*n.y-n.x*p.y;},0)/2;
test('terrain union removes internal seams and retains concave turns, holes and diagonal islands',()=>{
 const t=worldTerrainContours([{x:0,y:0,w:96,h:32},{x:32,y:32,w:32,h:64}]);assert.equal(t.length,1);assert.equal(area(t[0]),5120);assert.equal(t[0].length,8);
 const holes=worldTerrainContours([{x:0,y:0,w:96,h:32},{x:0,y:64,w:96,h:32},{x:0,y:32,w:32,h:32},{x:64,y:32,w:32,h:32}]);assert.equal(holes.length,2);assert.equal(holes.reduce((s,l)=>s+area(l),0),8192);assert.ok(holes.some(l=>area(l)<0));
 const diagonal=worldTerrainContours([{x:0,y:0,w:32,h:32},{x:32,y:32,w:32,h:32}]);assert.equal(diagonal.length,2);
 assert.deepEqual(worldTerrainContours([]),[]);
});
test('actual ground renderer rounds the complete dirt union once with no seams at rectangle junctions',()=>{
 const p=load(),scene=sceneOf(p);scene.art=check(p);const curves=[],clips=[];
 const g={save(){},restore(){},beginPath(){},rect(){},clip(rule){clips.push(rule);},fillRect(){},drawImage(){},moveTo(){},lineTo(){},closePath(){},quadraticCurveTo(...args){curves.push(args);}};
 drawWorldArtGround(g,scene,new Map(),true);
 assert.equal(clips.filter(v=>v==='evenodd').length,1);assert.ok(curves.length>=8);assert.ok(curves.every(c=>c.every(Number.isFinite)));
});

test('wall sides and four corners share one atlas and one pixel scale; short ends are cropped',()=>{
 const p=load(),plan=check(p),f=p.kit.frames;
 const ids=['wall-horizontal','wall-vertical','wall-south','wall-east','wall-corner','wall-ne','wall-sw','wall-se'];
 for(const id of ids)assert.equal(f[id].sheet,'quintal-walls');
 assert.equal(f['wall-corner'].x+f['wall-corner'].w,f['wall-horizontal'].x);
 assert.equal(f['wall-horizontal'].x+f['wall-horizontal'].w,f['wall-ne'].x);
 assert.equal(f['wall-corner'].y+f['wall-corner'].h,f['wall-vertical'].y);
 assert.equal(f['wall-vertical'].y+f['wall-vertical'].h,f['wall-sw'].y);
 const walls=plan.objects.filter(o=>ids.includes(o.sprite.frame));
 assert.ok(walls.some(o=>o.sprite.sw<f[o.sprite.frame].w));assert.ok(walls.some(o=>o.sprite.sh<f[o.sprite.frame].h));
 for(const {sprite:s} of walls){assert.equal(s.w/s.sw,3/16);assert.equal(s.h/s.sh,3/16);}
 assert.throws(()=>check(change('wall-horizontal',b=>{b.sourceWidth=99999;})),/recorte/i);
});
