import test from 'node:test';
import assert from 'node:assert/strict';
import {createCharacterBase} from './character-style.mjs';
import {serialize,validateProject} from './core.mjs';
import {cloneDocument} from './document.mjs';
import {duplicateFrame} from './animation.mjs';
import {atlas} from './animation.mjs';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {run} from './cli.mjs';
import {completeSkeleton,moveSkeletonJoint,solveChain,skeletonTemplate,applySkeletonTemplate,skeletonReport,JOINTS,paintSkeleton} from './skeleton.mjs';
const base=(options)=>validateProject(createCharacterBase(options));
const dist=(a,b)=>Math.hypot(a[0]-b[0],a[1]-b[1]);
test('all three bodies and eight directions have editable articulated joints, contacts and independent persistence',()=>{
 for(const body of ['jovem','adulto','robusto'])for(const [width,height]of [[48,64],[32,48]]){
  const p=base({body,width,height});for(const f of p.frames){assert.equal(Object.keys(f.pose).length,14);for(const j of JOINTS)assert.ok(f.pose[j]);assert.deepEqual(f.support,['peTras','peFrente']);}
  assert.deepEqual(validateProject(serialize(p)).frames[0].pose,p.frames[0].pose);
  const c=cloneDocument(p);c.frames[0].support.pop();assert.equal(p.frames[0].support.length,2);
  const i=duplicateFrame(p,0);p.frames[i].support.pop();assert.equal(p.frames[0].support.length,2);
 }
 const old={topo:[12,2],queixo:[12,12],quadril:[12,24],ombroTras:[8,15],maoTras:[7,24],ombroFrente:[16,15],maoFrente:[17,24],peTras:[10,40],peFrente:[14,40]};
 const done=completeSkeleton(old);assert.equal(old.cotoveloTras,undefined);assert.equal(Object.keys(done).length,14);
});
test('two-bone IK preserves lengths within pixel rounding, reachable target and bending side',()=>{
 const root=[15,15],joint=[22,20],end=[20,28];
 for(const target of [[25,20],[18,25],[15,30],[100,100],[15,15]]){
  const q=solveChain(root,joint,end,target);
  assert.ok(Math.abs(dist(root,joint)-dist(root,q.joint))<1.5);
  assert.ok(Math.abs(dist(joint,end)-dist(q.joint,q.end))<1.5);
  assert.ok(q.joint.concat(q.end).every(Number.isInteger));
 }
 assert.throws(()=>solveChain(root,root,end,end),/sem comprimento/);
});
test('hip movement holds contact, impossible reach and canvas overflow preserve original pose and pixels',()=>{
 const p=base(),f=p.frames[0],original=JSON.stringify(serialize(p));
 const pose=moveSkeletonJoint(f.pose,'quadril',[f.pose.quadril[0],f.pose.quadril[1]-1],{width:48,height:64,support:f.support});
 assert.deepEqual(pose.peTras,f.pose.peTras);assert.deepEqual(pose.peFrente,f.pose.peFrente);
 assert.throws(()=>moveSkeletonJoint(f.pose,'peTras',[10,40],{width:48,height:64,support:f.support}),/Solte/);
 assert.throws(()=>moveSkeletonJoint(f.pose,'quadril',[24,0],{width:48,height:64,support:f.support}),/alcance/);
 assert.throws(()=>moveSkeletonJoint(f.pose,'quadril',[-99,30],{width:48,height:64}),/ultrapassa/);
 assert.equal(JSON.stringify(serialize(p)),original);
 const lifted=moveSkeletonJoint(f.pose,'maoFrente',[36,35],{width:48,height:64});assert.notDeepEqual(lifted.cotoveloFrente,f.pose.cotoveloFrente);
});
test('reusable templates accept matching duplicated frames; reject incompatible directions, bodies, supports and malformed joints',()=>{
 const p=base(),template=skeletonTemplate(p),i=duplicateFrame(p,0);applySkeletonTemplate(p,i,template);
 assert.deepEqual(p.frames[i].pose,p.frames[0].pose);p.frames[i].pose.topo[0]++;assert.notDeepEqual(p.frames[i].pose,p.frames[0].pose);
 assert.throws(()=>applySkeletonTemplate(p,2,template),/direção/);
 assert.throws(()=>applySkeletonTemplate(base({body:'adulto'}),0,template),/incompatível/);
 assert.throws(()=>applySkeletonTemplate(p,0,{...template,pose:{...template.pose,cotoveloFrente:[-1,0]}}),/inválida/);
 assert.throws(()=>validateProject({...serialize(p),frames:serialize(p).frames.map((f,i)=>i?f:{...f,support:['maoFrente']})}),/Apoio inválido/);
});
test('overlay never changes native data and audit detects bone-length drift and planted-foot sliding',()=>{
 const p=base(),before=JSON.stringify(serialize(p)),ctx={save(){},restore(){},setLineDash(){},beginPath(){},moveTo(){},lineTo(){},stroke(){},fillRect(){}};
 paintSkeleton(ctx,p.frames[0].pose,8,0,p.frames[0].support);assert.equal(JSON.stringify(serialize(p)),before);
 duplicateFrame(p,0);p.frames[1].pose.peFrente[0]+=5;p.frames[1].pose.cotoveloFrente[1]-=10;p.sequences[0].end=1;
 const r=skeletonReport(p);assert.ok(r.warnings.some(t=>t.includes('apoio')));assert.ok(r.warnings.some(t=>t.includes('comprimento')));assert.ok(r.frames[0].anchors.cabelo);
});
test('CLI exports/imports rigs across compatible characters, and atlases retain joints and support',async()=>{
 const folder=fs.mkdtempSync(path.join(os.tmpdir(),'pixelgen-rig-')),file=path.join(folder,'personagem.pixelgen.json'),rig=path.join(folder,'pose.json');
 try{
  const p=base();fs.writeFileSync(file,JSON.stringify(serialize(p)));
  await run(['skeleton',file,'--frame','0','--export',rig]);assert.equal(JSON.parse(fs.readFileSync(rig)).pose.pescoco.length,2);
  await run(['skeleton',file,'--frame','0','--support','peFrente']);assert.deepEqual(JSON.parse(fs.readFileSync(file)).frames[0].support,['peFrente']);
  await run(['skeleton',file,'--frame','0','--import',rig]);const loaded=validateProject(JSON.parse(fs.readFileSync(file)));assert.equal(loaded.frames[0].support.length,2);
  const a=atlas(loaded,'sprite.png');assert.deepEqual(a.frames[0].pose,loaded.frames[0].pose);assert.deepEqual(a.frames[0].support,['peTras','peFrente']);
  a.frames[0].pose.topo[0]++;assert.notDeepEqual(a.frames[0].pose,loaded.frames[0].pose);
 }finally{for(const f of [file,rig])if(fs.existsSync(f))fs.unlinkSync(f);fs.rmdirSync(folder);}
});
