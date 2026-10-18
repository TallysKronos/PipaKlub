import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../../',import.meta.url)),app=path.join(root,'tools','atelie');
const port=Number(process.env.ATELIE_PORT||5210);
if(!Number.isInteger(port)||port<1024||port>65535)throw Error('ATELIE_PORT inválida');
const types={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.json':'application/json','.tmj':'application/json','.png':'image/png'};
export async function serve(req,res){
 try{
  if(!['GET','HEAD'].includes(req.method)){res.writeHead(405);return res.end();}
  const u=new URL(req.url,'http://localhost'),p=decodeURIComponent(u.pathname);
  if(p.includes('\\')||p.split('/').includes('..')){res.writeHead(403);return res.end();}
  const shared=p.startsWith('/assets/')&&['.png','.json','.tmj'].includes(path.extname(p))||['/src/world-map.js','/src/world-art.js','/src/world-navigation.js'].includes(p);
  const base=shared?root:app,relative=shared?p.slice(1):p==='/'?'index.html':p.slice(1),file=path.resolve(base,relative);
  if(!file.startsWith(path.resolve(base)+path.sep)||!types[path.extname(file)]){res.writeHead(404);return res.end();}
  const data=await fs.readFile(file);res.writeHead(200,{'Content-Type':types[path.extname(file)],'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'self'; img-src 'self' data: blob:; style-src 'self'; script-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'"});res.end(req.method==='HEAD'?undefined:data);
 }catch{res.writeHead(404);res.end('Arquivo não encontrado');}
}
if(process.argv[1]===fileURLToPath(import.meta.url))http.createServer(serve).listen(port,'127.0.0.1',()=>console.log('Ateliê local: http://127.0.0.1:'+port+' — Ctrl+C para encerrar. Sem acesso a contas ou banco.'));
