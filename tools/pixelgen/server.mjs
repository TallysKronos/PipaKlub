import http from 'node:http';
import fs from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
const app=new URL('./',import.meta.url);
const allowed=new Map([['/','index.html'],...['style.css','app.mjs','core.mjs','animation.mjs','document.mjs','storage.mjs','quality.mjs','godot.mjs','worker.mjs','aseprite.mjs'].map(f=>['/'+f,f])]);
allowed.set('/professor-walk.pixelgen.json','examples/professor-walk.pixelgen.json');
allowed.set('/kael-walk.pixelgen.json','examples/kael-walk.pixelgen.json');
allowed.set('/kael-library.pixelgen.json','../../art/characters/kael-eight-directions-v1/kael-library.pixelgen.json');
allowed.set('/kael-stairs.pixelgen.json','../../art/characters/kael-stairs-study-v1/kael-stairs.pixelgen.json');
const types={html:'text/html; charset=utf-8',css:'text/css; charset=utf-8',mjs:'text/javascript; charset=utf-8',png:'image/png',json:'application/json; charset=utf-8'};
export async function serve(req,res){
 const headers={'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'self'; img-src 'self' data: blob:; style-src 'self' 'unsafe-inline'; script-src 'self'; worker-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'"};
 const end=(code,text)=>{res.writeHead(code,headers);res.end(text);};
 try{
  if(!['GET','HEAD'].includes(req.method))return end(405,'Somente leitura.');
  const pathname=new URL(req.url,'http://localhost').pathname;
  const file=pathname==='/demo.png'?new URL('../../art/characters/rpg-overworld-study-v1/kael-professor-4-direcoes.png',app):allowed.has(pathname)?new URL(allowed.get(pathname),app):null;
  if(!file)return end(404,'Não encontrado.');
  const bytes=await fs.readFile(file);res.writeHead(200,{...headers,'Content-Type':types[file.pathname.split('.').pop()]||'application/octet-stream'});res.end(req.method==='HEAD'?undefined:bytes);
 }catch{end(404,'Arquivo indisponível.');}
}
if(process.argv[1]===fileURLToPath(import.meta.url)){
 let port=Number(process.env.PIXELGEN_PORT||5264),attempts=0;
 if(!Number.isInteger(port)||port<1024||port>65525)throw Error('Porta inválida.');
 const server=http.createServer(serve);server.on('error',error=>{if(error.code==='EADDRINUSE'&&attempts++<10)server.listen(++port,'127.0.0.1');else throw error;});
 server.on('listening',()=>console.log(`Pixelgen: http://127.0.0.1:${port} — imagens processadas no navegador, sem uploads.`));server.listen(port,'127.0.0.1');
}
