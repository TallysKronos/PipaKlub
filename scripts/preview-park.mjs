import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import {artConfig} from './art-build.mjs';
const root=path.resolve(import.meta.dirname,'..'),review='art/ui-reviews/park-coherence-2026-10-21';
const config=()=>{const c=artConfig().courtyard;return {scenes:Object.fromEntries(['park-trail','park-clearing'].map(k=>[k,c.world.scenes[k]])),images:c.images,actor:c.plaza.actor};};
http.createServer((req,res)=>{
 const u=new URL(req.url,'http://localhost');if(!['GET','HEAD'].includes(req.method)){res.writeHead(405);res.end();return;}
 if(u.pathname==='/config'){res.setHeader('Content-Type','application/json');res.setHeader('Cache-Control','no-store');res.end(u.searchParams.has('before')?fs.readFileSync(path.join(root,review,'before.json')):JSON.stringify(config()));return;}
 const file=u.pathname==='/'?'/'+review+'/index.html':u.pathname;
 const modules=['/src/world-art.js','/src/world-map.js','/src/world-navigation.js'];
 const before=JSON.parse(fs.readFileSync(path.join(root,review,'before.json'),'utf8'));
 const allowed=new Set(['/'+review+'/index.html',...modules,...Object.values({...before.images,...config().images}).map(d=>'/assets/'+d.image)]);
 if(!allowed.has(file)){res.writeHead(404);res.end();return;}res.setHeader('Content-Type',({'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.png':'image/png'})[path.extname(file)]);res.setHeader('Cache-Control','no-store');if(req.method==='HEAD'){res.end();return;}fs.createReadStream(path.join(root,file)).pipe(res);
}).listen(5233,'127.0.0.1',()=>console.log('Park review: http://127.0.0.1:5233/'));
