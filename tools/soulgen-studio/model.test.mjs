import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {createCarcara} from './carcara.mjs';
import {validate,sample,identity,clone,putKey,matrices,point,render,exportPlan,History} from './model.mjs';
import {pose as approvedPose,expression as approvedExpression} from '../../art/soulgen/keys/carcara/color-rig/rig.mjs';
const preset=await createCarcara(async src=>{const png=fs.readFileSync(new URL('../..'+src,import.meta.url));return {width:png.readUInt32BE(16),height:png.readUInt32BE(20)};});
test('approved full-color Carcara imports source rectangles, timing, expressions and stable cycle endpoints',()=>{
 assert.equal(validate(preset).ok,true);assert.equal(preset.parts.length,4);assert.equal(preset.assets.original.width,1254);
 for(const [id,c]of Object.entries(preset.clips))for(const t of [0,.1,.4,.74,c.seconds]){const p=sample(preset,id,t),a=approvedPose(id,t);assert.ok(Math.abs(p.values.root.x-a.x)<.05,id+' body x');assert.ok(Math.abs(p.values.wingNear.rotation-a.near)<.2,id+' wing angle');assert.equal(p.face,approvedExpression(id,t));}
 for(const id of ['idle','flight']){const c=preset.clips[id],a=sample(preset,id,0),b=sample(preset,id,c.seconds-1e-7);assert.ok(Math.abs(a.values.tail.rotation-b.values.tail.rotation)<.001);}
 assert.equal(sample(preset,'skill',10).done,true);assert.equal(sample(preset,'skill',10).values.root.x,0);
});
test('validation blocks invalid cuts, remote images, cycles, missing pieces, malformed documents and duplicate times',()=>{
 for(const change of [p=>p.parts[0].source[0]=99999,p=>p.assets.original.src='https://untrusted.invalid/image.png',p=>{p.parts[0].parent=p.parts[1].id;p.parts[1].parent=p.parts[0].id;},p=>p.parts[0].parent='missing',p=>p.clips.idle.frames[1].t=0,p=>p.clips.skill.hitTime=99,p=>p.clips.idle.frames[0].values.root.scaleX=0,p=>p.parts[0].id='__proto__']){const p=clone(preset);change(p);assert.equal(validate(p).ok,false);assert.throws(()=>exportPlan(p));}
 for(const p of [null,{},[],{schema:'soulgen-studio',version:1,parts:[null]}])assert.equal(validate(p).ok,false);
});
test('generic hierarchy supports other anatomies and applies parent transforms around fixed joint pivots',()=>{
 const p=clone(preset);p.parts[0].parent='body';const pose=sample(p,'idle',0);pose.values.root=identity();pose.values.body={...identity(),rotation:90};pose.values.tail=identity();const m=matrices(p,pose),q=point(m.tail,48,56);assert.ok(Math.abs(q.x-34)<1e-8);assert.ok(Math.abs(q.y-42)<1e-8);
 const original=[...p.parts[0].pivot];for(let i=0;i<100;i++)matrices(p,sample(p,'flight',i/60));assert.deepEqual(p.parts[0].pivot,original);
});
test('recorded keys interpolate, replace their timestamp and survive a JSON roundtrip with undo/redo',()=>{
 const p=clone(preset),h=new History(2),before=JSON.stringify(p);h.push(p);const values=sample(p,'skill',.5).values;values.root.x=12;putKey(p,'skill',.5,values,'smooth');assert.equal(sample(p,'skill',.5).values.root.x,12);const count=p.clips.skill.frames.length;values.root.x=14;putKey(p,'skill',.5,values);assert.equal(p.clips.skill.frames.length,count);assert.equal(sample(p,'skill',.5).values.root.x,14);assert.equal(validate(JSON.parse(JSON.stringify(p))).ok,true);
 const undo=h.undo(p);assert.equal(JSON.stringify(undo),before);assert.equal(sample(h.redo(undo),'skill',.5).values.root.x,14);
});
test('preview and export renderer replace the face on one body and restore transforms',()=>{
 const source={id:'original'},face={id:'fierce'},calls=[],ctx={canvas:{width:256,height:256},clearRect(){},save(){},restore(){},translate(){},scale(){},transform(){},drawImage(...args){calls.push(args);}};
 render(ctx,preset,{original:source,fierce:face},sample(preset,'skill',.74));assert.equal(calls.length,4);assert.equal(calls[2][0],face);assert.deepEqual(calls[2].slice(1,5),[0,0,280,361]);assert.deepEqual(calls[2].slice(5),[35,24,26,34]);
});
test('atlas export preserves action metadata, impact, bounded dimensions and refuses excessive output',()=>{
 const a=exportPlan(preset);assert.ok(a.frames.length>100);assert.equal(a.animations.skill.hitTime,.74);assert.equal(a.animations.skill.hitFrame,9);assert.equal(a.animations.idle.loop,true);assert.equal(a.animations.hurt.loop,false);assert.ok(a.pixelPivot.y<a.cell/2);assert.ok(a.frames.every(f=>f.x+f.w<=a.width&&f.y+f.h<=a.height));assert.equal(a.frames.at(-1).time,preset.clips.victory.seconds);
 assert.throws(()=>exportPlan(preset,{fps:60,cell:512,columns:1}),/grande/);assert.throws(()=>exportPlan(preset,{clipIds:['missing']}));assert.throws(()=>exportPlan(preset,{fps:0}));
});
test('continuous (spline) keys pass through every pose, close loops smoothly and the preset stays compact and faithful',()=>{
 for(const [id,c]of Object.entries(preset.clips)){
  assert.ok(c.frames.length<=13,id+' keeps few editable poses');
  for(let t=0;t<=c.seconds;t+=1/120){const p=sample(preset,id,t).values,a=approvedPose(id,t),lag=preset.parts.find(q=>q.id==='tail').lag,at=c.loop?t-lag:Math.max(0,t-lag),b=approvedPose(id,c.loop?((at%c.seconds)+c.seconds)%c.seconds:at);assert.ok(Math.abs(p.root.y-a.y)<.01,id+' y');assert.ok(Math.abs(p.tail.rotation-b.tail)<.1,id+' tail follows the approved curve, delayed');}
  for(const f of c.frames){const v=sample(preset,id,f.t).values.wingNear.rotation;assert.ok(Math.abs(v-(f.values.wingNear?.rotation??0))<1e-9,id+' passes through its key');}
 }
 const c=preset.clips.flight,e=1e-4,slope=t=>(sample(preset,'flight',t+e).values.wingNear.rotation-sample(preset,'flight',t-e).values.wingNear.rotation)/(2*e);
 assert.ok(Math.abs(slope(e*2)-slope(c.seconds-e*2))<1,'loop seam has matching speed');
 assert.ok(Math.abs(slope(c.frames[1].t))>50,'spline does not stop at an inner key');
});
test('lag delays only that part and is validated',()=>{
 const base=clone(preset);for(const q of base.parts)delete q.lag;const p=clone(base);p.parts.find(q=>q.id==='tail').lag=.12;
 for(const t of [.2,.9,2.5]){const a=sample(p,'idle',t),b=sample(base,'idle',t-.12);assert.ok(Math.abs(a.values.tail.rotation-b.values.tail.rotation)<1e-9);assert.deepEqual(a.values.root,sample(base,'idle',t).values.root);}
 assert.deepEqual(sample(p,'skill',.05).values.tail,sample(base,'skill',0).values.tail,'one-shot clips hold the first pose until the lag passes');
 assert.equal(validate(p).ok,true);p.parts[0].lag=2;assert.equal(validate(p).ok,false);p.parts[0].lag=-1;assert.equal(validate(p).ok,false);
});
