import test from'node:test';
import assert from'node:assert/strict';
import fs from'node:fs';
import{HOME_LAYOUT as plan,homeProject,homeRoom,homeMap}from'./src/home-layout.js';
import{createOpeningRoom}from'./src/opening-room.js';
import{parseWorldMap}from'./src/world-map.js';
import{createWorldNavigation}from'./src/world-navigation.js';
import{auditScene,pieceBox}from'./tools/iso-studio/model.mjs';
import{createVillageIsometricRenderer}from'./src/village-isometric.js';
test('downstairs has one measured layout for story, solid furniture, exits and free walking',()=>{
 const r=homeRoom(),opening=createOpeningRoom(r),scene=parseWorldMap(homeMap()),nav=createWorldNavigation(scene),f=plan.floor;
 assert.deepEqual(auditScene(homeProject.room,homeProject.pieces),[]);assert.equal(scene.actorSize,102);
 for(let x=f.x+2;x<f.x+f.w;x+=8)for(let y=f.y+2;y<f.y+f.h;y+=8)assert.equal(opening.safe({x,y}),nav.geometry.safe({x,y}),`${x},${y}`);
 for(const p of plan.hotspots){assert.ok(opening.safe(p),p.id);assert.ok(nav.target(nav.create(),p).length,p.id);const place=scene.places.find(q=>q.name===p.name);assert.deepEqual(scene.nodes[place.node],[p.x,p.y]);}
 for(const o of plan.objects){const[x,y,w,h]=o.footprint;assert.equal(opening.safe({x:x+w/2,y:y+h/2}),false,o.asset);}
});
test('arrival from upstairs, mother conversation and street exit keep both companions on safe floor',()=>{
 const nav=createOpeningRoom(homeRoom()),p=a=>({x:a[0],y:a[1]}),points=[p(plan.blocking.kaelEntry),p(plan.blocking.rabbitoEntry),...plan.hotspots];
 for(const a of points)for(const b of points){const actor={...a,path:nav.route(a,b)};assert.ok(actor.path.length,'route '+JSON.stringify([a,b]));for(let n=0;n<500&&actor.path.length;n++){nav.tick(actor,{},.05);assert.ok(nav.safe(actor));}assert.ok(Math.hypot(actor.x-b.x,actor.y-b.y)<1);}
 assert.ok(nav.safe(p(plan.blocking.mother)));
});
test('upstairs and street portals have a safe step away without entering furniture',()=>{
 const nav=createWorldNavigation(parseWorldMap(homeMap()));for(const id of ['upstairs','exit']){const p=plan.hotspots.find(h=>h.id===id);assert.ok([[0,-64],[64,0],[-64,0],[0,64]].some(([x,y])=>nav.geometry.segment(p,{x:p.x+x,y:p.y+y})),id);}
});
test('story and exploration share the downstairs camera, inverse clicks and visibly positioned actions',()=>{
 const ctx=new Proxy({canvas:{width:1280,height:720}},{get:(o,k)=>k in o?o[k]:()=>{},set:(o,k,v)=>(o[k]=v,true)}),canvas=()=>({getContext:()=>ctx}),make=opening=>createVillageIsometricRenderer({village:'kael-home',opening},{},{},null,canvas);
 const a=make(true),b=make(false);for(const[w,h]of[[1280,720],[825,885],[390,700]])assert.deepEqual(a.camera(null,w,h),b.camera(null,w,h));
 for(const p of plan.hotspots){const q=a.unproject(a.project(p));assert.ok(Math.hypot(p.x-q.x,p.y-q.y)<1e-8);const box=a.feature(p.id);assert.ok(box.w>0&&box.h>0);}
 for(const id of ['mother','exit']){const box=a.feature(id);assert.equal(a.pick({x:box.x+box.w/2,y:box.y-16}).hotspot,id);}
});
test('the final downstairs delivery preserves every Iso Studio anchor and native image size',()=>{
 const manifest=JSON.parse(fs.readFileSync('assets/world/kael-home-iso-v1/manifest.json')),report=JSON.parse(fs.readFileSync('art/kael-home-iso-v1/conferencia.json'));
 assert.equal(report.pieces.length,10);assert.ok(report.pieces.every(p=>p.verdict!=='fail'));
 for(const p of homeProject.pieces){const b=pieceBox(p),bytes=fs.readFileSync('assets/'+manifest.images['home-'+p.id].image);assert.deepEqual(manifest.pieces[p.id].anchor,b.anchor);assert.deepEqual(manifest.pieces[p.id].cell,p.cell);assert.deepEqual([bytes.readUInt32BE(16),bytes.readUInt32BE(20)],[b.w,b.h]);}
});

test('a tall staircase fades when it occludes Kael, remains solid in front and restores alpha',()=>{
 const context=new Proxy({canvas:{width:1280,height:720}},{get:(o,k)=>k in o?o[k]:()=>{}}),canvas=()=>({getContext:()=>context}),stair={id:'stair'},r=createVillageIsometricRenderer({village:'kael-home'},{'home-escada':stair},{},null,canvas);
 function render(actor){const seen=[],stack=[],g=new Proxy({globalAlpha:1,save(){stack.push(this.globalAlpha);},restore(){this.globalAlpha=stack.pop();},drawImage(im){if(im===stair)seen.push(this.globalAlpha);}},{get:(o,k)=>k in o?o[k]:()=>{}});r.draw(g,actor,[{...actor,type:'player',draw(){}}]);assert.equal(g.globalAlpha,1);return seen;}
 assert.deepEqual(render({x:1248,y:720}),[.3]);assert.deepEqual(render({x:1440,y:1104}),[1]);
});
