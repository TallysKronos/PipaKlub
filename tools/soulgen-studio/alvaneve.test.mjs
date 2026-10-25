import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import http from 'node:http';
import {validate,sample,matrices,point,identity,exportPlan} from './model.mjs';
import {anatomyReport} from './workflow.mjs';
import {createAlvaneve} from './alvaneve.mjs';
import {serve} from './server.mjs';
const folder=new URL('../../art/soulgen/keys/alvaneve/color-rig-v2/',import.meta.url);
const project=JSON.parse(fs.readFileSync(new URL('alvaneve.soulgen.json',folder)));

test('Alvaneve rig keeps its own articulated anatomy, source sizes and portable project',()=>{
 assert.deepEqual(validate(project),{ok:true,errors:[],warnings:[]});
 assert.deepEqual(anatomyReport(project).warnings,[]);
 assert.equal(project.parts.length,9);
 assert.equal(project.parts.find(p=>p.id==='hindFar').z<project.parts.find(p=>p.id==='body').z,true);
 for(const a of Object.values(project.assets)){
  const bytes=fs.readFileSync(new URL(a.src.slice(a.src.lastIndexOf('/')+1),folder));
  assert.equal(bytes.readUInt32BE(16),a.width);assert.equal(bytes.readUInt32BE(20),a.height);
 }
 const portable=JSON.parse(fs.readFileSync(new URL('alvaneve.portable.soulgen.json',folder)));
 assert.equal(validate(portable).ok,true);assert.deepEqual(portable.parts,project.parts);assert.deepEqual(portable.clips,project.clips);
 assert.ok(Object.values(portable.assets).every(a=>a.src.startsWith('data:image/png;base64,')));
 const registration=JSON.parse(fs.readFileSync(new URL('registration.json',folder)));
 for(const face of Object.values(registration.expressions)){assert.equal(face.alpha_identical,true);assert.equal(face.outside_face_identical,true);assert.ok(face.changed_pixels>100);}
});

test('Alvaneve loops close, joints stay attached, expressions settle and atlas has all actions',()=>{
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

test('Soulgen serves and loads the Alvaneve preset and every source without broader file access',async()=>{
 const server=http.createServer(serve);await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 const base='http://127.0.0.1:'+server.address().port,original=globalThis.fetch;
 globalThis.fetch=(input,options)=>original(new URL(input,base),options);
 try {
  const loaded=await createAlvaneve();assert.deepEqual(loaded,project);
  assert.equal((await fetch('/alvaneve.mjs')).status,200);
  assert.match(await (await fetch('/')).text(),/id="alvaneve"/);
  const studio=await (await fetch('/studio.mjs')).text();assert.match(studio,/requestedPreset==='alvaneve'/);assert.match(studio,/'lacertubo-v2','nozinho','guaravento','micofolha','capimansa','tatutrama','flautrevo','trinca-brasas','alvaneve'/);
  for(const a of Object.values(loaded.assets))assert.equal((await fetch(a.src)).status,200);
  assert.equal((await fetch('/art/soulgen/keys/alvaneve/prepare.py')).status,404);
 }finally{globalThis.fetch=original;server.closeAllConnections();await new Promise(resolve=>server.close(resolve));}
});

 test('all Alvaneve parts preserve the exact source aspect ratio',()=>{assert.equal(project.preserveSourceAspect,true);for(const p of project.parts)assert.ok(Math.abs(p.rect[2]/p.rect[3]-p.source[2]/p.source[3])<1e-8,p.id+' is stretched');});


test('authored hands and upper body stay intact, new thighs preserve aspect and duplicate hand is animated',()=>{
 const authored=JSON.parse(fs.readFileSync(new URL('../../art/soulgen/keys/alvaneve/author-layout.json',import.meta.url)));
 for(const id of ['body','head','wingNear','wingFar','tail','frontNear','frontNear-copy']){const a=authored.parts.find(p=>p.id===id),p=project.parts.find(p=>p.id===id);for(const key of ['rect','pivot','artTransform'])assert.deepEqual(p[key],a[key]);}
 assert.equal(project.parts.find(p=>p.id==='hindNear').asset,'thighNear');assert.equal(project.parts.find(p=>p.id==='hindFar').asset,'thighFar');
 for(const c of Object.values(project.clips))for(const f of c.frames){assert.ok(f.values['frontNear-copy']);assert.ok(Math.abs(f.values['frontNear-copy'].rotation+f.values.frontNear.rotation)<1e-8);}
 assert.ok(Math.abs(sample(project,'flight',.3).values['frontNear-copy'].rotation)>5);
});

 test('final approved Alvaneve layout and clips survive regeneration exactly',()=>{const approved=JSON.parse(fs.readFileSync(new URL('../../art/soulgen/keys/alvaneve/approved-layout.json',import.meta.url)));assert.deepEqual(project.parts,approved.parts);assert.deepEqual(project.clips,approved.clips);assert.deepEqual(project.rootPivot,approved.rootPivot);assert.equal(project.rigRevision,3);});
