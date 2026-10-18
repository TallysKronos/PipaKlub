import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {artConfig} from './scripts/art-build.mjs';
import {buildWorldArtPlan} from './src/world-art.js';
import {parseWorldMap,createWorldGeometry} from './src/world-map.js';
const dir='assets/world/morro-kit-v1/',manifest=JSON.parse(fs.readFileSync(dir+'manifest.json'));
test('all 26 kit frames fit their actual PNGs and object sheets retain alpha',()=>{
 assert.equal(Object.keys(manifest.frames).length,26);
 for(const [id,s]of Object.entries(manifest.sheets)){
  const b=fs.readFileSync('assets/'+s.image);assert.equal(b.toString('ascii',1,4),'PNG');
  assert.equal(b.readUInt32BE(16),s.width);assert.equal(b.readUInt32BE(20),s.height);
  if(id!=='ground')assert.equal(b[25],6,'RGBA required: '+id);
 }
 for(const f of Object.values(manifest.frames)){const s=manifest.sheets[f.sheet];assert.ok(f.x>=0&&f.y>=0&&f.w>0&&f.h>0&&f.x+f.w<=s.width&&f.y+f.h<=s.height);}
 assert.ok(JSON.parse(fs.readFileSync(dir+'audit.json')).every(a=>!a.needsReview));
});
test('kit sheets are published with content hashes and every generation prompt is preserved',()=>{
 const c=artConfig();assert.equal(Object.keys(c.courtyard.world.kit.frames).length,26);
 for(const id of Object.keys(manifest.sheets)){const image=c.courtyard.images['world-kit-'+id];assert.equal(image.image,manifest.sheets[id].image);assert.match(image.url,/\?v=[0-9a-f]{12}$/);}
 const p=JSON.parse(fs.readFileSync(dir+'prompts.json'));assert.equal(p.prompts.length,6);assert.ok(p.prompts.every(p=>p.prompt.length>100));
});
test('all kit sheets are served by the explicit asset allowlist with HEAD and version caching',async()=>{
 const {createAssetHandler}=await import('./src/static-assets.js'),handler=createAssetHandler(),c=artConfig();
 for(const id of Object.keys(manifest.sheets)){const image=c.courtyard.images['world-kit-'+id],response=await handler(new Request('http://local/'+image.url,{method:'HEAD'}));assert.equal(response.status,200);assert.match(response.headers.get('cache-control'),/immutable/);assert.equal(response.headers.get('content-type'),'image/png');}
 assert.equal((await handler(new Request('http://local/assets/world/morro-kit-v1/prompts.json'))).status,404);
});
test('applied art preserves proportions and has no missing binding or atlas bleed',()=>{
 const scene=artConfig().courtyard.world.pilot;assert.ok(scene.art.objects.length>20);
 for(const e of scene.art.objects){const f=e.sprite,s=manifest.sheets[f.sheet];assert.ok(f.sx>=0&&f.sy>=0&&f.sx+f.sw<=s.width&&f.sy+f.sh<=s.height);assert.ok(Math.abs(f.w/f.h-f.sw/f.sh)<1e-8);assert.ok(Number.isFinite(e.y)&&Number.isInteger(e.level));}
 const raw=JSON.parse(fs.readFileSync('assets/world/morro-pilot/blockout.tmj')),layout=JSON.parse(fs.readFileSync('assets/world/morro-pilot/art.json')),parsed=parseWorldMap(raw),before=JSON.stringify(parsed);
 buildWorldArtPlan(parsed,manifest,layout);assert.equal(JSON.stringify(parsed),before);
 delete layout.bindings['5'];assert.throws(()=>buildWorldArtPlan(parsed,manifest,layout),/sem peça/);
});
test('the decorative lamp has a physical base in the walkable plaza',()=>{
 const scene=artConfig().courtyard.world.pilot,g=createWorldGeometry(scene.tiled);
 assert.equal(g.safe({x:624,y:728}),false);assert.equal(g.safe({x:580,y:728}),true);
});
