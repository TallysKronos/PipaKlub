import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import {serve} from './server.mjs';
test('local studio serves only editor and approved source assets, refuses writes and path escapes',async()=>{
 const server=http.createServer(serve);await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));const base='http://127.0.0.1:'+server.address().port;
 try{
  const page=await fetch(base+'/');assert.equal(page.status,200);assert.match(await page.text(),/Soulgen Studio/);assert.match(page.headers.get('content-security-policy'),/object-src 'none'/);
  for(const route of ['/studio.mjs','/model.mjs','/carcara.mjs','/eremor.mjs','/workflow.mjs','/studio.css','/art/soulgen/keys/carcara/color-rig/rig.mjs','/art/soulgen/keys/carcara/source/layers-generated.png','/art/soulgen/keys/eremor/rig-data.mjs','/art/soulgen/keys/eremor/parts/head.png','/art/soulgen/keys/eremor/eremor.soulgen.json'])assert.equal((await fetch(base+route)).status,200,route);
  for(const route of ['/.env','/package.json','/server.mjs','/art/soulgen/keys/carcara/prepare.py','/%2e%2e%2f.env','/art/soulgen/keys/%2e%2e%2fREADME.md'])assert.ok([403,404].includes((await fetch(base+route)).status),route);
  assert.equal((await fetch(base+'/',{method:'POST',body:'overwrite'})).status,405);assert.equal((await fetch(base+'/studio.css',{method:'HEAD'})).headers.get('content-type'),'text/css; charset=utf-8');
 }finally{await new Promise(resolve=>server.close(resolve));}
});
