import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import crypto from 'node:crypto';
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

test('Retalho preserves author PNG bytes, edited pivots and animation keys',()=>{
 const raw=fs.readFileSync(new URL('author-approved.portable.soulgen.json',dir));
 const author=JSON.parse(raw),p=read('retalho-original.soulgen.json');
 assert.equal(crypto.createHash('sha256').update(raw).digest('hex'),read('author-import.json').sha256);
 assert.equal(p.artRevision,2);assert.equal(p.rigRevision,2);
 assert.deepEqual(p.parts,author.parts);assert.deepEqual(p.clips,author.clips);
 for(const [id,a]of Object.entries(author.assets)){
  const png=fs.readFileSync(new URL(p.assets[id].src.split('/').at(-1),dir));
  assert.deepEqual(png,Buffer.from(a.src.split(',')[1],'base64'));
 }
});
