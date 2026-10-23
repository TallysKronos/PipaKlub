import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import {serve} from './server.mjs';
test('Iso Studio serve só a bancada e recusa escrita e caminhos de fuga',async()=>{
 const server=http.createServer(serve);await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));const base='http://127.0.0.1:'+server.address().port;
 try{
  const page=await fetch(base+'/');assert.equal(page.status,200);assert.match(await page.text(),/Iso Studio/);assert.match(page.headers.get('content-security-policy'),/object-src 'none'/);
  for(const route of ['/studio.mjs','/model.mjs','/studio.css'])assert.equal((await fetch(base+route)).status,200,route);
  for(const route of ['/server.mjs','/.env','/../package.json','/%2e%2e%2fpackage.json','/model.test.mjs'])assert.equal((await fetch(base+route)).status,404,route);
  assert.equal((await fetch(base+'/',{method:'POST',body:'x'})).status,405);
 }finally{await new Promise(resolve=>server.close(resolve));}
});
