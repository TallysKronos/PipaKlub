import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {decodePNG} from '../../../../tools/pixelgen/png.mjs';
import {validate,sample,identity,exportPlan} from '../../../../tools/soulgen-studio/model.mjs';
import {anatomyReport} from '../../../../tools/soulgen-studio/workflow.mjs';
const folder=new URL('./cutout-rig-v1/',import.meta.url);
const project=JSON.parse(fs.readFileSync(new URL('glacerol.soulgen.json',folder)));
test('Glacerol sources, nine separate parts and anatomical anchors are valid throughout all actions',()=>{
 assert.deepEqual(validate(project),{ok:true,errors:[],warnings:[]});
 assert.deepEqual(anatomyReport(project).warnings,[]);
 for(const id of ['threadNear','threadFar'])assert.equal(project.parts.find(p=>p.id===id).parent,'head');
 assert.deepEqual(project.parts.map(p=>p.id),['body','head','frontNear','frontFar','hindNear','hindFar','tail','threadNear','threadFar']);
 for(const [id,a]of Object.entries(project.assets)){
  const png=decodePNG(fs.readFileSync(new URL(a.src.split('/').at(-1),folder)));
  assert.equal(png.width,a.width,id);assert.equal(png.height,a.height,id);
 }
});
test('Glacerol eye expressions retain exact canonical alpha and every pixel outside registered windows',()=>{
 const head=project.parts.find(p=>p.id==='head'),base=decodePNG(fs.readFileSync(new URL('head.png',folder)));
 for(const face of ['fierce','hurt','happy']){
  const png=decodePNG(fs.readFileSync(new URL('head-'+face+'.png',folder)));let changed=0;
  for(let y=0;y<base.height;y++)for(let x=0;x<base.width;x++){
   const i=(y*base.width+x)*4;assert.equal(png.data[i+3],base.data[i+3],face+' alpha');
   const inside=head.faceWindows.some(([wx,wy,w,h])=>x>=wx&&x<wx+w&&y>=wy&&y<wy+h);
   for(let c=0;c<3;c++)if(inside){changed+=png.data[i+c]!==base.data[i+c];}else assert.equal(png.data[i+c],base.data[i+c],face+' outside');
  }
  assert.ok(changed>0,face+' must actually change');
 }
});
test('Glacerol loops close smoothly, one-shot poses recover, expressions and impact are timed',()=>{
 for(const id of ['idle','flight']){
  const c=project.clips[id];assert.deepEqual(c.frames[0].values,c.frames.at(-1).values);
  const a=sample(project,id,0),b=sample(project,id,c.seconds-1e-6);
  for(const part of ['root',...project.parts.map(p=>p.id)])for(const channel of Object.keys(identity()))assert.ok(Math.abs(a.values[part][channel]-b.values[part][channel])<.001,id+'/'+part+'/'+channel);
 }
 for(const [id,face,t]of [['skill','fierce',.62],['hurt','hurt',.12],['victory','happy',.8]]){
  const c=project.clips[id];assert.equal(sample(project,id,t).face,face);assert.equal(sample(project,id,c.seconds).face,'normal');
  for(const values of Object.values(c.frames.at(-1).values))assert.deepEqual(values,identity());
 }
 assert.equal(sample(project,'defeat',2).done,true);assert.equal(project.clips.skill.hitTime,.62);
 assert.equal(exportPlan(project).frames.length,126);
});
