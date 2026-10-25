import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import http from 'node:http';
import {validate,sample,matrices,point,identity,exportPlan} from './model.mjs';
import {anatomyReport} from './workflow.mjs';
import {createTatutrama} from './tatutrama.mjs';
import {serve} from './server.mjs';
const folder=new URL('../../art/soulgen/keys/tatutrama/color-rig-v2/',import.meta.url);
const project=JSON.parse(fs.readFileSync(new URL('tatutrama.soulgen.json',folder)));

test('Tatutrama rig keeps its own articulated anatomy, source sizes and portable project',()=>{
 assert.deepEqual(validate(project),{ok:true,errors:[],warnings:[]});
 assert.deepEqual(anatomyReport(project).warnings,[]);
 assert.equal(project.parts.length,7);assert.equal(new Set(project.parts.map(p=>p.z)).size,7);assert.equal(project.parts.some(p=>p.id==='sail'),false);
 assert.equal(project.parts.find(p=>p.id==='frontNear').z<project.parts.find(p=>p.id==='body').z,true);
 for(const a of Object.values(project.assets)){
  const bytes=fs.readFileSync(new URL(a.src.slice(a.src.lastIndexOf('/')+1),folder));
  assert.equal(bytes.readUInt32BE(16),a.width);assert.equal(bytes.readUInt32BE(20),a.height);
 }
 const portable=JSON.parse(fs.readFileSync(new URL('tatutrama.portable.soulgen.json',folder)));
 assert.equal(validate(portable).ok,true);assert.deepEqual(portable.parts,project.parts);assert.deepEqual(portable.clips,project.clips);
 assert.ok(Object.values(portable.assets).every(a=>a.src.startsWith('data:image/png;base64,')));
 const registration=JSON.parse(fs.readFileSync(new URL('registration.json',folder)));
 for(const face of Object.values(registration.expressions)){assert.equal(face.alpha_identical,true);assert.equal(face.outside_face_identical,true);assert.ok(face.changed_pixels>100);}
});

test('Tatutrama loops close, joints stay attached, expressions settle and atlas has all actions',()=>{
 for(const [id,c]of Object.entries(project.clips)){
  for(let i=0;i<=120;i++){
   const pose=sample(project,id,c.seconds*i/120),m=matrices(project,pose);
   for(const p of project.parts){
    const [x,y,w,h]=p.rect;
    for(const corner of [[x,y],[x+w,y],[x,y+h],[x+w,y+h]]){
     const q=point(m[p.id],...corner);assert.ok(q.x>=0&&q.y>=0&&q.x<=project.width&&q.y<=project.height,`${id}/${p.id} clips`);
    }
   }
   for(const joint of project.anatomy.joints){
    const child=project.parts.find(p=>p.id===joint.part),parent=project.parts.find(p=>p.id===joint.parent);
    const a=point(m[child.id],child.rect[0]+joint.anchor[0]*child.rect[2],child.rect[1]+joint.anchor[1]*child.rect[3]);
    const b=point(m[parent.id],parent.rect[0]+joint.socket[0]*parent.rect[2],parent.rect[1]+joint.socket[1]*parent.rect[3]);
    assert.ok(Math.hypot(a.x-b.x,a.y-b.y)<1e-7,`${id}/${child.id} detaches`);
   }
  }
  if(c.loop){const a=sample(project,id,0),b=sample(project,id,c.seconds-1e-7);for(const p of Object.keys(a.values))for(const key of Object.keys(identity()))assert.ok(Math.abs(a.values[p][key]-b.values[p][key])<.0001);}
  else {const end=sample(project,id,c.seconds);assert.equal(end.face,'normal');for(const v of Object.values(end.values))assert.deepEqual(v,identity());}
 }
 assert.equal(sample(project,'skill',project.clips.skill.hitTime).face,'fierce');
 assert.equal(sample(project,'hurt',.2).face,'hurt');assert.equal(sample(project,'victory',1).face,'happy');
 const plan=exportPlan(project);assert.equal(plan.frames.length,116);assert.deepEqual(Object.keys(plan.animations),['idle','flight','skill','hurt','victory']);
});

test('Soulgen serves and loads the Tatutrama preset and every source without broader file access',async()=>{
 const server=http.createServer(serve);await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 const base='http://127.0.0.1:'+server.address().port,original=globalThis.fetch;
 globalThis.fetch=(input,options)=>original(new URL(input,base),options);
 try {
  const loaded=await createTatutrama();assert.deepEqual(loaded,project);
  assert.equal((await fetch('/tatutrama.mjs')).status,200);
  assert.match(await (await fetch('/')).text(),/id="tatutrama"/);
  const studio=await (await fetch('/studio.mjs')).text();assert.match(studio,/requestedPreset==='tatutrama'/);assert.match(studio,/'lacertubo-v2','nozinho','guaravento','micofolha','capimansa','tatutrama'/);
  for(const a of Object.values(loaded.assets))assert.equal((await fetch(a.src)).status,200);
  assert.equal((await fetch('/art/soulgen/keys/tatutrama/prepare.py')).status,404);
 }finally{globalThis.fetch=original;server.closeAllConnections();await new Promise(resolve=>server.close(resolve));}
});

 test('Tatutrama preserves approved placement and individual horizontal flip',()=>{const edits=JSON.parse(fs.readFileSync(new URL('../../art/soulgen/keys/tatutrama/author-adjustments.json',import.meta.url)));assert.equal(project.rigRevision,2);for(const [id,values]of Object.entries(edits.parts))for(const [key,value]of Object.entries(values))assert.deepEqual(project.parts.find(p=>p.id===id)[key],value);assert.equal(project.parts.find(p=>p.id==='hindNear').artTransform.flipX,true);});
