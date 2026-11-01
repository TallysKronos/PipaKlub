import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import http from 'node:http';
import {decodePNG} from '../pixelgen/png.mjs';
import {validate,sample,matrices,point,exportPlan} from './model.mjs';
import {anatomyReport} from './workflow.mjs';
import {serve} from './server.mjs';
import {createDoberman} from './doberman-c.mjs';
const folder=new URL('../../art/soulgen/keys/doberman-c/sliced-rig-v2/',import.meta.url);
const project=JSON.parse(fs.readFileSync(new URL('doberman-c.soulgen.json',folder)));
test('slices retain every visible source RGBA exactly once and preserve the neutral geometry',()=>{
 const source=decodePNG(fs.readFileSync(new URL('source.png',folder))),rebuilt=new Uint8ClampedArray(source.data.length),owners=new Uint8Array(source.width*source.height);
 const slices=JSON.parse(fs.readFileSync(new URL('slices.json',folder)));
 for(const [id,p]of Object.entries(slices.parts)){
  const im=decodePNG(fs.readFileSync(new URL(id+'.png',folder))),[x,y,w,h]=p.crop;
  assert.deepEqual([im.width,im.height],[w,h]);
  assert.deepEqual(project.parts.find(q=>q.id===id).rect,[x*.25,y*.25,w*.25,h*.25]);
  for(let py=0;py<h;py++)for(let px=0;px<w;px++){const i=(py*w+px)*4;if(!im.data[i+3])continue;const at=(y+py)*source.width+x+px;owners[at]++;rebuilt.set(im.data.subarray(i,i+4),at*4);}
 }
 let count=0;for(let i=0;i<owners.length;i++)if(source.data[i*4+3]){assert.equal(owners[i],1);assert.deepEqual(rebuilt.subarray(i*4,i*4+4),source.data.subarray(i*4,i*4+4));count++;}
 assert.equal(count,381302);assert.equal(slices.reconstruction.changedVisiblePixels,0);
});
test('portable Soulgen project has eight exact cuts, six actions, stable sockets and closed cycles',()=>{
 assert.deepEqual(validate(project),{ok:true,errors:[],warnings:[]});assert.deepEqual(anatomyReport(project).warnings,[]);assert.equal(project.parts.length,8);
 const portable=JSON.parse(fs.readFileSync(new URL('doberman-c.portable.soulgen.json',folder)));assert.deepEqual(portable.parts,project.parts);assert.deepEqual(portable.clips,project.clips);assert.ok(Object.values(portable.assets).every(a=>a.src.startsWith('data:image/png;base64,')));
 for(const [id,clip]of Object.entries(project.clips))for(let i=0;i<=120;i++){const m=matrices(project,sample(project,id,clip.seconds*i/120));for(const p of project.parts.filter(p=>p.parent)){const a=point(m[p.id],...p.pivot),b=point(m.body,...p.pivot);assert.ok(Math.hypot(a.x-b.x,a.y-b.y)<1e-6);}}
 assert.equal(exportPlan(project).frames.length,109);
 const game=JSON.parse(fs.readFileSync(new URL('../../godot/assets/campaign/content.json',import.meta.url))).combat['doberman-c'];assert.ok(game.source.endsWith('sliced-rig-v2/doberman-c.soulgen.json'));
 for(const action of ['idle','flight','attack','hurt','victory','defeat']){assert.ok(game.animations[action].length>1);assert.equal(game.playback[action].fps,12);}
});
test('Soulgen serves the exact-source preset and isolates its autosave',async()=>{
 const server=http.createServer(serve);await new Promise(r=>server.listen(0,'127.0.0.1',r));const base='http://127.0.0.1:'+server.address().port,original=globalThis.fetch;globalThis.fetch=(u,o)=>original(new URL(u,base),o);
 try{assert.deepEqual(await createDoberman(),project);assert.equal((await fetch('/doberman-c.mjs')).status,200);assert.match(await(await fetch('/')).text(),/id="doberman-c"/);const studio=await(await fetch('/studio.mjs')).text();assert.match(studio,/requestedPreset==='doberman-c'/);assert.match(studio,/const STORE=\['doberman-c'/);for(const a of Object.values(project.assets))assert.equal((await fetch(a.src)).status,200);assert.equal((await fetch('/../package.json')).status,404);}finally{globalThis.fetch=original;server.closeAllConnections();await new Promise(r=>server.close(r));}
});
