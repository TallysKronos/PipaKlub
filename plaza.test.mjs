import test from 'node:test';
import assert from 'node:assert/strict';
import {createPlazaPolicy} from './src/plaza-policy.js';
import {artConfig} from './scripts/art-build.mjs';
import {createAssetHandler} from './src/static-assets.js';
import fs from 'node:fs';

test('plaza account XP is bounded and does not use Pipamon XP',()=>{
 const p=createPlazaPolicy();assert.equal(p.profile({level:8,xp:5100,next_level_xp:6400,pipamon_xp:999999}).percent,200/1500*100);
 assert.equal(p.profile({level:1,xp:-5}).percent,0);assert.equal(p.profile({level:2,xp:5000}).percent,100);assert.equal(p.profile(null).level,1);
});
test('plaza objectives respect onboarding and use the next actual trail',()=>{
 const p=createPlazaPolicy();for(const phase of ['arrival','choose','practice'])assert.equal(p.mission(phase).action,'professor');
 assert.equal(p.mission('city').action,'city');const m=p.mission('complete',{id:'praia-2'},{name:'Trilha da Beira-Mar'});assert.equal(m.stage,'praia-2');assert.match(m.body,/Beira-Mar/);
});
test('plaza walking targets stay on the two paved paths',()=>{
 const p=createPlazaPolicy();for(let x=-100;x<1800;x+=37)for(let y=-100;y<1200;y+=37){const a=p.point(x,y);assert.ok(a.x>=600&&a.x<=825&&a.y>=460&&a.y<=1010||a.x>=235&&a.x<=1000&&a.y>=550&&a.y<=625);}
 assert.deepEqual(p.point(NaN,Infinity),{x:735,y:630});
});
test('all new hub assets are served with hashed URLs and copied to Pages, source prompts stay private',async()=>{
 const config=artConfig(),serve=createAssetHandler();assert.equal(config.courtyard.plaza.actor.frames.length,8);
 for(const file of config.courtyard.plaza.files){const key='plaza-'+file.replace('.png',''),asset=config.courtyard.images[key],response=await serve(new Request('https://test/'+asset.url,{method:'HEAD'}));assert.equal(response.status,200,file);assert.match(response.headers.get('cache-control'),/immutable/);assert.ok(fs.existsSync('docs/assets/'+asset.image),file);}
 for(const file of ['prompts.json','sources/icons.png','manifest.json'])assert.equal((await serve(new Request('https://test/assets/hub/praca-v1/'+file))).status,404);
});
