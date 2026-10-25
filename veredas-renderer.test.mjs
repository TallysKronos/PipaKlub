import test from 'node:test';
import assert from 'node:assert/strict';
import {artConfig} from './scripts/art-build.mjs';
import {createParkIsometricRenderer} from './src/park-isometric-renderer.js';
import {toIso} from './src/world-isometric.js';
import {veredasTerrainPlan} from './src/veredas-region-renderer.js';
import {createParkBossScene} from './src/park-boss-layout.js';
import * as model from './tools/soulgen-studio/model.mjs';

test('terrain joints leave ramp mouths open and keep earth outside bridge decks',()=>{
 const scene=createParkBossScene(),plan=veredasTerrainPlan(scene);
 assert.equal(plan.bridges.length,2);
 for(const bridge of plan.bridges){const water=scene.veredas.water[0];assert.equal(bridge.x,water.x-24);assert.equal(bridge.x+bridge.w,water.x+water.w+24);
  for(const path of plan.paths.filter(r=>r.elevation===0))assert.ok(!(path.x<bridge.x+bridge.w&&path.x+path.w>bridge.x&&path.y<bridge.y+bridge.h&&path.y+path.h>bridge.y),'earth overlaps bridge');
  assert.ok(plan.paths.some(r=>r.x+r.w===bridge.x&&r.y===bridge.y));assert.ok(plan.paths.some(r=>r.x===bridge.x+bridge.w&&r.y===bridge.y));
 }
 for(const ramp of plan.ramps){assert.ok(!plan.cliffs.some(e=>e.axis==='x'&&e.y===ramp.y&&e.x<ramp.x+ramp.w&&e.x+e.w>ramp.x),'wall crosses ramp mouth');assert.ok(plan.paths.some(r=>r.elevation===96&&r.x===ramp.x&&r.y+r.h===ramp.y));assert.ok(plan.paths.some(r=>r.elevation===0&&r.x===ramp.x&&r.y===ramp.y+ramp.h));}
});

test('Veredas uses the same height for floors, stair movement, actor rendering and pointer picking',()=>{
 const config=artConfig().courtyard.world,scene=config.scenes['park-veredas'],pack=config.parkIsometric;
 const images=Object.fromEntries(Object.entries(pack.images).map(([id,a])=>[id,{width:a.width,height:a.height}]));
 const ctx=new Proxy({canvas:{width:1104,height:700}},{get:(o,k)=>k in o?o[k]:()=>{},set:(o,k,v)=>(o[k]=v,true)});
 const renderer=createParkIsometricRenderer(scene,images,pack,model,()=>({width:1,height:1,getContext:()=>ctx}));
 for(const p of [{x:224,y:816},{x:784,y:608},{x:416,y:384},{x:1744,y:608},{x:2112,y:384},{x:2944,y:352}]){const projected=renderer.project(p),back=renderer.unproject(projected);assert.ok(Math.hypot(p.x-back.x,p.y-back.y)<3,JSON.stringify(p));}
 assert.equal(toIso({x:416,y:384}).y-renderer.project({x:416,y:384}).y,96);
 assert.equal(toIso({x:1744,y:608}).y-renderer.project({x:1744,y:608}).y,48);
 const actor={x:416,y:432,path:[],history:[]},draws=[];
 renderer.draw(ctx,actor,[{...actor,draw:p=>draws.push(p)}],{animate:false,opened:['lookout']});
 assert.deepEqual(draws,[renderer.project(actor)]);
 const chest=renderer.project({x:416,y:384});assert.equal(renderer.pick({x:chest.x,y:chest.y-30}).target,'lookout');
});
