import test from 'node:test';
import assert from 'node:assert/strict';
import {artConfig} from './scripts/art-build.mjs';
import {drawWorldArtGround,worldTerrainContours,auditWorldStructure} from './src/world-art.js';
import {worldRenderQueue} from './src/world-map.js';
import {createWorldNavigation} from './src/world-navigation.js';

test('garden circuit offers two safe branches, reachable searches and a return without compulsory grass',()=>{
 const garden=artConfig().courtyard.world.scenes['park-trail'],clearing=artConfig().courtyard.world.scenes['park-clearing'];
 const nav=createWorldNavigation(garden),walk=garden.tiled.layers.Walkable;
 const contains=(r,p)=>p.x>=r.x&&p.x<=r.x+r.w&&p.y>=r.y&&p.y<=r.y+r.h;
 const safeTrail=p=>walk.some(r=>r.properties.safe_area&&contains(r,p));
 const branches=[[[592,816],[592,528],[1136,528]],[[592,816],[1136,816],[1136,528]]];
 for(const branch of branches){const actor=nav.create();nav.target(actor,{x:branch[0][0],y:branch[0][1]},true);
  for(const [x,y]of [...branch.slice(1),[1296,400],...branch.toReversed()]){
   assert.ok(nav.target(actor,{x,y}).length,'branch destination reachable');let steps=0;
   while(actor.path.length&&steps++<2000){nav.step(actor,.05);assert.ok(nav.geometry.safe(actor),'Kael stays clear of trunks');assert.ok(nav.geometry.safe(nav.follower(actor)),'partner stays on walkable ground');assert.ok(safeTrail(actor),'branch can be walked without entering a search patch');}
   assert.ok(Math.hypot(actor.x-x,actor.y-y)<.1);
  }
 }
 const habitats=walk.filter(r=>r.properties.habitat_id);
 assert.deepEqual([...new Set(habitats.map(r=>r.properties.habitat_id))].sort(),['jardim-campo','jardim-encosta','jardim-recanto']);
 for(const id of new Set(habitats.map(r=>r.properties.habitat_id))){const patch=habitats.find(r=>r.properties.habitat_id===id),point=nav.nodes.filter(p=>contains(patch,p)).sort((a,b)=>Math.hypot(a.x-patch.x-patch.w/2,a.y-patch.y-patch.h/2)-Math.hypot(b.x-patch.x-patch.w/2,b.y-patch.y-patch.h/2))[0],actor=nav.create();assert.ok(point&&nav.target(actor,point).length,id);}
 assert.notDeepEqual(walk.filter(r=>r.properties.safe_area).map(r=>[r.x,r.y,r.w,r.h]),clearing.tiled.layers.Walkable.filter(r=>r.properties.safe_area).map(r=>[r.x,r.y,r.w,r.h]));
});

