import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {createGameSpritesService,gameSprites} from './game-sprites-service.mjs';
import {encodePNG,decodePNG} from '../pixelgen/png.mjs';
import {serve} from './server.mjs';
import http from 'node:http';
test('direction patch preserves every other pixel, alpha, revisions and backup; concurrent edits conflict',async()=>{
 const root=await fs.mkdtemp(path.join(os.tmpdir(),'soulgen-game-sprites-'));
 try{
  const rgba=new Uint8ClampedArray(8*8*4);for(let i=0;i<rgba.length;i++)rgba[i]=(i*17)%256;
  for(const asset of gameSprites){await fs.mkdir(path.dirname(path.join(root,asset.file)),{recursive:true});await fs.writeFile(path.join(root,asset.file),encodePNG(rgba,8,8));}
  await fs.writeFile(path.join(root,'godot/assets/mounts/doberman-c-v1/mount.json'),JSON.stringify({directions:{se:{rect:[2,2,2,2],riderRect:[2,2,2,2]}}}));
  const service=createGameSpritesService(root),catalog=await service.list(),revision=catalog.assets[0].revision;
  const patch=new Uint8ClampedArray([255,0,0,255,0,0,0,0,4,5,6,120,8,9,10,255]);
  const payload={revision,direction:'se',png:'data:image/png;base64,'+encodePNG(patch,2,2).toString('base64')};
  const results=await Promise.allSettled([service.save('doberman-c',payload),service.save('doberman-c',payload)]);
  assert.equal(results.filter(r=>r.status==='fulfilled').length,1);assert.equal(results.find(r=>r.status==='rejected').reason.status,409);
  const result=results.find(r=>r.status==='fulfilled').value,actual=decodePNG(await service.image('doberman-c'));
  for(let y=0;y<8;y++)for(let x=0;x<8;x++){const inside=x>=2&&x<4&&y>=2&&y<4;const expected=inside?patch.subarray(((y-2)*2+x-2)*4,((y-2)*2+x-2)*4+4):rgba.subarray((y*8+x)*4,(y*8+x)*4+4);assert.deepEqual(actual.data.subarray((y*8+x)*4,(y*8+x)*4+4),expected);}
  assert.deepEqual(decodePNG(await fs.readFile(path.join(root,result.backup))).data,rgba);
  assert.deepEqual(decodePNG(await service.image('kael-mounted')).data,rgba);
  await assert.rejects(service.save('doberman-c',{...payload,revision:result.revision,direction:'unknown'}),e=>e.status===422);
  await assert.rejects(service.save('doberman-c',{...payload,revision:result.revision,png:'data:image/png;base64,'+encodePNG(patch,1,4).toString('base64')}),e=>e.status===422);
  await assert.rejects(service.image('../outside'),e=>e.status===404);
  await fs.writeFile(path.join(root,'godot/assets/mounts/doberman-c-v1/mount.json'),JSON.stringify({directions:{se:{rect:[2,2,2,2],riderRect:[2,2,2,2]},e:{rect:[3,2,2,2],riderRect:[3,2,2,2]}}}));
  const changed=patch.slice();changed[4]=122;
  await assert.rejects(service.save('doberman-c',{...payload,revision:result.revision,png:'data:image/png;base64,'+encodePNG(changed,2,2).toString('base64')}),e=>e.status===422);
 }finally{await fs.rm(root,{recursive:true,force:true});}
});
test('local editor routes, fixed files and cross-origin write rejection',async()=>{
 const server=http.createServer(serve);await new Promise(r=>server.listen(0,'127.0.0.1',r));const base='http://127.0.0.1:'+server.address().port;
 try{
  for(const route of ['/game-sprites.html','/game-sprites.mjs','/game-sprites.css','/api/game-sprites','/api/game-sprites/kael-mounted/image'])assert.equal((await fetch(base+route)).status,200,route);
  assert.equal((await fetch(base+'/api/game-sprites/unknown/image')).status,404);
  assert.equal((await fetch(base+'/api/game-sprites/kael-mounted',{method:'PUT',headers:{Origin:'https://outside.example','Content-Type':'application/json'},body:'{}'})).status,403);
  assert.equal((await fetch(base+'/api/game-sprites/kael-mounted',{method:'PUT',body:'{}'})).status,415);
  assert.equal((await fetch(base+'/api/game-sprites/kael-mounted',{method:'PUT',headers:{'Content-Type':'application/json'},body:'broken'})).status,400);
  assert.equal((await fetch(base+'/game-sprites-service.mjs')).status,404);
 }finally{await new Promise(r=>server.close(r));}
});

test('layout saves validate fixed fields, preserve other views, synchronize socket frames and backup',async()=>{
 const root=await fs.mkdtemp(path.join(os.tmpdir(),'soulgen-layout-'));try{
  const dest=path.join(root,'godot/assets/mounts/doberman-c-v1/mount.json');await fs.mkdir(path.dirname(dest),{recursive:true});
  const frame={seat:[10,20],hip:[30,40],ground:[50,60],frames:[{seat:[10,20]}]},rig={directions:{se:frame,sw:structuredClone(frame)}};
  await fs.writeFile(dest,JSON.stringify(rig));
  for(const asset of gameSprites)await fs.writeFile(path.join(root,asset.file),encodePNG(new Uint8ClampedArray(4),1,1));
  const service=createGameSpritesService(root),data=await service.list(),patch={seat:[12,25],hip:[35,42],ground:[54,64],farLegAngle:24};
  await assert.rejects(service.saveRig({revision:data.rigRevision,direction:'se',patch:{...patch,texture:'outside.png'}}),e=>e.status===422);
  await assert.rejects(service.saveRig({revision:data.rigRevision,direction:'se',patch:{...patch,seat:[Infinity,1]}}),e=>e.status===422);
  const saved=await service.saveRig({revision:data.rigRevision,direction:'se',patch}),next=JSON.parse(await fs.readFile(dest));
  assert.deepEqual(next.directions.sw,rig.directions.sw);assert.deepEqual(next.directions.se.frames[0].seat,patch.seat);assert.deepEqual(next.directions.se.hip,patch.hip);
  assert.deepEqual(JSON.parse(await fs.readFile(path.join(root,saved.backup))),rig);
  await assert.rejects(service.saveRig({revision:data.rigRevision,direction:'se',patch}),e=>e.status===409);
 }finally{await fs.rm(root,{recursive:true,force:true});}
});
