import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import {createMountedRigService} from './mounted-rig-service.mjs';
import {matrices,sample,point,validate} from './model.mjs';
const target='godot/assets/mounts/kael-mounted-rig-v1/project.json';
const source=new URL('../../'+target,import.meta.url);
test('rig has independent pivots and shoulder motion carries its hand, preserving hip and head',async()=>{
 const p=JSON.parse(await fs.readFile(source));assert.equal(validate(p).ok,true);assert.equal(p.parts.length,15);
 const rest=sample(p,'idle',0),r=matrices(p,rest),pose=structuredClone(rest);pose.values['upper-near'].rotation=12;
 const m=matrices(p,pose),hand=p.parts.find(x=>x.id==='hand-near');
 assert.notDeepEqual(point(m[hand.id],...hand.pivot),point(r[hand.id],...hand.pivot));
 assert.deepEqual(m.pelvis,r.pelvis);assert.deepEqual(m.head,r.head);
});
test('fixed destination, image validation, backup and stale/concurrent saves protect authoring work',async()=>{
 const root=await fs.mkdtemp(path.join(os.tmpdir(),'soulgen-mounted-'));
 try{
  await fs.mkdir(path.dirname(path.join(root,target)),{recursive:true});await fs.copyFile(source,path.join(root,target));
  const service=createMountedRigService(root),original=await service.read(),p=structuredClone(original.project);p.parts[0].pivot[0]+=2;
  const invalid=structuredClone(p);invalid.assets.atlas.width=1;
  await assert.rejects(service.save({revision:original.revision,project:invalid}),{status:422});
  const [a,b]=await Promise.allSettled([service.save({revision:original.revision,project:p}),service.save({revision:original.revision,project:p})]);
  assert.equal(a.status,'fulfilled');assert.equal(b.status,'rejected');assert.equal(b.reason.status,409);
  assert.deepEqual(JSON.parse(await fs.readFile(path.join(root,a.value.backup))),original.project);
  assert.equal((await service.read()).project.parts[0].pivot[0],p.parts[0].pivot[0]);
 }finally{await fs.rm(root,{recursive:true,force:true});}
});
