// Local, read-only preview. Serves only the public assets folder, on loopback.
import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../assets/',import.meta.url));
const port=Number(process.env.PIPA_KIT_PORT||5195);
const mime={'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.js':'text/javascript; charset=utf-8','.json':'application/json; charset=utf-8','.png':'image/png','.svg':'image/svg+xml','.md':'text/plain; charset=utf-8'};
http.createServer(async(req,res)=>{
 try{
  if(!['GET','HEAD'].includes(req.method)){res.writeHead(405);res.end();return;}
  const url=new URL(req.url,'http://localhost');
  if(url.pathname==='/'){res.writeHead(302,{Location:'/ui/kit-switch-v1/index.html'});res.end();return;}
  const target=path.resolve(root,'.'+decodeURIComponent(url.pathname));
  if(!target.startsWith(root)){res.writeHead(403);res.end();return;}
  const ext=path.extname(target);if(!mime[ext]){res.writeHead(404);res.end();return;}
  const data=await fs.readFile(target);
  res.writeHead(200,{'Content-Type':mime[ext],'X-Content-Type-Options':'nosniff','Cache-Control':'no-store'});res.end(req.method==='HEAD'?undefined:data);
 }catch{res.writeHead(404);res.end('Arquivo não encontrado.');}
}).listen(port,'127.0.0.1',()=>console.log('Kit: http://127.0.0.1:'+port+'/ui/kit-switch-v1/index.html'));
