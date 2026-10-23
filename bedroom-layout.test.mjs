import test from 'node:test';
import assert from 'node:assert/strict';
import {BEDROOM_LAYOUT as plan,bedroomRoom,bedroomMap,bedroomObjects,bedroomProject,bedroomProjectPoint,bedroomUnprojectPoint} from './src/bedroom-layout.js';
import {auditScene,pieceBox,footprintRect,drawOrder} from './tools/iso-studio/model.mjs';
import fs from 'node:fs';
import {createOpeningRoom} from './src/opening-room.js';
import {parseWorldMap} from './src/world-map.js';
import {createWorldNavigation} from './src/world-navigation.js';
import {villageObjects,createVillageIsometricRenderer} from './src/village-isometric.js';
import {artConfig} from './scripts/art-build.mjs';
import * as model from './tools/soulgen-studio/model.mjs';

test('opening and overworld share every traversable floor point, furniture solid and action anchor',()=>{
 const r=bedroomRoom(),opening=createOpeningRoom(r),scene=parseWorldMap(bedroomMap()),nav=createWorldNavigation(scene),f=plan.floor;
 assert.deepEqual(villageObjects('kael-bedroom',{opening:true}),bedroomObjects());assert.deepEqual(villageObjects('kael-bedroom'),bedroomObjects());
 assert.equal(scene.actorSize,plan.actorHeight);
 for(let x=f.x+2;x<f.x+f.w;x+=8)for(let y=f.y+2;y<f.y+f.h;y+=8)assert.equal(opening.safe({x,y}),nav.geometry.safe({x,y}),`${x},${y}`);
 for(const p of plan.hotspots){assert.ok(opening.safe(p),p.id);assert.ok(nav.geometry.safe(p),p.id);assert.ok(opening.route({x:768,y:496},p).length,p.id);assert.ok(nav.target(nav.create(),p).length,p.id);}
 for(const o of [...plan.objects,{asset:'stairwell',footprint:Object.values(plan.stairwell)}]){const [x,y,w,h]=o.footprint,p={x:x+w/2,y:y+h/2};assert.equal(opening.safe(p),false,o.asset);assert.equal(nav.geometry.safe(p),false,o.asset);}
 for(const name of ['desk','stairs']){const h=plan.hotspots.find(h=>h.id===name),p=scene.places.find(p=>p.action===(name==='desk'?'pilot_story':'street_scene'));assert.deepEqual(scene.nodes[p.node],[h.x,h.y]);}
 assert.ok(opening.safe({x:1200,y:850}),'formerly invisible blocked floor is now traversable');
});

test('Iso Studio delivery and runtime use the same volumes, integer native pixels and front/back ordering',()=>{
 const delivery=JSON.parse(fs.readFileSync('assets/world/kael-bedroom-iso-v4/manifest.json'));
 assert.deepEqual(auditScene(bedroomProject.room,bedroomProject.pieces),[]);
 assert.deepEqual(delivery.grid.cell,[64,32]);assert.deepEqual(delivery.room.cells,[10,8]);
 const report=JSON.parse(fs.readFileSync('art/kael-bedroom-iso-v4/conferencia.json'));
 assert.equal(report.pieces.length,9);assert.ok(report.pieces.every(p=>p.verdict==='ok'));
 for(const p of bedroomProject.pieces){
  const box=pieceBox(p),a=delivery.pieces[p.id],bytes=fs.readFileSync('assets/'+delivery.images['bedroom-'+p.id].image);
  assert.deepEqual(a.anchor,box.anchor);assert.deepEqual(a.cell,p.cell);assert.equal(bytes.readUInt32BE(16),box.w);assert.equal(bytes.readUInt32BE(20),box.h);
 }
 const origin=bedroomProjectPoint(plan.floor),u=bedroomProjectPoint({x:plan.floor.x+96,y:plan.floor.y}),v=bedroomProjectPoint({x:plan.floor.x,y:plan.floor.y+96});
 assert.deepEqual([u.x-origin.x,u.y-origin.y],[32,16]);assert.deepEqual([v.x-origin.x,v.y-origin.y],[-32,16]);
 for(const p of plan.hotspots){const q=bedroomUnprojectPoint(bedroomProjectPoint(p));assert.ok(Math.hypot(p.x-q.x,p.y-q.y)<1e-8);}
 const bed=bedroomProject.pieces.find(p=>p.id==='cama'),furniture={id:'bed',rect:footprintRect(bed)};
 const behind={id:'behind',rect:{u0:.5,u1:1,v0:.5,v1:.9}},front={id:'front',rect:{u0:.5,u1:1,v0:5.1,v1:5.5}};
 assert.deepEqual(drawOrder([front,furniture,behind]).map(p=>p.id),['behind','bed','front']);
});

test('every narrative entrance, birth and follow path avoids furniture and the stair opening',()=>{
 const room=createOpeningRoom(bedroomRoom()),points=plan.blocking,p=name=>({x:points[name][0],y:points[name][1]});
 for(const [a,b]of [['kaelTV','kaelDesk'],['motherEntry','mother'],['kaelDesk','kaelTalk'],['kaelTalk','kaelBirth'],['rabbito','rabbitoNear'],['kaelBirth','motherEntry']]){
  const actor={...p(a),path:room.route(p(a),p(b))};assert.ok(actor.path.length,`${a} → ${b}`);
  for(let i=0;i<400&&actor.path.length;i++){room.tick(actor,{},.05);assert.ok(room.safe(actor));}
  assert.ok(Math.hypot(actor.x-p(b).x,actor.y-p(b).y)<1,`${a} → ${b}`);
 }
});

test('wall art stays within wall height, furniture supports do not overlap and cameras match across story/world',()=>{
 for(const a of Object.values(plan.wallArt))assert.ok(a.bottom>0&&a.bottom+a.height<plan.wallHeight);
 for(const a of plan.objects)for(const b of plan.objects)if(a!==b){const [x,y,w,h]=a.footprint,[u,v,s,t]=b.footprint;assert.ok(x+w<=u||u+s<=x||y+h<=v||v+t<=y,`${a.asset}/${b.asset}`);}
 const config=artConfig(),pack=config.courtyard.world.villageIsometric,images=Object.fromEntries(Object.entries(pack.images).map(([k,a])=>[k,{width:a.width,height:a.height}])),ctx=new Proxy({},{get:()=>()=>{}}),canvas=()=>({getContext:()=>ctx});
 const make=opening=>createVillageIsometricRenderer({village:'kael-bedroom',opening},images,pack,model,canvas);
 for(const [id,label]of Object.entries({tv:'TV',drawings:'Desenhos',desk:'Bancada'})){const r=make(true),b=r.feature(id);assert.equal(r.pick({x:b.x+b.w/2,y:b.y-16})?.hotspot,id,`${label} label is clickable`);}
 for(const [w,h]of [[1280,720],[825,885],[390,700]])assert.deepEqual(make(true).camera(null,w,h),make(false).camera(null,w,h));
 assert.deepEqual(config.opening.rooms.bedroom,bedroomRoom());
 assert.deepEqual(config.courtyard.world.scenes['kael-bedroom'].tiled.layers.Solids.map(r=>[r.x,r.y,r.w,r.h]),bedroomRoom().blocked);
});
