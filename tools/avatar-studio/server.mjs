import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../../',import.meta.url)),app=fileURLToPath(new URL('./',import.meta.url));
const types={'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.png':'image/png'};
// Bancada + o zip do Iso Studio + os quadros do piloto do Kael. Nada mais é servido.
const routes=new Map([['/',path.join(app,'index.html')],...['index.html','studio.css','studio.mjs','model.mjs'].map(f=>['/'+f,path.join(app,f)]),['/iso-studio/model.mjs',path.join(root,'tools/iso-studio/model.mjs')],
 ...Array.from({length:8},(_,i)=>[`/art/soulgen/keys/kael-frame-test/frames/east-${i}.png`,path.join(root,`art/soulgen/keys/kael-frame-test/frames/east-${i}.png`)])]);
export async function serve(req,res){
 const headers={'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'self'; img-src 'self' data: blob:; style-src 'self' 'unsafe-inline'; script-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'"};
 const end=(code,message)=>{res.writeHead(code,headers);res.end(message);};
 try{
  if(!['GET','HEAD'].includes(req.method))return end(405,'Somente leitura. Salve projetos pelo navegador.');
  const file=routes.get(decodeURIComponent(new URL(req.url,'http://localhost').pathname));if(!file)return end(404,'Arquivo não encontrado.');
  const data=await fs.readFile(file);res.writeHead(200,{...headers,'Content-Type':types[path.extname(file)]});res.end(req.method==='HEAD'?undefined:data);
 }catch{return end(404,'Arquivo não encontrado.');}
}
if(process.argv[1]===fileURLToPath(import.meta.url)){const port=Number(process.env.AVATAR_STUDIO_PORT||5242);if(!Number.isInteger(port)||port<1024||port>65535)throw Error('Porta inválida.');http.createServer(serve).listen(port,'127.0.0.1',()=>console.log('Avatar Studio: http://127.0.0.1:'+port+' — ferramenta local, sem contas ou banco.'));}
