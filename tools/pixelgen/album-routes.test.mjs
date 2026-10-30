import test from 'node:test';
import assert from 'node:assert/strict';
import {Readable} from 'node:stream';
import {serve} from './server.mjs';
async function request(url,{method='GET',headers={},body=''}={}){const req=Readable.from(body?[Buffer.from(body)]:[]);Object.assign(req,{url,method,headers:{host:'127.0.0.1:5264',...headers}});let status,data,responseHeaders;await serve(req,{writeHead:(code,h)=>{status=code;responseHeaders=h;},end:value=>{data=value;}});return {status,data,headers:responseHeaders};}
test('album routes expose current characters, projects and PNG previews',async()=>{
 const list=await request('/api/characters');assert.equal(list.status,200);assert.equal(JSON.parse(list.data).length,18);
 for(const id of ['iara','nilo','dora','caue','celina']) {
  const entry=await request('/api/characters/'+id);assert.equal(entry.status,200);
  assert.equal(JSON.parse(entry.data).project.frames.length,8);
  assert.equal((await request('/api/characters/'+id+'/preview')).status,200);
 }
 const doc=await request('/api/characters/nina');assert.equal(doc.status,200);assert.equal(JSON.parse(doc.data).project.width,64);
 const png=await request('/api/characters/nina/preview');assert.equal(png.status,200);assert.equal(png.headers['Content-Type'],'image/png');
 assert.equal((await request('/api/characters/not-a-character')).status,404);
});
test('write routes reject cross-origin, rebinding hosts, wrong methods and malformed payloads before touching files',async()=>{
 assert.equal((await request('/api/characters/nina',{method:'PUT',headers:{origin:'https://attacker.example'}})).status,403);
 assert.equal((await request('/api/characters/nina',{method:'PUT',headers:{host:'attacker.example'}})).status,403);
 assert.equal((await request('/api/characters/nina',{method:'PUT',headers:{'sec-fetch-site':'cross-site'}})).status,403);
 assert.equal((await request('/api/characters/nina',{method:'POST'})).status,405);
 assert.equal((await request('/api/characters/nina',{method:'PUT'})).status,415);
 assert.equal((await request('/api/characters/nina',{method:'PUT',headers:{'content-type':'application/json'},body:'broken'})).status,400);
 assert.equal((await request('/api/characters/nina',{method:'PUT',headers:{'content-type':'application/json'},body:'null'})).status,400);
 assert.equal((await request('/api/characters/not-a-character',{method:'PUT',headers:{'content-type':'application/json'},body:'{"revision":"missing","project":{}}'})).status,404);
});
