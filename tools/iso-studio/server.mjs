import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const app=fileURLToPath(new URL('./',import.meta.url)),files=['index.html','studio.css','studio.mjs','model.mjs'];
const types={'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.mjs':'text/javascript; charset=utf-8'};
export async function serve(req,res){
 const headers={'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'self'; img-src 'self' data: blob:; style-src 'self' 'unsafe-inline'; script-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'"};
 const end=(code,message)=>{res.writeHead(code,headers);res.end(message);};
 try{
  if(!['GET','HEAD'].includes(req.method))return end(405,'Somente leitura. Salve projetos pelo navegador.');
  const p=decodeURIComponent(new URL(req.url,'http://localhost').pathname),relative=p==='/'?'index.html':p.slice(1);
  if(!files.includes(relative))return end(404,'Arquivo não encontrado.');
  const data=await fs.readFile(path.join(app,relative));res.writeHead(200,{...headers,'Content-Type':types[path.extname(relative)]});res.end(req.method==='HEAD'?undefined:data);
 }catch{return end(404,'Arquivo não encontrado.');}
}
if(process.argv[1]===fileURLToPath(import.meta.url)){const port=Number(process.env.ISO_STUDIO_PORT||5241);if(!Number.isInteger(port)||port<1024||port>65535)throw Error('Porta inválida.');http.createServer(serve).listen(port,'127.0.0.1',()=>console.log('Iso Studio: http://127.0.0.1:'+port+' — ferramenta local, sem contas ou banco.'));}
