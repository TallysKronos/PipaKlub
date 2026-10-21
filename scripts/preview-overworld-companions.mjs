// Local art review only. No account endpoints, database or unrestricted file serving.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
const root=path.resolve(import.meta.dirname,'..'),pack=JSON.parse(fs.readFileSync(path.join(root,'assets/creatures/overworld-v1/manifest.json'),'utf8'));
const allowed=new Set(['/art/overworld-companions-v1/index.html','/src/world-actors.js','/assets/creatures/overworld-v1/manifest.json','/assets/creatures/overworld-v1/README.md','/assets/hub/praca-v1/kael.png','/assets/world/street-v1/street.png',...Object.values(pack.species).map(a=>'/assets/'+a.image)]);
http.createServer((req,res)=>{
 const file=new URL(req.url,'http://localhost').pathname;
 if(!allowed.has(file)||!['GET','HEAD'].includes(req.method)){res.writeHead(404);res.end();return;}
 const type={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.png':'image/png','.json':'application/json; charset=utf-8','.md':'text/plain; charset=utf-8'}[path.extname(file)];
 res.setHeader('Content-Type',type);res.setHeader('Cache-Control','no-store');
 if(req.method==='HEAD'){res.end();return;}fs.createReadStream(path.join(root,file)).pipe(res);
}).listen(5228,'127.0.0.1',()=>console.log('Companion review: http://127.0.0.1:5228/art/overworld-companions-v1/index.html'));
