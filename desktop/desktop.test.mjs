import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
import policy from './policy.cjs';
import {steamBuildFiles} from './scripts/steam-vdf.mjs';
const origin='https://pipaklub.onrender.com',repo=fileURLToPath(new URL('../',import.meta.url));
async function fixture(t,extra={}){
 const parent=path.join(repo,'.local');await fs.mkdir(parent,{recursive:true});const root=await fs.mkdtemp(path.join(parent,'desktop-policy-'));
 t.after(async()=>{if(path.dirname(root)!==parent||!path.basename(root).startsWith('desktop-policy-'))throw Error('Unsafe fixture cleanup');await fs.rm(root,{recursive:true,force:true});});
 await fs.mkdir(path.join(root,'assets'));await fs.writeFile(path.join(root,'index.html'),'<html><script>const ready=true;\r\n</script></html>');await fs.writeFile(path.join(root,'assets','test.png'),Uint8Array.of(137,80,78,71));
 await fs.writeFile(path.join(root,'bundle.json'),JSON.stringify({files:['index.html','assets/test.png']}));
 return policy.createBundleHandler({root,origin,delegate:()=>Response.json({ok:true}),...extra});
}
test('desktop accepts only a credential-free HTTPS origin and constrains navigation and external links',()=>{
 assert.equal(policy.serverOrigin(origin),origin);
 for(const value of ['http://example.com','https://x:y@example.com','https://example.com/path','https://example.com?token=secret','file:///etc/passwd'])assert.throws(()=>policy.serverOrigin(value));
 assert.ok(policy.navigationAllowed(origin+'/?sala=ABC123',origin));assert.equal(policy.navigationAllowed(origin+'/account/session',origin),false);assert.equal(policy.navigationAllowed('https://evil.example',origin),false);
 assert.equal(policy.externalAllowed('file:///C:/Windows/System32/cmd.exe',origin),false);assert.equal(policy.externalAllowed('https://evil.example',origin),false);assert.ok(policy.externalAllowed('https://store.steampowered.com/',origin));
});
test('only listed client files are served; unknown files, traversal, foreign origins and write methods fail',async t=>{
 const serve=await fixture(t),get=url=>serve(new Request(origin+url));
 assert.equal((await get('/?sala=123ABC')).status,200);assert.equal((await get('/assets/test.png?v=1')).headers.get('Content-Type'),'image/png');
 for(const p of ['/.env','/bundle.json','/main.cjs','/assets/%2e%2e/.env','/assets/%5c..%5c.env','/assets/not-installed.png'])assert.equal((await get(p)).status,404,p);
 assert.equal((await serve(new Request('https://evil.example/'))).status,403);assert.equal((await serve(new Request(origin+'/',{method:'POST'}))).status,405);
 const head=await serve(new Request(origin+'/assets/test.png',{method:'HEAD'}));assert.equal(head.status,200);assert.equal((await head.arrayBuffer()).byteLength,0);
});
test('account requests preserve their body, origin, headers and credentials without broadening server access',async t=>{
 let received;const serve=await fixture(t,{delegate:r=>{received=r;return Response.json({ok:true});}});
 const request=new Request(origin+'/account/login',{method:'POST',headers:{origin,'Content-Type':'application/json',cookie:'__Host-pipa_access=test-only'},body:'{"test":true}',credentials:'include'});
 assert.equal((await serve(request)).status,200);assert.equal(received,request);assert.equal(received.headers.get('origin'),origin);assert.equal(received.credentials,'include');assert.equal(await received.text(),'{"test":true}');
});
test('offline mode refuses remote operations while the installed game and assets remain available',async t=>{
 const serve=await fixture(t,{offline:true,delegate:()=>assert.fail('No network in offline smoke')});
 assert.equal((await serve(new Request(origin+'/account/config'))).status,503);assert.equal((await serve(new Request(origin+'/api/create',{method:'POST'}))).status,503);
 assert.equal((await serve(new Request(origin+'/'))).status,200);assert.equal((await serve(new Request(origin+'/assets/test.png'))).status,200);
});
test('CSP hashes normalize HTML line endings and never enable arbitrary inline script or unsafe eval',()=>{
 const hash=createHash('sha256').update('const ready=true;\n').digest('base64'),csp=policy.contentPolicy('<script>const ready=true;\r\n</script>',origin);
 assert.ok(csp.includes("'sha256-"+hash+"'"));assert.match(csp,/object-src 'none'/);assert.match(csp,/connect-src 'self' wss:\/\/pipaklub.onrender.com/);
 const script=csp.split('; ').find(p=>p.startsWith('script-src'));assert.equal(script.includes('unsafe-inline'),false);assert.equal(script.includes('unsafe-eval'),false);
});
test('SteamPipe generation requires explicit IDs, starts in preview mode and never sets a live branch',()=>{
 for(const [a,d]of [[undefined,undefined],['APP_ID','DEPOT_ID'],['0','1'],['1','1'],['123"\n','456']])assert.throws(()=>steamBuildFiles(a,d,repo));
 const fixture=steamBuildFiles('123456','123457',path.join(repo,'dist','steam','PipaKlub-win32-x64'));assert.match(fixture.app,/"Preview" "1"/);assert.equal(fixture.app.includes('SetLive'),false);assert.match(fixture.depot,/steam_appid\.txt/);
});
test('prepared build bundles fonts and gameplay without a server or private files',async()=>{
 const root=path.join(repo,'desktop','build','client'),manifest=JSON.parse(await fs.readFile(path.join(root,'bundle.json'),'utf8')),html=await fs.readFile(path.join(root,'index.html'),'utf8');
 assert.ok(manifest.files.some(f=>f.endsWith('.woff2')));assert.ok(manifest.files.some(f=>f.endsWith('walls-v2.png')));
 assert.ok(manifest.files.every(f=>f==='index.html'||/^assets\/[a-zA-Z0-9/_.-]+\.(png|woff2?)$/.test(f)));
 assert.equal(html.includes('fonts.googleapis.com'),false);assert.equal(html.includes('const STATIC_HOST = true'),false);assert.match(html,/const CLARITY_ID=(?:""|'')/);
 assert.equal(createHash('sha256').update(html).digest('hex'),manifest.htmlSha256);
});
