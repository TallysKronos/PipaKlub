import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {validate} from './model.mjs';
import {anatomyReport} from './workflow.mjs';
const dir=new URL('../../art/soulgen/keys/tramadraco/cutout-rig-v1/',import.meta.url);
const p=JSON.parse(fs.readFileSync(new URL('tramadraco.soulgen.json',dir)));
test('Tramadraco separates anatomical segments and keeps sword and complete rabiola attached through all six actions',()=>{
 assert(validate(p).ok);assert.deepEqual(anatomyReport(p).warnings,[]);assert.equal(p.parts.length,13);
 const part=id=>p.parts.find(x=>x.id===id);
 for(const [child,parent]of [['foreNear','upperNear'],['foreFar','upperFar'],['shinNear','thighNear'],['shinFar','thighFar'],['sword','foreNear'],['tail','sword'],['cape','body']])assert.equal(part(child).parent,parent);
 for(const face of ['fierce','hurt','happy'])assert.deepEqual(part('head').faces[face].source,part('head').source);
 for(const a of Object.values(p.assets)){
  const bytes=fs.readFileSync(new URL(a.src.split('/').at(-1),dir));assert.equal(bytes.readUInt32BE(16),a.width);assert.equal(bytes.readUInt32BE(20),a.height);
 }
 const report=JSON.parse(fs.readFileSync(new URL('validation.json',dir)));assert.equal(report.atlas.frames,129);assert.equal(report.atlas.borderPixels,0);
 assert.equal(Object.keys(p.clips).length,6);
 for(const c of Object.values(p.clips))if(c.loop)assert.deepEqual(c.frames[0].values,c.frames.at(-1).values);
 const portable=JSON.parse(fs.readFileSync(new URL('tramadraco.portable.soulgen.json',dir)));assert(validate(portable).ok);assert(Object.values(portable.assets).every(x=>x.src.startsWith('data:image/png;base64,')));
});