test('park planting and terrain form continuous families while every destination and habitat remains reachable',()=>{
 const config=artConfig().courtyard.world;
 for(const id of ['park-trail','park-clearing']){
  const scene=config.scenes[id],props=scene.tiled.properties;
  assert.equal(props.terrain_repeat,'mirror');assert.equal(props.terrain_edge_mode,'none');
  assert.deepEqual(auditWorldStructure(scene,scene.art),[]);
  const trees=scene.art.objects.filter(o=>o.sprite.frame.startsWith('park-tree'));
  assert.ok(trees.some(o=>o.sprite.frame==='park-tree-a')&&trees.some(o=>o.sprite.frame==='park-tree-b'));
  assert.ok(trees.filter(o=>o.sprite.frame==='park-tree').length<=2,'caught kites are landmarks, not repeated decoration');
  assert.ok(trees.every(o=>o.occludesActors));
  assert.ok(!scene.art.objects.some(o=>['park-habitat','fence','shrub'].includes(o.sprite.frame)),'no borrowed isolated stamps');
  const habitats=scene.tiled.layers.Walkable.filter(r=>r.properties.encounter_zone);
  assert.ok(habitats.every(r=>r.properties.ground_frame==='park-tall-grass'));
  assert.equal(worldTerrainContours(habitats).length,3,'overlapping authored rectangles become three continuous planting beds');
  const nav=createWorldNavigation(scene),actor=nav.create();
  for(const place of scene.places){const[x,y]=scene.nodes[place.node];assert.ok(nav.target(actor,{x,y}).length,place.name);}
  for(const r of habitats){const center={x:r.x+r.w/2,y:r.y+r.h/2},samples=[];for(let y=r.y+20;y<r.y+r.h-10;y+=20)for(let x=r.x+20;x<r.x+r.w-10;x+=20)samples.push({x,y});const safe=samples.filter(p=>nav.geometry.safe(p));assert.ok(safe.length/samples.length>.7,'habitat remains mostly traversable around authored column bases');const p=nav.geometry.safe(center)?center:safe.sort((a,b)=>Math.hypot(a.x-center.x,a.y-center.y)-Math.hypot(b.x-center.x,b.y-center.y))[0];assert.ok(p&&nav.target(actor,p).length,'habitat entry reachable');}
 }
});

test('adjacent mirrored tiles meet on the same source edge without atlas bleed or inverted tall-grass blades',()=>{
 const scene=artConfig().courtyard.world.scenes['park-trail'],draws=[],stack=[];let matrix=[1,1,0,0];
 const g={save(){stack.push([...matrix]);},restore(){matrix=stack.pop();},beginPath(){},rect(){},clip(){},fillRect(){},moveTo(){},lineTo(){},closePath(){},quadraticCurveTo(){},
  translate(x,y){matrix[2]+=x*matrix[0];matrix[3]+=y*matrix[1];},scale(x,y){matrix[0]*=x;matrix[1]*=y;},
  drawImage(image,sx,sy,sw,sh,x,y,w,h){draws.push({sx,sy,sw,sh,x:matrix[2]+x*matrix[0],y:matrix[3]+y*matrix[1],w:w*matrix[0],h:h*matrix[1],smoothing:this.imageSmoothingEnabled});}};
 const images=new Map(Object.keys(scene.art.kit.sheets).map(k=>['world-kit-'+k,{}]));
 drawWorldArtGround(g,scene,images,true);
 const lawn=draws.filter(d=>d.sx===0&&d.sy===0&&d.sw===768&&d.sh===512);
 const first=lawn[0],right=lawn[1],below=lawn.find(d=>d.h<0);
 assert.equal(first.x+first.w,right.x+right.w); // both destination edges meet at x=384
 assert.equal(first.sx+first.sw,right.sx+right.sw); // the shared source right edge is reflected
 assert.equal(first.h,256,'material aspect is preserved');assert.equal(right.w,-384);assert.ok(below);
 assert.ok(lawn.every(d=>d.smoothing===false),'adjacent quadrant colors cannot bleed through bilinear filtering');
 const tall=draws.filter(d=>d.sx===768&&d.sy===512&&d.sw===768&&d.sh===512);
 assert.ok(tall.length);assert.ok(tall.every(d=>d.h>0),'blades keep their authored upward direction');
});

test('whole tree fades behind its own floor while its trunk collision is preserved',()=>{
 const scene=artConfig().courtyard.world.scenes['park-trail'],tree=scene.art.objects.find(o=>o.sprite.frame==='park-tree-a'),s=tree.sprite;
 const actor={id:'player',x:s.x+s.w*.5,y:tree.y-55,level:0};
 assert.equal(worldRenderQueue(scene,[actor]).find(o=>o.rect?.id===tree.rect.id).opacity,.45);
 assert.equal(worldRenderQueue(scene,[{...actor,level:1}]).find(o=>o.rect?.id===tree.rect.id).opacity,1);
 assert.ok(scene.tiled.layers.Solids.some(r=>r.id===tree.rect.id));
});
