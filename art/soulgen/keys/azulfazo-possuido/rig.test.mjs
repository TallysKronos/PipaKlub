import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {validate,sample} from '../../../../tools/soulgen-studio/model.mjs';
import {anatomyReport} from '../../../../tools/soulgen-studio/workflow.mjs';
const dir=new URL('./cutout-rig-v1/',import.meta.url);
const read=name=>JSON.parse(fs.readFileSync(new URL(name,dir)));
test('Azulfazo has articulated wings, legs, full tail and registered complete heads in six actions',()=>{
 const p=read('azulfazo-possuido.soulgen.json');assert.deepEqual(validate(p),{ok:true,errors:[],warnings:[]});assert.deepEqual(anatomyReport(p).warnings,[]);
 assert.equal(p.parts.length,7);assert.equal(Object.keys(p.clips).length,6);
 for(const id of ['wingLeft','wingRight','legLeft','legRight','tail'])assert(p.parts.some(x=>x.id===id));
 for(const [id,a]of Object.entries(p.assets)){const bytes=fs.readFileSync(new URL(a.src.split('/').at(-1),dir));assert.equal(bytes.readUInt32BE(16),a.width,id);assert.equal(bytes.readUInt32BE(20),a.height,id);}
 const head=p.parts.find(x=>x.id==='head');assert.equal(Object.keys(head.faces).length,3);for(const face of Object.values(head.faces))assert.deepEqual(face.source,head.source);
 for(const face of Object.values(read('registration.json').expressions)){assert(face.complete_head);assert(face.canvas_identical);assert(face.opaque_ratio>.75);}
 for(const id of ['idle','flight'])assert.deepEqual(sample(p,id,0).values,sample(p,id,p.clips[id].seconds).values);
 for(const [id,time,face]of [['skill',.72,'fierce'],['hurt',.2,'hurt'],['victory',.8,'happy']])assert.equal(sample(p,id,time).face,face);
 assert.equal(sample(p,'defeat',9).done,true);assert.equal(read('validation.json').atlas.borderPixels,0);
});
