import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {createKael,customizeKael,setKaelDirection,KAEL_OPTIONS} from './kael.mjs';
import {validate,sample,matrices,point,exportPlan} from './model.mjs';
import {anatomyReport} from './workflow.mjs';

test('64 appearances preserve joints, animation, dimensions and roundtrip through the portable project',async()=>{
 const p=await createKael(),geometry=JSON.stringify(p.parts.map(({id,rect,pivot,parent,z})=>({id,rect,pivot,parent,z}))),clips=JSON.stringify(p.clips);
 let combinations=0;
 for(const [skin]of KAEL_OPTIONS.skin)for(const [hair]of KAEL_OPTIONS.hair)for(const [hairColor]of KAEL_OPTIONS.hairColor)for(const [outfit]of KAEL_OPTIONS.outfit){
  customizeKael(p,{skin,hair,hairColor,outfit});assert.equal(validate(p).ok,true);assert.equal(JSON.stringify(p.parts.map(({id,rect,pivot,parent,z})=>({id,rect,pivot,parent,z}))),geometry);assert.equal(JSON.stringify(p.clips),clips);assert.equal(p.parts.find(p=>p.id==='legLeft').asset,'leg-left-'+skin);combinations++;
 }
 assert.equal(combinations,64);const before=JSON.stringify(p);assert.throws(()=>customizeKael(p,{hair:'missing'}),/inválida/);assert.equal(JSON.stringify(p),before);
 const portable=JSON.parse(await fs.readFile(new URL('../../art/soulgen/keys/kael-v2/kael-v2.soulgen.json',import.meta.url),'utf8'));assert.equal(validate(portable).ok,true);assert.ok(Object.values(portable.assets).every(a=>a.src.startsWith('data:image/png;base64,')));customizeKael(portable,{skin:'escuro',outfit:'clay'});assert.equal(validate(portable).ok,true);assert.equal(exportPlan(portable,{fps:12,cell:128}).animations.walk.loop,true);
});

test('all four directions preserve sockets at 60 Hz across six actions; cycles close',async()=>{
 const p=await createKael();assert.deepEqual(validate(p).warnings,[]);assert.deepEqual(anatomyReport(p).warnings,[]);
 for(const [view]of KAEL_OPTIONS.view){setKaelDirection(p,view);assert.deepEqual(anatomyReport(p).warnings,[]);for(const [id,c]of Object.entries(p.clips)){
  for(let t=0;t<c.seconds;t+=1/60){const m=matrices(p,sample(p,id,t));for(const j of p.anatomy.joints){const part=p.parts.find(q=>q.id===j.part),parent=p.parts.find(q=>q.id===j.parent);const a=point(m[part.id],...part.pivot),b=point(m[parent.id],...part.pivot);assert.ok(Math.hypot(a.x-b.x,a.y-b.y)<1e-8,id+' '+j.part);}}
  if(c.loop)assert.deepEqual(c.frames[0].values,c.frames.at(-1).values);
 }}
});


test('direction switching keeps all 64 appearances, the registered source cell and reversible depth order',async()=>{
 const p=await createKael();let combinations=0;const clips=JSON.stringify(p.clips);
 for(const [view]of KAEL_OPTIONS.view){setKaelDirection(p,view);const geometry=JSON.stringify(p.parts.map(({pivot,z,parent})=>({pivot,z,parent})));
 for(const [skin]of KAEL_OPTIONS.skin)for(const [hair]of KAEL_OPTIONS.hair)for(const [hairColor]of KAEL_OPTIONS.hairColor)for(const [outfit]of KAEL_OPTIONS.outfit){customizeKael(p,{skin,hair,hairColor,outfit});assert.equal(validate(p).ok,true);assert.ok(p.parts.every(part=>part.source[0]>=p.avatar.directions.indexOf(view)*320&&part.source[0]+part.source[2]<=(p.avatar.directions.indexOf(view)+1)*320&&part.rect[2]<512));assert.equal(JSON.stringify(p.parts.map(({pivot,z,parent})=>({pivot,z,parent}))),geometry);combinations++;}
 }
 assert.equal(combinations,256);assert.equal(JSON.stringify(p.clips),clips);const before=JSON.stringify(p);assert.throws(()=>setKaelDirection(p,'invalid'));assert.equal(JSON.stringify(p),before);
 setKaelDirection(p,'north');assert.ok(p.parts.find(p=>p.id==='backpack').z>p.parts.find(p=>p.id==='body').z);setKaelDirection(p,'south');assert.ok(p.parts.find(p=>p.id==='backpack').z<p.parts.find(p=>p.id==='body').z);
});

test('raster audit covers opaque shoulder overlap and its negative control matches the exact delivered images',async()=>{
 const report=JSON.parse(await fs.readFile(new URL('../../art/soulgen/keys/kael-v2/pixel-audit.json',import.meta.url),'utf8'));assert.equal(report.checks.length,144);assert.equal(report.failures.length,0);assert.equal(report.negativeControl.detected,true);assert.ok(report.checks.every(c=>c.overlapPixels>=8));
 for(const [file,hash]of Object.entries(report.hashes)){const actual=createHash('sha256').update(await fs.readFile(new URL('../../'+file,import.meta.url))).digest('hex');assert.equal(actual,hash,file+' needs a new raster audit');}
});
