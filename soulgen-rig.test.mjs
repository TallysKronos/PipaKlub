import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import {validate,sample} from './tools/soulgen-studio/model.mjs';
import {artConfig,rigSource} from './scripts/art-build.mjs';
import {createAssetHandler} from './src/static-assets.js';

const manifest=JSON.parse(fs.readFileSync('assets/creatures/rig-v1/manifest.json','utf8'));
test('exported rigs are valid Studio projects whose PNGs are served and hashed for the game',async()=>{
 const serve=createAssetHandler(),config=artConfig();
 for(const [id,r]of Object.entries(manifest.rigs)){
  // The Studio only accepts its own key folder as a source; the game copies live under assets/ and are guarded by the asset allowlist.
  const structural=JSON.parse(JSON.stringify(r.project));for(const a of Object.values(structural.assets))a.src='/art/soulgen/keys/'+a.src.replace(/^creatures\/rig-v1\//,'');assert.deepEqual(validate(structural).errors,[],id);assert.ok(Number.isInteger(r.color));
  for(const [asset,a]of Object.entries(r.project.assets)){
   const res=await serve(new Request('http://x/assets/'+a.src));assert.equal(res.status,200,a.src);
   assert.match(config.rigs[id].urls[asset],new RegExp('^assets/'+a.src+'\\?v=[0-9a-f]{12}$'));
  }
  assert.equal(r.project.parts.find(p=>p.id==='tail').lag,.1,'approved follow-through travels with the export');
 }
});
function client(search){
 const loaded=[];
 const context={location:{search},ART_CONFIG:artConfig(),art:{reduced:false,special:()=>false},Image:class{set src(v){loaded.push(v);}},Math,Object,JSON};
 vm.createContext(context);vm.runInContext(rigSource()+';globalThis.soulgenRigs=soulgenRigs;',context);return {rigs:context.soulgenRigs,loaded};
}
test('rigs stay off without ?rig and never block the painted fallback while loading',()=>{
 const off=client('');assert.equal(off.rigs.enabled,false);assert.equal(off.rigs.draw({},0,0,-56,-44,112,{}),false);assert.equal(off.loaded.length,0,'no rig image is downloaded without the flag');
 const on=client('?rig');assert.equal(on.rigs.enabled,true);assert.equal(on.rigs.draw({},0,0,-56,-44,112,{}),false,'falls back to the atlas until images load');assert.ok(on.loaded.length>0);
 assert.equal(on.rigs.draw({},1,0,-56,-44,112,{}),false,'other Pipamons keep their painted art');
});
test('the Golpe impact pose is reachable from a landed cut',()=>{
 const p=manifest.rigs.carcara.project,s=p.clips.skill;assert.ok(s.hitTime>0&&s.hitTime<s.seconds);
 const impact=sample(p,'skill',s.hitTime);assert.equal(impact.face,'fierce');assert.ok(Math.abs(impact.values.root.rotation)>5);
});
