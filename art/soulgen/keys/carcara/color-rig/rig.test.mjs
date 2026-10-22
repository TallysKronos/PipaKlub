import assert from 'node:assert/strict';
import test from 'node:test';
import {clips,pose,expression,render} from './rig.mjs';
test('continuous cycles close without pose jumps',()=>{
  for(const n of ['idle','flight']){
    const a=pose(n,0),b=pose(n,clips[n].seconds-1e-7);
    for(const key of Object.keys(a))assert.ok(Math.abs(a[key]-b[key])<1e-4,n+' '+key);
  }
});
test('actions settle in the original pose and keep every sampled transform finite',()=>{
  for(const n of Object.keys(clips)){
    const c=clips[n];
    for(let i=0;i<=240;i++)for(const v of Object.values(pose(n,i*c.seconds/240)))assert.ok(Number.isFinite(v));
    if(!c.loop)for(const v of Object.values(pose(n,c.seconds+3)))assert.equal(v,0);
  }
});
test('faces correspond to impact and recovery rather than blink patches',()=>{
  assert.equal(expression('skill',.74),'fierce');
  assert.equal(expression('hurt',.2),'hurt');
  assert.equal(expression('victory',1),'happy');
  for(const name of Object.keys(clips))assert.equal(expression(name,clips[name].seconds+2),'normal');
});
test('facial changes use the invariant body rectangle and do not insert extra face overlays',()=>{
  const img={width:1230,height:1278},face={width:280,height:361};
  for(const [name,seconds,key] of [['skill',.74,'fierce'],['hurt',.2,'hurt'],['victory',1,'happy']]){
    const calls=[];const ctx={canvas:{width:640,height:640},clearRect(){},save(){},restore(){},translate(){},scale(){},rotate(){},drawImage(...args){calls.push(args);}};
    render(ctx,img,name,seconds,{faces:{[key]:face}});
    assert.equal(calls.length,4);assert.equal(calls[2][0],face);
    assert.deepEqual(calls[2].slice(5),[35,24,26,34]);
  }
});
