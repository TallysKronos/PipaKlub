import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {createHash} from 'node:crypto';
import {SERVICE_INTERIORS,serviceLayout,serviceMap} from './src/service-interiors.js';
import {auditScene,pieceBox} from './tools/iso-studio/model.mjs';
import {parseWorldMap} from './src/world-map.js';
import {createWorldNavigation} from './src/world-navigation.js';
import {STREET_LAYOUT} from './src/street-layout.js';
import {createServiceIsometricRenderer} from './src/service-isometric.js';

const manifest=JSON.parse(fs.readFileSync('assets/world/village-grid-v2/manifest.json')),report=JSON.parse(fs.readFileSync('art/village-grid-v2/conferencia.json'));
test('all three houses have four tiled roof slopes, including both formerly exposed gables',()=>{
 const geometry=JSON.parse(fs.readFileSync('art/village-grid-v2/geometry.json'));
 for(const f of manifest.facades){const slopes=geometry[f.id].filter(q=>q.material==='roof');assert.equal(slopes.length,4);assert.equal(slopes.filter(q=>q.points.length===3).length,2);const right=slopes.find(q=>q.points.length===3&&q.points.slice(0,2).every(p=>p[0]===f.footprint[0]));assert.ok(right);assert.equal(right.points[0][1],0);assert.equal(right.points[1][1],f.footprint[1]);assert.ok(right.points[2][2]>right.points[0][2]);}
});
test('the delivered facades preserve native scale, measured 2:1 support and the actual doorway pivot',()=>{
 assert.deepEqual(manifest.grid,[64,32,32]);
 for(const f of manifest.facades){const a=manifest.images[f.id],b=pieceBox({footprint:f.footprint,height:f.height}),bytes=fs.readFileSync('assets/'+a.image),r=report.pieces.find(p=>p.id===f.id),h=STREET_LAYOUT.houses.find(h=>h.asset===f.id);
  assert.equal(h.w,a.width,'native width instead of arbitrary sprite fitting');assert.deepEqual(h.gridFootprint,f.footprint);assert.deepEqual(h.doorCell,f.door);assert.deepEqual([a.width,a.height],[b.w,b.h]);assert.equal(r.verdict,'ok');
  assert.ok(r.items.some(i=>i.level==='ok'&&i.text.includes('(esquerda) em 2:1')));assert.ok(r.items.some(i=>i.level==='ok'&&i.text.includes('(direita) em 2:1')));
  assert.equal(r.sha256,createHash('sha256').update(bytes).digest('hex'));
  const [u,v]=f.door;assert.ok(Math.abs(a.pivot[0]*a.width-(f.footprint[1]*32+(u-v)*32))<1e-7);assert.ok(Math.abs(a.pivot[1]*a.height-(f.height*32+(u+v)*16))<1e-7);
 }
});
test('both service rooms use nonoverlapping Iso Studio footprints and audited native PNGs',()=>{
 for(const [id,p]of Object.entries(SERVICE_INTERIORS)){assert.deepEqual(auditScene(p.room,p.pieces),[]);assert.ok(p.room.cells[0]>=14&&p.room.cells[1]>=11);
  const source=JSON.parse(fs.readFileSync(`art/village-grid-v2/${id}.isostudio.json`));assert.equal(source.pieces.length,p.pieces.length);
  for(const q of p.pieces){const a=manifest.images[p.prefix+q.id],b=pieceBox(q),bytes=fs.readFileSync('assets/'+a.image),r=report.pieces.find(r=>r.id===p.prefix+q.id);assert.deepEqual([bytes.readUInt32BE(16),bytes.readUInt32BE(20)],[b.w,b.h]);assert.notEqual(r.verdict,'fail');assert.equal(r.sha256,createHash('sha256').update(bytes).digest('hex'));assert.deepEqual(Buffer.from(source.pieces.find(s=>s.id===q.id).image.split(',')[1],'base64'),bytes);}
 }
});
test('all interior destinations stay reachable in both directions with a safe companion',()=>{
 for(const id of Object.keys(SERVICE_INTERIORS)){const p=serviceLayout(id),s=parseWorldMap(serviceMap(id)),nav=createWorldNavigation(s);
  if(p.npc)assert.ok(nav.geometry.safe({x:p.npc[0],y:p.npc[1]}));
  if(p.companion)assert.ok(nav.geometry.safe({x:p.companion[0],y:p.companion[1]}));
  for(const from of s.places)for(const to of s.places){const a=nav.create();nav.target(a,nav.nodes[from.node],true);assert.ok(nav.target(a,nav.nodes[to.node]).length);for(let n=0;a.path.length&&n<4000;n++){nav.step(a,.1);assert.ok(nav.geometry.safe(a));assert.ok(nav.geometry.safe(nav.follower(a,74)));}assert.equal(a.path.length,0);assert.ok(nav.distance(a,nav.nodes[to.node])<1);}
 }
});
test('the new service renderer shares the floor projection, depth order, actions and inverse clicks',()=>{
 const g=new Proxy({canvas:{width:1280,height:720}},{get:(o,k)=>k in o?o[k]:()=>{},set:(o,k,v)=>(o[k]=v,true)});
 for(const id of Object.keys(SERVICE_INTERIORS)){const scene={village:id},r=createServiceIsometricRenderer(scene,{},{},null),plan=serviceLayout(id),a={x:1056,y:1120},seen=[];
  r.draw(g,a,[{...a,action:'professor',draw:p=>seen.push(p)}]);assert.deepEqual(seen,[r.project(a)]);assert.equal(r.pick({x:seen[0].x,y:seen[0].y-50}).action,'professor');
  for(const [w,h]of [[1280,720],[825,885],[390,700]]){const c=r.camera(a,w,h),p=r.project(a),q=r.unproject(p);assert.ok(c.scale>0);assert.ok(Math.hypot(a.x-q.x,a.y-q.y)<1e-7);assert.ok((p.x-c.x)*c.scale>0&&(p.x-c.x)*c.scale<w);assert.ok((p.y-c.y)*c.scale>0&&(p.y-c.y)*c.scale<h);}
  for(const h of plan.hotspots.filter(h=>h.id!=='professor')){const b=r.feature(h.id);assert.ok(b&&b.w>0&&b.h>0);}
 }
});
