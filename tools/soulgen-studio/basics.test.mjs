import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {validate,sample,matrices,point,identity,exportPlan} from './model.mjs';
import {anatomyReport} from './workflow.mjs';
for(const revision of ['v1','v2']){
const folder=revision==='v1'?'color-rig':'color-rig-v2';
const registry=JSON.parse(fs.readFileSync(new URL(`../../art/soulgen/keys/basic-color-${revision}/registry.json`,import.meta.url)));
for(const [id,{project:p}]of Object.entries(registry)){
 test(revision+'/'+id+': stable loops, attached hierarchy, finite motion and settled actions',()=>{
  assert.deepEqual(validate(p),{ok:true,errors:[],warnings:[]});
  assert.deepEqual(anatomyReport(p).warnings,[]);
  const portable=JSON.parse(fs.readFileSync(new URL(`../../art/soulgen/keys/${id}/${folder}/${id}.portable.soulgen.json`,import.meta.url)));
  assert.equal(validate(portable).ok,true);assert.ok(Object.values(portable.assets).every(a=>a.src.startsWith('data:image/png;base64,')));
  assert.equal(Object.keys(p.clips).length,5);
  const reg=JSON.parse(fs.readFileSync(new URL(`../../art/soulgen/keys/${id}/${folder}/registration.json`,import.meta.url)));
  for(const face of Object.values(reg.expressions)){assert.equal(face.alpha_identical,true);assert.equal(face.outside_face_identical,true);assert.ok(face.changed_pixels>100);}
  if(revision==='v2')for(const face of Object.values(reg.expressions))assert.equal(face.beak_or_nose_identical,true);
  for(const [clip,c]of Object.entries(p.clips)){
   for(let i=0;i<=120;i++){
    const pose=sample(p,clip,c.seconds*i/120),m=matrices(p,pose);
    for(const part of p.parts){const [x,y,w,h]=part.rect;for(const xy of [[x,y],[x+w,y],[x,y+h],[x+w,y+h]]){const q=point(m[part.id],...xy);assert.ok(Number.isFinite(q.x)&&Number.isFinite(q.y));assert.ok(q.x>=-2&&q.x<=p.width+2&&q.y>=-2&&q.y<=p.height+2,`${clip}/${part.id} clipped: ${q.x},${q.y}`);}}
   }
   if(c.loop){const a=sample(p,clip,0),b=sample(p,clip,c.seconds-1e-7);for(const part of Object.keys(a.values))for(const channel of Object.keys(identity()))assert.ok(Math.abs(a.values[part][channel]-b.values[part][channel])<.0001);}
   else{const pose=sample(p,clip,c.seconds);assert.equal(pose.face,'normal');for(const v of Object.values(pose.values))assert.deepEqual(v,identity());}
  }
  assert.equal(sample(p,'skill',p.clips.skill.hitTime).face,'fierce');assert.equal(sample(p,'hurt',.2).face,'hurt');assert.equal(sample(p,'victory',1).face,'happy');
  assert.ok(exportPlan(p).frames.length>100);
  if(id==='rabbito'){for(const part of ['earNear','earFar'])assert.equal(p.parts.find(p=>p.id===part).parent,'head');}
  if(revision==='v2'&&id==='rabbito'){
   const manual=JSON.parse(fs.readFileSync(new URL('../../art/soulgen/keys/rabbito/color-rig-v2/user-hierarchy.json',import.meta.url)));
   const original=JSON.parse(fs.readFileSync(new URL('../../art/soulgen/keys/rabbito/color-rig-v2/user-hierarchy-original.soulgen.json',import.meta.url)));
   assert.deepEqual(p.clips,original.clips);assert.equal(p.rigRevision,1);
   for(const edited of manual.parts){const part=p.parts.find(x=>x.id===edited.id);assert.equal(part.z,edited.z);assert.equal(part.parent,edited.parent);assert.deepEqual(part.rect,[edited.rect[0],edited.rect[1]+12,...edited.rect.slice(2)]);assert.deepEqual(part.pivot,[edited.pivot[0],edited.pivot[1]+12]);}
   assert.ok(p.parts.find(x=>x.id==='head').z<p.parts.find(x=>x.id==='body').z);
  }
 });
}

}
