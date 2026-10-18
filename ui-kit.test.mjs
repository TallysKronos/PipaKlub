import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import {uiKitSurfaces} from './src/ui-kit-policy.js';
test('kit surface policy references existing manifest pieces',()=>{const m=JSON.parse(fs.readFileSync('assets/ui/kit-switch-v1/manifest.json'));for(const skin of Object.keys(uiKitSurfaces))assert.ok(m.components[skin],skin);});
test('kit adapter decorates new controls without replacing listeners or observing animation attributes',async()=>{
 const button={dataset:{},classList:{contains:c=>c==='primary'},matches:()=>false,closest:()=>null};
 const root={querySelector:()=>null,querySelectorAll:s=>s.startsWith('button.primary')?[button]:[],body:{classList:{add(){}}}};let callback,options;const tasks=[];
 const context={document:root,ART_CONFIG:{courtyard:{images:{}}},uiKitSurfaces,Set,Promise:{resolve:()=>({then:f=>tasks.push(f)})},MutationObserver:class{constructor(f){callback=f}observe(target,o){options=o}}};
 vm.runInNewContext(fs.readFileSync('src/ui-kit-client.js','utf8'),context);assert.equal(button.dataset.kitButton,'primary');assert.equal(options.attributes,undefined);
 const fresh={dataset:{},classList:{contains:()=>false},matches:()=>false,closest:()=>null};const subtree={nodeType:1,isConnected:true,matches:()=>false,querySelectorAll:s=>s.startsWith('button.primary')?[fresh]:[]};
 callback([{addedNodes:[subtree]}]);assert.equal(tasks.length,1);tasks[0]();assert.equal(fresh.dataset.kitButton,'secondary');
});
