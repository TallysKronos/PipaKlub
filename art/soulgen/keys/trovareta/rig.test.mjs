import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {validate,sample,identity,exportPlan} from '../../../../tools/soulgen-studio/model.mjs';
import {anatomyReport} from '../../../../tools/soulgen-studio/workflow.mjs';
const folder=new URL('./cutout-rig-v1/',import.meta.url);
const project=JSON.parse(fs.readFileSync(new URL('trovareta.soulgen.json',folder)));
test('Trovareta has eight complete independent parts, valid sources and stable joints throughout six actions',()=>{
 assert.deepEqual(validate(project),{ok:true,errors:[],warnings:[]});
 assert.equal(project.parts.length,8);
 assert.deepEqual(anatomyReport(project).warnings,[]);
 assert.deepEqual(Object.keys(project.clips),['idle','flight','skill','hurt','victory','defeat']);
 for(const [id,a]of Object.entries(project.assets)){
  const bytes=fs.readFileSync(new URL(a.src.split('/').at(-1),folder));
  assert.equal(bytes.readUInt32BE(16),a.width,id);assert.equal(bytes.readUInt32BE(20),a.height,id);
 }
 for(const id of ['tailNear','tailFar']){
  const part=project.parts.find(p=>p.id===id);assert.equal(part.parent,'body');assert.equal(part.asset,id);
 }
});
test('Trovareta loops close; one-shots recover; expressions are timed and defeat holds',()=>{
 for(const id of ['idle','flight']){
  const c=project.clips[id];assert.deepEqual(c.frames[0].values,c.frames.at(-1).values);
  const a=sample(project,id,0),b=sample(project,id,c.seconds-1e-6);
  for(const part of ['root',...project.parts.map(p=>p.id)])for(const channel of Object.keys(identity()))assert.ok(Math.abs(a.values[part][channel]-b.values[part][channel])<.001,id+'/'+part+'/'+channel);
 }
 for(const [id,face,t]of [['skill','fierce',.65],['hurt','hurt',.12],['victory','happy',.8]]){
  const c=project.clips[id];assert.equal(sample(project,id,t).face,face);
  assert.equal(sample(project,id,c.seconds).face,'normal');
  for(const values of Object.values(c.frames.at(-1).values))assert.deepEqual(values,identity());
 }
 assert.equal(sample(project,'defeat',2).done,true);
 assert.equal(project.clips.skill.hitTime,.65);
 const plan=exportPlan(project);assert.equal(plan.frames.length,123);
});
