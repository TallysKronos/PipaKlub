import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import {createEremor} from './eremor.mjs';
import {validate,sample,matrices,point,exportPlan,render} from './model.mjs';
import {anatomyReport} from './workflow.mjs';

const root=new URL('../../',import.meta.url);
const pngSize=async src=>{
 const data=await fs.readFile(new URL(src.slice(1),root));
 assert.equal(data.subarray(1,4).toString(),'PNG');
 return {width:data.readUInt32BE(16),height:data.readUInt32BE(20)};
};
test('Eremor opens with seven independent PNG parts and a portable embedded project',async()=>{
 const p=await createEremor(pngSize);assert.deepEqual(validate(p),{ok:true,errors:[],warnings:[]});
 assert.equal(p.parts.length,7);
 const portable=JSON.parse(await fs.readFile(new URL('art/soulgen/keys/eremor/eremor.soulgen.json',root),'utf8'));
 assert.equal(validate(portable).ok,true);
 assert.deepEqual(portable.parts,p.parts);assert.deepEqual(portable.clips,p.clips);assert.deepEqual(portable.anatomy,p.anatomy);
 for(const [id,a]of Object.entries(portable.assets)){
  assert.match(a.src,/^data:image\/png;base64,/);
  const actual=await fs.readFile(new URL('art/soulgen/keys/eremor/parts/'+id+'.png',root));
  assert.deepEqual(Buffer.from(a.src.split(',')[1],'base64'),actual);
 }
 const second=await createEremor();second.parts[0].rect[0]=999;
 assert.notEqual((await createEremor()).parts[0].rect[0],999,'Presets must not share mutable state');
 await assert.rejects(createEremor(async()=>({width:1,height:1})),/Dimensões/);
});
test('Eremor joints follow the trunk and animations settle without scale jumps or detached limbs',async()=>{
 const p=await createEremor();
 for(const [id,c]of Object.entries(p.clips)){
  for(let t=0;t<=c.seconds;t+=1/60){
   const pose=sample(p,id,t),m=matrices(p,pose);
   for(const part of p.parts){
    const v=pose.values[part.id];assert.equal(v.scaleX,1);assert.equal(v.scaleY,1);
    if(part.parent){
     const joint=point(m[part.id],...part.pivot),parentJoint=point(m[part.parent],...part.pivot);
     assert.ok(Math.hypot(joint.x-parentJoint.x,joint.y-parentJoint.y)<1e-9,id+'/'+part.id+' detached joint');
    }
    for(const [x,y]of [[0,0],[1,0],[0,1],[1,1]]){
     const at=point(m[part.id],part.rect[0]+x*part.rect[2],part.rect[1]+y*part.rect[3]);
     assert.ok(at.x>=0&&at.x<=p.width&&at.y>=0&&at.y<=p.height,id+'/'+part.id+' outside stage');
    }
   }
  }
  if(c.loop){
   const before=sample(p,id,c.seconds-1e-6),after=sample(p,id,1e-6);
   for(const name of Object.keys(before.values))for(const channel of ['x','y','rotation'])assert.ok(Math.abs(before.values[name][channel]-after.values[name][channel])<.001,'loop seam '+id+'/'+name);
  }else{
   const final=sample(p,id,c.seconds+10);assert.equal(final.done,true);
   for(const v of Object.values(final.values))assert.deepEqual(v,{x:0,y:0,rotation:0,scaleX:1,scaleY:1});
  }
 }
 assert.equal(p.clips.skill.hitTime,1.05);
 const plan=exportPlan(p,{fps:12,cell:256,columns:8});
 assert.deepEqual(Object.keys(plan.animations),['idle','flight','skill','hurt','victory']);
 assert.equal(plan.animations.skill.hitFrame,13);
});

test('anatomical audit catches oversized heads, disconnected anchors, wrong layering and pivot drift',async()=>{
 const p=await createEremor(),report=anatomyReport(p);
 assert.deepEqual(report.warnings,[]);assert.equal(report.notes.length,7);
 const changed=()=>JSON.parse(JSON.stringify(p));
 const big=changed();big.parts.find(p=>p.id==='head').rect[2]=120;
 assert.ok(anatomyReport(big).warnings.some(s=>/Cabeça \/ tronco/.test(s)));
 const floating=changed(),head=floating.parts.find(p=>p.id==='head');head.rect[0]-=30;head.pivot[0]-=30;
 assert.ok(anatomyReport(floating).warnings.some(s=>/Cabeça e pescoço: encaixe/.test(s)),'Moving part and pivot together must still detect a detached anatomical joint');
 const z=changed();z.parts.find(p=>p.id==='sails').z=9;
 assert.ok(anatomyReport(z).warnings.some(s=>/Leque dorsal.*atrás/.test(s)));
 const drifting=changed();drifting.parts.find(p=>p.id==='armNear').pivot[0]+=50;
 assert.ok(anatomyReport(drifting).warnings.some(s=>/Braço próximo.*encaixe/.test(s)),'A bad pivot can pass rest but fail during the attack');
});

test('Eremor renders the chest knot behind the near arm and replaces one head with the matching expression',async()=>{
 const p=await createEremor(),head=p.parts.find(p=>p.id==='head');
 assert.deepEqual(Object.keys(head.faces),['fierce','hurt','happy']);
 const images=Object.fromEntries(Object.keys(p.assets).map(id=>[id,{id}]));
 for(const [clip,t,face]of [['idle',1,'normal'],['flight',1,'normal'],['skill',.85,'fierce'],['skill',1.05,'fierce'],['hurt',.14,'hurt'],['victory',1.3,'happy']]){
  const draws=[],ctx={canvas:{width:340,height:280},clearRect(){},save(){},restore(){},translate(){},scale(){},transform(){},drawImage(image){draws.push(image.id);}};
  const pose=sample(p,clip,t);assert.equal(pose.face,face);render(ctx,p,images,pose);
  assert.equal(draws.length,7,'Face must replace the head, never add another overlay');
  assert.ok(draws.indexOf('knot')<draws.indexOf('armNear'),'The near arm must cover the knot');
  assert.equal(draws.filter(id=>id.startsWith('head')).length,1);
  assert.ok(draws.includes(face==='normal'?'head':head.faces[face].asset));
 }
 for(const clip of ['skill','hurt','victory'])assert.equal(sample(p,clip,p.clips[clip].seconds).face,'normal');
 const bad=JSON.parse(JSON.stringify(p));bad.parts.find(p=>p.id==='knot').z=8;
 assert.ok(anatomyReport(bad).warnings.some(s=>/Nó do Elo.*atrás/.test(s)));
});
