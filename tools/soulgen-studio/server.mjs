import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createGameSpritesService} from './game-sprites-service.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),app=fileURLToPath(new URL('./',import.meta.url));
const sprites=createGameSpritesService(root);
const types={'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.png':'image/png','.gif':'image/gif','.json':'application/json'};
export async function serve(req,res){
 const headers={'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'self'; img-src 'self' data: blob:; style-src 'self' 'unsafe-inline'; script-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'"};
 const end=(code,message)=>{res.writeHead(code,headers);res.end(message);};
 try{
  const route=new URL(req.url,'http://localhost').pathname;
  if(route.startsWith('/api/game-sprites')){
   const host=req.headers.host||'';
   if(!/^(127\.0\.0\.1|localhost|\[::1\])(:\d+)?$/.test(host)||req.headers.origin&&req.headers.origin!==`http://${host}`||req.headers['sec-fetch-site']==='cross-site')return end(403,'Use o Soulgen local.');
   const json=(code,value)=>{res.writeHead(code,{...headers,'Content-Type':'application/json'});res.end(JSON.stringify(value));};
   try{
    if(route==='/api/game-sprites'&&req.method==='GET')return json(200,await sprites.list());
    const match=/^\/api\/game-sprites\/([a-z-]+)(\/image)?$/.exec(route);if(!match)return end(404,'Sprite não encontrado.');
    if(req.method==='GET'&&match[2]){const bytes=await sprites.image(match[1]);res.writeHead(200,{...headers,'Content-Type':'image/png'});return res.end(bytes);}
    if(req.method!=='PUT'||match[2])return end(405,'Método não permitido.');
    if(!req.headers['content-type']?.startsWith('application/json'))return end(415,'Envie JSON.');
    const chunks=[];let size=0;for await(const chunk of req){size+=chunk.length;if(size>5e6)return end(413,'Recorte muito grande.');chunks.push(chunk);}
    let value;try{value=JSON.parse(Buffer.concat(chunks));}catch{return end(400,'JSON inválido.');}
    return json(200,await sprites.save(match[1],value));
   }catch(e){return json(e.status||500,{error:e.status?e.message:'Não foi possível salvar. Sua edição permanece no navegador.'});}
  }
  if(!['GET','HEAD'].includes(req.method))return end(405,'Somente leitura. Salve projetos pelo navegador.');
  const u=new URL(req.url,'http://localhost'),p=decodeURIComponent(u.pathname);if(p.includes('\\')||p.split('/').includes('..')||p.includes('\0'))return end(403,'Caminho inválido.');
  const shared=p.startsWith('/art/soulgen/keys/')&&['.png','.gif','.mjs','.json'].includes(path.extname(p)),base=shared?root:app,relative=shared?p.slice(1):p==='/'?'index.html':p.slice(1),file=path.resolve(base,relative);
  if(!file.startsWith(path.resolve(base)+path.sep)||!types[path.extname(file)]||!shared&&!['game-sprites.html','game-sprites.mjs','game-sprites.css','index.html','studio.css','studio.mjs','paint.mjs','model.mjs','carcara.mjs','eremor.mjs','kael.mjs','kael-review.html','kael-review.mjs','kael-frames.html','kael-frames.mjs','workflow.mjs','basics.mjs','nozinho.mjs','guaravento.mjs','micofolha.mjs','capimansa.mjs','tatutrama.mjs','flautrevo.mjs','trinca-brasas.mjs','alvaneve.mjs','chaspiral.mjs','hiponilo.mjs','marulume.mjs','jarabrasa.mjs','jaguarluar.mjs','azulongo.mjs','auriflama.mjs','umbrocasco.mjs','nevagume.mjs','rexal.mjs','tricerafan.mjs','pteralis.mjs','stegaru.mjs','yaguaru-memoria.mjs','araruna-memoria.mjs','caimbira-memoria.mjs','tamoata-memoria.mjs','herravento.mjs','basics-review.html','basics-review.mjs','lacertubo-compare.html','lacertubo-compare.mjs'].includes(relative))return end(404,'Arquivo não encontrado.');
  // Refuse symlinks outside the explicitly served roots.
  const actual=await fs.realpath(file),allowed=shared?path.resolve(root,'art/soulgen/keys'):path.resolve(app);if(!actual.startsWith(allowed+path.sep))return end(403,'Caminho inválido.');
  const data=await fs.readFile(actual);res.writeHead(200,{...headers,'Content-Type':types[path.extname(file)]});res.end(req.method==='HEAD'?undefined:data);
 }catch{return end(404,'Arquivo não encontrado.');}
}
if(process.argv[1]===fileURLToPath(import.meta.url)){const port=Number(process.env.SOULGEN_STUDIO_PORT||5240);if(!Number.isInteger(port)||port<1024||port>65535)throw Error('Porta inválida.');http.createServer(serve).listen(port,'127.0.0.1',()=>console.log('Soulgen Studio: http://127.0.0.1:'+port+' — ferramenta local, sem contas ou banco.'));}
