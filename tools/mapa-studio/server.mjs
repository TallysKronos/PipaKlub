import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
// Serve a bancada e lê (só lê) os mapas e tilesets de art/overworld. Salvar é no Tiled.
const app=fileURLToPath(new URL('./',import.meta.url)),art=fileURLToPath(new URL('../../art/overworld/',import.meta.url)),files=['index.html','studio.css','studio.mjs','model.mjs'];
const types={'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.tmj':'application/json; charset=utf-8','.tsj':'application/json; charset=utf-8','.json':'application/json; charset=utf-8','.png':'image/png'};
const NAME=/^[a-z0-9][a-z0-9-]*\.(tmj|tsj|png)$/;
export async function serve(req,res){
 const headers={'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'self'; img-src 'self' data: blob:; style-src 'self' 'unsafe-inline'; script-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'"};
 const end=(code,message)=>{res.writeHead(code,headers);res.end(message);};
 const send=(file,data)=>{res.writeHead(200,{...headers,'Content-Type':types[path.extname(file)]});res.end(req.method==='HEAD'?undefined:data);};
 try{
  // Explicit local review mode: save only generated PNG references to a fixed
  // workspace directory. Normal Studio remains read-only.
  if(process.env.MAPA_STUDIO_EXPORT==='1'&&req.method==='POST'&&req.url==='/export-reference'){
   const expected=`http://${req.headers.host}`;
   if(req.headers.origin!==expected||req.headers['content-type']!=='image/png')return end(403,'Origem ou formato inválido.');
   const name=String(req.headers['x-export-name']||'');
   const match=name.match(/^([a-z0-9-]+)-(referencia|legendas)\.png$/);
   if(!match)return end(400,'Nome inválido.');
   await fs.access(path.join(art,'mapas',match[1]+'.tmj'));
   const chunks=[];let length=0;
   for await(const chunk of req){length+=chunk.length;if(length>16*1024*1024)return end(413,'Arquivo grande demais.');chunks.push(chunk);}
   const png=Buffer.concat(chunks);
   if(png.subarray(0,8).toString('hex')!=='89504e470d0a1a0a')return end(400,'PNG inválido.');
   const target=path.resolve(app,'../../documentation/overworld/pip81/references');
   await fs.mkdir(target,{recursive:true});await fs.writeFile(path.join(target,name),png);
   return send('result.json',JSON.stringify({saved:name}));
  }
  if(!['GET','HEAD'].includes(req.method))return end(405,'Somente leitura. Edite e salve os mapas no Tiled.');
  const p=decodeURIComponent(new URL(req.url,'http://localhost').pathname);
  if(p==='/mapas/'){const list=(await fs.readdir(path.join(art,'mapas'))).filter(f=>f.endsWith('.tmj')).map(f=>f.slice(0,-4)).sort();return send('x.json',JSON.stringify(list));}
  const m=p.match(/^\/(mapas|tiles)\/([^/]+)$/);
  if(m){if(!NAME.test(m[2]))return end(404,'Arquivo não encontrado.');return send(m[2],await fs.readFile(path.join(art,m[1],m[2])));}
  const relative=p==='/'?'index.html':p.slice(1);
  if(!files.includes(relative))return end(404,'Arquivo não encontrado.');
  send(relative,await fs.readFile(path.join(app,relative)));
 }catch{return end(404,'Arquivo não encontrado.');}
}
if(process.argv[1]===fileURLToPath(import.meta.url)){const port=Number(process.env.MAPA_STUDIO_PORT||5244);if(!Number.isInteger(port)||port<1024||port>65535)throw Error('Porta inválida.');http.createServer(serve).listen(port,'127.0.0.1',()=>console.log('Mapa Studio: http://127.0.0.1:'+port+' — lê art/overworld/mapas; edite no Tiled e clique em Recarregar.'));}
