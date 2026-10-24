import test from 'node:test';
import assert from 'node:assert/strict';
import {serve} from './server.mjs';

async function request(url,method='GET') {
 const result={};
 await serve({url,method},{writeHead(status,headers){Object.assign(result,{status,headers});},end(body){result.body=body;}});
 return result;
}

test('standalone workshop serves its visual dependencies with explicit types',async()=>{
 for(const [url,type] of [['/','text/html'],['/look.mjs','text/javascript'],['/hand.mjs','text/javascript'],['/tools.html','text/html'],['/tools-preview.mjs','text/javascript'],['/style.css','text/css'],['/hud-skin.mjs','text/javascript'],['/assis.png','image/png'],['/ui/panels.png','image/png'],['/ui/icons.png','image/png']]){
  const response=await request(url);
  assert.equal(response.status,200,url);
  assert.ok(response.headers['Content-Type'].startsWith(type),url);
  assert.ok(response.body.length>0,url);
 }
 const css=await request('/hud.css'),atlas=await request('/hud.json');
 assert.equal(css.status,200);
 assert.ok(css.body.includes('/ui/panels.png'));
 assert.ok(!css.body.includes('assets/ui/'));
 assert.ok(JSON.parse(atlas.body).slices['button-compact-normal']);
});

test('local server keeps an explicit read-only file allowlist',async()=>{
 for(const url of ['/package.json','/.env','/../../package.json','/%2e%2e%2fpackage.json','/%ZZ'])assert.equal((await request(url)).status,404,url);
 assert.equal((await request('/','POST')).status,405);
 assert.equal((await request('/assis.png','HEAD')).body,undefined);
 const response=await request('/');
 assert.match(response.headers['Content-Security-Policy'],/frame-ancestors 'self'/);
 assert.match(response.headers['Content-Security-Policy'],/connect-src 'self'/);
});
