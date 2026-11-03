import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {validate,sample} from '../../../../tools/soulgen-studio/model.mjs';
import {anatomyReport} from '../../../../tools/soulgen-studio/workflow.mjs';
const dir=new URL('./cutout-rig-v1/',import.meta.url);
const read=name=>JSON.parse(fs.readFileSync(new URL(name,dir)));
test('Platyx C keeps seven complete parts, full heads and anatomical joints',()=>{
 const p=read('platyx.soulgen.json');assert.deepEqual(validate(p),{ok:true,errors:[],warnings:[]});assert.deepEqual(anatomyReport(p).warnings,[]);
 assert.equal(p.parts.length,7);assert.equal(p.creatureId,'platyx');assert.equal(Object.keys(p.clips).length,6);
 for(const id of ['body','head','armNear','armFar','footNear','footFar','tail'])assert(p.parts.some(x=>x.id===id));
 for(const [id,a]of Object.entries(p.assets)){const bytes=fs.readFileSync(new URL(a.src.split('/').at(-1),dir));assert.equal(bytes.readUInt32BE(16),a.width,id);assert.equal(bytes.readUInt32BE(20),a.height,id);}
 const head=p.parts.find(x=>x.id==='head');for(const face of Object.values(head.faces))assert.deepEqual(face.source,head.source);
 for(const face of Object.values(read('registration.json').expressions)){assert(face.complete_head);assert(face.opaque_ratio>.75);assert(face.canvas_identical);}
 for(const id of ['idle','flight'])assert.deepEqual(sample(p,id,0).values,sample(p,id,p.clips[id].seconds).values);
 for(const [id,t,face]of [['skill',.68,'fierce'],['hurt',.2,'hurt'],['victory',.8,'happy']])assert.equal(sample(p,id,t).face,face);
 assert.equal(sample(p,'defeat',9).done,true);assert.equal(read('validation.json').atlas.borderPixels,0);
});
