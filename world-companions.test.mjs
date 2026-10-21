import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {createWorldCompanions,worldCompanionMotion,worldPrimeCompanionTrail} from './src/world-actors.js';
import {artConfig} from './scripts/art-build.mjs';
import {createAssetHandler} from './src/static-assets.js';

test('overworld companion direction follows its own path and remains stable when stopped',()=>{
 let motion=worldCompanionMotion(null,{x:10,y:10},3);
 assert.equal(motion.direction,3);assert.equal(motion.moving,false);
 motion=worldCompanionMotion(motion,{x:20,y:10},0);
 assert.equal(motion.direction,2);assert.equal(motion.moving,true);
 motion=worldCompanionMotion(motion,{x:20,y:10},1);
 assert.equal(motion.direction,2);assert.equal(motion.moving,false);
 for(const [point,direction]of [[{x:10,y:10},1],[{x:10,y:0},3],[{x:10,y:10},0]]){
  motion=worldCompanionMotion(motion,point,2);assert.equal(motion.direction,direction);
 }
});

test('initial companion position joins the travelled path instead of snapping onto the protagonist',()=>{
 const state={actor:{x:100,y:100,history:[{x:100,y:100}]},navigation:{geometry:{segment:(a,b)=>b.x<=160&&b.y===106}}};
 worldPrimeCompanionTrail({actorSize:65},state);
 assert.equal(state.actor.history.length,2);assert.ok(state.actor.history[0].x>100);
 assert.deepEqual(state.actor.history[1],{x:100,y:100});
 worldPrimeCompanionTrail({actorSize:65},state);assert.equal(state.actor.history.length,2);
 const blocked={actor:{x:100,y:100,history:[{x:100,y:100}]},navigation:{geometry:{segment:()=>false}}};
 worldPrimeCompanionTrail({actorSize:65},blocked);assert.equal(blocked.actor.history.length,1);
});

test('each demo sheet has four authored directions, stable anchors, held idle and two locomotion frames',async()=>{
 const config=artConfig(),pack=config.courtyard.world.companions,renderer=createWorldCompanions(pack),serve=createAssetHandler();
 for(const id of ['rabbito','carcara','mata-verde','azulao','raio-de-sol','nozinho','nevagume'])assert.ok(pack.species[id],id);
 for(const [id,a]of Object.entries(pack.species)){
  const model={soul:id,color:0},image={id},images=new Map([['world-companion-'+id,image]]),calls=[];
  const g={save(){},restore(){},drawImage(...args){calls.push(args);}};
  const png=fs.readFileSync('assets/'+a.image),w=png.readUInt32BE(16),h=png.readUInt32BE(20);
  assert.equal(a.frames.length,8);
  for(let d=0;d<4;d++){
   assert.equal(a.animations.idle[d].length,1);assert.equal(a.animations.move[d].length,2);
   assert.notEqual(renderer.frame(model,d,true,0).index,renderer.frame(model,d,true,a.frameMs).index);
   assert.equal(renderer.frame(model,d,false,0).index,renderer.frame(model,d,false,10000).index);
   for(const time of [0,a.frameMs]){
    const {frame:f}=renderer.frame(model,d,true,time),scale=52*a.scale/a.referenceHeight;
    assert.ok(f.x>=0&&f.y>=0&&f.x+f.w<=w&&f.y+f.h<=h);
    assert.equal(renderer.draw(g,images,model,180,240,52,{direction:d,moving:true,time}),true);
    const [,sx,sy,sw,sh,dx,dy]=calls.at(-1);
    assert.deepEqual([sx,sy,sw,sh],[f.x,f.y,f.w,f.h]);
    assert.ok(Math.abs(dx+f.footAnchor.x*scale-180)<1e-8);
    assert.ok(Math.abs(dy+f.footAnchor.y*scale-240)<1e-8);
   }
  }
  const url=config.courtyard.images['world-companion-'+id].url;
  const response=await serve(new Request('https://test/'+url,{method:'HEAD'}));assert.equal(response.status,200);assert.match(response.headers.get('cache-control'),/immutable/);
  assert.deepEqual(fs.readFileSync('docs/assets/'+a.image),png);
  assert.equal(renderer.draw(g,new Map(),model,0,0,50),false,'missing image permits legacy fallback');
 }
 for(let color=0;color<4;color++)assert.equal(renderer.get({color}).id,pack.basics[color]);
 assert.equal(renderer.get({soul:'not-in-pack',color:0}),null,'unknown species must not become Carcará');
 assert.equal(renderer.get(),null);
});
