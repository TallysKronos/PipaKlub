import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import {serve} from './server.mjs';
test('Avatar Studio serve só a bancada, o zip compartilhado e o piloto do Kael',async()=>{
 const server=http.createServer(serve);await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));const base='http://127.0.0.1:'+server.address().port;
 try{
  const page=await fetch(base+'/');assert.equal(page.status,200);assert.match(await page.text(),/Avatar Studio/);
  for(const route of ['/studio.mjs','/model.mjs','/studio.css','/iso-studio/model.mjs','/art/soulgen/keys/kael-frame-test/frames/east-0.png'])assert.equal((await fetch(base+route)).status,200,route);
  for(const route of ['/server.mjs','/../package.json','/art/soulgen/keys/kael-frame-test/manifest.json','/iso-studio/server.mjs','/%2e%2e/package.json'])assert.equal((await fetch(base+route)).status,404,route);
  assert.equal((await fetch(base+'/',{method:'POST',body:'x'})).status,405);
 }finally{await new Promise(resolve=>server.close(resolve));}
});
