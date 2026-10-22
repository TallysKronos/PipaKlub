// Local asset review. No accounts, persistence or production endpoints.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
const root=path.resolve(import.meta.dirname,'..');
const files=new Set(['/art/eremor-sprites-v1/index.html','/src/world-actors.js',
 '/assets/creatures/eremor-v1/battle/eremor.png','/assets/creatures/eremor-v1/battle/eremor.json',
 '/assets/creatures/eremor-v1/overworld/eremor.png','/assets/creatures/eremor-v1/overworld/manifest.json']);
http.createServer((req,res)=>{
 const url=new URL(req.url,'http://localhost'),file=url.pathname==='/'?'/art/eremor-sprites-v1/index.html':url.pathname;
 if(!files.has(file)||!['GET','HEAD'].includes(req.method)){res.writeHead(404);res.end();return;}
 const target=path.join(root,file);if(!fs.existsSync(target)){res.writeHead(404);res.end();return;}
 res.setHeader('Content-Type',({'.html':'text/html; charset=utf-8','.png':'image/png','.json':'application/json','.js':'text/javascript'})[path.extname(file)]);
 res.setHeader('Cache-Control','no-store');if(req.method==='HEAD'){res.end();return;}fs.createReadStream(target).pipe(res);
}).listen(5232,'127.0.0.1',()=>console.log('Eremor review: http://127.0.0.1:5232/'));
