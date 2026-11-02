import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {validate,sample} from '../../../../tools/soulgen-studio/model.mjs';
const dir=new URL('./cutout-rig-v2/',import.meta.url);
const read=name=>JSON.parse(fs.readFileSync(new URL(name,dir)));
test('Retalho original keeps seven isolated parts, four faces and six actions',()=>{
 const p=read('retalho-original.soulgen.json');assert.equal(validate(p).ok,true);
 assert.equal(p.parts.length,7);assert.equal(Object.keys(p.clips).length,6);
 assert.equal(Object.keys(p.parts.find(x=>x.id==='head').faces).length,3);
 assert(p.parts.some(x=>x.id==='tail'));assert.equal(p.creatureId,'retalho-original');
 for(const id of ['idle','flight'])assert.deepEqual(sample(p,id,0).values,sample(p,id,p.clips[id].seconds).values);
 assert.equal(sample(p,'skill',.72).face,'fierce');assert.equal(sample(p,'hurt',.2).face,'hurt');assert.equal(sample(p,'victory',.8).face,'happy');
 const report=read('validation.json');assert.equal(report.atlas.borderPixels,0);
 for(const face of Object.values(read('registration.json').expressions)){assert(face.complete_head);assert(face.canvas_identical);assert(face.opaque_ratio>.75);}
});
