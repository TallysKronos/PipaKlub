import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {createWorldActors} from './src/world-actors.js';
import {artConfig} from './scripts/art-build.mjs';
import {createAssetHandler} from './src/static-assets.js';

const config=artConfig(),actors=config.courtyard.world.actors;
test('all overworld character images have valid measured cells and are served and packaged with hashed URLs',async()=>{
 assert.deepEqual(Object.values(actors.characters).map(a=>a.name),['Sr. Assis','Zeca','Bia','Juninho','Lia','Tião','Nina','Mãe']);
 const serve=createAssetHandler();
 for(const [id,a]of Object.entries(actors.characters)){
  const png=fs.readFileSync('assets/'+a.image),w=png.readUInt32BE(16),h=png.readUInt32BE(20);
  assert.equal(a.frames.length,8);assert.ok(a.referenceHeight>0);
  for(const f of a.frames){assert.ok(f.x>=0&&f.y>=0&&f.x+f.w<=w&&f.y+f.h<=h);assert.ok(f.footAnchor.x>=0&&f.footAnchor.x<=f.w&&f.footAnchor.y<=f.h);}
  const image=config.courtyard.images['world-npc-'+id];assert.equal(image.image,a.image);
  const r=await serve(new Request('https://test/'+image.url,{method:'HEAD'}));assert.equal(r.status,200);assert.match(r.headers.get('cache-control'),/immutable/);
  assert.deepEqual(fs.readFileSync('docs/assets/'+a.image),png);
 }
 assert.equal((await serve(new Request('https://test/assets/characters/overworld-v1/manifest.json'))).status,404);
});
test('NPC directions and two-pose motion preserve fixed scale and place the feet at the world anchor',()=>{
 const renderer=createWorldActors(actors),calls=[];
 const g={save(){},restore(){},drawImage(...args){calls.push(args);}},images=new Map();
 for(const [id,a]of Object.entries(actors.characters)){
  const image={id};images.set('world-npc-'+id,image);
  for(let d=0;d<4;d++)for(const t of [0,170]){
   const selected=renderer.frame(a.name,d,true,t),f=selected.frame,scale=72/a.referenceHeight;
   assert.equal(selected.index,d+(t?4:0));
   assert.equal(renderer.draw(g,images,a.name,180,240,72,{direction:d,moving:true,time:t}),true);
   const [img,sx,sy,sw,sh,dx,dy,dw,dh]=calls.at(-1);
   assert.equal(img,image);assert.deepEqual([sx,sy,sw,sh],[f.x,f.y,f.w,f.h]);
   assert.equal(dw,sw*scale);assert.equal(dh,sh*scale);
   assert.ok(Math.abs(dx+f.footAnchor.x*scale-180)<1e-8);
   assert.ok(Math.abs(dy+f.footAnchor.y*scale-240)<1e-8);
  }
  assert.equal(renderer.frame(a.name,2,false,170).index,2);
 }
 assert.equal(renderer.draw(g,new Map(),'Sr. Assis',0,0,72),false);
 assert.equal(renderer.draw(g,images,'NPC desconhecido',0,0,72),false);
 assert.equal(renderer.facing(0,0,{x:-20,y:1}),1);assert.equal(renderer.facing(0,0,{x:20,y:1}),2);
 assert.equal(renderer.facing(0,0,{x:1,y:-20}),3);assert.equal(renderer.facing(0,0,{x:1,y:20}),0);
});
