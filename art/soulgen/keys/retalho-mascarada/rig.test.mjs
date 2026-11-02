import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import crypto from 'node:crypto';
import {validate,sample} from '../../../../tools/soulgen-studio/model.mjs';
import {anatomyReport} from '../../../../tools/soulgen-studio/workflow.mjs';
const dir=new URL('./cutout-rig-v1/',import.meta.url);
const read=name=>JSON.parse(fs.readFileSync(new URL(name,dir)));
test('Masked Retalho keeps seven complete parts, four full heads and six actions',()=>{
 const p=read('retalho-mascarada.soulgen.json');assert.deepEqual(validate(p),{ok:true,errors:[],warnings:[]});assert.deepEqual(anatomyReport(p).warnings,[]);
 assert.equal(p.parts.length,7);assert.equal(Object.keys(p.clips).length,6);assert.equal(p.creatureId,'retalho-mascarada');assert(p.parts.some(x=>x.id==='tail'));
 for(const [id,a]of Object.entries(p.assets)){const bytes=fs.readFileSync(new URL(a.src.split('/').at(-1),dir));assert.equal(bytes.readUInt32BE(16),a.width,id);assert.equal(bytes.readUInt32BE(20),a.height,id);}
 const head=p.parts.find(x=>x.id==='head');assert.equal(Object.keys(head.faces).length,3);
 for(const face of Object.values(head.faces))assert.deepEqual(face.source,head.source,'expressions must replace the complete head, not just the mouth');
 for(const face of Object.values(read('registration.json').expressions)){assert(face.complete_head);assert(face.canvas_identical);assert(face.opaque_ratio>.75);}
 for(const id of ['idle','flight'])assert.deepEqual(sample(p,id,0).values,sample(p,id,p.clips[id].seconds).values);
 for(const [id,time,face]of [['skill',.72,'fierce'],['hurt',.2,'hurt'],['victory',.8,'happy']])assert.equal(sample(p,id,time).face,face);
 assert.equal(sample(p,'defeat',9).done,true);assert.equal(read('validation.json').atlas.borderPixels,0);
});
test('Approved masked Retalho preserves author geometry, pivots, clips and PNG bytes',()=>{
 const raw=fs.readFileSync(new URL('author-approved.portable.soulgen.json',dir));
 const author=JSON.parse(raw),p=read('retalho-mascarada.soulgen.json');
 assert.equal(crypto.createHash('sha256').update(raw).digest('hex'),read('author-import.json').sha256);
 assert.equal(p.rigRevision,2);assert.deepEqual(p.parts,author.parts);assert.deepEqual(p.clips,author.clips);
 for(const [id,a]of Object.entries(author.assets))assert.deepEqual(fs.readFileSync(new URL(p.assets[id].src.split('/').at(-1),dir)),Buffer.from(a.src.split(',')[1],'base64'));
});
