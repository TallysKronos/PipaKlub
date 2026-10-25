import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import {serve} from './server.mjs';
test('Mapa Studio serve a bancada e os mapas, recusa escrita e caminhos de fuga',async()=>{
 const server=http.createServer(serve);await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));const base='http://127.0.0.1:'+server.address().port;
 try{
  const page=await fetch(base+'/');assert.equal(page.status,200);assert.match(await page.text(),/Mapa Studio/);assert.match(page.headers.get('content-security-policy'),/object-src 'none'/);
  for(const route of ['/studio.mjs','/model.mjs','/studio.css','/tiles/rascunho.tsj','/tiles/rascunho.png'])assert.equal((await fetch(base+route)).status,200,route);
  const list=await (await fetch(base+'/mapas/')).json();assert.ok(list.includes('veredas-piloto'));
  assert.equal((await (await fetch(base+'/mapas/veredas-piloto.tmj')).json()).orientation,'isometric');
  for(const route of ['/server.mjs','/.env','/../package.json','/%2e%2e%2fpackage.json','/model.test.mjs','/mapas/..%2f..%2fpackage.json','/tiles/.hidden.tsj','/mapas/x.js'])assert.equal((await fetch(base+route)).status,404,route);
  assert.equal((await fetch(base+'/',{method:'POST',body:'x'})).status,405);
 }finally{await new Promise(resolve=>server.close(resolve));}
});
