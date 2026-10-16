import test from 'node:test';
import assert from 'node:assert/strict';
import {createFrameHealth} from './src/frame-health.js';

test('sustained low frame rates request light graphics, a single slow window does not',()=>{
 const monitor=createFrameHealth();monitor.sample(0);
 let sample;for(let t=50;t<=1000;t+=50)sample=monitor.sample(t);
 assert.deepEqual(sample,{fps:20,needsLight:false});
 for(let t=1050;t<=2000;t+=50)sample=monitor.sample(t);
 assert.deepEqual(sample,{fps:20,needsLight:true});
});
test('inactive tabs reset the measurement instead of counting time away as slow rendering',()=>{
 const monitor=createFrameHealth();monitor.sample(0);monitor.sample(5000,false);monitor.sample(10000);
 let sample;for(let t=10020;t<=11000;t+=20)sample=monitor.sample(t);
 assert.deepEqual(sample,{fps:50,needsLight:false});
});
