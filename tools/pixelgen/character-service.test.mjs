import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {createCharacterService} from './character-service.mjs';
import {connectedSave} from './album.mjs';
import {decodePNG} from './png.mjs';
import {characters} from './character-catalog.mjs';
test('catalog includes fourteen human actors and four prepared Cerol Hunters',()=>{
 assert.equal(characters.length,18);assert.equal(characters.filter(c=>c.inGame).length,14);
 assert.deepEqual(characters[0].assets.map(a=>a.id),['kael-idle','kael-run','kael-walk','kael-jump','kael-item']);
});
test('save persists layered pixels, runtime PNG, native document and recoverable original; rejects stale/structural writes',async t=>{
 const root=await fs.mkdtemp(path.join(os.tmpdir(),'pixelgen-album-'));t.after(()=>fs.rm(root,{recursive:true,force:true}));
 const p={kind:'pixelgen',version:2,name:'Fixture',width:2,height:2,cols:1,rows:1,palette:[[0,0,0,0],[10,20,30,255],[90,80,70,255]],layers:[{name:'Arte'}],frames:[{name:'idle-S-1',duration:200,indices:[1,0,0,0],cels:[[1,0,0,0]]}]};
 await fs.writeFile(path.join(root,'person.pixelgen.json'),JSON.stringify(p));await fs.writeFile(path.join(root,'runtime.png'),'original');
 const binding={id:'fixture',project:'person.pixelgen.json',png:'source.png',runtime:'runtime.png',inGame:true};
 const service=createCharacterService(root,{catalog:[],assets:new Map([['fixture',binding]])});const before=await service.open('fixture');
 before.project.frames[0].cels[0][0]=2; // authoritative layer, stale composite must not win
 const saved=await service.save('fixture',{revision:before.revision,project:before.project});assert.notEqual(saved.revision,before.revision);
 const next=await service.open('fixture');assert.equal(next.project.frames[0].indices[0],2);
 const png=decodePNG(await fs.readFile(path.join(root,'runtime.png')));assert.deepEqual(Array.from(png.data.slice(0,4)),[90,80,70,255]);
 assert.deepEqual(await fs.readFile(path.join(root,'source.png')),await fs.readFile(path.join(root,'runtime.png')));
 assert.ok((await fs.readFile(path.join(root,'person.aseprite'))).length>128);
 const history=await fs.readdir(path.join(root,'.local/pixelgen-history/fixture'));assert.equal(history.length,1);
 assert.equal((await fs.readFile(path.join(root,'.local/pixelgen-history/fixture',history[0],'3.bak'))).toString(),'original');
 await assert.rejects(service.save('fixture',{revision:before.revision,project:before.project}),{status:409});
 const bad=structuredClone(next.project);bad.frames[0].name='wrong-direction';await assert.rejects(service.save('fixture',{revision:next.revision,project:bad}),{status:422});
 await assert.rejects(service.open('../anything'),{status:404});assert.equal((await service.open('fixture')).revision,next.revision);
});
test('autosave serializes edits while an earlier write is in flight; navigation waits for latest snapshot',async()=>{
 let release;const sent=[];const save=connectedSave({delay:100000,send:async(id,value)=>{sent.push({id,...value});if(sent.length===1)await new Promise(r=>release=r);return {revision:'r'+sent.length};}});
 save.bind({id:'kael',revision:'r0',inGame:true});save.change({pixel:1});const first=save.flush();await new Promise(r=>setImmediate(r));save.change({pixel:2});release();await first;await save.detach();
 assert.equal(sent.length,2);assert.equal(sent[1].revision,'r1');assert.deepEqual(sent[1].project,{pixel:2});assert.equal(save.active,null);
});
test('failed autosave keeps dirty data and blocks navigation until a successful retry',async()=>{
 let fail=true;const save=connectedSave({delay:100000,send:async()=>{if(fail)throw Error('Conflict');return {revision:'r1'};}});
 save.bind({id:'nina',revision:'r0'});save.change({pixel:1});await assert.rejects(save.flush(),/Conflict/);assert.equal(save.pending,true);await assert.rejects(save.detach());
 fail=false;await save.retry();assert.equal(save.pending,false);await save.detach();
});
